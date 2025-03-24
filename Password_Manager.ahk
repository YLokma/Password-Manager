#SingleInstance Force
config_file := "PM settings.ini"

if (not A_IsCompiled)
    TraySetIcon("Key.ico",,1)

if FileExist(config_file) {
    configuration := Map()
    for section in StrSplit(IniRead(config_file), "`n", '`r') {
		configuration[section] := Map()
		for line in StrSplit(IniRead(config_file, section),"`n", '`r') {
			pair := StrSplit(line, "=")
			configuration[section][pair[1]] := StrReplace(pair[2], '"', "")
		}
	}
} else {
	configuration := Map(
		"Hotkeys", Map(
			"1_account_finder_key", "^!Space",
			"3_username_key", "!u",
			"4_password_key", "!p",
            "2_lens_key", "!l",
		),
		"Recommendations", Map(
			"1_recommended_usernames", "",
			"2_recommended_passwords", ""
		),
		"Files and Sync", Map(
			"1_passwords_csv_file", "# Please locate your passwords CSV file #",
			"2_sync_directory", "# directory to sync your passwords file #"
		),
        "Lens", Map(
            "5_lens_save_dimensions", "1",
            "1_lens_width", "150",
            "2_lens_height", "50",
            "4_lens_border_width", "2",
            "3_lens_border_color", "Teal"
        )
	)
	open_settings()
}
enable_hotkeys(configuration['Hotkeys'])

username := '`0'
password := '`0'

enable_hotkeys(configuration_hotkeys) {
    HotIfWinNotActive("ahk_pid " WinGetPID(A_ScriptHwnd))
        Hotkey(configuration_hotkeys['1_account_finder_key'], find_current_window, 'On')
        Hotkey(configuration_hotkeys['3_username_key'], (*) => username ? SendText(username) : "", 'On')
        Hotkey(configuration_hotkeys['4_password_key'], (*) => password ? SendText(password) : "", 'On')
        Hotkey(configuration_hotkeys['2_lens_key'], lens, 'On')
    Hotif
    return
}
lens(*) {
    query := OCR_Under_Mouse()
    if not query
        return

    Search_Box.Text := query
    rows := search()
    
    found := 0
    if rows {
        if rows == 1
            found := 1
        else if List_View.GetText(1, 5) > List_View.GetText(2, 5)
            found := 1
    }
    if found {
        copy_account(1)
        ToolTip(List_View.GetText(1, 1))
        SetTimer((*) => ToolTip(), -2000)
    } else
        show()
}
open_settings(*) {
    global configuration
    global Settings_Gui := Gui("-MaximizeBox -MinimizeBox", "PM Settings")
    Settings_Gui.BackColor := 'White'
    Settings_Gui.SetFont("s10", 'Consolas')
    
    tab_titles := []
    for name, section in configuration
        tab_titles.Push(name)

    Tabs := Settings_Gui.AddTab3('+Theme -Background', tab_titles)
    Tabs.SetFont("bold")

	Tabs.UseTab('Hotkeys')
    for key, value in configuration['Hotkeys'] {
        Settings_Gui.AddText("w300", format_key_name(key)).SetFont("underline")
		Settings_Gui.AddHotkey('wp v' key, value)
    }

	Tabs.UseTab('Recommendations')
    for key, value in configuration['Recommendations'] {
		Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline")

		text := StrReplace(value, ", ", "`n")
		Settings_Gui.AddEdit("wp r11 v" key, text)
    }

	Tabs.UseTab('Files and Sync')
    for key, value in configuration['Files and Sync'] {
		Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline")

		Settings_Gui.AddEdit("wp v" key, value)
		browse_button := Settings_Gui.AddButton("wp vbrowse_" key, "Browse")
		browse_button.OnEvent("Click", browse)
		browse_button.Description := "Choose the file or folder"
		GuiButtonIcon(browse_button, "shell32.dll", 46, "s20 R80 A4")
    }

    Tabs.UseTab('Lens')
    for key, value in configuration['Lens'] {
        if InStr(key, "border_color") { ; 3_lens_border_color
            color_code := Settings_Gui.AddText("wp", "Lens Border Color: " value)
            color_code.SetFont("bold underline")
            color_demo := Settings_Gui.AddProgress("wp Range0-1 c" value, 1)

            for col in ["Red", "Green", "Blue"] {
                slider := Settings_Gui.AddSlider("wp Center AltSubmit v" key "_" col " Range0-255 ToolTip", "0X" SubStr(value, 1 + (A_Index * 2), 2))
                slider.OnEvent("Change", update_color)
                slider.Description := col
            }
        }
        else {
            Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline")
            if InStr(key, "lens_save_dimensions") ; 5_lens_save_dimensions
                Settings_Gui.AddCheckbox("wp v" key " " (value ? "Checked" : ""), "Save lens dimensions")
            else {
                Settings_Gui.AddEdit("wp v" key, value)
                Settings_Gui.AddUpDown("Range0-1000 Wrap", value)
            }
        }

    }

    Tabs.UseTab(0)
    submit_button := Settings_Gui.AddButton('w161 Default r2', "Save")
    submit_button.OnEvent("Click", submit_configuration)
    submit_button.SetFont("bold s12")
    submit_button.Description := "Apply & Save the changes"
    GuiButtonIcon(submit_button, "shell32.dll", 259, "s22 R90 A4")
    
    revert_button := Settings_Gui.AddButton('wp yp r2', "Revert")
    revert_button.OnEvent("Click", (*) => (Settings_Gui.Destroy(), open_settings()))
    revert_button.SetFont("bold s12")
    revert_button.Description := "Revert all changes"
    GuiButtonIcon(revert_button, "shell32.dll", 296, "s22 R120 A4")

    Settings_Gui.Show()
    Settings_Gui.OnEvent("Escape", (*) => Settings_Gui.Hide())

    SetTimer(show_descriptions, 250)
    format_key_name(keyname) {
        return StrTitle(StrReplace(RegExReplace(keyname, "^\d+_"), "_", " "))
    }
    browse(GuiCtrlObj, *) {
        global configuration
        key := SubStr(GuiCtrlObj.Name, 8)
        if InStr(key, "directory")
            selected_file_or_folder := FileSelect('D 2', A_WorkingDir, "Choose your " StrReplace(key, "_", " "))
        else
            selected_file_or_folder := FileSelect(3, A_WorkingDir, "Choose your " StrReplace(key, "_", " "), "*." StrSplit(key, "_")[-2])
        
        if selected_file_or_folder
            Settings_Gui[key].Value := StrReplace(selected_file_or_folder, A_WorkingDir '\', "")
    }
    update_color(*) {
        code := Format("{:02X}{:02X}{:02X}", Settings_Gui["3_lens_border_color_Red"].Value, Settings_Gui["3_lens_border_color_Green"].Value, Settings_Gui["3_lens_border_color_Blue"].Value)
        color_demo.Opt("c" code)
        color_code.Text := "Lens Border Color: 0x" code
        return code
    }
    submit_configuration(*) {
        global configuration
        disable_hotkeys(configuration['Hotkeys'])
        new_configuration := Settings_Gui.Submit()
    
        new_configuration.3_lens_border_color := Format("0x{:02X}{:02X}{:02X}", new_configuration.3_lens_border_color_Red, new_configuration.3_lens_border_color_Green, new_configuration.3_lens_border_color_Blue)
        
        for name, section in configuration {
            for key, value in section {
                if (new_configuration.%key% != value)
                    configuration[name][key] := new_configuration.%key%
            }
        }
    
        enable_hotkeys(configuration['Hotkeys'])
        Settings_Gui.Destroy()
        global configuration
        for name, section in configuration
            for key, value in section
                    IniWrite(StrReplace(value, "`n", ", "), config_file, name, key)
    }

    disable_hotkeys(configuration_hotkeys) {
        HotIfWinNotActive("ahk_pid " WinGetPID(A_ScriptHwnd))
            for key, value in configuration_hotkeys {
                try Hotkey(value, "Off", "Off")
            }
        Hotif
    }
}

csv_columns := ["name", "url", "username", "password"]
list_columns := ["name", "url", "username", "password", "#"]

A_TrayMenu.Delete()

Standard_Menu := Menu()
Standard_Menu.AddStandard()

A_TrayMenu.Add("Standard", Standard_Menu)
A_TrayMenu.Add()
A_TrayMenu.Add("Password Manager", (*) => (list_all_windows(), show()))
A_TrayMenu.Add("Find this account", find_current_window)
A_TrayMenu.Add("Lens", lens)
; A_TrayMenu.Add("OCR", OCR_Under_Mouse)
A_TrayMenu.Add("Settings", open_settings)
A_TrayMenu.Default := "Password Manager"
A_TrayMenu.ClickCount := 1

PM_GUI := Gui("-MaximizeBox -MinimizeBox", "Password Manager")
PM_GUI.BackColor := 'White'
PM_GUI.SetFont("s10", 'Consolas')
PM_GUI.OnEvent("Escape", (*) => (ToolTip(), PM_GUI.Hide()))

Search_Button := PM_GUI.AddButton("w25 h23 Default", '')
Search_Button.OnEvent("Click", (*) => (PM_GUI.Hide(), WinActivate(StrSplit(list_all_windows()[1], " -> ")[2]), find_current_window()))
Search_Button.Description := "Search for an account"
GuiButtonIcon(Search_Button, "shell32.dll", 23, "A4")

; Reset_Button := PM_GUI.AddButton("w25 h23 yp", '')
; Reset_Button.OnEvent("Click", (*) => search())
; Reset_Button.Description := "Reset current view"
; GuiButtonIcon(Reset_Button, "shell32.dll", 239, "A4")

Search_Box := PM_GUI.AddComboBox("w485 yp vSearch_Box")
Search_Box.Description := "Enter your search query"
Search_Box.OnEvent("Change", (*) => search())

Add_Button := PM_GUI.AddButton("w25 h23 yp", '')
Add_Button.OnEvent("Click", (*) => account_gui())
Add_Button.Description := "Add a new account"
GuiButtonIcon(Add_Button, "shell32.dll", 270, "A4")
Settings_Button := PM_GUI.AddButton("w25 h23 yp", '')
Settings_Button.OnEvent("Click", open_settings)
Settings_Button.Description := "Open settings"
GuiButtonIcon(Settings_Button, "shell32.dll", 315, "A4")

List_View := PM_GUI.AddListView("xm w580 h250 c555555 Sort +Grid -Multi -Hdr -E0x200 LV0x4000 LV0x40 LV0x800", list_columns)
List_View.OnEvent("ContextMenu", (CtrlObj, Item, *) => show_context_menu(Item))
List_View.OnEvent("DoubleClick", double_click_account)
List_View.OnEvent("Click", (*) => (Search_Box.Focus(), Send("{End}")))

list_all_windows(*) {
    window_IDs := WinGetList()
    old_text := Search_Box.Text

    titles := []
    for window_ID in window_IDs {
        title := WinGetTitle(window_ID)
        app_name := WinGetProcessName(window_ID)
        if (title)
            if (app_name != "explorer.exe" and app_name != "AutoHotkey64.exe")
                titles.Push(app_name ' -> ' title)
    }
    if (InStr(titles[1], "Arc.exe -> ")) {
        WinActivate('ahk_exe Arc.exe')
        WinwaitActive('ahk_exe Arc.exe')

        A_Clipboard := ""
        loop 4 {
            Send '^+c'
            if ClipWait(0.5)
                break
        }

        domain := RegExReplace(A_Clipboard, ".*://(.*?)/.*", "$1")
        ; domain := RegExReplace(domain, "\.[^.]+$", "") ; remove .com, .edu...
        titles[1] := "Arc.exe -> " domain
    }
    
    Search_Box.Delete()
    Search_Box.Add(titles)
    Search_Box.Text := old_text

    return titles
}
find_current_window(*) {
    list_all_windows()
    Search_Box.Choose(1)
    
    rows := search(), found := 0
    if rows {
        if rows == 1
            found := 1
        else if List_View.GetText(1, 5) > List_View.GetText(2, 5)
            found := 1
        
        if found {
            copy_account(1)
            
            ToolTip(List_View.GetText(1, 1))
            SetTimer((*) => ToolTip(), -2000)
        }
        else
            show()
    } else
        lens()
}
show(*) {
    PM_GUI.Show('AutoSize Center')
    Search_Box.Focus()
    
    SetTimer(show_descriptions, 250)
}
show_descriptions() {
    if WinActive("ahk_pid " WinGetPID(A_ScriptHwnd)) {
        try {
            MouseGetPos(,,&Window, &ctrl)
            parent_gui := (Window == PM_GUI.Hwnd ? PM_GUI : Settings_Gui)
            desc := parent_gui[ControlGetHwnd(ctrl, Window)].Description
            if desc
                ToolTip(desc)
        }
        catch Error
            ToolTip()
    } else {
        ToolTip()
        SetTimer(show_descriptions, 0)
    }
}
double_click_account(list, row) {
    copy_account(row)
    PM_GUI.Hide()
}

search()
List_View.ModifyCol(1, 200)
List_View.ModifyCol(2, 100)
List_View.ModifyCol(3, 238)
List_View.ModifyCol(4, 12)
List_View.ModifyCol(5, 12)

#Hotif WinActive("ahk_id " PM_GUI.Hwnd)
{
    Enter:: {
        copy_account(List_View.GetNext(, "F"))
        PM_GUI.Hide()
    }
    Up::   move_selector(-1)
    Down:: move_selector(+1)
    ^BackSpace:: {
        if not Search_Box.Focused
            Search_Box.Focus()

        Send '^{Left}'
        Send '^{Delete}'
    }
    ^a:: Search_Box.Focus()
    Del:: delete_account()
}
#HotIf

; -----------------------------------------------------------------------

search(query := Search_Box.Text) {
    List_View.Delete()
    List_View.Opt("-Redraw")
    delimiters := [',', ' ', '_', ';', '.', '-', '@', '(', ')', "'", '"']
    
    if InStr(query, ' -> ') {
        app_name := StrSplit(query, ' -> ')[1]
        if (app_name)
            query := StrReplace(query, app_name, "", 1,, 1)
        app_name := StrReplace(app_name, ".exe", "", 1,, 1)
    } else
        app_name := "`0"
    
    keywords := StrSplit(query, delimiters)
    
    while not FileExist(configuration['Files and Sync']['1_passwords_csv_file'])
        Sleep(50)
    
    loop read configuration['Files and Sync']['1_passwords_csv_file'] {
        current := []
        loop parse A_LoopReadLine, "CSV"
            current.Push(A_LoopField)
        
        relevance := (keywords.Length = 0)
        
        for word in StrSplit(current[1], delimiters)
            relevance += (3 * (app_name = word))
        
        for keyword in keywords
            for word in StrSplit(current[1], delimiters)
                if StrLen(keyword) > 0
                    relevance += (Max(InStr(word, keyword) > 0, 2 * (word = keyword))) ; * 2) + (InStr(current[3], word) > 0))
        
        if relevance
            List_View.Add(, current[1], current[2], current[3], current[4], relevance)
    }

    if keywords.Length > 0
        List_View.ModifyCol(5, "Integer SortDesc")
    
    List_View.Modify(1, "Focus Select")
    List_View.Opt("+Redraw")

    PM_GUI.Title := "Password Manager - " List_View.GetCount() " results"

    return List_View.GetCount()
}
move_selector(displacement) {
    old_selector := List_View.GetNext(, "F")
    List_View.Modify(old_selector, "-Focus -Select")
    
    new_selector := old_selector + displacement
    if (new_selector <= 0)
        new_selector := List_View.GetCount()
    else if (new_selector > List_View.GetCount())
        new_selector := 1
    List_View.Modify(new_selector, "Vis Focus Select")
}

copy_account(row) {
    global username, password
    
    username := List_View.GetText(row, 3)
    password := List_View.GetText(row, 4)

    SetTimer(clear_variable, -1000 * 60 * 5)
    clear_variable(*) {
        username := '`0'
        password := '`0'
    }
}

show_context_menu(row) {
    context_menu := Menu()
    context_menu.Add("Go to website", run_website)
    context_menu.Add("Modify", modify_account)
    context_menu.Add("Delete", delete_account)
    context_menu.Show()
    
    modify_account(ItemName, ItemPos, MyMenu) {
        found_account_text := csv_format(List_View.GetNext(, 'F'))
        found_account_array := StrSplit(found_account_text, ',', '`r`n')
        account_gui(found_account_array)
    }
    run_website(ItemName, ItemPos, MyMenu) {
        row := List_View.GetNext(, "F")
        url := List_View.GetText(row, 2)
        if (SubStr(url, 1, 4) == "http")
            Run url
        else if MsgBox("URL not found, do you want to search for it?", "Invalid URL", "Y/N") == "Yes"
                Run "https://www.google.com/search?q=" StrReplace(url, ' ', '+')
    }
}
account_gui(found_account_array := 0) {
    New_Account_GUI := Gui(, "Add Account")
    New_Account_GUI.SetFont("s10", 'Consolas')
    New_Account_GUI.OnEvent("Escape", (*) => New_Account_GUI.Destroy())

    Recommendations := Map()
    
    for column in csv_columns {
        if (found_account_array)
            Recommendations[column] := [found_account_array[A_Index]]
        else
            Recommendations[column] := []
    }
    
	Recommendations["username"].Push(StrSplit(configuration['Recommendations']['1_recommended_usernames'], ", ")*)
	Recommendations["password"].Push(StrSplit(configuration['Recommendations']['2_recommended_passwords'], ", ")*)

    for column in csv_columns {
        New_Account_GUI.AddText("xm w200", column).SetFont("underline")
        New_Account_GUI.AddComboBox("xm wp v" column, Recommendations[column])
        if found_account_array
            New_Account_GUI[column].Value := 1
    }
    New_Account_GUI.AddButton("xm Default w97", found_account_array ? "Modify" : "Create").OnEvent("Click", found_account_array ? modify : create)
    
    New_Account_GUI.AddButton("yp w97", "Cancel").OnEvent("Click", (*) => New_Account_GUI.Destroy())  
    New_Account_GUI.Show()
    return New_Account_GUI
    
    create(GuiCtrlObj, Info) {
        submitted_account := GuiCtrlObj.Gui.Submit()
        
        replace_text_in_file(, csv_format(submitted_account))
        Search_Box.Text := submitted_account.name
        search()
        sync_file()
    }
    modify(GuiCtrlObj, Info) {
        submitted_account := GuiCtrlObj.Gui.Submit()
    
        replace_text_in_file(csv_format(List_View.GetNext(, 'F')), csv_format(submitted_account))
        Search_Box.Text := submitted_account.name
        search()
        sync_file()
    }
}
csv_format(source) {
    formatted_text := ""
    
    for column in csv_columns {
        if IsInteger(source)
            formatted_text .= List_View.GetText(source, A_Index)
        else if IsObject(source)
            formatted_text .= source.%column%
        else
            return
        
        if (A_Index < csv_columns.Length)
            formatted_text .= ','
    }
    formatted_text .= "`r`n"
    return formatted_text
}
replace_text_in_file(old_text?, new_text?, Filename := configuration['Files and Sync']['1_passwords_csv_file']) {
    File_Text := FileRead(Filename)
    if IsSet(old_text)
        New_File_Text := StrReplace(File_Text, old_text, new_text, true,, 1)
    else
        New_File_Text := File_Text . new_text
    
    FileObj := FileOpen(Filename, "w `n")
    FileObj.Write(Sort(New_File_Text))
    FileObj.Close()
}
delete_account(*) {
    if (MsgBox("Are you sure you want to delete this account?",,"Y/N Default2")) = "No"
        return

    replace_text_in_file(csv_format(List_View.GetNext(, 'F')), "")

    sync_file()
    search()
}
sync_file(Filename := configuration['Files and Sync']['1_passwords_csv_file'], destination := configuration['Files and Sync']['2_sync_directory']) {
    if DirExist(destination)
        FileCopy(Filename, destination, true)
}

; https://renenyffenegger.ch/development/Windows/PowerShell/examples/WinAPI/ExtractIconEx/shell32.html

GuiButtonIcon(Handle, File, Index := 1, Options := '')
{
	RegExMatch(Options, 'i)w\K\d+', &W) ? W := W.0 : W := 16
	RegExMatch(Options, 'i)h\K\d+', &H) ? H := H.0 : H := 16
	RegExMatch(Options, 'i)s\K\d+', &S) ? W := H := S.0 : ''
	RegExMatch(Options, 'i)l\K\d+', &L) ? L := L.0 : L := 0
	RegExMatch(Options, 'i)t\K\d+', &T) ? T := T.0 : T := 0
	RegExMatch(Options, 'i)r\K\d+', &R) ? R := R.0 : R := 0
	RegExMatch(Options, 'i)b\K\d+', &B) ? B := B.0 : B := 0
	RegExMatch(Options, 'i)a\K\d+', &A) ? A := A.0 : A := 4
	W *= A_ScreenDPI / 96, H *= A_ScreenDPI / 96
	button_il := Buffer(20 + A_PtrSize)
	normal_il := DllCall('ImageList_Create', 'Int', W, 'Int', H, 'UInt', 0x21, 'Int', 1, 'Int', 1)
	NumPut('Ptr', normal_il, button_il, 0)			; Width & Height
	NumPut('UInt', L, button_il, 0 + A_PtrSize)		; Left Margin
	NumPut('UInt', T, button_il, 4 + A_PtrSize)		; Top Margin
	NumPut('UInt', R, button_il, 8 + A_PtrSize)		; Right Margin
	NumPut('UInt', B, button_il, 12 + A_PtrSize)	; Bottom Margin
	NumPut('UInt', A, button_il, 16 + A_PtrSize)	; Alignment
	SendMessage(BCM_SETIMAGELIST := 5634, 0, button_il, Handle)
	Return IL_Add(normal_il, File, Index)
}

; https://github.com/Descolada/OCR
#include OCR Library.ahk
OCR_Under_Mouse(*) {
	CoordMode "Mouse", "Screen"

	DllCall("SetThreadDpiAwarenessContext", "ptr", -3) ; Needed for multi-monitor setups with differing DPIs
	OCR.PerformanceMode := 1 ; Uncommenting this makes the OCR more performant, but also more CPU-heavy
    DetectHiddenWindows(1)

	done := esc := 0
    minsize := 5, step := 3

    w := configuration['Lens']['1_lens_width'], h := configuration['Lens']['2_lens_height']
    
    Hotkey("LButton", (*) => (done := 1), 'On')
    Hotkey("Left", (*) => (w+=step), 'On')
    Hotkey("Right", (*) => (w-=(w < minsize ? 0 : step)), 'On')
    Hotkey("Up", (*) => (h+=step), 'On')
    Hotkey("Down", (*) => (h-=(h < minsize ? 0 : step)), 'On')
    Hotkey("Esc", (*) => (esc := 1), 'On')
    
    guis := []
    while not (done or esc) {
		MouseGetPos(&x, &y)
		Highlight(x-w, y-h, w, h, configuration['Lens']['3_lens_border_color'], configuration['Lens']['4_lens_border_width'])
		ToolTip(found_text := OCR.FromRect(x-w, y-h, w, h, {scale:2}).Text, , y+h//2+10)
	}
	Highlight()
	ToolTip()
    
    if (w != configuration['Lens']['1_lens_width']) {
        configuration['Lens']['1_lens_width'] := w
        IniWrite(w, config_file, 'Lens', '1_lens_width')
    }
    
    if (h != configuration['Lens']['2_lens_height']) {
        configuration['Lens']['2_lens_height'] := h
        IniWrite(h, config_file, 'Lens', '2_lens_height')
    }

    Hotkey("LButton", 'Off', 'Off')
    Hotkey("Right", 'Off', 'Off')
    Hotkey("Left", 'Off', 'Off')
    Hotkey("Up", 'Off', 'Off')
    Hotkey("Down", 'Off', 'Off')
    Hotkey("Esc", 'Off', 'Off')
	
    if done
        return found_text
    else
        return 0

    Highlight(x?, y?, w?, h?, color:="Gray", d:=2) {
		if !IsSet(x) {
			for g in guis
				g.Destroy()
			guis := []
			return
		}
		if !guis.Length {
			Loop 4
				guis.Push(Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"))
		}
		Loop 4 {
			i:=A_Index
			x1:=(i=2 ? x+w : x-d)
			y1:=(i=3 ? y+h : y-d)
			w1:=(i=1 or i=3 ? w+2*d : d)
			h1:=(i=2 or i=4 ? h+2*d : d)
			guis[i].BackColor := color
			guis[i].Show("NA x" . x1 . " y" . y1 . " w" . w1 . " h" . h1)
		}
	}
    ; box := Gui("+AlwaysOnTop -SysMenu ToolWindow -DPIScale", 'Lens')
    ; box.BackColor := configuration['Lens']['3_lens_border_color']
    ; WinSetTransparent(100, box.Hwnd)
    
    ; while not (done or esc) {
    ;     MouseGetPos(&x, &y)
    ;     ; box.Title := OCR.FromRect(x-w, y-h, w, h, {scale:2}).Text
    ;     ; box.Show("NA x" . x-w-5 . " y" . y-h-40 . " w" . w . " h" . h)
	; }
    ; found_text := box.Title
    ; box.Destroy()
}

/* columns := Map("CSV", Map("Website Name", 1, "URL", 2, "username/email", 3, "password", 4),
"list", Map("relevance", 1, "Website Name", 2,  "username/email", 3, "password", 4, "URL", 5))

new_columns := Map(
    "#", Map("CSV", 0, "List", 1),
    "Website Name", Map("CSV", 1, "List", 2),
    "username/email", Map("CSV", 3, "List", 3),
    "password", Map("CSV", 4, "List", 4),
    "URL", Map("CSV", 2, "List", 5)
) */
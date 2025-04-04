#SingleInstance Force
config_file := "PM settings.ini"
font_size := 10

TraySetIcon("imageres.dll", 78, 1)
A_TrayMenu.Delete()
A_TrayMenu.ClickCount := 1
A_TrayMenu.Add("Settings", open_settings)
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Settings"

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
            "2_lens_key", "!l",
			"3_username_key", "!u",
			"4_password_key", "!p"
		),
		"Recommendations", Map(
			"1_recommended_usernames", "",
			"2_recommended_passwords", ""
		),
		"Settings", Map(
			"1_passwords_csv_file", "Locate your passwords CSV file",
			"2_sync_directory", "# directory to sync your passwords file #",
            "3_show_on_launch?", "1",
            "4_run_on_system_startup?", "0"
		),
        "Lens", Map(
            "1_lens_width", "150",
            "2_lens_height", "50",
            "3_lens_border_color", "0xFF0000",
            "4_lens_border_width", "2",
            "5_save_lens_dimensions?", "1"
        )
	)
}
if not FileExist(configuration['Settings']['1_passwords_csv_file']) {
    MsgBox("Please locate your passwords CSV file", "Error: non-existent passwords file")
    open_settings()
}

if configuration['Settings']['4_run_on_system_startup?']
    FileCreateShortcut(A_ScriptFullPath, A_Startup '\' RegExReplace(A_ScriptName, "\..*$", ".lnk"), , , , A_IsCompiled ? A_ScriptFullPath : A_IconFile)
else
    try FileDelete(A_Startup '\' RegExReplace(A_ScriptName, "\..*$", ".lnk"))

username := '`0'
password := '`0'

PM_GUI := Gui("+Resize", "Password Manager")
PM_GUI.BackColor := 'White'
PM_GUI.SetFont("s" font_size, 'Consolas')
PM_GUI.OnEvent("Escape", (*) => (ToolTip(), PM_GUI.Hide()))
PM_GUI.OnEvent("Size", (GuiObj, MinMax, Width, Height) => MinMax == -1 ? "" : resize_window(Width, Height))

Search_Button := PM_GUI.AddButton("w25 h23 Default", '')
Search_Button.OnEvent("Click", (*) => (PM_GUI.Hide(), WinActivate(StrSplit(list_all_windows()[1], " -> ")[2]), find_current_window()))
Search_Button.Description := "Search for an account"
GuiButtonIcon(Search_Button, "imageres.dll", 169, "S15")

Add_Button := PM_GUI.AddButton("w25 h23 yp", '')
Add_Button.OnEvent("Click", (*) => account_gui())
Add_Button.Description := "Add a new account"
GuiButtonIcon(Add_Button, "imageres.dll", 248, "S15")

Settings_Button := PM_GUI.AddButton("w25 h23 yp", '')
Settings_Button.OnEvent("Click", open_settings)
Settings_Button.Description := "Open settings"
GuiButtonIcon(Settings_Button, "imageres.dll", 110, "S15")

Search_Box := PM_GUI.AddComboBox("yp w450 vSearch_Box")
Search_Box.Description := "Enter your search query"

while not FileExist(configuration['Settings']['1_passwords_csv_file'])
    Sleep(50)

csv_columns := [], csv_column_locations := Map()
loop read configuration['Settings']['1_passwords_csv_file'] {
    loop parse A_LoopReadLine, "CSV" {
        csv_columns.Push(A_LoopField)
        csv_column_locations[A_LoopField] := A_Index
    }
    break
}

col_count := 0, required_columns := ["name", "url", "username", "password"]
for req_col in required_columns
    for col in csv_columns
        if (req_col = col)
            col_count++
if (col_count != required_columns.Length) {
    result := MsgBox("The CSV passwords file must contain the following columns:`n" '"name", "url", "username", "password"', "Error: Invalid CSV file", "R/C Iconx")
    if (result = "Retry") {
        IniWrite("Locate your passwords CSV file", config_file, 'Settings', '1_passwords_csv_file')
        Reload()
    } else
        ExitApp()
}

A_TrayMenu.Delete()
A_TrayMenu.Add("Password Manager", (*) => (list_all_windows(), show()))
A_TrayMenu.Add("Find this account", find_current_window)
A_TrayMenu.Add("Lens", lens)
A_TrayMenu.Add("Settings", open_settings)
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Password Manager"
A_TrayMenu.ClickCount := 1

HotIfWinNotActive("ahk_pid " WinGetPID(A_ScriptHwnd))
    Hotkey(configuration['Hotkeys']['1_account_finder_key'], find_current_window)
    Hotkey(configuration['Hotkeys']['2_lens_key'], lens)
    Hotkey(configuration['Hotkeys']['3_username_key'], (*) => username ? SendText(username) : "")
    Hotkey(configuration['Hotkeys']['4_password_key'], (*) => password ? SendText(password) : "")
HotIfWinActive("ahk_id " PM_GUI.Hwnd)
    Hotkey('Enter', (*) => (copy_account(List_View.GetNext(, "F")), PM_GUI.Hide()))
    Hotkey('^Enter', (*) => run_website(List_View.GetNext(, "F")))
    Hotkey('F1', (*) => account_gui())
    Hotkey('F2', (*) => modify_account(List_View.GetNext(, "F")))
    Hotkey('F3', (*) => delete_account(List_View.GetNext(, "F")))
    Hotkey('F5', (*) => search())
    Hotkey('Up', (*) => move_selector(-1))
    Hotkey('Down', (*) => move_selector(+1))
    
    Hotkey('^a', (*) => Search_Box.Focus())
    Hotkey('^BackSpace', delete_word)

    Hotkey('^WheelUp', (*) => change_font_size(1))
    Hotkey('^WheelDown', (*) => change_font_size(-1))

    Hotkey('+WheelUp', (*) => Send('{WheelLeft}'))
    Hotkey('+WheelDown', (*) => Send('{{WheelRight}}'))
HotIf

list_columns := csv_columns.Clone()
list_columns.Push("rank")
list_column_locations := Map()
for col in list_columns
    list_column_locations[col] := A_Index

column_widths := Map(
    'name', 0.3, 'username', 0.25, 'url', 0.2, 'password', 0.05, 'rank', 0.02
)
column_widths.Default := 0.18 / (csv_columns.Length - required_columns.Length)

rows_count := -1 ; to skip the header row
loop read configuration['Settings']['1_passwords_csv_file']
    rows_count++

image_list := IL_Create(1 + required_columns.Length + rows_count, 1)
icons := Map(
    "rank", IL_Add(image_list, "imageres.dll", 254),
    "username", IL_Add(image_list, "imageres.dll", 125),
    "password", IL_Add(image_list, "imageres.dll", 301),
    "name", IL_Add(image_list, "imageres.dll", 205),
    "url", IL_Add(image_list, "imageres.dll", 171)
)
icons.Default := IL_Add(image_list, "imageres.dll", 95)

List_View := PM_GUI.AddListView("xm w600 h250 c555555 Count" rows_count " +Grid -Multi -E0x200 LV0x4000 LV0x40 LV0x800", list_columns)
List_View.OnEvent("ContextMenu", (lv_obj, row_number, *) => (show_context_menu(row_number)))
List_View.OnEvent("DoubleClick", double_click_account)
List_View.SetImageList(image_list, 1)

Status_Bar := PM_GUI.AddStatusBar()
Status_Bar.SetParts(100, 135, 150, 200, 135, 60, 80, 85, 220)
Status_Bar.SetText("Enter: copy account", 3)
Status_Bar.SetText("Ctrl+Enter: visit website", 4)
Status_Bar.SetText("Up/Down: navigate", 5)
Status_Bar.SetText("F1: Add", 6)
Status_Bar.SetText("F2: Modify", 7)
Status_Bar.SetText("F3: Delete", 8)
Status_Bar.SetText("Ctrl+WheelUp/WheelDown: zoom", 9)

for col, loc in list_column_locations
    List_View.ModifyCol(loc, "Icon" icons[col])

icons.Default := -1
search()
Search_Box.OnEvent("Change", (*) => search())

api := "http://www.google.com/s2/favicons?domain=", ico_file := A_Temp "\favicon.ico"
loop read configuration['Settings']['1_passwords_csv_file'] {
    if (A_Index = 1) ; Skip header
        continue
    loop parse A_LoopReadLine, "CSV" {
        if (A_Index = csv_column_locations["url"]) {
            domain := RegExReplace(A_LoopField, ".*://(.*?)/.*", "$1")
            if icons.Has(domain)
                break

            url := api . domain
            try {
                Download("*0 " url, ico_file) ; *0 allows browser caching, increasing overall speed 
                icons[domain] := IL_Add(image_list, ico_file)
            }
            break
        }
    }
    Status_Bar.SetText(icons.Count - required_columns.Length - 2 " icons loaded", 2)
}
try FileDelete(ico_file)
search()

if (configuration['Settings']['3_show_on_launch?'])
    show()

; =============================================================================
; --------------------------------- FUNCTIONS ---------------------------------
; =============================================================================

change_font_size(change) {
    global font_size += change
    List_View.SetFont('s' font_size)
}
resize_window(w, h) {
    Search_Box.Move(,, w - 120)
    Search_Box.Redraw()

    List_View.Opt("-Redraw")
    List_View.Move(,, w - 25, h - 70)
    for column in list_columns
        List_View.ModifyCol(A_Index, column_widths[column] * (w - 50))
    List_View.Opt("+Redraw")
}
delete_word(*) {
    if not Search_Box.Focused
        Search_Box.Focus()

    Send '^{Left}'
    Send '^{Delete}'
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
        else if List_View.GetText(1, list_column_locations['rank']) > List_View.GetText(2, list_column_locations['rank'])
            found := 1
    }
    if found {
        copy_account(1)
        ToolTip(List_View.GetText(1, list_column_locations["name"]))
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
        Settings_Gui.AddText("w250", format_key_name(key)).SetFont("underline bold")
		Settings_Gui.AddHotkey('wp v' key, value)
    }

	Tabs.UseTab('Recommendations')
    for key, value in configuration['Recommendations'] {
		Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline bold")

		text := StrReplace(value, ", ", "`n")
		Settings_Gui.AddEdit("wp r10 v" key, text)
    }

	Tabs.UseTab('Settings')
    for key, value in configuration['Settings'] {
        if InStr(key, "?")
            Settings_Gui.AddCheckbox("wp v" key " " (value ? "Checked" : ""), format_key_name(key)).SetFont("underline bold")
        else {
            Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline bold")
            Settings_Gui.AddEdit("wp Disabled v" key, value).SetFont("s10 bold")
            browse_button := Settings_Gui.AddButton("wp vbrowse_" key, "Browse")
            browse_button.OnEvent("Click", browse)
            browse_button.Description := "Choose the file or folder"
            GuiButtonIcon(browse_button, "imageres.dll", 206, "s20 R80 A4")
        }
    }

    Tabs.UseTab('Lens')
    for key, value in configuration['Lens'] {
        if InStr(key, "border_color") { ; 3_lens_border_color
            color_code := Settings_Gui.AddText("wp", "Lens Border Color: " value)
            color_code.SetFont("bold underline")
            color_demo := Settings_Gui.AddProgress("wp Range0-1 c" value, 1)

            for col in ["Red", "Green", "Blue"] {
                slider := Settings_Gui.AddSlider("wp NoTicks AltSubmit v" key "_" col " Range0-255", "0X" SubStr(value, 1 + (A_Index * 2), 2))
                slider.OnEvent("Change", update_color)
                slider.Description := col
            }
        }
        else {
            if InStr(key, "?") ; 5_save_lens_dimensions?
                Settings_Gui.AddCheckbox("wp v" key " " (value ? "Checked" : ""), format_key_name(key)).SetFont("underline bold")
            else if InStr(key, "border_width") {
                thickness_demo := Settings_Gui.AddText("wp v" key "_demo", format_key_name(key) ": " value)
                thickness_demo.SetFont("underline bold")
                thickness_slider := Settings_Gui.AddSlider("wp AltSubmit v" key " Range0-15 NoTicks", value)
                thickness_slider.OnEvent("Change", update_thickness)
                thickness_slider.Description := format_key_name(key)
            }
            else {
                Settings_Gui.AddText("wp", format_key_name(key)).SetFont("underline bold")
                Settings_Gui.AddEdit("wp v" key, value)
                Settings_Gui.AddUpDown("Range0-1000 Wrap", value)
            }
        }
    }

    Tabs.UseTab(0)
    submit_button := Settings_Gui.AddButton('w136 Default r2', "Save")
    submit_button.OnEvent("Click", submit_configuration)
    submit_button.SetFont("bold s12")
    submit_button.Description := "Apply & Save the changes"
    GuiButtonIcon(submit_button, "imageres.dll", 24, "s22 R90 A4")
    
    revert_button := Settings_Gui.AddButton('wp yp r2', "Revert")
    revert_button.OnEvent("Click", (*) => (Settings_Gui.Destroy(), open_settings()))
    revert_button.SetFont("bold s12")
    revert_button.Description := "Revert all changes"
    GuiButtonIcon(revert_button, "imageres.dll", 230, "s22 R90 A4")

    Settings_Gui.Show()
    Settings_Gui.OnEvent("Escape", (*) => Settings_Gui.Hide())

    SetTimer(show_descriptions, 250, -5)
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
    update_thickness(*) {
        thickness_demo.Text := format_key_name(thickness_slider.Name) ": " thickness_slider.Value
    }
    submit_configuration(*) {
        global configuration
        new_configuration := Settings_Gui.Submit()
    
        new_configuration.3_lens_border_color := Format("0x{:02X}{:02X}{:02X}", new_configuration.3_lens_border_color_Red, new_configuration.3_lens_border_color_Green, new_configuration.3_lens_border_color_Blue)
        
        for name, section in configuration {
            for key, value in section {
                if (new_configuration.%key% != value)
                    configuration[name][key] := new_configuration.%key%
            }
        }
    
        for name, section in configuration
            for key, value in section
                    IniWrite(StrReplace(value, "`n", ", "), config_file, name, key)
        Reload()
    }
}

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
    if not titles.Has(1)
        return
    
    if (InStr(titles[1], "Arc.exe -> ")) {
        WinActivate('ahk_exe Arc.exe')
        WinwaitActive('ahk_exe Arc.exe')

        A_Clipboard := ""
        loop 2 {
            Send '^+c'
            if ClipWait(1)
                break
        }

        domain := RegExReplace(A_Clipboard, ".*://(.*?)/.*", "$1")
        titles[1] := domain " -> " A_Clipboard
    }
    
    Search_Box.Delete()
    Search_Box.Add(titles)
    Search_Box.Text := old_text

    return titles
}
find_current_window(*) {
    list_all_windows()
    try Search_Box.Choose(1)
    
    rows := search(), found := 0
    if rows {
        if rows == 1
            found := 1
        else if List_View.GetText(1, list_column_locations['rank']) > List_View.GetText(2, list_column_locations['rank'])
            found := 1
        
        if found {
            copy_account(1)
            ToolTip(List_View.GetText(1, list_column_locations["name"]))
            SetTimer((*) => ToolTip(), -2000)
        }
        else
            show()
    } else
        lens()
}
show(*) {
    if not IsSet(List_View)
        return

    Critical "Off"
    PM_GUI.Show()
    PM_GUI.GetPos(, , &w, &h)
    resize_window(w - 14, h - 40)

    Search_Box.Focus()
    
    SetTimer(show_descriptions, 250, -5)
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

    try {
        loop read configuration['Settings']['1_passwords_csv_file'] {
            if A_Index = 1
                continue ; skip column headers

            csv_row := []
            loop parse A_LoopReadLine, "CSV"
                csv_row.Push(A_LoopField)

            rank := (Search_Box.Text = "")
            
            domain := RegExReplace(csv_row[csv_column_locations["url"]], ".*://(.*?)/.*", "$1")
            rank += (4 * (domain = app_name))
            
            name := RegExReplace(csv_row[csv_column_locations["name"]], "\.[^.]+(\.[^.]+)?$", "") ; remove .com, .net, .gov.eg, .gov.sa... from name field

            for word in StrSplit(name, delimiters)
                rank += (3 * (app_name = word))
            
            for keyword in keywords
                for word in StrSplit(name, delimiters)
                    if StrLen(keyword) > 0
                        rank += (Max(InStr(word, keyword) > 0, 2 * (word = keyword)))

            list_row := csv_row.Clone()
            list_row.Push(rank)
            if rank
                List_View.Add("Icon" icons[domain], list_row*)
        }
    } catch Error {
        IniWrite("Locate your passwords CSV file", config_file, 'Settings', '1_passwords_csv_file')
        Reload()    
    }

    if keywords.Length > 0
        List_View.ModifyCol(list_column_locations['rank'], "Integer SortDesc")
    else
        List_View.ModifyCol(list_column_locations['name'], "Sort")

    List_View.Modify(1, "Focus Select")
    List_View.Opt("+Redraw")

    try Status_Bar.SetText(" " List_View.GetCount() " results")

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
    
    username := List_View.GetText(row, list_column_locations["username"])
    password := List_View.GetText(row, list_column_locations["password"])

    SetTimer(clear_variable, -1000 * 60 * 5)
    clear_variable(*) {
        username := '`0'
        password := '`0'
    }
}
modify_account(row) {
    arr := []
    for col in list_columns
        arr.Push(List_View.GetText(row, A_Index))
    account_gui(arr)
}
show_context_menu(row) {
    context_menu := Menu()
    context_menu.Add("Go to website", (*) => run_website(List_View.GetNext(, "F")))
    context_menu.Add("Modify", (*) => modify_account(List_View.GetNext(, "F")))
    context_menu.Add("Delete", (*) => delete_account(List_View.GetNext(, 'F')))
    context_menu.Show()
}
run_website(row) {
    url := List_View.GetText(row, list_column_locations["url"])
    name := List_View.GetText(row, list_column_locations["name"])
    if (SubStr(url, 1, 4) == "http")
        Run url
    else if MsgBox("URL not found, do you want to search for it?", "Invalid URL", "Y/N") == "Yes"
            Run "https://www.google.com/search?q=" StrReplace(name, ' ', '+')
}
account_gui(found_account_array?) {
    New_Account_GUI := Gui(, "Account Editor")
    New_Account_GUI.SetFont("s10", 'Consolas')
    New_Account_GUI.OnEvent("Escape", (*) => New_Account_GUI.Destroy())

    Recommendations := Map()
    
    for column in csv_columns {
        if IsSet(found_account_array)
            Recommendations[column] := [found_account_array[list_column_locations[column]]]
        else
            Recommendations[column] := []
    }
    
	Recommendations["username"].Push(StrSplit(configuration['Recommendations']['1_recommended_usernames'], ", ")*)
	Recommendations["password"].Push(StrSplit(configuration['Recommendations']['2_recommended_passwords'], ", ")*)

    for column in csv_columns {
        New_Account_GUI.AddText("xm w200", column).SetFont("underline bold")
        New_Account_GUI.AddComboBox("xm wp v" column, Recommendations[column])
        if IsSet(found_account_array)
            New_Account_GUI[column].Value := 1
    }
    New_Account_GUI.AddButton("xm Default w97", "Submit").OnEvent("Click", (*) => submit_account(IsSet(found_account_array) ? List_View.GetNext(, "F") : unset))
    
    New_Account_GUI.AddButton("yp w97", "Cancel").OnEvent("Click", (*) => New_Account_GUI.Destroy())  
    New_Account_GUI.Show()
    return New_Account_GUI
    
    submit_account(old_account?) {
        submitted_account := New_Account_GUI.Submit()
        
        replace_text_in_file(IsSet(old_account) ? csv_format(old_account) : unset, csv_format(submitted_account))

        domain := RegExReplace(submitted_account.url, ".*://(.*?)/.*", "$1")
        url := api . domain
        if not icons.Has(domain) {
            try {
                Download("*0 " url, A_Temp "\new_favicon.ico")
                icons[domain] := IL_Add(image_list, A_Temp "\new_favicon.ico")
                FileDelete(A_Temp "\new_favicon.ico")
            }
        }

        search()
        sync_file()
    }
}
csv_format(source) {
    formatted_text := ""
    
    for column in csv_columns {
        if IsNumber(source) {
            formatted_text .= List_View.GetText(source, list_column_locations[column])
        }
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
replace_text_in_file(old_text?, new_text?, Filename := configuration['Settings']['1_passwords_csv_file']) {
    try {
        File_Text := FileRead(Filename)
    } catch Error {
        IniWrite("Locate your passwords CSV file", config_file, 'Settings', '1_passwords_csv_file')
        Reload()    
    }
    
    if IsSet(old_text)
        New_File_Text := StrReplace(File_Text, old_text, new_text, true,, 1)
    else
        New_File_Text := File_Text . new_text
    
    FileObj := FileOpen(Filename, "w `n")
    FileObj.Write(New_File_Text)
    FileObj.Close()
}
delete_account(row) {
    if (MsgBox("Are you sure you want to delete this account?",,"Y/N Default2") == "No")
        return

    replace_text_in_file(csv_format(row), "")

    search()
    sync_file()
}
sync_file(Filename := configuration['Settings']['1_passwords_csv_file'], destination := configuration['Settings']['2_sync_directory']) {
    if DirExist(destination)
        FileCopy(Filename, destination, true)
}

; source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=115871
; useful resource to find icon number: https://renenyffenegger.ch/development/Windows/PowerShell/examples/WinAPI/ExtractIconEx/shell32.html
GuiButtonIcon(Handle, File, Index := 1, Options := '') {
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
}
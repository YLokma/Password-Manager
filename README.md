# Password Manager (AutoHotkey)

This is a feature-rich Password Manager built using AutoHotkey (AHK). It allows users to manage their passwords, search for accounts, and perform various operations like adding, modifying, and deleting accounts. The program also includes advanced features like OCR-based text recognition, dynamic lens resizing, customizable border colors, and a user-friendly settings interface.

![image](https://github.com/user-attachments/assets/c3efab5d-a3f3-4999-b414-81504c795a79)

## Features

- **Password Management**: Add, modify, delete, and search for accounts.
- **Hotkey Support**: Activate the manager, copy usernames/passwords, and use the OCR lens with customizable hotkeys.
- **OCR Lens**: Extract text from the screen using OCR (Optical Character Recognition) with dynamic resizing and customizable border colors.
- **Customizable Settings**: Modify hotkeys, file paths, lens properties, and other configurations through a user-friendly GUI.
- **File Synchronization**: Sync the password CSV file to a specified directory.
- **Context Menu**: Perform actions like visiting the website or modifying/deleting an account, directly from the list view.
- **Search Functionality**: Search for accounts using keywords, website domains, application names, or OCR-extracted text with improved relevance scoring.
- **Find Current Account**: Automatically locate the account associated with the current application or website.
- **Add a New Account**: Automatically suggest the account details for the current application or website and allow the user to fill in their credentials.
- **Run on System Startup**: Optionally enable the program to run automatically when the system starts.
- **Show on Launch**: Optionally display the Password Manager GUI immediately after launching the program.

## Warning
**Use with extreme caution**: This app makes your passwords very vulnerable if someone else accesses your computer, **it is not secure at all**. Use it **only if** you are willing to take the risk. You are a very easy target if anyone knows that you save your passwords in a CSV file.

## How It Works

### 1. Configuration
The program reads its configuration from an `.ini` file (`PM settings.ini`). If the file does not exist, default settings are initialized. The settings include:
- Hotkeys for various actions.
- File paths for the password CSV file and sync directory.
- Lens dimensions, border color, and appearance.
- Options to run on system startup and show the GUI on launch.

### 2. Hotkeys
Hotkeys are defined in the settings and can be customized. The default hotkeys include:
- `Ctrl+Alt+Space`: Find the current app's account.
- `Alt+U`: Paste the username of the selected account.
- `Alt+P`: Paste the password of the selected account.
- `Alt+L`: Search for accounts using the OCR lens.

### 3. Password Management
Passwords are stored in a CSV file. The program reads this file to populate the list view. Users can:
- **Search**: Enter keywords, application names, or OCR-extracted text to find accounts.
- **Add** (`F1`): Add a new account with recommendations for usernames and passwords that can be configured in the settings gui.
- **Modify** (`F2`): Edit an existing account directly from the list view or context menu.
- **Delete** (`F3`): Remove an account after confirmation.

![image](https://github.com/user-attachments/assets/2ff8b260-be52-4471-b002-523eb3aac8a9)

### 4. Adding New Accounts
The "Add New Account" gui allows you to easily add a new account to your password manager.
- It can be accessed by pressing `F1` in the app or through the tray menu.
- It provides fields for entering the app/website name, URL, username, password, and any additional columns you have in your passwords file.
- It automatically suggests account names and URLs based on the currently opened applications or websites.
- It also shows a list of recommended usernames and passwords, which you can configure in the settings GUI.

![image](https://github.com/user-attachments/assets/a207ba9e-c270-45b3-ba7e-14255bad4f75)

### 5. OCR Lens
The OCR lens allows users to extract text from the screen. The lens dimensions and appearance can be adjusted dynamically using arrow keys:
- **Arrow Keys**: Resize the lens (width and height).
- **Esc**: Exit the lens mode without selecting text, cancelling the account finding operation.
- **Left Mouse Button**: Confirm the selection and extract text, then try to find the corresponding account.
- **Dynamic Border Color and Thickness**: Adjust the lens border thickness and color dynamically using RGB sliders in the settings GUI.

![image](https://github.com/user-attachments/assets/75eaebf2-5539-4e03-b40c-5969fb6ce85c)

The extracted text can be used to search for accounts or perform other actions.

### 6. Settings GUI
The settings GUI provides a tabbed interface to modify configurations:
- **Hotkeys**: Customize shortcuts for various actions.
- **Recommendations**: Manage recommended usernames and passwords.
- **Settings**: Configure file paths, toggle "Run on System Startup," and "Show on Launch."
- **Lens**: Adjust lens dimensions, border color, and other properties dynamically.

![image](https://github.com/user-attachments/assets/65d88add-34b8-4c5e-9027-07b7eab72ea2)

### 7. Synchronization
The program can sync the password CSV file to a specified directory. This ensures that the file is backed up or accessible from other locations.

![image](https://github.com/user-attachments/assets/b8467e61-25fc-4c3c-8347-74ac97ad7cb8)


## Usage

1. **Run the Script**: Launch the AutoHotkey script or the compiled executable.
2. **Add New Accounts**: Use the tray menu to add a new account in seconds.
3. **Find The Current Account**: Use the finder hotkey (`Ctrl+Alt+Space` by default) to find the current window or website's account. This feature matches the active window's title or tab URL with entries in the CSV file.
   > Note: for an optimal experience, make sure you can copy the current tab url using the shortcut `Ctrl+Alt+Shift+C` either through built-in support in the browser or by installing an extension similar to the following:
      [Copy Current URL](https://chromewebstore.google.com/detail/copy-current-url/okkmnbabeggdmakmnffkoflpdlkmmpcp),
      [Copy Markdown Link](https://chromewebstore.google.com/detail/copy-markdown-link/gkceaaphhbeanfciglgpffnncfpipjpa),
      [Copy Title and Url as Markdown Style](https://chromewebstore.google.com/detail/copy-title-and-url-as-mar/fpmbiocnfbjpajgeaicmnjnnokmkehil) 
4. **Search for Accounts**: Enter a search query in the search box to find accounts. The search results are ranked based on relevance.
5. **Perform Actions**:
   - Double-click an account to copy its username and password.
   - Use the context menu to visit the website, toggle default, or modify/delete the account.
6. **Use the OCR Lens**: Activate the lens (`Alt+L` by default) to extract text from the screen and search for the text it finds.
7. **Modify Settings**: Open the settings GUI to customize configurations.

## Requirements

- **AutoHotkey v2**: The script is written in AHK v2 and requires the corresponding runtime.
- **OCR Library**: The script includes an OCR library for text recognition. Ensure the library file (`OCR Library.ahk`) is in the same directory.
Note: neither requirement is needed when using the compiled (exe) version.

## File Structure

- `Password_Manager.ahk`: Main script file.
- `PM settings.ini`: Configuration file (auto-generated if not present).
- `OCR Library.ahk`: OCR library for text recognition.
- `passwords.csv`: CSV file containing all passwords and accounts (typically exported from Chrome).

or

- `Password_Manager.exe`: Main script file (compiled).
- `PM settings.ini`: Configuration file (auto-generated if not present).
- `passwords.csv`: CSV file containing all passwords and accounts (typically exported from Chrome).

### CSV Format

The `passwords.csv` file should follow this format:
| App/Website Name | URL             | Username       | Password       | (Optional Column) |
|------------------|-----------------|----------------|----------------|-------------------|
| Example_App      | https://app.com | example_user   | example_pass   | Optional note     |

The file should look like this:
```
name,url,username,password
Example_App1,https://app1.com,example_user1,example_pass1
Example_App2,https://app2.com,example_user2,example_pass2
Example_App3,https://app3.com,example_user3,example_pass3

```
![image](https://github.com/user-attachments/assets/85452d61-a42e-4e11-8598-550dea28564a)

- The columns can be rearranged, which will be reflected in the list view columns order.
- The "note" column is entirely optional and can be removed from the file.
- Every column name is case-sensitive and must follow the standard format shown above
- The last line in the csv must be empty. If not, please add a new line at the end

## Notes

- Ensure the `passwords.csv` file exists and is properly formatted.
- The program automatically saves changes to the configuration file and synchronizes the password file if a sync directory is specified.
- Lens dimensions and border colors are saved automatically if the "Save lens dimensions" option is enabled in the settings.
- If "Run on System Startup" is enabled, a shortcut is created in the system's startup folder. The shortcut is deleted if disabled.

## License

This program is provided as-is without any warranty. Use it at your own risk.

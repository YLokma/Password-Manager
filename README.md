# Password Manager (AutoHotkey)

This is a feature-rich Password Manager built using AutoHotkey (AHK). It allows users to securely manage their passwords, search for accounts, and perform various operations like adding, modifying, and deleting accounts. The program also includes advanced features like OCR-based text recognition, dynamic lens resizing, customizable border colors, and a user-friendly settings interface.

## Features

- **Password Management**: Add, modify, delete, and search for accounts.
- **Hotkey Support**: Activate the manager, copy usernames/passwords, and use the OCR lens with customizable hotkeys.
- **OCR Lens**: Extract text from the screen using OCR (Optical Character Recognition) with dynamic resizing and customizable border colors.
- **Customizable Settings**: Modify hotkeys, file paths, lens properties, and other configurations through a user-friendly GUI.
- **File Synchronization**: Sync the password CSV file to a specified directory.
- **Context Menu**: Perform actions like visiting the website or modifying/deleting an account, directly from the list view.
- **Search Functionality**: Search for accounts using keywords, website domains, application names, or OCR-extracted text with improved relevance scoring.
- **Find Current Account**: Automatically locate the account associated with the current application or website.

## How It Works

### 1. Configuration
The program reads its configuration from an `.ini` file (`PM settings.ini`). If the file does not exist, default settings are initialized. The settings include:
- Hotkeys for various actions.
- File paths for the password CSV file and sync directory.
- Lens dimensions, border color, and appearance.

### 2. Hotkeys
Hotkeys are defined in the settings and can be customized. The default hotkeys include:
- `Ctrl+Alt+Space`: Find the current app's account.
- `Alt+U`: Paste the username of the selected account.
- `Alt+P`: Paste the password of the selected account.
- `Alt+L`: Search for accounts using the OCR lens.

### 3. Password Management
Passwords are stored in a CSV file. The program reads this file to populate the list view. Users can:
- **Search**: Enter keywords, application names, or OCR-extracted text to find accounts.
- **Add**: Add a new account using a dedicated GUI with recommendations for usernames and passwords.
- **Modify**: Edit an existing account directly from the list view or context menu.
- **Delete**: Remove an account after confirmation.

### 4. OCR Lens
The OCR lens allows users to extract text from the screen. The lens dimensions and appearance can be adjusted dynamically using arrow keys:
- **Arrow Keys**: Resize the lens (width and height).
- **Esc**: Exit the lens mode without selecting text.
- **Left Mouse Button**: Confirm the selection and extract text.
- **Dynamic Border Color**: Adjust the lens border color dynamically using RGB sliders in the settings GUI.

The extracted text can be used to search for accounts or perform other actions.

### 5. Settings GUI
The settings GUI provides a tabbed interface to modify configurations:
- **Hotkeys**: Customize shortcuts for various actions.
- **Recommendations**: Manage recommended usernames and passwords.
- **Files and Sync**: Set the password CSV file path and sync directory.
- **Lens**: Adjust lens dimensions, border color, and other properties dynamically.

### 6. Synchronization
The program can sync the password CSV file to a specified directory. This ensures that the file is backed up or accessible from other locations.

## Usage

1. **Run the Script**: Launch the script using AutoHotkey or as a compiled executable.
2. **Find The Current Account**: Use the finder hotkey (`Ctrl+Alt+Space` by default) to find the current window or website's account. This feature matches the active window's title or URL with entries in the CSV file.
3. **Search for Accounts**: Enter a search query in the search box to find accounts. The search results are ranked based on relevance.
4. **Perform Actions**:
   - Double-click an account to copy its username and password.
   - Use the context menu to visit the website or modify/delete the account.
5. **Use the OCR Lens**: Activate the lens (`Alt+L` by default) to extract text from the screen and search for the text it finds.
6. **Modify Settings**: Open the settings GUI to customize configurations.

## Requirements

- **AutoHotkey v2**: The script is written in AHK v2 and requires the corresponding runtime.
- **OCR Library**: The script includes an OCR library for text recognition. Ensure the library file (`OCR Library.ahk`) is in the same directory.

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
The `passwords.csv` file must follow this format without the heding row:
| App/Website Name | URL             | Username       | Password       |
|------------------|-----------------|----------------|----------------|
| Example_App      | https://app.com | example_user   | example_pass   |

which looks like this:
```
Example_App1,https://app1.com,example_user1,example_pass1
Example_App2,https://app2.com,example_user2,example_pass2
Example_App3,https://app3.com,example_user3,example_pass3
```

## Notes

- Ensure the `passwords.csv` file exists and is properly formatted.
- The program automatically saves changes to the configuration file and synchronizes the password file if a sync directory is specified.
- Lens dimensions and border colors are saved automatically if the "Save lens dimensions" option is enabled in the settings.

## License

This program is provided as-is without any warranty. Use it at your own risk.

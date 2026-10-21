# QuickShare4All Revived 🚀

[English](README.md) | [Tiếng Việt](README.vi.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)

A dual-purpose toolkit designed to fix the two biggest limitations of Quick Share on Windows:
1. **Samsung Quick Share**: Enables the official app on **non-Galaxy Book devices** (Dell, HP, Lenovo, ASUS, Acer, custom desktops, etc.).
2. **Google Quick Share**: Restores the missing right-click **"Send with Quick Share" Explorer Context Menu** on standard Windows 10 & 11 installations.

> [!NOTE]
> **Author's Note**:  
> *"Built entirely with Google Antigravity. I'm not a developer—I just needed this thing to actually work on my PC. It finally does, so I'm sharing it here for anyone who might find it useful. Please don't ask me for tech support, because honestly, I wouldn't have a clue."*

---

## 📖 The Problem: A Tale of Two Quick Shares

On Windows, Quick Share exists in two distinct ecosystems, each with its own frustrating drawback:

| Edition | Compatibility | Context Menu ("Send with Quick Share") | The Problem |
| :--- | :--- | :--- | :--- |
| **Samsung Quick Share** | 🔒 **Galaxy Books Only** | ✅ Native (when supported) | Artificially locked to Samsung laptops; crashes/blocks on third-party PCs. |
| **Google Quick Share** | 🔓 **All Windows PCs** | ❌ **Missing on standard setups** | Sparse package/MSIX signature issues prevent Windows from registering the right-click menu. |

**QuickShare4All Revived** provides native, non-destructive solutions for both.

---

## 🛠️ Toolkits Included

### 1. 🔓 Samsung Quick Share Enabler (For Non-Galaxy Book Devices)
Historically, Samsung restricted its Windows app (`SAMSUNGELECTRONICSCoLtd.SamsungQuickShare`) by checking BIOS strings (`SystemManufacturer`). Modern versions (**v2.3+**) upgraded to Windows App SDK `EasClientDeviceInformation` API, breaking old registry spoofs (`QuickShare4All` / `GalaxyBookMask`).

#### The Discovery
Disassembling `QuickShareCore.dll` and `QuickShare.dll` via [REA](https://github.com/morluto/rea) revealed an undocumented internal bypass in `QSSystray.Utility.Helper.DeviceModelSupportChecker`:

```csharp
public static bool IsSamsungDevice()
{
    if (IsNonSamsungDeviceSupported())
    {
        LogHandler.LogMessage("All devices including non-Samsung, are supported.");
        return true; // Completely bypasses the manufacturer check!
    }
    return EasClientDeviceInformation.get_SystemManufacturer().ToLower().Contains("samsung");
}

public static bool IsNonSamsungDeviceSupported()
{
    return File.Exists(Path.Combine(localStatePath, "QuickShare_Non_Samsung_support.config"));
}
```

Placing `QuickShare_Non_Samsung_support.config` into the app's `LocalState` directory permanently triggers non-Samsung device mode—without binary modification or signature invalidation!

---

### 2. 🖱️ Google Quick Share Context Menu Enabler (For Windows 10 & 11)
Google Quick Share runs on all PCs, but standard Windows users do not get a right-click **"Send with Quick Share"** option in File Explorer because Google distributes its shell extension (`nearby_share_context_menu.dll`) inside an unregistered sparse MSIX package.

Our script registers a clean, native per-user Windows shell context menu that directly calls:
```
"C:\Program Files\Google\NearbyShare\nearby_share_launcher.exe" "%1"
```
providing instantaneous, seamless right-click sending for any file or folder.

---

## 🚀 Usage Guide

### Scenario A: You use Google Quick Share & want Right-Click Context Menu
1. Ensure **Google Quick Share** is installed (`nearby_share.exe`).
2. Open PowerShell and run:
   ```powershell
   .\scripts\install_google_context_menu.ps1
   ```
3. Right-click any file or folder in File Explorer and select **Send with Quick Share**.
4. *(To remove later)*: `.\scripts\uninstall_google_context_menu.ps1`

---

### Scenario B: You want to run Samsung Quick Share on a Non-Samsung PC
1. Install **Samsung Quick Share** from the Microsoft Store or via winget.
2. Open PowerShell and run:
   ```powershell
   .\scripts\enable_samsung_quickshare.ps1
   ```
   *(This creates the trigger file in `LocalState` and launches the daemon).*
3. *(Optional)*: If you also want a right-click Explorer context menu specifically for Samsung Quick Share:
   ```powershell
   .\scripts\install_samsung_context_menu.ps1
   ```
4. *(To remove Samsung context menu)*: `.\scripts\uninstall_samsung_context_menu.ps1`

---

## 📂 Project Structure

```text
QuickShare4All-Revived/
├── scripts/
│   ├── enable_samsung_quickshare.ps1        # Unlocks Samsung Quick Share on non-Galaxy Books
│   ├── install_google_context_menu.ps1      # Adds right-click menu for Google Quick Share
│   ├── uninstall_google_context_menu.ps1    # Removes Google Quick Share menu
│   ├── install_samsung_context_menu.ps1     # Adds right-click menu for Samsung Quick Share
│   ├── uninstall_samsung_context_menu.ps1   # Removes Samsung Quick Share menu
│   ├── send_to_quickshare.vbs               # Silent URI dispatcher for Samsung Quick Share
│   ├── install_google_context_menu.reg      # Manual registry template for Google
│   └── install_samsung_context_menu.reg     # Manual registry template for Samsung
├── research/
│   ├── disassemble_checker.ps1              # Disassembly tool for DeviceModelSupportChecker
│   ├── dump_il.ps1                          # IL extraction tool
│   ├── find_callers.ps1                     # Call graph tracer
│   ├── inspect_checker_methods.ps1          # Reflection metadata inspector
│   └── inspect_verb.js                      # Protocol verb inspector
├── .gitignore
├── LICENSE
├── README.md                                # English documentation
└── README.vi.md                             # Vietnamese documentation
```

---

## ⚖️ Legal Disclaimer

- **No Proprietary Code Distributed**: This repository does **not** host, redistribute, or modify any copyrighted binaries, DLLs, or assets belonging to Samsung Electronics Co., Ltd. or Google LLC.
- **Interoperability & Research**: All scripts and findings provided here were developed solely for educational and interoperability purposes in accordance with **17 U.S.C. § 1201(f)** (Reverse Engineering for Interoperability) and **EU Directive 2009/24/EC (Article 6)**.
- **Trademarks**: "Samsung", "Galaxy Book", "Google", and "Quick Share" are trademarks of their respective owners. This project is independent and has no affiliation with, endorsement by, or sponsorship from Samsung or Google.

---

## 📄 License

Distributed under the [MIT License](LICENSE).

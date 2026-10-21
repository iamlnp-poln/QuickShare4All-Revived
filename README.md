# QuickShare4All Revived 🚀

[English](README.md) | [Tiếng Việt](README.vi.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)

A lightweight enabler and Windows Explorer Context Menu integration for **Samsung Quick Share** on non-Samsung PCs (Dell, HP, Lenovo, ASUS, Acer, custom desktops, etc.).

> [!NOTE]
> **Author's Note**:  
> *"Built entirely with Google Antigravity. I'm not a developer—I just needed this thing to actually work on my PC. It finally does, so I'm sharing it here for anyone who might find it useful. Please don't ask me for tech support, because honestly, I wouldn't have a clue."*

---

## 📖 Background & Problem

On Windows, Quick Share exists in two separate editions:

| Feature | Samsung Quick Share | Google Quick Share |
| :--- | :--- | :--- |
| **Hardware Restriction** | 🔒 Historically locked to Samsung Galaxy Books | 🔓 Works on all Windows PCs |
| **Context Menu ("Share with")** | ✅ Native Explorer integration | ❌ Missing on standard installs |
| **ShareTarget API** | ✅ Fully supported | ❌ Registration issues on Windows 11 |

Previous community workarounds (e.g., the original `QuickShare4All` or `GalaxyBookMask`) relied on spoofing BIOS registry values (`SystemManufacturer` / `SystemProductName`). With Samsung Quick Share **v2.3+**, Samsung shifted hardware verification to the modern Windows App SDK `EasClientDeviceInformation` API, rendering all registry-spoofing techniques obsolete.

Through non-destructive reverse engineering with [REA (Reverse Engineer Anything)](https://github.com/morluto/rea), we discovered an internal developer override switch embedded directly inside Samsung's binaries, alongside the proprietary URI scheme used to trigger file transfers from File Explorer.

---

## 🔍 Reverse Engineering Findings

### 1. The Undocumented Non-Samsung PC Bypass
Disassembling `QuickShareCore.dll` and `QuickShare.dll` revealed the verification routine inside `QSSystray.Utility.Helper.DeviceModelSupportChecker`:

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
    // Checks for the existence of this configuration file:
    return File.Exists(Path.Combine(localStatePath, "QuickShare_Non_Samsung_support.config"));
}
```

> **The Solution**: Creating an empty file named `QuickShare_Non_Samsung_support.config` in the app's `LocalState` directory permanently triggers non-Samsung device mode—without patching binaries, altering code, or invalidating digital signatures!

### 2. Explorer Context Menu URI Protocol
Inspecting `ExplorerCommandVerb.dll` revealed the URI schema Windows Explorer uses to dispatch files to Quick Share:

```
quickshare://pc/send?fileList=<FilePath1><FilePath2>
```
- **Single file**: `quickshare://pc/send?fileList=C:\path\to\document.pdf`
- **Multiple files**: Joined using the `<` delimiter.

---

## 🚀 Installation & Usage

### Prerequisites
1. Install **Samsung Quick Share** on your PC (from the Microsoft Store or via winget).
2. Ensure both Wi-Fi and Bluetooth are turned on.

### 1. Enable Quick Share on Your PC
Open PowerShell and run:
```powershell
.\scripts\enable_samsung_quickshare.ps1
```
This script will automatically:
- Locate the Samsung Quick Share AppX `LocalState` directory.
- Generate `QuickShare_Non_Samsung_support.config`.
- Start the background service and daemon process.

### 2. Add "Share with Quick Share" to File Explorer
To register the right-click context menu:
```powershell
.\scripts\install_context_menu.ps1
```
You can now right-click any file or folder in File Explorer and choose **Share with Quick Share**.

### 3. Uninstall Context Menu
To cleanly remove the context menu integration:
```powershell
.\scripts\uninstall_context_menu.ps1
```

---

## 📂 Project Structure

```text
QuickShare4All-Revived/
├── scripts/
│   ├── enable_samsung_quickshare.ps1    # Main enabler script
│   ├── install_context_menu.ps1         # Registers right-click Explorer context menu
│   ├── uninstall_context_menu.ps1       # Cleans up context menu entries
│   ├── send_to_quickshare.vbs           # Silent background URI dispatcher
│   ├── install_context_menu.reg         # Manual registry import template
│   └── uninstall_context_menu.reg       # Manual registry cleanup
├── research/
│   ├── disassemble_checker.ps1          # Disassembly tool for DeviceModelSupportChecker
│   ├── dump_il.ps1                      # IL disassembly extraction
│   ├── find_callers.ps1                 # Call graph tracer
│   ├── inspect_checker_methods.ps1      # Reflection metadata inspector
│   ├── inspect_driver_check.ps1         # Driver requirement verification
│   └── inspect_verb.js                  # Explorer verb protocol inspector
├── .gitignore
├── LICENSE
├── README.md                            # English documentation
└── README.vi.md                         # Vietnamese documentation
```

---

## ⚖️ Legal Disclaimer

- **No Proprietary Code Distributed**: This repository does **not** host, redistribute, or modify any copyrighted binaries, DLLs, or assets belonging to Samsung Electronics Co., Ltd. or Google LLC.
- **Interoperability & Research**: All scripts and findings provided here were developed solely for educational and interoperability purposes in accordance with **17 U.S.C. § 1201(f)** (Reverse Engineering for Interoperability) and **EU Directive 2009/24/EC (Article 6)**.
- **Trademarks**: "Samsung", "Galaxy Book", "Google", and "Quick Share" are trademarks of their respective owners. This project is independent and has no affiliation with, endorsement by, or sponsorship from Samsung or Google.

---

## 📄 License

Distributed under the [MIT License](LICENSE).

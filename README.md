# QuickShare4All Revived 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)

A lightweight enabler and Windows Explorer Context Menu integration for **Samsung Quick Share** on non-Samsung PCs (Dell, HP, Lenovo, ASUS, Acer, custom builds, etc.).

---

## 📖 Background & Problem

On Windows, Quick Share exists in two different ecosystems:

| Feature | Samsung Quick Share | Google Quick Share |
| :--- | :--- | :--- |
| **Hardware Restriction** | 🔒 Locked to Samsung Galaxy Books (historically) | 🔓 Works on all Windows PCs |
| **Context Menu ("Share with")** | ✅ Native Explorer integration | ❌ Missing on standard installs |
| **ShareTarget API** | ✅ Supported | ❌ Registration issues on Win 11 |

Previous community workarounds (e.g., legacy `QuickShare4All` or `GalaxyBookMask`) attempted to spoof BIOS registry keys (`SystemManufacturer` / `SystemProductName`). However, with Samsung Quick Share **v2.3+**, Samsung upgraded their hardware checks to use the modern Windows App SDK `EasClientDeviceInformation` API, rendering registry spoofing obsolete.

Through reverse-engineering with [REA (Reverse Engineer Anything)](https://github.com/morluto/rea), we identified a native, non-destructive backdoor left by developers inside Samsung's binaries, as well as the proprietary URI protocol used for File Explorer context menu dispatching.

---

## 🔍 Reverse Engineering Findings

### 1. The Undocumented Non-Samsung PC Bypass
Disassembly of `QuickShareCore.dll` and `QuickShare.dll` revealed the verification routine inside `QSSystray.Utility.Helper.DeviceModelSupportChecker`:

```csharp
public static bool IsSamsungDevice()
{
    if (IsNonSamsungDeviceSupported())
    {
        LogHandler.LogMessage("All devices including non-Samsung, are supported.");
        return true; // Bypass Samsung manufacturer check entirely!
    }
    return EasClientDeviceInformation.get_SystemManufacturer().ToLower().Contains("samsung");
}

public static bool IsNonSamsungDeviceSupported()
{
    // Checks for presence of config file:
    return File.Exists(Path.Combine(localStatePath, "QuickShare_Non_Samsung_support.config"));
}
```

> **Result**: Creating an empty file named `QuickShare_Non_Samsung_support.config` in the app's `LocalState` directory permanently triggers non-Samsung device mode without modifying any binaries or violating digital signatures!

### 2. Explorer Context Menu URI Protocol
Analyzing `ExplorerCommandVerb.dll` revealed the URI schema used to send files directly to Quick Share:

```
quickshare://pc/send?fileList=<FilePath1><FilePath2>
```
- **Single file**: `quickshare://pc/send?fileList=C:\path\to\document.pdf`
- **Multiple files**: Joined using the `<` delimiter.

---

## 🚀 Installation & Usage

### Prerequisites
1. Ensure **Samsung Quick Share** is installed on your Windows PC (via Microsoft Store or winget).
2. Wi-Fi and Bluetooth enabled.

### 1. Enable Quick Share on Your PC
Open PowerShell and run:
```powershell
.\scripts\enable_samsung_quickshare.ps1
```
This script automatically:
- Locates your Samsung Quick Share AppX `LocalState` directory.
- Creates `QuickShare_Non_Samsung_support.config`.
- Starts the Quick Share background service and daemon.

### 2. Add "Share with Quick Share" to File Explorer
To enable right-click context menu integration:
```powershell
.\scripts\install_context_menu.ps1
```
Now, right-click any file or folder in File Explorer and select **Share with Quick Share**.

### 3. Uninstall Context Menu
To cleanly remove the context menu entries:
```powershell
.\scripts\uninstall_context_menu.ps1
```

---

## 📂 Project Structure

```text
QuickShare4All/
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
└── README.md
```

---

## ⚖️ Legal Disclaimer

- **No Proprietary Code Distributed**: This repository does **not** contain, distribute, or modify any copyrighted binaries, DLLs, or assets belonging to Samsung Electronics Co., Ltd. or Google LLC.
- **Interoperability & Research**: All research and scripts provided herein are developed solely for interoperability and educational purposes in accordance with **17 U.S.C. § 1201(f)** (Reverse Engineering for Interoperability) and **EU Directive 2009/24/EC (Article 6)**.
- **Trademarks**: "Samsung", "Galaxy Book", "Google", and "Quick Share" are trademarks of their respective owners. This project is not affiliated with, endorsed by, or sponsored by Samsung or Google.

---

## 📄 License

Distributed under the [MIT License](LICENSE).

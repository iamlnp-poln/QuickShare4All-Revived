# QuickShare4All Revived 🚀

[English](README.md) | [Tiếng Việt](README.vi.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)

Bộ công cụ kép giải quyết triệt để 2 sự ức chế lớn nhất của Quick Share trên Windows:
1. **Samsung Quick Share**: Kích hoạt ứng dụng chính chủ chạy mượt mà trên **các thiết bị không phải Galaxy Book** (Dell, HP, Lenovo, ASUS, Acer, PC tự ráp,...).
2. **Google Quick Share**: Bổ sung tùy chọn chuột phải **"Send with Quick Share" trong File Explorer Context Menu** vốn bị thiếu trên các bản Windows 10 & 11 tiêu chuẩn.

> [!NOTE]
> **Tâm sự mỏng**:  
> *"t làm bằng antigravity. t ngu code. t chỉ cần nó chạy. bây h nó chạy đc nên t share. đừng hỏi j hết"*

---

## 📖 Bối cảnh: Câu chuyện 2 phiên bản Quick Share

Trên Windows, Quick Share tồn tại dưới hai phiên bản độc lập do Samsung và Google phát hành, nhưng bản nào cũng có "hạt sạn" riêng:

| Phiên bản | Khả năng tương thích | Menu chuột phải ("Send with Quick Share") | Vấn đề cốt lõi |
| :--- | :--- | :--- | :--- |
| **Samsung Quick Share** | 🔒 **Chỉ Galaxy Book** | ✅ Có sẵn (nếu là Galaxy Book) | Bị Samsung khóa cứng phần cứng; chặn không cho máy hãng khác chạy. |
| **Google Quick Share** | 🔓 **Mọi PC Windows** | ❌ **Bị thiếu trên máy thường** | Gói MSIX sparse package bị lỗi chứng chỉ/đăng ký khiến Windows không hiện menu chuột phải. |

**QuickShare4All Revived** cung cấp giải pháp an toàn, không can thiệp mã nhị phân cho cả hai vấn đề trên.

---

## 🛠️ Chi tiết 2 bộ công cụ

### 1. 🔓 Kích hoạt Samsung Quick Share trên máy không phải Galaxy Book
Trước đây, Samsung chặn máy hãng khác bằng cách kiểm tra BIOS Registry (`SystemManufacturer`). Các phiên bản mới (**v2.3+**) đã nâng cấp lên kiểm tra qua API `EasClientDeviceInformation` của Windows App SDK, khiến các script cũ (`QuickShare4All` / `GalaxyBookMask`) bị vô hiệu hóa hoàn toàn.

#### Phát hiện kỹ thuật đảo ngược
Phân tích `QuickShareCore.dll` và `QuickShare.dll` bằng [REA](https://github.com/morluto/rea) đã phát hiện ra cơ chế "cửa sau" mà chính lập trình viên Samsung để lại trong `QSSystray.Utility.Helper.DeviceModelSupportChecker`:

```csharp
public static bool IsSamsungDevice()
{
    if (IsNonSamsungDeviceSupported())
    {
        LogHandler.LogMessage("All devices including non-Samsung, are supported.");
        return true; // Bỏ qua hoàn toàn việc kiểm tra máy Samsung!
    }
    return EasClientDeviceInformation.get_SystemManufacturer().ToLower().Contains("samsung");
}

public static bool IsNonSamsungDeviceSupported()
{
    return File.Exists(Path.Combine(localStatePath, "QuickShare_Non_Samsung_support.config"));
}
```

Chỉ cần tạo file `QuickShare_Non_Samsung_support.config` trong thư mục `LocalState` của ứng dụng, Samsung Quick Share sẽ tự động chuyển sang chế độ hỗ trợ mọi dòng máy—không cần patch file, không làm mất chữ ký số!

---

### 2. 🖱️ Kích hoạt Menu chuột phải cho Google Quick Share
Bản Google Quick Share cài được trên mọi máy Windows, nhưng người dùng thường **không có menu ngữ cảnh chuột phải** khi bấm vào file/thư mục. Nguyên nhân là Google đóng gói phần mở rộng shell (`nearby_share_context_menu.dll`) trong một gói sparse MSIX chưa được cấp chứng chỉ dev trên Windows tiêu chuẩn.

Script của chúng tôi đăng ký trực tiếp menu ngữ cảnh chuẩn của Windows Explorer trỏ thẳng đến:
```
"C:\Program Files\Google\NearbyShare\nearby_share_launcher.exe" "%1"
```
Giúp bạn có thể click chuột phải vào bất kỳ tệp hoặc thư mục nào để bắn file qua Google Quick Share ngay lập tức!

---

## 🚀 Hướng dẫn Sử dụng

### Trường hợp A: Bạn dùng Google Quick Share & muốn có Menu chuột phải
1. Đảm bảo máy đã cài đặt **Google Quick Share** (`nearby_share.exe`).
2. Mở PowerShell và chạy:
   ```powershell
   .\scripts\install_google_context_menu.ps1
   ```
3. Chuột phải vào bất kỳ file hoặc thư mục nào và chọn **Send with Quick Share**.
4. *(Nếu muốn gỡ bỏ)*: `.\scripts\uninstall_google_context_menu.ps1`

---

### Trường hợp B: Bạn muốn chạy Samsung Quick Share trên máy không phải Samsung
1. Cài đặt **Samsung Quick Share** từ Microsoft Store hoặc winget.
2. Mở PowerShell và chạy:
   ```powershell
   .\scripts\enable_samsung_quickshare.ps1
   ```
   *(Script sẽ tự tạo file config mở khóa trong `LocalState` và khởi động dịch vụ).*
3. *(Tùy chọn)*: Nếu muốn thêm menu chuột phải riêng cho bản Samsung:
   ```powershell
   .\scripts\install_samsung_context_menu.ps1
   ```
4. *(Nếu muốn gỡ menu của Samsung)*: `.\scripts\uninstall_samsung_context_menu.ps1`

---

## 📂 Cấu trúc Thư mục

```text
QuickShare4All-Revived/
├── scripts/
│   ├── enable_samsung_quickshare.ps1        # Mở khóa Samsung Quick Share trên máy non-Galaxy Book
│   ├── install_google_context_menu.ps1      # Thêm menu chuột phải cho Google Quick Share
│   ├── uninstall_google_context_menu.ps1    # Gỡ menu chuột phải của Google Quick Share
│   ├── install_samsung_context_menu.ps1     # Thêm menu chuột phải cho Samsung Quick Share
│   ├── uninstall_samsung_context_menu.ps1   # Gỡ menu chuột phải của Samsung Quick Share
│   ├── send_to_quickshare.vbs               # Script chuyển tiếp URI ngầm cho bản Samsung
│   ├── install_google_context_menu.reg      # File Registry mẫu cho Google
│   └── install_samsung_context_menu.reg     # File Registry mẫu cho Samsung
├── research/
│   ├── disassemble_checker.ps1              # Script dịch ngược DeviceModelSupportChecker
│   ├── dump_il.ps1                          # Script trích xuất mã IL
│   ├── find_callers.ps1                     # Truy vết luồng gọi hàm
│   ├── inspect_checker_methods.ps1          # Soi reflection metadata
│   └── inspect_verb.js                      # Phân tích verb protocol
├── .gitignore
├── LICENSE
├── README.md                                # Tài liệu tiếng Anh
└── README.vi.md                             # Tài liệu tiếng Việt
```

---

## ⚖️ Tuyên bố Pháp lý (Legal Disclaimer)

- **Không phân phối mã độc quyền**: Kho mã nguồn này **không** lưu trữ, phân phối lại hay sửa đổi bất kỳ tệp nhị phân, DLL hay tài sản có bản quyền nào của Samsung Electronics Co., Ltd. hoặc Google LLC.
- **Tính tương thích & Nghiên cứu giáo dục**: Mọi công cụ và phân tích trong tài liệu này được thực hiện vì mục đích học hỏi và đảm bảo tính tương thích hệ thống theo quy định tại **17 U.S.C. § 1201(f)** (Ngoại lệ Kỹ thuật đảo ngược vì tính tương thích) và **Chỉ thị của Liên minh Châu Âu EU Directive 2009/24/EC (Điều 6)**.
- **Thương hiệu**: Các tên gọi "Samsung", "Galaxy Book", "Google" và "Quick Share" là nhãn hiệu thuộc quyền sở hữu của các tổ chức tương ứng. Dự án này hoàn toàn độc lập và không liên kết, không được bảo trợ bởi Samsung hay Google.

---

## 📄 Giấy phép

Phát hành theo [Giấy phép MIT](LICENSE).

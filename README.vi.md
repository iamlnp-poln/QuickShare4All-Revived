# QuickShare4All Revived 🚀

[English](README.md) | [Tiếng Việt](README.vi.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://github.com/PowerShell/PowerShell)

Bộ công cụ kích hoạt và tích hợp Menu chuột phải (Context Menu) cho **Samsung Quick Share** trên các dòng PC/Laptop không phải của Samsung (Dell, HP, Lenovo, ASUS, Acer, PC tự build,...).

> [!NOTE]
> **Tâm sự mỏng**:  
> *"t làm bằng antigravity. t ngu code. t chỉ cần nó chạy. bây h nó chạy đc nên t share. đừng hỏi j hết"*

---

## 📖 Bối cảnh & Vấn đề

Trên hệ điều hành Windows hiện nay, tính năng Quick Share tồn tại dưới hai phiên bản khác nhau:

| Tính năng | Samsung Quick Share | Google Quick Share |
| :--- | :--- | :--- |
| **Giới hạn phần cứng** | 🔒 Bị khóa độc quyền cho dòng Samsung Galaxy Book | 🔓 Hoạt động trên mọi dòng máy Windows |
| **Menu ngữ cảnh ("Share with")** | ✅ Tích hợp sẵn chuột phải trên File Explorer | ❌ Không có sẵn trên các bản cài tiêu chuẩn |
| **Hỗ trợ ShareTarget API** | ✅ Đầy đủ | ❌ Hay gặp lỗi đăng ký trên Windows 11 |

Trước đây, cộng đồng từng sử dụng các script như `QuickShare4All` hoặc `GalaxyBookMask` nhằm làm giả (spoof) thông tin nhà sản xuất trong Registry BIOS (`SystemManufacturer` / `SystemProductName`). Tuy nhiên, từ phiên bản **v2.3+**, Samsung đã chuyển sang kiểm tra phần cứng bằng API hiện đại `EasClientDeviceInformation` của Windows App SDK, khiến toàn bộ các phương pháp fake Registry trước đó hoàn toàn vô tác dụng.

Bằng phương pháp kỹ thuật đảo ngược (reverse engineering) an toàn thông qua [REA (Reverse Engineer Anything)](https://github.com/morluto/rea), chúng tôi đã phát hiện ra một công tắc nội bộ do chính lập trình viên của Samsung để lại bên trong mã nguồn, cùng với cấu trúc giao thức URI mà Windows Explorer dùng để gửi file.

---

## 🔍 Phát hiện Kỹ thuật Đảo ngược

### 1. "Cửa sau" mở khóa PC không phải Samsung
Khi phân tích và dịch ngược hai thư viện `QuickShareCore.dll` và `QuickShare.dll`, chúng tôi tìm thấy quy trình kiểm tra nằm trong lớp `QSSystray.Utility.Helper.DeviceModelSupportChecker`:

```csharp
public static bool IsSamsungDevice()
{
    if (IsNonSamsungDeviceSupported())
    {
        LogHandler.LogMessage("All devices including non-Samsung, are supported.");
        return true; // Vượt qua hoàn toàn bước kiểm tra nhà sản xuất Samsung!
    }
    return EasClientDeviceInformation.get_SystemManufacturer().ToLower().Contains("samsung");
}

public static bool IsNonSamsungDeviceSupported()
{
    // Kiểm tra sự tồn tại của file cấu hình này:
    return File.Exists(Path.Combine(localStatePath, "QuickShare_Non_Samsung_support.config"));
}
```

> **Giải pháp**: Chỉ cần tạo một file rỗng mang tên `QuickShare_Non_Samsung_support.config` đặt vào thư mục `LocalState` của ứng dụng, Quick Share sẽ tự động chuyển sang chế độ hỗ trợ tất cả các thiết bị—hoàn toàn không cần vá mã nhị phân, không chỉnh sửa file hệ thống và không làm mất chữ ký số gốc của Samsung!

### 2. Giao thức URI kích hoạt chia sẻ từ chuột phải
Phân tích thư viện `ExplorerCommandVerb.dll` giúp phục hồi cú pháp URI mà File Explorer sử dụng để gửi danh sách tệp trực tiếp đến Quick Share:

```
quickshare://pc/send?fileList=<ĐườngDẫnFile1><ĐườngDẫnFile2>
```
- **Gửi 1 file**: `quickshare://pc/send?fileList=C:\duong-dan\tai-lieu.pdf`
- **Gửi nhiều file**: Nối tiếp nhau bằng ký tự `<`.

---

## 🚀 Cài đặt & Sử dụng

### Yêu cầu trước khi cài
1. Máy tính đã cài đặt **Samsung Quick Share** (tải qua Microsoft Store hoặc winget).
2. Đã bật sẵn kết nối Wi-Fi và Bluetooth trên máy.

### 1. Kích hoạt Quick Share cho máy tính của bạn
Mở PowerShell và chạy lệnh:
```powershell
.\scripts\enable_samsung_quickshare.ps1
```
Script sẽ tự động:
- Xác định thư mục `LocalState` của Samsung Quick Share AppX trên máy bạn.
- Tạo file kích hoạt `QuickShare_Non_Samsung_support.config`.
- Khởi chạy tiến trình dịch vụ ngầm và giao diện Quick Share.

### 2. Thêm tính năng "Share with Quick Share" vào chuột phải
Để đăng ký menu ngữ cảnh trên File Explorer:
```powershell
.\scripts\install_context_menu.ps1
```
Bây giờ bạn chỉ cần click chuột phải vào bất kỳ file hoặc thư mục nào trong File Explorer rồi chọn **Share with Quick Share**.

### 3. Gỡ bỏ Menu chuột phải
Nếu không muốn sử dụng menu chuột phải nữa, bạn có thể gỡ sạch sẽ bằng lệnh:
```powershell
.\scripts\uninstall_context_menu.ps1
```

---

## 📂 Cấu trúc Dự án

```text
QuickShare4All-Revived/
├── scripts/
│   ├── enable_samsung_quickshare.ps1    # Script kích hoạt chính
│   ├── install_context_menu.ps1         # Đăng ký menu chuột phải File Explorer
│   ├── uninstall_context_menu.ps1       # Gỡ bỏ menu chuột phải
│   ├── send_to_quickshare.vbs           # Dispatcher gọi URI ngầm (không nháy cửa sổ console)
│   ├── install_context_menu.reg         # File mẫu import Registry thủ công
│   └── uninstall_context_menu.reg       # File xóa Registry thủ công
├── research/
│   ├── disassemble_checker.ps1          # Công cụ dịch ngược DeviceModelSupportChecker
│   ├── dump_il.ps1                      # Trích xuất mã byte IL
│   ├── find_callers.ps1                 # Truy vết luồng gọi hàm
│   ├── inspect_checker_methods.ps1      # Soi reflection metadata
│   ├── inspect_driver_check.ps1         # Kiểm tra điều kiện driver
│   └── inspect_verb.js                  # Phân tích giao thức verb Explorer
├── .gitignore
├── LICENSE
├── README.md                            # Tài liệu tiếng Anh
└── README.vi.md                         # Tài liệu tiếng Việt
```

---

## ⚖️ Tuyên bố Pháp lý (Legal Disclaimer)

- **Không phân phối mã độc quyền**: Kho mã nguồn này **không** lưu trữ, phân phối lại hay sửa đổi bất kỳ tệp nhị phân, DLL hay tài sản có bản quyền nào của Samsung Electronics Co., Ltd. hoặc Google LLC.
- **Tính tương thích & Nghiên cứu giáo dục**: Mọi công cụ và phân tích trong tài liệu này được thực hiện vì mục đích học hỏi và đảm bảo tính tương thích hệ thống theo quy định tại **17 U.S.C. § 1201(f)** (Ngoại lệ Kỹ thuật đảo ngược vì tính tương thích) và **Chỉ thị của Liên minh Châu Âu EU Directive 2009/24/EC (Điều 6)**.
- **Thương hiệu**: Các tên gọi "Samsung", "Galaxy Book", "Google" và "Quick Share" là nhãn hiệu thuộc quyền sở hữu của các tổ chức tương ứng. Dự án này hoàn toàn độc lập và không liên kết, không được bảo trợ bởi Samsung hay Google.

---

## 📄 Giấy phép

Phát hành theo [Giấy phép MIT](LICENSE).

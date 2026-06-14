# Hướng dẫn Deploy Game Caro lên GitHub Pages

Ứng dụng cờ Caro đã được cấu hình tự động deploy lên **GitHub Pages** sử dụng **GitHub Actions**. Mỗi khi có code mới được đẩy (push) lên nhánh `master`, hệ thống sẽ tự động build bản Web và cập nhật lên trang chạy online.

## 1. Các file đã được tạo / chỉnh sửa

- **[.github/workflows/deploy.yml](file:///d:/uuuu/.github/workflows/deploy.yml)** [NEW]: Tệp cấu hình GitHub Actions thực hiện:
  - Tải mã nguồn & cấu hình môi trường Flutter (nhánh stable).
  - Cài đặt các thư viện phụ thuộc (`flutter pub get`).
  - Build bản web chế độ Release với base-href đặt là `/uuuu/` để chạy đúng trên thư mục con của GitHub Pages.
  - Tải lên (upload) và triển khai (deploy) bản build web trực tiếp lên GitHub Pages.
- **[DEPLOYMENT_NOTE.md](file:///d:/uuuu/DEPLOYMENT_NOTE.md)** [NEW]: Tệp ghi chú hướng dẫn chạy và deploy này.

---

## 2. Các lệnh GitHub CLI đã sử dụng

Chúng tôi đã cấu hình trực tiếp từ máy của bạn bằng các lệnh sau:
1. **Kiểm tra trạng thái xác thực**:
   ```bash
   gh auth status
   ```
2. **Kích hoạt GitHub Pages thông qua API với chế độ build bằng GitHub Actions**:
   ```bash
   gh api -X POST /repos/janyrollzone/uuuu/pages -f build_type="workflow"
   ```

---

## 3. Các thao tác thủ công (Nếu cần)

Mọi cấu hình triển khai tự động **đã được thiết lập thành công**. 
- Bạn chỉ cần đẩy các thay đổi lên GitHub bằng lệnh `git push origin master`.
- Bạn có thể theo dõi tiến độ chạy build & deploy tại tab **Actions** trên GitHub: [https://github.com/janyrollzone/uuuu/actions](https://github.com/janyrollzone/uuuu/actions)

---

## 4. Đường link chạy game online

Sau khi quá trình Build & Deploy của GitHub Actions hoàn tất, game cờ Caro của bạn sẽ chạy trực tuyến tại địa chỉ:
👉 **[https://janyrollzone.github.io/uuuu/](https://janyrollzone.github.io/uuuu/)**

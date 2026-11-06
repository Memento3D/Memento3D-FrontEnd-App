# Luồng model/custom đồng bộ với web — 06/11/2026

## Cập nhật đặt sản xuất custom

Đã nối `CustomPrintCheckoutScreen` từ workspace sau khi lưu. POST `/api/v1/orders` gửi `modelOutputId`, `fitResultId`, `customizationRevision`, `requestedHeightCm`, địa chỉ/điện thoại và `idempotencyKey` có tiền tố `custom:`; không gửi giá client. Yêu cầu đang chờ được giữ trên thiết bị để retry nguyên payload/key.

`OrderDetailScreen` hiển thị `FrozenOrderDesignPanel`, đọc `/api/v1/orders/{orderId}/custom-design`, xem GLB của đúng bản trong đơn và theo dõi trạng thái xuất/duyệt. Báo giá phải được chấp thuận qua `/accept-quote` mới hiện thanh toán custom. VNPAY dùng `/api/v1/payments/vnpay/create`; return URL đi qua BE verify, sau đó app đọc lại đơn để xác nhận trạng thái.

Phần đặt in không còn bị chặn như trạng thái preview/save ban đầu bên dưới. Xưởng vẫn phải duyệt kỹ thuật file, báo giá, nhận chấp thuận/thanh toán trước khi lập Print Job. Ghép GLB không tự thay thế bước chuẩn bị STL/support/slicing. Chi tiết BE + web: `Memento3D-Fronted-Web/docs/26-custom-print-checkout-flow.md`.

Đã thêm 3 kiểm tra app có trọng tâm cho checkout retry, chấp thuận báo giá trước thanh toán và transport VNPAY; chưa chạy trên điện thoại/emulator thật.

Repo được clone tại `D:\FPTU\07\EXE201\Memento3D-FrontEnd-App`, từ `git@github.com:Memento3D/Memento3D-FrontEnd-App.git`, baseline `bb712e3da6c3c4586d4bb9f011e8b53e5e842c6b`.

## Luồng hiện tại

1. **Tạo kỷ vật:** ba ảnh chính diện/trái/phải, tùy chọn ảnh phía sau, xác nhận quyền sử dụng ảnh. Camera hoặc thư viện; kiểm tra định dạng và dung lượng bằng capabilities BE. Luồng tạo mới không còn mặc định video.
2. **Gửi ảnh:** tạo scan `input_mode=image`; upload kèm `view_hint`; giữ các ID đã được BE xác nhận trong màn hình để tiếp tục sau lỗi. Nếu POST tạo job mất phản hồi, tìm job của scan trước khi thử tạo lại. Không tự replay POST.
3. **Theo dõi:** polling tuần tự 4 giây, dừng khi app vào nền/rời màn hình hoặc job terminal. Phần trăm không xác định dùng indicator không xác định. Mất kết nối không bị coi là ảnh hỏng.
4. **Custom:** lấy scene theo **output ID**; xem body/đầu cùng mũ hoặc tóc và kính tùy chọn. Danh sách thumbnail theo `groups/assetVersionIds` từ BE. Xoay/zoom bằng chạm, nút xem khuôn mặt/toàn thân.
5. **Lưu:** chỉ PUT khi bấm Lưu thiết kế, gửi `fitResultId`, `revision`, `selection`. Click asset không gọi AI, không tạo GLB mới. Mở lại model lấy cùng scene/draft ở BE nên dùng chung bản lưu với web.
6. **Xung đột:** 409 giữ lựa chọn local, khóa lưu và yêu cầu tải bản đã lưu; không tự tăng revision hoặc ghi đè. Thiết kế chỉ xem khóa lựa chọn/lưu.
7. **Rời trang:** cảnh báo thay đổi chưa lưu; JSON tạm trên thiết bị gắn với output/fit/revision, không lưu URL ký. Khôi phục JSON tạm có revision cũ không được tự ghi đè bản trên server.

Các điểm vào từ trang chính, danh sách scan, xem tiến trình và mở model đã hoàn tất đã được nối. Quay về sau luồng tạo/custom làm mới danh sách. Model cũ chỉ dùng fallback khi BE trả đúng `409 CUSTOMIZATION_NOT_AVAILABLE`; lỗi quyền/mạng không bị che thành model legacy.

## Tải và render 3D

- Native HTTP tải GLB từ signed URL; chỉ gửi Bearer khi đúng host/port BE. Không gửi token tới B2/Cloudinary và không tự theo redirect.
- File tạm được phục vụ tới WebView qua HTTP loopback có token riêng; không yêu cầu public bucket hay tắt bảo vệ CORS của WebView.
- Base và asset được cache trong vòng đời viewer theo ID/hash, chỉ tải asset được chọn. URL 401/403 được lấy lại qua scene và thử một lần nếu output/fit/hash vẫn khớp.
- Một root tọa độ chung; `matrixColumnMajor` áp dụng một lần ở wrapper. Không căn giữa/scale riêng từng asset. Đổi asset giữ camera và chỉ thay khi tải thành công; kết quả tải cũ không ghi đè lựa chọn mới.
- Download có timeout stream và kiểm tra GLB header, file tạm bị xóa khi lỗi/đóng viewer; tài nguyên Three.js được dispose khi rời màn hình.
- Nguồn JS: `tool/model_viewer/src`; bundle chạy thực tế: `assets/model_viewer/viewer.bundle.js`. Sau sửa JS chạy `npm run build` trong `tool/model_viewer`.

## API dùng chung với web

| Thao tác | Endpoint |
| --- | --- |
| Giới hạn ảnh | GET `/api/v1/reconstruction/capabilities` |
| Tạo scan | POST `/api/v1/scans` |
| Upload | POST `/api/v1/scans/{scanId}/images?view_hint=front|left|right|back` |
| Tạo preview | POST `/api/v1/reconstructions/previews` |
| Tìm job hiện có | GET `/api/v1/scans/{scanId}/reconstruction-jobs` |
| Tiến trình/output | GET `/api/v1/reconstruction-jobs/{jobId}` và `/outputs` |
| Scene | GET `/api/v1/models/{outputId}/scene` |
| Đọc/lưu lựa chọn | GET/PUT `/api/v1/models/{outputId}/customization` |

App chỉ giữ token đăng nhập người dùng. Key AI, B2, Cloudinary nằm phía server.

## Kiểm chứng và giới hạn

- Flutter phân tích `lib` và các test mới: không có issue. Phân tích toàn repo còn một lint `use_super_parameters` có sẵn trong `test/optimistic_scan_creation_test.dart`.
- Nhóm test Dart API/controller/loopback: 20 trường hợp đạt; thêm 2 widget test xác minh chuyển job hoàn tất → custom → Back và job thất bại không tạo lại tác vụ.
- Nhóm JS runtime/renderer: 30 trường hợp, gồm cache, slot/matrix, lỗi asset, kết quả tải cũ, framing và thao tác camera.
- Đã build lại viewer bundle. Các test sử dụng transport có kiểm soát; không tạo job AI hoặc ghi Neon/B2.
- **Chưa chạy app trên Android/iOS thật:** máy hiện không có Android SDK/emulator; Windows không build iOS. Chưa xác nhận end-to-end app với BE/ngrok/AI đang chạy.
- Resume upload chỉ trong màn hình còn sống, chưa khôi phục file ảnh sau kill app. JSON chưa lưu trên thiết bị có thể được khôi phục khi mở lại đúng output.
- **Đặt in custom đã được nối:** BE giữ snapshot theo order item, xuất GLB và xưởng duyệt kỹ thuật. App gửi bản lưu, xem file của đơn, chấp thuận báo giá rồi thanh toán. Chưa kiểm chứng đơn thật/B2 mới/thanh toán sandbox trên thiết bị; không coi preview AI là file tự động sẵn sàng chạy máy.

## Chạy trên thiết bị Android

Flutter đã được chuẩn bị riêng ở `C:\tmp\memento-flutter-sdk` (Flutter 3.47.9 / Dart 3.13.7); không thay PATH toàn máy. Cần Android SDK và emulator hoặc điện thoại bật USB debugging.

```powershell
cd D:\FPTU\07\EXE201\Memento3D-FrontEnd-App
& 'C:\tmp\memento-flutter-sdk\bin\flutter.bat' pub get
& 'C:\tmp\memento-flutter-sdk\bin\flutter.bat' devices
# Android emulator truy cập BE trên máy Windows:
& 'C:\tmp\memento-flutter-sdk\bin\flutter.bat' run --dart-define=API_URL=http://10.0.2.2:8080
```

Điện thoại thật dùng IP LAN của máy chạy BE hoặc HTTPS URL của **cùng bản BE mà web đang dùng**. `localhost` trên điện thoại là điện thoại. `API_URL` là origin, không thêm `/api/v1`. Đổi URL cần chạy/build lại vì đây là `dart-define`.

Khi thiết bị sẵn sàng, kiểm tra một lượt bằng tài khoản thật: tạo mới → đợi model → đổi mũ/tóc/kính → lưu → về danh sách → mở lại → mở web cùng tài khoản để đối chiếu. Không cần chạy AI lại cho mỗi lần đổi phụ kiện.

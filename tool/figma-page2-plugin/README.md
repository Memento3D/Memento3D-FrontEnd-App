# Figma plugin — đồng bộ Page 2 với code đặt hàng

Figma REST API chỉ đọc, không tạo/sửa được node. Muốn sửa file Figma bằng code thì
phải chạy plugin bên trong Figma, nên thư mục này là một plugin development.

File Figma: `BrvtUjLBQp73IKa6QaKsmC` ("Untitled"), sửa trên page **Page 2**.

## Chạy

1. Mở **Figma desktop app** (bản web không import được plugin local) và mở file trên.
2. Menu → **Plugins → Development → Import plugin from manifest…** → chọn
   `tool/figma-page2-plugin/manifest.json`.
3. Mở console để xem log: **Plugins → Development → Open console**.
4. Chạy: **Plugins → Development → Memento3D — Page 2 order flow**.

Mọi thay đổi nằm trong một bước undo: `Ctrl+Z` một lần là trả lại như trước.

## Plugin làm gì

Bật/tắt từng phần ở đầu `code.js` (`STEPS`):

- `viewerCta` — **sửa thẳng các frame `3D Model Viewer`** (`11:1742`, `11:1981` và
  mọi frame có tên bắt đầu bằng `3D Model Viewer`): chèn nút `Đặt in 3D vật lý`
  ngay dưới nút `Kiểm tra khả năng in`. Đây là điểm nối: màn viewer kết thúc luồng
  scan và là lối vào duy nhất của luồng đặt hàng, đúng như
  `model_viewer_screen.dart` (key `model-viewer-order-print`).
  Nút mới được **clone từ nút `Kiểm tra khả năng in` trong chính frame đó** nên
  thừa hưởng nguyên nền, bo góc, padding, font — chỉ đổi phần chữ. Icon vẫn là bản
  sao của icon máy in, đổi sang icon túi mua hàng thủ công nếu cần. Frame nào đã có
  nút này rồi thì bỏ qua.

- `newFrames` — tạo 3 frame cho màn đã có trong code nhưng chưa có trên Page 2:
  `Giỏ hàng (CartScreen)`, `Sản phẩm (ShopScreen)`,
  `Cấu hình đơn in 3D — chưa báo giá (ConfigurePrintScreen · state)`.
  Frame nào trùng tên sẵn có thì bỏ qua.
- `content` — xoá 4 dòng chỉ có trong design mà API đơn hàng không trả dữ liệu, nên
  app không bao giờ hiển thị được: `Tiến độ 65%`,
  `Đang xử lý lớp quang hóa UV mịn 50µm`, `Dự kiến giao ngày 31/10`,
  `Giao tận tay khách hàng`. Mốc thời gian từng bước (`29/10/2026 09:15`,
  `29/10/2026 10:30`) được giữ lại vì `OrderResponse` có `createdAt`/`updatedAt`.
- `layout` — xếp lại Page 2 thành 3 hàng, mỗi hàng có nhãn:
  1. `LUỒNG ĐẶT HÀNG — bản chuẩn, khớp code Flutter` theo đúng thứ tự điều hướng:
     Model 3D → Cấu hình đơn in 3D (có/chưa báo giá) → Xác nhận đơn chế tác →
     Giỏ hàng → Xác nhận đơn hàng → Đặt hàng thành công → Đơn hàng của tôi →
     Chi tiết đơn hàng → Thanh toán.
  2. `LUỒNG ĐẶT HÀNG — bản cũ, trùng với hàng trên` — 4 frame trùng
     (`16:931`, `16:823`, `16:1133`, `16:1441`). **Không xoá**, chỉ dồn xuống.
  3. `AUTH & SCAN` — các frame còn lại, giữ nguyên thứ tự.

## Giới hạn

- Frame mới do plugin tạo dựng bằng auto-layout theo token màu/typography của app,
  không phải bản sao pixel-perfect của các frame Stitch sinh ra.
- Plugin không sửa bố cục bên trong các frame có sẵn (chỉ xoá text ở `content`),
  vì cấu trúc node của từng frame khác nhau, sửa mù dễ làm vỡ layout.
- Font dùng Inter (mặc định của Figma). Design gốc dùng Plus Jakarta Sans; nếu muốn
  khớp, đổi `family` trong `loadFonts()` và `text()` của `code.js` sau khi cài font
  đó vào Figma.

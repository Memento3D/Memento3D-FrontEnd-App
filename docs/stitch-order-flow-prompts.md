# Stitch prompts — luồng đặt hàng (Memento3D)

Prompt để tái tạo luồng đặt hàng đã implement trong `lib/features/orders/` sang
Google Stitch (https://stitch.withgoogle.com). Dán **Design system** một lần ở
prompt đầu, sau đó dán từng prompt màn hình để Stitch thêm screen mới vào project.

Prompt gộp viết bằng tiếng Việt. Các prompt tách rời (mục 0-7) giữ bản tiếng Anh —
dùng khi cần sinh lại một màn và muốn Stitch bám sát mô tả layout.

Thứ tự màn theo đúng luồng trong app:

```
Màn xem 3D ─"Đặt in 3D vật lý"─> Cấu hình & báo giá ─┐
Giỏ hàng ───"Đặt hàng"───────────────────────────────┴─> Xác nhận đơn hàng ─> Đặt hàng thành công
                                                                              │
                                        Đơn hàng của tôi <────────────────────┴─> Chi tiết đơn hàng ─> Thanh toán
```

---

## Prompt gộp (một lần dán, tạo cả 7 màn)

Dùng khối này nếu muốn Stitch sinh toàn bộ luồng trong một lượt. Các mục 0-7 bên
dưới là bản tách rời, dùng khi cần sửa lại từng màn.

```
Tạo 7 màn hình mobile (390x844, chỉ light theme) cho app in kỷ vật 3D Memento3D —
đây là luồng đặt hàng. Giữ nguyên mọi chuỗi tiếng Việt trong dấu ngoặc kép.

DESIGN SYSTEM áp dụng cho mọi màn:
Font Plus Jakarta Sans; tiêu đề 15-20px weight 700-800, nội dung 13-14px weight
500. Màu nhấn #6366F1 (nhấn xuống #4F46E5). Nền trang #FBFBFE. Thẻ nền #FFFFFF,
bo góc 20, viền 1px #F1F0F5, không đổ bóng, padding trang 16px, khoảng cách giữa
các thẻ 16px. Chữ chính #111827, chữ phụ #6B7280, chữ mờ #9CA3AF. Pill trạng thái
bo 999, padding ngang 10px, chữ 12px weight 700: tím #EDE9FE/#7C3AED, hổ phách
#FEF3C7/#B45309, cam #FFDEC9/#C2410C, xanh lá #D1FAE5/#065F46, đỏ
#FEE2E2/#B91C1C. Nút chính nền màu nhấn, chữ trắng, bo 16, cao 52, rộng hết hàng.
Nút phụ viền ngoài, bo 16, cao 50. Định dạng tiền "200.000 ₫". Mỗi thẻ có hàng
tiêu đề in đậm, bên phải có thể là link chữ hoặc pill; bên trong là các hàng
nhãn/giá trị với nhãn màu chữ phụ và giá trị in đậm.

MÀN 1 "Model 3D" — điểm vào luồng: khu xem trước 3D nền tối lớn ở trên với tượng
kỷ vật ở giữa, bên dưới là thẻ thống kê có nhãn "CHI TIẾT" và "TRẠNG THÁI", rồi 3
nút rộng hết hàng xếp dọc, bo góc 24, padding dọc 20px, cách nhau 12px: nút nền
màu nhấn "Kiểm tra khả năng in" (icon máy in), nút nền màu nhấn "Đặt in 3D vật lý"
(icon túi mua hàng), nút viền ngoài "Đánh giá & Chia sẻ" (icon chia sẻ).

MÀN 2 "Cấu hình đơn in 3D" — có mũi tên back; các thẻ: "Mô hình đặt in" (icon khối
3D màu nhấn, dòng đậm "Chân dung bà Hoa", dòng phụ "Mã phiên: s-20261029-77");
"Gói chế tác" gồm 3 hàng radio, hàng đầu được chọn, mỗi hàng có tên gói in đậm và
phụ đề 2 dòng gồm mô tả và giá ("Tượng chân dung Premium" / "Resin SLA, hoàn thiện
thủ công" / "1.200.000 ₫"; "Tượng chân dung Standard" / "Resin tiêu chuẩn" /
"750.000 ₫"; "Tượng mini kỷ vật" / "PLA, 8-10cm" / "320.000 ₫"); "Kích thước tượng"
với "15 cm" in đậm màu nhấn ở góc phải tiêu đề thẻ và thanh trượt từ 10 đến 30;
"Vật liệu in" radio "High-Detail Resin SLA" kèm dòng phụ "+ 150.000 ₫" và "PLA
tiêu chuẩn"; "Đế trưng bày" radio "Đế gỗ óc chó tự nhiên" kèm "+ 200.000 ₫" và "Đế
tiêu chuẩn"; "Khắc tên trên đế" là ô nhập viền ngoài, placeholder "Ví dụ: Gia đình
An · 2026", bộ đếm 0/60; "Báo giá" gồm các hàng "Giá chế tác cơ bản" 1.200.000 ₫,
"Phí cá nhân hóa" 350.000 ₫, "Phí vận chuyển" 50.000 ₫, đường kẻ mảnh, "Tổng cộng"
1.600.000 ₫ in đậm màu nhấn, rồi dòng chữ mờ "Báo giá có hiệu lực đến 29/10/2026
18:00". Thanh dưới cố định: bên trái nhãn nhỏ "Tạm tính" trên số "1.600.000 ₫"
cỡ 20px weight 800 màu nhấn, bên phải nút chính "Tiếp tục đặt hàng"; vẽ thêm
trạng thái chưa có báo giá: một nút chính rộng hết hàng "Nhận báo giá".

MÀN 3 "Xác nhận đơn hàng" — có mũi tên back; các thẻ: "Địa chỉ giao hàng" với link
"Quản lý" bên phải tiêu đề và 2 hàng radio (dòng đậm "An · 0123456789", dòng phụ
"12 Phố A, Phường A, Hà Nội"), hàng đầu được chọn; "Sản phẩm (2)" gồm 2 hàng (tên
"Tượng mini kỷ vật" in đậm bên trái, dòng phụ "100.000 ₫ × 2" bên dưới, "200.000 ₫"
in đậm bên phải); "Phương thức thanh toán" radio "Thanh toán khi nhận hàng (COD)"
được chọn, "Ví MoMo", "ZaloPay"; "Ghi chú cho đơn hàng" ô nhập nhiều dòng
placeholder "Ví dụ: giao buổi chiều, khắc tên lên đế gỗ…", bộ đếm 0/255; "Chi tiết
thanh toán" các hàng "Tạm tính" 200.000 ₫, "Giảm giá" 0 ₫, "Phí giao hàng" 0 ₫,
đường kẻ, "Tổng cộng" 200.000 ₫ in đậm màu nhấn. Thanh dưới cố định: bên trái nhãn
"Tổng thanh toán" trên số "200.000 ₫" cỡ 20px weight 800 màu nhấn, bên phải nút
chính "Đặt hàng".

MÀN 4 — biến thể của màn 3 dành cho đơn chế tác từ scan: thay thẻ danh sách sản
phẩm bằng thẻ "Sản phẩm chế tác" gồm icon khối 3D màu nhấn, dòng đậm "Kỷ vật 3D ·
Chân dung bà Hoa", dòng phụ "15cm · High-Detail Resin SLA", bên phải "1.600.000 ₫"
in đậm; thẻ chi tiết thanh toán đổi thành "Giá chế tác cơ bản" 1.200.000 ₫, "Phí cá
nhân hóa" 350.000 ₫, "Phí giao hàng" 50.000 ₫, đường kẻ, "Tổng cộng" 1.600.000 ₫.

MÀN 5 "Đặt hàng thành công" — không có mũi tên back; thẻ hero căn giữa với vòng
tròn tích xanh lá 56px (#10B981), dòng đậm 16px "Chúng tôi đã nhận được đơn hàng
của bạn", dòng phụ "Mã đơn: ORD-20261029-A1B2", pill hổ phách "Chờ xác nhận"; thẻ
"Thông tin đơn hàng" các hàng "Người nhận" An, "Số điện thoại" 0123456789, "Địa
chỉ" 12 Phố A, Phường A, Hà Nội, "Thanh toán" Thanh toán khi nhận hàng (COD),
đường kẻ, "Tổng cộng" 200.000 ₫ in đậm màu nhấn; thẻ "Hoàn tất thanh toán" có dòng
chữ phụ "Đơn hàng sẽ được xác nhận sau khi cổng thanh toán báo thành công." và nút
chính "Mở trang thanh toán"; cuối trang là nút chính "Theo dõi đơn hàng" rồi nút
viền ngoài "Về trang chủ".

MÀN 6 "Đơn hàng của tôi" — hàng chip lọc cuộn ngang: "Tất cả" (đang chọn, nền màu
nhấn), "Chờ xác nhận (1)", "Đã xác nhận", "Đang in 3D", "Đang giao", "Hoàn tất",
"Đã hủy"; bên dưới là 4 thẻ đơn hàng cách nhau 12px, mỗi thẻ có hàng trên gồm mã
đơn "ORD-20261029-A1B2" in đậm bên trái và pill trạng thái bên phải, dòng phụ 13px
"Tượng mini kỷ vật", hàng dưới gồm chữ mờ 12px "1 sản phẩm" bên trái và "200.000 ₫"
cỡ 15px weight 800 màu nhấn bên phải; pill lần lượt: "Chờ xác nhận" hổ phách,
"Đang in 3D" tím, "Đang giao" cam, "Hoàn tất" xanh lá; dưới danh sách có nút chữ
căn giữa "Xem thêm"; vẽ thêm trạng thái rỗng với dòng chữ căn giữa "Bạn chưa có đơn
hàng nào."

MÀN 7 "ORD-20261029-A1B2" — có mũi tên back; thẻ "Trạng thái đơn hàng" với pill tím
"Đang in 3D" ở tiêu đề và timeline dọc 5 bước nối bằng đường 2px: "Chờ xác nhận",
"Đã xác nhận", "Đang in 3D", "Đang giao", "Đã giao" — ba bước đầu là vòng tròn tích
đầy màu nhấn với đường nối màu nhấn và nhãn bước hiện tại in đậm, hai bước cuối là
vòng tròn rỗng màu xám mờ với đường nối #F1F0F5 và nhãn mờ; thẻ "Sản phẩm" có
"Tượng mini kỷ vật" in đậm bên trái và "200.000 ₫" in đậm bên phải, dòng phụ
"100.000 ₫ × 2 · Resin · 12-15cm · Phủ bóng UV", và dòng màu tím "Khắc tên: Gia
đình An"; thẻ "Giao hàng" các hàng "Người nhận", "Số điện thoại", "Địa chỉ", "Đơn vị
vận chuyển" Giao Hàng Nhanh (GHN Express), "Mã vận đơn" GHN-20261029-A1B2, "Ghi
chú"; thẻ "Thanh toán" các hàng "Phương thức" Ví MoMo, "Tình trạng" Chờ thanh toán,
"Đã thanh toán" 0 ₫, "Còn lại" 200.000 ₫; thẻ "Chi tiết giá" các hàng "Tạm tính",
"Giảm giá", "Phí giao hàng", "Phí cá nhân hóa", "Phụ phí sản xuất", đường kẻ, "Tổng
cộng" 200.000 ₫ in đậm màu nhấn. Thanh dưới cố định có 2 nút bằng nhau: nút viền
ngoài "Hủy đơn hàng" màu đỏ #EF4444 và nút nền màu nhấn "Thanh toán".

Liên kết luồng: màn 1 bấm "Đặt in 3D vật lý" sang màn 2, màn 2 sang màn 4; màn giỏ
hàng sang màn 3; màn 3 và màn 4 sang màn 5; màn 5 và màn 6 sang màn 7.
```

---

## 0. Design system (dán kèm prompt đầu tiên)

```
Mobile app screens, 390x844, light theme only. Design system:
- Font: Plus Jakarta Sans. Headings 15-20px weight 700-800, body 13-14px weight 500.
- Primary / accent: #6366F1. Pressed: #4F46E5.
- Page background: #FBFBFE. Cards: #FFFFFF, corner radius 20, 1px border #F1F0F5, no shadow.
- Text: primary #111827, secondary #6B7280, muted #9CA3AF.
- Status pills: radius 999, 10px horizontal padding, 12px text weight 700.
  Purple #EDE9FE bg / #7C3AED text. Amber #FEF3C7 / #B45309. Orange #FFDEC9 / #C2410C.
  Green #D1FAE5 / #065F46. Red #FEE2E2 / #B91C1C.
- Primary button: filled #6366F1, white text, radius 16, height 52, full width.
- Secondary button: outlined, radius 16, height 50.
- Currency format: "200.000 ₫".
- Section cards stack vertically with 16px gaps, 16px page padding.
```

---

## 1. CTA trên màn xem 3D (điểm vào luồng đặt hàng)

```
Screen showing a finished 3D keepsake model: a large dark 3D preview area at the
top with the model centered, a statistics card below it with the labels
"CHI TIẾT" and "TRẠNG THÁI", then three stacked full-width action buttons with
24px corner radius and 20px vertical padding, 12px apart:
1. filled accent button with a printer icon, label "Kiểm tra khả năng in"
2. filled accent button with a shopping bag icon, label "Đặt in 3D vật lý"
3. outlined button with a share icon, label "Đánh giá & Chia sẻ"
```

---

## 2. Cấu hình & báo giá đơn in 3D

```
Screen title "Cấu hình đơn in 3D" with a back arrow. Scrolling section cards,
then a fixed bottom bar.

Card "Mô hình đặt in": a 3D cube icon in accent color, bold line
"Chân dung bà Hoa", secondary line "Mã phiên: s-20261029-77".

Card "Gói chế tác": three radio rows, the first selected. Each row has a bold
package name and a secondary two-line subtitle with description and price:
"Tượng chân dung Premium" / "Resin SLA, hoàn thiện thủ công" / "1.200.000 ₫";
"Tượng chân dung Standard" / "Resin tiêu chuẩn" / "750.000 ₫";
"Tượng mini kỷ vật" / "PLA, 8-10cm" / "320.000 ₫".

Card "Kích thước tượng" with the value "15 cm" in bold accent color on the right
of the card header, and a slider from 10 to 30 underneath.

Card "Vật liệu in": radio rows "High-Detail Resin SLA" with secondary line
"+ 150.000 ₫", and "PLA tiêu chuẩn".

Card "Đế trưng bày": radio rows "Đế gỗ óc chó tự nhiên" with "+ 200.000 ₫",
and "Đế tiêu chuẩn".

Card "Khắc tên trên đế" with an outlined text field, placeholder
"Ví dụ: Gia đình An · 2026", character counter 0/60.

Card "Báo giá" with label/value rows: "Giá chế tác cơ bản" 1.200.000 ₫,
"Phí cá nhân hóa" 350.000 ₫, "Phí vận chuyển" 50.000 ₫, a thin divider,
"Tổng cộng" 1.600.000 ₫ in 17px bold accent, then a muted 12px line
"Báo giá có hiệu lực đến 29/10/2026 18:00".

Fixed bottom bar, two states:
- before quoting: one full-width primary button "Nhận báo giá".
- after quoting: left side small label "Tạm tính" above "1.600.000 ₫" in 20px
  weight 800 accent; right side primary button "Tiếp tục đặt hàng".
```

---

## 3. Xác nhận đơn hàng (checkout)

```
Screen title "Xác nhận đơn hàng" in a plain app bar with a back arrow.
Scrolling list of section cards, then a fixed bottom bar.

Card 1, header "Địa chỉ giao hàng" with a text link "Quản lý" on the right.
Two radio rows; the first one selected. Each row: bold line "An · 0123456789",
secondary line "12 Phố A, Phường A, Hà Nội".

Card 2, header "Sản phẩm (2)". Two rows; each row has the product name
"Tượng mini kỷ vật" bold on the left, the line "100.000 ₫ × 2" in secondary text
underneath, and the line total "200.000 ₫" bold on the right.

Card 3, header "Phương thức thanh toán". Three radio rows:
"Thanh toán khi nhận hàng (COD)" selected, "Ví MoMo", "ZaloPay".

Card 4, header "Ghi chú cho đơn hàng" with an outlined multiline text field,
placeholder "Ví dụ: giao buổi chiều, khắc tên lên đế gỗ…", character counter 0/255.

Card 5, header "Chi tiết thanh toán". Label/value rows in secondary text:
"Tạm tính" 200.000 ₫, "Giảm giá" 0 ₫, "Phí giao hàng" 0 ₫, a thin divider,
then "Tổng cộng" 200.000 ₫ in 17px bold accent color.

Fixed bottom bar on white: left side small label "Tổng thanh toán" above
"200.000 ₫" in 20px weight 800 accent color; right side primary button "Đặt hàng".
```

Biến thể cho đơn chế tác từ scan (dán tiếp để Stitch tạo thêm một màn):

```
Same "Xác nhận đơn hàng" screen, but instead of the product list card it has a
card "Sản phẩm chế tác" containing a 3D cube icon in accent color, bold line
"Kỷ vật 3D · Chân dung bà Hoa", secondary line "15cm · High-Detail Resin SLA",
and "1.600.000 ₫" bold on the right.
The payment detail card reads "Giá chế tác cơ bản" 1.200.000 ₫,
"Phí cá nhân hóa" 350.000 ₫, "Phí giao hàng" 50.000 ₫, divider,
"Tổng cộng" 1.600.000 ₫.
```

---

## 4. Đặt hàng thành công

```
Screen title "Đặt hàng thành công" in an app bar with no back arrow.

Hero card, centered: a 56px green check circle (#10B981), then bold 16px text
"Chúng tôi đã nhận được đơn hàng của bạn", then secondary 13px
"Mã đơn: ORD-20261029-A1B2", then an amber status pill "Chờ xác nhận".

Card "Thông tin đơn hàng" with label/value rows: "Người nhận" An,
"Số điện thoại" 0123456789, "Địa chỉ" 12 Phố A, Phường A, Hà Nội,
"Thanh toán" Thanh toán khi nhận hàng (COD), divider, "Tổng cộng" 200.000 ₫
in bold accent.

Card "Hoàn tất thanh toán" with secondary text
"Đơn hàng sẽ được xác nhận sau khi cổng thanh toán báo thành công."
and a primary button "Mở trang thanh toán". This card appears only for e-wallet
orders.

Bottom of the page: primary button "Theo dõi đơn hàng", then outlined button
"Về trang chủ".
```

---

## 5. Đơn hàng của tôi (danh sách)

```
Screen title "Đơn hàng của tôi".

Under the app bar, a horizontally scrolling row of filter chips:
"Tất cả", "Chờ xác nhận (1)", "Đã xác nhận", "Đang in 3D", "Đang giao",
"Hoàn tất", "Đã hủy". The first chip is selected and filled with the accent color.

Below, a vertical list of order cards (16px page padding, 12px between cards).
Each card: top row with the order code "ORD-20261029-A1B2" bold on the left and a
status pill on the right; secondary 13px product line "Tượng mini kỷ vật";
bottom row with muted 12px "1 sản phẩm" on the left and "200.000 ₫" in 15px
weight 800 accent on the right.

Show four cards with different pills: "Chờ xác nhận" amber, "Đang in 3D" purple,
"Đang giao" orange, "Hoàn tất" green.

Below the list, a centered text button "Xem thêm".
Also show an empty state variant: centered text "Bạn chưa có đơn hàng nào."
```

---

## 6. Chi tiết đơn hàng

```
Screen title "ORD-20261029-A1B2" with a back arrow.

Card "Trạng thái đơn hàng" with a purple pill "Đang in 3D" in the header.
Body is a vertical timeline of five steps, each a 20px icon plus a label, joined
by a 2px connector line: "Chờ xác nhận", "Đã xác nhận", "Đang in 3D",
"Đang giao", "Đã giao". The first three icons are filled check circles in the
accent color with accent connectors; the current step label is bold; the last two
are empty circles in muted gray with #F1F0F5 connectors and muted labels.

Card "Sản phẩm": product name "Tượng mini kỷ vật" bold left, "200.000 ₫" bold
right, secondary line "100.000 ₫ × 2 · Resin · 12-15cm · Phủ bóng UV", and a
purple line "Khắc tên: Gia đình An".

Card "Giao hàng" with label/value rows: "Người nhận", "Số điện thoại", "Địa chỉ",
"Đơn vị vận chuyển" Giao Hàng Nhanh (GHN Express), "Mã vận đơn" GHN-20261029-A1B2,
"Ghi chú".

Card "Thanh toán" with rows "Phương thức" Ví MoMo, "Tình trạng" Chờ thanh toán,
"Đã thanh toán" 0 ₫, "Còn lại" 200.000 ₫.

Card "Chi tiết giá" with rows "Tạm tính", "Giảm giá", "Phí giao hàng",
"Phí cá nhân hóa", "Phụ phí sản xuất", divider, "Tổng cộng" 200.000 ₫ bold accent.

Fixed bottom bar with two buttons side by side, equal width: outlined
"Hủy đơn hàng" in red (#EF4444) and filled "Thanh toán".
```

---

## 7. Thanh toán (cổng e-wallet)

```
Screen title "Thanh toán" with a back arrow and a thin indeterminate accent
progress bar directly under the app bar. The rest of the screen is an embedded
payment gateway web page placeholder: a centered MoMo-style payment panel with
the amount "200.000 ₫", a QR code block, and a note
"Quét mã để hoàn tất thanh toán".
```

---

## Đối chiếu code

| Màn Stitch | File Flutter |
|---|---|
| 1 | `lib/features/model_viewer/presentation/screens/model_viewer_screen.dart` (key `model-viewer-order-print`) |
| 2 | `lib/features/orders/presentation/screens/print_order_config_screen.dart` |
| 3 | `lib/features/orders/presentation/screens/checkout_screen.dart` |
| 4 | `lib/features/orders/presentation/screens/order_placed_screen.dart` |
| 5 | `lib/features/orders/presentation/screens/orders_screen.dart` |
| 6 | `lib/features/orders/presentation/screens/order_detail_screen.dart` |
| 7 | `lib/features/orders/presentation/screens/payment_webview_screen.dart` |

Trạng thái và nhãn pill lấy từ `order_presentation.dart`; enum trạng thái thật ở
`Memento3D-Backend/.../orders/domain/model/OrderStatus.java`. Giá đơn chế tác do
`POST /api/v1/pricing/quotes` quyết định, client không tự tính.

---
## Prompt cho các màn còn thiếu — theo style Main Screen

> Lỗi thời: MÀN 6 "Xác nhận rủi ro chất lượng" và MÀN 7 "Xem trước video" đã bị bỏ
> khỏi design (29/10/2026). Dùng mục "Prompt đầy đủ" bên dưới.

Các màn này đã có trong code nhưng chưa có frame trên Page 1 / Page 2. Chuỗi UI lấy
từ `shop_screen.dart`, `addresses_screen.dart`, `rate_share_screen.dart`,
`quality_override_screen.dart`, `video_preview_screen.dart`,
`print_order_config_screen.dart` và `app_vi.arb`.

Điểm nối hai luồng: màn 3D Model Viewer là **kết thúc luồng scan** và là **điểm vào
duy nhất của luồng đặt hàng** (`model_viewer_screen.dart`, key
`model-viewer-order-print`). Hai frame viewer cũ trên Page 2 (`11:1742`, `11:1981`)
chưa có nút này, nên MÀN 0 bên dưới là bản cập nhật cho chúng.

```
Tạo 9 màn hình mobile (390x844, chỉ light theme) cho app in kỷ vật 3D Memento3D,
dùng lại đúng ngôn ngữ thị giác của màn "Studio Tái Tạo 3D - Mobile" đã có trong
file. Giữ nguyên mọi chuỗi tiếng Việt trong dấu ngoặc kép.

SHELL & DESIGN SYSTEM (theo main screen):
- Font Plus Jakarta Sans. Nền trang #FBFBFE. Thẻ trắng #FFFFFF bo góc 20, viền 1px
  #F1F0F5, không đổ bóng; padding trang 16px, các thẻ cách nhau 16px.
- Header màn chính: ô vuông bo tròn 40x40 nền tím nhạt #EDE9FE chứa icon khối 3D,
  bên cạnh là tiêu đề in đậm 17px và dòng phụ 12px màu #6B7280; góc phải là icon
  chuông và avatar, mỗi cái trong hình tròn 36px nền #F5F3FF.
- Màn phụ (mở chồng lên) KHÔNG có header này và KHÔNG có tab bar: chỉ app bar đơn
  giản với mũi tên back và tiêu đề in đậm.
- Tiêu đề thẻ in đậm 15px, bên phải có thể là pill hoặc link chữ màu nhấn #6366F1.
- Pill bo 999, chữ 11-12px weight 700: tím #EDE9FE/#7C3AED, xanh lá #D1FAE5/#065F46,
  hổ phách #FEF3C7/#B45309, đỏ #FEE2E2/#B91C1C.
- Nút chính: nền #6366F1, chữ trắng weight 700, bo góc 14, cao 52, rộng hết hàng,
  có icon đứng trước nhãn. Nút phụ: viền 1px #6366F1, chữ màu nhấn, cùng kích thước.
- Hàng danh sách: thumbnail vuông 48x48 bo 14 nền #F5F3FF chứa icon, tên in đậm
  14px, dòng meta 12px màu #9CA3AF dạng "186 ảnh · 2 giờ trước", pill trạng thái,
  và icon chevron phải ở cuối hàng.
- Tiền định dạng "320.000 ₫".

MÀN 0 "3D Model Viewer — Memento3D" (cập nhật frame đã có) — khu xem 3D nền tối
chiếm nửa trên với mô hình ở giữa và thanh công cụ nổi bo tròn; dưới là thẻ thống kê
có nhãn "CHI TIẾT" và "TRẠNG THÁI"; rồi ba nút xếp dọc cách nhau 12px:
nút chính "Kiểm tra khả năng in" (icon máy in), nút chính "Đặt in 3D vật lý" (icon
túi mua hàng), nút phụ "Đánh giá & Chia sẻ" (icon chia sẻ). Nhấn "Đặt in 3D vật lý"
là điểm bắt đầu luồng đặt hàng.

MÀN 1 "Sản phẩm (ShopScreen)" — app bar "Sản phẩm" có icon giỏ hàng góc phải; ô tìm
kiếm viền ngoài nhãn "Tìm sản phẩm" kèm icon kính lúp; 3 hàng sản phẩm theo kiểu
hàng danh sách ở trên, mỗi hàng có tên in đậm, meta mô tả + giá, và icon thêm vào
giỏ thay cho chevron: "Tượng chân dung Premium" / "Resin SLA, hoàn thiện thủ công ·
1.200.000 ₫"; "Tượng chân dung Standard" / "Resin tiêu chuẩn · 750.000 ₫"; "Tượng
mini kỷ vật" / "PLA, 8-10cm · 320.000 ₫" kèm pill hổ phách "Hết hàng" và icon thêm
bị mờ. Dưới danh sách có nút chữ "Xem thêm". Vẽ thêm trạng thái rỗng: dòng căn giữa
"Không có sản phẩm."

MÀN 2 "Giỏ hàng (CartScreen)" — app bar "Giỏ hàng"; 2 hàng danh sách sản phẩm, mỗi
hàng có thumbnail, tên in đậm "Tượng mini kỷ vật", meta "320.000 ₫", và bộ số lượng
bên phải gồm icon trừ, số "2", icon cộng; dưới cùng là dòng "Tổng cộng: 640.000 ₫"
in đậm và nút chính "Đặt hàng" (icon túi mua hàng). Vẽ thêm trạng thái rỗng: dòng
căn giữa "Giỏ hàng đang trống."

MÀN 3 "Địa chỉ giao hàng (AddressesScreen)" — app bar "Địa chỉ giao hàng"; 2 thẻ địa
chỉ, mỗi thẻ có dòng đậm "An · 0123456789", dòng phụ "12 Phố A, Phường A, Hà Nội" và
hàng nút chữ "Sửa" / "Xóa" / "Đặt mặc định"; thẻ đầu có icon tích xanh lá bên phải
cùng dòng "Địa chỉ mặc định" và không có nút "Đặt mặc định". Nút nổi dạng viên thuốc
góc dưới phải: icon cộng + "Thêm địa chỉ". Trạng thái rỗng: "Bạn chưa có địa chỉ
giao hàng."

MÀN 4 "Thêm địa chỉ (AddressFormScreen)" — app bar "Thêm địa chỉ"; 5 ô nhập viền
ngoài xếp dọc, mỗi ô có nhãn nổi và bộ đếm ký tự: "Tên người nhận" (0/100), "Số điện
thoại" (0/30, bàn phím số), "Tỉnh / Thành phố" (0/100), "Phường / Xã" (0/100), "Địa
chỉ chi tiết" (0/255); dưới cùng nút chính "Lưu địa chỉ". Vẽ thêm biến thể có dòng
lỗi đỏ #EF4444 "Vui lòng nhập tên người nhận." dưới ô đầu tiên.

MÀN 5 "Đánh giá mô hình (RateShareScreen)" — app bar "Đánh giá mô hình"; thẻ đầu
hiện tên mô hình "Chân dung bà Hoa" in đậm và mã phiên màu mờ; hàng 5 ngôi sao cỡ
lớn màu nhấn với 4 sao đã chọn; ô nhập nhiều dòng viền ngoài nhãn "Nhận xét"; nút
chính "Lưu đánh giá" và nút phụ "Xóa đánh giá của tôi" màu đỏ #EF4444.

MÀN 6 "Xác nhận rủi ro chất lượng (QualityOverrideScreen)" — app bar có mũi tên
back; thẻ cảnh báo nền #FFFBEB viền #FDE68A, icon tam giác cảnh báo #D97706, tiêu đề
đậm "Chất lượng ảnh chưa hoàn toàn tối ưu", đoạn chữ #92400E "Bạn vẫn có thể dựng mô
hình, nhưng một số ảnh có thể ảnh hưởng đến độ chính xác của mô hình 3D."; bên dưới
là checkbox với nhãn "Tôi hiểu và đồng ý tiếp tục với rủi ro này"; nút chính "Xác
nhận và tiếp tục" và nút phụ "Quay lại kiểm tra ảnh". Vẽ thêm 2 biến thể: một có
pill đỏ "CHƯA THỂ TIẾP TỤC" trong thẻ cảnh báo và nút chính bị mờ; một là trạng thái
đã xác nhận với icon tích xanh lá, tiêu đề "Đã xác nhận rủi ro", dòng phụ "Xác nhận
của bạn đã được chấp nhận." và nút phụ "Quay lại báo cáo chất lượng".

MÀN 7 "Xem trước video (VideoPreviewScreen)" — app bar có mũi tên back; khung video
nền tối tỉ lệ 9:16 với nút play lớn ở giữa và thanh tiến độ dưới đáy; dưới khung là
thẻ thông tin gồm pill tím "Video từ thư viện", hàng "Thời lượng: 00:18" kèm dòng
xanh lá "Đã đạt thời lượng tối thiểu.", hàng "Dung lượng khi quay" giá trị "48,2
MB"; nút chính "Tiếp tục" và nút phụ "Thử lại". Biến thể lỗi: dòng đỏ "Chưa chọn
video" thay cho thẻ thông tin.

MÀN 8 "Cấu hình đơn in 3D — chưa báo giá (ConfigurePrintScreen · state)" — giống màn
"Cấu hình đơn in 3D" đã có nhưng chưa có báo giá: các thẻ "Mô hình đặt in", "Gói chế
tác", "Kích thước tượng" (giá trị "15 cm" in đậm màu nhấn, thanh trượt 10-30), "Vật
liệu in", "Đế trưng bày", "Khắc tên trên đế"; thẻ "Báo giá" chỉ có đoạn chữ phụ
"Chọn cấu hình rồi nhấn "Nhận báo giá" để hệ thống tính giá theo thể tích, vật liệu
và phí vận chuyển."; thanh dưới cố định chỉ có một nút chính rộng hết hàng "Nhận báo
giá", không hiện số tiền.

Liên kết luồng: màn 0 là kết thúc luồng scan và điểm vào luồng đặt hàng — nhấn "Đặt
in 3D vật lý" sang màn 8, màn 8 sau khi báo giá sang "Xác nhận đơn chế tác"; màn 1 →
màn 2 → "Xác nhận đơn hàng"; màn 3 ↔ màn 4, mở từ "Xác nhận đơn hàng" qua link "Quản
lý"; màn 6 nằm giữa "Báo cáo chất lượng" và "Xác nhận bắt đầu tái tạo"; màn 7 nằm
giữa màn quay/chọn video và "Đang tạo mô hình 3D".
```

---

## Prompt đầy đủ — toàn bộ luồng scan → order (14 màn)

Gộp mọi màn liên quan đến đặt hàng, theo style main screen "Studio Tái Tạo 3D".
Không bao gồm màn "Xác nhận rủi ro chất lượng" và "Xem trước video" — đã bỏ khỏi
design theo quyết định ngày 29/10/2026; code hai màn đó vẫn giữ nguyên.
Stitch có thể cắt bớt khi prompt quá dài: nếu màn cuối ra sơ sài, dán nửa đầu
(MÀN 1-7) trước rồi nửa sau (MÀN 8-14) sau.

```
Tạo 14 màn hình mobile (390x844, chỉ light theme) cho app in kỷ vật 3D Memento3D,
dùng lại đúng ngôn ngữ thị giác của màn "Studio Tái Tạo 3D - Mobile" đã có trong
file. Giữ nguyên mọi chuỗi tiếng Việt trong dấu ngoặc kép.

SHELL & DESIGN SYSTEM (theo main screen):
- Font Plus Jakarta Sans. Nền trang #FBFBFE. Thẻ trắng #FFFFFF bo góc 20, viền 1px
  #F1F0F5, không đổ bóng; padding trang 16px, các thẻ cách nhau 16px.
- Chỉ main screen mới có header lớn và tab bar. Cả 16 màn dưới đây là màn mở chồng:
  chỉ có app bar đơn giản gồm mũi tên back và tiêu đề in đậm, không có tab bar.
- Tiêu đề thẻ in đậm 15px; bên phải tiêu đề có thể là pill hoặc link chữ màu nhấn.
- Chữ chính #111827, chữ phụ #6B7280, chữ mờ #9CA3AF. Màu nhấn #6366F1.
- Pill bo 999, chữ 11-12px weight 700: tím #EDE9FE/#7C3AED, xanh lá #D1FAE5/#065F46,
  hổ phách #FEF3C7/#B45309, cam #FFDEC9/#C2410C, đỏ #FEE2E2/#B91C1C.
- Nút chính: nền #6366F1, chữ trắng weight 700, bo 14, cao 52, rộng hết hàng, icon
  đứng trước nhãn. Nút phụ: viền 1px màu nhấn, chữ màu nhấn, cùng kích thước.
- Hàng danh sách: thumbnail vuông 48x48 bo 14 nền #F5F3FF chứa icon, tên in đậm
  14px, dòng meta 12px màu #9CA3AF, pill trạng thái, icon chevron phải ở cuối.
- Hàng nhãn/giá trị trong thẻ: nhãn 13px màu chữ phụ bên trái, giá trị 13px in đậm
  bên phải; hàng tổng cộng dùng 15px nhãn và 17px giá trị in đậm màu nhấn.
- Tiền định dạng "320.000 ₫".

MÀN 1 "3D Model Viewer — Memento3D" — kết thúc luồng scan, điểm vào luồng đặt hàng.
Khu xem 3D nền tối chiếm nửa trên với mô hình ở giữa và thanh công cụ nổi bo tròn;
dưới là thẻ thống kê có nhãn "CHI TIẾT" và "TRẠNG THÁI"; rồi ba nút xếp dọc cách
nhau 12px: nút chính "Kiểm tra khả năng in" (icon máy in), nút chính "Đặt in 3D vật
lý" (icon túi mua hàng), nút phụ "Đánh giá & Chia sẻ" (icon chia sẻ).

MÀN 2 "Cấu hình đơn in 3D — chưa báo giá (ConfigurePrintScreen · state)" — app bar
"Cấu hình đơn in 3D"; thẻ "Mô hình đặt in" (icon khối 3D màu nhấn, dòng đậm "Chân
dung bà Hoa", dòng phụ "Mã phiên: s-20261029-77"); thẻ "Gói chế tác" với 3 hàng
radio, hàng đầu được chọn, mỗi hàng tên gói in đậm và phụ đề 2 dòng mô tả + giá
("Tượng chân dung Premium" / "Resin SLA, hoàn thiện thủ công" / "1.200.000 ₫";
"Tượng chân dung Standard" / "Resin tiêu chuẩn" / "750.000 ₫"; "Tượng mini kỷ vật" /
"PLA, 8-10cm" / "320.000 ₫"); thẻ "Kích thước tượng" với "15 cm" in đậm màu nhấn ở
góc phải tiêu đề và thanh trượt 10-30; thẻ "Vật liệu in" radio "High-Detail Resin
SLA" kèm "+ 150.000 ₫" và "PLA tiêu chuẩn"; thẻ "Đế trưng bày" radio "Đế gỗ óc chó
tự nhiên" kèm "+ 200.000 ₫" và "Đế tiêu chuẩn"; thẻ "Khắc tên trên đế" ô nhập viền
ngoài placeholder "Ví dụ: Gia đình An · 2026" bộ đếm 0/60; thẻ "Báo giá" chỉ có đoạn
chữ phụ "Chọn cấu hình rồi nhấn "Nhận báo giá" để hệ thống tính giá theo thể tích,
vật liệu và phí vận chuyển."; thanh dưới cố định chỉ một nút chính rộng hết hàng
"Nhận báo giá", không hiện số tiền.

MÀN 3 "Cấu hình đơn in 3D (ConfigurePrintScreen)" — y như màn 2 nhưng đã có báo giá:
thẻ "Báo giá" gồm các hàng "Giá chế tác cơ bản" 1.200.000 ₫, "Phí cá nhân hóa"
350.000 ₫, "Phí vận chuyển" 50.000 ₫, đường kẻ, "Tổng cộng" 1.600.000 ₫ in đậm màu
nhấn, rồi dòng chữ mờ "Báo giá có hiệu lực đến 29/10/2026 18:00"; thanh dưới cố định
có bên trái nhãn "Tạm tính" trên số "1.600.000 ₫" cỡ 20px weight 800 màu nhấn, bên
phải nút chính "Tiếp tục đặt hàng".

MÀN 4 "Xác nhận đơn chế tác (CustomCheckoutScreen)" — app bar "Xác nhận đơn hàng";
thẻ "Địa chỉ giao hàng" với link "Quản lý" bên phải và 2 hàng radio (dòng đậm "An ·
0123456789", dòng phụ "12 Phố A, Phường A, Hà Nội"), hàng đầu được chọn; thẻ "Sản
phẩm chế tác" gồm icon khối 3D màu nhấn, dòng đậm "Kỷ vật 3D · Chân dung bà Hoa",
dòng phụ "15cm · High-Detail Resin SLA", bên phải "1.600.000 ₫" in đậm; thẻ "Phương
thức thanh toán" radio "Thanh toán khi nhận hàng (COD)" được chọn, "Ví MoMo",
"ZaloPay"; thẻ "Ghi chú cho đơn hàng" ô nhập nhiều dòng placeholder "Ví dụ: giao
buổi chiều, khắc tên lên đế gỗ…" bộ đếm 0/255; thẻ "Chi tiết thanh toán" các hàng
"Giá chế tác cơ bản" 1.200.000 ₫, "Phí cá nhân hóa" 350.000 ₫, "Phí giao hàng"
50.000 ₫, đường kẻ, "Tổng cộng" 1.600.000 ₫; thanh dưới cố định bên trái "Tổng thanh
toán" trên "1.600.000 ₫", bên phải nút chính "Đặt hàng".

MÀN 5 "Sản phẩm (ShopScreen)" — app bar "Sản phẩm" có icon giỏ hàng góc phải; ô tìm
kiếm viền ngoài nhãn "Tìm sản phẩm" kèm icon kính lúp; 3 hàng danh sách sản phẩm,
mỗi hàng tên in đậm, meta mô tả + giá, icon thêm vào giỏ thay cho chevron: "Tượng
chân dung Premium" / "Resin SLA, hoàn thiện thủ công · 1.200.000 ₫"; "Tượng chân
dung Standard" / "Resin tiêu chuẩn · 750.000 ₫"; "Tượng mini kỷ vật" / "PLA, 8-10cm ·
320.000 ₫" kèm pill hổ phách "Hết hàng" và icon thêm bị mờ; dưới danh sách nút chữ
"Xem thêm". Biến thể rỗng: dòng căn giữa "Không có sản phẩm."

MÀN 6 "Giỏ hàng (CartScreen)" — app bar "Giỏ hàng"; 2 hàng danh sách sản phẩm, mỗi
hàng thumbnail, tên in đậm "Tượng mini kỷ vật", meta "320.000 ₫", bộ số lượng bên
phải gồm icon trừ, số "2", icon cộng; dưới cùng dòng "Tổng cộng: 640.000 ₫" in đậm
và nút chính "Đặt hàng" (icon túi mua hàng). Biến thể rỗng: "Giỏ hàng đang trống."

MÀN 7 "Xác nhận đơn hàng (CheckoutScreen)" — app bar "Xác nhận đơn hàng"; thẻ "Địa
chỉ giao hàng" với link "Quản lý" và 2 hàng radio như màn 4; thẻ "Sản phẩm (2)" gồm
2 hàng (tên "Tượng mini kỷ vật" in đậm bên trái, dòng phụ "100.000 ₫ × 2", "200.000
₫" in đậm bên phải); thẻ "Phương thức thanh toán" radio "Thanh toán khi nhận hàng
(COD)" được chọn, "Ví MoMo", "ZaloPay"; thẻ "Ghi chú cho đơn hàng" placeholder "Ví
dụ: giao buổi chiều, khắc tên lên đế gỗ…" bộ đếm 0/255; thẻ "Chi tiết thanh toán"
các hàng "Tạm tính" 200.000 ₫, "Giảm giá" 0 ₫, "Phí giao hàng" 0 ₫, đường kẻ, "Tổng
cộng" 200.000 ₫; thanh dưới cố định bên trái "Tổng thanh toán" trên "200.000 ₫", bên
phải nút chính "Đặt hàng".

MÀN 8 "Địa chỉ giao hàng (AddressesScreen)" — app bar "Địa chỉ giao hàng"; 2 thẻ địa
chỉ, mỗi thẻ dòng đậm "An · 0123456789", dòng phụ "12 Phố A, Phường A, Hà Nội", hàng
nút chữ "Sửa" / "Xóa" / "Đặt mặc định"; thẻ đầu có icon tích xanh lá bên phải, dòng
"Địa chỉ mặc định" và không có nút "Đặt mặc định"; nút nổi dạng viên thuốc góc dưới
phải: icon cộng + "Thêm địa chỉ". Biến thể rỗng: "Bạn chưa có địa chỉ giao hàng."

MÀN 9 "Thêm địa chỉ (AddressFormScreen)" — app bar "Thêm địa chỉ"; 5 ô nhập viền
ngoài xếp dọc, mỗi ô nhãn nổi và bộ đếm: "Tên người nhận" (0/100), "Số điện thoại"
(0/30, bàn phím số), "Tỉnh / Thành phố" (0/100), "Phường / Xã" (0/100), "Địa chỉ chi
tiết" (0/255); dưới cùng nút chính "Lưu địa chỉ". Biến thể lỗi: dòng đỏ #EF4444 "Vui
lòng nhập tên người nhận." dưới ô đầu tiên.

MÀN 10 "Đặt hàng thành công (OrderSuccessScreen)" — app bar "Đặt hàng thành công"
không có mũi tên back; thẻ hero căn giữa với vòng tròn tích xanh lá 56px (#10B981),
dòng đậm 16px "Chúng tôi đã nhận được đơn hàng của bạn", dòng phụ "Mã đơn:
ORD-20261029-A1B2", pill hổ phách "Chờ xác nhận"; thẻ "Thông tin đơn hàng" các hàng
"Người nhận" An, "Số điện thoại" 0123456789, "Địa chỉ" 12 Phố A, Phường A, Hà Nội,
"Thanh toán" Thanh toán khi nhận hàng (COD), đường kẻ, "Tổng cộng" 200.000 ₫; thẻ
"Hoàn tất thanh toán" có dòng chữ phụ "Đơn hàng sẽ được xác nhận sau khi cổng thanh
toán báo thành công." và nút chính "Mở trang thanh toán"; cuối trang nút chính "Theo
dõi đơn hàng" rồi nút phụ "Về trang chủ".

MÀN 11 "Đơn hàng của tôi (OrdersListScreen)" — app bar "Đơn hàng của tôi"; hàng chip
lọc cuộn ngang "Tất cả" (đang chọn, nền màu nhấn), "Chờ xác nhận (1)", "Đã xác
nhận", "Đang in 3D", "Đang giao", "Hoàn tất", "Đã hủy"; 4 thẻ đơn hàng cách nhau
12px, mỗi thẻ hàng trên gồm mã đơn "ORD-20261029-A1B2" in đậm và pill trạng thái,
dòng phụ 13px "Tượng mini kỷ vật", hàng dưới chữ mờ 12px "1 sản phẩm" và "200.000 ₫"
cỡ 15px weight 800 màu nhấn; pill lần lượt "Chờ xác nhận" hổ phách, "Đang in 3D"
tím, "Đang giao" cam, "Hoàn tất" xanh lá; dưới danh sách nút chữ căn giữa "Xem
thêm". Biến thể rỗng: dòng căn giữa "Bạn chưa có đơn hàng nào."

MÀN 12 "Chi tiết đơn hàng (OrderDetailScreen)" — app bar "ORD-20261029-A1B2"; thẻ
"Trạng thái đơn hàng" với pill tím "Đang in 3D" ở tiêu đề và timeline dọc 5 bước nối
bằng đường 2px: "Chờ xác nhận", "Đã xác nhận", "Đang in 3D", "Đang giao", "Đã giao"
— ba bước đầu vòng tròn tích đầy màu nhấn với đường nối màu nhấn, nhãn bước hiện tại
in đậm, hai bước cuối vòng tròn rỗng xám mờ với đường nối #F1F0F5 và nhãn mờ, không
có dòng mô tả phụ nào dưới các bước; thẻ "Sản phẩm" có "Tượng mini kỷ vật" in đậm
bên trái và "200.000 ₫" in đậm bên phải, dòng phụ "100.000 ₫ × 2 · Resin · 12-15cm ·
Phủ bóng UV", dòng màu tím "Khắc tên: Gia đình An"; thẻ "Giao hàng" các hàng "Người
nhận", "Số điện thoại", "Địa chỉ", "Đơn vị vận chuyển" Giao Hàng Nhanh (GHN
Express), "Mã vận đơn" GHN-20261029-A1B2, "Ghi chú"; thẻ "Thanh toán" các hàng
"Phương thức" Ví MoMo, "Tình trạng" Chờ thanh toán, "Đã thanh toán" 0 ₫, "Còn lại"
200.000 ₫; thẻ "Chi tiết giá" các hàng "Tạm tính", "Giảm giá", "Phí giao hàng", "Phí
cá nhân hóa", "Phụ phí sản xuất", đường kẻ, "Tổng cộng" 200.000 ₫; thanh dưới cố
định 2 nút bằng nhau: nút phụ "Hủy đơn hàng" màu đỏ #EF4444 và nút chính "Thanh
toán".

MÀN 13 "Thanh toán (PaymentGatewayScreen)" — app bar "Thanh toán" với mũi tên back
và thanh tiến độ mảnh màu nhấn ngay dưới app bar; phần còn lại là trang cổng thanh
toán nhúng: bảng thanh toán kiểu MoMo căn giữa với số tiền "200.000 ₫", khối mã QR
và dòng "Quét mã để hoàn tất thanh toán".

MÀN 14 "Đánh giá mô hình (RateShareScreen)" — app bar "Đánh giá mô hình"; thẻ đầu
hiện tên mô hình "Chân dung bà Hoa" in đậm và mã phiên màu mờ; hàng 5 ngôi sao cỡ
lớn màu nhấn với 4 sao đã chọn; ô nhập nhiều dòng viền ngoài nhãn "Nhận xét"; nút
chính "Lưu đánh giá" và nút phụ "Xóa đánh giá của tôi" màu đỏ #EF4444.
Liên kết luồng:
- Luồng scan kết thúc ở màn 1; nhấn "Đặt in 3D vật lý" ở màn 1 là điểm bắt đầu luồng
  đặt hàng: màn 1 → màn 2 → (nhận báo giá) màn 3 → màn 4 → màn 10.
- Luồng catalog: màn 5 → màn 6 → màn 7 → màn 10.
- Màn 8 ↔ màn 9; màn 8 mở từ màn 4 và màn 7 qua link "Quản lý".
- Thanh toán là bước cuối: màn 10 → màn 13 (nếu chọn ví điện tử). Xác nhận đơn xong
  thì kết thúc luồng — nút "Về trang chủ" ở màn 10 đưa người dùng về main screen.
- Theo dõi về sau: màn 11 → màn 12; màn 12 → màn 13 khi còn khoản phải trả.
- Màn 14 mở từ màn 1.
```

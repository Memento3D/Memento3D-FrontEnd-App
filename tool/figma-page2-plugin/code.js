// Memento3D — sắp xếp và đồng bộ Page 2 với code Flutter trong lib/features/orders.
//
// Chạy: Figma desktop → Plugins → Development → Import plugin from manifest →
// chọn manifest.json cạnh file này → Run. Mọi thay đổi đều ghi ra console
// (Plugins → Development → Open console) và undo được bằng Ctrl+Z một lần.
//
// Bật/tắt từng phần ở đây:
const STEPS = {
  viewerCta: true, // chèn nút "Đặt in 3D vật lý" vào các frame 3D Model Viewer
  layout: true, // xếp frame theo thứ tự luồng + thêm nhãn section
  content: true, // xoá các dòng mô tả backend không có dữ liệu
  newFrames: true, // tạo frame cho màn đã có trong code nhưng chưa có trên Page 2
};

// Điểm nối scan → order: các frame viewer cần có nút đặt in.
const VIEWER_FRAME_IDS = ['11:1742', '11:1981'];
const CTA_LABEL = 'Đặt in 3D vật lý';
const CTA_ANCHOR = 'Kiểm tra khả năng in'; // nút được clone để giữ nguyên style

const PAGE_NAME = 'Page 2';
const GAP = 80; // khoảng cách giữa các frame trong một hàng
const ROW_GAP = 220; // khoảng cách giữa các hàng
const ORIGIN = { x: 0, y: 0 };

// Thứ tự luồng đặt hàng, theo đúng điều hướng trong app.
const FLOW = [
  '3D Model Viewer — Memento3D (UC-07)',
  'Model 3D (ModelViewerEntryScreen)',
  'Cấu hình đơn in 3D (ConfigurePrintScreen)',
  'Cấu hình đơn in 3D — chưa báo giá (ConfigurePrintScreen · state)',
  'Xác nhận đơn chế tác (CustomCheckoutScreen)',
  'Giỏ hàng (CartScreen)',
  'Xác nhận đơn hàng (CheckoutScreen)',
  'Đặt hàng thành công (OrderSuccessScreen)',
  'Đơn hàng của tôi (OrdersListScreen)',
  'Chi tiết đơn hàng ORD-20261029-A1B2 (OrderDetailScreen)',
  'Thanh toán (PaymentGatewayScreen)',
];

// Frame trùng với bộ chuẩn ở trên; giữ nguyên, chỉ dồn xuống hàng riêng.
const LEGACY_IDS = ['16:931', '16:823', '16:1133', '16:1441'];

// Các dòng chỉ có trong design: API đơn hàng không trả tiến độ in, mốc thời gian
// từng bước hay ngày giao dự kiến, nên app không bao giờ hiển thị được.
const UNSUPPORTED_TEXTS = [
  'Tiến độ 65%',
  'Đang xử lý lớp quang hóa UV mịn 50µm',
  'Dự kiến giao ngày 31/10',
  'Giao tận tay khách hàng',
];

const TOKENS = {
  bg: hex('#FBFBFE'),
  surface: hex('#FFFFFF'),
  border: hex('#F1F0F5'),
  textPrimary: hex('#111827'),
  textSecondary: hex('#6B7280'),
  textMuted: hex('#9CA3AF'),
  accent: hex('#6366F1'),
  purpleBg: hex('#EDE9FE'),
  purpleText: hex('#7C3AED'),
};

function hex(value) {
  const n = parseInt(value.slice(1), 16);
  return {
    r: ((n >> 16) & 255) / 255,
    g: ((n >> 8) & 255) / 255,
    b: (n & 255) / 255,
  };
}

const log = [];
function note(line) {
  log.push(line);
  console.log(line);
}

async function findPage() {
  if (figma.loadAllPagesAsync) await figma.loadAllPagesAsync();
  const page =
    figma.root.children.find((p) => p.name === PAGE_NAME) || figma.currentPage;
  note(`Page: ${page.name} (${page.children.length} node)`);
  return page;
}

async function loadFonts() {
  await Promise.all([
    figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' }),
    figma.loadFontAsync({ family: 'Inter', style: 'Bold' }),
  ]);
}

function text(characters, { size = 13, style = 'Regular', color } = {}) {
  const node = figma.createText();
  node.fontName = { family: 'Inter', style };
  node.fontSize = size;
  node.characters = characters;
  node.fills = [{ type: 'SOLID', color: color || TOKENS.textPrimary }];
  return node;
}

function column(children, options = {}) {
  const frame = figma.createFrame();
  frame.layoutMode = 'VERTICAL';
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = options.width ? 'FIXED' : 'AUTO';
  frame.itemSpacing = options.spacing == null ? 8 : options.spacing;
  frame.paddingTop = frame.paddingBottom = options.padding == null ? 0 : options.padding;
  frame.paddingLeft = frame.paddingRight = options.padding == null ? 0 : options.padding;
  frame.fills = options.fill ? [{ type: 'SOLID', color: options.fill }] : [];
  if (options.radius) frame.cornerRadius = options.radius;
  if (options.stroke) {
    frame.strokes = [{ type: 'SOLID', color: options.stroke }];
    frame.strokeWeight = 1;
  }
  for (const child of children) frame.appendChild(child);
  if (options.width) frame.resize(options.width, frame.height);
  if (options.name) frame.name = options.name;
  return frame;
}

function row(children, options = {}) {
  const frame = column(children, options);
  frame.layoutMode = 'HORIZONTAL';
  frame.counterAxisAlignItems = options.align || 'CENTER';
  if (options.width) {
    frame.layoutSizingHorizontal = 'FIXED';
    frame.resize(options.width, frame.height);
  }
  return frame;
}

function card(title, children, trailing) {
  const header = row(
    [
      grow(text(title, { size: 15, style: 'Bold' })),
      trailing || text('', { size: 11 }),
    ],
    { width: 358 - 32, spacing: 8 },
  );
  return column([header, ...children], {
    width: 358,
    padding: 16,
    spacing: 12,
    fill: TOKENS.surface,
    stroke: TOKENS.border,
    radius: 20,
  });
}

function grow(node) {
  const wrapper = row([node], { spacing: 0 });
  wrapper.layoutGrow = 1;
  node.layoutGrow = 1;
  return wrapper;
}

function infoRow(label, value, emphasized) {
  return row(
    [
      grow(
        text(label, {
          size: emphasized ? 15 : 13,
          style: emphasized ? 'Bold' : 'Medium',
          color: emphasized ? TOKENS.textPrimary : TOKENS.textSecondary,
        }),
      ),
      text(value, {
        size: emphasized ? 17 : 13,
        style: 'Bold',
        color: emphasized ? TOKENS.accent : TOKENS.textPrimary,
      }),
    ],
    { width: 358 - 32, spacing: 8 },
  );
}

function pill(label) {
  const node = column([text(label, { size: 11, style: 'Bold', color: TOKENS.purpleText })], {
    padding: 6,
    fill: TOKENS.purpleBg,
    radius: 999,
  });
  node.paddingTop = node.paddingBottom = 3;
  node.paddingLeft = node.paddingRight = 10;
  return node;
}

function button(label, filled) {
  const node = column(
    [
      text(label, {
        size: 15,
        style: 'Bold',
        color: filled ? hex('#FFFFFF') : TOKENS.accent,
      }),
    ],
    {
      width: 358,
      padding: 16,
      fill: filled ? TOKENS.accent : undefined,
      stroke: filled ? undefined : TOKENS.accent,
      radius: 16,
    },
  );
  node.counterAxisAlignItems = 'CENTER';
  return node;
}

function screen(name, children) {
  const frame = column(children, {
    width: 390,
    padding: 16,
    spacing: 16,
    fill: TOKENS.bg,
    name,
  });
  return frame;
}

// --- Bước 1: layout -------------------------------------------------------

function arrange(page, created) {
  const byName = new Map();
  for (const node of page.children) if (node.type === 'FRAME') byName.set(node.name, node);
  for (const node of created) byName.set(node.name, node);

  const flowFrames = [];
  for (const name of FLOW) {
    const frame = byName.get(name);
    if (frame) flowFrames.push(frame);
    else note(`⚠ không thấy frame "${name}"`);
  }
  const legacy = page.children.filter(
    (n) => n.type === 'FRAME' && LEGACY_IDS.indexOf(n.id) !== -1,
  );
  const used = new Set([...flowFrames, ...legacy].map((n) => n.id));
  const rest = page.children.filter((n) => n.type === 'FRAME' && !used.has(n.id));

  let y = ORIGIN.y;
  y = placeRow('LUỒNG ĐẶT HÀNG — bản chuẩn, khớp code Flutter', flowFrames, page, y);
  y = placeRow('LUỒNG ĐẶT HÀNG — bản cũ, trùng với hàng trên', legacy, page, y);
  placeRow('AUTH & SCAN', rest, page, y);
}

function placeRow(label, frames, page, y) {
  if (!frames.length) return y;
  const heading = text(label, { size: 24, style: 'Bold', color: TOKENS.textMuted });
  heading.name = `· ${label}`;
  page.appendChild(heading);
  heading.x = ORIGIN.x;
  heading.y = y;

  let x = ORIGIN.x;
  const top = y + 48;
  let tallest = 0;
  for (const frame of frames) {
    frame.x = x;
    frame.y = top;
    x += frame.width + GAP;
    tallest = Math.max(tallest, frame.height);
  }
  note(`${label}: ${frames.length} frame`);
  return top + tallest + ROW_GAP;
}

// --- Bước 0: nút đặt in trên màn viewer -----------------------------------

function findText(node, characters) {
  if (node.type === 'TEXT' && node.characters.trim() === characters) return node;
  for (const child of node.children || []) {
    const hit = findText(child, characters);
    if (hit) return hit;
  }
  return null;
}

// Leo từ text node lên tới node có bề ngang cỡ một nút full-width: clone node đó
// thì nút mới thừa hưởng nguyên nền, bo góc, padding và icon của bản gốc.
function buttonAncestor(textNode, frameWidth) {
  let node = textNode;
  while (node.parent && node.parent.id !== node.parent.parent?.id) {
    const parent = node.parent;
    if (!parent || parent.type === 'PAGE') break;
    if (node.width >= frameWidth * 0.6 && node !== textNode) return node;
    node = parent;
    if (node.width >= frameWidth * 0.95) return node === textNode ? null : node;
  }
  return null;
}

function addViewerCta(page) {
  const frames = page.children.filter(
    (n) =>
      n.type === 'FRAME' &&
      (VIEWER_FRAME_IDS.indexOf(n.id) !== -1 ||
        /^3D Model Viewer/.test(n.name)),
  );
  if (!frames.length) note('⚠ không thấy frame 3D Model Viewer nào');

  for (const frame of frames) {
    if (findText(frame, CTA_LABEL)) {
      note(`= "${frame.name}" đã có nút "${CTA_LABEL}", bỏ qua`);
      continue;
    }
    const anchorText = findText(frame, CTA_ANCHOR);
    if (!anchorText) {
      note(`⚠ "${frame.name}": không thấy nút "${CTA_ANCHOR}" để clone`);
      continue;
    }
    const anchor = buttonAncestor(anchorText, frame.width);
    if (!anchor || !anchor.parent) {
      note(`⚠ "${frame.name}": không xác định được khối nút`);
      continue;
    }
    const parent = anchor.parent;
    const clone = anchor.clone();
    const label = findText(clone, CTA_ANCHOR);
    if (label) label.characters = CTA_LABEL;
    clone.name = CTA_LABEL;

    const index = parent.children.indexOf(anchor);
    parent.insertChild(index + 1, clone);

    // Khung không auto-layout: tự đẩy nút mới xuống và dịch các node bên dưới.
    if (parent.layoutMode === 'NONE' || parent.layoutMode === undefined) {
      const gap = 12;
      clone.y = anchor.y + anchor.height + gap;
      for (const sibling of parent.children) {
        if (sibling === clone || sibling === anchor) continue;
        if (sibling.y > anchor.y) sibling.y += clone.height + gap;
      }
      if (parent.type === 'FRAME' && parent.clipsContent === false) {
        parent.resize(parent.width, parent.height + clone.height + gap);
      }
    }
    note(`+ "${frame.name}": chèn nút "${CTA_LABEL}" ngay dưới "${CTA_ANCHOR}"`);
    note('  (icon trong nút là bản sao của icon máy in — đổi thủ công nếu cần)');
  }
}

// --- Bước 2: nội dung -----------------------------------------------------

function fixContent(page) {
  let removed = 0;
  const walk = (node) => {
    if (node.type === 'TEXT' && UNSUPPORTED_TEXTS.indexOf(node.characters.trim()) !== -1) {
      note(`– xoá dòng không có dữ liệu: "${node.characters.trim()}"`);
      node.remove();
      removed += 1;
      return;
    }
    if ('children' in node) for (const child of [...node.children]) walk(child);
  };
  for (const frame of [...page.children]) walk(frame);
  note(`Nội dung: xoá ${removed} text node`);
}

// --- Bước 3: frame còn thiếu ---------------------------------------------

function buildCart() {
  return screen('Giỏ hàng (CartScreen)', [
    text('Giỏ hàng', { size: 20, style: 'Bold' }),
    card('Sản phẩm (1)', [
      row(
        [
          grow(
            column(
              [
                text('Tượng mini kỷ vật', { size: 14, style: 'Semi Bold' }),
                text('100.000 ₫ × 2', { size: 12, color: TOKENS.textSecondary }),
              ],
              { spacing: 4 },
            ),
          ),
          text('200.000 ₫', { size: 13, style: 'Bold' }),
        ],
        { width: 358 - 32, spacing: 8 },
      ),
    ]),
    card('Tổng cộng', [infoRow('Tổng cộng', '200.000 ₫', true)]),
    button('Đặt hàng', true),
  ]);
}

function buildConfigNoQuote() {
  return screen('Cấu hình đơn in 3D — chưa báo giá (ConfigurePrintScreen · state)', [
    text('Cấu hình đơn in 3D', { size: 20, style: 'Bold' }),
    card(
      'Mô hình đặt in',
      [
        column(
          [
            text('Chân dung bà Hoa', { size: 14, style: 'Bold' }),
            text('Mã phiên: s-20261029-77', { size: 12, color: TOKENS.textSecondary }),
          ],
          { spacing: 4 },
        ),
      ],
      pill('Tạo từ bản Scan 3D'),
    ),
    card('Kích thước tượng', [
      row(
        [
          text('10 cm', { size: 12, color: TOKENS.textMuted }),
          grow(text('', { size: 12 })),
          text('30 cm', { size: 12, color: TOKENS.textMuted }),
        ],
        { width: 358 - 32, spacing: 8 },
      ),
    ]),
    card('Báo giá', [
      text(
        'Chọn cấu hình rồi nhấn "Nhận báo giá" để hệ thống tính giá theo thể tích, vật liệu và phí vận chuyển.',
        { size: 13, color: TOKENS.textSecondary },
      ),
    ]),
    button('Nhận báo giá', true),
  ]);
}

function buildShop() {
  return screen('Sản phẩm (ShopScreen)', [
    text('Sản phẩm', { size: 20, style: 'Bold' }),
    card('Tìm sản phẩm', [
      text('Tìm sản phẩm…', { size: 13, color: TOKENS.textMuted }),
    ]),
    card(
      'Tượng chân dung Premium',
      [
        text('Resin SLA, hoàn thiện thủ công', { size: 12, color: TOKENS.textSecondary }),
        infoRow('Giá', '1.200.000 ₫'),
      ],
      pill('Còn hàng'),
    ),
    card('Tượng mini kỷ vật', [
      text('PLA, 8-10cm', { size: 12, color: TOKENS.textSecondary }),
      infoRow('Giá', '320.000 ₫'),
    ]),
  ]);
}

function createMissing(page) {
  const existing = new Set(page.children.map((n) => n.name));
  const builders = [buildCart, buildConfigNoQuote, buildShop];
  const created = [];
  for (const build of builders) {
    const frame = build();
    if (existing.has(frame.name)) {
      note(`= đã có "${frame.name}", bỏ qua`);
      frame.remove();
      continue;
    }
    page.appendChild(frame);
    created.push(frame);
    note(`+ tạo frame "${frame.name}"`);
  }
  return created;
}

// --- main -----------------------------------------------------------------

(async () => {
  try {
    const page = await findPage();
    await loadFonts();
    if (STEPS.viewerCta) addViewerCta(page);
    const created = STEPS.newFrames ? createMissing(page) : [];
    if (STEPS.content) fixContent(page);
    if (STEPS.layout) arrange(page, created);
    figma.notify(`Xong: ${log.length} thay đổi. Xem console để biết chi tiết.`);
  } catch (error) {
    console.error(error);
    figma.notify(`Lỗi: ${error.message}`, { error: true });
  } finally {
    figma.closePlugin();
  }
})();

const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, TableOfContents
} = require("docx");

// ===== CONSTANTS =====
const PAGE_WIDTH = 12240;
const PAGE_HEIGHT = 15840;
const MARGIN = 1440;
const CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN; // 9360

const BLUE = "1F4E79";
const DARK_GRAY = "333333";
const WHITE = "FFFFFF";
const BORDER_COLOR = "B4C6E7";

const border = { style: BorderStyle.SINGLE, size: 1, color: BORDER_COLOR };
const borders = { top: border, bottom: border, left: border, right: border };
const cellMargins = { top: 60, bottom: 60, left: 100, right: 100 };

const headerShading = { fill: BLUE, type: ShadingType.CLEAR };
const altRowShading = { fill: "F2F7FB", type: ShadingType.CLEAR };

// ===== HELPERS =====
function hCell(text, width) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: headerShading, margins: cellMargins,
    verticalAlign: "center",
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text, bold: true, color: WHITE, font: "Arial", size: 20 })] })]
  });
}

function cell(text, width, opts = {}) {
  const shading = opts.shaded ? altRowShading : undefined;
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading, margins: cellMargins,
    children: [new Paragraph({
      alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
      children: [new TextRun({ text: String(text), font: "Arial", size: 20, bold: opts.bold || false })]
    })]
  });
}

function multiCell(lines, width, opts = {}) {
  const shading = opts.shaded ? altRowShading : undefined;
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading, margins: cellMargins,
    children: lines.map(l => new Paragraph({
      children: [new TextRun({ text: l, font: "Arial", size: 20 })]
    }))
  });
}

function heading(text, level) {
  return new Paragraph({ heading: level, spacing: { before: 240, after: 120 }, children: [new TextRun({ text, font: "Arial" })] });
}

function body(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120 },
    alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
    children: [new TextRun({ text, font: "Arial", size: 22, bold: opts.bold || false, italics: opts.italic || false, color: opts.color || DARK_GRAY })]
  });
}

function bullet(text, ref = "bullets", level = 0) {
  return new Paragraph({
    numbering: { reference: ref, level },
    children: [new TextRun({ text, font: "Arial", size: 22 })]
  });
}

function numberedItem(text, ref = "numbers", level = 0) {
  return new Paragraph({
    numbering: { reference: ref, level },
    children: [new TextRun({ text, font: "Arial", size: 22 })]
  });
}

function spacer(after = 100) {
  return new Paragraph({ spacing: { after }, children: [] });
}

// ===== TITLE PAGE =====
const titlePage = [
  new Paragraph({ spacing: { before: 3000 }, children: [] }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 200 },
    children: [new TextRun({ text: "FIDO BANK", font: "Arial", size: 44, bold: true, color: BLUE })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "MARS — Avtomatlashtirilgan Bank Tizimi", font: "Arial", size: 28, color: DARK_GRAY })]
  }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 },
    children: [new TextRun({ text: "________________________________________", color: BLUE, font: "Arial", size: 22 })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 200 },
    children: [new TextRun({ text: "BIZNES TALAB", font: "Arial", size: 40, bold: true, color: BLUE })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "BT-001: Mijozlar moduli (core_cif)", font: "Arial", size: 28, color: DARK_GRAY })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "Customer Information File", font: "Arial", size: 24, italics: true, color: "666666" })]
  }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({
    width: { size: 5000, type: WidthType.DXA },
    columnWidths: [2000, 3000],
    rows: [
      new TableRow({ children: [cell("Hujjat raqami:", 2000, { bold: true }), cell("BT-001", 3000)] }),
      new TableRow({ children: [cell("Versiya:", 2000, { bold: true, shaded: true }), cell("3.0", 3000, { shaded: true })] }),
      new TableRow({ children: [cell("Sana:", 2000, { bold: true }), cell("2026-05-26", 3000)] }),
      new TableRow({ children: [cell("Modul:", 2000, { bold: true, shaded: true }), cell("core_cif (Mijozlar)", 3000, { shaded: true })] }),
      new TableRow({ children: [cell("Holat:", 2000, { bold: true }), cell("Qoralama", 3000)] }),
      new TableRow({ children: [cell("Muallif:", 2000, { bold: true, shaded: true }), cell("MARS loyiha guruhi", 3000, { shaded: true })] }),
    ]
  }),
  new Paragraph({ children: [new PageBreak()] })
];

// ===== TABLE OF CONTENTS =====
const tocSection = [
  heading("Mundarija", HeadingLevel.HEADING_1),
  new TableOfContents("Mundarija", { hyperlink: true, headingStyleRange: "1-3" }),
  new Paragraph({ children: [new PageBreak()] })
];

// ===== 1. UMUMIY MA'LUMOT =====
const section1 = [
  heading("1. Umumiy ma'lumot", HeadingLevel.HEADING_1),

  heading("1.1. Maqsad", HeadingLevel.HEADING_2),
  body("Ushbu hujjat MARS avtomatlashtirilgan bank tizimining Mijozlar moduli (core_cif) uchun biznes talablarni belgilaydi."),
  body("Modul bankning barcha mijozlari — jismoniy va yuridik shaxslar haqidagi ma'lumotlarni markazlashtirilgan holda boshqarish, saqlash va taqdim etish uchun mo'ljallangan."),

  heading("1.2. Qamrov", HeadingLevel.HEADING_2),
  body("Hujjat quyidagi biznes sohalarni qamrab oladi:"),
  bullet("Jismoniy va yuridik shaxs mijozlarni ro'yxatga olish"),
  bullet("Mijoz ma'lumotlarini yangilash va boshqarish"),
  bullet("Mijoz identifikatsiya hujjatlarini saqlash"),
  bullet("CIF (Customer Information File) raqamlash tizimi"),
  bullet("Mijozlar bo'yicha qidiruv va filtrlash"),
  bullet("Mijoz holati (status) boshqaruvi"),
  bullet("KYC (Know Your Customer) va AML (Anti-Money Laundering) talablari"),
  bullet("PEP (Politically Exposed Person) nazorati"),

  heading("1.3. Maqsadli auditoriya", HeadingLevel.HEADING_2),
  body("Ushbu hujjat quyidagi tomonlar uchun mo'ljallangan:"),
  bullet("Biznes tahlilchilar va loyiha rahbarlari"),
  bullet("Dasturchilar (texnik topshiriq uchun asos sifatida)"),
  bullet("Bank operatsion xodimlari (jarayonlarni tushunish uchun)"),
  bullet("Sifat nazorati bo'limi (test stsenariylarini shakllantirish uchun)"),

  heading("1.4. Atamalar va qisqartmalar", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Atama", 2400), hCell("Ta'rifi", 6960)] }),
      new TableRow({ children: [cell("CIF", 2400), cell("Customer Information File — mijoz ma'lumotlar bazasi", 6960)] }),
      new TableRow({ children: [cell("ABS", 2400, { shaded: true }), cell("Avtomatlashtirilgan Bank Tizimi", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("MARS", 2400), cell("Loyihaning ishchi nomi (ABS tizimi)", 6960)] }),
      new TableRow({ children: [cell("FYaSh", 2400, { shaded: true }), cell("Jismoniy shaxs — fuqaro mijoz", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("YuSh", 2400), cell("Yuridik shaxs — tashkilot/korxona mijoz", 6960)] }),
      new TableRow({ children: [cell("STIR", 2400, { shaded: true }), cell("Soliq to'lovchining identifikatsiya raqami (9 xonali)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("PINFL", 2400), cell("Jismoniy shaxsning shaxsiy identifikatsiya raqami (14 xonali)", 6960)] }),
      new TableRow({ children: [cell("MFO", 2400, { shaded: true }), cell("Bank bo'limi (filial) kodi", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("KYC", 2400), cell("Know Your Customer — mijozni aniqlash tamoyili", 6960)] }),
      new TableRow({ children: [cell("AML", 2400, { shaded: true }), cell("Anti-Money Laundering — pul yuvishga qarshi kurash", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("PEP", 2400), cell("Politically Exposed Person — siyosiy lavozimli shaxs", 6960)] }),
      new TableRow({ children: [cell("OKED", 2400, { shaded: true }), cell("O'zbekiston iqtisodiy faoliyat turlari klassifikatori", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("CBU", 2400), cell("O'zbekiston Respublikasi Markaziy banki", 6960)] }),
      new TableRow({ children: [cell("Maker-Checker", 2400, { shaded: true }), cell("Ikki bosqichli tasdiqlash — bir xodim yaratadi, boshqa xodim tasdiqlaydi", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Rezident", 2400), cell("O'zbekiston hududida doimiy yashash huquqiga ega shaxs", 6960)] }),
      new TableRow({ children: [cell("Norezident", 2400, { shaded: true }), cell("O'zbekiston hududida doimiy yashash huquqiga ega bo'lmagan xorijiy fuqaro", 6960, { shaded: true })] }),
    ]
  }),
  spacer(200),
];

// ===== 2. BIZNES JARAYONLAR =====
const section2 = [
  heading("2. Biznes jarayonlar", HeadingLevel.HEADING_1),

  // --- BP-001 ---
  heading("2.1. BP-001: Yangi mijoz ro'yxatga olish", HeadingLevel.HEADING_2),
  body("Yangi mijozni bank tizimida ro'yxatga olish jarayoni. Mijoz jismoniy yoki yuridik shaxs bo'lishi mumkin."),

  heading("2.1.1. Jismoniy shaxs (fuqaro)", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-001-FYaSh", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor (tasdiqlash uchun), Mijoz (fuqaro)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Fuqaro bank filialiga murojaat qilgan, shaxsini tasdiqlovchi hujjatlari bor", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Mijozga CIF raqam tayinlangan, barcha ma'lumotlar tizimga kiritilgan, Supervisor tasdiqlagan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator yangi mijoz formasini ochadi va mijoz turini tanlaydi: Jismoniy shaxs"),
  numberedItem("Shaxsiy ma'lumotlarni kiritadi: familiya, ism, otasining ismi, tug'ilgan sana va joyi, jinsi"),
  numberedItem("Identifikatsiya ma'lumotlarini kiritadi: PINFL raqami, passport/ID karta ma'lumotlari (seriya, raqam, berilgan sana, amal qilish muddati, kim tomonidan berilgan)"),
  numberedItem("Fuqarolik va rezidentlik ma'lumotlarini belgilaydi"),
  numberedItem("Aloqa ma'lumotlarini kiritadi: telefon raqam, email, yashash manzili, ro'yxatga olingan manzil"),
  numberedItem("Ish joyi ma'lumotlarini kiritadi: tashkilot nomi, lavozimi (ixtiyoriy)"),
  numberedItem("PEP (siyosiy lavozimli shaxs) belgisini belgilaydi"),
  numberedItem("KYC ma'lumotlarini to'ldiradi: xavf darajasi, iqtisodiyot sektori, bank xizmatidan maqsad"),
  numberedItem("Tizim avtomatik ravishda: CIF raqam generatsiya qiladi, PINFL bo'yicha dublikat tekshiradi, KYC xavf darajasini belgilaydi"),
  numberedItem("Operator ma'lumotlarni saqlaydi — mijoz 'Tasdiqlash kutilmoqda' holatiga tushadi"),
  numberedItem("Supervisor mijoz ma'lumotlarini ko'rib chiqadi va tasdiqlaydi (Maker-Checker)"),
  numberedItem("Tasdiqlangandan so'ng mijoz holati FAOL ga o'tadi"),

  heading("2.1.2. Yuridik shaxs (tashkilot)", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-001-YuSh", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor (tasdiqlash uchun), Tashkilot vakili", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Tashkilot vakili bank filialiga murojaat qilgan, ta'sis hujjatlari mavjud", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Tashkilotga CIF raqam tayinlangan, barcha ma'lumotlar tizimga kiritilgan, Supervisor tasdiqlagan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator yangi mijoz formasini ochadi va mijoz turini tanlaydi: Yuridik shaxs"),
  numberedItem("Tashkilot ma'lumotlarini kiritadi: qisqa nomi, to'liq rasmiy nomi, tashkiliy-huquqiy shakli (MChJ, AJ, YaTT, QK, UP va h.k.)"),
  numberedItem("Davlat ro'yxati ma'lumotlarini kiritadi: STIR, ro'yxat raqami, sanasi, ro'yxatga olgan organ"),
  numberedItem("OKED faoliyat turi kodini kiritadi"),
  numberedItem("Rahbar ma'lumotlarini kiritadi: FIO, lavozimi"),
  numberedItem("Bosh hisobchi FIO sini kiritadi"),
  numberedItem("Aloqa ma'lumotlarini kiritadi: telefon, email, yuridik manzil, haqiqiy manzil"),
  numberedItem("Bank rekvizitlarini kiritadi: xizmat ko'rsatuvchi bank nomi, MFO, hisob raqami (agar mavjud bo'lsa)"),
  numberedItem("Iqtisodiyot sektori va KYC xavf darajasini belgilaydi"),
  numberedItem("PEP belgisini belgilaydi (tashkilot rahbari uchun)"),
  numberedItem("Tizim avtomatik ravishda: CIF raqam generatsiya qiladi, STIR bo'yicha dublikat tekshiradi"),
  numberedItem("Operator ma'lumotlarni saqlaydi — mijoz 'Tasdiqlash kutilmoqda' holatiga tushadi"),
  numberedItem("Supervisor mijoz ma'lumotlarini ko'rib chiqadi va tasdiqlaydi (Maker-Checker)"),
  numberedItem("Tasdiqlangandan so'ng mijoz holati FAOL ga o'tadi"),

  // --- BP-002 ---
  heading("2.2. BP-002: Mijoz ma'lumotlarini yangilash", HeadingLevel.HEADING_2),
  body("Mavjud mijoz ma'lumotlarini o'zgartirish jarayoni. Har qanday o'zgarish tizimda saqlanadi va kuzatiladi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-002", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Mijoz tizimda mavjud (CIF raqam bor), FAOL holatda, o'zgartirish uchun asos mavjud", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Ma'lumotlar yangilangan, o'zgarish tarixi saqlangan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator mijozni qidiradi (CIF, FIO, PINFL/STIR bo'yicha)"),
  numberedItem("Mijozning joriy ma'lumotlari ekranda ko'rsatiladi"),
  numberedItem("Operator kerakli ma'lumotlarni o'zgartiradi"),
  numberedItem("Tizim o'zgarishlarni tekshiradi (validatsiya)"),
  numberedItem("Eski va yangi qiymatlar o'zgarishlar tarixiga yoziladi"),
  numberedItem("Yangilangan ma'lumotlar saqlanadi"),
  spacer(),
  body("Muhim: CIF raqam va mijoz turi (jismoniy/yuridik) o'zgartirilmaydi.", { italic: true }),

  // --- BP-003 ---
  heading("2.3. BP-003: Mijozni qidirish", HeadingLevel.HEADING_2),
  body("Mijozlarni turli mezonlar bo'yicha qidirish imkoniyati."),
  spacer(),
  body("Qidiruv mezonlari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3200, 3080, 3080],
    rows: [
      new TableRow({ children: [hCell("Mezon", 3200), hCell("Qidiruv turi", 3080), hCell("Natija", 3080)] }),
      new TableRow({ children: [cell("CIF raqami", 3200), cell("Aniq moslik", 3080), cell("Bitta mijoz", 3080)] }),
      new TableRow({ children: [cell("PINFL / STIR", 3200, { shaded: true }), cell("Aniq moslik", 3080, { shaded: true }), cell("Bitta mijoz", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Familiya va ism", 3200), cell("Qisman moslik", 3080), cell("Ro'yxat", 3080)] }),
      new TableRow({ children: [cell("Passport / ID raqami", 3200, { shaded: true }), cell("Aniq moslik", 3080, { shaded: true }), cell("Bitta mijoz", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Telefon raqami", 3200), cell("Aniq moslik", 3080), cell("Bitta/bir nechta", 3080)] }),
      new TableRow({ children: [cell("Holat (FAOL/BLOKLANGAN/YOPIQ)", 3200, { shaded: true }), cell("Filtr", 3080, { shaded: true }), cell("Ro'yxat", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Mijoz turi (FYaSh/YuSh)", 3200), cell("Filtr", 3080), cell("Ro'yxat", 3080)] }),
      new TableRow({ children: [cell("Ro'yxatga olingan sana oralig'i", 3200, { shaded: true }), cell("Filtr", 3080, { shaded: true }), cell("Ro'yxat", 3080, { shaded: true })] }),
    ]
  }),

  // --- BP-004 ---
  heading("2.4. BP-004: Mijoz holatini boshqarish", HeadingLevel.HEADING_2),
  body("Mijoz holatini o'zgartirish jarayoni. Har bir o'tish sababi bilan birga qayd etiladi."),
  spacer(),
  body("Mumkin bo'lgan holatlar:", { bold: true }),
  bullet("FAOL (ACTIVE) — mijoz tizimda faol, barcha operatsiyalar ochiq"),
  bullet("BLOKLANGAN (BLOCKED) — vaqtinchalik cheklangan, operatsiyalar to'xtatilgan"),
  bullet("YOPIQ (CLOSED) — mijoz arxivga o'tgan, qayta ochish mumkin emas"),
  spacer(),
  body("Holat o'tishlari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2000, 2000, 2680, 2680],
    rows: [
      new TableRow({ children: [
        hCell("Joriy holat", 2000), hCell("Yangi holat", 2000),
        hCell("Shart", 2680), hCell("Ta'sir", 2680)
      ]}),
      new TableRow({ children: [
        cell("FAOL", 2000), cell("BLOKLANGAN", 2000),
        cell("Supervisor buyrug'i + sabab matni", 2680), cell("Barcha hisoblar operatsiyaga yopiladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("BLOKLANGAN", 2000, { shaded: true }), cell("FAOL", 2000, { shaded: true }),
        cell("Supervisor buyrug'i + sabab matni", 2680, { shaded: true }), cell("Hisoblar qayta ochiladi", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("FAOL", 2000), cell("YOPIQ", 2000),
        cell("Barcha hisoblar yopiq va nol balans", 2680), cell("Mijoz arxivga o'tadi", 2680)
      ]}),
      new TableRow({ children: [
        cell("BLOKLANGAN", 2000, { shaded: true }), cell("YOPIQ", 2000, { shaded: true }),
        cell("Barcha hisoblar yopiq va nol balans", 2680, { shaded: true }), cell("Mijoz arxivga o'tadi", 2680, { shaded: true })
      ]}),
    ]
  }),
  spacer(),
  body("Eslatma: YOPIQ holatdan boshqa holatga qaytish mumkin emas.", { italic: true }),

  // --- BP-005 ---
  heading("2.5. BP-005: Mijoz hujjatlarini boshqarish", HeadingLevel.HEADING_2),
  body("Mijozga tegishli identifikatsiya hujjatlarini tizimda saqlash va boshqarish jarayoni."),
  spacer(),
  body("Qo'llab-quvvatlanadigan hujjat turlari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 3180, 3180],
    rows: [
      new TableRow({ children: [hCell("Hujjat turi", 3000), hCell("Qo'llanilishi", 3180), hCell("Izoh", 3180)] }),
      new TableRow({ children: [cell("Passport", 3000), cell("Jismoniy shaxs", 3180), cell("O'zbekiston fuqarosi", 3180)] }),
      new TableRow({ children: [cell("ID karta", 3000, { shaded: true }), cell("Jismoniy shaxs", 3180, { shaded: true }), cell("Biometrik identifikatsiya", 3180, { shaded: true })] }),
      new TableRow({ children: [cell("Xorijiy passport", 3000), cell("Jismoniy shaxs", 3180), cell("Norezident fuqarolar", 3180)] }),
      new TableRow({ children: [cell("Guvohnoma", 3000, { shaded: true }), cell("Yuridik shaxs", 3180, { shaded: true }), cell("Davlat ro'yxatiga olish", 3180, { shaded: true })] }),
      new TableRow({ children: [cell("Litsenziya", 3000), cell("Yuridik shaxs", 3180), cell("Faoliyat ruxsatnomasi", 3180)] }),
      new TableRow({ children: [cell("Ta'sis shartnomasi", 3000, { shaded: true }), cell("Yuridik shaxs", 3180, { shaded: true }), cell("Tashkilotning tuzilish asosi", 3180, { shaded: true })] }),
      new TableRow({ children: [cell("Ishonchnoma", 3000), cell("Ikkala tur", 3180), cell("Vakil uchun", 3180)] }),
    ]
  }),
  spacer(),
  body("Har bir hujjat uchun saqlanadigan ma'lumotlar: hujjat turi, seriya, raqam, kim tomonidan berilgan, berilgan sana, amal qilish muddati, asosiy hujjat belgisi.", { italic: true }),

  // --- BP-006 ---
  heading("2.6. BP-006: KYC/AML nazorati", HeadingLevel.HEADING_2),
  body("Mijozlarning KYC (Mijozni bilish) va AML (Pul yuvishga qarshi kurash) talablariga muvofiqligini nazorat qilish jarayoni."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-006", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Komplayens xodimi, Supervisor", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Mijoz tizimda ro'yxatdan o'tgan", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("KYC xavf darajasi belgilangan, PEP tekshiruvi amalga oshirilgan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Tizim mijozning KYC ma'lumotlari to'liqligini tekshiradi"),
  numberedItem("PEP belgisi bor mijozlar avtomatik ravishda YUQORI xavf darajasiga o'tkaziladi"),
  numberedItem("Komplayens xodimi xavf darajasini ko'rib chiqadi va tasdiqlaydi yoki o'zgartiradi"),
  numberedItem("KYC muddati tugagan mijozlar uchun qayta tekshiruv ogohlantirishi beriladi"),
  numberedItem("KYC nazorati natijalari tizimda qayd etiladi"),
];

// ===== 3. MA'LUMOTLAR TALABLARI (BIZNES TILDA) =====
const section3 = [
  heading("3. Ma'lumotlar talablari", HeadingLevel.HEADING_1),
  body("Quyida har bir mijoz turi uchun tizimda saqlanishi kerak bo'lgan ma'lumotlar guruhlari keltirilgan. Texnik amalga oshirish (jadval strukturasi, maydon turlari, hajmlari) Texnik Topshiriq (TZ-001) da batafsil yoritiladi."),

  heading("3.1. Jismoniy shaxs (fuqaro) ma'lumotlari", HeadingLevel.HEADING_2),

  heading("3.1.1. Shaxsiy ma'lumotlar", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Familiya", 3500), cell("Majburiy", 2930), cell("Kamida 2 belgi", 2930)] }),
      new TableRow({ children: [cell("Ism", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Kamida 2 belgi", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Otasining ismi", 3500), cell("Ixtiyoriy", 2930), cell("", 2930)] }),
      new TableRow({ children: [cell("Tug'ilgan sana", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("18 yoshdan katta bo'lishi shart", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Tug'ilgan joyi", 3500), cell("Majburiy", 2930), cell("Shahar/tuman/viloyat", 2930)] }),
      new TableRow({ children: [cell("Jinsi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Erkak / Ayol", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.1.2. Identifikatsiya ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("PINFL", 3500), cell("Majburiy", 2930), cell("14 xonali, tizimda yagona", 2930)] }),
      new TableRow({ children: [cell("Passport seriyasi va raqami", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Amaldagi hujjat", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Passport berilgan sana", 3500), cell("Majburiy", 2930), cell("", 2930)] }),
      new TableRow({ children: [cell("Passport amal qilish muddati", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Muddati o'tmagan bo'lishi shart", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Passport kim tomonidan berilgan", 3500), cell("Majburiy", 2930), cell("Tuman/shahar IIB", 2930)] }),
      new TableRow({ children: [cell("Fuqarolik", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Davlat kodi (masalan: UZB)", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Rezidentlik belgisi", 3500), cell("Majburiy", 2930), cell("Rezident yoki norezident", 2930)] }),
    ]
  }),

  heading("3.1.3. Aloqa ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Asosiy telefon raqam", 3500), cell("Majburiy", 2930), cell("+998 formatda", 2930)] }),
      new TableRow({ children: [cell("Qo'shimcha telefon raqam", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Email", 3500), cell("Ixtiyoriy", 2930), cell("Email format tekshiriladi", 2930)] }),
      new TableRow({ children: [cell("Yashash manzili", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Haqiqiy yashash joyi", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Ro'yxatga olingan manzil", 3500), cell("Ixtiyoriy", 2930), cell("Propiska manzili", 2930)] }),
    ]
  }),

  heading("3.1.4. Ish joyi ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Ish joyi (tashkilot nomi)", 3500), cell("Ixtiyoriy", 2930), cell("Mijoz ishlayotgan tashkilot", 2930)] }),
      new TableRow({ children: [cell("Lavozimi", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Ish joyi manzili", 3500), cell("Ixtiyoriy", 2930), cell("", 2930)] }),
      new TableRow({ children: [cell("Ish joyi telefoni", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("", 2930, { shaded: true })] }),
    ]
  }),

  // --- 3.2 ---
  heading("3.2. Yuridik shaxs (tashkilot) ma'lumotlari", HeadingLevel.HEADING_2),

  heading("3.2.1. Tashkilot ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Qisqa nomi", 3500), cell("Majburiy", 2930), cell("Kamida 3 belgi", 2930)] }),
      new TableRow({ children: [cell("To'liq rasmiy nomi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Ustav bo'yicha", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Tashkiliy-huquqiy shakli", 3500), cell("Majburiy", 2930), cell("MChJ, AJ, YaTT, QK, UP va h.k.", 2930)] }),
      new TableRow({ children: [cell("OKED faoliyat turi kodi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("CBU klassifikatori bo'yicha", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.2.2. Davlat ro'yxati ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("STIR", 3500), cell("Majburiy", 2930), cell("9 xonali, tizimda yagona", 2930)] }),
      new TableRow({ children: [cell("Davlat ro'yxati raqami", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Ro'yxatga olish guvohnomasi", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Ro'yxatga olingan sana", 3500), cell("Majburiy", 2930), cell("", 2930)] }),
      new TableRow({ children: [cell("Ro'yxatga olgan organ", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Masalan: Adliya vazirligi", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.2.3. Rahbariyat ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Rahbar FIO", 3500), cell("Majburiy", 2930), cell("Direktor/Boshqaruvchi", 2930)] }),
      new TableRow({ children: [cell("Rahbar lavozimi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Masalan: Bosh direktor", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Rahbar PINFL", 3500), cell("Majburiy", 2930), cell("Rahbarni identifikatsiya qilish uchun", 2930)] }),
      new TableRow({ children: [cell("Bosh hisobchi FIO", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.2.4. Aloqa ma'lumotlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Asosiy telefon raqam", 3500), cell("Majburiy", 2930), cell("+998 formatda", 2930)] }),
      new TableRow({ children: [cell("Email", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("Email format tekshiriladi", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Yuridik manzil", 3500), cell("Majburiy", 2930), cell("Ro'yxatga olingan manzil", 2930)] }),
      new TableRow({ children: [cell("Haqiqiy manzil", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("Joylashgan manzil", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.2.5. Bank rekvizitlari", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Xizmat ko'rsatuvchi bank nomi", 3500), cell("Ixtiyoriy", 2930), cell("Boshqa bankdagi hisob (agar mavjud)", 2930)] }),
      new TableRow({ children: [cell("Xizmat ko'rsatuvchi bank MFO", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Hisob raqami (boshqa bankda)", 3500), cell("Ixtiyoriy", 2930), cell("20 xonali format", 2930)] }),
    ]
  }),

  // --- 3.3 ---
  heading("3.3. Umumiy (ikkala tur uchun) ma'lumotlar", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("CIF raqam", 3500), cell("Avtomatik", 2930), cell("Tizim tomonidan generatsiya qilinadi", 2930)] }),
      new TableRow({ children: [cell("Mijoz turi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Jismoniy yoki Yuridik shaxs", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Ro'yxatga olgan filial", 3500), cell("Majburiy", 2930), cell("MFO kodi", 2930)] }),
      new TableRow({ children: [cell("Iqtisodiyot sektori", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("CBU klassifikatori bo'yicha", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("KYC xavf darajasi", 3500), cell("Majburiy", 2930), cell("PAST / O'RTA / YUQORI", 2930)] }),
      new TableRow({ children: [cell("PEP belgisi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Siyosiy lavozimli shaxs: Ha / Yo'q", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Bank xizmatidan maqsad", 3500), cell("Majburiy", 2930), cell("Hisob ochish, kredit, depozit va h.k.", 2930)] }),
      new TableRow({ children: [cell("Mijoz holati", 3500, { shaded: true }), cell("Avtomatik", 2930, { shaded: true }), cell("FAOL / BLOKLANGAN / YOPIQ", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Ro'yxatga olingan sana", 3500), cell("Avtomatik", 2930), cell("Mijoz yaratilgan sana va vaqt", 2930)] }),
    ]
  }),

  // --- 3.4 ---
  heading("3.4. Qo'shimcha aloqa ma'lumotlari", HeadingLevel.HEADING_2),
  body("Har bir mijozga bir nechta qo'shimcha aloqa ma'lumoti bog'lanishi mumkin:"),
  bullet("Qo'shimcha telefon raqamlar"),
  bullet("Qo'shimcha email manzillar"),
  bullet("Faks raqami"),
  bullet("Telegram / boshqa messenjer"),
  body("Har bir aloqa ma'lumoti uchun saqlanadi: turi, qiymati, asosiy/qo'shimcha belgisi, izoh.", { italic: true }),

  // --- 3.5 ---
  heading("3.5. O'zgarishlar tarixi", HeadingLevel.HEADING_2),
  body("Mijoz ma'lumotlaridagi har qanday o'zgarish tizimda qayd etilishi shart:"),
  bullet("Qaysi ma'lumot o'zgargan"),
  bullet("Eski qiymat va yangi qiymat"),
  bullet("Kim o'zgartirgan (foydalanuvchi)"),
  bullet("Qachon o'zgartirilgan (sana va vaqt)"),
  bullet("O'zgarish turi: yaratish, yangilash, holat o'zgartirish"),
  spacer(200),
];

// ===== 4. BIZNES QOIDALAR =====
const section4 = [
  heading("4. Biznes qoidalar", HeadingLevel.HEADING_1),

  heading("4.1. Identifikatsiya qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-001", 900), cell("Har bir mijozga noyob CIF raqam tayinlanadi. CIF raqam qayta ishlatilmaydi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-002", 900, { shaded: true }),
        cell("Jismoniy shaxsning PINFL raqami tizimda yagona bo'lishi shart. Dublikat kiritishga ruxsat berilmaydi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("FYaSh", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-003", 900),
        cell("Yuridik shaxsning STIR raqami tizimda yagona bo'lishi shart. Dublikat kiritishga ruxsat berilmaydi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("YuSh", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-004", 900, { shaded: true }),
        cell("Har bir mijoz kamida bitta asosiy identifikatsiya hujjatiga ega bo'lishi shart.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.2. Holat boshqaruv qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-005", 900),
        cell("YOPIQ holatdagi mijozni qayta ochish (FAOL ga o'tkazish) mumkin emas.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-006", 900, { shaded: true }),
        cell("Ochiq (faol) hisobi bor mijozni YOPIQ holatga o'tkazish mumkin emas. Avval barcha hisoblar yopilishi shart.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-007", 900),
        cell("Holat o'zgartirish sababi (izoh matni) majburiy talab etiladi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-008", 900, { shaded: true }),
        cell("Mijoz holatini faqat Supervisor yoki Administrator o'zgartirishi mumkin. Operator holatni o'zgartira olmaydi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.3. Validatsiya qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-009", 900),
        cell("Jismoniy shaxs 18 yoshdan katta bo'lishi shart (tug'ilgan sana bo'yicha tekshiriladi).", 5760),
        cell("Yuqori", 1350, { center: true }), cell("FYaSh", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-010", 900, { shaded: true }),
        cell("Telefon raqam +998XXXXXXXXX formatda kiritilishi shart (12 xona).", 5760, { shaded: true }),
        cell("O'rta", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-011", 900),
        cell("PINFL raqami aniq 14 xonali raqamdan iborat bo'lishi shart.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("FYaSh", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-012", 900, { shaded: true }),
        cell("STIR raqami aniq 9 xonali raqamdan iborat bo'lishi shart.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("YuSh", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-013", 900),
        cell("Yuridik shaxsda tashkiliy-huquqiy shakl, OKED kodi, davlat ro'yxati ma'lumotlari, rahbar FIO va bosh hisobchi FIO majburiy.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("YuSh", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-014", 900, { shaded: true }),
        cell("Hujjat amal qilish muddati o'tgan bo'lsa, tizim ogohlantirish beradi.", 5760, { shaded: true }),
        cell("O'rta", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-015", 900),
        cell("Email kiritilgan taqdirda, email format to'g'riligi tekshiriladi.", 5760),
        cell("Past", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
    ]
  }),

  heading("4.4. KYC va AML qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-016", 900),
        cell("Har bir mijozga KYC xavf darajasi belgilanishi shart. Yangi mijoz uchun boshlang'ich daraja: PAST (LOW).", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-017", 900, { shaded: true }),
        cell("PEP (siyosiy lavozimli shaxs) belgisi \"Ha\" bo'lsa, xavf darajasi avtomatik ravishda YUQORI (HIGH) ga o'rnatiladi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-018", 900),
        cell("Iqtisodiyot sektori kodi Markaziy bank klassifikatoriga mos bo'lishi shart.", 5760),
        cell("O'rta", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-019", 900, { shaded: true }),
        cell("YUQORI xavf darajasidagi mijozlar uchun kamida yiliga bir marta KYC qayta tekshiruvi o'tkazilishi shart.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.5. Maker-Checker qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-020", 900),
        cell("Yangi mijoz ro'yxatga olishni bir xodim (Operator) yaratadi, boshqa xodim (Supervisor) tasdiqlaydi. Bir kishi ham yaratib, ham tasdiqlay olmaydi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-021", 900, { shaded: true }),
        cell("Supervisor tomonidan tasdiqlangunga qadar mijoz 'Tasdiqlash kutilmoqda' holatida bo'ladi va hisoblar modulida ishlatib bo'lmaydi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.6. Audit qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-022", 900),
        cell("Mijoz ma'lumotlaridagi har qanday o'zgarish o'zgarishlar tarixiga yoziladi (kim, qachon, nima o'zgargan).", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-023", 900, { shaded: true }),
        cell("O'zgarishlar tarixini o'chirish yoki o'zgartirish mumkin emas.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.7. CIF raqam generatsiyasi", HeadingLevel.HEADING_2),
  body("Har bir yangi mijozga noyob CIF raqam avtomatik tayinlanadi."),
  spacer(),
  body("CIF raqam formati:", { bold: true }),
  body("CIF-YYYYMMDD-NNNNNN"),
  bullet("CIF — doimiy prefiks"),
  bullet("YYYYMMDD — mijoz yaratilgan sana"),
  bullet("NNNNNN — 6 xonali ketma-ket tartib raqam (kun ichida)"),
  spacer(),
  body("Misol: CIF-20260526-000001, CIF-20260526-000002, ...", { italic: true }),
  body("CIF raqam bir marta tayinlangandan keyin o'zgartirilmaydi va qayta ishlatilmaydi.", { italic: true }),
  spacer(200),
];

// ===== 5. FOYDALANUVCHI ROLLARI =====
const section5 = [
  heading("5. Foydalanuvchi rollari va huquqlar", HeadingLevel.HEADING_1),
  body("Mijozlar moduli bilan ishlaydigan foydalanuvchi rollari va ularning huquqlari:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1800, 3780, 3780],
    rows: [
      new TableRow({ children: [hCell("Rol", 1800), hCell("Nima qila oladi", 3780), hCell("Cheklovlar", 3780)] }),
      new TableRow({ children: [
        cell("Operator", 1800),
        multiCell(["Yangi mijoz yaratish (Maker)", "Mijoz ma'lumotlarini ko'rish", "Mijoz ma'lumotlarini yangilash", "Hujjat va aloqa ma'lumoti qo'shish", "Mijozni qidirish"], 3780),
        multiCell(["Mijozni tasdiqlay olmaydi (Checker)", "Mijoz holatini o'zgartira olmaydi", "Mijozni o'chira olmaydi", "Hisobotlarni ko'ra olmaydi"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Supervisor", 1800, { shaded: true }),
        multiCell(["Operator huquqlari +", "Mijoz yaratilishini tasdiqlash (Checker)", "Mijoz holatini o'zgartirish", "Hisobotlarni ko'rish va yuklab olish"], 3780, { shaded: true }),
        multiCell(["Mijozni o'chira olmaydi", "Tizim sozlamalarini o'zgartira olmaydi"], 3780, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("Administrator", 1800),
        multiCell(["Barcha huquqlar", "Foydalanuvchilarni boshqarish", "Tizim sozlamalari", "Klassifikatorlarni boshqarish"], 3780),
        multiCell(["O'zgarishlar tarixini o'chira olmaydi"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Auditor", 1800, { shaded: true }),
        multiCell(["Mijozlarni ko'rish (faqat o'qish)", "Hisobotlarni ko'rish va yuklab olish", "Audit loglarni ko'rish", "KYC/PEP hisobotlarni ko'rish"], 3780, { shaded: true }),
        multiCell(["Hech qanday o'zgartirish qila olmaydi", "Mijoz yarata olmaydi", "Holat o'zgartira olmaydi"], 3780, { shaded: true })
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 6. INTERFEYS TALABLARI =====
const section6 = [
  heading("6. Interfeys talablari", HeadingLevel.HEADING_1),
  body("Quyida foydalanuvchi ko'rishi va ishlatishi kerak bo'lgan asosiy ekranlar tavsiflangan."),

  heading("6.1. SCR-001: Mijozlar ro'yxati", HeadingLevel.HEADING_2),
  body("Maqsad: barcha mijozlarni ko'rsatish, qidirish va filtrlash."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Qidiruv paneli — CIF raqam, FIO, PINFL/STIR, telefon bo'yicha qidirish"),
  bullet("Filtrlar — holat (FAOL/BLOKLANGAN/YOPIQ/Barchasi), mijoz turi (FYaSh/YuSh/Barchasi), KYC xavf darajasi (PAST/O'RTA/YUQORI/Barchasi), PEP belgisi (Ha/Yo'q/Barchasi)"),
  bullet("Natijalar jadvali — CIF raqam, FIO yoki tashkilot nomi, tur, telefon, holat, KYC daraja, yaratilgan sana"),
  bullet("Sahifalash — har sahifada 20 ta yozuv"),
  bullet("\"Yangi mijoz\" tugmasi — mijoz yaratish formasiga o'tadi"),
  bullet("Har bir qatorda \"Ko'rish\" tugmasi — mijoz tafsilotlariga o'tadi"),

  heading("6.2. SCR-002: Mijoz yaratish formasi", HeadingLevel.HEADING_2),
  body("Maqsad: yangi mijozni tizimga kiritish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Mijoz turi tanlash — Jismoniy shaxs / Yuridik shaxs (turga qarab forma o'zgaradi)"),
  bullet("Shaxsiy ma'lumotlar bloki (FYaSh uchun) yoki Tashkilot ma'lumotlari bloki (YuSh uchun)"),
  bullet("Identifikatsiya ma'lumotlari bloki"),
  bullet("Aloqa ma'lumotlari bloki"),
  bullet("Ish joyi ma'lumotlari bloki (FYaSh uchun)"),
  bullet("Bank rekvizitlari bloki (YuSh uchun)"),
  bullet("Hujjat qo'shish bloki"),
  bullet("KYC ma'lumotlari bloki (xavf darajasi, PEP, sektor, bank xizmatidan maqsad)"),
  bullet("Real-time validatsiya — noto'g'ri formatda kiritilsa, xato xabari ko'rsatiladi"),
  bullet("\"Saqlash\" va \"Bekor qilish\" tugmalari"),

  heading("6.3. SCR-003: Mijoz tafsilotlari", HeadingLevel.HEADING_2),
  body("Maqsad: tanlangan mijoz haqida to'liq ma'lumot ko'rsatish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Asosiy ma'lumotlar tabi — barcha maydonlar o'qish rejimida"),
  bullet("Hujjatlar tabi — mijozga bog'langan hujjatlar ro'yxati"),
  bullet("Aloqa ma'lumotlari tabi"),
  bullet("Bog'langan hisoblar tabi (core_acc moduldan olinadi)"),
  bullet("KYC ma'lumotlari tabi — xavf darajasi, PEP belgisi, sektor"),
  bullet("O'zgarishlar tarixi tabi — barcha o'zgarishlar jadvali"),
  bullet("\"Tahrirlash\" tugmasi — tahrirlash formasiga o'tadi"),
  bullet("\"Holatni o'zgartirish\" tugmasi — modal oyna ochadi (faqat Supervisor/Admin uchun)"),

  heading("6.4. SCR-004: Mijoz tahrirlash formasi", HeadingLevel.HEADING_2),
  body("Maqsad: mavjud mijoz ma'lumotlarini o'zgartirish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Barcha maydonlar joriy qiymatlar bilan to'ldirilgan"),
  bullet("O'zgartirilgan maydonlar vizual ajratilgan (rangi o'zgaradi)"),
  bullet("CIF raqam va mijoz turi o'zgartirilmaydi (faqat o'qish)"),
  bullet("\"Saqlash\" va \"Bekor qilish\" tugmalari"),

  heading("6.5. SCR-005: Mijoz holatini o'zgartirish", HeadingLevel.HEADING_2),
  body("Maqsad: mijoz holatini o'zgartirish (modal dialog oynasi)."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Joriy holat ko'rsatkichi"),
  bullet("Yangi holat tanlash (faqat ruxsat etilgan o'tishlar ko'rsatiladi)"),
  bullet("Sabab matni — majburiy matn maydoni"),
  bullet("Ogohlantirish xabari — agar YOPIQ tanlansa, qaytarib bo'lmasligini eslatadi"),
  bullet("\"Tasdiqlash\" va \"Bekor qilish\" tugmalari"),

  heading("6.6. SCR-006: Supervisor tasdiqlash ekrani", HeadingLevel.HEADING_2),
  body("Maqsad: Supervisor uchun yangi mijozlarni ko'rib chiqish va tasdiqlash."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Tasdiqlash kutayotgan mijozlar ro'yxati"),
  bullet("Har bir mijoz uchun to'liq ma'lumotlarni ko'rish imkoniyati"),
  bullet("\"Tasdiqlash\" va \"Rad etish\" tugmalari"),
  bullet("Rad etish sababini kiritish maydoni"),
  spacer(200),
];

// ===== 7. HISOBOTLAR =====
const section7 = [
  heading("7. Hisobotlar", HeadingLevel.HEADING_1),
  body("Mijozlar moduli quyidagi hisobotlarni taqdim etishi kerak:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1000, 2400, 3560, 2400],
    rows: [
      new TableRow({ children: [hCell("ID", 1000), hCell("Nomi", 2400), hCell("Tavsif", 3560), hCell("Chastotasi", 2400)] }),
      new TableRow({ children: [
        cell("RPT-001", 1000), cell("Mijozlar ro'yxati", 2400),
        cell("Barcha mijozlar to'liq ma'lumotlar bilan, filtr va saralash imkoniyati", 3560), cell("Talab bo'yicha", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-002", 1000, { shaded: true }), cell("Yangi mijozlar", 2400, { shaded: true }),
        cell("Tanlangan davr uchun yangi ro'yxatga olingan mijozlar soni va ro'yxati", 3560, { shaded: true }),
        cell("Kunlik / Oylik", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-003", 1000), cell("Bloklangan mijozlar", 2400),
        cell("BLOKLANGAN holatdagi mijozlar, bloklash sabablari va sanasi", 3560), cell("Talab bo'yicha", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-004", 1000, { shaded: true }), cell("Hujjat muddati", 2400, { shaded: true }),
        cell("Amal qilish muddati o'tayotgan (30 kun ichida) yoki o'tgan hujjatlar", 3560, { shaded: true }),
        cell("Haftalik", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-005", 1000), cell("KYC xavf hisoboti", 2400),
        cell("Xavf darajasi bo'yicha mijozlar taqsimoti: PAST, O'RTA, YUQORI darajadagi mijozlar soni va ro'yxati", 3560), cell("Oylik", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-006", 1000, { shaded: true }), cell("PEP hisoboti", 2400, { shaded: true }),
        cell("Siyosiy lavozimli shaxs (PEP) belgisi bo'lgan barcha mijozlar ro'yxati, xavf darajasi va holati", 3560, { shaded: true }),
        cell("Oylik", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-007", 1000), cell("Mijoz o'zgarishlar hisoboti", 2400),
        cell("Tanlangan davr uchun mijoz ma'lumotlaridagi barcha o'zgarishlar audit hisoboti", 3560), cell("Talab bo'yicha", 2400)
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 8. INTEGRATSIYA TALABLARI =====
const section8 = [
  heading("8. Integratsiya talablari", HeadingLevel.HEADING_1),
  body("Mijozlar moduli (core_cif) MARS tizimining boshqa modullari bilan quyidagicha o'zaro aloqada bo'ladi:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1600, 1800, 3280, 2680],
    rows: [
      new TableRow({ children: [
        hCell("Modul", 1600), hCell("Yo'nalish", 1800),
        hCell("Qanday ma'lumot almashiladi", 3280), hCell("Qachon kerak", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_acc", 1600), cell("CIF → ACC", 1800),
        cell("Mijoz ma'lumotlari: CIF raqam, FIO/nomi, holat, KYC daraja", 3280), cell("Hisob ochishda mijoz tekshiriladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_adm", 1600, { shaded: true }), cell("ADM → CIF", 1800, { shaded: true }),
        cell("Foydalanuvchi va filial ma'lumotlari", 3280, { shaded: true }),
        cell("Operatorni aniqlash, filial kodini olish", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("core_gl", 1600), cell("CIF → GL", 1800),
        cell("Mijoz ma'lumotlari bosh kitob yozuvlari uchun", 3280), cell("Mijozga tegishli operatsiyalar hisoblanganida", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_doc", 1600, { shaded: true }), cell("CIF ↔ DOC", 1800, { shaded: true }),
        cell("Hujjatlar ma'lumotlari", 3280, { shaded: true }), cell("Hujjatlarni markaziy boshqarish", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("dep_deposit", 1600), cell("CIF → DEP", 1800),
        cell("Mijoz holati va identifikatsiya", 3280), cell("Depozit ochishdan oldin mijoz tekshiriladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("crd_credit", 1600, { shaded: true }), cell("CIF → CRD", 1800, { shaded: true }),
        cell("Mijoz holati va identifikatsiya", 3280, { shaded: true }), cell("Kredit berishdan oldin mijoz tekshiriladi", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("core_trx", 1600), cell("CIF → TRX", 1800),
        cell("Mijoz identifikatsiya ma'lumotlari", 3280), cell("Tranzaksiya amalga oshirilayotganda mijoz tekshiriladi", 2680)
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 9. QABUL QILISH MEZONLARI =====
const section9 = [
  heading("9. Qabul qilish mezonlari", HeadingLevel.HEADING_1),
  body("Modul quyidagi mezonlarga javob berganida qabul qilingan hisoblanadi:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [700, 5960, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("#", 700), hCell("Mezon", 5960), hCell("Ustuvorlik", 1350), hCell("Holat", 1350)] }),
      new TableRow({ children: [
        cell("1", 700, { center: true }),
        cell("Jismoniy shaxs mijozni to'liq ma'lumotlar bilan muvaffaqiyatli ro'yxatga olish mumkin", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("2", 700, { center: true, shaded: true }),
        cell("Yuridik shaxs mijozni to'liq ma'lumotlar bilan muvaffaqiyatli ro'yxatga olish mumkin", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("3", 700, { center: true }),
        cell("CIF raqam avtomatik generatsiya qilinadi va noyob bo'lishi kafolatlanadi", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("4", 700, { center: true, shaded: true }),
        cell("PINFL/STIR dublikat tekshiruvi ishlaydi — takroriy kiritishga ruxsat berilmaydi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("5", 700, { center: true }),
        cell("Maker-Checker tamoyili ishlaydi — Operator yaratadi, Supervisor tasdiqlaydi, bir kishi ikkala amalni bajara olmaydi", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("6", 700, { center: true, shaded: true }),
        cell("Mijoz ma'lumotlarini yangilash mumkin va har bir o'zgarish tarixda qayd etiladi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("7", 700, { center: true }),
        cell("Holat o'tishlari to'g'ri ishlaydi (FAOL → BLOKLANGAN → YOPIQ), teskari yo'l yo'q", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("8", 700, { center: true, shaded: true }),
        cell("Qidiruv barcha mezonlar bo'yicha ishlaydi (CIF, PINFL, STIR, FIO, telefon, holat, tur)", 5960, { shaded: true }),
        cell("O'rta", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("9", 700, { center: true }),
        cell("Hujjat muddati o'tganda yoki o'tayotganda ogohlantirish beriladi", 5960),
        cell("O'rta", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("10", 700, { center: true, shaded: true }),
        cell("PEP belgisi o'rnatilganda xavf darajasi avtomatik YUQORI ga o'zgaradi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("11", 700, { center: true }),
        cell("Barcha validatsiya qoidalari to'g'ri ishlaydi (yosh, PINFL/STIR format, telefon format, majburiy maydonlar)", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("12", 700, { center: true, shaded: true }),
        cell("Foydalanuvchi rollari va ruxsatnomalar to'g'ri ishlaydi (Operator, Supervisor, Administrator, Auditor)", 5960, { shaded: true }),
        cell("O'rta", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("13", 700, { center: true }),
        cell("KYC va PEP hisobotlari to'g'ri generatsiya qilinadi va yuklab olish mumkin", 5960),
        cell("O'rta", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
    ]
  }),
  spacer(300),

  // === TASDIQLASH ===
  heading("Tasdiqlash", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 3480, 3480],
    rows: [
      new TableRow({ children: [hCell("Rol", 2400), hCell("FIO", 3480), hCell("Imzo / Sana", 3480)] }),
      new TableRow({ children: [cell("Tayyorladi", 2400), cell("", 3480), cell("", 3480)] }),
      new TableRow({ children: [cell("Tekshirdi", 2400, { shaded: true }), cell("", 3480, { shaded: true }), cell("", 3480, { shaded: true })] }),
      new TableRow({ children: [cell("Tasdiqladi", 2400), cell("", 3480), cell("", 3480)] }),
    ]
  }),
];

// ===== DOCUMENT ASSEMBLY =====
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: BLUE },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 }
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: BLUE },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 }
      },
      {
        id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: DARK_GRAY },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 }
      },
    ]
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      },
      {
        reference: "numbers",
        levels: [{
          level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: PAGE_WIDTH, height: PAGE_HEIGHT },
        margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
          children: [new TextRun({ text: "MARS ABS  |  BT-001  |  core_cif", font: "Arial", size: 18, color: "999999" })]
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          border: { top: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
          children: [
            new TextRun({ text: "Fido Bank  |  MARS ABS  |  Konfidensial  |  Sahifa ", font: "Arial", size: 16, color: "999999" }),
            new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16, color: "999999" }),
          ]
        })]
      })
    },
    children: [
      ...titlePage,
      ...tocSection,
      ...section1,
      ...section2,
      new Paragraph({ children: [new PageBreak()] }),
      ...section3,
      new Paragraph({ children: [new PageBreak()] }),
      ...section4,
      new Paragraph({ children: [new PageBreak()] }),
      ...section5,
      ...section6,
      new Paragraph({ children: [new PageBreak()] }),
      ...section7,
      ...section8,
      ...section9,
    ]
  }]
});

// ===== GENERATE =====
const OUTPUT = "/Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project/docs/BT-001_core_cif_biznes_talab.docx";
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUTPUT, buf);
  console.log(`Generated: ${OUTPUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

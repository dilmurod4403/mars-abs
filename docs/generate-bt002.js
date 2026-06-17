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
    children: [new TextRun({ text: "BT-002: Hisoblar moduli (core_acc)", font: "Arial", size: 28, color: DARK_GRAY })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "Accounts Management", font: "Arial", size: 24, italics: true, color: "666666" })]
  }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({
    width: { size: 5000, type: WidthType.DXA },
    columnWidths: [2000, 3000],
    rows: [
      new TableRow({ children: [cell("Hujjat raqami:", 2000, { bold: true }), cell("BT-002", 3000)] }),
      new TableRow({ children: [cell("Versiya:", 2000, { bold: true, shaded: true }), cell("1.0", 3000, { shaded: true })] }),
      new TableRow({ children: [cell("Sana:", 2000, { bold: true }), cell("2026-05-26", 3000)] }),
      new TableRow({ children: [cell("Modul:", 2000, { bold: true, shaded: true }), cell("core_acc (Hisoblar)", 3000, { shaded: true })] }),
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
  body("Ushbu hujjat MARS avtomatlashtirilgan bank tizimining Hisoblar moduli (core_acc) uchun biznes talablarni belgilaydi."),
  body("Modul bankning barcha hisoblarini — ochish, yopish, holatini boshqarish, qoldiq nazorati va hisoblar bo'yicha ma'lumotlarni markazlashtirilgan holda boshqarish uchun mo'ljallangan."),

  heading("1.2. Qamrov", HeadingLevel.HEADING_2),
  body("Hujjat quyidagi biznes sohalarni qamrab oladi:"),
  bullet("Jismoniy va yuridik shaxs mijozlar uchun yangi hisob ochish"),
  bullet("Hisob ma'lumotlarini yangilash va boshqarish"),
  bullet("Hisob holatini boshqarish (faollashtirish, muzlatish, bloklash, yopish)"),
  bullet("Hisoblar bo'yicha qidiruv va filtrlash"),
  bullet("Hisob raqamlash tizimi (20 xonali format)"),
  bullet("Hisobni yopish jarayoni"),
  bullet("Hisob qoldig'i nazorati va limitlar boshqaruvi"),

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
      new TableRow({ children: [cell("Hisob", 2400), cell("Bank hisobi — mijozning bank bilan moliyaviy munosabatlarini yuritish uchun ochiladigan raqam", 6960)] }),
      new TableRow({ children: [cell("ABS", 2400, { shaded: true }), cell("Avtomatlashtirilgan Bank Tizimi", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("MARS", 2400), cell("Loyihaning ishchi nomi (ABS tizimi)", 6960)] }),
      new TableRow({ children: [cell("CIF", 2400, { shaded: true }), cell("Customer Information File — mijoz ma'lumotlar bazasi", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("FYaSh", 2400), cell("Jismoniy shaxs — fuqaro mijoz", 6960)] }),
      new TableRow({ children: [cell("YuSh", 2400, { shaded: true }), cell("Yuridik shaxs — tashkilot/korxona mijoz", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("UZS", 2400), cell("O'zbekiston so'mi — milliy valyuta (valyuta kodi: 000)", 6960)] }),
      new TableRow({ children: [cell("USD", 2400, { shaded: true }), cell("AQSh dollari (valyuta kodi: 840)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("EUR", 2400), cell("Yevropa valyutasi (valyuta kodi: 978)", 6960)] }),
      new TableRow({ children: [cell("KYC", 2400, { shaded: true }), cell("Know Your Customer — mijozni aniqlash tamoyili", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Maker-Checker", 2400), cell("Ikki bosqichli tasdiqlash — bir xodim yaratadi, boshqasi tasdiqlaydi", 6960)] }),
      new TableRow({ children: [cell("Overdraft", 2400, { shaded: true }), cell("Hisob qoldig'idan ortiq mablag' sarflash (ushbu tizimda ruxsat etilmaydi)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("MFO", 2400), cell("Bank bo'limi (filial) kodi", 6960)] }),
    ]
  }),
  spacer(200),
];

// ===== 2. BIZNES JARAYONLAR =====
const section2 = [
  heading("2. Biznes jarayonlar", HeadingLevel.HEADING_1),

  // --- BP-001 ---
  heading("2.1. BP-001: Yangi hisob ochish", HeadingLevel.HEADING_2),
  body("Mijozga yangi bank hisobi ochish jarayoni. Hisob jismoniy yoki yuridik shaxs mijoz uchun ochilishi mumkin."),

  heading("2.1.1. Jismoniy shaxs uchun hisob ochish", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-001-FYaSh", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor (tasdiqlash uchun), Mijoz (fuqaro)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Mijoz tizimda ro'yxatdan o'tgan (CIF raqam mavjud), FAOL holatda, KYC to'liq", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Yangi hisob ochilgan, hisob raqami tayinlangan, Supervisor tasdiqlagan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator yangi hisob ochish formasini ochadi"),
  numberedItem("Mijozni CIF raqami yoki FIO bo'yicha qidiradi va tanlaydi"),
  numberedItem("Tizim mijoz holatini tekshiradi (FAOL bo'lishi shart) va KYC to'liqligini tekshiradi"),
  numberedItem("Operator hisob turini tanlaydi: joriy (current), jamg'arma (savings), depozit (deposit)"),
  numberedItem("Valyutani tanlaydi: UZS, USD yoki EUR"),
  numberedItem("Hisob parametrlarini kiritadi: minimal qoldiq, kunlik/oylik limit"),
  numberedItem("Tizim avtomatik ravishda: 20 xonali hisob raqamini generatsiya qiladi, yagonaligini tekshiradi"),
  numberedItem("Operator ma'lumotlarni saqlaydi — hisob 'Tasdiqlash kutilmoqda' holatiga tushadi"),
  numberedItem("Supervisor hisob ochishni ko'rib chiqadi va tasdiqlaydi (Maker-Checker)"),
  numberedItem("Tasdiqlangandan so'ng hisob FAOL holatga o'tadi"),

  heading("2.1.2. Yuridik shaxs uchun hisob ochish", HeadingLevel.HEADING_3),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-001-YuSh", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor (tasdiqlash uchun), Tashkilot vakili", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Tashkilot tizimda ro'yxatdan o'tgan (CIF raqam mavjud), FAOL holatda, KYC to'liq", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Yangi hisob ochilgan, hisob raqami tayinlangan, Supervisor tasdiqlagan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator yangi hisob ochish formasini ochadi"),
  numberedItem("Tashkilotni CIF raqami yoki nomi bo'yicha qidiradi va tanlaydi"),
  numberedItem("Tizim tashkilot holatini tekshiradi (FAOL bo'lishi shart) va KYC to'liqligini tekshiradi"),
  numberedItem("Operator hisob turini tanlaydi: joriy (current), maxsus (special)"),
  numberedItem("Valyutani tanlaydi: UZS, USD yoki EUR"),
  numberedItem("Imzo huquqiga ega shaxslarni belgilaydi"),
  numberedItem("Hisob parametrlarini kiritadi: minimal qoldiq, kunlik/oylik limit"),
  numberedItem("Tizim avtomatik ravishda: 20 xonali hisob raqamini generatsiya qiladi, yagonaligini tekshiradi"),
  numberedItem("Operator ma'lumotlarni saqlaydi — hisob 'Tasdiqlash kutilmoqda' holatiga tushadi"),
  numberedItem("Supervisor hisob ochishni ko'rib chiqadi va tasdiqlaydi (Maker-Checker)"),
  numberedItem("Tasdiqlangandan so'ng hisob FAOL holatga o'tadi"),

  // --- BP-002 ---
  heading("2.2. BP-002: Hisob ma'lumotlarini yangilash", HeadingLevel.HEADING_2),
  body("Mavjud hisob ma'lumotlarini o'zgartirish jarayoni. Har qanday o'zgarish tizimda saqlanadi va kuzatiladi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-002", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori, Supervisor", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Hisob tizimda mavjud, FAOL yoki MUZLATILGAN holatda", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Ma'lumotlar yangilangan, o'zgarish tarixi saqlangan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator hisobni qidiradi (hisob raqami, CIF raqam, mijoz nomi bo'yicha)"),
  numberedItem("Hisobning joriy ma'lumotlari ekranda ko'rsatiladi"),
  numberedItem("Operator kerakli ma'lumotlarni o'zgartiradi (limitlar, parametrlar, imzo huquqi)"),
  numberedItem("Tizim o'zgarishlarni tekshiradi (validatsiya)"),
  numberedItem("Eski va yangi qiymatlar o'zgarishlar tarixiga yoziladi"),
  numberedItem("Yangilangan ma'lumotlar saqlanadi"),
  spacer(),
  body("Muhim: Hisob raqami, valyutasi va turi o'zgartirilmaydi.", { italic: true }),

  // --- BP-003 ---
  heading("2.3. BP-003: Hisob holatini boshqarish", HeadingLevel.HEADING_2),
  body("Hisob holatini o'zgartirish jarayoni. Har bir o'tish sababi bilan birga qayd etiladi."),
  spacer(),
  body("Mumkin bo'lgan holatlar:", { bold: true }),
  bullet("FAOL (ACTIVE) — hisob ochiq, barcha operatsiyalar ruxsat etilgan"),
  bullet("MUZLATILGAN (FROZEN) — hisob cheklangan, faqat kirim operatsiyalari ruxsat etilgan, chiqim taqiqlangan"),
  bullet("BLOKLANGAN (BLOCKED) — hisob to'liq cheklangan, faqat ko'rish mumkin, hech qanday operatsiya yo'q"),
  bullet("YOPIQ (CLOSED) — hisob yopilgan, qayta ochish mumkin emas"),
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
        cell("FAOL", 2000), cell("MUZLATILGAN", 2000),
        cell("Supervisor buyrug'i + sabab matni", 2680), cell("Faqat kirim ruxsat, chiqim taqiqlanadi", 2680)
      ]}),
      new TableRow({ children: [
        cell("FAOL", 2000, { shaded: true }), cell("BLOKLANGAN", 2000, { shaded: true }),
        cell("Supervisor buyrug'i + sabab matni", 2680, { shaded: true }), cell("Barcha operatsiyalar taqiqlanadi", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("MUZLATILGAN", 2000), cell("FAOL", 2000),
        cell("Supervisor buyrug'i + sabab matni", 2680), cell("Barcha operatsiyalar qayta ochiladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("MUZLATILGAN", 2000, { shaded: true }), cell("BLOKLANGAN", 2000, { shaded: true }),
        cell("Supervisor buyrug'i + sabab matni", 2680, { shaded: true }), cell("Barcha operatsiyalar taqiqlanadi", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BLOKLANGAN", 2000), cell("FAOL", 2000),
        cell("Supervisor buyrug'i + sabab matni", 2680), cell("Barcha operatsiyalar qayta ochiladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("FAOL", 2000, { shaded: true }), cell("YOPIQ", 2000, { shaded: true }),
        cell("Qoldiq 0, kutilayotgan tranzaksiya yo'q", 2680, { shaded: true }), cell("Hisob arxivga o'tadi, qaytish yo'q", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BLOKLANGAN", 2000), cell("YOPIQ", 2000),
        cell("Qoldiq 0, kutilayotgan tranzaksiya yo'q", 2680), cell("Hisob arxivga o'tadi, qaytish yo'q", 2680)
      ]}),
    ]
  }),
  spacer(),
  body("Eslatma: YOPIQ holatdan boshqa holatga qaytish mumkin emas.", { italic: true }),

  // --- BP-004 ---
  heading("2.4. BP-004: Hisoblarni qidirish va filtrlash", HeadingLevel.HEADING_2),
  body("Hisoblarni turli mezonlar bo'yicha qidirish va filtrlash imkoniyati."),
  spacer(),
  body("Qidiruv mezonlari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3200, 3080, 3080],
    rows: [
      new TableRow({ children: [hCell("Mezon", 3200), hCell("Qidiruv turi", 3080), hCell("Natija", 3080)] }),
      new TableRow({ children: [cell("Hisob raqami", 3200), cell("Aniq moslik", 3080), cell("Bitta hisob", 3080)] }),
      new TableRow({ children: [cell("CIF raqami (mijoz)", 3200, { shaded: true }), cell("Aniq moslik", 3080, { shaded: true }), cell("Mijozning barcha hisoblar", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Mijoz nomi / FIO", 3200), cell("Qisman moslik", 3080), cell("Ro'yxat", 3080)] }),
      new TableRow({ children: [cell("Hisob turi", 3200, { shaded: true }), cell("Filtr", 3080, { shaded: true }), cell("Ro'yxat", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Valyuta", 3200), cell("Filtr", 3080), cell("Ro'yxat", 3080)] }),
      new TableRow({ children: [cell("Holat (FAOL/MUZLATILGAN/BLOKLANGAN/YOPIQ)", 3200, { shaded: true }), cell("Filtr", 3080, { shaded: true }), cell("Ro'yxat", 3080, { shaded: true })] }),
      new TableRow({ children: [cell("Ochilgan sana oralig'i", 3200), cell("Filtr", 3080), cell("Ro'yxat", 3080)] }),
    ]
  }),

  // --- BP-005 ---
  heading("2.5. BP-005: Hisobni yopish", HeadingLevel.HEADING_2),
  body("Mavjud hisobni yopish jarayoni. Hisobni yopish qaytarilmas operatsiya hisoblanadi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-005", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank administrator, Mijoz", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Hisob tizimda mavjud, qoldiq nolga teng, kutilayotgan tranzaksiyalar yo'q", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Hisob YOPIQ holatga o'tgan, audit logga yozilgan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Administrator hisobni qidiradi va tanlaydi"),
  numberedItem("Tizim qoldiqni tekshiradi — noldan farqli bo'lsa, xato xabari ko'rsatiladi"),
  numberedItem("Tizim kutilayotgan tranzaksiyalarni tekshiradi — mavjud bo'lsa, xato xabari ko'rsatiladi"),
  numberedItem("Administrator yopish sababini kiritadi (majburiy matn maydoni)"),
  numberedItem("Tizim hisobni YOPIQ holatga o'tkazadi"),
  numberedItem("Yopish sanasi, sababi va administrator ma'lumotlari audit logga yoziladi"),
  numberedItem("Mijozga bildirishnoma yuboriladi (agar sozlangan bo'lsa)"),
  spacer(),
  body("Muhim: YOPIQ holatdagi hisobni qayta ochish mumkin emas. Mijoz yangi hisob ochishi kerak.", { italic: true }),
];

// ===== 3. MA'LUMOTLAR TALABLARI (BIZNES TILDA) =====
const section3 = [
  heading("3. Ma'lumotlar talablari", HeadingLevel.HEADING_1),
  body("Quyida hisoblar uchun tizimda saqlanishi kerak bo'lgan ma'lumotlar guruhlari keltirilgan. Texnik amalga oshirish (jadval strukturasi, maydon turlari, hajmlari) Texnik Topshiriq (TZ-002) da batafsil yoritiladi."),

  heading("3.1. Hisob asosiy ma'lumotlari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Hisob raqami", 3500), cell("Avtomatik", 2930), cell("20 xonali, tizim tomonidan generatsiya qilinadi", 2930)] }),
      new TableRow({ children: [cell("Hisob turi", 3500, { shaded: true }), cell("Majburiy", 2930, { shaded: true }), cell("Joriy, jamg'arma, depozit, kredit, maxsus", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Valyuta", 3500), cell("Majburiy", 2930), cell("UZS (000), USD (840), EUR (978)", 2930)] }),
      new TableRow({ children: [cell("Ochilgan sana", 3500, { shaded: true }), cell("Avtomatik", 2930, { shaded: true }), cell("Hisob ochilgan sana va vaqt", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Hisob holati", 3500), cell("Avtomatik", 2930), cell("FAOL / MUZLATILGAN / BLOKLANGAN / YOPIQ", 2930)] }),
      new TableRow({ children: [cell("Hisob nomi / tavsifi", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("Hisobni aniqlash uchun qisqa tavsif", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.2. Hisob egasi ma'lumotlari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Mijoz (CIF raqam)", 3500), cell("Majburiy", 2930), cell("core_cif modulidan olinadi", 2930)] }),
      new TableRow({ children: [cell("Mijoz turi", 3500, { shaded: true }), cell("Avtomatik", 2930, { shaded: true }), cell("Jismoniy yoki Yuridik shaxs (CIF dan)", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Imzo huquqi", 3500), cell("Ixtiyoriy", 2930), cell("Hisobdan foydalanish huquqiga ega shaxslar", 2930)] }),
    ]
  }),

  heading("3.3. Hisob parametrlari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3500, 2930, 2930],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3500), hCell("Majburiyligi", 2930), hCell("Izoh", 2930)] }),
      new TableRow({ children: [cell("Foiz stavkasi", 3500), cell("Ixtiyoriy", 2930), cell("Yillik foiz, hisob turiga qarab", 2930)] }),
      new TableRow({ children: [cell("Minimal qoldiq", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("Hisobda saqlanishi kerak bo'lgan eng kam mablag'", 2930, { shaded: true })] }),
      new TableRow({ children: [cell("Kunlik limit", 3500), cell("Ixtiyoriy", 2930), cell("Bir kunda maksimal chiqim summasi", 2930)] }),
      new TableRow({ children: [cell("Oylik limit", 3500, { shaded: true }), cell("Ixtiyoriy", 2930, { shaded: true }), cell("Bir oyda maksimal chiqim summasi", 2930, { shaded: true })] }),
    ]
  }),

  heading("3.4. Hisob turlari", HeadingLevel.HEADING_2),
  body("Tizimda quyidagi hisob turlari qo'llab-quvvatlanadi:"),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2500, 3430, 3430],
    rows: [
      new TableRow({ children: [hCell("Hisob turi", 2500), hCell("Maqsadi", 3430), hCell("Izoh", 3430)] }),
      new TableRow({ children: [cell("Joriy (Current)", 2500), cell("Kundalik to'lovlar va operatsiyalar", 3430), cell("FYaSh va YuSh uchun", 3430)] }),
      new TableRow({ children: [cell("Jamg'arma (Savings)", 2500, { shaded: true }), cell("Mablag' jamg'arish, foiz hisoblash", 3430, { shaded: true }), cell("Asosan FYaSh uchun", 3430, { shaded: true })] }),
      new TableRow({ children: [cell("Depozit (Deposit)", 2500), cell("Muddatli omonat, belgilangan foiz stavka", 3430), cell("FYaSh va YuSh uchun", 3430)] }),
      new TableRow({ children: [cell("Kredit (Loan)", 2500, { shaded: true }), cell("Kredit hisobi, to'lov grafigi", 3430, { shaded: true }), cell("FYaSh va YuSh uchun", 3430, { shaded: true })] }),
      new TableRow({ children: [cell("Maxsus (Special)", 2500), cell("Maxsus maqsadli hisoblar", 3430), cell("Asosan YuSh uchun", 3430)] }),
    ]
  }),

  heading("3.5. Hisob raqam formati", HeadingLevel.HEADING_2),
  body("Har bir hisobga 20 xonali noyob raqam tayinlanadi. Raqam quyidagi tuzilishga ega:"),
  spacer(),
  body("XXXXX-XXX-X-XXXXXXXX-XXX", { bold: true }),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2500, 1430, 5430],
    rows: [
      new TableRow({ children: [hCell("Qism", 2500), hCell("Xona soni", 1430), hCell("Izoh", 5430)] }),
      new TableRow({ children: [cell("Balans hisobi", 2500), cell("5", 1430, { center: true }), cell("Bosh kitob (General Ledger) hisobi kodi", 5430)] }),
      new TableRow({ children: [cell("Hisob turi", 2500, { shaded: true }), cell("3", 1430, { center: true, shaded: true }), cell("Hisob turi kodi (joriy, jamg'arma, depozit va h.k.)", 5430, { shaded: true })] }),
      new TableRow({ children: [cell("Kontrol raqam", 2500), cell("1", 1430, { center: true }), cell("Hisob raqamining to'g'riligini tekshirish uchun", 5430)] }),
      new TableRow({ children: [cell("Mijoz raqami", 2500, { shaded: true }), cell("8", 1430, { center: true, shaded: true }), cell("Mijozning tartib raqami", 5430, { shaded: true })] }),
      new TableRow({ children: [cell("Valyuta kodi", 2500), cell("3", 1430, { center: true }), cell("UZS=000, USD=840, EUR=978", 5430)] }),
    ]
  }),
  spacer(),
  body("Misol: 10101-001-2-00000001-000 (joriy hisob, UZS valyutada, birinchi mijoz)", { italic: true }),
  body("Hisob raqami bir marta tayinlangandan keyin o'zgartirilmaydi va qayta ishlatilmaydi.", { italic: true }),

  heading("3.6. O'zgarishlar tarixi", HeadingLevel.HEADING_2),
  body("Hisob ma'lumotlaridagi har qanday o'zgarish tizimda qayd etilishi shart:"),
  bullet("Qaysi ma'lumot o'zgargan"),
  bullet("Eski qiymat va yangi qiymat"),
  bullet("Kim o'zgartirgan (foydalanuvchi)"),
  bullet("Qachon o'zgartirilgan (sana va vaqt)"),
  bullet("O'zgarish turi: ochish, yangilash, holat o'zgartirish, yopish"),
  spacer(200),
];

// ===== 4. BIZNES QOIDALAR =====
const section4 = [
  heading("4. Biznes qoidalar", HeadingLevel.HEADING_1),

  heading("4.1. Hisob ochish qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-001", 900), cell("Hisob faqat FAOL (ACTIVE) holatdagi mijozga ochiladi. Bloklangan yoki yopiq mijozga hisob ochish taqiqlanadi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-002", 900, { shaded: true }),
        cell("Mijozning KYC (Mijozni bilish) ma'lumotlari to'liq kiritilgan bo'lishi shart. KYC to'liq bo'lmagan mijozga hisob ochib bo'lmaydi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-003", 900),
        cell("Hisob raqami tizimda yagona (noyob) bo'lishi shart. Bir xil raqamli ikkita hisob mavjud bo'lishi mumkin emas.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-013", 900, { shaded: true }),
        cell("Maker-Checker tamoyili: hisob ochishni bir xodim (Operator) yaratadi, boshqa xodim (Supervisor) tasdiqlaydi. Bir kishi ham yaratib, ham tasdiqlay olmaydi.", 5760, { shaded: true }),
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
        cell("BR-004", 900),
        cell("Holat o'tish tartibi qat'iy: FAOL → MUZLATILGAN → BLOKLANGAN → YOPIQ. YOPIQ holatdan boshqa holatga qaytish mumkin emas.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-007", 900, { shaded: true }),
        cell("Bloklangan (BLOCKED) hisobda faqat ma'lumotlarni ko'rish mumkin. Hech qanday moliyaviy operatsiya (kirim yoki chiqim) bajarilib bo'lmaydi.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-008", 900),
        cell("Muzlatilgan (FROZEN) hisobda faqat kirim operatsiyalari ruxsat etiladi. Chiqim operatsiyalari taqiqlanadi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
    ]
  }),

  heading("4.3. Hisobni yopish qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-005", 900),
        cell("Hisobni yopish uchun qoldiq nolga (0) teng bo'lishi shart. Qoldig'i bor hisobni yopib bo'lmaydi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-006", 900, { shaded: true }),
        cell("Hisobni yopish uchun kutilayotgan (bajarilmagan) tranzaksiyalar bo'lmasligi shart.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),

  heading("4.4. Moliyaviy nazorat qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-009", 900),
        cell("Bir mijozda bir valyutada bir nechta hisob bo'lishi mumkin. Cheklov qo'yilmaydi.", 5760),
        cell("O'rta", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-010", 900, { shaded: true }),
        cell("Hisob qoldig'i minimal qoldiq chegarasidan pastga tushishi mumkin emas. Overdraft (qoldiqdan ortiq sarflash) taqiqlangan.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("BR-011", 900),
        cell("Kunlik chiqim limiti oshgan taqdirda, operatsiya avtomatik to'xtatiladi va Supervisor tasdiqlashi talab qilinadi.", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
    ]
  }),

  heading("4.5. Audit qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 5760, 1350, 1350],
    rows: [
      new TableRow({ children: [hCell("ID", 900), hCell("Qoida", 5760), hCell("Muhimlik", 1350), hCell("Tur", 1350)] }),
      new TableRow({ children: [
        cell("BR-012", 900),
        cell("Har bir hisob ochish, yopish, holat o'zgartirish va bloklash operatsiyasi audit logga yoziladi (kim, qachon, nima qilgan, sabab).", 5760),
        cell("Yuqori", 1350, { center: true }), cell("Ikkala", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("BR-014", 900, { shaded: true }),
        cell("Audit logni o'chirish yoki o'zgartirish mumkin emas. Log faqat o'qish rejimida mavjud.", 5760, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Ikkala", 1350, { center: true, shaded: true })
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 5. FOYDALANUVCHI ROLLARI =====
const section5 = [
  heading("5. Foydalanuvchi rollari va huquqlar", HeadingLevel.HEADING_1),
  body("Hisoblar moduli bilan ishlaydigan foydalanuvchi rollari va ularning huquqlari:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1800, 3780, 3780],
    rows: [
      new TableRow({ children: [hCell("Rol", 1800), hCell("Nima qila oladi", 3780), hCell("Cheklovlar", 3780)] }),
      new TableRow({ children: [
        cell("Operator", 1800),
        multiCell(["Yangi hisob ochish (yaratish)", "Hisob ma'lumotlarini ko'rish", "Hisoblarni qidirish va filtrlash"], 3780),
        multiCell(["Hisobni tasdiqlash mumkin emas", "Holat o'zgartira olmaydi", "Hisobni yopa olmaydi", "Hisobotlarni ko'ra olmaydi"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Supervisor", 1800, { shaded: true }),
        multiCell(["Operator huquqlari +", "Hisob ochishni tasdiqlash (Checker)", "Hisob holatini o'zgartirish", "Muzlatish va bloklash", "Kunlik limit oshganda tasdiqlash"], 3780, { shaded: true }),
        multiCell(["Hisobni yopa olmaydi", "Tizim sozlamalarini o'zgartira olmaydi"], 3780, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("Administrator", 1800),
        multiCell(["Barcha huquqlar", "Hisobni yopish", "Tizim sozlamalari", "Hisob turlari va parametrlarini boshqarish"], 3780),
        multiCell(["Audit logni o'chira olmaydi"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Auditor", 1800, { shaded: true }),
        multiCell(["Hisoblarni ko'rish (faqat o'qish)", "Hisobotlarni ko'rish va yuklab olish", "Audit loglarni ko'rish"], 3780, { shaded: true }),
        multiCell(["Hech qanday o'zgartirish qila olmaydi", "Hisob ocha olmaydi", "Holat o'zgartira olmaydi"], 3780, { shaded: true })
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 6. INTERFEYS TALABLARI =====
const section6 = [
  heading("6. Interfeys talablari", HeadingLevel.HEADING_1),
  body("Quyida foydalanuvchi ko'rishi va ishlatishi kerak bo'lgan asosiy ekranlar tavsiflangan."),

  heading("6.1. SCR-001: Hisoblar ro'yxati", HeadingLevel.HEADING_2),
  body("Maqsad: barcha hisoblarni ko'rsatish, qidirish va filtrlash."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Qidiruv paneli — hisob raqami, CIF raqam, mijoz nomi bo'yicha qidirish"),
  bullet("Filtrlar — holat (FAOL/MUZLATILGAN/BLOKLANGAN/YOPIQ/Barchasi), valyuta (UZS/USD/EUR/Barchasi), hisob turi (Joriy/Jamg'arma/Depozit/Kredit/Maxsus/Barchasi), mijoz turi (FYaSh/YuSh/Barchasi)"),
  bullet("Natijalar jadvali — hisob raqami, mijoz nomi, hisob turi, valyuta, qoldiq, holat, ochilgan sana"),
  bullet("Sahifalash — har sahifada 20 ta yozuv"),
  bullet("\"Yangi hisob\" tugmasi — hisob ochish formasiga o'tadi"),
  bullet("Har bir qatorda \"Ko'rish\" tugmasi — hisob tafsilotlariga o'tadi"),

  heading("6.2. SCR-002: Yangi hisob ochish formasi", HeadingLevel.HEADING_2),
  body("Maqsad: yangi hisob ochish uchun zarur ma'lumotlarni kiritish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Mijozni qidirish va tanlash bloki — CIF raqam, FIO yoki tashkilot nomi bo'yicha"),
  bullet("Tanlangan mijoz ma'lumotlari kartasi (faqat o'qish rejimida)"),
  bullet("Hisob turi tanlash — ro'yxatdan (joriy, jamg'arma, depozit, kredit, maxsus)"),
  bullet("Valyuta tanlash — ro'yxatdan (UZS, USD, EUR)"),
  bullet("Hisob parametrlari bloki — minimal qoldiq, kunlik/oylik limit"),
  bullet("Imzo huquqi bloki (YuSh uchun) — shaxslar ro'yxati"),
  bullet("Real-time validatsiya — noto'g'ri qiymat kiritilsa, xato xabari ko'rsatiladi"),
  bullet("\"Saqlash\" va \"Bekor qilish\" tugmalari"),

  heading("6.3. SCR-003: Hisob tafsilotlari", HeadingLevel.HEADING_2),
  body("Maqsad: tanlangan hisob haqida to'liq ma'lumot ko'rsatish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Asosiy ma'lumotlar tabi — hisob raqami, turi, valyutasi, holati, ochilgan sana, parametrlar"),
  bullet("Mijoz ma'lumotlari — CIF raqam, FIO/nomi, aloqa ma'lumotlari (faqat o'qish)"),
  bullet("Operatsiyalar tabi — hisobdagi so'nggi operatsiyalar ro'yxati (core_trx moduldan)"),
  bullet("Tarix tabi — hisob bo'yicha barcha o'zgarishlar tarixi"),
  bullet("\"Tahrirlash\" tugmasi — tahrirlash formasiga o'tadi"),
  bullet("\"Holatni o'zgartirish\" tugmasi — modal oyna ochadi (faqat Supervisor/Admin uchun)"),

  heading("6.4. SCR-004: Hisob tahrirlash", HeadingLevel.HEADING_2),
  body("Maqsad: mavjud hisob parametrlarini o'zgartirish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Barcha o'zgartiriladigan maydonlar joriy qiymatlar bilan to'ldirilgan"),
  bullet("O'zgartirilgan maydonlar vizual ajratilgan (rangi o'zgaradi)"),
  bullet("Hisob raqami, valyutasi va turi o'zgartirilmaydi (faqat o'qish)"),
  bullet("\"Saqlash\" va \"Bekor qilish\" tugmalari"),

  heading("6.5. SCR-005: Hisob holatini o'zgartirish", HeadingLevel.HEADING_2),
  body("Maqsad: hisob holatini o'zgartirish (modal dialog oynasi)."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Joriy holat ko'rsatkichi"),
  bullet("Yangi holat tanlash (faqat ruxsat etilgan o'tishlar ko'rsatiladi)"),
  bullet("Sabab matni — majburiy matn maydoni"),
  bullet("Ogohlantirish xabari — agar YOPIQ tanlansa, qaytarib bo'lmasligini eslatadi"),
  bullet("\"Tasdiqlash\" va \"Bekor qilish\" tugmalari"),
  spacer(200),
];

// ===== 7. HISOBOTLAR =====
const section7 = [
  heading("7. Hisobotlar", HeadingLevel.HEADING_1),
  body("Hisoblar moduli quyidagi hisobotlarni taqdim etishi kerak:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1000, 2400, 3560, 2400],
    rows: [
      new TableRow({ children: [hCell("ID", 1000), hCell("Nomi", 2400), hCell("Tavsif", 3560), hCell("Chastotasi", 2400)] }),
      new TableRow({ children: [
        cell("RPT-001", 1000), cell("Hisoblar reestri", 2400),
        cell("Barcha hisoblar to'liq ma'lumotlar bilan, filtr va saralash imkoniyati", 3560), cell("Talab bo'yicha", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-002", 1000, { shaded: true }), cell("Kunlik ochilgan/yopilgan", 2400, { shaded: true }),
        cell("Tanlangan kun uchun ochilgan va yopilgan hisoblar soni va ro'yxati", 3560, { shaded: true }),
        cell("Kunlik", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-003", 1000), cell("Valyuta bo'yicha statistika", 2400),
        cell("Har bir valyuta bo'yicha hisoblar soni, umumiy qoldiq va o'rtacha qoldiq", 3560), cell("Kunlik / Oylik", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-004", 1000, { shaded: true }), cell("Qoldiqlar hisoboti", 2400, { shaded: true }),
        cell("Tanlangan sana bo'yicha barcha hisoblar qoldiqlari, filtr imkoniyati", 3560, { shaded: true }),
        cell("Talab bo'yicha", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-005", 1000), cell("Harakatsiz hisoblar", 2400),
        cell("Belgilangan muddatda (masalan, 90 kun) hech qanday operatsiya bo'lmagan hisoblar ro'yxati", 3560), cell("Oylik", 2400)
      ]}),
    ]
  }),
  spacer(200),
];

// ===== 8. INTEGRATSIYA TALABLARI =====
const section8 = [
  heading("8. Integratsiya talablari", HeadingLevel.HEADING_1),
  body("Hisoblar moduli (core_acc) MARS tizimining boshqa modullari bilan quyidagicha o'zaro aloqada bo'ladi:"),
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
        cell("core_cif", 1600), cell("CIF → ACC", 1800),
        cell("Mijoz ma'lumotlari: CIF raqam, FIO/nomi, holat, KYC daraja", 3280), cell("Hisob ochishda mijoz tekshiriladi", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_gl", 1600, { shaded: true }), cell("ACC ↔ GL", 1800, { shaded: true }),
        cell("Bosh kitob hisobi bilan sinxronizatsiya, balans hisobi kodi", 3280, { shaded: true }),
        cell("Har bir hisob ochish va operatsiyada", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("core_trx", 1600), cell("ACC ↔ TRX", 1800),
        cell("Tranzaksiya ma'lumotlari: hisob raqami, qoldiq, limit tekshiruvi", 3280), cell("Har bir kirim/chiqim operatsiyada", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_curr", 1600, { shaded: true }), cell("CURR → ACC", 1800, { shaded: true }),
        cell("Valyuta kurslari, valyuta kodlari", 3280, { shaded: true }),
        cell("Valyutali hisob ochishda va hisobotlarda", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("core_adm", 1600), cell("ADM → ACC", 1800),
        cell("Foydalanuvchi va filial ma'lumotlari", 3280), cell("Operatorni aniqlash, audit logda", 2680)
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
        cell("Jismoniy shaxs mijozga yangi hisob muvaffaqiyatli ochish mumkin (barcha turlar va valyutalar)", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("2", 700, { center: true, shaded: true }),
        cell("Yuridik shaxs mijozga yangi hisob muvaffaqiyatli ochish mumkin (barcha turlar va valyutalar)", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("3", 700, { center: true }),
        cell("20 xonali hisob raqami avtomatik generatsiya qilinadi va noyob bo'lishi kafolatlanadi", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("4", 700, { center: true, shaded: true }),
        cell("Maker-Checker tamoyili ishlaydi — Operator yaratadi, Supervisor tasdiqlaydi, bir kishi ikkala amalni bajara olmaydi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("5", 700, { center: true }),
        cell("FAOL bo'lmagan yoki KYC to'liq bo'lmagan mijozga hisob ochishga ruxsat berilmaydi", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("6", 700, { center: true, shaded: true }),
        cell("Holat o'tishlari to'g'ri ishlaydi (FAOL → MUZLATILGAN → BLOKLANGAN → YOPIQ), YOPIQ dan qaytish yo'q", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("7", 700, { center: true }),
        cell("Muzlatilgan hisobda faqat kirim ruxsat, bloklangan hisobda hech qanday operatsiya yo'q", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("8", 700, { center: true, shaded: true }),
        cell("Hisobni yopish faqat qoldiq 0 va kutilayotgan tranzaksiya yo'q bo'lganda mumkin", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("9", 700, { center: true }),
        cell("Minimal qoldiq chegarasidan pastga tushishga ruxsat berilmaydi (overdraft himoyasi ishlaydi)", 5960),
        cell("Yuqori", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("10", 700, { center: true, shaded: true }),
        cell("Kunlik limit oshganda operatsiya to'xtatiladi va Supervisor tasdiqlashi so'raladi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
      ]}),
      new TableRow({ children: [
        cell("11", 700, { center: true }),
        cell("Qidiruv barcha mezonlar bo'yicha ishlaydi (hisob raqam, CIF, mijoz nomi, valyuta, tur, holat)", 5960),
        cell("O'rta", 1350, { center: true }), cell("Kutilmoqda", 1350, { center: true })
      ]}),
      new TableRow({ children: [
        cell("12", 700, { center: true, shaded: true }),
        cell("Har bir hisob ochish, yopish va holat o'zgartirish audit logga yoziladi va log o'chirilmaydi", 5960, { shaded: true }),
        cell("Yuqori", 1350, { center: true, shaded: true }), cell("Kutilmoqda", 1350, { center: true, shaded: true })
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
          children: [new TextRun({ text: "MARS ABS  |  BT-002  |  core_acc", font: "Arial", size: 18, color: "999999" })]
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
const OUTPUT = "/Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project/docs/BT-002_core_acc_biznes_talab.docx";
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUTPUT, buf);
  console.log(`Generated: ${OUTPUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

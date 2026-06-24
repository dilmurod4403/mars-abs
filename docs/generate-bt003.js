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
    children: [new TextRun({ text: "BT-003: core_ac — Buxgalteriya yadrosi (core accounting): Pul o'tkazmalari", font: "Arial", size: 28, color: DARK_GRAY })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "Money Transfers", font: "Arial", size: 24, italics: true, color: "666666" })]
  }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({
    width: { size: 5000, type: WidthType.DXA },
    columnWidths: [2000, 3000],
    rows: [
      new TableRow({ children: [cell("Hujjat raqami:", 2000, { bold: true }), cell("BT-003", 3000)] }),
      new TableRow({ children: [cell("Versiya:", 2000, { bold: true, shaded: true }), cell("1.0", 3000, { shaded: true })] }),
      new TableRow({ children: [cell("Sana:", 2000, { bold: true }), cell("2026-06-24", 3000)] }),
      new TableRow({ children: [cell("Modul:", 2000, { bold: true, shaded: true }), cell("core_ac (Pul o'tkazmalari)", 3000, { shaded: true })] }),
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
  body("Ushbu hujjat MARS avtomatlashtirilgan bank tizimining Pul o'tkazmalari moduli (core_ac) uchun biznes talablarni belgilaydi."),
  body("Modul bank mijozlarining hisoblari o'rtasida pul mablag'larini ko'chirish — o'tkazma yaratish, tasdiqlash, bajarish (chiqim/kirim), rad etish va qaytarish (storno), shuningdek o'tkazmalar tarixini yuritish jarayonlarini markazlashtirilgan holda boshqarish uchun mo'ljallangan."),
  body("Modul Hisoblar moduli (core_acc) bilan chambarchas bog'liq: har bir o'tkazma kamida bitta hisobni chiqim (debet) va bitta hisobni kirim (kredit) qiladi, natijada hisob qoldig'i (saldo) o'zgaradi. O'tkazma core_acc dagi hisob holati, valyuta va qoldiq qoidalariga to'liq bo'ysunadi."),
  body("Modulning asosiy maqsadlari:"),
  bullet("Pul o'tkazmalarini xavfsiz, nazorat ostida va izlanuvchan (audit) tarzda amalga oshirish"),
  bullet("Maker-Checker tamoyili orqali har bir o'tkazmani ikki bosqichda nazorat qilish (operator yaratadi, supervisor tasdiqlaydi)"),
  bullet("Hisob qoldig'ini darhol va to'g'ri yuritish — qoldiqdan ortiq sarflashga (overdraft) yo'l qo'ymaslik"),
  bullet("O'zbekiston Respublikasi to'lov tizimlari talablariga (to'lov maqsadi, valyutalash sanasi, banklararo hisob-kitob) izchillik"),

  heading("1.2. Qamrov", HeadingLevel.HEADING_2),
  body("Hujjat quyidagi biznes sohalarni qamrab oladi."),
  body("Birinchi navbatda amalga oshiriladi (F0 yadro):", { bold: true }),
  bullet("Ichki o'tkazma (bank ichidagi hisoblar o'rtasida): bir mijozdan boshqa mijozga; shuningdek bir mijozning o'z hisoblari o'rtasida"),
  bullet("O'tkazmani yaratish, tasdiqlash va bajarish (chiqim/kirim)"),
  bullet("Tasdiqlanmagan o'tkazmani rad etish va bajarilgan o'tkazmani qaytarish (storno)"),
  bullet("O'tkazmalar tarixini ko'rish, qidirish va filtrlash"),
  bullet("Komissiya (xizmat haqi) hisoblash va undirish tartibining biznes qoidalari"),
  bullet("O'tkazmaning to'lov maqsadini qayd etish"),
  spacer(),
  body("Keyingi fazada amalga oshiriladi (kelgusi talab):", { bold: true }),
  bullet("Banklararo o'tkazma — boshqa bankka, Markaziy bank to'lov/kliring tizimlari orqali (MFO/filial kodi bo'yicha)"),
  bullet("Byudjet to'lovlari — soliq va boshqa byudjet to'lovlari (yagona g'aznachilik hisobiga)"),
  bullet("Valyuta konvertatsiyasi bilan o'tkazma (turli valyutadagi hisoblar o'rtasida — core_curr kurslari asosida)"),
  bullet("Ommaviy (paket) o'tkazmalar — ko'p o'tkazmani bir faylda yuklab bajarish (ish haqi ro'yxati va h.k.)"),
  bullet("Rejalashtirilgan/takroriy o'tkazmalar (kelajak sanaga yoki davriy)"),
  spacer(),
  body("Hujjat qamramaydi:", { bold: true }),
  bullet("Naqd pul kirim/chiqim operatsiyalari (op_cash / op_teller moduli mas'uliyati)"),
  bullet("Bosh kitobdagi (General Ledger) buxgalteriya provodkalarini yuritish tafsilotlari (core_gl moduli; core_ac faqat hisob qoldig'i darajasida ishlaydi)"),
  bullet("Hisob ochish/yopish va holat boshqaruvi (core_acc moduli)"),
  bullet("Operatsion kunni ochish va yopish (core_gl / core_adm moduli mas'uliyati; core_ac faqat ochiq kun ma'lumotidan foydalanadi)"),

  heading("1.3. Maqsadli auditoriya", HeadingLevel.HEADING_2),
  body("Ushbu hujjat quyidagi tomonlar uchun mo'ljallangan:"),
  bullet("Biznes tahlilchilar va loyiha rahbarlari"),
  bullet("Dasturchilar (Texnik Topshiriq — TZ-003 uchun asos sifatida)"),
  bullet("Bank operatsion xodimlari — operatorlar va supervisorlar (jarayonlarni tushunish uchun)"),
  bullet("Sifat nazorati (QA) bo'limi (test stsenariylarini shakllantirish uchun)"),
  bullet("Ichki audit va xavfsizlik bo'limi (nazorat va izlanuvchanlik talablarini baholash uchun)"),

  heading("1.4. Atamalar va qisqartmalar", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2600, 6760],
    rows: [
      new TableRow({ children: [hCell("Atama", 2600), hCell("Ta'rifi", 6760)] }),
      new TableRow({ children: [cell("O'tkazma (tranzaksiya)", 2600), cell("Bir hisobdan boshqa hisobga pul mablag'ini ko'chirish operatsiyasi; tizimda yagona hujjat (yozuv) sifatida saqlanadi", 6760)] }),
      new TableRow({ children: [cell("To'lovchi (jo'natuvchi)", 2600, { shaded: true }), cell("Pul o'tkazmasi chiqayotgan hisob egasi; uning hisobi chiqim (debet) qilinadi", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Oluvchi (qabul qiluvchi)", 2600), cell("Pul o'tkazmasi tushadigan hisob egasi; uning hisobi kirim (kredit) qilinadi", 6760)] }),
      new TableRow({ children: [cell("Chiqim (debet)", 2600, { shaded: true }), cell("Hisobdan pul chiqishi; to'lovchi hisobida qoldiq kamayadi", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Kirim (kredit)", 2600), cell("Hisobga pul kirishi; oluvchi hisobida qoldiq oshadi", 6760)] }),
      new TableRow({ children: [cell("Qoldiq (saldo)", 2600, { shaded: true }), cell("Hisobda mavjud joriy pul mablag'i", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Hisob holati", 2600), cell("Hisobning core_acc dagi holati: Yaratilgan / Tasdiqlangan / Bloklangan / Vaqtincha yopilgan / Yopilgan", 6760)] }),
      new TableRow({ children: [cell("O'tkazma holati", 2600, { shaded: true }), cell("O'tkazma hujjatining bosqichi: Tasdiq kutilmoqda / Bajarilgan / Rad etilgan / Bekor qilingan / Storno", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Ichki o'tkazma", 2600), cell("MARS tizimi ichidagi (bir bank doirasidagi) ikki hisob o'rtasidagi o'tkazma", 6760)] }),
      new TableRow({ children: [cell("Banklararo o'tkazma", 2600, { shaded: true }), cell("Boshqa bankdagi hisobga, Markaziy bank to'lov tizimi orqali amalga oshiriladigan o'tkazma (keyingi faza)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("To'lov maqsadi", 2600), cell("O'tkazma nima uchun amalga oshirilayotganini tavsiflovchi matn va/yoki kod", 6760)] }),
      new TableRow({ children: [cell("Valyutalash sanasi", 2600, { shaded: true }), cell("Mablag' hisobga rasman o'tgan deb hisoblanadigan sana (F0 da — bajarilgan operatsion kun)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Komissiya (xizmat haqi)", 2600), cell("Bank o'tkazma uchun undiradigan to'lov; to'lovchi hisobidan, summadan tashqari (qo'shimcha) ushlanadi", 6760)] }),
      new TableRow({ children: [cell("Storno", 2600, { shaded: true }), cell("Bajarilgan o'tkazmani teskari (qarshi) yozuv bilan bekor qilish; qoldiqlar dastlabki holatga qaytariladi", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Maker", 2600), cell("O'tkazmani yaratuvchi xodim (operator)", 6760)] }),
      new TableRow({ children: [cell("Checker", 2600, { shaded: true }), cell("O'tkazmani tasdiqlovchi xodim (supervisor); Maker bilan bir shaxs bo'la olmaydi", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Maker-Checker", 2600), cell("Ikki bosqichli nazorat tamoyili — bir xodim yaratadi, boshqasi tasdiqlaydi", 6760)] }),
      new TableRow({ children: [cell("Hujjat (referens) raqami", 2600, { shaded: true }), cell("O'tkazmaning noyob aniqlash raqami; hujjat raqami va referens raqami bir xil identifikatordir", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("MFO", 2600), cell("Bank filiali (bo'limi) kodi; banklararo o'tkazmalarda oluvchi bankni aniqlaydi", 6760)] }),
      new TableRow({ children: [cell("Markaziy bank kliring", 2600, { shaded: true }), cell("Banklararo o'zaro to'lovlarni hisob-kitob qilish tizimi (tezkor va chakana kliring)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Yagona g'aznachilik hisobi", 2600), cell("Byudjet to'lovlari tushadigan yagona davlat hisobi", 6760)] }),
      new TableRow({ children: [cell("AML", 2600, { shaded: true }), cell("Jinoiy yo'l bilan olingan daromadlarni legallashtirishga qarshi nazorat", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("CIF", 2600), cell("Customer Information File — mijoz ma'lumotlar bazasi (core_cif)", 6760)] }),
      new TableRow({ children: [cell("UZS / USD / EUR", 2600, { shaded: true }), cell("O'zbekiston so'mi (kod 000), AQSh dollari (840), Yevro (978)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Qo'sh yozuv (balansli)", 2600), cell("Har bir bajarilgan o'tkazmada jami chiqim summasi jami kirim summasiga teng bo'lishi (balans buzilmasligi)", 6760)] }),
      new TableRow({ children: [cell("Provodka (buxgalteriya yozuvi)", 2600, { shaded: true }), cell("Qo'sh yozuvning bir bo'lagi — ma'lum hisobning debetiga (chiqim) yoki kreditiga (kirim) tegishli summani qayd etuvchi yagona buxgalteriya yozuvi", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Provodkalar jurnali", 2600), cell("Barcha buxgalteriya yozuvlarining (provodkalarning) yagona xronologik registri; har bir yozuv ketma-ket qayd etiladi va o'zgartirilmaydi (faqat qo'shiladi — audit izi)", 6760)] }),
      new TableRow({ children: [cell("Kiritilgan (Введён)", 2600, { shaded: true }), cell("Provodkaning boshlang'ich holati: yozuv kiritildi, ammo hisob qoldig'i va aylanmasiga hali ta'sir qilmaydi (qoralama yozuv)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("Tekshirilgan (Проверен)", 2600), cell("Provodka tekshiruvdan o'tgan oraliq holati (Maker-Checker bo'yicha, ixtiyoriy); qoldiqqa hali ta'sir qilmaydi", 6760)] }),
      new TableRow({ children: [cell("O'tkazilgan (Проведён)", 2600, { shaded: true }), cell("Provodka kitobga rasman o'tkazilgan holati: hisob qoldig'i va aylanmasiga ta'sir qiladi — pul haqiqatan harakatlanadi. Ijobiy-yakuniy holat (faqat storno orqali qaytariladi)", 6760, { shaded: true })] }),
      new TableRow({ children: [cell("O'chirilgan (Удалён)", 2600), cell("Provodka faqat Kiritilgan yoki Tekshirilgan holatdan o'chiriladi (qoldiqqa ta'sir qilmasdan); O'tkazilgan provodkani o'chirib bo'lmaydi", 6760)] }),
      new TableRow({ children: [cell("Storno (Сторнирован)", 2600, { shaded: true }), cell("O'tkazilgan (bajarilgan) provodka yoki o'tkazma teskari (qarshi) yozuv orqali bekor qilinishi; qoldiqlar dastlabki holatga qaytariladi, asl yozuv o'chirilmaydi", 6760, { shaded: true })] }),
    ]
  }),
  spacer(200),
];

// ===== 2. BIZNES JARAYONLAR =====
const section2 = [
  heading("2. Biznes jarayonlar", HeadingLevel.HEADING_1),
  body("Quyida core_ac modulining asosiy biznes jarayonlari (BP — Business Process) qadamma-qadam keltirilgan. Jarayonlar Maker-Checker tamoyiliga asoslanadi: o'tkazmani operator yaratadi (Maker), supervisor tasdiqlaydi va bajaradi (Checker)."),

  // --- BP-001 ---
  heading("2.1. BP-001: Ichki o'tkazma yaratish", HeadingLevel.HEADING_2),
  body("Operator bank ichidagi ikki hisob o'rtasida yangi pul o'tkazmasini shakllantiradi. Bu jarayon faqat o'tkazmani yaratadi — pul hali ko'chirilmaydi; saqlangan o'tkazma supervisor tasdiqlashini kutadi (\"Tasdiq kutilmoqda\" holati)."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-001", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Bank operatori (Maker)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Operator tizimga kirgan; to'lovchi va oluvchi hisoblari tizimda mavjud va Tasdiqlangan (faol) holatda", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("O'tkazma \"Tasdiq kutilmoqda\" holatida saqlangan, hujjat (referens) raqami berilgan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Operator \"Yangi o'tkazma\" formasini ochadi"),
  numberedItem("To'lovchi hisobini tanlaydi — hisob raqami yoki mijoz (CIF/nom) bo'yicha qidirib topadi"),
  numberedItem("Tizim to'lovchi hisobini tekshiradi: hisob Tasdiqlangan (faol) holatda bo'lishi va chiqim operatsiyasiga ruxsat berilishi shart (Bloklangan yoki Vaqtincha yopilgan hisobdan chiqim mumkin emas)"),
  numberedItem("Oluvchi hisobini tanlaydi — hisob raqami yoki mijoz bo'yicha; tizim oluvchi hisobini ham tekshiradi (kirim qabul qila olishi shart)"),
  numberedItem("Tizim ikkala hisob valyutasini solishtiradi — F0 yadroda valyutalar bir xil bo'lishi shart (turli valyuta = keyingi faza, konvertatsiya bilan)"),
  numberedItem("Operator o'tkazma summasini kiritadi (tegishli valyutada, 2 kasr aniqligida); tizim summa noldan katta ekanini tekshiradi"),
  numberedItem("Operator to'lov maqsadini kiritadi — majburiy matn maydoni"),
  numberedItem("Tizim komissiyani biznes qoidalari bo'yicha hisoblaydi (o'z hisoblari o'rtasidagi o'tkazmada komissiya 0) va to'lovchiga qo'shimcha ravishda ushlanishini ko'rsatadi"),
  numberedItem("Tizim to'lovchi hisobida yetarli qoldiq borligini darhol tekshiradi: summa va komissiya yig'indisi hisobga olinib, qoldiq minimal qoldiqdan pastga tushmasligi shart (overdraft taqiqlanadi)"),
  numberedItem("Operator ma'lumotlarni \"Saqlash va tasdiqqa yuborish\" orqali saqlaydi — o'tkazma \"Tasdiq kutilmoqda\" holatiga tushadi, unga noyob hujjat (referens) raqami beriladi"),
  numberedItem("O'tkazmani yaratish operatsiyasi (kim, qachon, qaysi hisoblar, summa) audit logga yoziladi"),
  spacer(),
  body("Natija: \"Tasdiq kutilmoqda\" holatdagi o'tkazma supervisor tasdiqlash navbatiga tushadi. Pul ushbu bosqichda ko'chirilmaydi va hisob qoldig'iga ta'sir qilmaydi.", { italic: true }),
  body("Eslatma: Operatorning o'zi o'tkazmani tasdiqlay olmaydi (Maker-Checker).", { italic: true }),

  // --- BP-002 ---
  heading("2.2. BP-002: O'tkazmani tasdiqlash va bajarish", HeadingLevel.HEADING_2),
  body("Supervisor \"Tasdiq kutilmoqda\" holatidagi o'tkazmani ko'rib chiqadi, tasdiqlaydi va bajaradi. Aynan shu bosqichda pul to'lovchi hisobidan oluvchi hisobiga ko'chiriladi (chiqim/kirim) va qoldiqlar yangilanadi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-002", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Supervisor (Checker)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("O'tkazma \"Tasdiq kutilmoqda\" holatida; Checker o'tkazmani yaratgan Maker bilan bir shaxs emas", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("O'tkazma \"Bajarilgan\" holatida; to'lovchi hisob chiqim, oluvchi hisob kirim qilingan; qoldiqlar yangilangan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Supervisor tasdiqlash kutayotgan o'tkazmalar ro'yxatini ochadi va kerakli o'tkazmani tanlaydi"),
  numberedItem("Tizim o'tkazma tafsilotlarini ko'rsatadi: to'lovchi/oluvchi hisob, summa, valyuta, komissiya, to'lov maqsadi, yaratgan operator"),
  numberedItem("Tizim Maker-Checker qoidasini tekshiradi — tasdiqlovchi shaxs yaratuvchi bilan bir xil bo'lsa, tasdiqlashga ruxsat berilmaydi"),
  numberedItem("Supervisor ma'lumotlarni qayta tekshiradi"),
  numberedItem("Tasdiqlash tanlansa, tizim bajarish oldidan barcha biznes qoidalarni qayta tekshiradi: to'lovchi hisob hamon Tasdiqlangan va chiqimga ruxsat etilgan; oluvchi hisob hamon kirim qabul qila oladi; to'lovchi hisobida qoldiq yetarli (summa + komissiya), minimal qoldiq buzilmaydi (yaratish vaqtidan keyin holat o'zgargan bo'lishi mumkin)"),
  numberedItem("Tekshiruvlar muvaffaqiyatli bo'lsa, tizim bir butun amal sifatida: to'lovchi hisobini summa va komissiya miqdorida chiqim qiladi (qoldiq kamayadi); oluvchi hisobini summa miqdorida kirim qiladi (qoldiq oshadi); komissiyani tegishli bank daromad hisobiga yozadi"),
  numberedItem("O'tkazmaga valyutalash sanasi (bajarilgan operatsion kun) belgilanadi va holati \"Bajarilgan\" ga o'tadi"),
  numberedItem("Operatsiya — kim tasdiqlagani, qachon, qoldiqlarning oldingi va yangi qiymatlari — audit logga yoziladi"),
  spacer(),
  body("Natija: O'tkazma \"Bajarilgan\" holatda; pul ko'chirilgan, ikkala hisob qoldig'i yangilangan; o'tkazma tarixda ko'rinadi.", { italic: true }),
  body("Muhim: Chiqim va kirim yagona, bo'linmas amal sifatida bajariladi — yo to'liq bajariladi, yo umuman bajarilmaydi (yarim qolmaydi). Xatolik yuz bersa, o'tkazma bajarilmaydi va \"Tasdiq kutilmoqda\" holatida qoladi. Qoldiq faqat tasdiqlash payti yechiladi (oldindan rezerv qilinmaydi).", { italic: true }),

  // --- BP-003 ---
  heading("2.3. BP-003: O'tkazmani rad etish, bekor qilish yoki qaytarish (storno)", HeadingLevel.HEADING_2),
  body("Bu jarayon uchta holatni qamrab oladi: (a) tasdiq kutayotgan o'tkazmani rad etish; (b) hali bajarilmagan o'tkazmani bekor qilish (qoralamani); (v) allaqachon bajarilgan o'tkazmani qaytarish (storno)."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-003", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Rad etish: Supervisor (Checker). Bekor qilish: Maker yoki Supervisor. Qaytarish (storno): Supervisor (Administrator ham, barcha huquqlar doirasida)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Rad/bekor uchun — o'tkazma \"Tasdiq kutilmoqda\" holatida. Qaytarish uchun — o'tkazma \"Bajarilgan\" holatida", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("\"Rad etilgan\", \"Bekor qilingan\" yoki \"Storno\" holati; sabab qayd etilgan", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("2.3.1. Tasdiqlanmagan o'tkazmani rad etish yoki bekor qilish", { bold: true }),
  numberedItem("Supervisor tasdiqlash kutayotgan (\"Tasdiq kutilmoqda\") o'tkazmani ochadi"),
  numberedItem("\"Rad etish\" ni tanlaydi va rad etish sababini kiritadi (majburiy matn maydoni); muqobil ravishda Maker o'z qoralamasini \"Bekor qilish\"ga o'tkazishi mumkin"),
  numberedItem("Tizim o'tkazmani \"Rad etilgan\" yoki \"Bekor qilingan\" holatga o'tkazadi (fizik o'chirilmaydi — izlanuvchanlik talabi)"),
  numberedItem("Hech qanday chiqim/kirim bajarilmagani uchun hisob qoldiqlari o'zgarmaydi"),
  numberedItem("Operatsiya (kim, qachon, sabab) audit logga yoziladi"),
  spacer(),
  body("Natija: O'tkazma bajarilmaydi; qoldiqlarga ta'sir qilmaydi; tarixda saqlanadi.", { italic: true }),
  spacer(),
  body("2.3.2. Bajarilgan o'tkazmani qaytarish (storno)", { bold: true }),
  numberedItem("Supervisor (yoki Administrator) \"Bajarilgan\" o'tkazmani topadi va \"Qaytarish (storno)\" ni tanlaydi"),
  numberedItem("Qaytarish sababini kiritadi (majburiy matn maydoni)"),
  numberedItem("Tizim qaytarish bajarilishi mumkinligini tekshiradi — masalan, oluvchi hisobda qaytariladigan mablag' mavjudligi va hisob holati qaytarishga to'sqinlik qilmasligi"),
  numberedItem("Tizim teskari (qarshi) yozuv yaratadi: oldingi to'lovchi hisobi kirim qilinadi, oldingi oluvchi hisobi chiqim qilinadi (asl summa miqdorida; ushlangan komissiya ham to'liq qaytariladi)"),
  numberedItem("Asl o'tkazma \"Storno\" holatga o'tkaziladi va teskari yozuv bilan bog'lanadi; ikkala hisob qoldig'i yangilanadi"),
  numberedItem("Storno operatsiyasi audit logga to'liq yoziladi (asl hujjat raqami, qaytarish hujjat raqami, sabab, ijrochi)"),
  spacer(),
  body("Natija: Asl o'tkazma ta'siri bekor qilingan; qoldiqlar storno yozuvi hisobiga tiklangan; har ikki yozuv ham tarixda saqlanadi (o'tkazma o'chirilmaydi).", { italic: true }),
  body("Muhim: O'tkazma hech qachon fizik o'chirilmaydi — faqat holati o'zgaradi yoki teskari yozuv bilan qaytariladi.", { italic: true }),

  // --- BP-004 ---
  heading("2.4. BP-004: O'tkazmalar tarixini ko'rish va qidirish", HeadingLevel.HEADING_2),
  body("Foydalanuvchi amalga oshirilgan va kutilayotgan o'tkazmalarni turli mezonlar bo'yicha qidiradi, filtrlaydi va ko'radi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-004", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Operator, Supervisor, Administrator, Auditor (huquqlariga muvofiq)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("Foydalanuvchi tizimga kirgan va tegishli ko'rish huquqiga ega", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Talab qilingan o'tkazmalar ro'yxati ko'rsatilgan; tafsilotlarga o'tish mumkin", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("Foydalanuvchi o'tkazmalar ro'yxati ekranini ochadi"),
  numberedItem("Qidiruv/filtr mezonlarini belgilaydi"),
  numberedItem("Tizim mos o'tkazmalar ro'yxatini ko'rsatadi (sahifalab)"),
  numberedItem("Foydalanuvchi bitta o'tkazmani tanlab, to'liq tafsilotini ko'radi: to'lovchi/oluvchi, summa, valyuta, komissiya, to'lov maqsadi, holati, hujjat raqami, yaratgan va tasdiqlagan xodimlar, sanalar"),
  numberedItem("Tegishli huquqi bo'lsa, foydalanuvchi o'tkazmani chop etishga/eksport (jadval ko'rinishida yuklab olish) ga chiqaradi yoki (qaytariladigan bo'lsa) storno jarayoniga o'tadi"),
  spacer(),
  body("Qidiruv va filtr mezonlari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3700, 2830, 2830],
    rows: [
      new TableRow({ children: [hCell("Mezon", 3700), hCell("Qidiruv turi", 2830), hCell("Natija", 2830)] }),
      new TableRow({ children: [cell("Hujjat (referens) raqami", 3700), cell("Aniq moslik", 2830), cell("Bitta o'tkazma", 2830)] }),
      new TableRow({ children: [cell("To'lovchi/oluvchi hisob raqami", 3700, { shaded: true }), cell("Aniq moslik", 2830, { shaded: true }), cell("Hisob bo'yicha o'tkazmalar", 2830, { shaded: true })] }),
      new TableRow({ children: [cell("Mijoz (CIF/nom)", 3700), cell("Qisman moslik", 2830), cell("Ro'yxat", 2830)] }),
      new TableRow({ children: [cell("O'tkazma holati", 3700, { shaded: true }), cell("Filtr", 2830, { shaded: true }), cell("Ro'yxat", 2830, { shaded: true })] }),
      new TableRow({ children: [cell("Valyuta (UZS/USD/EUR)", 3700), cell("Filtr", 2830), cell("Ro'yxat", 2830)] }),
      new TableRow({ children: [cell("Summa oralig'i", 3700, { shaded: true }), cell("Filtr", 2830, { shaded: true }), cell("Ro'yxat", 2830, { shaded: true })] }),
      new TableRow({ children: [cell("Sana oralig'i (yaratilgan/bajarilgan)", 3700), cell("Filtr", 2830), cell("Ro'yxat", 2830)] }),
    ]
  }),

  // --- BP-005 (Provodkalar jurnali) ---
  heading("2.5. BP-005: Provodkalar jurnalini yuritish va ko'rish", HeadingLevel.HEADING_2),
  body("Provodkalar jurnali — modulning buxgalteriya o'zagi: barcha buxgalteriya yozuvlarining (provodkalarning) yagona xronologik registri. Har bir o'tkazma bajarilganda hosil bo'lgan provodkalar shu jurnalga ketma-ket qayd etiladi. Bu jarayon provodkalar jurnali avtomatik to'ldirilishini va foydalanuvchi tomonidan ko'rilishini tavsiflaydi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Xususiyat", 2400), hCell("Tavsif", 6960)] }),
      new TableRow({ children: [cell("Jarayon ID", 2400), cell("BP-005", 6960)] }),
      new TableRow({ children: [cell("Ishtirokchilar", 2400, { shaded: true }), cell("Tizim (avtomatik yozuv); Operator, Supervisor, Administrator, Auditor (ko'rish, huquqlariga muvofiq)", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Kirish sharti", 2400), cell("O'tkazma bo'yicha provodkalar shakllantirilgan; foydalanuvchi tegishli ko'rish huquqiga ega", 6960)] }),
      new TableRow({ children: [cell("Chiqish sharti", 2400, { shaded: true }), cell("Provodkalar jurnali xronologik tartibda ko'rsatilgan; har bir provodka holati va summasi ko'rinadi", 6960, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Jarayon qadamlari:", { bold: true }),
  numberedItem("O'tkazma yaratilganda tizim unga mos provodkalarni \"Kiritilgan\" holatda jurnalga qo'shadi (qoldiqqa ta'sir qilmaydi — qoralama yozuv)"),
  numberedItem("O'tkazma tasdiqlanib bajarilganda provodkalar \"O'tkazilgan\" holatga o'tadi va aynan shu payt hisob qoldig'i va aylanmasiga ta'sir qiladi"),
  numberedItem("O'tkazma rad/bekor qilinsa provodkalar \"O'chirilgan\" holatga, storno qilinsa \"Storno\" holatga o'tadi va qarshi yozuvlar bilan bog'lanadi"),
  numberedItem("Har bir provodka jurnalga xronologik (provodka sanasi va ketma-ketligi bo'yicha) qayd etiladi; mavjud yozuv o'zgartirilmaydi — faqat yangi yozuv qo'shiladi"),
  numberedItem("Foydalanuvchi provodkalar jurnali ekranini ochib, yozuvlarni sana, hisob, holat, debet/kredit va bog'liq hujjat raqami bo'yicha filtrlaydi va ko'radi"),
  numberedItem("Foydalanuvchi bitta provodkani tanlab, uning bog'liq o'tkazma hujjatiga (referens raqami orqali) o'tadi"),
  spacer(),
  body("Natija: provodkalar jurnali har bir o'tkazmaning buxgalteriya izini to'liq va o'zgartirib bo'lmas tarzda saqlaydi; jurnal Bosh kitob (core_gl) uchun birlamchi yozuv manbai bo'lib xizmat qiladi.", { italic: true }),
  body("Muhim: Jurnal yozuvlari hech qachon o'chirilmaydi yoki tahrirlanmaydi — to'g'rilash faqat yangi (storno yoki tuzatuvchi) yozuv qo'shish orqali amalga oshadi.", { italic: true }),

  // --- BP-006 ---
  heading("2.6. BP-006: Banklararo va byudjet o'tkazmalari (keyingi faza)", HeadingLevel.HEADING_2),
  body("Quyidagi o'tkazma turlari keyingi fazada amalga oshiriladi va hozircha biznes talab darajasida qisqacha belgilanadi. Ular F0 yadroga kirmaydi."),
  spacer(),
  body("Banklararo o'tkazma:", { bold: true }),
  bullet("Operator oluvchi bank MFO (filial) kodini, oluvchi hisob raqamini va oluvchi nomini kiritadi"),
  bullet("Tizim MFO kodini va hisob raqami formatini tekshiradi"),
  bullet("O'tkazma kliring turini (tezkor yoki chakana) belgilaydi va Markaziy bank to'lov tizimiga jo'natish uchun shakllantiradi"),
  bullet("Bajarilishi tashqi tizim tasdig'iga bog'liq; o'tkazma \"Jo'natildi\" → \"Bajarildi\" yoki \"Rad etildi\" holatlaridan o'tadi"),
  bullet("Maker-Checker tamoyili saqlanadi"),
  spacer(),
  body("Byudjet to'lovlari:", { bold: true }),
  bullet("Operator byudjet to'lovi rekvizitlarini kiritadi: to'lov maqsadi kodi, byudjet daromad kodi, to'lovchi identifikatori (INN/PINFL)"),
  bullet("Tizim majburiy byudjet rekvizitlarining to'liqligini tekshiradi"),
  bullet("O'tkazma yagona g'aznachilik hisobiga yo'naltiriladi"),
  bullet("Maker-Checker tamoyili saqlanadi"),
  spacer(),
  body("Eslatma: Ushbu turlarning batafsil jarayonlari, biznes qoidalari va rekvizit ro'yxati keyingi faza biznes talabida (BT-003 keyingi versiyasi yoki alohida BT) to'liq yoritiladi.", { italic: true }),
];

// ===== 3. MA'LUMOTLAR TALABLARI (BIZNES TILDA) =====
const section3 = [
  heading("3. Ma'lumotlar talablari", HeadingLevel.HEADING_1),
  body("Quyida pul o'tkazmalari uchun tizimda saqlanishi kerak bo'lgan ma'lumotlar guruhlari biznes tilida keltirilgan. Texnik amalga oshirish (jadval strukturasi, maydon turlari, hajmlari) Texnik Topshiriq (TZ-003) da batafsil yoritiladi."),

  heading("3.1. O'tkazma hujjati asosiy ma'lumotlari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 4060, 2300],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3000), hCell("Mazmuni", 4060), hCell("Majburiyligi", 2300)] }),
      new TableRow({ children: [cell("Hujjat (referens) raqami", 3000), cell("O'tkazma hujjatining noyob tartib raqami; tizim avtomatik beradi", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Hujjat sanasi", 3000, { shaded: true }), cell("Hujjat tuzilgan sana (operatsion kunga bog'liq)", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("O'tkazma turi", 3000), cell("Ichki / Banklararo / Byudjet to'lovi", 4060), cell("Majburiy", 2300)] }),
      new TableRow({ children: [cell("To'lovchi hisob", 3000, { shaded: true }), cell("Mablag' yechib olinadigan hisob raqami (bizning bankdagi hisob)", 4060, { shaded: true }), cell("Majburiy", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("To'lovchi nomi", 3000), cell("To'lovchining nomi/FIO (hisobdan avtomatik to'ldiriladi)", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Oluvchi hisob", 3000, { shaded: true }), cell("Mablag' tushadigan hisob raqami", 4060, { shaded: true }), cell("Majburiy", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Oluvchi nomi", 3000), cell("Oluvchining nomi/FIO", 4060), cell("Majburiy", 2300)] }),
      new TableRow({ children: [cell("Oluvchi banki (MFO)", 3000, { shaded: true }), cell("Banklararo o'tkazmada — oluvchi bankning filial kodi", 4060, { shaded: true }), cell("Shartli (banklararo)", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Summa", 3000), cell("O'tkaziladigan mablag' (tegishli valyutada, 2 kasr aniqligida)", 4060), cell("Majburiy", 2300)] }),
      new TableRow({ children: [cell("Valyuta", 3000, { shaded: true }), cell("O'tkazma valyutasi: UZS (000), USD (840), EUR (978)", 4060, { shaded: true }), cell("Majburiy", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("To'lov maqsadi (matn)", 3000), cell("To'lovning maqsadini erkin matnda tavsiflash", 4060), cell("Majburiy", 2300)] }),
      new TableRow({ children: [cell("To'lov maqsadi kodi", 3000, { shaded: true }), cell("Tasniflagich bo'yicha to'lov maqsadi kodi", 4060, { shaded: true }), cell("Shartli (banklararo/byudjet)", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Valyutalash sanasi", 3000), cell("Mablag' hisobga o'tkaziladigan sana (F0 da — bajarilgan operatsion kun)", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Komissiya summasi", 3000, { shaded: true }), cell("Bank xizmati uchun to'lovchidan qo'shimcha ushlanadigan haq", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Komissiya hisobi", 3000), cell("Komissiya yo'naltiriladigan bank daromad hisobi", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("O'tkazma holati", 3000, { shaded: true }), cell("O'tkazmaning joriy bosqichi", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Yaratuvchi (Maker)", 3000), cell("O'tkazmani kiritgan xodim nomi", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Yaratilgan sana/vaqt", 3000, { shaded: true }), cell("O'tkazma kiritilgan vaqt", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Tasdiqlovchi (Checker)", 3000), cell("O'tkazmani tasdiqlagan/bajargan xodim nomi", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Tasdiqlangan sana/vaqt", 3000, { shaded: true }), cell("O'tkazma tasdiqlangan/bajarilgan vaqt", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Rad/bekor/storno sababi", 3000), cell("Rad etilgan, bekor qilingan yoki storno qilingan hollarda sabab matni", 4060), cell("Shartli (rad/bekor/storno)", 2300)] }),
    ]
  }),
  spacer(),
  body("Byudjet to'lovlari uchun qo'shimcha ma'lumotlar (faqat byudjet to'lovi turida — keyingi faza):", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 4060, 2300],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3000), hCell("Mazmuni", 4060), hCell("Majburiyligi", 2300)] }),
      new TableRow({ children: [cell("INN/PINFL", 3000), cell("To'lovchining soliq to'lovchi identifikatori", 4060), cell("Majburiy", 2300)] }),
      new TableRow({ children: [cell("Byudjet hisobi turi", 3000, { shaded: true }), cell("Yagona g'aznachilik hisobi yoki tegishli byudjet hisobi turkumi", 4060, { shaded: true }), cell("Majburiy", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Soliq/yig'im kodi", 3000), cell("To'lov turiga mos byudjet daromad kodi", 4060), cell("Majburiy", 2300)] }),
    ]
  }),

  heading("3.2. O'tkazma yozuvlari (qo'sh yozuv — balansli)", HeadingLevel.HEADING_2),
  body("Har bir bajarilgan o'tkazma kamida ikkita yozuvdan iborat bo'ladi: to'lovchi hisobdan chiqim (debet) va oluvchi hisobga kirim (kredit). Agar komissiya undirilsa, qo'shimcha kirim yozuvi (bank daromad hisobiga) qo'shiladi. Quyidagi ma'lumotlar har bir yozuv uchun saqlanadi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 4060, 2300],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3000), hCell("Mazmuni", 4060), hCell("Majburiyligi", 2300)] }),
      new TableRow({ children: [cell("Bog'liq hujjat raqami", 3000), cell("Yozuv tegishli bo'lgan o'tkazma hujjati raqami", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Hisob raqami", 3000, { shaded: true }), cell("Yozuv tegishli bo'lgan hisob", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Yozuv turi", 3000), cell("Chiqim (debet) yoki Kirim (kredit)", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Summa", 3000, { shaded: true }), cell("Yozuv summasi (tegishli valyutada)", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Yozuv sanasi", 3000), cell("Yozuv amalga oshirilgan operatsion kun", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Valyutalash sanasi", 3000, { shaded: true }), cell("Yozuv qoldiqqa ta'sir qiladigan sana", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Eslatma: bir o'tkazma doirasidagi jami chiqim summasi jami kirim summasiga (oluvchi kirimi + komissiya kirimi) teng bo'lishi shart — balans buzilishi mumkin emas.", { italic: true }),

  heading("3.3. O'tkazma holatlari (hayot sikli)", HeadingLevel.HEADING_2),
  body("O'tkazma hujjati o'z umri davomida quyidagi holatlardan o'tadi. Har bir holat o'zgarishi kim va qachon amalga oshirgani bilan birga qayd etiladi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Holat", 2400), hCell("Mazmuni", 6960)] }),
      new TableRow({ children: [cell("Tasdiq kutilmoqda", 2400), cell("Operator hujjatni kiritdi va tasdiqqa yubordi. Maker tahrir qila olmaydi. Checker (boshqa xodim) ko'rib chiqishi kutilmoqda. Hisob qoldig'iga ta'sir qilmagan (mablag' rezervga olinmaydi).", 6960)] }),
      new TableRow({ children: [cell("Bajarilgan", 2400, { shaded: true }), cell("Checker tasdiqladi, qo'sh yozuvli operatsiya amalga oshirildi — to'lovchi hisobdan summa va komissiya yechildi, oluvchi hisobga summa o'tkazildi. Yakuniy holat. Hujjatni o'zgartirib bo'lmaydi.", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Rad etilgan", 2400), cell("Checker hujjatni tasdiqlamadi va sabab ko'rsatib qaytardi. Hisob qoldig'iga ta'sir qilmaydi. Yakuniy holat (yangi hujjat yaratish kerak).", 6960)] }),
      new TableRow({ children: [cell("Bekor qilingan", 2400, { shaded: true }), cell("Hujjat bajarilishidan oldin (Tasdiq kutilmoqda holatida) Maker yoki Supervisor tomonidan bekor qilindi. Hisob qoldig'iga ta'sir qilmaydi. Yakuniy holat.", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Storno", 2400), cell("Allaqachon bajarilgan o'tkazma xato deb topilib, qarshi (teskari) yozuv orqali bekor qilindi. Asl hujjat o'zgarmaydi; storno teskari yozuvi bilan bog'lanadi. Yakuniy holat.", 6960)] }),
    ]
  }),
  spacer(),
  body("Holat o'tish qoidalari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2800, 2800, 3760],
    rows: [
      new TableRow({ children: [hCell("Joriy holat", 2800), hCell("Mumkin keyingi holat", 2800), hCell("Shart", 3760)] }),
      new TableRow({ children: [cell("Tasdiq kutilmoqda", 2800), cell("Bajarilgan", 2800), cell("Checker tasdiqlaydi (Maker ≠ Checker); biznes qoidalar qayta tekshiriladi", 3760)] }),
      new TableRow({ children: [cell("Tasdiq kutilmoqda", 2800, { shaded: true }), cell("Rad etilgan", 2800, { shaded: true }), cell("Checker rad etadi + sabab matni majburiy", 3760, { shaded: true })] }),
      new TableRow({ children: [cell("Tasdiq kutilmoqda", 2800), cell("Bekor qilingan", 2800), cell("Maker/Supervisor bekor qiladi (hali bajarilmagan)", 3760)] }),
      new TableRow({ children: [cell("Bajarilgan", 2800, { shaded: true }), cell("Storno", 2800, { shaded: true }), cell("Faqat Supervisor (Administrator ham); sabab matni majburiy; qarshi yozuv yaratiladi", 3760, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Muhim: Bajarilgan, Rad etilgan, Bekor qilingan va Storno holatlari yakuniy hisoblanadi — ularga qaytib o'zgartirish kiritib bo'lmaydi. Bajarilgan o'tkazmani tuzatishning yagona yo'li — storno.", { italic: true }),
  spacer(200),

  heading("3.4. Provodkalar jurnali (buxgalteriya registri)", HeadingLevel.HEADING_2),
  body("Provodkalar jurnali — modulning markaziy buxgalteriya registri. U barcha buxgalteriya yozuvlarining (provodkalarning) yagona xronologik ro'yxati bo'lib, har bir provodka qo'sh yozuvning bir bo'lagini (ma'lum hisobning debetini yoki kreditini) qayd etadi. Jurnal o'zgartirilmaydi — unga faqat yangi yozuvlar qo'shiladi (to'liq audit izi). Quyida har bir jurnal yozuvi uchun saqlanadigan ma'lumotlar biznes tilida keltirilgan."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 4060, 2300],
    rows: [
      new TableRow({ children: [hCell("Ma'lumot", 3000), hCell("Mazmuni", 4060), hCell("Majburiyligi", 2300)] }),
      new TableRow({ children: [cell("Provodka raqami", 3000), cell("Jurnal yozuvining noyob tartib raqami; tizim avtomatik beradi", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Bog'liq hujjat (referens) raqami", 3000, { shaded: true }), cell("Provodka qaysi o'tkazma hujjatidan kelib chiqqanini ko'rsatuvchi raqam", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Provodka sanasi", 3000), cell("Provodka qayd etilgan operatsion kun", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Valyutalash sanasi", 3000, { shaded: true }), cell("Provodka qoldiqqa ta'sir qiladigan sana (F0 da — bajarilgan operatsion kun)", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Debet hisob", 3000), cell("Chiqim (debet) qilinadigan hisob raqami", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Kredit hisob", 3000, { shaded: true }), cell("Kirim (kredit) qilinadigan hisob raqami", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Summa", 3000), cell("Provodka summasi (tegishli valyutada, 2 kasr aniqligida)", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Valyuta", 3000, { shaded: true }), cell("Provodka valyutasi: UZS (000), USD (840), EUR (978)", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Provodka holati", 3000), cell("Kiritilgan / Tekshirilgan / O'tkazilgan / O'chirilgan / Storno", 4060), cell("Avtomatik", 2300)] }),
      new TableRow({ children: [cell("Operator", 3000, { shaded: true }), cell("Provodkani yaratgan/o'tkazgan xodim nomi", 4060, { shaded: true }), cell("Avtomatik", 2300, { shaded: true })] }),
      new TableRow({ children: [cell("Izoh / maqsad", 3000), cell("Provodka mazmunini tavsiflovchi matn (o'tkazmaning to'lov maqsadidan olinadi)", 4060), cell("Avtomatik", 2300)] }),
    ]
  }),
  spacer(),
  body("Eslatma: Provodkalar jurnali Bosh kitob (core_gl) uchun birlamchi yozuv manbai bo'lib xizmat qiladi — har bir O'tkazilgan provodka core_gl ga buxgalteriya yozuvi sifatida yetkaziladi (8-bo'limga qarang). Jurnaldagi hech bir yozuv o'chirilmaydi yoki tahrirlanmaydi.", { italic: true }),

  heading("3.5. Provodka hayot sikli (holatlari)", HeadingLevel.HEADING_2),
  body("Har bir provodka o'z umri davomida quyidagi holatlardan o'tadi. Faqat \"O'tkazilgan\" holatdagi provodka hisob qoldig'i va aylanmasiga ta'sir qiladi; qolgan holatlar qoldiqqa ta'sir qilmaydi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2400, 6960],
    rows: [
      new TableRow({ children: [hCell("Holat", 2400), hCell("Mazmuni", 6960)] }),
      new TableRow({ children: [cell("Kiritilgan (Введён)", 2400), cell("Provodka kiritildi, ammo hisob qoldig'i va aylanmasiga TA'SIR QILMAYDI (qoralama yozuv). Bu holatdan provodka tekshirishga yoki o'tkazishga yo'naltiriladi yoki o'chiriladi.", 6960)] }),
      new TableRow({ children: [cell("Tekshirilgan (Проверен)", 2400, { shaded: true }), cell("Provodka tekshiruvdan o'tdi (Maker-Checker bo'yicha; ixtiyoriy oraliq holat). Qoldiqqa hali ta'sir qilmaydi. Bu holatdan provodka o'tkaziladi yoki o'chiriladi.", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("O'tkazilgan / Bajarilgan (Проведён)", 2400), cell("Provodka kitobga rasman o'tkazildi — hisob qoldig'i va aylanmasiga TA'SIR QILADI, pul haqiqatan harakatlanadi. Ijobiy-yakuniy holat: o'chirib bo'lmaydi, faqat storno orqali qaytariladi.", 6960)] }),
      new TableRow({ children: [cell("O'chirilgan (Удалён)", 2400, { shaded: true }), cell("Provodka faqat Kiritilgan yoki Tekshirilgan holatdan o'chiriladi (qoldiqqa ta'sir qilmasdan). O'tkazilgan provodkani o'chirib BO'LMAYDI. Yakuniy holat (izlanuvchanlik uchun fizik o'chirilmaydi).", 6960, { shaded: true })] }),
      new TableRow({ children: [cell("Storno (Сторнирован)", 2400), cell("O'tkazilgan provodka teskari (qarshi) yozuv orqali bekor qilindi; qoldiqlar dastlabki holatga qaytdi. Asl provodka o'zgarmaydi — qarshi yozuv bilan bog'lanadi. Yakuniy holat.", 6960)] }),
    ]
  }),
  spacer(),
  body("Provodka holat o'tish qoidalari:", { bold: true }),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2800, 2800, 3760],
    rows: [
      new TableRow({ children: [hCell("Joriy holat", 2800), hCell("Mumkin keyingi holat", 2800), hCell("Shart", 3760)] }),
      new TableRow({ children: [cell("Kiritilgan", 2800), cell("Tekshirilgan", 2800), cell("Tekshiruvga yuborilganda (Maker-Checker; ixtiyoriy)", 3760)] }),
      new TableRow({ children: [cell("Kiritilgan", 2800, { shaded: true }), cell("O'tkazilgan", 2800, { shaded: true }), cell("O'tkazma bajarilganda (qoldiqqa ta'sir qiladi)", 3760, { shaded: true })] }),
      new TableRow({ children: [cell("Kiritilgan", 2800), cell("O'chirilgan", 2800), cell("O'tkazma rad/bekor qilinganda (qoldiqqa ta'sir yo'q)", 3760)] }),
      new TableRow({ children: [cell("Tekshirilgan", 2800, { shaded: true }), cell("O'tkazilgan", 2800, { shaded: true }), cell("Tasdiqlanib o'tkazilganda (qoldiqqa ta'sir qiladi)", 3760, { shaded: true })] }),
      new TableRow({ children: [cell("Tekshirilgan", 2800), cell("O'chirilgan", 2800), cell("Tekshiruvdan keyin bekor qilinganda (qoldiqqa ta'sir yo'q)", 3760)] }),
      new TableRow({ children: [cell("O'tkazilgan", 2800, { shaded: true }), cell("Storno", 2800, { shaded: true }), cell("Faqat qarshi yozuv orqali (o'chirib bo'lmaydi); sabab majburiy", 3760, { shaded: true })] }),
    ]
  }),
  spacer(),
  body("Muhim: O'tkazilgan provodkani o'chirib bo'lmaydi — uni faqat storno (qarshi yozuv) orqali qaytarish mumkin. O'chirilgan va Storno holatlari yakuniy hisoblanadi.", { italic: true }),

  heading("3.6. Hujjat va provodka qatlamlarining bog'lanishi", HeadingLevel.HEADING_2),
  body("Pul o'tkazmasi ikki qatlamda yashaydi: hujjat darajasi (o'tkazma hujjatining holati — operator/supervisor ish jarayoni) va buxgalteriya darajasi (o'tkazma hosil qiladigan provodkalarning holati). O'tkazma HUJJATI provodkalarni HOSIL QILADI: hujjat holati o'zgarganda unga bog'liq provodkalar holati ham izchil ravishda o'zgaradi. Quyidagi jadval ikki qatlam o'rtasidagi muvofiqlikni ko'rsatadi."),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 3000, 3360],
    rows: [
      new TableRow({ children: [hCell("O'tkazma (hujjat) holati", 3000), hCell("Provodkalar holati", 3000), hCell("Qoldiqqa ta'siri", 3360)] }),
      new TableRow({ children: [cell("Tasdiq kutilmoqda", 3000), cell("Kiritilgan (Введён)", 3000), cell("Yo'q — qoralama, pul harakatlanmaydi", 3360)] }),
      new TableRow({ children: [cell("Bajarilgan", 3000, { shaded: true }), cell("O'tkazilgan (Проведён)", 3000, { shaded: true }), cell("Bor — qoldiq haqiqatan harakatlanadi", 3360, { shaded: true })] }),
      new TableRow({ children: [cell("Rad etilgan", 3000), cell("O'chirilgan (Удалён)", 3000), cell("Yo'q — yozuv o'chiriladi, qoldiq o'zgarmaydi", 3360)] }),
      new TableRow({ children: [cell("Bekor qilingan", 3000, { shaded: true }), cell("O'chirilgan (Удалён)", 3000, { shaded: true }), cell("Yo'q — yozuv o'chiriladi, qoldiq o'zgarmaydi", 3360, { shaded: true })] }),
      new TableRow({ children: [cell("Storno", 3000), cell("Storno (Сторнирован) + qarshi yozuv", 3000), cell("Bor — qarshi yozuv qoldiqni tiklaydi", 3360)] }),
    ]
  }),
  spacer(),
  body("Xulosa: ikki qatlam doimo izchil bo'lishi shart — hujjat \"Bajarilgan\" bo'lmaguncha provodkalar \"O'tkazilgan\" bo'lmaydi va qoldiq harakatlanmaydi; hujjat \"Storno\" qilinganda provodkalar ham qarshi yozuv bilan teskari yo'naltiriladi. Bu izchillik buzilishi mumkin emas.", { italic: true }),
  spacer(200),
];

// ===== 4. BIZNES QOIDALAR =====
const QCOLS = [900, 5760, 1350, 1350];
function brRow(id, rule, importance, type, shaded) {
  return new TableRow({ children: [
    cell(id, QCOLS[0], { shaded }),
    cell(rule, QCOLS[1], { shaded }),
    cell(importance, QCOLS[2], { center: true, shaded }),
    cell(type, QCOLS[3], { center: true, shaded })
  ]});
}
function brHeader() {
  return new TableRow({ children: [hCell("ID", QCOLS[0]), hCell("Qoida", QCOLS[1]), hCell("Muhimlik", QCOLS[2]), hCell("Tur", QCOLS[3])] });
}

const section4 = [
  heading("4. Biznes qoidalar", HeadingLevel.HEADING_1),

  heading("4.1. To'lovchi hisob va mablag' nazorati qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-001", "To'lovchi hisob faqat Tasdiqlangan (faol) holatda bo'lishi shart. Bloklangan, Yopilgan yoki Vaqtincha yopilgan hisobdan o'tkazma qilish qat'iyan taqiqlanadi.", "Yuqori", "Ikkala", false),
      brRow("BR-002", "O'tkazma summasi va komissiya yig'indisi to'lovchi hisobdagi mavjud qoldiqdan (minimal qoldiq chegarasini hisobga olgan holda) oshmasligi shart: (summa + komissiya) qoldiqdan oshmasin. Qoldiqdan ortiq sarflash (overdraft) taqiqlanadi.", "Yuqori", "Ikkala", true),
      brRow("BR-003", "O'tkazma summasi noldan katta bo'lishi shart. Nol yoki manfiy summali o'tkazma yaratib bo'lmaydi.", "Yuqori", "Ikkala", false),
      brRow("BR-004", "To'lovchi va oluvchi bir xil hisob raqami bo'lishi mumkin emas (o'z-o'ziga o'tkazma taqiqlanadi). Bir mijozning ikki har xil hisobi o'rtasidagi o'tkazma esa ruxsat etiladi.", "Yuqori", "Ikkala", true),
      brRow("BR-005", "Vaqtincha yopilgan hisobga kirim (oluvchi sifatida) ruxsat etilishi mumkin, ammo undan chiqim (to'lovchi sifatida) taqiqlanadi.", "Yuqori", "Ikkala", false),
    ]
  }),

  heading("4.2. Valyuta, summa va komissiya qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-006", "To'lovchi va oluvchi hisob valyutalari bir xil bo'lishi shart. Boshqa valyutadagi hisoblar orasida o'tkazma (konvertatsiya/kurs bilan) F0 fazada qo'llab-quvvatlanmaydi — keyingi fazaga rejalashtirilgan.", "Yuqori", "Ikkala", false),
      brRow("BR-007", "Barcha pul summalari tegishli valyutada (UZS/USD/EUR), 2 kasr aniqligida saqlanadi va ko'rsatiladi. Yaxlitlash xatosi yuzaga kelmasligi kerak.", "Yuqori", "Ikkala", true),
      brRow("BR-008", "Komissiya tarifi (foiz yoki qat'iy summa, o'tkazma turi/summa kesimida) Administrator tomonidan sozlanadi; standart qiymatlar joriy etish bosqichida belgilanadi. Ichki o'tkazmada komissiya 0 bo'lishi mumkin.", "O'rta", "Ikkala", false),
      brRow("BR-009", "Komissiya to'lovchi hisobidan, o'tkazma summasidan tashqari (qo'shimcha) ushlanadi. To'lovchida summa va komissiya yig'indisi yetarli bo'lishi shart.", "Yuqori", "Ikkala", true),
      brRow("BR-010", "Bir mijozning o'z hisoblari orasidagi o'tkazmada komissiya undirilmaydi (0).", "O'rta", "Ikkala", false),
    ]
  }),

  heading("4.3. Qo'sh yozuv va balans qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-011", "Har bir bajarilgan o'tkazma qo'sh yozuv tamoyiliga amal qiladi: to'lovchi hisobdan chiqim, oluvchi hisobga kirim (va komissiya bo'lsa, bank daromadiga qo'shimcha kirim). Jami chiqim summasi jami kirim summasiga teng bo'lishi shart.", "Yuqori", "Tizim", false),
      brRow("BR-012", "O'tkazma bajarilishi bir butun amal bo'lishi shart: chiqim va kirim yozuvlari faqat birgalikda amalga oshadi — yo to'liq bajariladi, yo umuman bajarilmaydi (qisman bajarilish yo'q).", "Yuqori", "Tizim", true),
      brRow("BR-013", "Bajarilgan o'tkazmaning qoldiqqa ta'siri valyutalash sanasida hisobga olinadi.", "Yuqori", "Tizim", false),
    ]
  }),

  heading("4.4. Maker-Checker va tasdiqlash qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-014", "Maker-Checker tamoyili: o'tkazmani bir xodim (Maker) yaratadi, boshqa xodim (Checker) tasdiqlaydi. Xodim o'zi yaratgan o'tkazmani o'zi tasdiqlay olmaydi (Maker ≠ Checker).", "Yuqori", "Ikkala", false),
      brRow("BR-015", "O'tkazma faqat \"Tasdiq kutilmoqda\" holatida tasdiqlanishi mumkin. Tasdiqlash atomik — ayni payt barcha biznes qoidalar (hisob holati, qoldiq, valyuta mosligi) qayta tekshiriladi va qoldiq darhol yechiladi; oldindan rezerv qilinmaydi.", "Yuqori", "Ikkala", true),
      brRow("BR-016", "O'tkazmani rad etish, bekor qilish yoki storno qilishda sabab matni majburiy kiritilishi shart.", "O'rta", "Ikkala", false),
    ]
  }),

  heading("4.5. Limit va AML (monitoring) qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-017", "Bir martalik o'tkazma summasi belgilangan bir martalik limitdan oshmasligi kerak. Limitlar Administrator tomonidan rol/valyuta kesimida sozlanadi. Oshgan taqdirda o'tkazma to'xtatiladi va Supervisor tasdig'i talab qilinadi.", "Yuqori", "Ikkala", false),
      brRow("BR-018", "To'lovchi hisobning bir operatsion kundagi jami chiqim summasi kunlik limitdan oshmasligi kerak. Oshgan taqdirda operatsiya to'xtatiladi va Supervisor tasdig'i talab qilinadi.", "Yuqori", "Ikkala", true),
      brRow("BR-019", "Belgilangan chegaradan katta summadagi o'tkazmalar AML nazoratidan o'tkaziladi (qo'shimcha tasdiqlash va monitoring uchun belgilanadi). AML chegarasi O'zbekiston qonunchiligiga muvofiq belgilanadi.", "Yuqori", "Ikkala", false),
    ]
  }),

  heading("4.6. O'zgartirish, storno va qaytarib bo'lmaslik qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-020", "Bajarilgan o'tkazmani tahrirlash yoki o'chirish mumkin emas. Xatoni tuzatishning yagona yo'li — storno (qarshi yozuv) orqali teskari operatsiya yaratish.", "Yuqori", "Ikkala", false),
      brRow("BR-021", "Storno faqat Supervisor (yoki Administrator) tomonidan, sabab ko'rsatilgan holda amalga oshiriladi. Storno asl hujjatni o'zgartirmaydi — alohida qarshi yozuv sifatida yoziladi va asl hujjatga bog'lanadi. Storno'da ushlangan komissiya ham to'liq qaytariladi.", "Yuqori", "Ikkala", true),
      brRow("BR-022", "Tasdiq kutilmoqda holatidagi o'tkazma fizik o'chirilmaydi — \"Bekor qilingan\" holatga o'tkaziladi (izlanuvchanlik). Rad etilgan, Bekor qilingan va Storno qilingan o'tkazmalar yakuniy holatda bo'ladi va qayta faollashtirib bo'lmaydi.", "Yuqori", "Ikkala", false),
    ]
  }),

  heading("4.7. Operatsion kun va valyutalash sanasi qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-023", "O'tkazmalar faqat ochiq operatsion kun doirasida bajariladi. Operatsion kunni ochish/yopish core_gl/core_adm mas'uliyatida; core_ac ochiq kun ma'lumotidan foydalanadi.", "Yuqori", "Ikkala", false),
      brRow("BR-024", "F0 fazada valyutalash sanasi joriy (bajarilgan) operatsion kunga teng bo'ladi. Orqaga sanali o'tkazma taqiqlanadi; kelajak sanali (rejalashtirilgan) o'tkazma keyingi fazaga rejalashtirilgan.", "O'rta", "Ikkala", true),
      brRow("BR-025", "Har bir o'tkazma operatsiyasi (yaratish, tasdiqlash, rad etish, bekor qilish, storno) audit logga yoziladi: kim, qachon, nima qilgan, sabab. Audit logni o'chirish yoki o'zgartirish mumkin emas.", "Yuqori", "Ikkala", false),
    ]
  }),

  heading("4.8. O'tkazma turlari bo'yicha qamrov (fazalar)", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-026", "Ichki o'tkazma (bank ichidagi hisoblar orasida) F0 yadro doirasida to'liq qo'llab-quvvatlanadi: mijozdan mijozga hamda mijozning o'z hisoblari orasida.", "Yuqori", "Ikkala", false),
      brRow("BR-027", "Banklararo o'tkazma (Markaziy bank kliring orqali, MFO bo'yicha) keyingi fazaga rejalashtirilgan. Bunda oluvchi banki (MFO) va to'lov maqsadi kodi majburiy bo'ladi, Markaziy bank to'lov tizimi bilan integratsiya talab qilinadi.", "O'rta", "Ikkala", true),
      brRow("BR-028", "Byudjet to'lovlari (soliq/yig'imlar, yagona g'aznachilik hisobiga) keyingi fazaga rejalashtirilgan. Bunda INN/PINFL va byudjet daromad kodi majburiy bo'ladi.", "O'rta", "Ikkala", false),
    ]
  }),

  heading("4.9. Provodka va provodkalar jurnali qoidalari", HeadingLevel.HEADING_2),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: QCOLS,
    rows: [
      brHeader(),
      brRow("BR-029", "Faqat \"O'tkazilgan\" (Проведён) holatdagi provodka hisob qoldig'i va aylanmasiga ta'sir qiladi. \"Kiritilgan\" holatdagi provodka (qoralama) qoldiqqa ta'sir qilmaydi.", "Yuqori", "Tizim", false),
      brRow("BR-030", "Har bir provodkalar to'plamida (bir o'tkazma doirasida) jami debet summasi jami kredit summasiga teng bo'lishi shart — buxgalteriya balansi buzilmasligi kerak.", "Yuqori", "Tizim", true),
      brRow("BR-031", "\"O'tkazilgan\" provodkani o'chirib bo'lmaydi. Uni tuzatishning yagona yo'li — storno (qarshi yozuv) yaratish. Provodka faqat \"Kiritilgan\" yoki \"Tekshirilgan\" holatdan o'chirilishi mumkin.", "Yuqori", "Tizim", false),
      brRow("BR-032", "Provodkalar jurnali o'zgartirilmaydi: mavjud yozuvni tahrirlash yoki fizik o'chirish taqiqlanadi. Jurnalga faqat yangi yozuv qo'shiladi (audit izi). To'g'rilash faqat storno yoki tuzatuvchi yozuv orqali amalga oshadi.", "Yuqori", "Tizim", true),
      brRow("BR-033", "Provodka holati o'tkazma (hujjat) holatiga izchil bog'liq bo'lishi shart: Tasdiq kutilmoqda → Kiritilgan; Bajarilgan → O'tkazilgan; Rad etilgan/Bekor qilingan → O'chirilgan; Storno → Storno (qarshi yozuv). Ikki qatlam o'rtasidagi nomuvofiqlik bo'lishi mumkin emas.", "Yuqori", "Tizim", false),
      brRow("BR-034", "Har bir provodka bog'liq o'tkazma hujjati (referens) raqamiga ega bo'lishi shart — jurnaldan asl o'tkazmaga, o'tkazmadan jurnal yozuvlariga izlanish mumkin bo'lishi kerak.", "O'rta", "Tizim", true),
    ]
  }),
  spacer(200),
];

// ===== 5. FOYDALANUVCHI ROLLARI =====
const section5 = [
  heading("5. Foydalanuvchi rollari va huquqlar", HeadingLevel.HEADING_1),
  body("Pul o'tkazmalari moduli bilan ishlaydigan foydalanuvchi rollari va ularning huquqlari quyida keltirilgan. Modul Maker-Checker tamoyiliga asoslanadi: o'tkazmani bir xodim yaratadi (Maker), boshqa xodim tasdiqlaydi (Checker). Bir kishi o'zi yaratgan o'tkazmani o'zi tasdiqlay olmaydi (Maker ≠ Checker)."),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1800, 3780, 3780],
    rows: [
      new TableRow({ children: [hCell("Rol", 1800), hCell("Nima qila oladi", 3780), hCell("Cheklovlar", 3780)] }),
      new TableRow({ children: [
        cell("Operator (Maker)", 1800),
        multiCell(["Yangi ichki o'tkazma yaratish", "To'lovchi/oluvchi hisobni tanlash, summa va to'lov maqsadini kiritish", "O'z o'tkazmasini bekor qilish (tasdiqdan oldin)", "Hisoblar va qoldiqlarni qidirish/ko'rish"], 3780),
        multiCell(["O'z o'tkazmasini tasdiqlay olmaydi", "Tasdiqlangan o'tkazmani storno qila olmaydi", "Boshqa operatorning o'tkazmasini tahrirlay olmaydi"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Supervisor (Checker)", 1800, { shaded: true }),
        multiCell(["Operator huquqlari +", "O'tkazmani tasdiqlash yoki rad etish (sabab bilan)", "Ommaviy tasdiqlash/rad etish", "Limitdan oshgan o'tkazmalarni tasdiqlash", "Bajarilgan o'tkazmani storno qilish"], 3780, { shaded: true }),
        multiCell(["O'zi yaratgan o'tkazmani tasdiqlay olmaydi", "Tizim sozlamalari (limitlar, taqvim) ni o'zgartira olmaydi"], 3780, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("Administrator", 1800),
        multiCell(["Barcha huquqlar", "Tizim sozlamalari (kunlik limitlar, to'lov maqsadi kodlari, taqvim)", "O'tkazma turlarini yoqish/o'chirish (faza bo'yicha)", "Storno (barcha huquqlar doirasida)"], 3780),
        multiCell(["Audit logni o'chira yoki o'zgartira olmaydi", "Bajarilgan o'tkazma yozuvlarini qo'lda o'zgartira olmaydi (faqat storno orqali)"], 3780)
      ]}),
      new TableRow({ children: [
        cell("Auditor", 1800, { shaded: true }),
        multiCell(["O'tkazmalarni ko'rish (faqat o'qish)", "Barcha hisobotlarni ko'rish va yuklab olish", "Hisob ko'chirmasini ko'rish", "Audit loglarni ko'rish"], 3780, { shaded: true }),
        multiCell(["Hech qanday o'zgartirish qila olmaydi", "O'tkazma yarata, tasdiqlay yoki storno qila olmaydi"], 3780, { shaded: true })
      ]}),
    ]
  }),
  spacer(),
  body("Eslatma: Foydalanuvchi faqat o'ziga biriktirilgan filial (MFO) doirasidagi hisoblar bilan o'tkazma bajara oladi. Rollar, tasdiqlash huquqi va limit chegaralari core_adm modulida Administrator tomonidan belgilanadi. Auditor — faqat ko'rish huquqiga ega rol bo'lib, joriy etishda core_adm da aniqlanadi.", { italic: true }),
  spacer(200),
];

// ===== 6. INTERFEYS TALABLARI =====
const section6 = [
  heading("6. Interfeys talablari", HeadingLevel.HEADING_1),
  body("Quyida foydalanuvchi ko'rishi va ishlatishi kerak bo'lgan asosiy ekranlar biznes darajasida tavsiflangan. Texnik amalga oshirish TZ-003 da yoritiladi."),

  heading("6.1. SCR-001: O'tkazma yaratish formasi", HeadingLevel.HEADING_2),
  body("Maqsad: yangi pul o'tkazmasini tayyorlash (F0 fazada — ichki o'tkazma)."),
  body("Ekran elementlari:", { bold: true }),
  bullet("O'tkazma turini tanlash — Ichki (bank ichida) [F0]; Banklararo va Byudjet ko'rinadi, lekin keyingi fazada yoqiladi"),
  bullet("To'lovchi (chiqim) hisobini tanlash bloki — hisob raqami, CIF raqam yoki mijoz nomi bo'yicha qidirish; tanlangach hisob egasi nomi, valyutasi va joriy qoldiq ko'rsatiladi"),
  bullet("Oluvchi (kirim) hisobini tanlash bloki — bank ichidagi hisob uchun qidirish (raqam/CIF/nom); tanlangach oluvchi nomi va valyutasi ko'rsatiladi"),
  bullet("Summa maydoni — tegishli valyutada (2 kasr); summa kiritilganda qoldiq yetarliligini darhol vizual ko'rsatadi"),
  bullet("Valyuta — to'lovchi hisob valyutasidan avtomatik olinadi; F0 da to'lovchi va oluvchi valyutalari bir xil bo'lishi shart (konvertatsiya keyingi fazada)"),
  bullet("To'lov maqsadi — majburiy matn maydoni"),
  bullet("Hujjat raqami / sanasi — avtomatik beriladi"),
  bullet("Darhol tekshiruv — hisob faol emas, qoldiq yetarli emas, valyuta mos kelmasa yoki limit oshsa o'sha zahoti xato/ogohlantirish chiqaradi"),
  bullet("\"Saqlash va tasdiqqa yuborish\" va \"Bekor qilish\" tugmalari — saqlangach o'tkazma \"Tasdiq kutilmoqda\" holatiga tushadi"),

  heading("6.2. SCR-002: Tasdiqlash navbati (Checker)", HeadingLevel.HEADING_2),
  body("Maqsad: Supervisorga tasdiqlash kutayotgan o'tkazmalarni ko'rsatish va qaror qabul qilish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("\"Tasdiq kutilmoqda\" holatidagi o'tkazmalar ro'yxati — sana, to'lovchi, oluvchi, summa, valyuta, to'lov maqsadi, yaratgan operator"),
  bullet("Filtrlar — sana oralig'i, summa oralig'i, valyuta, yaratgan operator"),
  bullet("Har bir qatorda \"Ko'rish\", \"Tasdiqlash\" va \"Rad etish\" amallari"),
  bullet("Rad etishda sabab matni majburiy kiritiladi"),
  bullet("O'zi yaratgan o'tkazmalar ro'yxatda ko'rinadi, lekin tasdiqlash tugmasi faolsiz (Maker ≠ Checker)"),
  bullet("Ommaviy tanlash — bir nechta o'tkazmani belgilab birdaniga tasdiqlash yoki rad etish"),

  heading("6.3. SCR-003: O'tkazmalar ro'yxati va filtr", HeadingLevel.HEADING_2),
  body("Maqsad: barcha o'tkazmalarni ko'rsatish, qidirish va filtrlash."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Qidiruv paneli — hisob raqami, hujjat raqami yoki mijoz nomi bo'yicha"),
  bullet("Filtrlar — holat (Tasdiq kutilmoqda/Bajarilgan/Rad etilgan/Bekor qilingan/Storno), o'tkazma turi, valyuta, sana oralig'i, summa oralig'i"),
  bullet("Natijalar jadvali — sana, hujjat raqami, to'lovchi, oluvchi, summa, valyuta, holat, o'tkazma turi"),
  bullet("Holat rangli yorliq bilan ajratiladi"),
  bullet("Sahifalash (har sahifada 20 yozuv), saralash va ro'yxatni jadval ko'rinishida yuklab olish"),
  bullet("Har bir qatorda \"Detal / chek\" havolasi"),

  heading("6.4. SCR-004: O'tkazma detali va chek (kvitansiya)", HeadingLevel.HEADING_2),
  body("Maqsad: bitta o'tkazma haqida to'liq ma'lumot ko'rsatish va chek chop etish."),
  body("Ekran elementlari:", { bold: true }),
  bullet("O'tkazma sarlavhasi — hujjat raqami, sana/vaqt, holat"),
  bullet("To'lovchi bloki — hisob raqami, mijoz nomi, valyuta"),
  bullet("Oluvchi bloki — hisob raqami, mijoz nomi, valyuta (banklararo uchun bank/MFO ma'lumoti)"),
  bullet("Summa, valyuta, komissiya, to'lov maqsadi"),
  bullet("Maker-Checker izi — kim yaratgan/qachon, kim tasdiqlagan yoki rad etgan/qachon, rad/storno sababi"),
  bullet("\"Chek (kvitansiya) chop etish\" tugmasi — bosma/PDF ko'rinishida"),
  bullet("Supervisor/Admin uchun \"Storno (qaytarish)\" tugmasi (faqat bajarilgan o'tkazma uchun, sabab bilan)"),

  heading("6.5. SCR-005: Ommaviy tasdiqlash", HeadingLevel.HEADING_2),
  body("Maqsad: ko'p o'tkazmalarni bir amalda tasdiqlash yoki rad etish (Supervisor uchun)."),
  body("Ekran elementlari:", { bold: true }),
  bullet("Tasdiq kutayotgan o'tkazmalar ro'yxati, har qatorda tanlash katakchasi"),
  bullet("Tanlangan o'tkazmalar soni va umumiy summasi ko'rsatkichi"),
  bullet("\"Tanlanganlarni tasdiqlash\" va \"Tanlanganlarni rad etish\" (rad sababi bilan) tugmalari"),
  bullet("Yakunda har bir o'tkazma natijasi (muvaffaqiyatli/xato) hisoboti ko'rsatiladi"),
  spacer(),
  body("Qulaylik talablari (umumiy): hisob tanlashda tezkor qidiruv (raqam/CIF/nom), tanlangan hisob qoldig'ining darhol ko'rsatilishi, summa formatlash (mingliklar ajratgich), valyuta belgisi, klaviatura bilan navigatsiya, qoldiq yetmaganda aniq va tushunarli xato xabari.", { italic: true }),
  spacer(200),
];

// ===== 7. HISOBOTLAR =====
const section7 = [
  heading("7. Hisobotlar", HeadingLevel.HEADING_1),
  body("Pul o'tkazmalari moduli quyidagi hisobotlarni taqdim etishi kerak:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1000, 2400, 3560, 2400],
    rows: [
      new TableRow({ children: [hCell("ID", 1000), hCell("Nomi", 2400), hCell("Tavsif", 3560), hCell("Chastotasi", 2400)] }),
      new TableRow({ children: [
        cell("RPT-001", 1000), cell("O'tkazmalar tarixi", 2400),
        cell("Barcha o'tkazmalar sana, hisob va holat bo'yicha filtr/saralash bilan; to'lovchi, oluvchi, summa, valyuta, to'lov maqsadi, holat", 3560), cell("Talab bo'yicha", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-002", 1000, { shaded: true }), cell("Hisob ko'chirmasi (vypiska)", 2400, { shaded: true }),
        cell("Tanlangan hisob va davr bo'yicha kirim, chiqim va har operatsiyadan keyingi qoldiq; boshlang'ich va yakuniy qoldiq ko'rsatiladi", 3560, { shaded: true }),
        cell("Talab bo'yicha / Kunlik", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-003", 1000), cell("Kunlik aylanma", 2400),
        cell("Tanlangan kun uchun jami chiqim aylanma, jami kirim aylanma, o'tkazmalar soni; valyuta bo'yicha taqsimlangan", 3560), cell("Kunlik", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-004", 1000, { shaded: true }), cell("Rad etilgan o'tkazmalar", 2400, { shaded: true }),
        cell("Tanlangan davrda rad etilgan o'tkazmalar, har biri uchun rad sababi, yaratgan operator va rad etgan supervisor", 3560, { shaded: true }),
        cell("Kunlik / Talab bo'yicha", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-005", 1000), cell("Storno hisoboti", 2400),
        cell("Tanlangan davrda storno qilingan bajarilgan o'tkazmalar, storno sababi va mas'ul xodim", 3560), cell("Oylik / Talab bo'yicha", 2400)
      ]}),
      new TableRow({ children: [
        cell("RPT-006", 1000, { shaded: true }), cell("Provodkalar jurnali hisoboti", 2400, { shaded: true }),
        cell("Tanlangan davr, hisob va holat (Kiritilgan/Tekshirilgan/O'tkazilgan/O'chirilgan/Storno) bo'yicha provodkalar; har bir yozuv uchun debet, kredit va oraliq qoldiq, jami debet/kredit aylanma ko'rsatiladi", 3560, { shaded: true }),
        cell("Kunlik / Talab bo'yicha", 2400, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("RPT-007", 1000), cell("Banklararo reestr (keyingi faza)", 2400),
        cell("Markaziy bank kliring orqali yuborilgan/qabul qilingan banklararo o'tkazmalar, MFO bo'yicha guruhlangan", 3560), cell("Kunlik", 2400)
      ]}),
    ]
  }),
  spacer(),
  body("Eslatma: Hisob ko'chirmasi (RPT-002) da chiqim, kirim va qoldiq ustunlari muvozanatda bo'lishi shart — yakuniy qoldiq = boshlang'ich qoldiq + jami kirim − jami chiqim.", { italic: true }),
  body("Eslatma: Provodkalar jurnali hisobotida (RPT-006) faqat \"O'tkazilgan\" provodkalar qoldiqqa ta'sir qiladi; jami debet aylanma jami kredit aylanmaga teng bo'lishi (balans) tekshiriladi.", { italic: true }),
  spacer(200),
];

// ===== 8. INTEGRATSIYA TALABLARI =====
const section8 = [
  heading("8. Integratsiya talablari", HeadingLevel.HEADING_1),
  body("Pul o'tkazmalari moduli (core_ac) MARS tizimining boshqa modullari va tashqi tizimlar bilan quyidagicha o'zaro aloqada bo'ladi:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1700, 1700, 3280, 2680],
    rows: [
      new TableRow({ children: [
        hCell("Modul / Tizim", 1700), hCell("Yo'nalish", 1700),
        hCell("Qanday ma'lumot almashiladi", 3280), hCell("Qachon kerak", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_acc", 1700), cell("TRX ↔ ACC", 1700),
        cell("Hisob holati va valyutasini tekshirish; to'lovchi qoldig'idan chiqim, oluvchi qoldig'iga kirim; qoldiq va limit tekshiruvi", 3280), cell("Yaratishda (tekshiruv) va tasdiqlanganda (qoldiqni yangilash)", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_gl", 1700, { shaded: true }), cell("TRX → GL", 1700, { shaded: true }),
        cell("Provodkalar jurnalidagi har bir \"O'tkazilgan\" provodka core_gl (Bosh kitob) ga buxgalteriya yozuvi sifatida yetkaziladi (chiqim/kirim, balans hisoblari kodi bo'yicha). Jurnal — Bosh kitob uchun birlamchi yozuv manbai.", 3280, { shaded: true }),
        cell("Har o'tkazma tasdiqlanganda (provodka O'tkazilgan holatga o'tganda)", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("core_curr", 1700), cell("CURR → TRX", 1700),
        cell("Valyuta kurslari va konvertatsiya qoidalari", 3280), cell("Turli valyutali o'tkazmada (keyingi faza)", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_cif", 1700, { shaded: true }), cell("CIF → TRX", 1700, { shaded: true }),
        cell("Mijoz nomi, holati; hisob egasi ma'lumotlari", 3280, { shaded: true }),
        cell("Hisob/mijoz qidirishda va chek/ko'chirma chop etishda", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("Markaziy bank to'lov tizimi (keyingi faza)", 1700), cell("TRX ↔ MB", 1700),
        cell("Banklararo o'tkazmalar MFO bo'yicha kliring orqali yuboriladi/qabul qilinadi; to'lov maqsadi, summa, oluvchi rekvizitlari", 3280), cell("Boshqa bankka o'tkazmada (keyingi faza)", 2680)
      ]}),
      new TableRow({ children: [
        cell("Byudjet / Yagona g'aznachilik (keyingi faza)", 1700, { shaded: true }), cell("TRX → G'aznachilik", 1700, { shaded: true }),
        cell("Soliq va byudjet to'lovlari yagona g'aznachilik hisobiga, byudjet rekvizitlari bilan", 3280, { shaded: true }),
        cell("Byudjet to'lovlarini bajarishda (keyingi faza)", 2680, { shaded: true })
      ]}),
      new TableRow({ children: [
        cell("AML monitoring (keyingi faza)", 1700), cell("TRX ↔ AML", 1700),
        cell("Shubhali/yuqori summali o'tkazmalarni tekshirish, kontragent nazorati", 3280), cell("Tasdiqlashdan oldin (keyingi faza)", 2680)
      ]}),
      new TableRow({ children: [
        cell("core_adm", 1700, { shaded: true }), cell("ADM → TRX", 1700, { shaded: true }),
        cell("Foydalanuvchi, rol, filial (MFO) va limit sozlamalari", 3280, { shaded: true }),
        cell("Maker/Checker aniqlash, huquq va limit tekshiruvi, audit logda", 2680, { shaded: true })
      ]}),
    ]
  }),
  spacer(),
  body("Eng muhim shart: har bir tasdiqlangan o'tkazmada provodkalar jurnaliga \"O'tkazilgan\" provodkalarning yozilishi, core_acc dagi qoldiq yangilanishi va core_gl dagi buxgalteriya yozuvi bir butun amal sifatida bajarilishi shart — yo to'liq bajariladi, yo umuman bajarilmaydi.", { italic: true }),
  body("Provodkalar jurnali — core_ac va core_gl o'rtasidagi asosiy bog'lovchi halqa: o'tkazma bajarilganda jurnalga \"O'tkazilgan\" provodka yoziladi, ushbu provodka esa Bosh kitob (core_gl) ga birlamchi buxgalteriya yozuvi sifatida o'tadi. Jurnal o'zgartirilmaydi, shu sababli core_gl bilan to'liq izchillik va izlanuvchanlik ta'minlanadi.", { italic: true }),
  spacer(200),
];

// ===== 9. QABUL QILISH MEZONLARI =====
const ACOLS = [700, 5960, 1350, 1350];
function acRow(num, crit, prio, shaded) {
  return new TableRow({ children: [
    cell(num, ACOLS[0], { center: true, shaded }),
    cell(crit, ACOLS[1], { shaded }),
    cell(prio, ACOLS[2], { center: true, shaded }),
    cell("Kutilmoqda", ACOLS[3], { center: true, shaded })
  ]});
}

const section9 = [
  heading("9. Qabul qilish mezonlari", HeadingLevel.HEADING_1),
  body("Modul quyidagi mezonlarga javob berganida qabul qilingan hisoblanadi:"),
  spacer(),
  new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: ACOLS,
    rows: [
      new TableRow({ children: [hCell("#", ACOLS[0]), hCell("Mezon", ACOLS[1]), hCell("Ustuvorlik", ACOLS[2]), hCell("Holat", ACOLS[3])] }),
      acRow("1", "Operator faol to'lovchi hisobdan yetarli qoldiq mavjud bo'lganda faol oluvchi hisobga ichki o'tkazma yarata oladi", "Yuqori", false),
      acRow("2", "Maker-Checker ishlaydi: Operator yaratadi, Supervisor tasdiqlaydi; o'tkazmani yaratgan kishi uni tasdiqlay olmaydi", "Yuqori", true),
      acRow("3", "Checker tasdiqlagach to'lovchi hisob qoldig'i o'tkazma summasiga kamayadi, oluvchi hisob qoldig'i o'sha summaga oshadi", "Yuqori", false),
      acRow("4", "Jami chiqim summasi jami kirim summasiga teng bo'ladi (komissiya bilan birga) — balans buzilmaydi", "Yuqori", true),
      acRow("5", "Qoldiq yetarli bo'lmaganda o'tkazma yaratish/tasdiqlash rad etiladi (overdraft taqiqlanadi), aniq xato xabari ko'rsatiladi", "Yuqori", false),
      acRow("6", "Faol bo'lmagan (bloklangan/yopiq/vaqtincha yopilgan) to'lovchi yoki oluvchi hisobga o'tkazma bajarib bo'lmaydi", "Yuqori", true),
      acRow("7", "Tasdiq kutilayotgan o'tkazma qoldiqqa ta'sir qilmaydi — qoldiq faqat tasdiqdan keyin o'zgaradi (oldindan rezerv qilinmaydi)", "Yuqori", false),
      acRow("8", "Supervisor o'tkazmani rad etganda sabab majburiy kiritiladi va qoldiqlar o'zgarmaydi", "Yuqori", true),
      acRow("9", "Bajarilgan o'tkazmani Supervisor/Admin storno qila oladi — storno qoldiqlarni va buxgalteriya yozuvini teskari yo'naltiradi; ushlangan komissiya ham qaytariladi", "Yuqori", false),
      acRow("10", "Kunlik chiqim limiti oshganda o'tkazma to'xtatiladi va Supervisor tasdig'i talab qilinadi", "Yuqori", true),
      acRow("11", "Hisob ko'chirmasi (vypiska) da chiqim, kirim va qoldiq muvozanatda: yakuniy qoldiq = boshlang'ich + kirim − chiqim", "Yuqori", false),
      acRow("12", "O'tkazmalar ro'yxati barcha mezonlar bo'yicha qidiriladi va filtrlanadi (hisob, hujjat raqam, holat, valyuta, sana, summa)", "O'rta", true),
      acRow("13", "Ommaviy tasdiqlash/rad etish ishlaydi va har bir o'tkazma natijasi alohida ko'rsatiladi", "O'rta", false),
      acRow("14", "Har bir yaratish, tasdiqlash, rad etish, bekor qilish va storno amali audit logga yoziladi (kim, qachon, nima, sabab) va log o'chirilmaydi", "Yuqori", true),
      acRow("15", "O'tkazma cheki (kvitansiya) chop etiladi va to'lovchi/oluvchi/summa/maqsad/holat ma'lumotlarini to'liq ko'rsatadi", "O'rta", false),
      acRow("16", "Banklararo o'tkazma, byudjet to'lovi va valyuta konvertatsiyasi interfeysda ko'rinadi, lekin keyingi fazada yoqilishi belgilangan (F0 da faqat bir xil valyutadagi ichki o'tkazma faol)", "Past", true),
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
          children: [new TextRun({ text: "MARS ABS  |  BT-003  |  core_ac", font: "Arial", size: 18, color: "999999" })]
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
const OUTPUT = require("path").join(__dirname, "BT-003_core_ac_pul_otkazmalari_biznes_talab.docx");
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUTPUT, buf);
  console.log(`Generated: ${OUTPUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

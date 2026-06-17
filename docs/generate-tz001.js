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
const CW = PAGE_WIDTH - 2 * MARGIN; // 9360

const BLUE = "1F4E79";
const DARK_GRAY = "333333";
const WHITE = "FFFFFF";
const BC = "B4C6E7";
const CODE_BG = "F5F5F5";

const border = { style: BorderStyle.SINGLE, size: 1, color: BC };
const borders = { top: border, bottom: border, left: border, right: border };
const cm = { top: 60, bottom: 60, left: 100, right: 100 };
const hShade = { fill: BLUE, type: ShadingType.CLEAR };
const altShade = { fill: "F2F7FB", type: ShadingType.CLEAR };
const codeShade = { fill: CODE_BG, type: ShadingType.CLEAR };

// ===== HELPERS =====
function hCell(t, w) {
  return new TableCell({ borders, width: { size: w, type: WidthType.DXA }, shading: hShade, margins: cm, verticalAlign: "center",
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: t, bold: true, color: WHITE, font: "Arial", size: 20 })] })] });
}
function c(t, w, o = {}) {
  const sh = o.shaded ? altShade : o.code ? codeShade : undefined;
  return new TableCell({ borders, width: { size: w, type: WidthType.DXA }, shading: sh, margins: cm,
    children: [new Paragraph({ alignment: o.center ? AlignmentType.CENTER : AlignmentType.LEFT,
      children: [new TextRun({ text: String(t), font: o.code ? "Courier New" : "Arial", size: o.code ? 18 : 20, bold: o.bold || false })] })] });
}
function mc(lines, w, o = {}) {
  const sh = o.shaded ? altShade : undefined;
  return new TableCell({ borders, width: { size: w, type: WidthType.DXA }, shading: sh, margins: cm,
    children: lines.map(l => new Paragraph({ children: [new TextRun({ text: l, font: "Arial", size: 20 })] })) });
}
function h(t, lv) { return new Paragraph({ heading: lv, spacing: { before: 240, after: 120 }, children: [new TextRun({ text: t, font: "Arial" })] }); }
function p(t, o = {}) {
  return new Paragraph({ spacing: { after: 120 }, alignment: o.center ? AlignmentType.CENTER : AlignmentType.LEFT,
    children: [new TextRun({ text: t, font: "Arial", size: 22, bold: o.bold || false, italics: o.italic || false, color: o.color || DARK_GRAY })] });
}
function b(t) { return new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: t, font: "Arial", size: 22 })] }); }
function code(t) {
  return new Paragraph({ spacing: { after: 60 },
    children: [new TextRun({ text: t, font: "Courier New", size: 18, color: DARK_GRAY })] });
}
function sp(a = 100) { return new Paragraph({ spacing: { after: a }, children: [] }); }

// DB table helper - builds a full table with standard 6-column layout
function dbTable(title, rows) {
  // rows: [[name, type, size, constraint, nullable, desc], ...]
  const colW = [1600, 1300, 900, 1200, 700, 3660];
  const header = new TableRow({ children: [
    hCell("Ustun", colW[0]), hCell("Tur", colW[1]), hCell("Hajm", colW[2]),
    hCell("Cheklov", colW[3]), hCell("NULL", colW[4]), hCell("Tavsif", colW[5])
  ]});
  const dataRows = rows.map((r, i) => {
    const shaded = i % 2 === 1;
    return new TableRow({ children: [
      c(r[0], colW[0], { code: true, shaded }), c(r[1], colW[1], { shaded }),
      c(r[2], colW[2], { center: true, shaded }), c(r[3], colW[3], { shaded }),
      c(r[4], colW[4], { center: true, shaded }), c(r[5], colW[5], { shaded })
    ]});
  });
  return [
    h(title, HeadingLevel.HEADING_3),
    new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: colW, rows: [header, ...dataRows] }),
    sp(120)
  ];
}

// ===== TITLE PAGE =====
const titlePage = [
  new Paragraph({ spacing: { before: 3000 }, children: [] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
    children: [new TextRun({ text: "FIDO BANK", font: "Arial", size: 44, bold: true, color: BLUE })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "MARS — Avtomatlashtirilgan Bank Tizimi", font: "Arial", size: 28, color: DARK_GRAY })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 },
    children: [new TextRun({ text: "________________________________________", color: BLUE, font: "Arial", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
    children: [new TextRun({ text: "TEXNIK TOPSHIRIQ", font: "Arial", size: 40, bold: true, color: BLUE })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "TZ-001: Mijozlar moduli (core_cif)", font: "Arial", size: 28, color: DARK_GRAY })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "Customer Information File — Texnik loyiha", font: "Arial", size: 24, italics: true, color: "666666" })] }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({ width: { size: 5000, type: WidthType.DXA }, columnWidths: [2000, 3000], rows: [
    new TableRow({ children: [c("Hujjat raqami:", 2000, { bold: true }), c("TZ-001", 3000)] }),
    new TableRow({ children: [c("Versiya:", 2000, { bold: true, shaded: true }), c("2.0", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Sana:", 2000, { bold: true }), c("2026-05-26", 3000)] }),
    new TableRow({ children: [c("Modul:", 2000, { bold: true, shaded: true }), c("core_cif (Mijozlar)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Asoslanadi:", 2000, { bold: true }), c("BT-001 v3.0", 3000)] }),
    new TableRow({ children: [c("Holat:", 2000, { bold: true, shaded: true }), c("Qoralama", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Muallif:", 2000, { bold: true }), c("MARS loyiha guruhi", 3000)] }),
  ]}),
  new Paragraph({ children: [new PageBreak()] })
];

const tocSection = [
  h("Mundarija", HeadingLevel.HEADING_1),
  new TableOfContents("Mundarija", { hyperlink: true, headingStyleRange: "1-3" }),
  new Paragraph({ children: [new PageBreak()] })
];

// ===== 1. UMUMIY MA'LUMOT =====
const section1 = [
  h("1. Umumiy ma'lumot", HeadingLevel.HEADING_1),

  h("1.1. Maqsad", HeadingLevel.HEADING_2),
  p("Ushbu hujjat BT-001 (Mijozlar moduli biznes talablari) asosida tayyorlangan texnik topshiriq bo'lib, core_cif modulining texnik amalga oshirilish tafsilotlarini belgilaydi."),

  h("1.2. Texnologiyalar steki", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3000, 6360], rows: [
    new TableRow({ children: [hCell("Texnologiya", 3000), hCell("Versiya / Tavsif", 6360)] }),
    new TableRow({ children: [c("Dasturlash tili", 3000), c("Java 1.8 (JDK 8)", 6360)] }),
    new TableRow({ children: [c("Web framework", 3000, { shaded: true }), c("Servlet 3.1 + JSP 2.3 + JSTL 1.2 (no Spring)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Ma'lumotlar bazasi", 3000), c("Oracle XE 21c", 6360)] }),
    new TableRow({ children: [c("JDBC driver", 3000, { shaded: true }), c("ojdbc8", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Connection pool", 3000), c("HikariCP 5.1.0", 6360)] }),
    new TableRow({ children: [c("Ilovalar serveri", 3000, { shaded: true }), c("Apache Tomcat 9.0", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Build tizimi", 3000), c("Apache Maven 3.9", 6360)] }),
    new TableRow({ children: [c("Konteynerizatsiya", 3000, { shaded: true }), c("Docker Compose (Oracle XE + Tomcat)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Logging", 3000), c("SLF4J + Logback 1.4.14", 6360)] }),
  ]}),

  h("1.3. Nomlash konvensiyalari", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2800, 3280, 3280], rows: [
    new TableRow({ children: [hCell("Element", 2800), hCell("Qoida", 3280), hCell("Misol", 3280)] }),
    new TableRow({ children: [c("DB jadval", 2800), c("core_cif_{nom}", 3280), c("core_cif_customers", 3280)] }),
    new TableRow({ children: [c("DB ustun", 2800, { shaded: true }), c("snake_case", 3280, { shaded: true }), c("first_name, birth_date", 3280, { shaded: true })] }),
    new TableRow({ children: [c("DB indeks", 2800), c("idx_{jadval}_{ustun}", 3280), c("idx_cif_cust_pinfl", 3280)] }),
    new TableRow({ children: [c("DB constraint", 2800, { shaded: true }), c("chk_{jadval}_{qoida}", 3280, { shaded: true }), c("chk_cust_status", 3280, { shaded: true })] }),
    new TableRow({ children: [c("Java paket", 2800), c("uz.fido.mars.core.cif.{qatlam}", 3280), c("uz.fido.mars.core.cif.model", 3280)] }),
    new TableRow({ children: [c("Java sinf (model)", 2800, { shaded: true }), c("PascalCase", 3280, { shaded: true }), c("Customer, CifDocument", 3280, { shaded: true })] }),
    new TableRow({ children: [c("Java sinf (DAO)", 2800), c("{Model}Dao", 3280), c("CustomerDao", 3280)] }),
    new TableRow({ children: [c("Java sinf (Servlet)", 2800, { shaded: true }), c("{Model}Servlet", 3280, { shaded: true }), c("CustomerServlet", 3280, { shaded: true })] }),
    new TableRow({ children: [c("JSP fayl", 2800), c("kebab-case.jsp", 3280), c("customer-form.jsp", 3280)] }),
    new TableRow({ children: [c("URL pattern", 2800, { shaded: true }), c("/cif/{resurs}/*", 3280, { shaded: true }), c("/cif/customers/new", 3280, { shaded: true })] }),
  ]}),
  sp(200),
];

// ===== 2. MA'LUMOTLAR BAZASI =====
const section2 = [
  h("2. Ma'lumotlar bazasi strukturasi", HeadingLevel.HEADING_1),
  p("Barcha jadvallar bankuser sxemasida yaratiladi. Jadval nomlari core_cif_ prefiksi bilan boshlanadi."),

  h("2.1. ER diagramma", HeadingLevel.HEADING_2),
  p("Jadvallar orasidagi bog'lanishlar:"),
  code("core_cif_customers (1) ──< (N) core_cif_documents"),
  code("core_cif_customers (1) ──< (N) core_cif_contacts"),
  code("core_cif_customers (1) ──< (N) core_cif_audit_log"),
  sp(),

  // --- 2.2. core_cif_customers ---
  h("2.2. core_cif_customers", HeadingLevel.HEADING_2),
  p("Asosiy mijozlar jadvali. Jismoniy va yuridik shaxslar bitta jadvalda, customer_type ustun orqali farqlanadi."),
  ...dbTable("2.2.1. Ustunlar", [
    ["customer_id",      "NUMBER",    "—",   "PK, IDENTITY",    "NN", "Avtomatik ID (GENERATED ALWAYS AS IDENTITY)"],
    ["cif_number",       "VARCHAR2",  "20",  "UNIQUE",          "NN", "CIF raqam, format: CIF-YYYYMMDD-NNNNNN"],
    ["customer_type",    "VARCHAR2",  "20",  "CHECK",           "NN", "INDIVIDUAL | CORPORATE"],
    ["first_name",       "VARCHAR2",  "100", "—",               "NN", "Ism (FYaSh uchun, YuSh da NULL)"],
    ["last_name",        "VARCHAR2",  "100", "—",               "NN", "Familiya (FYaSh uchun, YuSh da NULL)"],
    ["middle_name",      "VARCHAR2",  "100", "—",               "Y",  "Otasining ismi"],
    ["org_name",         "VARCHAR2",  "300", "—",               "Y",  "Tashkilot qisqa nomi (YuSh uchun)"],
    ["org_full_name",    "VARCHAR2",  "500", "—",               "Y",  "Tashkilot to'liq rasmiy nomi"],
    ["org_form",         "VARCHAR2",  "30",  "—",               "Y",  "Tashkiliy-huquqiy shakl: MChJ, AJ, YaTT, QK, UP"],
    ["oked",             "VARCHAR2",  "10",  "—",               "Y",  "OKED faoliyat turi kodi"],
    ["reg_number",       "VARCHAR2",  "30",  "—",               "Y",  "Davlat ro'yxatiga olish raqami"],
    ["reg_date",         "DATE",      "—",   "—",               "Y",  "Ro'yxatga olingan sana"],
    ["reg_authority",    "VARCHAR2",  "200", "—",               "Y",  "Ro'yxatga olgan organ"],
    ["director_name",    "VARCHAR2",  "200", "—",               "Y",  "Rahbar FIO"],
    ["director_position","VARCHAR2",  "100", "—",               "Y",  "Rahbar lavozimi"],
    ["accountant_name",  "VARCHAR2",  "200", "—",               "Y",  "Bosh hisobchi FIO"],
    ["pinfl",            "VARCHAR2",  "14",  "UNIQUE",          "Y",  "PINFL — 14 xonali (FYaSh uchun)"],
    ["inn",              "VARCHAR2",  "9",   "UNIQUE",          "Y",  "STIR — 9 xonali (YuSh uchun)"],
    ["birth_date",       "DATE",      "—",   "—",               "Y",  "Tug'ilgan sana (FYaSh)"],
    ["birth_place",      "VARCHAR2",  "200", "—",               "Y",  "Tug'ilgan joyi (FYaSh)"],
    ["gender",           "VARCHAR2",  "1",   "CHECK",           "Y",  "Jinsi: M | F"],
    ["phone",            "VARCHAR2",  "20",  "—",               "NN", "Asosiy telefon raqam (+998...)"],
    ["email",            "VARCHAR2",  "150", "—",               "Y",  "Email manzil"],
    ["legal_address",    "VARCHAR2",  "500", "—",               "Y",  "Yuridik/ro'yxatga olingan manzil"],
    ["actual_address",   "VARCHAR2",  "500", "—",               "Y",  "Haqiqiy yashash/joylashish manzili"],
    ["resident_flag",    "CHAR",      "1",   "CHECK",           "NN", "Rezident belgisi: Y | N"],
    ["country_code",     "VARCHAR2",  "3",   "—",               "NN", "Fuqarolik kodi (ISO 3166-1 alpha-3)"],
    ["branch_code",      "VARCHAR2",  "5",   "—",               "NN", "Ro'yxatga olgan filial MFO kodi"],
    ["sector_code",      "VARCHAR2",  "10",  "—",               "NN", "Iqtisodiyot sektori (CBU klassifikatori)"],
    ["risk_category",    "VARCHAR2",  "10",  "CHECK",           "NN", "KYC xavf darajasi: LOW | MEDIUM | HIGH"],
    ["is_pep",           "CHAR",      "1",   "CHECK",           "NN", "PEP belgisi: Y | N (default N)"],
    ["opening_purpose",  "VARCHAR2",  "200", "—",               "Y",  "Bank xizmatidan maqsad"],
    ["employer_name",    "VARCHAR2",  "300", "—",               "Y",  "Ish joyi (tashkilot nomi) — FYaSh uchun"],
    ["employer_position","VARCHAR2",  "100", "—",               "Y",  "Lavozimi — FYaSh uchun"],
    ["employer_address", "VARCHAR2",  "500", "—",               "Y",  "Ish joyi manzili — FYaSh uchun"],
    ["employer_phone",   "VARCHAR2",  "20",  "—",               "Y",  "Ish joyi telefoni — FYaSh uchun"],
    ["director_pinfl",   "VARCHAR2",  "14",  "—",               "Y",  "Rahbar PINFL — YuSh uchun"],
    ["other_bank_name",  "VARCHAR2",  "200", "—",               "Y",  "Boshqa bankdagi hisob: bank nomi — YuSh uchun"],
    ["other_bank_mfo",   "VARCHAR2",  "5",   "—",               "Y",  "Boshqa bank MFO kodi — YuSh uchun"],
    ["other_bank_account","VARCHAR2", "20",  "—",               "Y",  "Boshqa bankdagi hisob raqami — YuSh uchun"],
    ["status",           "VARCHAR2",  "20",  "CHECK",           "NN", "Holat: PENDING | ACTIVE | BLOCKED | CLOSED"],
    ["approved_by",      "VARCHAR2",  "50",  "—",               "Y",  "Tasdiqlagan foydalanuvchi (Checker)"],
    ["approved_at",      "TIMESTAMP", "—",   "—",               "Y",  "Tasdiqlangan vaqt"],
    ["created_at",       "TIMESTAMP", "—",   "DEFAULT CURRENT", "NN", "Yaratilgan vaqt"],
    ["updated_at",       "TIMESTAMP", "—",   "—",               "Y",  "Oxirgi o'zgarish vaqti"],
    ["created_by",       "VARCHAR2",  "50",  "—",               "NN", "Yaratgan foydalanuvchi (Maker)"],
    ["updated_by",       "VARCHAR2",  "50",  "—",               "Y",  "O'zgartirgan foydalanuvchi"],
  ]),

  h("2.2.2. CHECK cheklovlar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2800, 6560], rows: [
    new TableRow({ children: [hCell("Cheklov nomi", 2800), hCell("Ifoda", 6560)] }),
    new TableRow({ children: [c("chk_cust_type", 2800), c("customer_type IN ('INDIVIDUAL', 'CORPORATE')", 6560, { code: true })] }),
    new TableRow({ children: [c("chk_cust_gender", 2800, { shaded: true }), c("gender IN ('M', 'F') OR gender IS NULL", 6560, { code: true, shaded: true })] }),
    new TableRow({ children: [c("chk_cust_resident", 2800), c("resident_flag IN ('Y', 'N')", 6560, { code: true })] }),
    new TableRow({ children: [c("chk_cust_risk", 2800, { shaded: true }), c("risk_category IN ('LOW', 'MEDIUM', 'HIGH')", 6560, { code: true, shaded: true })] }),
    new TableRow({ children: [c("chk_cust_pep", 2800), c("is_pep IN ('Y', 'N')", 6560, { code: true })] }),
    new TableRow({ children: [c("chk_cust_status", 2800, { shaded: true }), c("status IN ('PENDING', 'ACTIVE', 'BLOCKED', 'CLOSED')", 6560, { code: true, shaded: true })] }),
  ]}),
  sp(),

  h("2.2.3. Indekslar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 3080, 3080], rows: [
    new TableRow({ children: [hCell("Indeks nomi", 3200), hCell("Ustunlar", 3080), hCell("Turi", 3080)] }),
    new TableRow({ children: [c("idx_cif_cust_cif", 3200), c("cif_number", 3080), c("UNIQUE (avtomatik)", 3080)] }),
    new TableRow({ children: [c("idx_cif_cust_pinfl", 3200, { shaded: true }), c("pinfl", 3080, { shaded: true }), c("UNIQUE (avtomatik)", 3080, { shaded: true })] }),
    new TableRow({ children: [c("idx_cif_cust_inn", 3200), c("inn", 3080), c("UNIQUE (avtomatik)", 3080)] }),
    new TableRow({ children: [c("idx_cif_cust_name", 3200, { shaded: true }), c("last_name, first_name", 3080, { shaded: true }), c("NON-UNIQUE", 3080, { shaded: true })] }),
    new TableRow({ children: [c("idx_cif_cust_org", 3200), c("org_name", 3080), c("NON-UNIQUE", 3080)] }),
    new TableRow({ children: [c("idx_cif_cust_phone", 3200, { shaded: true }), c("phone", 3080, { shaded: true }), c("NON-UNIQUE", 3080, { shaded: true })] }),
    new TableRow({ children: [c("idx_cif_cust_status", 3200), c("status", 3080), c("NON-UNIQUE", 3080)] }),
    new TableRow({ children: [c("idx_cif_cust_branch", 3200, { shaded: true }), c("branch_code", 3080, { shaded: true }), c("NON-UNIQUE", 3080, { shaded: true })] }),
    new TableRow({ children: [c("idx_cif_cust_approved", 3200), c("status, approved_by", 3080), c("NON-UNIQUE (PENDING filtr)", 3080)] }),
  ]}),
  sp(200),

  // --- 2.3. core_cif_documents ---
  h("2.3. core_cif_documents", HeadingLevel.HEADING_2),
  p("Mijoz identifikatsiya hujjatlari jadvali."),
  ...dbTable("2.3.1. Ustunlar", [
    ["doc_id",       "NUMBER",    "—",   "PK, IDENTITY",    "NN", "Avtomatik ID"],
    ["customer_id",  "NUMBER",    "—",   "FK → customers",  "NN", "Mijoz ID (ON DELETE CASCADE)"],
    ["doc_type",     "VARCHAR2",  "30",  "CHECK",           "NN", "PASSPORT | ID_CARD | FOREIGN_PASSPORT | CERTIFICATE | LICENSE | POWER_OF_ATTORNEY"],
    ["doc_series",   "VARCHAR2",  "10",  "—",               "Y",  "Hujjat seriyasi (masalan: AA)"],
    ["doc_number",   "VARCHAR2",  "20",  "—",               "NN", "Hujjat raqami"],
    ["issued_by",    "VARCHAR2",  "200", "—",               "NN", "Kim tomonidan berilgan"],
    ["issued_date",  "DATE",      "—",   "—",               "NN", "Berilgan sana"],
    ["expiry_date",  "DATE",      "—",   "—",               "Y",  "Amal qilish muddati"],
    ["is_primary",   "CHAR",      "1",   "CHECK",           "NN", "Asosiy hujjat belgisi: Y | N"],
    ["created_at",   "TIMESTAMP", "—",   "DEFAULT CURRENT", "NN", "Yaratilgan vaqt"],
    ["created_by",   "VARCHAR2",  "50",  "—",               "NN", "Yaratgan foydalanuvchi"],
  ]),

  h("2.3.2. Cheklovlar va indekslar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 6160], rows: [
    new TableRow({ children: [hCell("Nomi", 3200), hCell("Tavsif", 6160)] }),
    new TableRow({ children: [c("chk_doc_type", 3200), c("doc_type IN ('PASSPORT','ID_CARD','FOREIGN_PASSPORT','CERTIFICATE','LICENSE','POWER_OF_ATTORNEY')", 6160)] }),
    new TableRow({ children: [c("chk_doc_primary", 3200, { shaded: true }), c("is_primary IN ('Y', 'N')", 6160, { shaded: true })] }),
    new TableRow({ children: [c("fk_doc_customer", 3200), c("FOREIGN KEY (customer_id) REFERENCES core_cif_customers ON DELETE CASCADE", 6160)] }),
    new TableRow({ children: [c("idx_cif_doc_cust", 3200, { shaded: true }), c("INDEX ON (customer_id) — tez qidiruv uchun", 6160, { shaded: true })] }),
    new TableRow({ children: [c("idx_cif_doc_expiry", 3200), c("INDEX ON (expiry_date) — muddati o'tayotganlarni topish uchun", 6160)] }),
  ]}),
  sp(200),

  // --- 2.4. core_cif_contacts ---
  h("2.4. core_cif_contacts", HeadingLevel.HEADING_2),
  p("Qo'shimcha aloqa ma'lumotlari jadvali."),
  ...dbTable("2.4.1. Ustunlar", [
    ["contact_id",    "NUMBER",    "—",   "PK, IDENTITY",    "NN", "Avtomatik ID"],
    ["customer_id",   "NUMBER",    "—",   "FK → customers",  "NN", "Mijoz ID (ON DELETE CASCADE)"],
    ["contact_type",  "VARCHAR2",  "20",  "CHECK",           "NN", "PHONE | EMAIL | FAX | TELEGRAM | OTHER"],
    ["contact_value", "VARCHAR2",  "200", "—",               "NN", "Aloqa qiymati (raqam, email va h.k.)"],
    ["is_primary",    "CHAR",      "1",   "CHECK",           "NN", "Asosiy aloqa belgisi: Y | N"],
    ["description",   "VARCHAR2",  "200", "—",               "Y",  "Izoh"],
    ["created_at",    "TIMESTAMP", "—",   "DEFAULT CURRENT", "NN", "Yaratilgan vaqt"],
  ]),
  sp(),

  // --- 2.5. core_cif_audit_log ---
  h("2.5. core_cif_audit_log", HeadingLevel.HEADING_2),
  p("Mijoz ma'lumotlaridagi barcha o'zgarishlar tarixi. Bu jadvalga faqat INSERT qilinadi, UPDATE/DELETE ta'qiqlangan."),
  ...dbTable("2.5.1. Ustunlar", [
    ["log_id",       "NUMBER",    "—",   "PK, IDENTITY",    "NN", "Avtomatik ID"],
    ["customer_id",  "NUMBER",    "—",   "FK → customers",  "NN", "Mijoz ID"],
    ["action_type",  "VARCHAR2",  "20",  "CHECK",           "NN", "CREATE | UPDATE | STATUS_CHANGE"],
    ["field_name",   "VARCHAR2",  "100", "—",               "Y",  "O'zgargan maydon nomi"],
    ["old_value",    "VARCHAR2",  "500", "—",               "Y",  "Eski qiymat"],
    ["new_value",    "VARCHAR2",  "500", "—",               "Y",  "Yangi qiymat"],
    ["changed_by",   "VARCHAR2",  "50",  "—",               "NN", "O'zgartirgan foydalanuvchi"],
    ["changed_at",   "TIMESTAMP", "—",   "DEFAULT CURRENT", "NN", "O'zgarish vaqti"],
  ]),

  h("2.6. CIF raqam generatsiya ketma-ketligi", HeadingLevel.HEADING_2),
  p("CIF raqam avtomatik generatsiya uchun Oracle SEQUENCE ishlatiladi:"),
  code("CREATE SEQUENCE core_cif_seq"),
  code("  START WITH 1 INCREMENT BY 1"),
  code("  NOCACHE NOCYCLE;"),
  sp(),
  p("Java kodida CIF raqam formati:"),
  code('String cif = String.format("CIF-%s-%06d",'),
  code("  LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE),"),
  code("  nextVal);"),
  p("Misol: CIF-20260526-000001", { italic: true }),
  sp(200),
];

// ===== 3. JAVA ARXITEKTURASI =====
const section3 = [
  h("3. Java arxitekturasi", HeadingLevel.HEADING_1),

  h("3.1. Paket strukturasi", HeadingLevel.HEADING_2),
  code("uz.fido.mars.core.cif/"),
  code("  model/"),
  code("    Customer.java          — Asosiy mijoz POJO"),
  code("    CifDocument.java       — Hujjat POJO"),
  code("    CifContact.java        — Aloqa POJO"),
  code("    CifAuditLog.java       — Audit log POJO"),
  code("    CustomerType.java      — enum: INDIVIDUAL, CORPORATE"),
  code("    CustomerStatus.java    — enum: PENDING, ACTIVE, BLOCKED, CLOSED"),
  code("    RiskCategory.java      — enum: LOW, MEDIUM, HIGH"),
  code("  dao/"),
  code("    CustomerDao.java       — CRUD + qidiruv + holat o'zgartirish"),
  code("    CifDocumentDao.java    — Hujjat CRUD"),
  code("    CifContactDao.java     — Aloqa CRUD"),
  code("    CifAuditLogDao.java    — Audit log yozish (faqat INSERT)"),
  code("    CifSequenceDao.java    — CIF raqam generatsiya (SEQUENCE)"),
  code("  service/"),
  code("    CustomerService.java   — Biznes logika + tranzaksiya boshqaruvi"),
  code("  servlet/"),
  code("    CustomerServlet.java   — /cif/customers/* (CRUD)"),
  code("    CustomerSearchServlet.java — /cif/customers/search"),
  code("    CustomerApprovalServlet.java — /cif/customers/approval (Maker-Checker)"),
  code("  util/"),
  code("    CifValidator.java      — Validatsiya qoidalari"),
  code("    CifNumberGenerator.java — CIF raqam generatsiya"),
  sp(),

  h("3.2. Model sinflari", HeadingLevel.HEADING_2),
  p("Barcha model sinflari java.time va java.math.BigDecimal ishlatadi. Lombok ishlatilmaydi — standart getter/setter."),
  sp(),

  h("3.2.1. Customer.java — asosiy maydonlar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2800, 2280, 4280], rows: [
    new TableRow({ children: [hCell("Maydon", 2800), hCell("Java turi", 2280), hCell("Izoh", 4280)] }),
    new TableRow({ children: [c("customerId", 2800), c("Long", 2280), c("DB: customer_id", 4280)] }),
    new TableRow({ children: [c("cifNumber", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("DB: cif_number", 4280, { shaded: true })] }),
    new TableRow({ children: [c("customerType", 2800), c("CustomerType", 2280), c("enum: INDIVIDUAL | CORPORATE", 4280)] }),
    new TableRow({ children: [c("firstName", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("FYaSh. YuSh da null", 4280, { shaded: true })] }),
    new TableRow({ children: [c("lastName", 2800), c("String", 2280), c("FYaSh. YuSh da null", 4280)] }),
    new TableRow({ children: [c("middleName", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("Nullable", 4280, { shaded: true })] }),
    new TableRow({ children: [c("orgName", 2800), c("String", 2280), c("YuSh. FYaSh da null", 4280)] }),
    new TableRow({ children: [c("orgFullName", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("Nullable", 4280, { shaded: true })] }),
    new TableRow({ children: [c("orgForm", 2800), c("String", 2280), c("MChJ, AJ, YaTT, QK, UP", 4280)] }),
    new TableRow({ children: [c("oked", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("OKED kod", 4280, { shaded: true })] }),
    new TableRow({ children: [c("pinfl", 2800), c("String", 2280), c("14 xonali. YuSh da null", 4280)] }),
    new TableRow({ children: [c("inn", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("9 xonali. FYaSh da null", 4280, { shaded: true })] }),
    new TableRow({ children: [c("birthDate", 2800), c("LocalDate", 2280), c("FYaSh", 4280)] }),
    new TableRow({ children: [c("birthPlace", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("FYaSh", 4280, { shaded: true })] }),
    new TableRow({ children: [c("phone", 2800), c("String", 2280), c("+998XXXXXXXXX", 4280)] }),
    new TableRow({ children: [c("riskCategory", 2800, { shaded: true }), c("RiskCategory", 2280, { shaded: true }), c("enum: LOW | MEDIUM | HIGH", 4280, { shaded: true })] }),
    new TableRow({ children: [c("isPep", 2800), c("boolean", 2280), c("PEP belgisi", 4280)] }),
    new TableRow({ children: [c("employerName", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("FYaSh ish joyi", 4280, { shaded: true })] }),
    new TableRow({ children: [c("employerPosition", 2800), c("String", 2280), c("FYaSh lavozimi", 4280)] }),
    new TableRow({ children: [c("directorPinfl", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("YuSh rahbar PINFL", 4280, { shaded: true })] }),
    new TableRow({ children: [c("otherBankName", 2800), c("String", 2280), c("YuSh boshqa bank nomi", 4280)] }),
    new TableRow({ children: [c("otherBankMfo", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("YuSh boshqa bank MFO", 4280, { shaded: true })] }),
    new TableRow({ children: [c("otherBankAccount", 2800), c("String", 2280), c("YuSh boshqa bankdagi hisob", 4280)] }),
    new TableRow({ children: [c("status", 2800, { shaded: true }), c("CustomerStatus", 2280, { shaded: true }), c("enum: PENDING | ACTIVE | BLOCKED | CLOSED", 4280, { shaded: true })] }),
    new TableRow({ children: [c("approvedBy", 2800), c("String", 2280), c("Tasdiqlagan foydalanuvchi (Checker)", 4280)] }),
    new TableRow({ children: [c("approvedAt", 2800, { shaded: true }), c("LocalDateTime", 2280, { shaded: true }), c("Tasdiqlangan vaqt", 4280, { shaded: true })] }),
    new TableRow({ children: [c("createdAt", 2800), c("LocalDateTime", 2280), c("Yaratilgan vaqt", 4280)] }),
    new TableRow({ children: [c("createdBy", 2800, { shaded: true }), c("String", 2280, { shaded: true }), c("Yaratgan foydalanuvchi (Maker)", 4280, { shaded: true })] }),
  ]}),
  sp(),
  p("Qolgan maydonlar (regNumber, regDate, regAuthority, directorName, directorPosition, accountantName, email, legalAddress, actualAddress, residentFlag, countryCode, branchCode, sectorCode, openingPurpose, employerAddress, employerPhone, updatedAt, updatedBy) xuddi shu tamoyilda.", { italic: true }),
  sp(),

  h("3.3. DAO sinflari", HeadingLevel.HEADING_2),
  p("Barcha DAO sinflari DbUtil.getConnection() orqali HikariCP dan ulanish oladi. Raw JDBC — PreparedStatement ishlatiladi."),
  sp(),

  h("3.3.1. CustomerDao metodlari", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 2080, 4080], rows: [
    new TableRow({ children: [hCell("Metod", 3200), hCell("Qaytaradi", 2080), hCell("Tavsif", 4080)] }),
    new TableRow({ children: [c("create(Customer)", 3200), c("Customer", 2080), c("Yangi mijoz yaratish + CIF generatsiya + audit log", 4080)] }),
    new TableRow({ children: [c("findById(long)", 3200, { shaded: true }), c("Optional<Customer>", 2080, { shaded: true }), c("ID bo'yicha topish", 4080, { shaded: true })] }),
    new TableRow({ children: [c("findByCifNumber(String)", 3200), c("Optional<Customer>", 2080), c("CIF raqam bo'yicha topish", 4080)] }),
    new TableRow({ children: [c("findByPinfl(String)", 3200, { shaded: true }), c("Optional<Customer>", 2080, { shaded: true }), c("PINFL bo'yicha topish (dublikat tekshiruv)", 4080, { shaded: true })] }),
    new TableRow({ children: [c("findByInn(String)", 3200), c("Optional<Customer>", 2080), c("STIR bo'yicha topish (dublikat tekshiruv)", 4080)] }),
    new TableRow({ children: [c("search(SearchCriteria)", 3200, { shaded: true }), c("List<Customer>", 2080, { shaded: true }), c("Qidiruv: FIO, telefon, holat, tur bo'yicha", 4080, { shaded: true })] }),
    new TableRow({ children: [c("update(Customer)", 3200), c("void", 2080), c("Yangilash + o'zgargan maydonlar audit log ga", 4080)] }),
    new TableRow({ children: [c("changeStatus(id, status, reason, user)", 3200, { shaded: true }), c("void", 2080, { shaded: true }), c("Holat o'zgartirish + audit log", 4080, { shaded: true })] }),
    new TableRow({ children: [c("findAll(page, size)", 3200), c("List<Customer>", 2080), c("Sahifalash bilan ro'yxat (OFFSET/FETCH)", 4080)] }),
    new TableRow({ children: [c("count()", 3200, { shaded: true }), c("long", 2080, { shaded: true }), c("Jami mijozlar soni", 4080, { shaded: true })] }),
    new TableRow({ children: [c("findPending(page, size)", 3200), c("List<Customer>", 2080), c("PENDING holatdagi mijozlar (Checker uchun)", 4080)] }),
    new TableRow({ children: [c("approve(id, approvedBy)", 3200, { shaded: true }), c("void", 2080, { shaded: true }), c("Tasdiqlash: PENDING → ACTIVE + approved_by/at", 4080, { shaded: true })] }),
    new TableRow({ children: [c("reject(id, reason, rejectedBy)", 3200), c("void", 2080), c("Rad etish: PENDING → o'chirish + audit log", 4080)] }),
  ]}),
  sp(200),
];

// ===== 4. SERVLET VA URL ROUTING =====
const section4 = [
  h("4. Servlet va URL routing", HeadingLevel.HEADING_1),

  h("4.1. URL tuzilmasi", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [1200, 3200, 4960], rows: [
    new TableRow({ children: [hCell("Metod", 1200), hCell("URL", 3200), hCell("Tavsif", 4960)] }),
    new TableRow({ children: [c("GET", 1200), c("/cif/customers", 3200), c("Mijozlar ro'yxati (sahifalash + filtr)", 4960)] }),
    new TableRow({ children: [c("GET", 1200, { shaded: true }), c("/cif/customers/new", 3200, { shaded: true }), c("Yangi mijoz yaratish formasi", 4960, { shaded: true })] }),
    new TableRow({ children: [c("POST", 1200), c("/cif/customers", 3200), c("Yangi mijoz saqlash", 4960)] }),
    new TableRow({ children: [c("GET", 1200, { shaded: true }), c("/cif/customers/{id}", 3200, { shaded: true }), c("Mijoz tafsilotlari", 4960, { shaded: true })] }),
    new TableRow({ children: [c("GET", 1200), c("/cif/customers/{id}/edit", 3200), c("Mijoz tahrirlash formasi", 4960)] }),
    new TableRow({ children: [c("POST", 1200, { shaded: true }), c("/cif/customers/{id}", 3200, { shaded: true }), c("Mijoz ma'lumotlarini yangilash", 4960, { shaded: true })] }),
    new TableRow({ children: [c("POST", 1200), c("/cif/customers/{id}/status", 3200), c("Holat o'zgartirish", 4960)] }),
    new TableRow({ children: [c("GET", 1200, { shaded: true }), c("/cif/customers/search", 3200, { shaded: true }), c("Qidiruv (query parametrlari bilan)", 4960, { shaded: true })] }),
    new TableRow({ children: [c("GET", 1200), c("/cif/customers/approval", 3200), c("Tasdiqlash kutayotganlar ro'yxati (Supervisor)", 4960)] }),
    new TableRow({ children: [c("POST", 1200, { shaded: true }), c("/cif/customers/{id}/approve", 3200, { shaded: true }), c("Mijozni tasdiqlash (Maker-Checker: Checker)", 4960, { shaded: true })] }),
    new TableRow({ children: [c("POST", 1200), c("/cif/customers/{id}/reject", 3200), c("Mijozni rad etish + sabab", 4960)] }),
  ]}),

  h("4.2. CustomerServlet", HeadingLevel.HEADING_2),
  p("@WebServlet(\"/cif/customers/*\") — barcha mijoz operatsiyalari bir servlet da. Path-info parsing orqali routing."),
  sp(),
  p("doGet() ichidagi routing:", { bold: true }),
  code("pathInfo == null || \"/\"    → listCustomers(req, resp)"),
  code("pathInfo == \"/new\"         → showCreateForm(req, resp)"),
  code("pathInfo == \"/{id}\"        → showDetail(req, resp)"),
  code("pathInfo == \"/{id}/edit\"   → showEditForm(req, resp)"),
  code("pathInfo == \"/search\"      → searchCustomers(req, resp)"),
  code("pathInfo == \"/approval\"    → listPendingCustomers(req, resp)"),
  sp(),
  p("doPost() ichidagi routing:", { bold: true }),
  code("pathInfo == null || \"/\"    → createCustomer(req, resp)"),
  code("pathInfo == \"/{id}\"        → updateCustomer(req, resp)"),
  code("pathInfo == \"/{id}/status\"  → changeStatus(req, resp)"),
  code("pathInfo == \"/{id}/approve\" → approveCustomer(req, resp)"),
  code("pathInfo == \"/{id}/reject\"  → rejectCustomer(req, resp)"),
  sp(200),
];

// ===== 5. JSP SAHIFALAR =====
const section5 = [
  h("5. JSP sahifalar", HeadingLevel.HEADING_1),

  h("5.1. Fayllar ro'yxati", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 2080, 4080], rows: [
    new TableRow({ children: [hCell("Fayl", 3200), hCell("Ekran ID", 2080), hCell("Tavsif", 4080)] }),
    new TableRow({ children: [c("cif/customers.jsp", 3200), c("SCR-001", 2080), c("Mijozlar ro'yxati + qidiruv + filtrlar", 4080)] }),
    new TableRow({ children: [c("cif/customer-form.jsp", 3200, { shaded: true }), c("SCR-002/004", 2080, { shaded: true }), c("Yaratish va tahrirlash formasi (bir JSP)", 4080, { shaded: true })] }),
    new TableRow({ children: [c("cif/customer-detail.jsp", 3200), c("SCR-003", 2080), c("Mijoz tafsilotlari", 4080)] }),
    new TableRow({ children: [c("cif/customer-status.jsp", 3200, { shaded: true }), c("SCR-005", 2080, { shaded: true }), c("Holat o'zgartirish (modal fragment)", 4080, { shaded: true })] }),
    new TableRow({ children: [c("cif/customer-approval.jsp", 3200), c("SCR-006", 2080), c("Supervisor tasdiqlash ekrani (Maker-Checker)", 4080)] }),
  ]}),

  h("5.2. Request atributlari", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 2480, 4480], rows: [
    new TableRow({ children: [hCell("Atribut", 2400), hCell("Tur", 2480), hCell("Ishlatiladi", 4480)] }),
    new TableRow({ children: [c("customer", 2400), c("Customer", 2480), c("detail, form (tahrirlash rejimi)", 4480)] }),
    new TableRow({ children: [c("customers", 2400, { shaded: true }), c("List<Customer>", 2480, { shaded: true }), c("ro'yxat, qidiruv natijalari", 4480, { shaded: true })] }),
    new TableRow({ children: [c("documents", 2400), c("List<CifDocument>", 2480), c("detail sahifa — hujjatlar bo'limi", 4480)] }),
    new TableRow({ children: [c("contacts", 2400, { shaded: true }), c("List<CifContact>", 2480, { shaded: true }), c("detail sahifa — aloqa bo'limi", 4480, { shaded: true })] }),
    new TableRow({ children: [c("auditLogs", 2400), c("List<CifAuditLog>", 2480), c("detail sahifa — tarix bo'limi", 4480)] }),
    new TableRow({ children: [c("currentPage", 2400, { shaded: true }), c("int", 2480, { shaded: true }), c("sahifalash", 4480, { shaded: true })] }),
    new TableRow({ children: [c("totalPages", 2400), c("int", 2480), c("sahifalash", 4480)] }),
    new TableRow({ children: [c("pendingCustomers", 2400, { shaded: true }), c("List<Customer>", 2480, { shaded: true }), c("tasdiqlash kutayotganlar (SCR-006)", 4480, { shaded: true })] }),
    new TableRow({ children: [c("error / success", 2400), c("String (session)", 2480), c("xato/muvaffaqiyat xabarlari (flash)", 4480)] }),
  ]}),
  sp(200),
];

// ===== 6. VALIDATSIYA =====
const section6 = [
  h("6. Validatsiya qoidalari", HeadingLevel.HEADING_1),
  p("CifValidator.java sinfi barcha validatsiya qoidalarini amalga oshiradi. Validatsiya servlet darajasida (doPost) chaqiriladi."),
  sp(),

  h("6.1. Umumiy validatsiya", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 4960, 2000], rows: [
    new TableRow({ children: [hCell("Maydon", 2400), hCell("Qoida", 4960), hCell("BR havolasi", 2000)] }),
    new TableRow({ children: [c("phone", 2400), c("Regex: ^\\+998\\d{9}$ (13 belgi)", 4960), c("BR-009", 2000, { center: true })] }),
    new TableRow({ children: [c("email", 2400, { shaded: true }), c("Regex: ^[\\w.-]+@[\\w.-]+\\.\\w{2,}$ (ixtiyoriy)", 4960, { shaded: true }), c("—", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("is_pep → risk", 2400), c("Agar is_pep = Y, risk_category avtomatik HIGH ga o'rnatiladi", 4960), c("BR-017", 2000, { center: true })] }),
    new TableRow({ children: [c("status o'tish", 2400, { shaded: true }), c("Faqat ruxsat etilgan o'tishlar: PENDING→ACTIVE(approve), ACTIVE→BLOCKED, BLOCKED→ACTIVE, ACTIVE→CLOSED, BLOCKED→CLOSED", 4960, { shaded: true }), c("BR-005,020,021", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("Maker ≠ Checker", 2400), c("created_by va approved_by bir xil foydalanuvchi bo'la olmaydi", 4960), c("BR-020", 2000, { center: true })] }),
  ]}),

  h("6.2. FYaSh validatsiya", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 4960, 2000], rows: [
    new TableRow({ children: [hCell("Maydon", 2400), hCell("Qoida", 4960), hCell("BR havolasi", 2000)] }),
    new TableRow({ children: [c("first_name", 2400), c("NOT NULL, kamida 2 belgi", 4960), c("BR-009", 2000, { center: true })] }),
    new TableRow({ children: [c("last_name", 2400, { shaded: true }), c("NOT NULL, kamida 2 belgi", 4960, { shaded: true }), c("BR-009", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("pinfl", 2400), c("NOT NULL, aniq 14 raqam, UNIQUE tekshiruv", 4960), c("BR-002,011", 2000, { center: true })] }),
    new TableRow({ children: [c("birth_date", 2400, { shaded: true }), c("NOT NULL, yoshi >= 18 (bugungi_sana - birth_date >= 18 yil)", 4960, { shaded: true }), c("BR-009", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("birth_place", 2400), c("NOT NULL", 4960), c("—", 2000, { center: true })] }),
  ]}),

  h("6.3. YuSh validatsiya", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 4960, 2000], rows: [
    new TableRow({ children: [hCell("Maydon", 2400), hCell("Qoida", 4960), hCell("BR havolasi", 2000)] }),
    new TableRow({ children: [c("org_name", 2400), c("NOT NULL, kamida 3 belgi", 4960), c("BR-013", 2000, { center: true })] }),
    new TableRow({ children: [c("inn", 2400, { shaded: true }), c("NOT NULL, aniq 9 raqam, UNIQUE tekshiruv", 4960, { shaded: true }), c("BR-003,012", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("org_form", 2400), c("NOT NULL", 4960), c("BR-013", 2000, { center: true })] }),
    new TableRow({ children: [c("oked", 2400, { shaded: true }), c("NOT NULL", 4960, { shaded: true }), c("BR-013", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("reg_number", 2400), c("NOT NULL", 4960), c("BR-013", 2000, { center: true })] }),
    new TableRow({ children: [c("reg_date", 2400, { shaded: true }), c("NOT NULL", 4960, { shaded: true }), c("BR-013", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("reg_authority", 2400), c("NOT NULL", 4960), c("BR-013", 2000, { center: true })] }),
    new TableRow({ children: [c("director_name", 2400, { shaded: true }), c("NOT NULL", 4960, { shaded: true }), c("BR-013", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("director_pinfl", 2400), c("NOT NULL, 14 xonali raqam", 4960), c("BR-013", 2000, { center: true })] }),
    new TableRow({ children: [c("accountant_name", 2400, { shaded: true }), c("NOT NULL", 4960, { shaded: true }), c("BR-013", 2000, { center: true, shaded: true })] }),
    new TableRow({ children: [c("legal_address", 2400), c("NOT NULL", 4960), c("BR-013", 2000, { center: true })] }),
  ]}),
  sp(200),
];

// ===== 7. XAVFSIZLIK =====
const section7 = [
  h("7. Xavfsizlik talablari", HeadingLevel.HEADING_1),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [800, 3560, 5000], rows: [
    new TableRow({ children: [hCell("#", 800), hCell("Talab", 3560), hCell("Amalga oshirish", 5000)] }),
    new TableRow({ children: [c("1", 800, { center: true }), c("SQL Injection himoyasi", 3560), c("Barcha so'rovlarda PreparedStatement ishlatiladi", 5000)] }),
    new TableRow({ children: [c("2", 800, { center: true, shaded: true }), c("XSS himoyasi", 3560, { shaded: true }), c("JSP da JSTL <c:out> orqali chiqarish, HTML escape", 5000, { shaded: true })] }),
    new TableRow({ children: [c("3", 800, { center: true }), c("CSRF himoyasi", 3560), c("Forma POST so'rovlarda CSRF token", 5000)] }),
    new TableRow({ children: [c("4", 800, { center: true, shaded: true }), c("Input sanitizatsiya", 3560, { shaded: true }), c("Barcha kirishlar serverda qayta validatsiya qilinadi", 5000, { shaded: true })] }),
    new TableRow({ children: [c("5", 800, { center: true }), c("Audit trail", 3560), c("Barcha o'zgarishlar audit_log ga yoziladi", 5000)] }),
    new TableRow({ children: [c("6", 800, { center: true, shaded: true }), c("Shaxsiy ma'lumotlar", 3560, { shaded: true }), c("PINFL/STIR/passport faqat vakolatli foydalanuvchilarga ko'rsatiladi", 5000, { shaded: true })] }),
    new TableRow({ children: [c("7", 800, { center: true }), c("Maker-Checker nazorati", 3560), c("Bir foydalanuvchi yaratib, o'zi tasdiqlay olmaydi. created_by ≠ approved_by tekshiruvi", 5000)] }),
    new TableRow({ children: [c("8", 800, { center: true, shaded: true }), c("Rol asosida kirish (RBAC)", 3560, { shaded: true }), c("Operator/Supervisor/Admin/Auditor rollari, AuthFilter orqali URL himoyasi", 5000, { shaded: true })] }),
  ]}),
  sp(200),
];

// ===== 8. TEST STSENARIYLAR =====
const section8 = [
  h("8. Test stsenariylar", HeadingLevel.HEADING_1),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [800, 2200, 4160, 2200], rows: [
    new TableRow({ children: [hCell("#", 800), hCell("Stsenariy", 2200), hCell("Kutilgan natija", 4160), hCell("BR havolasi", 2200)] }),
    new TableRow({ children: [
      c("1", 800, { center: true }), c("FYaSh yaratish", 2200),
      c("To'liq ma'lumotlar bilan CIF yaratiladi, CIF raqam generatsiya qilinadi", 4160), c("BP-001, BR-001", 2200)
    ]}),
    new TableRow({ children: [
      c("2", 800, { center: true, shaded: true }), c("YuSh yaratish", 2200, { shaded: true }),
      c("To'liq ma'lumotlar bilan CIF yaratiladi, OKED va reg. ma'lumotlar saqlanadi", 4160, { shaded: true }), c("BP-001, BR-010", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("3", 800, { center: true }), c("Dublikat PINFL", 2200),
      c("Xatolik: bu PINFL tizimda mavjud", 4160), c("BR-002", 2200)
    ]}),
    new TableRow({ children: [
      c("4", 800, { center: true, shaded: true }), c("Dublikat STIR", 2200, { shaded: true }),
      c("Xatolik: bu STIR tizimda mavjud", 4160, { shaded: true }), c("BR-003", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("5", 800, { center: true }), c("17 yoshli FYaSh", 2200),
      c("Xatolik: yosh 18 dan kichik", 4160), c("BR-008", 2200)
    ]}),
    new TableRow({ children: [
      c("6", 800, { center: true, shaded: true }), c("PEP = Ha", 2200, { shaded: true }),
      c("risk_category avtomatik HIGH ga o'rnatiladi", 4160, { shaded: true }), c("BR-013", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("7", 800, { center: true }), c("FAOL → BLOKLANGAN", 2200),
      c("Holat o'zgaradi, sabab audit log ga yoziladi", 4160), c("BR-005,007", 2200)
    ]}),
    new TableRow({ children: [
      c("8", 800, { center: true, shaded: true }), c("YOPIQ → FAOL", 2200, { shaded: true }),
      c("Xatolik: YOPIQ dan qaytish mumkin emas", 4160, { shaded: true }), c("BR-005", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("9", 800, { center: true }), c("Ma'lumot yangilash", 2200),
      c("O'zgarish saqlanadi, audit log da eski/yangi qiymatlar", 4160), c("BR-015", 2200)
    ]}),
    new TableRow({ children: [
      c("10", 800, { center: true, shaded: true }), c("Qidiruv: FIO", 2200, { shaded: true }),
      c("Qisman moslik natijalar ro'yxatda ko'rsatiladi", 4160, { shaded: true }), c("BP-003", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("11", 800, { center: true }), c("Noto'g'ri telefon", 2200),
      c("Xatolik: telefon formati noto'g'ri", 4160), c("BR-009", 2200)
    ]}),
    new TableRow({ children: [
      c("12", 800, { center: true, shaded: true }), c("Muddati o'tgan hujjat", 2200, { shaded: true }),
      c("Ogohlantirish ko'rsatiladi", 4160, { shaded: true }), c("BR-014", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("13", 800, { center: true }), c("Maker-Checker: yaratish", 2200),
      c("Yangi mijoz PENDING holatda yaratiladi, approved_by = NULL", 4160), c("BR-020,021", 2200)
    ]}),
    new TableRow({ children: [
      c("14", 800, { center: true, shaded: true }), c("Maker-Checker: tasdiqlash", 2200, { shaded: true }),
      c("Supervisor tasdiqlaydi: PENDING → ACTIVE, approved_by to'ldiriladi", 4160, { shaded: true }), c("BR-020", 2200, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("15", 800, { center: true }), c("Maker = Checker", 2200),
      c("Xatolik: bir kishi ham yaratib, ham tasdiqlay olmaydi", 4160), c("BR-020", 2200)
    ]}),
    new TableRow({ children: [
      c("16", 800, { center: true, shaded: true }), c("Maker-Checker: rad etish", 2200, { shaded: true }),
      c("Supervisor rad etadi: PENDING → o'chiriladi + sabab audit logga yoziladi", 4160, { shaded: true }), c("BR-020", 2200, { shaded: true })
    ]}),
  ]}),
  sp(200),
];

// ===== 9. AMALGA OSHIRISH REJASI =====
const section9 = [
  h("9. Amalga oshirish rejasi", HeadingLevel.HEADING_1),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [800, 1600, 3960, 3000], rows: [
    new TableRow({ children: [hCell("#", 800), hCell("Bosqich", 1600), hCell("Vazifalar", 3960), hCell("Natija", 3000)] }),
    new TableRow({ children: [
      c("1", 800, { center: true }), c("DB", 1600),
      c("DDL skriptlar: jadvallar, indekslar, sequence, seed data", 3960), c("Ishlaydigan DB schema", 3000)
    ]}),
    new TableRow({ children: [
      c("2", 800, { center: true, shaded: true }), c("Model", 1600, { shaded: true }),
      c("POJO sinflari, enum'lar", 3960, { shaded: true }), c("Java model qatlami", 3000, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("3", 800, { center: true }), c("DAO", 1600),
      c("CRUD operatsiyalari, qidiruv, audit log", 3960), c("Ma'lumotlar qatlami", 3000)
    ]}),
    new TableRow({ children: [
      c("4", 800, { center: true, shaded: true }), c("Validatsiya", 1600, { shaded: true }),
      c("CifValidator, CifNumberGenerator", 3960, { shaded: true }), c("Biznes qoidalar", 3000, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("5", 800, { center: true }), c("Servlet", 1600),
      c("CustomerServlet routing, doGet/doPost", 3960), c("Controller qatlami", 3000)
    ]}),
    new TableRow({ children: [
      c("6", 800, { center: true, shaded: true }), c("JSP", 1600, { shaded: true }),
      c("Ro'yxat, forma, tafsilot, holat o'zgartirish sahifalari", 3960, { shaded: true }), c("Foydalanuvchi interfeysi", 3000, { shaded: true })
    ]}),
    new TableRow({ children: [
      c("7", 800, { center: true }), c("Test", 1600),
      c("Test stsenariylar bo'yicha qo'lda test", 3960), c("Sifat ta'minoti", 3000)
    ]}),
  ]}),
  sp(300),

  // === TASDIQLASH ===
  h("Tasdiqlash", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 3480, 3480], rows: [
    new TableRow({ children: [hCell("Rol", 2400), hCell("FIO", 3480), hCell("Imzo / Sana", 3480)] }),
    new TableRow({ children: [c("Tayyorladi", 2400), c("", 3480), c("", 3480)] }),
    new TableRow({ children: [c("Tekshirdi", 2400, { shaded: true }), c("", 3480, { shaded: true }), c("", 3480, { shaded: true })] }),
    new TableRow({ children: [c("Tasdiqladi", 2400), c("", 3480), c("", 3480)] }),
  ]}),
];

// ===== DOCUMENT ASSEMBLY =====
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: BLUE },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: BLUE },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: DARK_GRAY },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: { config: [
    { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
  ]},
  sections: [{
    properties: {
      page: { size: { width: PAGE_WIDTH, height: PAGE_HEIGHT }, margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN } }
    },
    headers: { default: new Header({ children: [new Paragraph({
      alignment: AlignmentType.RIGHT,
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
      children: [new TextRun({ text: "MARS ABS  |  TZ-001  |  core_cif", font: "Arial", size: 18, color: "999999" })]
    })] }) },
    footers: { default: new Footer({ children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      border: { top: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
      children: [
        new TextRun({ text: "Fido Bank  |  MARS ABS  |  Konfidensial  |  Sahifa ", font: "Arial", size: 16, color: "999999" }),
        new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16, color: "999999" }),
      ]
    })] }) },
    children: [
      ...titlePage, ...tocSection,
      ...section1,
      new Paragraph({ children: [new PageBreak()] }),
      ...section2,
      new Paragraph({ children: [new PageBreak()] }),
      ...section3,
      new Paragraph({ children: [new PageBreak()] }),
      ...section4,
      ...section5,
      new Paragraph({ children: [new PageBreak()] }),
      ...section6,
      new Paragraph({ children: [new PageBreak()] }),
      ...section7,
      ...section8,
      ...section9,
    ]
  }]
});

const OUT = "/Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project/docs/TZ-001_core_cif_texnik_topshiriq.docx";
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUT, buf);
  console.log(`Generated: ${OUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

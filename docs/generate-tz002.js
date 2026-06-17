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
function num(t) { return new Paragraph({ numbering: { reference: "numbers", level: 0 }, children: [new TextRun({ text: t, font: "Arial", size: 22 })] }); }
function code(t) {
  return new Paragraph({ spacing: { after: 40 }, shading: codeShade,
    children: [new TextRun({ text: t || " ", font: "Courier New", size: 18, color: DARK_GRAY })] });
}
function sp(a = 100) { return new Paragraph({ spacing: { after: a }, children: [] }); }

// DB table helper - 6-column layout: Ustun | Tur | Hajm | Cheklov | NULL | Tavsif
function dbTable(title, rows) {
  const colW = [1700, 1250, 850, 1300, 700, 3560];
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

// API table helper - 3-column: Element | <c2> | Tavsif  (procedures/functions)
function apiTable(title, c2label, rows, level = HeadingLevel.HEADING_2) {
  const colW = [3400, 2200, 3760];
  const header = new TableRow({ children: [hCell("Nomi", colW[0]), hCell(c2label, colW[1]), hCell("Tavsif", colW[2])] });
  const dataRows = rows.map((r, i) => {
    const shaded = i % 2 === 1;
    return new TableRow({ children: [
      c(r[0], colW[0], { code: true, shaded }), c(r[1], colW[1], { shaded }), c(r[2], colW[2], { shaded })
    ]});
  });
  return [
    h(title, level),
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
    children: [new TextRun({ text: "TZ-002: Hisoblar moduli (core_acc)", font: "Arial", size: 28, color: DARK_GRAY })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
    children: [new TextRun({ text: "Accounts Management — Texnik loyiha", font: "Arial", size: 24, italics: true, color: "666666" })] }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({ width: { size: 5000, type: WidthType.DXA }, columnWidths: [2000, 3000], rows: [
    new TableRow({ children: [c("Hujjat raqami:", 2000, { bold: true }), c("TZ-002", 3000)] }),
    new TableRow({ children: [c("Versiya:", 2000, { bold: true, shaded: true }), c("1.0", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Sana:", 2000, { bold: true }), c("2026-06-16", 3000)] }),
    new TableRow({ children: [c("Modul:", 2000, { bold: true, shaded: true }), c("core_acc (Hisoblar)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Asoslanadi:", 2000, { bold: true }), c("BT-002 v1.0", 3000)] }),
    new TableRow({ children: [c("Arxitektura:", 2000, { bold: true, shaded: true }), c("JSP + Mars + PL/SQL (servletsiz)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Holat:", 2000, { bold: true }), c("Qoralama", 3000)] }),
    new TableRow({ children: [c("Muallif:", 2000, { bold: true, shaded: true }), c("MARS loyiha guruhi", 3000, { shaded: true })] }),
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
  p("Ushbu hujjat BT-002 (Hisoblar moduli biznes talablari) asosida tayyorlangan texnik topshiriq bo'lib, core_acc modulining texnik amalga oshirilish tafsilotlarini belgilaydi: ma'lumotlar bazasi strukturasi, PL/SQL paketlari (SIRIUS qatlam arxitekturasi), view'lar, JSP sahifalar va Mars integratsiyasi."),
  p("Modul core_cif (Mijozlar) moduli bilan bir xil arxitektura va pattern'larni qayta ishlatadi: bir xil tag library, Mars helper, datagrid, modal va dizayn tizimi."),

  h("1.2. Arxitektura tamoyili — SERVLETSIZ, APIsiz", HeadingLevel.HEADING_2),
  p("MARS ABS klassik servlet/DAO arxitekturasidan FOYDALANMAYDI. UI butunlay JSP da, biznes logika Oracle PL/SQL paketlarida. JSP sahifalar Oracle procedure/function/view'larni JDBC orqali to'g'ridan-to'g'ri chaqiradi.", { bold: true }),
  sp(),
  p("Ma'lumotlar oqimi (data flow):", { bold: true }),
  code("  JSP sahifa"),
  code("    ├── Mars.procedure(\"core_acc_service.Open_Account\")   ← PL/SQL procedure"),
  code("    │       .record(\"io_account\", \"core_acc_types.t_account_rec\")"),
  code("    │       .outNumber(\"code\").outString(\"message\").execute()"),
  code("    ├── <t:table view=\"core_acc_accounts_ui_v\">           ← Oracle view"),
  code("    │       <t:grid pageSize=\"20\"> ... </t:grid>"),
  code("    └── AbsDb.getConnection()                             ← HikariCP pool"),
  sp(),
  p("Oqim: JSP → Mars/AbsDb → Oracle PL/SQL (SIRIUS qatlamlar) → JSP (JSTL render). Hech qanday servlet, REST API yoki ORM yo'q.", { italic: true }),

  h("1.3. Texnologiyalar steki", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3000, 6360], rows: [
    new TableRow({ children: [hCell("Texnologiya", 3000), hCell("Versiya / Tavsif", 6360)] }),
    new TableRow({ children: [c("Dasturlash tili", 3000), c("Java 17 (Temurin JDK, compile target 17)", 6360)] }),
    new TableRow({ children: [c("UI qatlami", 3000, { shaded: true }), c("JSP 2.3 + JSTL 1.2.5 (scriptlet faqat Mars chaqiruvi uchun)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Servlet API", 3000), c("4.0.1 (provided — faqat konteyner, biznes servlet yo'q)", 6360)] }),
    new TableRow({ children: [c("Ma'lumotlar bazasi", 3000, { shaded: true }), c("Oracle XE 21c (Docker: gvenzl/oracle-xe:21-slim)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("JDBC driver", 3000), c("ojdbc11 23.3 (Java 17+ uchun)", 6360)] }),
    new TableRow({ children: [c("Connection pool", 3000, { shaded: true }), c("HikariCP 5.1 (max 10 ulanish)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Ilovalar serveri", 3000), c("Apache Tomcat 9 (ROOT context)", 6360)] }),
    new TableRow({ children: [c("Build tizimi", 3000, { shaded: true }), c("Apache Maven 3.9.6 (2 ta pom: WAR + abs-core-lib JAR)", 6360, { shaded: true })] }),
    new TableRow({ children: [c("Custom kutubxona", 3000), c("abs-core-lib (uz.fido.abs:abs-core-lib:1.0.0) — Mars + tag library v6", 6360)] }),
    new TableRow({ children: [c("UI dizayn", 3000, { shaded: true }), c("Custom CSS + vanilla JS (Inter, slate+indigo) — framework yo'q", 6360, { shaded: true })] }),
  ]}),

  h("1.4. Nomlash konvensiyalari", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2600, 3380, 3380], rows: [
    new TableRow({ children: [hCell("Element", 2600), hCell("Qoida", 3380), hCell("Misol", 3380)] }),
    new TableRow({ children: [c("Jadval", 2600), c("core_acc_{nom}", 3380), c("core_acc_accounts", 3380)] }),
    new TableRow({ children: [c("View", 2600, { shaded: true }), c("core_acc_{nom}_{usage}_v", 3380, { shaded: true }), c("core_acc_accounts_ui_v", 3380, { shaded: true })] }),
    new TableRow({ children: [c("Paket", 2600), c("core_acc_{qatlam}", 3380), c("core_acc_service", 3380)] }),
    new TableRow({ children: [c("PK / UK", 2600, { shaded: true }), c("{jadval}_pk / _uk", 3380, { shaded: true }), c("core_acc_accounts_pk", 3380, { shaded: true })] }),
    new TableRow({ children: [c("FK", 2600), c("{jadval}_{ref}_fk", 3380), c("core_acc_accounts_cust_fk", 3380)] }),
    new TableRow({ children: [c("CHECK", 2600, { shaded: true }), c("{jadval}_{qoida}_ck", 3380, { shaded: true }), c("core_acc_accounts_status_ck", 3380, { shaded: true })] }),
    new TableRow({ children: [c("Index", 2600), c("{jadval}_{ustun}_idx", 3380), c("core_acc_accounts_cust_idx", 3380)] }),
    new TableRow({ children: [c("Sequence", 2600, { shaded: true }), c("core_acc_{nom}_seq", 3380, { shaded: true }), c("core_acc_number_seq", 3380, { shaded: true })] }),
    new TableRow({ children: [c("Trigger", 2600), c("{jadval}_{event}_trg", 3380), c("core_acc_accounts_bi_trg", 3380)] }),
    new TableRow({ children: [c("JSP fayl", 2600, { shaded: true }), c("kebab-case.jsp", 3380, { shaded: true }), c("account-create.jsp", 3380, { shaded: true })] }),
    new TableRow({ children: [c("PL/SQL parametr", 2600), c("i_ (IN), o_ (OUT), io_ (IN OUT)", 3380), c("i_account_id, o_code", 3380)] }),
    new TableRow({ children: [c("PL/SQL local/const", 2600, { shaded: true }), c("v_ (local), c_ (const), cr_ (cursor)", 3380, { shaded: true }), c("v_balance, c_status_active", 3380, { shaded: true })] }),
  ]}),

  h("1.5. SIRIUS qatlam arxitekturasi", HeadingLevel.HEADING_2),
  p("Barcha PL/SQL kodi SIRIUS qatlam arxitekturasiga amal qiladi (plsql-rules.md, qoida L-1). Bog'liqlik yo'nalishi qat'iy: yuqori qatlam faqat pastki qatlamni chaqiradi."),
  code("  INTERFACE / API    — (core_acc da ishlatilmaydi — JSP to'g'ridan SERVICE ni chaqiradi)"),
  code("       ↓"),
  code("  SERVICE            — biznes logika + COMMIT/ROLLBACK (faqat shu qatlamda)"),
  code("       ↓"),
  code("  RULES              — validatsiya qoidalari (DML YO'Q)"),
  code("  REPO               — CRUD / DML (COMMIT YO'Q)"),
  code("  DATA_READER        — faqat SELECT"),
  code("       ↓"),
  code("  LOGGER             — audit log (side-effect INSERT)"),
  code("  UTIL               — pure yordamchi funksiyalar"),
  code("  TYPES / CONST      — record type'lar va konstantalar"),
  sp(),
  p("Tegishli qoidalar: E-5 (COMMIT/ROLLBACK faqat SERVICE), SC-1 (_service paketda o_code/o_message/o_ora_message majburiy), SC-2 (OUT parametrlarni boshida init), V-1 (view WITH READ ONLY), S-1 (bind o'zgaruvchi, || yo'q).", { italic: true }),
  sp(200),
];

// ===== 2. MA'LUMOTLAR BAZASI =====
const section2 = [
  h("2. Ma'lumotlar bazasi strukturasi", HeadingLevel.HEADING_1),
  p("Barcha obyektlar bankuser sxemasida yaratiladi. Jadval nomlari core_acc_ prefiksi bilan boshlanadi. Init skript: docker/oracle/init/ papkasida (11–14 raqamli fayllar)."),

  h("2.1. ER diagramma", HeadingLevel.HEADING_2),
  p("Jadvallar orasidagi bog'lanishlar:"),
  code("core_cif_customers (1) ──< (N) core_acc_accounts       [FK: customer_id]"),
  code("core_acc_accounts  (1) ──< (N) core_acc_signatories    [FK: account_id]"),
  code("core_acc_accounts  (1) ──< (N) core_acc_audit_log      [FK: account_id]"),
  sp(),
  p("Eslatma: core_acc_accounts.customer_id → core_cif_customers.customer_id (modullararo bog'lanish). Hisob faqat mavjud va FAOL mijozga ochiladi (BR-001).", { italic: true }),

  // --- 2.2 core_acc_accounts ---
  h("2.2. core_acc_accounts", HeadingLevel.HEADING_2),
  p("Asosiy hisoblar jadvali. Barcha hisob turlari (joriy, jamg'arma, depozit, kredit, maxsus) bitta jadvalda, account_type ustuni orqali farqlanadi. Maker-Checker: DEFAULT status = 'PENDING'."),
  ...dbTable("2.2.1. Ustunlar", [
    ["account_id",        "NUMBER",    "—",    "PK, IDENTITY",    "NN", "Avtomatik ID (GENERATED ALWAYS AS IDENTITY)"],
    ["account_number",    "VARCHAR2",  "20",   "UNIQUE",          "NN", "20 xonali hisob raqami (trigger generatsiya)"],
    ["customer_id",       "NUMBER",    "—",    "FK→customers",    "NN", "Hisob egasi (core_cif_customers)"],
    ["account_type",      "VARCHAR2",  "20",   "CHECK",           "NN", "CURRENT|SAVINGS|DEPOSIT|LOAN|SPECIAL"],
    ["currency",          "VARCHAR2",  "3",    "CHECK",           "NN", "UZS | USD | EUR"],
    ["gl_code",           "VARCHAR2",  "5",    "—",               "NN", "Balans hisobi kodi (raqamning 1-5 xonasi)"],
    ["account_name",      "VARCHAR2",  "200",  "—",               "Y",  "Hisob nomi / tavsifi"],
    ["status",            "VARCHAR2",  "20",   "CHECK",           "NN", "PENDING|ACTIVE|FROZEN|BLOCKED|CLOSED|REJECTED"],
    ["balance",           "NUMBER",    "20,2", "DEFAULT 0",       "NN", "Joriy qoldiq (BigDecimal — double EMAS)"],
    ["available_balance", "NUMBER",    "20,2", "DEFAULT 0",       "NN", "Mavjud qoldiq (balance − bloklangan summa)"],
    ["min_balance",       "NUMBER",    "20,2", "DEFAULT 0",       "NN", "Minimal qoldiq (overdraft himoyasi, BR-010)"],
    ["daily_limit",       "NUMBER",    "20,2", "—",               "Y",  "Kunlik chiqim limiti (BR-011)"],
    ["monthly_limit",     "NUMBER",    "20,2", "—",               "Y",  "Oylik chiqim limiti"],
    ["interest_rate",     "NUMBER",    "5,2",  "—",               "Y",  "Yillik foiz stavkasi (%)"],
    ["branch_code",       "VARCHAR2",  "5",    "—",               "NN", "Filial MFO kodi"],
    ["opened_at",         "TIMESTAMP", "—",    "DEFAULT CURRENT", "NN", "Ochilgan sana/vaqt"],
    ["last_activity_at",  "TIMESTAMP", "—",    "—",               "Y",  "Oxirgi operatsiya (harakatsiz hisob — RPT-005)"],
    ["closed_at",         "TIMESTAMP", "—",    "—",               "Y",  "Yopilgan sana/vaqt"],
    ["close_reason",      "VARCHAR2",  "500",  "—",               "Y",  "Yopish sababi (BP-005)"],
    ["approved_by",       "VARCHAR2",  "50",   "—",               "Y",  "Tasdiqlagan foydalanuvchi (Checker)"],
    ["approved_at",       "TIMESTAMP", "—",    "—",               "Y",  "Tasdiqlangan vaqt"],
    ["created_by",        "VARCHAR2",  "50",   "—",               "NN", "Yaratgan foydalanuvchi (Maker)"],
    ["created_at",        "TIMESTAMP", "—",    "DEFAULT CURRENT", "NN", "Yaratilgan vaqt"],
    ["updated_by",        "VARCHAR2",  "50",   "—",               "Y",  "O'zgartirgan foydalanuvchi"],
    ["updated_at",        "TIMESTAMP", "—",    "—",               "Y",  "Oxirgi o'zgarish vaqti"],
  ]),

  h("2.2.2. CHECK cheklovlar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 6160], rows: [
    new TableRow({ children: [hCell("Cheklov nomi", 3200), hCell("Ifoda", 6160)] }),
    new TableRow({ children: [c("core_acc_accounts_type_ck", 3200), c("account_type IN ('CURRENT','SAVINGS','DEPOSIT','LOAN','SPECIAL')", 6160, { code: true })] }),
    new TableRow({ children: [c("core_acc_accounts_ccy_ck", 3200, { shaded: true }), c("currency IN ('UZS','USD','EUR')", 6160, { code: true, shaded: true })] }),
    new TableRow({ children: [c("core_acc_accounts_status_ck", 3200), c("status IN ('PENDING','ACTIVE','FROZEN','BLOCKED','CLOSED','REJECTED')", 6160, { code: true })] }),
    new TableRow({ children: [c("core_acc_accounts_bal_ck", 3200, { shaded: true }), c("balance >= min_balance  (overdraft taqiqi, BR-010)", 6160, { code: true, shaded: true })] }),
    new TableRow({ children: [c("core_acc_accounts_minbal_ck", 3200), c("min_balance >= 0", 6160, { code: true })] }),
  ]}),
  sp(),

  h("2.2.3. Indekslar", HeadingLevel.HEADING_3),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3400, 3000, 2960], rows: [
    new TableRow({ children: [hCell("Indeks nomi", 3400), hCell("Ustunlar", 3000), hCell("Turi", 2960)] }),
    new TableRow({ children: [c("core_acc_accounts_num_uk", 3400), c("account_number", 3000), c("UNIQUE (avtomatik)", 2960)] }),
    new TableRow({ children: [c("core_acc_accounts_cust_idx", 3400, { shaded: true }), c("customer_id", 3000, { shaded: true }), c("NON-UNIQUE", 2960, { shaded: true })] }),
    new TableRow({ children: [c("core_acc_accounts_status_idx", 3400), c("status", 3000), c("NON-UNIQUE", 2960)] }),
    new TableRow({ children: [c("core_acc_accounts_ccy_idx", 3400, { shaded: true }), c("currency", 3000, { shaded: true }), c("NON-UNIQUE", 2960, { shaded: true })] }),
    new TableRow({ children: [c("core_acc_accounts_branch_idx", 3400), c("branch_code", 3000), c("NON-UNIQUE", 2960)] }),
    new TableRow({ children: [c("core_acc_accounts_pending_idx", 3400, { shaded: true }), c("status, created_at", 3000, { shaded: true }), c("NON-UNIQUE (PENDING filtr)", 2960, { shaded: true })] }),
  ]}),
  sp(200),

  // --- 2.3 core_acc_signatories ---
  h("2.3. core_acc_signatories", HeadingLevel.HEADING_2),
  p("Imzo huquqiga ega shaxslar jadvali. Asosan yuridik shaxs hisoblari uchun (birinchi va ikkinchi imzo)."),
  ...dbTable("2.3.1. Ustunlar", [
    ["signatory_id",  "NUMBER",    "—",   "PK, IDENTITY",   "NN", "Avtomatik ID"],
    ["account_id",    "NUMBER",    "—",   "FK→accounts",    "NN", "Hisob ID (ON DELETE CASCADE)"],
    ["person_name",   "VARCHAR2",  "200", "—",              "NN", "Imzo huquqiga ega shaxs FIO"],
    ["person_pinfl",  "VARCHAR2",  "14",  "—",              "Y",  "Shaxs PINFL"],
    ["position",      "VARCHAR2",  "100", "—",              "Y",  "Lavozimi"],
    ["signature_type","VARCHAR2",  "10",  "CHECK",          "NN", "FIRST | SECOND (birinchi/ikkinchi imzo)"],
    ["is_active",     "CHAR",      "1",   "CHECK",          "NN", "Faol belgisi: Y | N (default Y)"],
    ["created_at",    "TIMESTAMP", "—",   "DEFAULT CURRENT","NN", "Yaratilgan vaqt"],
    ["created_by",    "VARCHAR2",  "50",  "—",              "NN", "Yaratgan foydalanuvchi"],
  ]),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3400, 5960], rows: [
    new TableRow({ children: [hCell("Cheklov", 3400), hCell("Ifoda", 5960)] }),
    new TableRow({ children: [c("core_acc_signatories_acc_fk", 3400), c("FK (account_id) → core_acc_accounts ON DELETE CASCADE", 5960, { code: true })] }),
    new TableRow({ children: [c("core_acc_signatories_type_ck", 3400, { shaded: true }), c("signature_type IN ('FIRST','SECOND')", 5960, { code: true, shaded: true })] }),
    new TableRow({ children: [c("core_acc_signatories_active_ck", 3400), c("is_active IN ('Y','N')", 5960, { code: true })] }),
  ]}),
  sp(200),

  // --- 2.4 core_acc_audit_log ---
  h("2.4. core_acc_audit_log", HeadingLevel.HEADING_2),
  p("Hisob ma'lumotlaridagi barcha o'zgarishlar tarixi (BR-012). Bu jadvalga faqat INSERT qilinadi; UPDATE/DELETE taqiqlangan (BR-014 — log o'zgartirilmaydi)."),
  ...dbTable("2.4.1. Ustunlar", [
    ["log_id",       "NUMBER",    "—",   "PK, IDENTITY",    "NN", "Avtomatik ID"],
    ["account_id",   "NUMBER",    "—",   "FK→accounts",     "NN", "Hisob ID"],
    ["action_type",  "VARCHAR2",  "20",  "CHECK",           "NN", "CREATE|UPDATE|STATUS_CHANGE|APPROVE|REJECT|CLOSE"],
    ["field_name",   "VARCHAR2",  "100", "—",               "Y",  "O'zgargan maydon nomi"],
    ["old_value",    "VARCHAR2",  "500", "—",               "Y",  "Eski qiymat"],
    ["new_value",    "VARCHAR2",  "500", "—",               "Y",  "Yangi qiymat"],
    ["reason",       "VARCHAR2",  "500", "—",               "Y",  "Sabab (holat o'zgartirish / yopish uchun)"],
    ["changed_by",   "VARCHAR2",  "50",  "—",               "NN", "O'zgartirgan foydalanuvchi"],
    ["changed_at",   "TIMESTAMP", "—",   "DEFAULT CURRENT", "NN", "O'zgarish vaqti"],
  ]),
  sp(200),

  // --- 2.5 sequence ---
  h("2.5. Sequence — core_acc_number_seq", HeadingLevel.HEADING_2),
  p("Hisob raqamining mijoz/tartib qismi (8 xona) uchun ketma-ketlik:"),
  code("CREATE SEQUENCE core_acc_number_seq"),
  code("    START WITH 1 INCREMENT BY 1"),
  code("    NOCACHE NOCYCLE;"),
  sp(),

  // --- 2.6 triggers ---
  h("2.6. Triggerlar", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 1800, 4360], rows: [
    new TableRow({ children: [hCell("Trigger", 3200), hCell("Hodisa", 1800), hCell("Vazifa", 4360)] }),
    new TableRow({ children: [c("core_acc_accounts_bi_trg", 3200), c("BEFORE INSERT", 1800), c("account_number NULL bo'lsa core_acc_util.Generate_Account_Number bilan to'ldirish; opened_at/created_at default", 4360)] }),
    new TableRow({ children: [c("core_acc_accounts_audit_trg", 3200, { shaded: true }), c("AFTER INS/UPD", 1800, { shaded: true }), c("CREATE/STATUS_CHANGE/APPROVE/UPDATE hodisalarini core_acc_audit_log ga yozish (core_cif pattern)", 4360, { shaded: true })] }),
  ]}),
  p("Eslatma: hisob raqamini SERVICE qatlamida ham, trigger'da ham generatsiya qilish mumkin. core_cif pattern'iga mos ravishda asosiy generatsiya core_acc_service.Open_Account ichida (control raqam to'g'ri hisoblanishi uchun), trigger esa zaxira (fallback) sifatida ishlaydi.", { italic: true }),

  // --- 2.7 account number format ---
  h("2.7. Hisob raqami formati va generatsiyasi", HeadingLevel.HEADING_2),
  p("Har bir hisobga 20 xonali noyob raqam tayinlanadi (BT-002 §3.5, BR-003). Tuzilishi:"),
  sp(),
  p("XXXXX-XXX-X-XXXXXXXX-XXX", { bold: true }),
  sp(),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2600, 1300, 5460], rows: [
    new TableRow({ children: [hCell("Qism", 2600), hCell("Xona", 1300), hCell("Izoh", 5460)] }),
    new TableRow({ children: [c("Balans hisobi (gl_code)", 2600), c("5", 1300, { center: true }), c("Bosh kitob (core_gl) hisobi kodi — hisob turiga bog'liq", 5460)] }),
    new TableRow({ children: [c("Hisob turi kodi", 2600, { shaded: true }), c("3", 1300, { center: true, shaded: true }), c("CURRENT=001, SAVINGS=002, DEPOSIT=003, LOAN=004, SPECIAL=005", 5460, { shaded: true })] }),
    new TableRow({ children: [c("Kontrol raqam", 2600), c("1", 1300, { center: true }), c("Tekshiruv raqami (oldingi 8 xona bo'yicha 7-3-1 vaznli MOD 10)", 5460)] }),
    new TableRow({ children: [c("Mijoz/tartib raqami", 2600, { shaded: true }), c("8", 1300, { center: true, shaded: true }), c("core_acc_number_seq → LPAD(...,8,'0')", 5460, { shaded: true })] }),
    new TableRow({ children: [c("Valyuta kodi", 2600), c("3", 1300, { center: true }), c("UZS=000, USD=840, EUR=978", 5460)] }),
  ]}),
  sp(),
  p("Generatsiya algoritmi (core_acc_util.Generate_Account_Number):", { bold: true }),
  code("FUNCTION Generate_Account_Number("),
  code("    i_account_type IN VARCHAR2,"),
  code("    i_currency     IN VARCHAR2"),
  code(") RETURN VARCHAR2 IS"),
  code("    v_gl    VARCHAR2(5)  := core_acc_util.Get_Gl_Code(i_account_type);   -- 5 xona"),
  code("    v_type  VARCHAR2(3)  := core_acc_util.Get_Type_Code(i_account_type); -- 3 xona"),
  code("    v_ccy   VARCHAR2(3)  := core_acc_util.Get_Currency_Code(i_currency); -- 3 xona"),
  code("    v_seq   VARCHAR2(8)  := LPAD(core_acc_number_seq.NEXTVAL, 8, '0');   -- 8 xona"),
  code("    v_ctrl  VARCHAR2(1);"),
  code("BEGIN"),
  code("    v_ctrl := core_acc_util.Calc_Control_Digit(v_gl || v_type);          -- 1 xona"),
  code("    RETURN v_gl || v_type || v_ctrl || v_seq || v_ccy;                   -- 20 xona"),
  code("END;"),
  sp(),
  p("Misol: 10101 001 2 00000001 000 → 10101001200000001000 (joriy hisob, UZS, 1-mijoz).", { italic: true }),
  p("Hisob raqami bir marta tayinlangandan keyin O'ZGARTIRILMAYDI va qayta ishlatilmaydi (BT-002 §3.5).", { italic: true }),
  sp(200),
];

// ===== 3. PL/SQL PAKETLAR =====
const section3 = [
  h("3. PL/SQL paket arxitekturasi (SIRIUS)", HeadingLevel.HEADING_1),
  p("core_acc moduli 8 ta paketdan iborat (core_cif bilan bir xil qatlam tuzilishi). Init skript: docker/oracle/init/12_acc_packages.sql."),

  h("3.1. Paketlar va kompilatsiya tartibi", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [600, 2800, 1500, 4460], rows: [
    new TableRow({ children: [hCell("#", 600), hCell("Paket", 2800), hCell("Qatlam", 1500), hCell("Vazifa", 4460)] }),
    new TableRow({ children: [c("1", 600, { center: true }), c("core_acc_const", 2800, { code: true }), c("CONST", 1500), c("Statuslar, turlar, valyuta/GL/tur kodlari, xato kodlari", 4460)] }),
    new TableRow({ children: [c("2", 600, { center: true, shaded: true }), c("core_acc_types", 2800, { code: true, shaded: true }), c("TYPES", 1500, { shaded: true }), c("t_account_rec, t_account_tab, t_signatory_rec", 4460, { shaded: true })] }),
    new TableRow({ children: [c("3", 600, { center: true }), c("core_acc_util", 2800, { code: true }), c("UTIL", 1500), c("Pure funksiyalar — raqam generatsiya, kod xaritalash, kontrol raqam", 4460)] }),
    new TableRow({ children: [c("4", 600, { center: true, shaded: true }), c("core_acc_logger", 2800, { code: true, shaded: true }), c("LOGGER", 1500, { shaded: true }), c("Audit log yozish/o'qish", 4460, { shaded: true })] }),
    new TableRow({ children: [c("5", 600, { center: true }), c("core_acc_data_reader", 2800, { code: true }), c("DATA_READER", 1500), c("Faqat SELECT (core_acc_accounts)", 4460)] }),
    new TableRow({ children: [c("6", 600, { center: true, shaded: true }), c("core_acc_repo", 2800, { code: true, shaded: true }), c("REPO", 1500, { shaded: true }), c("Faqat DML (INSERT/UPDATE) — COMMIT yo'q", 4460, { shaded: true })] }),
    new TableRow({ children: [c("7", 600, { center: true }), c("core_acc_rules", 2800, { code: true }), c("RULES", 1500), c("Validatsiya (DML yo'q) — data_reader ishlatadi", 4460)] }),
    new TableRow({ children: [c("8", 600, { center: true, shaded: true }), c("core_acc_service", 2800, { code: true, shaded: true }), c("SERVICE", 1500, { shaded: true }), c("Biznes logika + COMMIT/ROLLBACK — barcha qatlamni ishlatadi", 4460, { shaded: true })] }),
  ]}),

  h("3.2. core_acc_const — konstantalar", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3400, 5960], rows: [
    new TableRow({ children: [hCell("Guruh", 3400), hCell("Konstantalar", 5960)] }),
    new TableRow({ children: [c("Statuslar", 3400), c("c_status_pending/active/frozen/blocked/closed/rejected", 5960, { code: true })] }),
    new TableRow({ children: [c("Hisob turlari", 3400, { shaded: true }), c("c_type_current/savings/deposit/loan/special", 5960, { code: true, shaded: true })] }),
    new TableRow({ children: [c("Valyutalar", 3400), c("c_ccy_uzs='UZS', c_ccy_usd='USD', c_ccy_eur='EUR'", 5960, { code: true })] }),
    new TableRow({ children: [c("Valyuta kodlari", 3400, { shaded: true }), c("c_ccy_code_uzs='000', _usd='840', _eur='978'", 5960, { code: true, shaded: true })] }),
    new TableRow({ children: [c("Tur kodlari (3)", 3400), c("c_typecode_current='001' ... c_typecode_special='005'", 5960, { code: true })] }),
    new TableRow({ children: [c("GL kodlari (5)", 3400, { shaded: true }), c("c_gl_current='10101' ... (core_gl integratsiyada aniqlanadi)", 5960, { code: true, shaded: true })] }),
    new TableRow({ children: [c("Xato kodlari", 3400), c("c_err_* : −20101 .. −20120 (E-7: −20000..−20999)", 5960, { code: true })] }),
    new TableRow({ children: [c("Xato xabarlari", 3400, { shaded: true }), c("c_msg_* + c_msg_ok='OK'; c_code_ok=0, c_code_error=−1", 5960, { code: true, shaded: true })] }),
  ]}),
  p("Asosiy xato kodlari: −20101 customer_not_found, −20102 customer_not_active, −20103 kyc_incomplete, −20104 invalid_status_change, −20105 balance_not_zero, −20106 pending_trx_exists, −20107 maker_equals_checker, −20108 account_not_found, −20109 not_pending, −20110 below_min_balance.", { italic: true }),

  ...apiTable("3.3. core_acc_types — record type'lar", "Tur", [
    ["t_account_rec", "RECORD", "core_acc_accounts ustunlari (%TYPE bilan) — barcha qatlamlar ishlatadi"],
    ["t_account_tab", "TABLE OF", "t_account_rec jadval tipi (ko'p qatorli natija)"],
    ["t_signatory_rec", "RECORD", "core_acc_signatories ustunlari (%TYPE)"],
  ]),

  ...apiTable("3.4. core_acc_util — pure funksiyalar", "Qaytaradi", [
    ["Generate_Account_Number(i_type, i_ccy)", "VARCHAR2", "20 xonali hisob raqami (§2.7 algoritmi)"],
    ["Get_Gl_Code(i_type)", "VARCHAR2", "Hisob turiga mos 5 xonali GL kodi"],
    ["Get_Type_Code(i_type)", "VARCHAR2", "3 xonali hisob turi kodi (001..005)"],
    ["Get_Currency_Code(i_ccy)", "VARCHAR2", "3 xonali valyuta kodi (000/840/978)"],
    ["Calc_Control_Digit(i_digits)", "VARCHAR2", "1 xonali kontrol raqam (7-3-1 vaznli MOD 10)"],
    ["Is_Valid_Account_Number(i_num)", "BOOLEAN", "20 xona + kontrol raqam tekshiruvi"],
    ["Format_Account(i_num)", "VARCHAR2", "Ko'rinish uchun formatlash (XXXXX XXX X ...)"],
  ]),

  ...apiTable("3.5. core_acc_logger — audit log", "Tur", [
    ["Log_Audit(i_account_id, i_action_type, i_field_name, i_old, i_new, i_reason, i_changed_by)", "PROCEDURE", "Audit log yozish (INSERT, COMMIT yo'q)"],
    ["Find_By_Account(i_account_id, i_page, i_page_size, o_results)", "PROCEDURE", "Hisob bo'yicha audit log (SYS_REFCURSOR)"],
    ["Count_By_Account(i_account_id)", "FUNCTION", "Hisob bo'yicha log soni"],
  ]),

  ...apiTable("3.6. core_acc_data_reader — faqat SELECT", "Qaytaradi", [
    ["Get_Account(i_account_id, o_account)", "PROCEDURE", "ID bo'yicha hisob (t_account_rec)"],
    ["Find_By_Number(i_account_number, o_account)", "PROCEDURE", "Raqam bo'yicha hisob"],
    ["Find_By_Customer(i_customer_id, o_results)", "PROCEDURE", "Mijozning barcha hisoblari (SYS_REFCURSOR)"],
    ["Account_Exists(i_account_id)", "FUNCTION (BOOLEAN)", "Hisob mavjudligini tekshirish"],
    ["Get_Balance(i_account_id)", "FUNCTION (NUMBER)", "Joriy qoldiq"],
    ["Has_Pending_Trx(i_account_id)", "FUNCTION (BOOLEAN)", "Kutilayotgan tranzaksiya bormi (core_trx; hozircha FALSE — stub)"],
    ["Count_All / Count_By_Status(i_status)", "FUNCTION (NUMBER)", "Hisoblar soni"],
  ]),

  ...apiTable("3.7. core_acc_repo — faqat DML (COMMIT yo'q)", "Tur", [
    ["Insert_Account(io_account)", "PROCEDURE", "INSERT — account_id va account_number ni qaytaradi"],
    ["Update_Account(i_account)", "PROCEDURE", "UPDATE — tahrirlanadigan maydonlar (limit, nom, parametr)"],
    ["Update_Status(i_account_id, i_status, i_user)", "PROCEDURE", "Holat o'zgartirish (status + updated_by/at)"],
    ["Update_Balance(i_account_id, i_balance, i_avail)", "PROCEDURE", "Qoldiq yangilash (core_trx tomonidan chaqiriladi)"],
    ["Set_Approved(i_account_id, i_approved_by)", "PROCEDURE", "PENDING→ACTIVE + approved_by/at"],
    ["Set_Closed(i_account_id, i_reason, i_user)", "PROCEDURE", "Yopish — status=CLOSED, closed_at, close_reason"],
  ]),

  ...apiTable("3.8. core_acc_rules — validatsiya (DML yo'q)", "Qaytaradi", [
    ["Check_Customer_Eligible(i_customer_id, o_code, o_message)", "PROCEDURE", "Mijoz mavjud + ACTIVE + KYC to'liq (BR-001, BR-002)"],
    ["Validate_Open(i_account, o_code, o_message)", "PROCEDURE", "Hisob ochish validatsiyasi (tur, valyuta, mijoz)"],
    ["Validate_Update(i_account, o_code, o_message)", "PROCEDURE", "Tahrir validatsiyasi (raqam/valyuta/tur o'zgarmaydi)"],
    ["Validate_Status_Change(i_curr, i_new, o_code, o_message)", "PROCEDURE", "Holat o'tishi ruxsatini tekshirish (§6.2 matritsa)"],
    ["Validate_Close(i_account_id, o_code, o_message)", "PROCEDURE", "Yopish sharti: balance=0 + pending_trx yo'q (BR-005, BR-006)"],
    ["Check_Maker_Checker(i_account_id, i_checker, o_code, o_message)", "PROCEDURE", "created_by ≠ approver (BR-013)"],
  ]),

  h("3.9. core_acc_service — biznes logika", HeadingLevel.HEADING_2),
  p("SERVICE qatlami — yagona COMMIT/ROLLBACK joyi (E-5). Har bir public procedure SC-1 bo'yicha o_code/o_message/o_ora_message OUT parametrlariga ega va SC-2 bo'yicha ularni boshida init qiladi (o_code:=0; o_message:='OK')."),
  ...apiTable("3.9.1. Public procedure'lar", "Asosiy IN", [
    ["Open_Account(io_account, o_code, o_message, o_ora_message)", "t_account_rec", "Validate→raqam generatsiya→INSERT→audit→COMMIT. PENDING holatda yaratadi"],
    ["Update_Account(io_account, o_code, o_message, o_ora_message)", "t_account_rec", "Limit/nom/parametrlarni yangilash (raqam/valyuta/tur o'zgarmaydi)"],
    ["Change_Status(i_account_id, i_new_status, i_reason, i_user, o_code, o_message, o_ora_message)", "NUMBER + VARCHAR2", "Holat o'zgartirish (freeze/block/unfreeze) — matritsa tekshiruvi + sabab"],
    ["Approve_Account(i_account_id, i_checker, o_code, o_message, o_ora_message)", "NUMBER + VARCHAR2", "Maker-Checker: PENDING→ACTIVE (created_by ≠ checker)"],
    ["Reject_Account(i_account_id, i_checker, i_reason, o_code, ...)", "NUMBER + VARCHAR2", "PENDING→REJECTED + sabab"],
    ["Close_Account(i_account_id, i_reason, i_user, o_code, ...)", "NUMBER + VARCHAR2", "Yopish: balance=0 tekshiruv → CLOSED (qaytmas)"],
  ], HeadingLevel.HEADING_3),
  sp(),
  p("Service procedure namuna imzosi (Mars rekord pattern'iga mos):", { bold: true }),
  code("PROCEDURE Open_Account("),
  code("    io_account     IN OUT core_acc_types.t_account_rec,  -- OUT: account_id, account_number"),
  code("    o_code         OUT NUMBER,"),
  code("    o_message      OUT VARCHAR2,"),
  code("    o_ora_message  OUT VARCHAR2"),
  code(");"),
  sp(200),
];

// ===== 4. VIEW'LAR =====
const section4 = [
  h("4. View'lar", HeadingLevel.HEADING_1),
  p("View'lar tag library (t:table) orqali UI ga data beradi. Qoidalar: V-1 (WITH READ ONLY), V-2 (aniq ustunlar, SELECT * yo'q), N-7 (nomlash _ui_v / _i_v), V-4 (paket funksiyasi DUAL wrapper bilan). Init skript: docker/oracle/init/13_acc_views.sql."),

  h("4.1. View ro'yxati", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3400, 1500, 4460], rows: [
    new TableRow({ children: [hCell("View", 3400), hCell("Ekran", 1500), hCell("Vazifa", 4460)] }),
    new TableRow({ children: [c("core_acc_accounts_ui_v", 3400, { code: true }), c("SCR-001", 1500), c("Ro'yxat — qisqa ma'lumot + mijoz nomi (CIF join)", 4460)] }),
    new TableRow({ children: [c("core_acc_active_accounts_ui_v", 3400, { code: true, shaded: true }), c("SCR-001", 1500, { shaded: true }), c("Faqat ACTIVE hisoblar (operator ish ekrani)", 4460, { shaded: true })] }),
    new TableRow({ children: [c("core_acc_pending_accounts_ui_v", 3400, { code: true }), c("Maker-Chk", 1500), c("PENDING hisoblar — supervisor tasdiqlash", 4460)] }),
    new TableRow({ children: [c("core_acc_account_detail_i_v", 3400, { code: true, shaded: true }), c("SCR-003", 1500, { shaded: true }), c("To'liq tafsilot (barcha maydon + mijoz ma'lumoti)", 4460, { shaded: true })] }),
    new TableRow({ children: [c("core_acc_dormant_accounts_ui_v", 3400, { code: true }), c("RPT-005", 1500), c("Harakatsiz hisoblar (last_activity_at > 90 kun)", 4460)] }),
    new TableRow({ children: [c("core_acc_currency_stats_v", 3400, { code: true, shaded: true }), c("RPT-003", 1500, { shaded: true }), c("Valyuta bo'yicha: soni, umumiy/o'rtacha qoldiq", 4460, { shaded: true })] }),
  ]}),

  h("4.2. core_acc_accounts_ui_v — asosiy ro'yxat ko'rinishi", HeadingLevel.HEADING_2),
  p("Ustunlar: account_id, account_number, customer_id, display_name (CIF dan — FYaSh: Familiya I.O., YuSh: org_name), account_type, currency, balance, status, branch_code, opened_at."),
  code("CREATE OR REPLACE VIEW core_acc_accounts_ui_v AS"),
  code("SELECT a.account_id, a.account_number, a.customer_id,"),
  code("       CASE WHEN c.customer_type = 'INDIVIDUAL'"),
  code("            THEN c.last_name||' '||SUBSTR(c.first_name,1,1)||'.'"),
  code("            ELSE c.org_name END        AS display_name,"),
  code("       a.account_type, a.currency, a.balance, a.status,"),
  code("       a.branch_code, a.opened_at"),
  code("  FROM core_acc_accounts a"),
  code("  JOIN core_cif_customers c ON c.customer_id = a.customer_id"),
  code("WITH READ ONLY;"),
  sp(),
  p("Tafsilot ko'rinishi (core_acc_account_detail_i_v) barcha ustunlar + mijoz tafsilotlari (CIF join) + imzo huquqi sonini o'z ichiga oladi. Foiz va qoldiq formatlash UI da JSTL bilan amalga oshiriladi.", { italic: true }),
  sp(200),
];

// ===== 5. JSP SAHIFALAR =====
const section5 = [
  h("5. JSP sahifalar va Mars integratsiyasi", HeadingLevel.HEADING_1),
  p("Barcha sahifalar src/main/webapp/abs/acc/ papkasida. Chrome (sidebar+topbar) core_cif bilan bir xil: acc-header.jsp / acc-footer.jsp (cif-header pattern). Dizayn — yagona css/style.css."),

  h("5.1. Fayllar ro'yxati", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [3200, 1600, 4560], rows: [
    new TableRow({ children: [hCell("Fayl (abs/acc/)", 3200), hCell("Ekran", 1600), hCell("Tavsif", 4560)] }),
    new TableRow({ children: [c("dashboard.jsp", 3200, { code: true }), c("—", 1600), c("Modul boshqaruv paneli (stat kartalar, tezkor havola)", 4560)] }),
    new TableRow({ children: [c("account-list.jsp", 3200, { code: true, shaded: true }), c("SCR-001", 1600, { shaded: true }), c("t:table + datagrid (qidiruv, filtr, saralash, bulk status)", 4560, { shaded: true })] }),
    new TableRow({ children: [c("account-create.jsp", 3200, { code: true }), c("SCR-002", 1600), c("Mars: Open_Account (mijoz qidiruv + tur/valyuta/parametr)", 4560)] }),
    new TableRow({ children: [c("account-detail.jsp", 3200, { code: true, shaded: true }), c("SCR-003", 1600, { shaded: true }), c("Mars + RECORD: tafsilot, operatsiyalar, tarix tablari", 4560, { shaded: true })] }),
    new TableRow({ children: [c("account-edit.jsp", 3200, { code: true }), c("SCR-004", 1600), c("Mars: Update_Account (limit/nom/parametr)", 4560)] }),
    new TableRow({ children: [c("account-status-save.jsp", 3200, { code: true, shaded: true }), c("SCR-005", 1600, { shaded: true }), c("Handler: Mars Change_Status (modal forma)", 4560, { shaded: true })] }),
    new TableRow({ children: [c("account-approve.jsp", 3200, { code: true }), c("Maker-Chk", 1600), c("Supervisor tasdiqlash (t:table pending + Approve/Reject)", 4560)] }),
    new TableRow({ children: [c("account-bulk-save.jsp", 3200, { code: true, shaded: true }), c("—", 1600, { shaded: true }), c("Bulk status handler → Change_Status (customer-bulk-save pattern)", 4560, { shaded: true })] }),
    new TableRow({ children: [c("currency-stats.jsp", 3200, { code: true }), c("RPT-003", 1600), c("Valyuta statistikasi (core_acc_currency_stats_v)", 4560)] }),
    new TableRow({ children: [c("dormant-accounts.jsp", 3200, { code: true, shaded: true }), c("RPT-005", 1600, { shaded: true }), c("Harakatsiz hisoblar (t:table)", 4560, { shaded: true })] }),
  ]}),

  h("5.2. Mars chaqiruv namunasi — Open_Account", HeadingLevel.HEADING_2),
  p("account-create.jsp (POST) — customer-create.jsp pattern'iga mos:"),
  code("java.util.Map<String,Object> result ="),
  code("  Mars.procedure(\"core_acc_service.Open_Account\")"),
  code("      .record(\"io_account\", \"core_acc_types.t_account_rec\")"),
  code("          .field(\"customer_id\", customerId)"),
  code("          .field(\"account_type\", accountType)"),
  code("          .field(\"currency\", currency)"),
  code("          .field(\"account_name\", accountName)"),
  code("          .field(\"min_balance\", minBalance)"),
  code("          .field(\"daily_limit\", dailyLimit)"),
  code("          .field(\"monthly_limit\", monthlyLimit)"),
  code("          .field(\"branch_code\", branchCode)"),
  code("          .field(\"created_by\", createdBy)"),
  code("          .outField(\"account_id\", Types.NUMERIC)"),
  code("          .outField(\"account_number\", Types.VARCHAR)"),
  code("      .outNumber(\"code\").outString(\"message\").outString(\"ora_message\")"),
  code("      .execute();"),
  code("int code = ((Number) result.get(\"code\")).intValue();"),
  code("if (code == 0) { /* sendRedirect → account-detail.jsp?id=... */ }"),
  code("else { request.setAttribute(\"errorMsg\", (String) result.get(\"message\")); }"),
  sp(),

  h("5.3. Tag library namunasi — account-list.jsp", HeadingLevel.HEADING_2),
  code("<t:table view=\"core_acc_accounts_ui_v\" var=\"data\" orderBy=\"opened_at DESC\">"),
  code("  <t:field field=\"account_number\" title=\"Hisob raqami\"><t:filter type=\"text\"/></t:field>"),
  code("  <t:field field=\"account_type\" title=\"Turi\">"),
  code("    <t:filter type=\"select\" options=\"CURRENT:Joriy,SAVINGS:Jamg'arma,DEPOSIT:Depozit,LOAN:Kredit,SPECIAL:Maxsus\"/>"),
  code("  </t:field>"),
  code("  <t:field field=\"currency\" title=\"Valyuta\"><t:filter type=\"select\" options=\"UZS:UZS,USD:USD,EUR:EUR\"/></t:field>"),
  code("  <t:field field=\"status\" title=\"Holat\">"),
  code("    <t:filter type=\"select\" options=\"ACTIVE:Faol,FROZEN:Muzlatilgan,BLOCKED:Bloklangan,CLOSED:Yopiq\"/>"),
  code("  </t:field>"),
  code("  <t:grid pageSize=\"20\" selectable=\"true\" rowId=\"account_id\""),
  code("          saveUrl=\"${pageContext.request.contextPath}/abs/acc/account-bulk-save.jsp\""),
  code("          bulkStatus=\"FROZEN:Muzlatish,BLOCKED:Bloklash,ACTIVE:Faollashtirish\">"),
  code("    <t:col field=\"account_number\" link=\"account-detail.jsp?id={account_id}\"/>"),
  code("    <t:col field=\"balance\" align=\"right\" format=\"#,##0.00\"/>"),
  code("    <t:col field=\"status\" badge=\"ACTIVE:Faol:active,FROZEN:Muzlatilgan:pending,BLOCKED:Bloklangan:blocked\"/>"),
  code("  </t:grid>"),
  code("</t:table>"),
  sp(),

  h("5.4. Holat o'zgartirish handler — account-status-save.jsp", HeadingLevel.HEADING_2),
  code("Mars.procedure(\"core_acc_service.Change_Status\")"),
  code("    .in(\"i_account_id\", accountId).in(\"i_new_status\", newStatus)"),
  code("    .in(\"i_reason\", reason).in(\"i_user\", currentUser)"),
  code("    .outNumber(\"code\").outString(\"message\").outString(\"ora_message\")"),
  code("    .execute();"),
  sp(200),
];

// ===== 6. VALIDATSIYA VA BIZNES QOIDALAR =====
const section6 = [
  h("6. Validatsiya va biznes qoidalar", HeadingLevel.HEADING_1),
  p("BT-002 biznes qoidalari (BR-001..BR-014) qaysi qatlamda amalga oshirilishi:"),

  h("6.1. BR → amalga oshirish xaritasi", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [1100, 5260, 3000], rows: [
    new TableRow({ children: [hCell("BR", 1100), hCell("Qoida", 5260), hCell("Qayerda", 3000)] }),
    new TableRow({ children: [c("BR-001", 1100), c("Hisob faqat ACTIVE mijozga ochiladi", 5260), c("rules.Check_Customer_Eligible", 3000)] }),
    new TableRow({ children: [c("BR-002", 1100, { shaded: true }), c("Mijoz KYC to'liq bo'lishi shart", 5260, { shaded: true }), c("rules.Check_Customer_Eligible", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-003", 1100), c("Hisob raqami noyob", 5260), c("UNIQUE constraint + util generatsiya", 3000)] }),
    new TableRow({ children: [c("BR-004", 1100, { shaded: true }), c("Holat o'tish tartibi qat'iy, CLOSED qaytmas", 5260, { shaded: true }), c("rules.Validate_Status_Change", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-005", 1100), c("Yopish uchun qoldiq = 0", 5260), c("rules.Validate_Close", 3000)] }),
    new TableRow({ children: [c("BR-006", 1100, { shaded: true }), c("Yopish uchun kutilayotgan tranzaksiya yo'q", 5260, { shaded: true }), c("rules.Validate_Close (core_trx)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-007", 1100), c("BLOCKED — faqat ko'rish", 5260), c("status tekshiruvi (core_trx integratsiya)", 3000)] }),
    new TableRow({ children: [c("BR-008", 1100, { shaded: true }), c("FROZEN — faqat kirim", 5260, { shaded: true }), c("status tekshiruvi (core_trx integratsiya)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-009", 1100), c("Bir mijozda bir valyutada ko'p hisob mumkin", 5260), c("Cheklov yo'q (UNIQUE faqat raqamda)", 3000)] }),
    new TableRow({ children: [c("BR-010", 1100, { shaded: true }), c("Overdraft taqiqlangan (balance ≥ min_balance)", 5260, { shaded: true }), c("CHECK constraint + repo.Update_Balance", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-011", 1100), c("Kunlik limit oshsa supervisor tasdig'i", 5260), c("daily_limit (core_trx integratsiya)", 3000)] }),
    new TableRow({ children: [c("BR-012", 1100, { shaded: true }), c("Har bir amal audit logga yoziladi", 5260, { shaded: true }), c("logger.Log_Audit + audit_trg", 3000, { shaded: true })] }),
    new TableRow({ children: [c("BR-013", 1100), c("Maker-Checker (Operator≠Supervisor)", 5260), c("rules.Check_Maker_Checker", 3000)] }),
    new TableRow({ children: [c("BR-014", 1100, { shaded: true }), c("Audit log o'zgarmas (faqat INSERT)", 5260, { shaded: true }), c("audit_log: UPDATE/DELETE trigger taqiqi", 3000, { shaded: true })] }),
  ]}),

  h("6.2. Holat o'tish matritsasi", HeadingLevel.HEADING_2),
  p("rules.Validate_Status_Change faqat quyidagi o'tishlarga ruxsat beradi (BR-004):"),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 2400, 4560], rows: [
    new TableRow({ children: [hCell("Joriy holat", 2400), hCell("Ruxsat etilgan", 2400), hCell("Izoh", 4560)] }),
    new TableRow({ children: [c("PENDING", 2400), c("ACTIVE, REJECTED", 2400), c("Maker-Checker (Approve/Reject)", 4560)] }),
    new TableRow({ children: [c("ACTIVE", 2400, { shaded: true }), c("FROZEN, BLOCKED, CLOSED", 2400, { shaded: true }), c("CLOSED — qoldiq=0 sharti bilan", 4560, { shaded: true })] }),
    new TableRow({ children: [c("FROZEN", 2400), c("ACTIVE, BLOCKED", 2400), c("Muzlatishni qaytarish yoki bloklash", 4560)] }),
    new TableRow({ children: [c("BLOCKED", 2400, { shaded: true }), c("ACTIVE, CLOSED", 2400, { shaded: true }), c("Blokdan chiqarish yoki yopish", 4560, { shaded: true })] }),
    new TableRow({ children: [c("CLOSED", 2400), c("— (yo'q)", 2400), c("Qaytarib bo'lmaydi (terminal holat)", 4560)] }),
    new TableRow({ children: [c("REJECTED", 2400, { shaded: true }), c("— (yo'q)", 2400, { shaded: true }), c("Terminal — mijoz yangi ariza beradi", 4560, { shaded: true })] }),
  ]}),
  sp(200),
];

// ===== 7. XAVFSIZLIK =====
const section7 = [
  h("7. Xavfsizlik va Maker-Checker", HeadingLevel.HEADING_1),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [800, 3560, 5000], rows: [
    new TableRow({ children: [hCell("#", 800), hCell("Talab", 3560), hCell("Amalga oshirish", 5000)] }),
    new TableRow({ children: [c("1", 800, { center: true }), c("SQL Injection himoyasi", 3560), c("Mars bind o'zgaruvchilar (CallableStatement); PL/SQL da USING (S-1)", 5000)] }),
    new TableRow({ children: [c("2", 800, { center: true, shaded: true }), c("XSS himoyasi", 3560, { shaded: true }), c("JSTL <c:out> / tag library HTML escape", 5000, { shaded: true })] }),
    new TableRow({ children: [c("3", 800, { center: true }), c("Pul summalari", 3560), c("BigDecimal / NUMBER(20,2) — double/float HECH QACHON", 5000)] }),
    new TableRow({ children: [c("4", 800, { center: true, shaded: true }), c("Overdraft himoyasi", 3560, { shaded: true }), c("CHECK (balance ≥ min_balance) + repo tekshiruvi", 5000, { shaded: true })] }),
    new TableRow({ children: [c("5", 800, { center: true }), c("Audit trail", 3560), c("Barcha amal core_acc_audit_log ga (faqat INSERT)", 5000)] }),
    new TableRow({ children: [c("6", 800, { center: true, shaded: true }), c("Maker-Checker", 3560, { shaded: true }), c("created_by ≠ approved_by (rules.Check_Maker_Checker)", 5000, { shaded: true })] }),
    new TableRow({ children: [c("7", 800, { center: true }), c("Rol asosida kirish (RBAC)", 3560), c("Operator/Supervisor/Admin/Auditor — AuthFilter URL himoyasi", 5000)] }),
    new TableRow({ children: [c("8", 800, { center: true, shaded: true }), c("Tranzaksiya yaxlitligi", 3560, { shaded: true }), c("COMMIT/ROLLBACK faqat SERVICE qatlamda (E-5)", 5000, { shaded: true })] }),
  ]}),
  sp(),
  p("Rol huquqlari (BT-002 §5): Operator — hisob ochish (yaratish), ko'rish; Supervisor — tasdiqlash + holat o'zgartirish (muzlatish/bloklash); Administrator — hisobni yopish + sozlamalar; Auditor — faqat ko'rish + hisobotlar.", { italic: true }),
  sp(200),
];

// ===== 8. TEST STSENARIYLAR =====
const section8 = [
  h("8. Test stsenariylar", HeadingLevel.HEADING_1),
  p("Asosiy qabul test stsenariylari (BT-002 §9 mezonlariga mos). To'liq unit-testlar 14_acc_unit_tests.sql da."),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [700, 2600, 4060, 2000], rows: [
    new TableRow({ children: [hCell("#", 700), hCell("Stsenariy", 2600), hCell("Kutilgan natija", 4060), hCell("BR", 2000)] }),
    new TableRow({ children: [c("1", 700, { center: true }), c("FYaSh hisob ochish", 2600), c("PENDING hisob yaratiladi, 20 xonali raqam generatsiya", 4060), c("BP-001, BR-003", 2000)] }),
    new TableRow({ children: [c("2", 700, { center: true, shaded: true }), c("YuSh hisob ochish", 2600, { shaded: true }), c("Imzo huquqi bilan PENDING hisob yaratiladi", 4060, { shaded: true }), c("BP-001", 2000, { shaded: true })] }),
    new TableRow({ children: [c("3", 700, { center: true }), c("Bloklangan mijozga ochish", 2600), c("Xato −20102: mijoz FAOL emas", 4060), c("BR-001", 2000)] }),
    new TableRow({ children: [c("4", 700, { center: true, shaded: true }), c("Maker = Checker tasdig'i", 2600, { shaded: true }), c("Xato −20107: yaratuvchi tasdiqlay olmaydi", 4060, { shaded: true }), c("BR-013", 2000, { shaded: true })] }),
    new TableRow({ children: [c("5", 700, { center: true }), c("Supervisor tasdiqlash", 2600), c("PENDING→ACTIVE, approved_by/at to'ladi", 4060), c("BP-001, BR-013", 2000)] }),
    new TableRow({ children: [c("6", 700, { center: true, shaded: true }), c("ACTIVE→FROZEN", 2600, { shaded: true }), c("Holat o'zgaradi, sabab audit logga", 4060, { shaded: true }), c("BR-004, BR-008", 2000, { shaded: true })] }),
    new TableRow({ children: [c("7", 700, { center: true }), c("CLOSED→ACTIVE", 2600), c("Xato −20104: CLOSED dan qaytish yo'q", 4060), c("BR-004", 2000)] }),
    new TableRow({ children: [c("8", 700, { center: true, shaded: true }), c("Qoldiq > 0 da yopish", 2600, { shaded: true }), c("Xato −20105: qoldiq nolga teng emas", 4060, { shaded: true }), c("BR-005", 2000, { shaded: true })] }),
    new TableRow({ children: [c("9", 700, { center: true }), c("Qoldiq = 0 da yopish", 2600), c("CLOSED holatga o'tadi, audit logga", 4060), c("BP-005, BR-005", 2000)] }),
    new TableRow({ children: [c("10", 700, { center: true, shaded: true }), c("Overdraft urinishi", 2600, { shaded: true }), c("CHECK buzilishi: balance < min_balance taqiqlanadi", 4060, { shaded: true }), c("BR-010", 2000, { shaded: true })] }),
    new TableRow({ children: [c("11", 700, { center: true }), c("Audit log UPDATE", 2600), c("Xato: log o'zgartirib bo'lmaydi", 4060), c("BR-014", 2000)] }),
    new TableRow({ children: [c("12", 700, { center: true, shaded: true }), c("Filtr/qidiruv", 2600, { shaded: true }), c("Raqam/CIF/valyuta/tur/holat bo'yicha ishlaydi", 4060, { shaded: true }), c("BP-004", 2000, { shaded: true })] }),
  ]}),
  sp(300),

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
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    properties: { page: { size: { width: PAGE_WIDTH, height: PAGE_HEIGHT },
      margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN } } },
    headers: { default: new Header({ children: [new Paragraph({
      alignment: AlignmentType.RIGHT,
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } },
      children: [new TextRun({ text: "MARS ABS  |  TZ-002  |  core_acc", font: "Arial", size: 18, color: "999999" })]
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
      ...titlePage,
      ...tocSection,
      ...section1,
      new Paragraph({ children: [new PageBreak()] }),
      ...section2,
      new Paragraph({ children: [new PageBreak()] }),
      ...section3,
      new Paragraph({ children: [new PageBreak()] }),
      ...section4,
      new Paragraph({ children: [new PageBreak()] }),
      ...section5,
      new Paragraph({ children: [new PageBreak()] }),
      ...section6,
      new Paragraph({ children: [new PageBreak()] }),
      ...section7,
      ...section8,
    ]
  }]
});

// ===== GENERATE =====
const OUTPUT = "/Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project/docs/TZ-002_core_acc_texnik_topshiriq.docx";
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUTPUT, buf);
  console.log(`Generated: ${OUTPUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

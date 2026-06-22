const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, TableOfContents
} = require("docx");

// ===== CONSTANTS =====
const PAGE_WIDTH = 12240, PAGE_HEIGHT = 15840, MARGIN = 1440;
const CW = PAGE_WIDTH - 2 * MARGIN;
const BLUE = "1F4E79", DARK_GRAY = "333333", WHITE = "FFFFFF", BC = "B4C6E7", CODE_BG = "F5F5F5";
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
function h(t, lv) { return new Paragraph({ heading: lv, spacing: { before: 240, after: 120 }, children: [new TextRun({ text: t, font: "Arial" })] }); }
function p(t, o = {}) {
  return new Paragraph({ spacing: { after: 120 }, alignment: o.center ? AlignmentType.CENTER : AlignmentType.LEFT,
    children: [new TextRun({ text: t, font: "Arial", size: 22, bold: o.bold || false, italics: o.italic || false, color: o.color || DARK_GRAY })] });
}
function b(t) { return new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: t, font: "Arial", size: 22 })] }); }
function code(t) { return new Paragraph({ spacing: { after: 40 }, shading: codeShade, children: [new TextRun({ text: t || " ", font: "Courier New", size: 18, color: DARK_GRAY })] }); }
function sp(a = 100) { return new Paragraph({ spacing: { after: a }, children: [] }); }
function tbl(colW, header, rows) {
  const head = new TableRow({ children: header.map((t, i) => hCell(t, colW[i])) });
  const body = rows.map((r, ri) => new TableRow({ children: r.map((cell, i) => c(cell, colW[i], { shaded: ri % 2 === 1, code: i === (r._code) })) }));
  return new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: colW, rows: [head, ...body] });
}

// ===== TITLE =====
const titlePage = [
  new Paragraph({ spacing: { before: 3000 }, children: [] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: "FIDO BANK", font: "Arial", size: 44, bold: true, color: BLUE })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [new TextRun({ text: "MARS — Avtomatlashtirilgan Bank Tizimi", font: "Arial", size: 28, color: DARK_GRAY })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 }, children: [new TextRun({ text: "________________________________________", color: BLUE, font: "Arial", size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: "TEXNIK TOPSHIRIQ", font: "Arial", size: 40, bold: true, color: BLUE })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [new TextRun({ text: "TZ-003: Klientlar va Hisoblar (Клиенты и счета)", font: "Arial", size: 28, color: DARK_GRAY })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [new TextRun({ text: "Real SIRIUS-sodiq implementatsiya — mars-abs", font: "Arial", size: 24, italics: true, color: "666666" })] }),
  new Paragraph({ spacing: { before: 2000 }, children: [] }),
  new Table({ width: { size: 5200, type: WidthType.DXA }, columnWidths: [2200, 3000], rows: [
    new TableRow({ children: [c("Hujjat raqami:", 2200, { bold: true }), c("TZ-003", 3000)] }),
    new TableRow({ children: [c("Versiya:", 2200, { bold: true, shaded: true }), c("1.0 (Qoralama)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Sana:", 2200, { bold: true }), c("2026-06-22", 3000)] }),
    new TableRow({ children: [c("Modul:", 2200, { bold: true, shaded: true }), c("Клиенты и счета (CIF + ACC)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Loyiha:", 2200, { bold: true }), c("mars-abs (real build)", 3000)] }),
    new TableRow({ children: [c("Strategiya:", 2200, { bold: true, shaded: true }), c("Production-paritet (real SIRIUS)", 3000, { shaded: true })] }),
    new TableRow({ children: [c("Asoslanadi:", 2200, { bold: true }), c("SIRIUS Confluence spec (Счета, Физлицо, Юрлицо/ИП)", 3000)] }),
    new TableRow({ children: [c("Muallif:", 2200, { bold: true, shaded: true }), c("MARS loyiha guruhi", 3000, { shaded: true })] }),
  ]}),
  new Paragraph({ children: [new PageBreak()] })
];
const tocSection = [ h("Mundarija", HeadingLevel.HEADING_1), new TableOfContents("Mundarija", { hyperlink: true, headingStyleRange: "1-3" }), new Paragraph({ children: [new PageBreak()] }) ];

// ===== 1. UMUMIY =====
const s1 = [
  h("1. Umumiy ma'lumot", HeadingLevel.HEADING_1),
  h("1.1. Maqsad va strategik qaror", HeadingLevel.HEADING_2),
  p("Ushbu hujjat Fido Bank SIRIUS tizimining «Клиенты и счета» (Klientlar va Hisoblar) mikroservisiga SODIQ, real (production-darajadagi) implementatsiyani belgilaydi. Strategik qaror: oracle-test-project — o'quv prototipi bo'lib qoladi; real, spetsifikatsiyaga to'liq mos tizim mars-abs loyihasida quriladi."),
  p("Asos: Fido Bank Confluence spetsifikatsiyalari — «Счета», «Физическое лицо», «Юридическое лицо и индивидуальный предприниматель» (mause.fido.uz). TZ-003 shu hujjatlardagi talablarni MARS arxitekturasi (PL/SQL SIRIUS qatlamlar + JSP + Mars + tag library) ustida amalga oshirishni belgilaydi."),
  h("1.2. Qamrov", HeadingLevel.HEADING_2),
  b("Klient kartochkasi: jismoniy shaxs, yuridik shaxs, yakka tartibdagi tadbirkor (YaTT) — to'liq rekvizitlar, holatlar, jarayonlar"),
  b("Hisoblar: birlamchi (asosiy depozit) va ikkilamchi hisoblar — 20 xonali kodlash, Mod-11 kontrol kalit, holatlar, jarayonlar"),
  b("НИББД (ЦБ huzuridagi Milliy bank depozitorlari axborot bazasi) bilan majburiy integratsiya"),
  b("AML/KYC tekshiruv oqimi, «единое окно» (E-GOV/ЦГУ) orqali ro'yxat"),
  b("План счетов (COA), тип счета (produkt), субсчет, парные счета, справочниklar (СПР)"),
  h("1.3. oracle-test-project (prototip) bilan farq", HeadingLevel.HEADING_2),
  p("oracle-test-project'dagi MARS demo soddalashtirilgan (TZ-002). TZ-003 quyidagi real talablarni qo'shadi/tuzatadi: НИББД integratsiya, AML holatlari, hisob raqami formati (valyuta o'rtada) va Mod-11 kalit, birlamchi/ikkilamchi hisob, COA/produkt/субсчет, kengaytirilgan kartochkalar, единое окно. Mavjud abs-core-lib (Mars, tag library, AbsDb), CSS dizayn tizimi va SIRIUS PL/SQL qatlam arxitekturasi QAYTA ISHLATILADI.", { italic: true }),
  h("1.4. Texnologiyalar steki", HeadingLevel.HEADING_2),
  tbl([3000, 6360], ["Texnologiya", "Tafsilot"], [
    ["Til / UI", "Java 17, JSP 2.3 + JSTL 1.2.5, custom CSS + vanilla JS (servletsiz)"],
    ["DB", "Oracle XE 21c — biznes logika PL/SQL SIRIUS qatlamlarida"],
    ["Integratsiya", "Mars (PL/SQL caller), AbsDb (HikariCP); НИББД/E-GOV — tashqi servis interfeyslari"],
    ["Build/Infra", "Maven 3.9.6 (WAR + abs-core-lib JAR), Docker (Oracle + Tomcat 9)"],
  ]),
  sp(200),
];

// ===== 2. HISOB RAQAMI + KONTROL KALIT =====
const s2 = [
  h("2. Hisob raqami kodlash va kontrol kalit", HeadingLevel.HEADING_1),
  h("2.1. 20 xonali format", HeadingLevel.HEADING_2),
  p("Hisob raqami 20 xona: ", { bold: true }),
  p("CMMSS · VVV · K · XXXXXXXX · NNN", { bold: true }),
  tbl([2400, 1200, 5760], ["Qism", "Xona", "Izoh"], [
    ["CMMSS — Balans raqami", "5", "План счетов (COA): C=kategoriya (1-Aktiv, 2-Majburiyat, 3-Kapital, 4-Daromad, 5-Xarajat, 9-Balansdan tashqari), MM=asosiy hisob, SS=subhisob"],
    ["VVV — Valyuta kodi", "3", "Davlatlar va valyutalar klassifikatori (СПР 017). So'm = суммовой код 000; USD=840, EUR=978"],
    ["K — Kontrol kalit", "1", "Tizim hisoblaydi (§2.2 Mod-11 algoritm)"],
    ["XXXXXXXX — Unikal kod", "8", "Hisob ochilayotgan mijoz kodi (НИББД)"],
    ["NNN — Tartib raqami", "3", "Shu balans hisobi bo'yicha 001–999"],
  ]),
  p("MUHIM: valyuta kodi balans raqamidan KEYIN (6-8 pozitsiya), kontrol kalitdan OLDIN. (Demo'da valyuta oxirida edi — bu yerda tuzatiladi.)", { italic: true }),
  h("2.2. Kontrol kalit algoritmi (Mod-11)", HeadingLevel.HEADING_2),
  p("Kalit litsevoy hisob ro'yxatga olinganda hisoblanadi. Kombinatsiya: НКО mijoz kodi НИББД'da (8) + balans kodi (5) + valyuta kodi (3) + hisob ochilayotgan mijoz kodi (8) + tartib raqami (3)."),
  code("Misol kombinatsiya: 04654791 10101 000 9900123 001"),
  code("1-qadam:  S = (k1*k2) + (k2*k3) + (k3*k4) + ... + (k26*k27) + (k27*9)"),
  code("          (har bir belgi ASCII kodi qo'shni belgi ASCII kodiga ko'paytiriladi)"),
  code("2-qadam:  X = FLOOR(MOD(S, 11))"),
  code("3-qadam:  agar X=0 -> X=9;  agar X=1 -> X=0;  aks holda X = FLOOR(ABS(11 - X))"),
  code("Natija:   10101 000 X 9900123 001  (X = kontrol kalit)"),
  p("Tekshiruv funksiyasi (Is_Valid) xuddi shu kombinatsiyadan kalitni qayta hisoblab solishtiradi.", { italic: true }),
  h("2.3. Balans hisobini avtomatik tanlash (СПР 21)", HeadingLevel.HEADING_2),
  p("Asosiy (birlamchi depozit) hisob balans raqami mijoz tipiga qarab СПР 21 dan AVTO tanlanadi:"),
  tbl([1600, 4400, 1800, 1560], ["Tip (typeof)", "Mijoz turi", "Balans hisob", "Izoh"], [
    ["00", "Har qanday tip", "20296", "Default"],
    ["01", "Hukumat", "20202", ""],
    ["02", "Davlat tashkiloti", "20210", "qo'lda"],
    ["03", "NNT (notijorat)", "20212", ""],
    ["04", "Nobank moliya tashkiloti", "20216", ""],
    ["09", "(СПР 21 bo'yicha)", "20208", ""],
    ["11", "(СПР 21 bo'yicha)", "20218", ""],
    ["12", "Byudjet tashkiloti", "qo'lda", "asosiy hisobsiz ham mumkin"],
  ]),
  p("Eslatma: depozit hisoblar MAJBURIYAT kategoriyasida (2xxxx) — demo'dagi 10101 (aktiv) NOTO'G'RI edi. To'liq jadval СПР 21 da; bu yerda asosiylari.", { italic: true }),
  sp(200),
];

// ===== 3. COA / TIP / SUBSCHET =====
const s3 = [
  h("3. План счетов, тип счета, субсчет", HeadingLevel.HEADING_1),
  h("3.1. План счетов (COA)", HeadingLevel.HEADING_2),
  p("Balans hisoblari (CMMSS, 5 xona) Regulyator План счетов'iga (ЦБ Постановление №3336 / Hisoblar rejasi) muvofiq. Признак баланса: B=балансовый, O=внебалансовый (9xxxx kategoriya). Признак актив-пассив (liability_active) balans raqamidan avto aniqlanadi (СПР 019)."),
  h("3.2. Тип счета (produkt)", HeadingLevel.HEADING_2),
  p("«Тип счета» — alohida справочник (produkt/modul bilan bog'liq), balans hisoblariga bog'lanadi. Hisob ochishda produktdan тип AVTO meros qilinadi. Misol turlar: RASCH (hisob-kitob), SSUDA (ssuda), PERC (foiz), PROSR (muddati o'tgan), VKLAD (omonat)."),
  tbl([2600, 6760], ["Element", "Tavsif"], [
    ["Тип счета boshqaruvi", "Yangi tur qo'shish / tahrirlash / o'chirish (faqat ishlatilmayotgan bo'lsa)"],
    ["Прикрепить/Открепить", "Hisobga тип biriktirish / ajratish"],
    ["Субсчет (sub_coa)", "6 belgi: 3 belgi guruh kodi + 3 belgi produkt kodi (masalan IPK2KV); bazaviy = 000000"],
    ["Парные счета", "Справочник bo'yicha kontr-hisob (парный) avtomatik ochiladi"],
    ["special_code", "Produkt/bitim unikal identifikatori (3 belgi)"],
  ]),
  sp(200),
];

// ===== 4. HISOB HOLATLARI =====
const s4 = [
  h("4. Hisob holatlari va o'tishlar", HeadingLevel.HEADING_1),
  h("4.1. Holatlar (status_state) — 13", HeadingLevel.HEADING_2),
  tbl([3000, 6360], ["Holat", "Ruxsat etilgan amallar"], [
    ["Создан", "Moliyaviy tranzaksiyalar TAQIQ; faqat ma'lumot korreksiyasi"],
    ["на утверждение / На проверке AML / Проверен AML", "(Создан ichidagi под-statuslar) — moliyaviy taqiq"],
    ["На отправление НИББД / Отправлен НИББД / Обработан НИББД", "(под-statuslar) — НИББД ro'yxat oqimi"],
    ["Утверждён (= Активный)", "Korreksiya + BARCHA moliyaviy operatsiyalar RUXSAT"],
    ["Временно закрыт", "Faqat ko'rish; НИББД'ga UZATILMAYDI; ссуда/foiz hisoblari temp-yopilmaydi"],
    ["Закрыт", "Operatsiyalar taqiq; НИББД'ga UZATILADI"],
    ["Блокирован", "Barcha operatsiyalar taqiq; НИББД'ga UZATILADI"],
    ["Архивирован", "Faqat ko'rish/qayta tiklash (avto)"],
    ["Удалён", "Создан/Архивирован holatdan o'chirish"],
    ["в ожидании перевода", "Boshqa bankka ko'chirishda"],
  ]),
  p("Hisob признак-status (alohida): M=ПЕРВИЧНЫЙ (birlamchi/asosiy depozit), O=ВТОРИЧНЫЙ (ikkilamchi).", { italic: true }),
  h("4.2. Asosiy o'tishlar", HeadingLevel.HEADING_2),
  code("(-) --Добавить--> Создан"),
  code("Создан --Утвердить(AML+НИББД)--> Утверждён"),
  code("Создан --Архивировать--> Архивирован ; Создан --Удалить--> Удалён"),
  code("Утверждён --> Временно закрыт | Закрыт | Блокирован | в ожидании перевода"),
  code("Временно закрыт --Утвердить--> Утверждён ; Временно закрыт --> Закрыт"),
  code("Закрыт --Утвердить--> Утверждён ; Закрыт --Архивировать--> Архивирован"),
  code("Блокирован --Разблокировать--> Утверждён ; Архивирован --Утвердить--> Утверждён"),
  sp(200),
];

// ===== 5. MIJOZ KARTOCHKALARI =====
const s5 = [
  h("5. Mijoz kartochkalari", HeadingLevel.HEADING_1),
  p("Klient holatlari hisob holatlari bilan bir xil oqim (Создан + AML/НИББД под-statuslar → Утверждён → Временно закрыт → Закрыт → Архивирован → Удалён). Mijoz kodi FAQAT НИББД tomonidan generatsiya qilinadi."),
  h("5.1. Jismoniy shaxs (asosiy rekvizitlar)", HeadingLevel.HEADING_2),
  p("Kartochka 9 bo'lim, ~80 maydon. Asosiylari:"),
  tbl([3000, 6360], ["Maydon", "Qoida"], [
    ["client_code (НИББД)", "8 xona, diapazon 60000000–69999999 (1-raqam=6); НИББД generatsiya"],
    ["ПИНФЛ", "Majburiy agar hujjat turi 0/6/8; rezident identifikatsiyasi"],
    ["Тип/Серия/Номер hujjat", "doc_type 0/6/8 → seriya 2 + raqam 7; rezidentlik avto"],
    ["Резидентность", "doc_type 0,1,2,3,6,8 → Резидент; 4 → Нерезидент (AVTO)"],
    ["Unikallik", "Rezident: ПИНФЛ + (Тип+Серия+Номер); Norezident: (Тип+Серия+Номер)"],
    ["Rollar", "Asosiy: клиент / связанное лицо + 8 qo'shimcha rol"],
  ]),
  h("5.2. Yuridik shaxs va YaTT", HeadingLevel.HEADING_2),
  tbl([3000, 6360], ["Maydon / qoida", "Tavsif"], [
    ["client_code (НИББД)", "8 xona; vaqtinchalik I% kod — 10 kunda real kodga almashmasa kartochka avto-o'chadi; «Иностранный банк» tipi 0009% qo'lda"],
    ["ИНН (YuSh)", "Unikal; YaTT-rezident: ПИНФЛ + (Тип+Серия+Номер)"],
    ["Ta'sischi/Direktor/Buxgalter", "E-GOV (PINFL) orqali avto yuklanadi"],
    ["Imzo va muhr namunalari", "Образцы подписей и печатей — saqlanadi (birinchi/ikkinchi imzo)"],
    ["typeof (Тип клиента)", "СПР 21; o'zgarganda НИББД yangi balans+kalit bilan YANGI asosiy depozit hisob shakllantiradi"],
    ["soato/oked/property_form/org_legal_form", "НИББД'ga uzatiluvchi rekvizitlar; Код района ↔ Код области (СПР 052) mos"],
  ]),
  sp(200),
];

// ===== 6. НИББД INTEGRATSIYA =====
const s6 = [
  h("6. НИББД integratsiyasi", HeadingLevel.HEADING_1),
  p("НИББД — ЦБ huzuridagi Milliy bank depozitorlari axborot bazasi (ЦБ №3336). Markaziy majburiy integratsiya: kartochka va hisob НИББД'da ro'yxatdan o'tadi; ro'yxatsiz mijozga hisob ochish TAQIQ; НИББД tasdig'isiz ma'lumot o'zgartirib bo'lmaydi."),
  h("6.1. Identifikatsiya (ro'yxatdan oldin majburiy)", HeadingLevel.HEADING_2),
  b("checkClientPhys — mikroservis bazasida tekshirish"),
  b("checkClientPhysNibbdByPin — НИББД'da ПИНФЛ bo'yicha"),
  b("checkClientPhysNibbdByDoc — НИББД'da hujjat bo'yicha"),
  b("Agar НИББД'da bor, mikroservisda yo'q → kartochka «НИББД'da ro'yxatdan o'tgan» status bilan avto-yaratiladi"),
  h("6.2. НИББД metodlari", HeadingLevel.HEADING_2),
  tbl([3400, 5960], ["Metod", "Vazifa"], [
    ["Registratsiya (СПР 019 Reg_nibd)", "признак 1=yuridik, 3=jismoniy ro'yxatga olinadi; 0/2/9 olinmaydi"],
    ["closeMainAccount / closeAccount", "asosiy / ikkilamchi hisobni yopish (НИББД)"],
    ["lockMainAccount / unlockMainAccount", "asosiy hisobni bloklash / blokdan chiqarish"],
    ["lockAccount / unlockAccount", "ikkilamchi hisob blok / unblok (unikal ro'yxat blok raqami)"],
    ["moveMainAccount", "asosiy hisobni boshqa bankka ko'chirish"],
    ["Получить список счетов из НИББД", "ro'yxatdagi hisoblar (balans kod ko'rsatilmasa — barcha ikkilamchi, yopiqdan tashqari)"],
    ["Получить список заблокированных счетов", "blok ro'yxati (faqat blok tashabbuskori bank ko'radi)"],
  ]),
  p("MARS implementatsiyasida НИББД tashqi servis interfeysi sifatida (PL/SQL paket spetsifikatsiyasi + JSON/SOAP adapter) modellashtiriladi; test muhitida stub/mock bilan, productionда real endpoint bilan.", { italic: true }),
  sp(200),
];

// ===== 7. AML + EDINOE OKNO =====
const s7 = [
  h("7. AML/KYC va «единое окно»", HeadingLevel.HEADING_1),
  h("7.1. AML/KYC", HeadingLevel.HEADING_2),
  p("Tasdiqlash (Утверждение) jarayonida AML tekshiruvi alohida holat/event: shubhali shaxslar (Moliyaviy monitoring departamenti) ro'yxati bo'yicha. Holatlar: «На проверке AML» → «Проверен AML». Sanksiya/terror ro'yxati mos kelganda operatsiya to'xtatiladi va vakolatli organga xabar beriladi (660-II qonun)."),
  h("7.2. «Единое окно» (E-GOV / ЦГУ)", HeadingLevel.HEADING_2),
  p("Davlat xizmatlari markazida (ЦГУ) mijoz bank tanlaydi → davlat xizmati НИББД orqali asosiy (birlamchi) yoki ikkilamchi hisob ochadi → НИББД bankka mijoz kartochkasi + hisob FAYL bilan uzatiladi → mikroservis avto kartochka yaratadi/tasdiqlaydi. E-GOV: ПИНФЛ bo'yicha director/buxgalter/ta'sischi ma'lumoti avtomatik yuklanadi."),
  sp(200),
];

// ===== 8. JARAYONLAR =====
const s8 = [
  h("8. Asosiy jarayonlar", HeadingLevel.HEADING_1),
  tbl([2800, 6560], ["Jarayon", "Mohiyat / shartlar"], [
    ["Birlamchi hisob ochish", "Birinchi murojaatda kartochka+asosiy depozit hisob BIRGA; 1/subyekt; so'm valyuta; balans СПР 21 dan avto; muvaffaqiyatda holat=Активный"],
    ["Ikkilamchi hisob ochish", "Asosiy hisob Активный bo'lishi shart (НИББД so'rovi); byudjet/davlat istisno (СПР 203); norezident faqat 20296 valyutali"],
    ["Утверждение (tasdiqlash)", "Majburiy atribut → holat tekshiruvi → AML → НИББД ro'yxat (СПР 019); Maker-Checker (yaratuvchi ≠ tasdiqlovchi)"],
    ["Обновление данных", "Qisman/to'liq; KYC/ichki nazorat; kerak bo'lsa НИББД tasdig'i bilan"],
    ["Временное закрытие", "Faqat Утверждён dan; НИББД'ga UZATILMAYDI"],
    ["Закрытие", "Faqat Утверждён/Временно закрыт; barcha ikkilamchi yopilgan; qoldiq=0; НИББД'ga uzatiladi"],
    ["Блокирование / Разблокирование", "Faqat Утверждён dan; НИББД; asosiy bloklansa — barcha hisoblar (СПР 203 istisno)"],
    ["Архивирование / Авто-удаление", "Cron job — faolsizlik davridan keyin avtomatik; Удалить faqat Создан holatda"],
    ["moveMainAccount", "Asosiy hisobni boshqa bankka ko'chirish (в ожидании перевода)"],
  ]),
  sp(200),
];

// ===== 9. DB + 10. PL/SQL + 11. JSP =====
const s9 = [
  h("9. Ma'lumotlar bazasi (yuqori daraja)", HeadingLevel.HEADING_1),
  p("Naming: core_cif_* (klient), core_acc_* (hisob). Pul: NUMBER(20,2/4) — BigDecimal. Audit: created/modified by/at + operatsion kun."),
  tbl([3000, 6360], ["Jadval", "Tavsif"], [
    ["core_cif_clients", "Klient kartochkasi (jismoniy/yuridik/YaTT, ~80 rekvizit, client_code НИББД, rezidentlik, rollar)"],
    ["core_cif_signatories", "Imzo va muhr namunalari (yuridik)"],
    ["core_cif_nibd_log", "НИББД so'rov/javob jurnali"],
    ["core_acc_accounts", "Hisoblar (CMMSS+VVV+K+kod+NNN, status/state, primary/secondary, COA, тип, субсчет, saldo/oborot)"],
    ["core_acc_pairs", "Парные счета bog'lanishi"],
    ["core_ref_*", "Справочниklar: 012 filial/ofis, 017 valyuta, 019 reg/balans признак, 021 mijoz tipi→balans, 052 hudud, 203 blok matritsa"],
    ["*_audit_log", "O'zgarmas audit (faqat INSERT)"],
  ]),
  h("10. PL/SQL paket arxitekturasi (SIRIUS)", HeadingLevel.HEADING_1),
  p("Har modul SIRIUS qatlamlari: const → types → util → logger → data_reader → repo → rules → service (+ NIBD interfeys paketi). COMMIT/ROLLBACK faqat service'da; service'da o_code/o_message/o_ora_message; xato kodlari -20xxx. Kontrol kalit core_acc_util.Calc_Control_Key (Mod-11)."),
  h("11. JSP sahifalar", HeadingLevel.HEADING_1),
  p("abs/cif/ (klient: list, create — jismoniy/yuridik/YaTT tab, detail, edit, approve [AML+НИББД oqimi], signatories) va abs/acc/ (hisob: list, open primary/secondary, detail, status/block/close/archive, единое окно). Mavjud tag library (t:table datagrid) + Mars + dizayn tizimi qayta ishlatiladi. Identity sessiyadan, RBAC rol gate (oracle-test-project xavfsizlik tuzatishlari ko'chiriladi)."),
  sp(200),
];

// ===== 12. SPRAVOCHNIKLAR + 13. ROADMAP =====
const s12 = [
  h("12. Spravochniklar (СПР)", HeadingLevel.HEADING_1),
  tbl([1800, 7560], ["СПР", "Mazmun"], [
    ["012", "Filial / Офис банковских услуг (ofis filialga tegishli bo'lishi shart)"],
    ["017", "Davlatlar va valyutalar (ISO 4217 raqamli; so'm hisob raqamida 000)"],
    ["019", "Reg_nibd признак (0/1/2/3/9) + balans признак (актив/пассив, балансовый/внебалансовый)"],
    ["021", "Mijoz tipi (typeof) → asosiy depozit balans hisobi"],
    ["052", "Область / Район kodlari (mosligi tekshiriladi)"],
    ["203", "Blok holatida ish tartibi matritsasi (ГНК, Картотека №2, sud, likvidatsiya, qidiruv...)"],
  ]),
  h("13. Implement bosqichlari (roadmap)", HeadingLevel.HEADING_1),
  tbl([1400, 5200, 2760], ["Bosqich", "Ish", "Natija"], [
    ["F0", "DB asos: COA/спр jadvallar, core_cif_clients + core_acc_accounts real struktura, Mod-11 util, СПР 21 balans tanlash", "Real kodlash + COA"],
    ["F1", "Holat mashinasi (13 holat + под-status), birlamchi/ikkilamchi hisob, тип счета/субсчет/парные, SIRIUS paketlar", "To'liq hisob lifecycle"],
    ["F2", "НИББД interfeys paketi (checkClient, registratsiya, lock/close/move) + jurnal; test stub", "НИББД oqimi (stub)"],
    ["F3", "AML holatlari + единое окно/E-GOV adapter; sanksiya skrining interfeysi", "Compliance oqimi"],
    ["F4", "JSP UI (klient/hisob), imzo/muhr formasi, RBAC, audit o'zgarmaslik", "To'liq UI + xavfsizlik"],
    ["F5", "Real НИББД/E-GOV endpoint ulanishi (production), UAT", "Production"],
  ]),
  p("Eslatma: F0-F1 — mustaqil (ichki); F2-F3-F5 — tashqi tizimlarga (НИББД/E-GOV) bog'liq, ularning real endpoint va shartnomalari talab qilinadi.", { italic: true }),
  sp(300),
  h("Tasdiqlash", HeadingLevel.HEADING_2),
  new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: [2400, 3480, 3480], rows: [
    new TableRow({ children: [hCell("Rol", 2400), hCell("FIO", 3480), hCell("Imzo / Sana", 3480)] }),
    new TableRow({ children: [c("Tayyorladi", 2400), c("", 3480), c("", 3480)] }),
    new TableRow({ children: [c("Tekshirdi", 2400, { shaded: true }), c("", 3480, { shaded: true }), c("", 3480, { shaded: true })] }),
    new TableRow({ children: [c("Tasdiqladi", 2400), c("", 3480), c("", 3480)] }),
  ]}),
];

// ===== ASSEMBLY =====
const doc = new Document({
  styles: { default: { document: { run: { font: "Arial", size: 22 } } }, paragraphStyles: [
    { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 32, bold: true, font: "Arial", color: BLUE }, paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
    { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 26, bold: true, font: "Arial", color: BLUE }, paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 } },
    { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 24, bold: true, font: "Arial", color: DARK_GRAY }, paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
  ]},
  numbering: { config: [
    { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
  ]},
  sections: [{
    properties: { page: { size: { width: PAGE_WIDTH, height: PAGE_HEIGHT }, margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } }, children: [new TextRun({ text: "MARS ABS  |  TZ-003  |  Клиенты и счета (real SIRIUS)", font: "Arial", size: 18, color: "999999" })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, border: { top: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 1 } }, children: [new TextRun({ text: "Fido Bank  |  MARS ABS  |  Konfidensial  |  Sahifa ", font: "Arial", size: 16, color: "999999" }), new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16, color: "999999" })] })] }) },
    children: [
      ...titlePage, ...tocSection,
      ...s1, new Paragraph({ children: [new PageBreak()] }),
      ...s2, new Paragraph({ children: [new PageBreak()] }),
      ...s3, ...s4, new Paragraph({ children: [new PageBreak()] }),
      ...s5, new Paragraph({ children: [new PageBreak()] }),
      ...s6, ...s7, new Paragraph({ children: [new PageBreak()] }),
      ...s8, new Paragraph({ children: [new PageBreak()] }),
      ...s9, new Paragraph({ children: [new PageBreak()] }),
      ...s12,
    ]
  }]
});

const OUTPUT = "/Users/dilmurod.qayyumov/MY-FILES/tools/mars-abs/docs/TZ-003_klientlar_hisoblar_texnik_topshiriq.docx";
Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(OUTPUT, buf);
  console.log(`Generated: ${OUTPUT}`);
  console.log(`Size: ${(buf.length / 1024).toFixed(1)} KB`);
}).catch(err => { console.error("Error:", err); process.exit(1); });

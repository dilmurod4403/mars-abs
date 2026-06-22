# CLAUDE.md — MARS ABS

## Project Overview

**MARS** — Fido Bank uchun Automated Banking System (ABS).
**Arxitektura**: UI butunlay JSP da, servlet YO'Q, API YO'Q — Oracle view, procedure va function lar JDBC orqali to'g'ridan-to'g'ri JSP dan chaqiriladi.
**abs-core-lib** — o'zimizning JAR kutubxona (tag library + DB helpers).

**Miqyos**: 1 filial, 5-10 foydalanuvchi, ~10,000 mijoz

## Tech Stack

| Texnologiya | Versiya | Izoh |
|------------|---------|------|
| Java | 17 | Temurin JDK 24 (compile target 17) |
| Servlet API | 4.0.1 | provided scope |
| JSP | 2.3 | JSTL 1.2.5, scriptlet TAQIQLANGAN |
| Oracle XE | 21c | Docker: gvenzl/oracle-xe:21-slim |
| JDBC Driver | ojdbc11 23.3 | Java 17+ uchun |
| Connection Pool | HikariCP 5.1 | max 10 connections |
| Web Server | Tomcat 9 | Docker container |
| Build | Maven 3.9.6 | 2 ta alohida pom.xml |
| UI | Custom CSS + vanilla JS | Bootstrap YO'Q, framework YO'Q. Inter shrift, slate+indigo dizayn tizimi |
| Infra | Docker Compose | oracle-db + tomcat |

**Dizayn**: yorug', zamonaviy (Linear/Stripe uslubi) — to'q sidebar + yorug' kontent, Inter shrift, indigo `#4f46e5` accent, slate neytral. Barcha UI `frontend-architect` agentiga tegishli.

## Architecture — NO SERVLET, NO API

```
JSP sahifa
  ├── Mars.procedure("pkg.proc").in("param").execute()    ← Oracle procedure
  ├── <t:table view="my_view_v">                          ← Oracle view
  │     <t:field field="col" title="Sarlavha">
  │       <t:filter type="text"/>
  │     </t:field>
  │     <t:grid pageSize="20">
  │       <t:col field="col" link="detail.jsp?id={id}"/>
  │     </t:grid>
  │   </t:table>
  └── AbsDb.getConnection()                               ← JDBC pool
```

**Data flow**: `JSP → Mars/AbsDb → Oracle PL/SQL → JSP (JSTL render)`

## Commands

```bash
# Environment
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-24.jdk/Contents/Home
MVN=/Users/dilmurod.qayyumov/.m2/wrapper/dists/apache-maven-3.9.6-bin/439sdfsg2nbdob9ciift5h5nse/apache-maven-3.9.6/bin/mvn

# Build abs-core-lib (kerak bo'lganda — Java klass o'zgarganda)
cd /Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project/abs-core-lib && $MVN clean install -q

# Build WAR
cd /Users/dilmurod.qayyumov/MY-FILES/tools/oracle-test-project && $MVN clean package -q

# Deploy (Docker Tomcat ga) — MUHIM: ROOT.war! Foydalanuvchi ROOT context (/abs/...) orqali kiradi.
# bank-app.war ga deploy qilsang, alohida /bank-app/ context yaratiladi va foydalanuvchi o'zgarishni KO'RMAYDI.
docker cp target/bank-app.war bank-tomcat:/usr/local/tomcat/webapps/ROOT.war

# Docker
docker compose up -d                # start
docker compose down -v              # to'liq tozalash

# Oracle DB
docker exec -it oracle-bank-db sqlplus bankuser/BankUser123@//localhost:1521/XEPDB1

# Test — login + sahifalar (ROOT context, /bank-app/ EMAS)
curl -s -c /tmp/c.txt -X POST 'http://localhost:8080/abs/login.jsp' -d 'username=admin&password=Admin%40123' -o /dev/null -w 'login %{http_code}\n'
for p in "abs/cif/dashboard.jsp" "abs/cif/customer-list.jsp" "abs/cif/customer-approve.jsp" \
  "abs/cif/expired-docs.jsp" "abs/cif/pep-report.jsp" \
  "abs/admin/user-list.jsp"; do
  echo "$(curl -s -b /tmp/c.txt -o /dev/null -w '%{http_code}' "http://localhost:8080/$p")  $p"
done
```

**Endpointlar:**
- App: `http://localhost:8080/` (ROOT context — `/abs/...`)
- Admin login: `admin` / `Admin@123`
- Oracle: `localhost:1521/XEPDB1` (user: `bankuser`, pass: `BankUser123`)

## abs-core-lib — Custom JAR (uz.fido.abs:abs-core-lib:1.0.0)

Alohida Maven module, `mvn clean install` bilan local .m2 ga o'rnatiladi.

### Tag Library v6 (uri: http://fido.uz/abs/tags, prefix: t)

```
t:table (view, var, orderBy, columns)         ← Oracle view dan data oladi
  ├── t:field (field, title, format)           ← Ma'lumot maydoni ta'rifi
  │     └── t:filter (type, options)           ← Filter (text | select | date)
  └── t:grid (pageSize, mode, emptyText, id, title, modal, modalSize,
              selectable, stickyHeader, saveUrl, rowId, bulkStatus)  ← UI + datagrid
        └── t:col (field, title, format, link, badge, align, width, cssClass,
                    footer, footerFunc, editable, editType, editOptions, sortable)
```

**Data (t:field)** va **UI (t:grid > t:col)** ajratilgan. t:col title/format ni t:field dan oladi (override mumkin).

**Datagrid imkoniyatlari** (TableTag render + `js/abs-datagrid.js` client):
- **Saralash** — sarlavha bosilsa server-side ORDER BY (asc→desc→o'chirish), SQL-inj himoyali (faqat whitelisted ustun). `t:col sortable="false"` bilan o'chiriladi.
- **Sahifa o'lchami** — toolbar select (20/50/100, param `ps`).
- **Sticky header** — `stickyHeader="true"` (default) — scroll'da sarlavha tepada qotadi.
- **Zichlik** — toolbar toggle (compact/keng, localStorage).
- **Ustun ko'rsatish/yashirish** — toolbar dropdown (localStorage).
- **Eksport** — CSV / Excel (client-side, filtr/tanlovga mos).
- **Qator tanlash** — `selectable="true"` → checkbox ustun + bulk toolbar.
- **Bulk status o'zgartirish** — `selectable + rowId + saveUrl + bulkStatus` → tanlangan qatorlar statusini `saveUrl` (JSP handler → Mars procedure) orqali o'zgartiradi.

### Java Classes

```
abs-core-lib/src/main/java/uz/fido/abs/core/
├── db/
│   ├── AbsDb.java          # HikariCP pool, getConnection()
│   └── Mars.java            # Oracle procedure/function helper (RECORD support)
├── model/
│   ├── GridModel.java       # Sahifalangan data model
│   ├── ColumnDef.java       # Ustun ta'rifi + badge resolve
│   └── FilterDef.java       # Filter ta'rifi + parseOptions
└── tag/
    ├── TableTag.java        # Root tag — view → SQL → data + fieldMetas
    ├── FieldTag.java        # Data field + filter container
    ├── FilterTag.java       # Filter — FieldTag ichida
    ├── GridTag.java         # UI config — pageSize, mode, emptyText
    ├── ColumnTag.java       # UI ustun — GridTag ichida
    └── DataTag.java         # [LEGACY] eski data tag
```

### Mars class — Oracle PL/SQL caller

```java
// Oddiy procedure
Mars.procedure("core_cif_pkg.create_customer")
    .in("p_name", name)
    .in("p_type", type)
    .outNumber("p_id")
    .outString("p_error")
    .execute();

// RECORD type bilan
Mars.procedure("core_cif_pkg.get_customer")
    .in("p_id", id)
    .record("v_rec", "core_cif_pkg.t_customer_rec")
        .field("customer_id")
        .field("full_name")
        .fieldDate("birth_date")
        .outField()
    .execute();
```

## Project Structure

```
oracle-test-project/
├── pom.xml                          # WAR — bank-app
├── abs-core-lib/
│   ├── pom.xml                      # JAR — abs-core-lib
│   └── src/main/
│       ├── java/uz/fido/abs/core/   # (yuqoridagi tuzilma)
│       └── resources/META-INF/
│           └── abs-core.tld         # Tag Library Descriptor v6
├── src/main/
│   ├── java/uz/fido/bank/
│   │   ├── servlet/                 # [LEGACY] DashboardServlet, CustomerServlet, ...
│   │   ├── dao/                     # [LEGACY] CustomerDao, AccountDao, TransactionDao
│   │   ├── model/                   # [LEGACY] Customer, Account, Transaction
│   │   ├── filter/                  # AuthFilter, EncodingFilter
│   │   └── util/                    # DbUtil
│   └── webapp/
│       ├── abs/
│       │   ├── login.jsp            # Mars auth + zamonaviy split-screen dizayn
│       │   ├── logout.jsp
│       │   ├── header.jsp, footer.jsp # [LEGACY chrome] sidebar layout (eski modul: /customers...)
│       │   ├── dashboard.jsp, error.jsp
│       │   ├── cif/                 # Mijozlar moduli
│       │   │   ├── cif-header.jsp, cif-footer.jsp  # Sidebar+topbar chrome (modal=1 fragment, cache-bust)
│       │   │   ├── dashboard.jsp           # Zamonaviy: stat kartalar, progress-bar, tezkor havola kartalar
│       │   │   ├── customer-list.jsp      # t:table + datagrid (saralash/tanlash/bulk status)
│       │   │   ├── customer-bulk-save.jsp # Bulk handler → core_cif_service.change_status
│       │   │   ├── customer-create.jsp    # Mars.procedure
│       │   │   ├── customer-edit.jsp      # Mars.procedure
│       │   │   ├── customer-detail.jsp    # Mars.procedure + RECORD
│       │   │   ├── customer-approve.jsp   # Mars.procedure + t:table (data-only)
│       │   │   ├── expired-docs.jsp       # t:table
│       │   │   └── pep-report.jsp         # t:table
│       │   ├── admin/               # Foydalanuvchilar boshqaruvi (5 JSP)
│       │   │   ├── admin-header.jsp, admin-footer.jsp
│       │   │   ├── user-list.jsp          # t:table
│       │   │   ├── user-create.jsp        # Mars.procedure
│       │   │   └── user-edit.jsp          # Mars.procedure
│       │   └── accounts/            # [LEGACY] servlet-based (3 JSP)
│       ├── css/style.css            # Yagona dizayn tizimi (Inter, slate+indigo, datagrid, modal)
│       ├── js/
│       │   ├── abs.js               # tabs, alert, validation, grid keyboard nav
│       │   ├── abs-modal.js         # add/edit/view modal (AJAX fragment, ?modal=1)
│       │   ├── abs-datagrid.js      # datagrid: density, ustun, eksport, tanlash, bulk
│       │   └── abs-grid.js          # JSON-mode editable grid
│       └── WEB-INF/web.xml
├── docker/
│   ├── oracle/init/                 # 13 SQL init skript (01-15)
│   └── tomcat/Dockerfile
├── docker-compose.yml
├── docs/                            # Hujjatlar (DOCX + generatorlar)
│   ├── BT-001_core_cif_biznes_talab.docx
│   ├── BT-002_core_acc_biznes_talab.docx
│   ├── TZ-001_core_cif_texnik_topshiriq.docx
│   └── standards/plsql-rules.md
└── .claude/agents/                  # 8 ta agent (ba, dba, devops, ...)
```

## DB Init Scripts (docker/oracle/init/)

```
# === REAL build (F0+) — cutover 2026-06-22 ===
00_ref_spravochniklar.sql  # core_ref_currency/client_type/region/coa/branch (СПР 17/21/52/19/12; 4255 qator). Gen: docs/ref/gen_ref_sql.py (spr-12 .xls -> xlrd)
01_acc_util.sql            # core_acc_util — 20-xonali hisob raqami + Mod-11 kontrol kalit (real SIRIUS, Oracle'da tekshirilgan)
02_auth_setup.sql          # Autentifikatsiya (admin/Admin@123) — infra (demo'dan ko'chirilgan)
20_acc_schema.sql          # core_acc_accounts (real SIRIUS «Счета») + core_acc_status (14 holat lookup) + sequence + BIU trigger + 6 index. acctest'da end-to-end tekshirilgan.
# Keyingi F0: 10_cif_schema (real kartochka + НИББД client_code), core_acc paketlar (SIRIUS const/types/util/repo/rules/service qatlam), viewlar, НИББД interfeys

# === DEMO (prototip) — ARXIVLANGAN: docker/oracle/init-demo-archive/ (mount QILINMAYDI, o'chirilmagan) ===
# 01..15 (cif/acc/auth demo, 17 skript) — qaytarib bo'ladi. To'liq demo oracle-test-project'da saqlanadi.
# Eslatma: arxiv core_acc_util (eski 7-3-1) bilan to'qnashmaslik uchun mount'dan chiqarilgan.
```

## DB Naming Convention

```
Jadval:     core_cif_customers, core_acc_accounts
View:       core_cif_customers_ui_v, core_cif_pep_customers_ui_v
Package:    core_cif_pkg, core_cif_doc_pkg
PK:         core_cif_customers_pk
FK:         core_cif_documents_cust_fk
Index:      core_cif_customers_cif_idx
Sequence:   core_cif_customers_seq
Check:      core_cif_customers_status_ck
Trigger:    core_cif_customers_biu_trg
```

## Key Design Decisions

- **NO servlet, NO API** — JSP to'g'ridan-to'g'ri Oracle PL/SQL ni chaqiradi
- **Mars class** — PL/SQL procedure/function chaqirish uchun fluent builder
- **AbsDb** — HikariCP connection pool
- **Tag library** — t:table/field/filter + grid/col — deklarativ data grid
- **fieldMetas pattern** — FieldTag metadata ni ro'yxatga oladi, ColumnTag undan default oladi
- **Data vs UI ajratish** — t:field (nima ko'rsatiladi) ≠ t:col (qanday ko'rsatiladi)
- **BigDecimal** — barcha pul summalari uchun (double/float HECH QACHON)
- **Maker-Checker** — ikki bosqichli tasdiqlash (Operator yaratadi, Supervisor tasdiqlaydi)
- **CIF format** — CIF-YYYYMMDD-NNNNNN (sequence orqali)
- **Status workflow** — ACTIVE → BLOCKED → CLOSED (CLOSED dan qaytish YO'Q)
- **Audit trail** — har bir jadvalda created_by, created_at, updated_by, updated_at

## Tag Library Usage Examples

```jsp
<%-- Ro'yxat sahifasi — data grid bilan --%>
<t:table view="core_cif_customers_ui_v" var="data" orderBy="created_at DESC">
    <t:field field="cif_number" title="CIF">
        <t:filter type="text" />
    </t:field>
    <t:field field="status" title="Holat">
        <t:filter type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda,BLOCKED:Bloklangan" />
    </t:field>
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Mijoz topilmadi">
        <t:col field="cif_number" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="status" badge="ACTIVE:Faol:active,BLOCKED:Bloklangan:blocked" />
        <t:col field="created_at" />
    </t:grid>
</t:table>

<%-- To'liq datagrid — saralash, tanlash, bulk status o'zgartirish --%>
<t:table view="core_cif_customers_ui_v" var="data" orderBy="created_at DESC">
    <t:field field="status" title="Holat"><t:filter type="select" options="ACTIVE:Faol,BLOCKED:Bloklangan"/></t:field>
    <t:grid pageSize="20" selectable="true" rowId="customer_id"
            saveUrl="${pageContext.request.contextPath}/abs/cif/customer-bulk-save.jsp"
            bulkStatus="ACTIVE:Faollashtirish,BLOCKED:Bloklash">
        <t:col field="status" badge="ACTIVE:Faol:active,BLOCKED:Bloklangan:blocked" />
    </t:grid>
</t:table>
<%-- saveUrl handler (customer-bulk-save.jsp): action=status, ids=1,2,3, status=X ni
     o'qib, har id uchun Mars.procedure("core_cif_service.change_status") chaqiradi --%>

<%-- Data-only rejim (faqat data, UI — JSTL bilan qo'lda) --%>
<t:table view="core_cif_customers_ui_v" var="data" orderBy="created_at DESC">
    <t:grid pageSize="100" />
</t:table>
<c:forEach var="row" items="${data.rows}">...</c:forEach>

<%-- Procedure chaqirish --%>
<%@ page import="uz.fido.abs.core.db.Mars" %>
<% Mars.procedure("core_cif_pkg.create_customer").in("p_name", name).outNumber("p_id").execute(); %>
```

## Module Architecture (17 modul, 4 qatlam)

```
Core-Infra:     core_adm (Administration), core_sec (Security)
Core-Business:  core_cif (Customers) ✅, core_acc (Accounts) ✅, core_gl (General Ledger),
                core_trx (Transactions), core_curr (Currency)
Operational:    op_teller, op_cash, op_loan, op_deposit, op_fx, op_payment
Output:         out_report, out_cbu, out_statement, out_notification
```

**Implement tartibi**: 1. core_cif ✅ → 2. core_acc ✅ → 3. core_adm → 4. core_gl → 5. core_trx → qolganlar

## Joriy holat va keyingi qadamlar

### 🎯 Strategik yo'nalish — REAL SIRIUS build (mars-abs)
- **Qaror (2026-06-22):** `mars-abs` — Fido Bank SIRIUS «Клиенты и счета» spetsifikatsiyasiga SODIQ (production-paritet) real tizim quriladigan loyiha. `oracle-test-project` — o'quv prototipi bo'lib qoladi.
- **Asos:** SIRIUS Confluence hujjatlari (`docs/Счета.doc`, `Физическое+лицо.doc`, `Юридическое+лицо+и+ИП.doc`) — real hisob kodlash (CMMSS+VVV+K+kod8+NNN), **Mod-11 kontrol kalit** (ASCII qo'shni-raqam), НИББД integratsiya, AML/единое окно, 13 holat, birlamchi/ikkilamchi hisob, COA/тип/субсчет.
- **TZ-003** (`docs/generate-tz003.js` → docx) — shu real build texnik topshirig'i, F0→F5 roadmap.
- **Reference qatlami (F0):** SIRIUS spravochniklar (`docs/ref/spr-*.xlsx`) → `core_ref_*` jadval+seed, `docs/ref/gen_ref_sql.py` generatori orqali → `docs/ref/generated/00_ref_spravochniklar.sql`: core_ref_currency (СПР17, 213), core_ref_client_type (СПР21, 15), core_ref_region (СПР52, 230), core_ref_coa (СПР19 План счетов, 1690), core_ref_branch (СПР12 filial/MFO, 2107 — `spr-12.xls` xlrd orqali). Jami 4255 qator, Oracle'da tekshirilgan.
- **Eslatma:** quyidagi "✅ Bajarilgan core_cif/core_acc" — bu **DEMO darajasi** (prototipdan meros). Real build ularni SIRIUS spetsifikatsiyasiga ko'taradi (TZ-003): hisob raqami formati (valyuta o'rtada), Mod-11 kalit, НИББД, AML, COA, birlamchi/ikkilamchi.

### ✅ Bajarilgan — core_cif (Mijozlar moduli)
- **Sahifalar**: login (zamonaviy split-screen), dashboard (stat kartalar + progress-bar + tezkor havola kartalari), customer list/create/edit/detail/approve, expired-docs, pep-report; admin user list/create/edit
- **Auth**: `core_auth_service.Authenticate_User` + session; `AuthFilter` (rol tekshiruv + barcha HTML'ga no-cache); login `admin/Admin@123`
- **Dizayn**: yagona yorug' zamonaviy tizim (to'q sidebar + topbar, Inter, indigo accent, slate) — CIF + admin + eski chrome
- **Datagrid (Tag Library v6)**: saralash (server ORDER BY, SQL-inj himoyali), sahifa o'lchami (20/50/100), sticky header, zichlik, ustun ko'rsatish/yashirish, CSV/Excel eksport, qator tanlash + **bulk status o'zgartirish** (`customer-bulk-save.jsp` → `core_cif_service.change_status`, DB'ga haqiqatan saqlaydi)
- **Modal**: add/edit/view formalar modal oynada (AJAX `?modal=1` fragment); grid klaviatura navigatsiya
- **Infra**: Docker (Oracle XE + Tomcat 9), `ROOT.war` deploy, asset `?v=<mtime>` versiyalash

### ✅ Bajarilgan — core_acc (Hisoblar moduli)
- **DB** (`docker/oracle/init/`): `11_acc_schema` (core_acc_accounts / _signatories / _audit_log + sequence + indekslar), `12_acc_packages` (8 SIRIUS paket: const/types/util/logger/data_reader/repo/rules/service + BI trigger), `13_acc_views` (6 view), `14_acc_seed` (9 test hisob). Live DB ga additiv qo'llangan + sinovdan o'tgan (`down -v` da avtomatik ishlaydi).
- **Hisob raqami**: 20 xonali GL(5)+TUR(3)+KONTROL(1)+TARTIB(8)+VALYUTA(3); 7-3-1 vaznli kontrol raqam (`core_acc_util.Generate_Account_Number` / `Is_Valid_Account_Number`).
- **Biznes qoidalar (PL/SQL'da sinovdan o'tgan)**: mijoz mosligi (faqat ACTIVE, `-20102`), holat matritsasi PENDING→ACTIVE→FROZEN/BLOCKED→CLOSED (`-20104`), yopish qoldiq=0 (`-20105`), Maker-Checker (`-20107`).
- **JSP** (`abs/acc/`): dashboard, account-list (datagrid+bulk), account-create (`Open_Account`), account-detail, account-edit (`Update_Account`), account-status-save (Change/Approve/Reject/Close handler), account-bulk-save, account-approve (Maker-Checker), currency-stats (RPT-003), dormant-accounts (RPT-005) + acc-header/footer chrome. `cif-header`'ga "Hisoblar" havolasi.
- **Sinov**: create/approve/status oqimlari end-to-end (HTTP 302/200 + DB) tasdiqlangan; eski cif modul buzilmagan.
- **Qolgan (ixtiyoriy)**: imzo huquqi (signatories) formasi create'da yo'q (jadval + seed bor); approve ekranida reject sababi hardcoded; per-cell inline tahrir yo'q.

### 🔄 Keyingi qadamlar — core_cif
- **Per-cell inline tahrir** — infratuzilma bor (JSON mode + `saveUrl`), standart HTML grid'da to'liq ulanmagan. Ixtiyoriy maydon uchun `core_cif_service.update_customer` (RECORD tip) ulash kerak. Hozir faqat **status** bulk orqali o'zgaradi.
- **Eski demo modulni retire/redirect** — `/customers`, `/accounts`, `/transfer`, `/` servletlar (ikki parallel UI = chalkashlik). Tavsiya: `/` → `/abs/cif/dashboard.jsp` ga yo'naltirish va eski demo'ni olib tashlash. (Qaror foydalanuvchida.)

### 📋 Keyingi modullar (implement tartibida)
- **core_acc (Hisoblar)** — ✅ **Implement qilindi** (yuqoridagi "✅ Bajarilgan — core_acc"). BT-002 ✅, TZ-002 ✅, DB + JSP ✅, sinovdan o'tgan.
- **Keyingi modul: core_adm** (Administration) → keyin core_gl → core_trx → operatsion (op_*) / output (out_*) modullar.
- **Eslatma**: TZ-001 (core_cif) eskirgan servlet/DAO arxitekturasini tasvirlaydi — real implementatsiya PL/SQL + JSP + Mars. TZ-002 real arxitekturaga moslab yozilgan.

## Documentation

| Hujjat | Modul | Status |
|--------|-------|--------|
| BT-001 | core_cif | ✅ Tasdiqlangan |
| TZ-001 | core_cif | ⏳ Tekshiruvda (eskirgan: servlet/DAO tasvirlaydi, real = PL/SQL+JSP+Mars) |
| BT-002 | core_acc | ✅ Tayyor |
| TZ-002 | core_acc | ✅ Implement qilindi (DB + JSP) — real MARS arxitekturasi (PL/SQL SIRIUS + JSP/Mars) |
| TZ-003 | Клиенты и счета (real SIRIUS) | 🟢 Qoralama — production-paritet build (mars-abs); F0→F5 roadmap; `docs/generate-tz003.js`. F0 boshlanmoqda |

**Hujjat generatorlari**: `docs/generate-{bt001,bt002,tz001,tz002,tz003}.js` (Node + `docx`). Reference SQL: `docs/ref/gen_ref_sql.py` (СПР xlsx → `core_ref_*`). Tahrirlash: generatorni o'zgartirib qayta ishga tushiring.

**BT** = Biznes Talab (NIMA kerak, biznes tilida — VARCHAR2/NUMBER HECH QACHON)
**TZ** = Texnik Topshiriq (QANDAY qilinadi — jadvallar, kodlar, PL/SQL)

## Team Agents (.claude/agents/)

| Agent | Rol |
|-------|-----|
| `frontend-architect.md` | **Frontend Architect — BARCHA UI ishlari** (dizayn tizimi, CSS, JSP chrome, JS, ergonomika, a11y). UI ning yagona egasi. |
| `ba.md` | Business Analyst — BT hujjatlar |
| `senior-dev.md` | Senior Java Developer — core modullar |
| `middle-dev.md` | Middle Java Developer — JSP biznes-logika, operatsion |
| `dba.md` | Oracle DBA — schema, PL/SQL |
| `qa.md` | QA Engineer — test senariylar |
| `devops.md` | DevOps — Docker, CI/CD |
| `security.md` | Security — xavfsizlik audit |
| `ui-designer.md` | ~~UI/UX Designer~~ — `frontend-architect` ga birlashtirildi (eskirgan) |

**UI qoidasi:** barcha vizual/frontend ishlar (CSS, layout, komponent, sahifa dizayni, JS) `frontend-architect` agentiga topshiriladi.

## Gotchas

- **Build tartibi**: abs-core-lib Java o'zgarganda avval `cd abs-core-lib && mvn clean install`, keyin root `mvn clean package`
- **Docker deploy → ROOT.war!**: `docker cp target/bank-app.war bank-tomcat:/usr/local/tomcat/webapps/ROOT.war`. Ilova ROOT context'da (`http://localhost:8080/abs/...`). `bank-app.war` ga deploy qilsang alohida `/bank-app/` context yaratiladi — foydalanuvchi o'zgarishni ko'rmaydi! Faqat bitta context (ROOT) bo'lsin.
- **HTML kesh**: `AuthFilter` barcha `/abs/` sahifalarga `Cache-Control: no-cache` qo'yadi (include ichida `setHeader` ishlamaydi). CSS/JS esa `?v=<mtime>` bilan versiyalanadi.
- **Oracle XE limit** — 12GB DB, 2GB RAM, 2 CPU thread
- **Init skriptlar** — volume mavjud bo'lsa qayta ishlamaydi. Tozalash: `docker compose down -v`
- **Oracle XE ARM Mac** — 2-5 daqiqa ishga tushadi (healthcheck `start_period: 120s`)
- **fmt:formatDate + LocalDateTime** — JSTL faqat java.util.Date bilan ishlaydi
- **IKKI UI bor!** — (1) eski demo modul: servlet `/customers`, `/accounts`, `/transfer`, `/` (`abs/header.jsp`, demo ma'lumot); (2) asl MARS ABS: `/abs/cif/...`, `/abs/admin/...` (`cif-header.jsp`/`admin-header.jsp`). Ikkalasi ham endi sidebar dizaynda. Asl ish — `/abs/cif/...`.
- **Datagrid markazlashgan** — saralash/eksport/tanlash/bulk hammasi `TableTag.java` + `abs-datagrid.js` da. Yangi grid faqat tag atributlari bilan opt-in qiladi (per-page kod kerak emas).
- **Bulk/inline saqlash procedure'lari** — `core_cif_service.change_status(i_customer_id, i_new_status, i_user)`, `core_cif_service.update_customer(i_rec record)`, `core_auth_service.update_user`. Saqlash JSP handler (masalan `customer-bulk-save.jsp`) shularni Mars orqali chaqiradi.
- **[LEGACY]** — `src/main/java/uz/fido/bank/servlet/` va `accounts/` papkalar eski servlet-based kod, yangi modullar faqat JSP + Mars
- **Mars.field() + pul summalari** — `Mars.field()` faqat `String`/`long` qabul qiladi, `BigDecimal` EMAS. Pul/NUMBER maydonlarini `.field("min_balance", val.toPlainString())` ko'rinishida (String sifatida) uzating — Oracle record assignment'da VARCHAR→NUMBER implicit konvertatsiya qiladi. (core_acc JSP'larida shunday.)

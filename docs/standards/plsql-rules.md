# SIRIUS PL/SQL — Tahlil qoidalari to'plami

Jami **50 ta qoida**, 7 ta kategoriya.

## Kategoriyalar

| Kategoriya | Soni | Prefix |
|-----------|------|--------|
| Xavfsizlik | 13 | S- |
| Performance | 11 | P- |
| Xato boshqaruvi | 7 | E- |
| Kod sifati | 6 | Q-, V- |
| Naming | 8 | N-, V-3 |
| Versioning | 2 | BC- |
| Qatlam / Obyekt | 3 | SC-, L- |

## Severity darajalari

| Daraja | Ma'nosi |
|--------|---------|
| 🔴 BLOCKER | Darhol tuzatish shart — production'ga chiqmasligi kerak |
| 🟠 CRITICAL | Jiddiy xavf — sprint ichida tuzatish |
| 🟡 MAJOR | Muhim — keyingi sprintda tuzatish |
| 🔵 MINOR | Yaxshilash tavsiya — backlog |
| ⚪ INFO | Ma'lumot uchun |

## Xavfsizlik qoidalari (S-)

- S-1 (BLOCKER): SQL Injection — EXECUTE IMMEDIATE da || emas, USING ishlatish
- S-2 (MAJOR): SELECT * — faqat kerakli ustunlarni tanlash (ROWTYPE va cursor FOR loop xavfsiz)
- S-3 (MAJOR): INSERT ustun ro'yxatisiz — doim ustun nomlari ko'rsatilsin
- S-4 (MAJOR): TO_DATE format maskasiz — doim format mask berish
- S-5 (MINOR): USER — SYS_CONTEXT('USERENV','SESSION_USER') ishlatish
- S-6 (MINOR): DBMS_OUTPUT production'da — Logger ishlatish
- S-8 (MAJOR): ROWNUM + ORDER BY — subquery ichida ORDER BY, tashqarida ROWNUM
- S-9 (CRITICAL): NOT IN (SELECT) NULL trap — NOT EXISTS ishlatish
- S-10 (MAJOR): TO_CHAR YY — YYYY ishlatish
- S-11 (BLOCKER): Dinamik GRANT — DBA skriptlarida statik GRANT
- S-12 (MAJOR): UTL_FILE/HTTP/TCP/SMTP — security review shart
- S-13 (CRITICAL): TRUNCATE procedure ichida — DELETE ishlatish
- S-14 (CRITICAL): Dinamik DDL — DBA migration skriptlarida

## Performance qoidalari (P-)

- P-1 (MAJOR): BULK COLLECT LIMIT yo'q — LIMIT 1000 ishlatish
- P-2 (MAJOR): FOR loop ichida DML — set-based yoki FORALL
- P-3 (MAJOR): WHERE da ustun ustida funksiya — function-based index yoki qayta yozish
- P-4 (CRITICAL): LOOP ichida COMMIT — oxirida bitta COMMIT
- P-5 (MAJOR): LOOP ichida SELECT INTO (N+1) — JOIN bilan bitta so'rov
- P-6 (MAJOR): FORALL SAVE EXCEPTIONS yo'q — doim SAVE EXCEPTIONS
- P-7 (MINOR): COUNT(*) o'rniga EXISTS — ROWNUM <= 1 bilan COUNT yoki EXISTS
- P-8 (MINOR): DECODE — CASE ishlatish
- P-9 (MINOR): Oracle (+) join — ANSI JOIN
- P-10 (MAJOR): Cartesian product — JOIN shart doim bo'lsin
- V-4 (MAJOR): View ichida paket funksiyasi — (SELECT pkg.func(x) FROM DUAL) wrapper. Faqat UTIL va REPO ruxsat. LOGGER/RULES/SERVICE/EX_SERVICE/INTERFACE/API taqiqlangan.

## Xato boshqaruvi (E-)

- E-2 (BLOCKER): WHEN OTHERS THEN NULL — log + RAISE
- E-3 (MAJOR): Cursor OPEN %ISOPEN yo'q — tekshirish shart
- E-4 (BLOCKER): IF x = NULL — IS NULL ishlatish
- E-5 (BLOCKER): COMMIT/ROLLBACK noto'g'ri qatlamda — faqat SERVICE/INTERFACE'da
- E-6 (MINOR): NVL(x, NULL) — ma'nosiz, olib tashlash
- E-7 (CRITICAL): RAISE_APPLICATION_ERROR noto'g'ri kod — faqat -20000..-20999
- E-8 (MAJOR): IF da bir xil operand — mantiqiy xato

## Kod sifati (Q-, V-)

- Q-2 (MINOR): IF (condition) = TRUE — ortiqcha
- Q-3 (MINOR): Magic number — CONSTANT ishlatish
- Q-4 (MAJOR): GOTO — IF/LOOP/EXIT ishlatish
- Q-5 (INFO): Bo'sh procedure — stub, to'ldirish kerak
- V-1 (BLOCKER/MAJOR): View ichida DML yo'q + WITH READ ONLY
- V-2 (MAJOR): View ichida SELECT * — aniq column ro'yxati

## Naming qoidalari (N-)

- N-1 (MINOR): Parameter prefix — i_ (IN), o_ (OUT), io_ (IN OUT)
- N-2 (MINOR): Local variable — v_ prefix
- N-3 (MINOR): Cursor — cr_ prefix
- N-4 (MINOR): Constant — c_ prefix
- N-5 (MINOR): Exception — e_ prefix
- N-6 (MINOR): Type — t_ prefix + suffiks: _rec, _tab, _cur, _arr
- N-7 (MAJOR): View nomlash — <module>_<nom>_<usage>_v (usage: _ui_v, _i_v, _c_v)
- V-3 (MAJOR): View versioning — _c_v, _c_v2, _c_v3

## Versioning (BC-)

- BC-1 (BLOCKER): Yangi parametr DEFAULT bilan — backward compatibility
- BC-2 (MAJOR): Breaking change — _V2 versioning + deprecation marker, 6 oy migration window

## Qatlam / Obyekt (SC-, L-)

- SC-1 (CRITICAL): _service paketda o_code/o_message/o_ora_message majburiy
- SC-2 (BLOCKER): OUT parametrlarni boshida init (o_code := 0; o_message := 'OK')
- L-1 (CRITICAL): Qatlam buzilishi — INTERFACE/API → SERVICE → RULES/REPO → LOGGER/UTIL/CONST

## SIRIUS qatlam arxitekturasi

```
INTERFACE / API    — Tashqi tizimlar uchun
    ↓
SERVICE            — Biznes logika + COMMIT/ROLLBACK
    ↓
RULES              — Validatsiya qoidalari (DML yo'q!)
REPO               — CRUD operatsiyalar (DML bor)
    ↓
LOGGER             — Logging (side-effect)
UTIL               — Yordamchi funksiyalar (pure)
CONST              — Konstantalar
```

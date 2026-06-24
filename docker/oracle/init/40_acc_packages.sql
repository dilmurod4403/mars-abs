-- gvenzl init (sqlplus / as sysdba, CDB-root) -> XEPDB1.BANKUSER. Manual load: no-op (USER<>SYS).
BEGIN
  IF USER = 'SYS' THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = XEPDB1';
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = BANKUSER';
  END IF;
END;
/
-- ============================================================================
-- MARS ABS — core_acc moduli
-- 40_acc_packages.sql — HISOB OCHISH (открытие счёта) — SIRIUS PL/SQL qatlamlari
-- Qamrov: depozit hisob ochish (Создать -> Утвердить), M/O (первичный/вторичный),
--   balans hisobini mijoz turidan AUTO tanlash, NNN tartib raqami, парный счёт.
-- Asoslanadi: SIRIUS «Счета» spec + 20_acc_schema + 01_acc_util + 10_cif_schema
--   (core_cif_clients precondition) + 30_cif_packages (SIRIUS qatlam uslubi).
-- Target: Oracle 21c XE.
--
-- Qatlamlar (dependency tartibi, L-1):
--   const -> types -> svc_util -> logger -> data_reader -> repo -> rules -> service
--   COMMIT/ROLLBACK FAQAT service qatlamda (E-5).
--   repo  — faqat INSERT/UPDATE (COMMIT yo'q).
--   rules — faqat tekshiradi, qoida buzilsa RAISE_APPLICATION_ERROR(-203xx).
--   data_reader — faqat SELECT (read-only).
--   service public proc: o_code(0=ok)/o_message/o_ora_message bilan tugaydi (SC-1),
--     boshida init (SC-2), tanasi: rules+util+repo -> COMMIT, keyin
--     EXCEPTION WHEN OTHERS -> ROLLBACK + o_code/o_message/o_ora_message.
--
-- DIQQAT (trigger bilan koordinatsiya — 20_acc_schema):
--   core_acc_accounts_biu_trg INSERT da o'zi beradi:
--     account_id (NULL bo'lsa, sequence), account_number (NULL bo'lsa
--       core_acc_util.Generate_Account_Number 5 komponentdan), control_key
--       (raqamning 9-pozitsiyasidan), status (NULL bo'lsa default 'M'),
--       created_at, updated_at, r_uid=0.
--   Shuning uchun repo BU ustunlarni KIRITMAYDI (ikki marta generatsiya YO'Q) —
--     repo faqat 5 komponentni (balance_account, currency_code, client_code,
--     seq_number) + boshqa biznes maydonlarini INSERT qiladi, M/O statusni esa
--     ANIQ beradi (default 'M' ga tayanmaslik uchun, rules aniqlaydi).
--
-- KECHIKTIRILGAN operatsiyalar (kelajak skript — bu faylda YO'Q):
--   Update_Account, Block/Freeze/Close_Account, AML/НИББД REAL adapterlari,
--   парный счёт (контрсчёт) avto-ochish (Справочник парных счетов yuklangach).
-- ============================================================================

SET DEFINE OFF
SET SQLBLANKLINES ON


-- *************************************************************************
-- 1. core_acc_const — konstantalar (statuslar, M/O, balans-map, xato kodlari)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_const AS

    -- --- Состояние счета (core_acc_status FK domeni) -----------------------
    c_st_created        CONSTANT VARCHAR2(20) := 'CREATED';        -- Создан
    c_st_to_approve     CONSTANT VARCHAR2(20) := 'TO_APPROVE';     -- на утверждение (sub)
    c_st_aml_check      CONSTANT VARCHAR2(20) := 'AML_CHECK';      -- На проверке AML (sub)
    c_st_aml_passed     CONSTANT VARCHAR2(20) := 'AML_PASSED';     -- Проверен AML (sub)
    c_st_nibbd_to_send  CONSTANT VARCHAR2(20) := 'NIBBD_TO_SEND';  -- На отправление НИББД (sub)
    c_st_nibbd_sent     CONSTANT VARCHAR2(20) := 'NIBBD_SENT';     -- Отправлен НИББД (sub)
    c_st_nibbd_done     CONSTANT VARCHAR2(20) := 'NIBBD_DONE';     -- Обработан НИББД (sub)
    c_st_approved       CONSTANT VARCHAR2(20) := 'APPROVED';       -- Утвержден (активный)
    c_st_temp_closed    CONSTANT VARCHAR2(20) := 'TEMP_CLOSED';    -- Временно закрыт
    c_st_closed         CONSTANT VARCHAR2(20) := 'CLOSED';         -- Закрыт
    c_st_blocked        CONSTANT VARCHAR2(20) := 'BLOCKED';        -- Блокирован
    c_st_archived       CONSTANT VARCHAR2(20) := 'ARCHIVED';       -- Архивирован
    c_st_deleted        CONSTANT VARCHAR2(20) := 'DELETED';        -- Удален (terminal)

    -- --- Статус счета (M/O — первичный/вторичный) --------------------------
    c_status_primary    CONSTANT CHAR(1) := 'M';   -- ПЕРВИЧНЫЙ — asosiy depozit hisob
    c_status_secondary  CONSTANT CHAR(1) := 'O';   -- ВТОРИЧНЫЙ — qo'shimcha hisob

    -- --- Признак баланса (balance_out) ------------------------------------
    c_bal_on            CONSTANT CHAR(1) := 'B';   -- балансовый
    c_bal_off           CONSTANT CHAR(1) := 'O';   -- внебалансовый (9xxxx)

    -- --- Признак актив-пассив (liability_active) --------------------------
    c_ap_active         CONSTANT CHAR(1) := 'A';   -- актив
    c_ap_passive        CONSTANT CHAR(1) := 'P';   -- пассив

    -- --- Valyuta — so'm (суммовой код) ------------------------------------
    --   Asosiy (M) hisob DOIM so'mda ro'yxatga olinadi (spec l.1858).
    c_currency_sum      CONSTANT VARCHAR2(3) := '000';

    -- --- Mijoz holati (core_cif_clients.client_status) — precondition ------
    c_client_approved   CONSTANT VARCHAR2(20) := 'APPROVED';   -- Утвержден

    -- --- seq_number (NNN) diapazoni ---------------------------------------
    c_seq_first         CONSTANT VARCHAR2(3)  := '001';
    c_seq_min           CONSTANT PLS_INTEGER  := 1;
    c_seq_max           CONSTANT PLS_INTEGER  := 999;   -- 001..999 (spec l.1832)
    c_seq_len           CONSTANT PLS_INTEGER  := 3;

    -- --- Komponent uzunliklari (hisob raqami segmentlari) -----------------
    c_balance_len       CONSTANT PLS_INTEGER := 5;   -- CMMSS
    c_client_code_len   CONSTANT PLS_INTEGER := 8;   -- XXXXXXXX (НИББД)
    c_currency_len      CONSTANT PLS_INTEGER := 3;   -- VVV
    c_account_num_len   CONSTANT PLS_INTEGER := 20;  -- to'liq hisob raqami

    -- --- Mijoz turi (typeof, СПР 21) -> asosiy depozit balans hisobi (СПР19)
    --   SIRIUS «Счета» spec — mijoz turidan asosiy депозит balans nomeri (COA).
    --   Eslatma: 06/07/21 (ЦБ/коммерч.банки/самозанятые) spec jadvalida bo'sh ->
    --     bu yerda map YO'Q (Map_Balance_Account NULL qaytaradi -> caller COA bersin).
    c_coa_any           CONSTANT VARCHAR2(5) := '20296';  -- 00 — любые типы клиентов
    c_coa_government    CONSTANT VARCHAR2(5) := '20202';  -- 01 — Правительство
    c_coa_state_org     CONSTANT VARCHAR2(5) := '20210';  -- 02 — Гос. организации
    c_coa_nonprofit     CONSTANT VARCHAR2(5) := '20212';  -- 03 — Негос. некоммерч.
    c_coa_nonbank_fin   CONSTANT VARCHAR2(5) := '20216';  -- 04 — Небанк. фин. институты
    c_coa_other         CONSTANT VARCHAR2(5) := '20296';  -- 05 — Другие типы клиентов
    c_coa_phys          CONSTANT VARCHAR2(5) := '20206';  -- 08 — Физлица (20206 — Жисмоний шахслар депозити)
    c_coa_private_ent   CONSTANT VARCHAR2(5) := '20208';  -- 09 — Частные предприятия
    c_coa_foreign_cap   CONSTANT VARCHAR2(5) := '20214';  -- 10 — Предпр. с иностр. капиталом
    c_coa_ip            CONSTANT VARCHAR2(5) := '20218';  -- 11 — ИП
    c_coa_budget        CONSTANT VARCHAR2(5) := '20203';  -- 12 — Бюджетные учреждения
    c_coa_road_fund     CONSTANT VARCHAR2(5) := '20205';  -- 13 — Респ. дорожный фонд

    -- --- Norezident tashkilot uchun ruxsat etilgan yagona COA --------------
    --   Спец: норезидент tashkilot -> faqat 20296 (talab bo'yicha depozит), M shart emas.
    c_coa_nonresident   CONSTANT VARCHAR2(5) := '20296';

    -- --- Umumiy javob kodlari ----------------------------------------------
    c_code_ok           CONSTANT NUMBER := 0;
    c_code_error        CONSTANT NUMBER := -1;
    c_msg_ok            CONSTANT VARCHAR2(10) := 'OK';

    -- --- Xato kodlari (E-7: -203xx oralig'i, core_acc — cif -202xx dan ajra)
    c_err_required          CONSTANT PLS_INTEGER := -20310;  -- majburiy maydon bo'sh
    c_err_client_not_found  CONSTANT PLS_INTEGER := -20311;  -- mijoz topilmadi
    c_err_client_not_appr   CONSTANT PLS_INTEGER := -20312;  -- mijoz «Утвержден» emas
    c_err_nibbd_not_reg     CONSTANT PLS_INTEGER := -20313;  -- mijoz НИББД da ro'yxatda emas
    c_err_invalid_currency  CONSTANT PLS_INTEGER := -20314;  -- valyuta (СПР 017) topilmadi
    c_err_invalid_coa       CONSTANT PLS_INTEGER := -20315;  -- balans hisobi (СПР 19) topilmadi/yopiq
    c_err_coa_unresolved    CONSTANT PLS_INTEGER := -20316;  -- balans hisobi turdan aniqlanmadi
    c_err_primary_currency  CONSTANT PLS_INTEGER := -20317;  -- asosiy (M) hisob so'mda bo'lishi shart
    c_err_primary_exists    CONSTANT PLS_INTEGER := -20318;  -- mijozda asosiy (M) hisob allaqachon bor
    c_err_no_primary        CONSTANT PLS_INTEGER := -20319;  -- O hisob uchun M hisob yo'q/aktiv emas
    c_err_seq_exhausted     CONSTANT PLS_INTEGER := -20320;  -- NNN tartib raqami tugadi (999)
    c_err_invalid_account   CONSTANT PLS_INTEGER := -20321;  -- generatsiya qilingan hisob raqami yaroqsiz
    c_err_account_not_found CONSTANT PLS_INTEGER := -20322;  -- hisob topilmadi
    c_err_invalid_state     CONSTANT PLS_INTEGER := -20323;  -- holat o'tishi ruxsat etilmagan
    c_err_maker_eq_checker  CONSTANT PLS_INTEGER := -20324;  -- maker = checker (ikki ko'z)
    c_err_invalid_type      CONSTANT PLS_INTEGER := -20325;  -- client_type (СПР 21) topilmadi
    c_err_deal_required     CONSTANT PLS_INTEGER := -20326;  -- сделка ID majburiy (Reg_nibd 1/2/3)
    c_err_aml_failed        CONSTANT PLS_INTEGER := -20327;  -- AML ro'yxatidan o'tmadi
    c_err_nibbd_failed      CONSTANT PLS_INTEGER := -20328;  -- НИББД ro'yxatga olish xatosi

    -- --- Xato xabarlari (foydalanuvchi tilida) -----------------------------
    c_msg_required          CONSTANT VARCHAR2(200) := 'Majburiy maydon to''ldirilmagan';
    c_msg_client_not_found  CONSTANT VARCHAR2(200) := 'Mijoz topilmadi';
    c_msg_client_not_appr   CONSTANT VARCHAR2(200) := 'Mijoz holati «Утвержден» emas — hisob ochib bo''lmaydi';
    c_msg_nibbd_not_reg     CONSTANT VARCHAR2(200) := 'Mijoz НИББД da ro''yxatga olinmagan — hisob ochish taqiqlanadi';
    c_msg_invalid_currency  CONSTANT VARCHAR2(200) := 'Valyuta kodi (СПР 017) topilmadi';
    c_msg_invalid_coa       CONSTANT VARCHAR2(200) := 'Balans hisobi (СПР 19) topilmadi yoki yopiq';
    c_msg_coa_unresolved    CONSTANT VARCHAR2(200) := 'Mijoz turidan asosiy balans hisobi aniqlanmadi — COA qo''lda kiriting';
    c_msg_primary_currency  CONSTANT VARCHAR2(200) := 'Asosiy (M) depozit hisob faqat so''mda (000) ochiladi';
    c_msg_primary_exists    CONSTANT VARCHAR2(200) := 'Mijozda asosiy (M) depozit hisob allaqachon mavjud';
    c_msg_no_primary        CONSTANT VARCHAR2(200) := 'Qo''shimcha (O) hisob uchun aktiv asosiy (M) hisob talab qilinadi';
    c_msg_seq_exhausted     CONSTANT VARCHAR2(200) := 'Tartib raqami (NNN) tugadi — 999 chegarasi';
    c_msg_invalid_account   CONSTANT VARCHAR2(200) := 'Hosil qilingan hisob raqami yaroqsiz (kontrol kalit)';
    c_msg_account_not_found CONSTANT VARCHAR2(200) := 'Hisob topilmadi';
    c_msg_invalid_state     CONSTANT VARCHAR2(200) := 'Hisob holatini o''zgartirib bo''lmaydi';
    c_msg_maker_eq_checker  CONSTANT VARCHAR2(200) := 'Yaratuvchi va tasdiqlovchi bir xil bo''la olmaydi';
    c_msg_invalid_type      CONSTANT VARCHAR2(200) := 'Mijoz turi (СПР 21) topilmadi';
    c_msg_deal_required     CONSTANT VARCHAR2(200) := 'Сделка (deal_id) majburiy — НИББД признак 1/2/3';
    c_msg_aml_failed        CONSTANT VARCHAR2(200) := 'Hisob AML/shubhali ro''yxatda — tasdiqlash to''xtatildi';
    c_msg_nibbd_failed      CONSTANT VARCHAR2(200) := 'НИББД ro''yxatga olishda xato — hisob tasdiqlanmadi';

END core_acc_const;
/


-- *************************************************************************
-- 2. core_acc_types — record tiplar (Mars RECORD orqali uzatiladi)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_types AS

    -- ---------------------------------------------------------------------------
    -- t_account_rec — hisob ochish (открытие) yagona kirish rekordi.
    --   Caller (JSP/Mars) faqat biznes maydonlarini to'ldiradi; hisob raqami
    --   (account_number/control_key/account_id) — trigger; balance_account —
    --   berilmasa mijoz turidan AUTO (svc_util); seq_number — service AUTO;
    --   status (M/O) — rules aniqlaydi. %TYPE sxemaga aniq bog'langan (drift YO'Q).
    -- ---------------------------------------------------------------------------
    TYPE t_account_rec IS RECORD (
        -- --- Kirish/ID maydonlari -----------------------------------------
        account_id        core_acc_accounts.account_id%TYPE,
        account_number    core_acc_accounts.account_number%TYPE,   -- trigger beradi (NULL kiriting)
        control_key       core_acc_accounts.control_key%TYPE,      -- trigger beradi

        -- --- Hisob raqamining 5 komponenti --------------------------------
        balance_account   core_acc_accounts.balance_account%TYPE,  -- CMMSS — berilmasa turdan AUTO
        currency_code     core_acc_accounts.currency_code%TYPE,    -- VVV — so'm=000 (M majburiy)
        client_code       core_acc_accounts.client_code%TYPE,      -- XXXXXXXX — НИББД mijoz kodi (8)
        seq_number        core_acc_accounts.seq_number%TYPE,       -- NNN — service AUTO (001..999)

        -- --- Mijoz bog'lanishi --------------------------------------------
        client_id         core_acc_accounts.client_id%TYPE,        -- core_cif_clients.client_id (majburiy)
        client_name       core_acc_accounts.client_name%TYPE,      -- Владелец счета (mijozdan AUTO)
        client_type       core_acc_accounts.client_type%TYPE,      -- typeof — balans tanlash (СПР 21)

        -- --- Nomi va tasnif -----------------------------------------------
        name              core_acc_accounts.name%TYPE,             -- Наименование счета (majburiy)
        acc_type          core_acc_accounts.acc_type%TYPE,         -- Тип счета (produkt, majburiy)
        sub_coa           core_acc_accounts.sub_coa%TYPE,          -- Субсчет (default 000000)
        special_code      core_acc_accounts.special_code%TYPE,     -- Спец. характеристика
        module_code       core_acc_accounts.module_code%TYPE,      -- Код модуля
        group_code        core_acc_accounts.group_code%TYPE,       -- Код группы
        category          core_acc_accounts.category%TYPE,         -- Категория
        security_level    core_acc_accounts.security_level%TYPE,   -- Степень доступа (AUTO)
        deal_id           core_acc_accounts.deal_id%TYPE,          -- Сделка ID (Reg_nibd 1/2/3 da majburiy)

        -- --- Aktiv/passiv + balans turi + lifecycle + M/O statusi ----------
        liability_active  core_acc_accounts.liability_active%TYPE, -- A/P — COA dan AUTO
        balance_out       core_acc_accounts.balance_out%TYPE,      -- B/O — COA dan AUTO
        state             core_acc_accounts.state%TYPE,            -- Состояние счета (lifecycle) — service CREATED
        status            core_acc_accounts.status%TYPE,           -- M/O — rules aniqlaydi

        -- --- Filial / ofis -------------------------------------------------
        branch_code       core_acc_accounts.branch_code%TYPE,      -- Код филиала (majburiy)
        branch_cb_code    core_acc_accounts.branch_cb_code%TYPE,   -- Код офиса

        -- --- AML / НИББД / rezidentlik ------------------------------------
        reg_nibd          core_acc_accounts.reg_nibd%TYPE,         -- НИББД признак (0/1/2/3/9)
        resident_flag     core_acc_accounts.resident_flag%TYPE,    -- Y/N — mijozdan AUTO
        single_window_ref core_acc_accounts.single_window_ref%TYPE,-- Единое окно kanal havolasi

        -- --- Sanalar -------------------------------------------------------
        open_date         core_acc_accounts.open_date%TYPE,        -- ochilgan oper. kun
        created_oper_day  core_acc_accounts.created_oper_day%TYPE, -- yaratilgan oper. kun

        -- --- Maker-Checker / audit ----------------------------------------
        maker_user        core_acc_accounts.maker_user%TYPE,       -- Maker (yaratuvchi)
        created_by        core_acc_accounts.created_by%TYPE        -- audit user
    );

    -- ---------------------------------------------------------------------------
    -- t_aml_result — AML tekshiruvi natijasi (adapter; approve gate uchun)
    -- ---------------------------------------------------------------------------
    TYPE t_aml_result IS RECORD (
        passed   CHAR(1),
        risk     VARCHAR2(10),
        reason   VARCHAR2(200)
    );

    -- ---------------------------------------------------------------------------
    -- t_nibbd_result — НИББД ro'yxatga olish natijasi (adapter; approve gate)
    -- ---------------------------------------------------------------------------
    TYPE t_nibbd_result IS RECORD (
        registered CHAR(1),
        real_code  VARCHAR2(8),
        reason     VARCHAR2(200)
    );

END core_acc_types;
/


-- *************************************************************************
-- 3. core_acc_svc_util — yordamchi servis funksiyalari (kod EMAS, biznes)
--    Eslatma: 20 xonali hisob raqami / Mod-11 kalit — core_acc_util da
--    (01_acc_util) va trigger ichida. Bu paket faqat servis qoidalari uchun:
--    balansni turdan tanlash, NNN keyingi raqam, M/O qarori.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_svc_util AS

    -- ---------------------------------------------------------------------------
    -- Map_Balance_Account — mijoz turidan (typeof, СПР 21) asosiy депозит balans
    --   hisobi (COA, СПР 19) ni AUTO tanlaydi (SIRIUS «Счета» turlar jadvali).
    --   Map topilmasa NULL qaytaradi (caller COA ni qo'lda berishi shart:
    --   06/07/21 turlari, norezident tashkilot va h.k.).
    -- ---------------------------------------------------------------------------
    FUNCTION Map_Balance_Account(i_client_type IN VARCHAR2) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Is_Sum_Currency — valyuta so'mmi (000 — суммовой kod)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Sum_Currency(i_currency IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Balance_Out_From_Coa — COA dan балансовый/внебалансовый belgisi
    --   Внебалансовый (O) — balans 9 bilan boshlanadi; aks holda B (балансовый).
    -- ---------------------------------------------------------------------------
    FUNCTION Balance_Out_From_Coa(i_coa IN VARCHAR2) RETURN CHAR;

END core_acc_svc_util;
/


CREATE OR REPLACE PACKAGE BODY core_acc_svc_util AS

    -- ---------------------------------------------------------------------------
    -- Map_Balance_Account — typeof (СПР 21) -> asosiy депозит COA (СПР 19)
    -- ---------------------------------------------------------------------------
    FUNCTION Map_Balance_Account(i_client_type IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF i_client_type IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN CASE i_client_type
                   WHEN '00' THEN core_acc_const.c_coa_any
                   WHEN '01' THEN core_acc_const.c_coa_government
                   WHEN '02' THEN core_acc_const.c_coa_state_org
                   WHEN '03' THEN core_acc_const.c_coa_nonprofit
                   WHEN '04' THEN core_acc_const.c_coa_nonbank_fin
                   WHEN '05' THEN core_acc_const.c_coa_other
                   WHEN '08' THEN core_acc_const.c_coa_phys
                   WHEN '09' THEN core_acc_const.c_coa_private_ent
                   WHEN '10' THEN core_acc_const.c_coa_foreign_cap
                   WHEN '11' THEN core_acc_const.c_coa_ip
                   WHEN '12' THEN core_acc_const.c_coa_budget
                   WHEN '13' THEN core_acc_const.c_coa_road_fund
                   ELSE NULL   -- 06/07/21 va boshqalar: spec bo'sh -> caller COA bersin
               END;
    END Map_Balance_Account;

    -- ---------------------------------------------------------------------------
    -- Is_Sum_Currency — 000 (суммовой)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Sum_Currency(i_currency IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN i_currency = core_acc_const.c_currency_sum;
    END Is_Sum_Currency;

    -- ---------------------------------------------------------------------------
    -- Balance_Out_From_Coa — 9xxxx -> внебалансовый (O); aks holda балансовый (B)
    -- ---------------------------------------------------------------------------
    FUNCTION Balance_Out_From_Coa(i_coa IN VARCHAR2) RETURN CHAR IS
    BEGIN
        IF i_coa IS NOT NULL AND SUBSTR(i_coa, 1, 1) = '9' THEN
            RETURN core_acc_const.c_bal_off;
        END IF;
        RETURN core_acc_const.c_bal_on;
    END Balance_Out_From_Coa;

END core_acc_svc_util;
/


-- *************************************************************************
-- 4. core_acc_logger — audit/log (stub — COMMIT yo'q, E-5)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_logger AS

    -- ---------------------------------------------------------------------------
    -- Log — sodda audit log (hozir DBMS_OUTPUT stub; keyin core_acc_audit_log)
    --   COMMIT QILMAYDI (E-5) — service tranzaksiyasi tarkibida ishlaydi.
    -- ---------------------------------------------------------------------------
    PROCEDURE Log(
        i_account_id IN NUMBER,
        i_action     IN VARCHAR2,
        i_detail     IN VARCHAR2 DEFAULT NULL,
        i_user       IN NUMBER   DEFAULT NULL
    );

END core_acc_logger;
/


CREATE OR REPLACE PACKAGE BODY core_acc_logger AS

    -- ---------------------------------------------------------------------------
    -- Log — stub (audit jadval (core_acc_audit_log) qo'shilganda INSERT bilan almash)
    -- ---------------------------------------------------------------------------
    PROCEDURE Log(
        i_account_id IN NUMBER,
        i_action     IN VARCHAR2,
        i_detail     IN VARCHAR2 DEFAULT NULL,
        i_user       IN NUMBER   DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            'ACC-AUDIT [' || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') || '] '
            || 'account=' || NVL(TO_CHAR(i_account_id), '-')
            || ' user='   || NVL(TO_CHAR(i_user), '-')
            || ' action=' || i_action
            || CASE WHEN i_detail IS NOT NULL THEN ' detail=' || i_detail END);
    END Log;

END core_acc_logger;
/


-- *************************************************************************
-- 5. core_acc_aml — AML/KYC gate adapter (STUB; approve da gate sifatida wired)
--    SIRIUS: Утвердить paytida shubhali ro'yxat bilan tekshirish. Hozir STUB =
--    PASSED, lekin service GATE sifatida ishlatadi (FAILED -> RAISE -> ROLLBACK).
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_aml AS

    -- ---------------------------------------------------------------------------
    -- Check_Account — AML tekshiruvi (STUB). Natija: passed/risk/reason. COMMIT YO'Q.
    -- ---------------------------------------------------------------------------
    FUNCTION Check_Account(i_account_id IN NUMBER) RETURN core_acc_types.t_aml_result;

END core_acc_aml;
/


CREATE OR REPLACE PACKAGE BODY core_acc_aml AS

    -- ---------------------------------------------------------------------------
    -- Check_Account — STUB: har doim PASSED (LOW). Real adapter o'rnida gate.
    -- ---------------------------------------------------------------------------
    FUNCTION Check_Account(i_account_id IN NUMBER) RETURN core_acc_types.t_aml_result IS
        v_res core_acc_types.t_aml_result;
    BEGIN
        v_res.passed := 'Y';
        v_res.risk   := 'LOW';
        v_res.reason := NULL;
        RETURN v_res;
    END Check_Account;

END core_acc_aml;
/


-- *************************************************************************
-- 6. core_acc_nibbd — НИББД ro'yxatga olish gate adapter (STUB; wired)
--    SIRIUS: hisob НИББД da ro'yxatga olinishi shart; xato bo'lsa tasdiqlash
--    TAQIQLANADI. Hozir STUB = registered='Y'; service GATE sifatida ishlatadi.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_nibbd AS

    -- ---------------------------------------------------------------------------
    -- Register_Account — НИББД ro'yxatga olish (STUB). registered/real_code/reason.
    --   COMMIT YO'Q. Real versiya СПР 019 НИББД xizmatiga so'rov yuboradi.
    -- ---------------------------------------------------------------------------
    FUNCTION Register_Account(i_account_id IN NUMBER) RETURN core_acc_types.t_nibbd_result;

END core_acc_nibbd;
/


CREATE OR REPLACE PACKAGE BODY core_acc_nibbd AS

    -- ---------------------------------------------------------------------------
    -- Register_Account — STUB: registered='Y', real kod almashuvi YO'Q.
    -- ---------------------------------------------------------------------------
    FUNCTION Register_Account(i_account_id IN NUMBER) RETURN core_acc_types.t_nibbd_result IS
        v_res core_acc_types.t_nibbd_result;
    BEGIN
        v_res.registered := 'Y';
        v_res.real_code  := NULL;
        v_res.reason     := NULL;
        RETURN v_res;
    END Register_Account;

END core_acc_nibbd;
/


-- *************************************************************************
-- 7. core_acc_data_reader — faqat SELECT (read-only, DML YO'Q)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_data_reader AS

    -- ---------------------------------------------------------------------------
    -- Get_Account — bitta hisob (satr) account_id bo'yicha
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Account(
        i_account_id IN  NUMBER,
        o_row        OUT core_acc_accounts%ROWTYPE
    );

    -- ---------------------------------------------------------------------------
    -- Account_Exists — account_id bo'yicha hisob bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Account_Exists(i_account_id IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Get_Status — hisobning joriy holati (state — lifecycle)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Status(i_account_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Maker — hisobni yaratgan maker_user (Maker-Checker tekshiruvi)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Maker(i_account_id IN NUMBER) RETURN NUMBER;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Status — mijoz holati (core_cif_clients.client_status)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Status(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Is_Client_Nibbd_Registered — mijoz НИББД da ro'yxatda (Y/N -> BOOLEAN)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Client_Nibbd_Registered(i_client_id IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Code — mijozning client_code (НИББД 8 xona)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Code(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Name — mijoz nomi (full_name — Владелец счета)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Name(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Type — mijoz turi (client_type, typeof) — balans tanlash uchun
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Type(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Resident — mijoz rezidentligi (resident_flag, Y/N)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Resident(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Currency_Valid — valyuta kodi СПР 017 (core_ref_currency) da bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Currency_Valid(i_currency IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Coa_Valid — balans hisobi СПР 19 (core_ref_coa) da bor va aktivmi
    --   condition = 'A' (aktiv) bo'lishi shart (deaktiv COA ga ochib bo'lmaydi).
    -- ---------------------------------------------------------------------------
    FUNCTION Coa_Valid(i_coa IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Coa_Active_Passive — COA dan актив/пассив (type_acc_code 'A'/'P')
    --   core_ref_coa.type_acc_code/condition asosida (NULL bo'lsa NULL).
    -- ---------------------------------------------------------------------------
    FUNCTION Coa_Active_Passive(i_coa IN VARCHAR2) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Client_Type_Valid — client_type СПР 21 (core_ref_client_type) da bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Type_Valid(i_type IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Client_Has_Primary — mijozda asosiy (M) depozit hisob bormi (terminal emas)
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Has_Primary(i_client_id IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Client_Has_Active_Primary — mijozda АКТИВ (APPROVED) asosiy (M) hisob bormi
    --   O (вторичный) hisob ochish uchun M hisob «Активный» bo'lishi shart (spec).
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Has_Active_Primary(i_client_id IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Max_Seq_For_Group — (balans + valyuta) guruhidagi eng katta NNN -> NUMBER
    --   Yangi NNN = MAX+1. Hisob bo'lmasa 0 qaytaradi (-> birinchi = 001).
    --   Scope: balans COA + valyuta (spec NNN ni balans hisobiga bog'laydi).
    -- ---------------------------------------------------------------------------
    FUNCTION Max_Seq_For_Group(
        i_balance  IN VARCHAR2,
        i_currency IN VARCHAR2
    ) RETURN NUMBER;

END core_acc_data_reader;
/


CREATE OR REPLACE PACKAGE BODY core_acc_data_reader AS

    -- ---------------------------------------------------------------------------
    -- Get_Account — account_id bo'yicha satr (NO_DATA_FOUND -> bo'sh record)
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Account(
        i_account_id IN  NUMBER,
        o_row        OUT core_acc_accounts%ROWTYPE
    ) IS
        v_empty core_acc_accounts%ROWTYPE;
    BEGIN
        SELECT *
          INTO o_row
          FROM core_acc_accounts
         WHERE account_id = i_account_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_row := v_empty;
    END Get_Account;

    -- ---------------------------------------------------------------------------
    -- Account_Exists — account_id bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Account_Exists(i_account_id IN NUMBER) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_acc_accounts
         WHERE account_id = i_account_id;
        RETURN v_cnt > 0;
    END Account_Exists;

    -- ---------------------------------------------------------------------------
    -- Get_Status — joriy state (lifecycle)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Status(i_account_id IN NUMBER) RETURN VARCHAR2 IS
        v_state core_acc_accounts.state%TYPE;
    BEGIN
        SELECT state INTO v_state
          FROM core_acc_accounts
         WHERE account_id = i_account_id;
        RETURN v_state;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Status;

    -- ---------------------------------------------------------------------------
    -- Get_Maker — yaratgan maker_user
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Maker(i_account_id IN NUMBER) RETURN NUMBER IS
        v_maker core_acc_accounts.maker_user%TYPE;
    BEGIN
        SELECT maker_user INTO v_maker
          FROM core_acc_accounts
         WHERE account_id = i_account_id;
        RETURN v_maker;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Maker;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Status — mijoz holati (core_cif_clients)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Status(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_status core_cif_clients.client_status%TYPE;
    BEGIN
        SELECT client_status INTO v_status
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Client_Status;

    -- ---------------------------------------------------------------------------
    -- Is_Client_Nibbd_Registered — nibbd_registered = 'Y'
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Client_Nibbd_Registered(i_client_id IN NUMBER) RETURN BOOLEAN IS
        v_reg core_cif_clients.nibbd_registered%TYPE;
    BEGIN
        SELECT nibbd_registered INTO v_reg
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_reg = 'Y';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END Is_Client_Nibbd_Registered;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Code — НИББД 8 xona kod
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Code(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_code core_cif_clients.client_code%TYPE;
    BEGIN
        SELECT client_code INTO v_code
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Client_Code;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Name — full_name (Владелец счета)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Name(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_name core_cif_clients.full_name%TYPE;
    BEGIN
        SELECT full_name INTO v_name
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Client_Name;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Type — client_type (typeof, СПР 21)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Type(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_type core_cif_clients.client_type%TYPE;
    BEGIN
        SELECT client_type INTO v_type
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_type;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Client_Type;

    -- ---------------------------------------------------------------------------
    -- Get_Client_Resident — resident_flag (Y/N)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Client_Resident(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_res core_cif_clients.resident_flag%TYPE;
    BEGIN
        SELECT resident_flag INTO v_res
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_res;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Client_Resident;

    -- ---------------------------------------------------------------------------
    -- Currency_Valid — СПР 017 (core_ref_currency)
    -- ---------------------------------------------------------------------------
    FUNCTION Currency_Valid(i_currency IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_currency IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_ref_currency
         WHERE code = i_currency;
        RETURN v_cnt > 0;
    END Currency_Valid;

    -- ---------------------------------------------------------------------------
    -- Coa_Valid — СПР 19 (core_ref_coa) da bor va aktiv (condition='A')
    -- ---------------------------------------------------------------------------
    FUNCTION Coa_Valid(i_coa IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_coa IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_ref_coa
         WHERE code = i_coa
           AND condition = 'A';
        RETURN v_cnt > 0;
    END Coa_Valid;

    -- ---------------------------------------------------------------------------
    -- Coa_Active_Passive — type_acc_code / sign asosida актив/пассив
    --   core_ref_coa da актив/пассив to'g'ridan-to'g'ri ustun yo'q; sxema bo'yicha
    --   condition (A/P emas — bu status). Mavjud ustunlarda ishonchli A/P
    --   manbasi yo'q -> NULL qaytaramiz (caller bersa saqlanadi, aks holda NULL).
    -- ---------------------------------------------------------------------------
    FUNCTION Coa_Active_Passive(i_coa IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        -- core_ref_coa da актив/пассив requisiti aniq emas — NULL (caller/keyingi
        -- spravochnik bilan to'ldiriladi). Stub: hozir aniqlamaydi.
        RETURN NULL;
    END Coa_Active_Passive;

    -- ---------------------------------------------------------------------------
    -- Client_Type_Valid — СПР 21 (core_ref_client_type)
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Type_Valid(i_type IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_type IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_ref_client_type
         WHERE code = i_type;
        RETURN v_cnt > 0;
    END Client_Type_Valid;

    -- ---------------------------------------------------------------------------
    -- Client_Has_Primary — mijozda M hisob bor (terminal CLOSED/DELETED emas)
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Has_Primary(i_client_id IN NUMBER) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_acc_accounts
         WHERE client_id = i_client_id
           AND status    = core_acc_const.c_status_primary
           AND state NOT IN (core_acc_const.c_st_closed,
                             core_acc_const.c_st_deleted);
        RETURN v_cnt > 0;
    END Client_Has_Primary;

    -- ---------------------------------------------------------------------------
    -- Client_Has_Active_Primary — M hisob mavjud va APPROVED (Активный)
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Has_Active_Primary(i_client_id IN NUMBER) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_acc_accounts
         WHERE client_id = i_client_id
           AND status    = core_acc_const.c_status_primary
           AND state     = core_acc_const.c_st_approved;
        RETURN v_cnt > 0;
    END Client_Has_Active_Primary;

    -- ---------------------------------------------------------------------------
    -- Max_Seq_For_Group — (balans + valyuta) guruhidagi MAX(NNN) -> NUMBER
    -- ---------------------------------------------------------------------------
    FUNCTION Max_Seq_For_Group(
        i_balance  IN VARCHAR2,
        i_currency IN VARCHAR2
    ) RETURN NUMBER IS
        v_max NUMBER;
    BEGIN
        SELECT NVL(MAX(TO_NUMBER(seq_number)), 0) INTO v_max
          FROM core_acc_accounts
         WHERE balance_account = i_balance
           AND currency_code   = i_currency;
        RETURN v_max;
    END Max_Seq_For_Group;

END core_acc_data_reader;
/


-- *************************************************************************
-- 8. core_acc_repo — faqat DML (INSERT/UPDATE) — COMMIT YO'Q (E-5)
--    Trigger bilan koordinatsiya: account_id, account_number, control_key,
--    created_at, updated_at, r_uid — trigger beradi, repo TEGMAYDI.
--    repo 5 komponent (balance/currency/client_code/seq) + biznes maydonlar +
--    M/O statusni ANIQ beradi (rules aniqlagan qiymat).
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_repo AS

    -- ---------------------------------------------------------------------------
    -- Insert_Account — core_acc_accounts INSERT, account_id + account_number
    --   RETURNING orqali qaytaradi (trigger generatsiya qilgan qiymatlar).
    --   account_number/control_key/account_id KIRITILMAYDI (trigger beradi).
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Account(io_rec IN OUT core_acc_types.t_account_rec);

    -- ---------------------------------------------------------------------------
    -- Set_State — state (lifecycle) yangilash (state machine bosqichlari)
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_State(
        i_account_id IN NUMBER,
        i_state      IN VARCHAR2,
        i_user       IN NUMBER
    );

    -- ---------------------------------------------------------------------------
    -- Set_Aml_Checked — AML tekshiruvi vaqti (aml_checked_at) yozish
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Aml_Checked(
        i_account_id IN NUMBER,
        i_user       IN NUMBER
    );

    -- ---------------------------------------------------------------------------
    -- Set_Nibbd_Registered — НИББД ro'yxat natijasi (nibbd_reg_at) yozish
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Nibbd_Registered(
        i_account_id IN NUMBER,
        i_user       IN NUMBER
    );

    -- ---------------------------------------------------------------------------
    -- Approve — APPROVED (Утвержден/Активный) ga o'tkazish (checker/approved_at)
    --   open_date — APPROVED da o'rnatiladi (hisob faol bo'lgan kun).
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve(
        i_account_id IN NUMBER,
        i_checker    IN NUMBER
    );

END core_acc_repo;
/


CREATE OR REPLACE PACKAGE BODY core_acc_repo AS

    -- ---------------------------------------------------------------------------
    -- Insert_Account — satr INSERT (trigger-set ustunlar KIRITILMAYDI)
    --   account_id va account_number trigger beradi -> RETURNING bilan io_rec ga.
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Account(io_rec IN OUT core_acc_types.t_account_rec) IS
    BEGIN
        INSERT INTO core_acc_accounts (
            balance_account, currency_code, client_code, seq_number,
            client_id, client_name, client_type,
            name, acc_type, sub_coa, special_code, module_code, group_code,
            category, security_level, deal_id,
            liability_active, balance_out, state, status,
            branch_code, branch_cb_code,
            reg_nibd, resident_flag, single_window_ref,
            open_date, created_oper_day,
            maker_user, created_by
        ) VALUES (
            io_rec.balance_account, io_rec.currency_code, io_rec.client_code, io_rec.seq_number,
            io_rec.client_id, io_rec.client_name, io_rec.client_type,
            io_rec.name, io_rec.acc_type, NVL(io_rec.sub_coa, '000000'),
            io_rec.special_code, io_rec.module_code, io_rec.group_code,
            io_rec.category, io_rec.security_level, io_rec.deal_id,
            io_rec.liability_active, io_rec.balance_out,
            NVL(io_rec.state, core_acc_const.c_st_created), io_rec.status,
            io_rec.branch_code, io_rec.branch_cb_code,
            io_rec.reg_nibd, io_rec.resident_flag, io_rec.single_window_ref,
            io_rec.open_date, io_rec.created_oper_day,
            io_rec.maker_user, io_rec.created_by
        )
        RETURNING account_id, account_number, control_key, status, state
             INTO io_rec.account_id, io_rec.account_number, io_rec.control_key,
                  io_rec.status, io_rec.state;
    END Insert_Account;

    -- ---------------------------------------------------------------------------
    -- Set_State — state (lifecycle) yangilash
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_State(
        i_account_id IN NUMBER,
        i_state      IN VARCHAR2,
        i_user       IN NUMBER
    ) IS
    BEGIN
        UPDATE core_acc_accounts
           SET state             = i_state,
               modified_oper_day = TRUNC(SYSDATE),
               updated_by        = i_user
         WHERE account_id = i_account_id;
    END Set_State;

    -- ---------------------------------------------------------------------------
    -- Set_Aml_Checked — aml_checked_at = SYSTIMESTAMP
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Aml_Checked(
        i_account_id IN NUMBER,
        i_user       IN NUMBER
    ) IS
    BEGIN
        UPDATE core_acc_accounts
           SET aml_checked_at = SYSTIMESTAMP,
               updated_by     = i_user
         WHERE account_id = i_account_id;
    END Set_Aml_Checked;

    -- ---------------------------------------------------------------------------
    -- Set_Nibbd_Registered — nibbd_reg_at = SYSTIMESTAMP
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Nibbd_Registered(
        i_account_id IN NUMBER,
        i_user       IN NUMBER
    ) IS
    BEGIN
        UPDATE core_acc_accounts
           SET nibbd_reg_at = SYSTIMESTAMP,
               updated_by   = i_user
         WHERE account_id = i_account_id;
    END Set_Nibbd_Registered;

    -- ---------------------------------------------------------------------------
    -- Approve — APPROVED + checker/approved_at/open_date
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve(
        i_account_id IN NUMBER,
        i_checker    IN NUMBER
    ) IS
    BEGIN
        UPDATE core_acc_accounts
           SET state        = core_acc_const.c_st_approved,
               checker_user = i_checker,
               approved_at  = SYSTIMESTAMP,
               open_date    = NVL(open_date, TRUNC(SYSDATE)),
               updated_by   = i_checker
         WHERE account_id = i_account_id;
    END Approve;

END core_acc_repo;
/


-- *************************************************************************
-- 9. core_acc_rules — validatsiya (DML YO'Q; qoida buzilsa RAISE -203xx)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_rules AS

    -- ---------------------------------------------------------------------------
    -- Validate_For_Open — hisob ochish uchun to'liq tekshiruv (io_rec IN OUT)
    --   AUTO to'ldiradi: client_code/client_name/client_type/resident_flag
    --     (mijozdan), balance_account (turdan, berilmasa), liability_active/
    --     balance_out (COA dan), seq_number (keyingi NNN), status (M/O qarori).
    --   Tekshiradi: mijoz mavjud+APPROVED+НИББД; majburiy maydonlar; valyuta;
    --     balans hisobi; M -> so'm & yagona; O -> aktiv M mavjud; deal (НИББД 1/2/3);
    --     NNN diapazoni; hosil bo'ladigan hisob raqami yaroqliligi.
    --   Buzilsa RAISE_APPLICATION_ERROR(-203xx).
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_For_Open(io_rec IN OUT core_acc_types.t_account_rec);

    -- ---------------------------------------------------------------------------
    -- Validate_Approve — Утвердить uchun (holat CREATED + Maker-Checker)
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_Approve(
        i_account_id     IN NUMBER,
        i_current_state  IN VARCHAR2,
        i_maker          IN NUMBER,
        i_checker        IN NUMBER
    );

END core_acc_rules;
/


CREATE OR REPLACE PACKAGE BODY core_acc_rules AS

    -- ---------------------------------------------------------------------------
    -- p_require — qiymat bo'sh bo'lsa -20310 ko'taradi
    -- ---------------------------------------------------------------------------
    PROCEDURE p_require(i_value IN VARCHAR2, i_field IN VARCHAR2) IS
    BEGIN
        IF i_value IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_required,
                core_acc_const.c_msg_required || ': ' || i_field);
        END IF;
    END p_require;

    -- ---------------------------------------------------------------------------
    -- p_resolve_client — mijozdan AUTO maydonlar (code/name/type/resident) +
    --   mavjudlik / APPROVED / НИББД precondition tekshiruvi
    -- ---------------------------------------------------------------------------
    PROCEDURE p_resolve_client(io_rec IN OUT core_acc_types.t_account_rec) IS
        v_status core_cif_clients.client_status%TYPE;
    BEGIN
        -- client_id majburiy
        IF io_rec.client_id IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_required,
                core_acc_const.c_msg_required || ': client_id');
        END IF;

        -- Mijoz mavjudligi
        v_status := core_acc_data_reader.Get_Client_Status(io_rec.client_id);
        IF v_status IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_client_not_found,
                core_acc_const.c_msg_client_not_found || ': ' || io_rec.client_id);
        END IF;

        -- Mijoz holati «Утвержден» (APPROVED) bo'lishi shart
        IF v_status <> core_acc_const.c_client_approved THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_client_not_appr,
                core_acc_const.c_msg_client_not_appr
                || ' (joriy: ' || v_status || ')');
        END IF;

        -- Mijoz НИББД da ro'yxatga olingan bo'lishi shart
        IF NOT core_acc_data_reader.Is_Client_Nibbd_Registered(io_rec.client_id) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_nibbd_not_reg,
                core_acc_const.c_msg_nibbd_not_reg);
        END IF;

        -- AUTO: client_code / client_name / client_type / resident_flag
        IF io_rec.client_code IS NULL THEN
            io_rec.client_code := core_acc_data_reader.Get_Client_Code(io_rec.client_id);
        END IF;
        IF io_rec.client_name IS NULL THEN
            io_rec.client_name := core_acc_data_reader.Get_Client_Name(io_rec.client_id);
        END IF;
        IF io_rec.client_type IS NULL THEN
            io_rec.client_type := core_acc_data_reader.Get_Client_Type(io_rec.client_id);
        END IF;
        IF io_rec.resident_flag IS NULL THEN
            io_rec.resident_flag := core_acc_data_reader.Get_Client_Resident(io_rec.client_id);
        END IF;

        -- client_code НИББД 8 xona kod majburiy (hisob raqamiga kiradi)
        IF io_rec.client_code IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_required,
                core_acc_const.c_msg_required || ': client_code (НИББД)');
        END IF;
    END p_resolve_client;

    -- ---------------------------------------------------------------------------
    -- p_resolve_coa — balans hisobi (COA) ni turdan AUTO tanlash + tekshirish
    --   liability_active / balance_out AUTO (COA dan).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_resolve_coa(io_rec IN OUT core_acc_types.t_account_rec) IS
    BEGIN
        -- client_type (СПР 21) mavjud bo'lishi shart (balans tanlash uchun)
        IF NOT core_acc_data_reader.Client_Type_Valid(io_rec.client_type) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_type,
                core_acc_const.c_msg_invalid_type || ': ' || io_rec.client_type);
        END IF;

        -- COA berilmagan -> mijoz turidan AUTO tanlash
        IF io_rec.balance_account IS NULL THEN
            io_rec.balance_account := core_acc_svc_util.Map_Balance_Account(io_rec.client_type);
        END IF;

        -- Hali ham NULL -> turdan aniqlanmadi (06/07/21 va h.k.) -> caller bersin
        IF io_rec.balance_account IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_coa_unresolved,
                core_acc_const.c_msg_coa_unresolved);
        END IF;

        -- Norezident tashkilot uchun faqat 20296 ruxsat (spec)
        IF io_rec.resident_flag = 'N'
           AND io_rec.balance_account <> core_acc_const.c_coa_nonresident THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_coa,
                core_acc_const.c_msg_invalid_coa
                || ': norezident uchun faqat ' || core_acc_const.c_coa_nonresident);
        END IF;

        -- COA СПР 19 da bor va aktiv bo'lishi shart
        IF NOT core_acc_data_reader.Coa_Valid(io_rec.balance_account) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_coa,
                core_acc_const.c_msg_invalid_coa || ': ' || io_rec.balance_account);
        END IF;

        -- balance_out (B/O) AUTO COA dan (9xxxx -> внебалансовый)
        IF io_rec.balance_out IS NULL THEN
            io_rec.balance_out := core_acc_svc_util.Balance_Out_From_Coa(io_rec.balance_account);
        END IF;
        -- liability_active (A/P) — COA dan (manba aniq bo'lmasa NULL qoladi)
        IF io_rec.liability_active IS NULL THEN
            io_rec.liability_active := core_acc_data_reader.Coa_Active_Passive(io_rec.balance_account);
        END IF;
    END p_resolve_coa;

    -- ---------------------------------------------------------------------------
    -- p_decide_mo_status — M/O (первичный/вторичный) qarorini aniqlash
    --   M (первичный): so'm (000) + mijozda hali M yo'q -> birinchi asosiy hisob.
    --   Aks holda O (вторичный): mijozda aktiv M bo'lishi shart (norezident
    --     tashkilot bundan mustasno — M talab qilinmaydi).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_decide_mo_status(io_rec IN OUT core_acc_types.t_account_rec) IS
        v_has_primary BOOLEAN;
    BEGIN
        v_has_primary := core_acc_data_reader.Client_Has_Primary(io_rec.client_id);

        -- so'm + M yo'q -> bu hisob M (первичный)
        IF core_acc_svc_util.Is_Sum_Currency(io_rec.currency_code)
           AND NOT v_has_primary THEN
            io_rec.status := core_acc_const.c_status_primary;
        ELSE
            io_rec.status := core_acc_const.c_status_secondary;
        END IF;

        -- M qoidasi: faqat so'mda (000) bo'lishi shart
        IF io_rec.status = core_acc_const.c_status_primary
           AND NOT core_acc_svc_util.Is_Sum_Currency(io_rec.currency_code) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_primary_currency,
                core_acc_const.c_msg_primary_currency);
        END IF;

        -- M yagona: agar bu M bo'lsa, mijozda boshqa M bo'lmasligi shart
        IF io_rec.status = core_acc_const.c_status_primary AND v_has_primary THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_primary_exists,
                core_acc_const.c_msg_primary_exists);
        END IF;

        -- O qoidasi: aktiv (APPROVED) M hisob mavjud bo'lishi shart
        --   (norezident tashkilot bundan mustasno — M talab qilinmaydi).
        IF io_rec.status = core_acc_const.c_status_secondary
           AND io_rec.resident_flag = 'Y'
           AND NOT core_acc_data_reader.Client_Has_Active_Primary(io_rec.client_id) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_no_primary,
                core_acc_const.c_msg_no_primary);
        END IF;
    END p_decide_mo_status;

    -- ---------------------------------------------------------------------------
    -- p_assign_seq — keyingi NNN tartib raqamini aniqlash (001..999)
    --   Scope: (balans COA + valyuta). MAX(NNN)+1; 999 dan oshsa -20320.
    --   caller seq_number bergan bo'lsa hurmat qilinadi (tekshiriladi).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_assign_seq(io_rec IN OUT core_acc_types.t_account_rec) IS
        v_max NUMBER;
        v_next NUMBER;
    BEGIN
        IF io_rec.seq_number IS NOT NULL THEN
            -- caller bergan -> diapazon tekshiruvi (001..999)
            IF NOT REGEXP_LIKE(io_rec.seq_number, '^[0-9]{3}$')
               OR TO_NUMBER(io_rec.seq_number) < core_acc_const.c_seq_min
               OR TO_NUMBER(io_rec.seq_number) > core_acc_const.c_seq_max THEN
                RAISE_APPLICATION_ERROR(core_acc_const.c_err_seq_exhausted,
                    core_acc_const.c_msg_seq_exhausted || ': ' || io_rec.seq_number);
            END IF;
            RETURN;
        END IF;

        v_max  := core_acc_data_reader.Max_Seq_For_Group(io_rec.balance_account,
                                                         io_rec.currency_code);
        v_next := v_max + 1;
        IF v_next > core_acc_const.c_seq_max THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_seq_exhausted,
                core_acc_const.c_msg_seq_exhausted);
        END IF;
        io_rec.seq_number := LPAD(TO_CHAR(v_next), core_acc_const.c_seq_len, '0');
    END p_assign_seq;

    -- ---------------------------------------------------------------------------
    -- Validate_For_Open — to'liq orkestratsiya (PUBLIC)
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_For_Open(io_rec IN OUT core_acc_types.t_account_rec) IS
        v_acc VARCHAR2(20);
    BEGIN
        -- 1) Mijoz precondition + AUTO maydonlar (code/name/type/resident)
        p_resolve_client(io_rec);

        -- 2) Majburiy biznes maydonlar
        p_require(io_rec.name,        'name');
        p_require(io_rec.acc_type,    'acc_type');
        p_require(io_rec.branch_code, 'branch_code');

        -- 3) Valyuta (СПР 017) majburiy + mavjud
        p_require(io_rec.currency_code, 'currency_code');
        IF NOT core_acc_data_reader.Currency_Valid(io_rec.currency_code) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_currency,
                core_acc_const.c_msg_invalid_currency || ': ' || io_rec.currency_code);
        END IF;

        -- 4) Balans hisobi (COA) — turdan AUTO + tekshir + A/P, B/O AUTO
        p_resolve_coa(io_rec);

        -- 5) Сделка (deal_id) — НИББД признак 1/2/3 da majburiy
        IF io_rec.reg_nibd IN ('1', '2', '3') AND io_rec.deal_id IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_deal_required,
                core_acc_const.c_msg_deal_required);
        END IF;

        -- 6) M/O qarori + so'm/yagona/aktiv-M qoidalari
        p_decide_mo_status(io_rec);

        -- 7) Keyingi NNN tartib raqami
        p_assign_seq(io_rec);

        -- 8) Hosil bo'ladigan 20 xonali hisob raqami yaroqliligi (Mod-11)
        --    (trigger ham generatsiya qiladi; bu yerda oldindan tasdiqlaymiz)
        v_acc := core_acc_util.Generate_Account_Number(
                     LPAD(io_rec.balance_account, core_acc_const.c_balance_len, '0'),
                     LPAD(io_rec.currency_code,   core_acc_const.c_currency_len, '0'),
                     LPAD(io_rec.client_code,     core_acc_const.c_client_code_len, '0'),
                     LPAD(io_rec.seq_number,      core_acc_const.c_seq_len, '0'));
        IF NOT core_acc_util.Is_Valid_Account_Number(v_acc) THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_account,
                core_acc_const.c_msg_invalid_account || ': ' || v_acc);
        END IF;
    END Validate_For_Open;

    -- ---------------------------------------------------------------------------
    -- Validate_Approve — Утвердить (holat CREATED + Maker-Checker)
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_Approve(
        i_account_id     IN NUMBER,
        i_current_state  IN VARCHAR2,
        i_maker          IN NUMBER,
        i_checker        IN NUMBER
    ) IS
    BEGIN
        -- Hisob mavjudligi
        IF i_current_state IS NULL THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_account_not_found,
                core_acc_const.c_msg_account_not_found);
        END IF;
        -- Faqat «Создан» (CREATED) holatdan tasdiqlash mumkin
        IF i_current_state <> core_acc_const.c_st_created THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_state,
                core_acc_const.c_msg_invalid_state
                || ' (joriy: ' || i_current_state || ', kutilgan: CREATED)');
        END IF;
        -- Maker-Checker (ikki ko'z)
        IF i_checker IS NOT NULL AND i_maker IS NOT NULL AND i_checker = i_maker THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_maker_eq_checker,
                core_acc_const.c_msg_maker_eq_checker);
        END IF;
    END Validate_Approve;

END core_acc_rules;
/


-- *************************************************************************
-- 10. core_acc_service — biznes logika (COMMIT/ROLLBACK FAQAT shu yerda, E-5)
--    Public proc: o_code(0=ok)/o_message/o_ora_message (SC-1), boshida init
--    (SC-2), tanasi rules+util+repo -> COMMIT; WHEN OTHERS -> ROLLBACK + triple.
--
--    KECHIKTIRILGAN (bu faylda YO'Q): Update_Account, Block/Freeze/Close,
--      парный счёт (контрсчёт) avto-ochish (Справочник парных счетов yuklangach),
--      AML/НИББД REAL adapterlari (hozir STUB; gate ulangan).
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_service AS

    -- ---------------------------------------------------------------------------
    -- Open_Account — «Создать/Открыть»: hisob ochish (Создан holatda)
    --   rules.Validate_For_Open (AUTO + tekshir) -> repo.Insert_Account (trigger
    --   hisob raqami beradi) -> COMMIT. Holat = CREATED («Создан»); moliyaviy
    --   operatsiyalar TAQIQ (faqat Утвердить dan keyin). M/O status rules aniqlaydi.
    --   io_rec — IN OUT: AUTO to'ldirilgan maydonlar + account_id/number qaytadi.
    -- ---------------------------------------------------------------------------
    PROCEDURE Open_Account(
        io_rec           IN OUT core_acc_types.t_account_rec,
        o_account_id     OUT NUMBER,
        o_account_number OUT VARCHAR2,
        o_code           OUT NUMBER,
        o_message        OUT VARCHAR2,
        o_ora_message    OUT VARCHAR2
    );

    -- ---------------------------------------------------------------------------
    -- Approve_Account — «Утвердить»: Maker-Checker + AML + НИББД -> APPROVED
    --   Pipeline: CREATED -> TO_APPROVE -> AML_CHECK -> AML(gate) -> AML_PASSED
    --     -> NIBBD_TO_SEND -> NIBBD_SENT -> НИББД(gate) -> NIBBD_DONE -> APPROVED.
    --   AML/НИББД GATE (stub): FAILED -> RAISE -> ROLLBACK -> APPROVED ga O'TMAYDI.
    --   APPROVED dan keyin moliyaviy operatsiyalar ruxsat etiladi (Активный).
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve_Account(
        i_account_id   IN  NUMBER,
        i_checker_user IN  NUMBER,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2,
        o_ora_message  OUT VARCHAR2
    );

    -- ---------------------------------------------------------------------------
    -- Change_Account_State — holat o'zgartirish (operatsion).
    --   Matritsa: APPROVED->{TEMP_CLOSED,BLOCKED,CLOSED}; TEMP_CLOSED->{APPROVED,BLOCKED,CLOSED};
    --   BLOCKED->{APPROVED,CLOSED}; CLOSED=terminal. CLOSED uchun saldo_out=0 shart.
    -- ---------------------------------------------------------------------------
    PROCEDURE Change_Account_State(
        i_account_id  IN  NUMBER,
        i_new_state   IN  VARCHAR2,
        i_user        IN  NUMBER,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2,
        o_ora_message OUT VARCHAR2
    );

END core_acc_service;
/


CREATE OR REPLACE PACKAGE BODY core_acc_service AS

    -- ---------------------------------------------------------------------------
    -- Open_Account — hisob ochish orkestratsiyasi
    -- ---------------------------------------------------------------------------
    PROCEDURE Open_Account(
        io_rec           IN OUT core_acc_types.t_account_rec,
        o_account_id     OUT NUMBER,
        o_account_number OUT VARCHAR2,
        o_code           OUT NUMBER,
        o_message        OUT VARCHAR2,
        o_ora_message    OUT VARCHAR2
    ) IS
    BEGIN
        -- SC-2: OUT init
        o_code           := core_acc_const.c_code_ok;
        o_message        := NULL;
        o_ora_message    := NULL;
        o_account_id     := NULL;
        o_account_number := NULL;

        -- 1) Boshlang'ich holat (Создан) — financial ops taqiq
        io_rec.state := core_acc_const.c_st_created;
        IF io_rec.created_oper_day IS NULL THEN
            io_rec.created_oper_day := TRUNC(SYSDATE);
        END IF;

        -- 2) Qoidalar (AUTO to'ldirish: code/name/type/resident/COA/seq/M-O +
        --    precondition: mijoz APPROVED + НИББД; valyuta; deal; raqam yaroqli)
        core_acc_rules.Validate_For_Open(io_rec);

        -- 3) INSERT — trigger account_id/account_number/control_key beradi
        --    (M/O status io_rec dan ANIQ beriladi — default 'M' ga tayanmaymiz)
        core_acc_repo.Insert_Account(io_rec);

        -- 4) Audit log
        core_acc_logger.Log(io_rec.account_id, 'OPEN',
            'acc=' || io_rec.account_number
            || ' status=' || io_rec.status
            || ' coa=' || io_rec.balance_account
            || ' cur=' || io_rec.currency_code
            || ' seq=' || io_rec.seq_number,
            io_rec.maker_user);

        -- 5) COMMIT (E-5 — faqat service)
        COMMIT;

        o_account_id     := io_rec.account_id;
        o_account_number := io_rec.account_number;
        o_message        := 'Hisob ochildi (Создан): ' || io_rec.account_number
                            || ' [' || io_rec.status || ']';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := SQLCODE;
            o_message     := NVL(REGEXP_SUBSTR(SQLERRM, '[^:]+:\s*(.*)', 1, 1, NULL, 1),
                                 'Hisob ochishda xato');
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Open_Account;

    -- ---------------------------------------------------------------------------
    -- Approve_Account — «Утвердить»: Maker-Checker -> AML(gate) -> НИББД(gate) -> APPROVED
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve_Account(
        i_account_id   IN  NUMBER,
        i_checker_user IN  NUMBER,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2,
        o_ora_message  OUT VARCHAR2
    ) IS
        v_state core_acc_accounts.state%TYPE;
        v_maker core_acc_accounts.maker_user%TYPE;
        v_aml   core_acc_types.t_aml_result;
        v_nibbd core_acc_types.t_nibbd_result;
    BEGIN
        -- SC-2: OUT init
        o_code        := core_acc_const.c_code_ok;
        o_message     := NULL;
        o_ora_message := NULL;

        -- 1) Joriy holat + maker (Maker-Checker)
        v_state := core_acc_data_reader.Get_Status(i_account_id);
        v_maker := core_acc_data_reader.Get_Maker(i_account_id);

        -- 2) Qoidalar (holat CREATED + maker <> checker)
        core_acc_rules.Validate_Approve(i_account_id, v_state, v_maker, i_checker_user);

        -- 3) «на утверждение» (sub-state)
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_to_approve, i_checker_user);

        -- 4) AML bosqichi (GATE): На проверке AML -> adapter -> Проверен AML
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_aml_check, i_checker_user);
        v_aml := core_acc_aml.Check_Account(i_account_id);
        IF NVL(v_aml.passed, 'N') <> 'Y' THEN
            core_acc_logger.Log(i_account_id, 'AML_CHECK',
                'FAILED: ' || v_aml.reason, i_checker_user);
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_aml_failed,
                core_acc_const.c_msg_aml_failed
                || CASE WHEN v_aml.reason IS NOT NULL THEN ' (' || v_aml.reason || ')' END);
        END IF;
        core_acc_repo.Set_Aml_Checked(i_account_id, i_checker_user);
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_aml_passed, i_checker_user);
        core_acc_logger.Log(i_account_id, 'AML_CHECK', 'PASSED', i_checker_user);

        -- 5) НИББД bosqichi (GATE): На отправление -> Отправлен -> adapter -> Обработан
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_nibbd_to_send, i_checker_user);
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_nibbd_sent, i_checker_user);
        v_nibbd := core_acc_nibbd.Register_Account(i_account_id);
        IF NVL(v_nibbd.registered, 'N') <> 'Y' THEN
            core_acc_logger.Log(i_account_id, 'NIBBD_REG',
                'FAILED: ' || v_nibbd.reason, i_checker_user);
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_nibbd_failed,
                core_acc_const.c_msg_nibbd_failed
                || CASE WHEN v_nibbd.reason IS NOT NULL THEN ' (' || v_nibbd.reason || ')' END);
        END IF;
        core_acc_repo.Set_Nibbd_Registered(i_account_id, i_checker_user);
        core_acc_repo.Set_State(i_account_id, core_acc_const.c_st_nibbd_done, i_checker_user);
        core_acc_logger.Log(i_account_id, 'NIBBD_REG', 'registered', i_checker_user);

        -- 6) Yakuniy tasdiqlash (Утвержден/Активный) — Maker-Checker yopiladi
        core_acc_repo.Approve(i_account_id, i_checker_user);
        core_acc_logger.Log(i_account_id, 'APPROVE', 'state=APPROVED', i_checker_user);

        -- 7) COMMIT (E-5 — faqat service)
        COMMIT;

        o_message := 'Hisob tasdiqlandi (Утвержден) — moliyaviy operatsiyalar ochildi';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := SQLCODE;
            o_message     := NVL(REGEXP_SUBSTR(SQLERRM, '[^:]+:\s*(.*)', 1, 1, NULL, 1),
                                 'Hisobni tasdiqlashda xato');
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Approve_Account;

    -- ---------------------------------------------------------------------------
    -- Change_Account_State — holat matritsasi + CLOSED(saldo=0) -> repo.Set_State
    -- ---------------------------------------------------------------------------
    PROCEDURE Change_Account_State(
        i_account_id  IN  NUMBER,
        i_new_state   IN  VARCHAR2,
        i_user        IN  NUMBER,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2,
        o_ora_message OUT VARCHAR2
    ) IS
        v_state core_acc_accounts.state%TYPE;
        v_saldo core_acc_accounts.saldo_out%TYPE;
        v_ok    BOOLEAN := FALSE;
    BEGIN
        o_code := core_acc_const.c_code_ok; o_message := NULL; o_ora_message := NULL;
        SELECT state, saldo_out INTO v_state, v_saldo
          FROM core_acc_accounts WHERE account_id = i_account_id;

        IF    v_state = core_acc_const.c_st_approved
              AND i_new_state IN (core_acc_const.c_st_temp_closed, core_acc_const.c_st_blocked, core_acc_const.c_st_closed) THEN v_ok := TRUE;
        ELSIF v_state = core_acc_const.c_st_temp_closed
              AND i_new_state IN (core_acc_const.c_st_approved, core_acc_const.c_st_blocked, core_acc_const.c_st_closed) THEN v_ok := TRUE;
        ELSIF v_state = core_acc_const.c_st_blocked
              AND i_new_state IN (core_acc_const.c_st_approved, core_acc_const.c_st_closed) THEN v_ok := TRUE;
        END IF;
        IF NOT v_ok THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_state,
                'Holat o''tishi ruxsat etilmagan: ' || v_state || ' -> ' || i_new_state);
        END IF;

        IF i_new_state = core_acc_const.c_st_closed AND NVL(v_saldo, 0) <> 0 THEN
            RAISE_APPLICATION_ERROR(core_acc_const.c_err_invalid_state,
                'Hisobni yopib bo''lmaydi: qoldiq 0 emas (' || v_saldo || ')');
        END IF;

        core_acc_repo.Set_State(i_account_id, i_new_state, i_user);
        core_acc_logger.Log(i_account_id, 'STATE_CHANGE', v_state || '->' || i_new_state, i_user);
        COMMIT;
        o_message := 'Holat o''zgartirildi: ' || i_new_state;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK; o_code := 100; o_message := 'Hisob topilmadi: ' || i_account_id;
            o_ora_message := SQLERRM;
        WHEN OTHERS THEN
            ROLLBACK; o_code := SQLCODE;
            o_message := NVL(REGEXP_SUBSTR(SQLERRM, '[^:]+:\s*(.*)', 1, 1, NULL, 1),
                             'Holat o''zgartirishda xato');
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Change_Account_State;

END core_acc_service;
/

-- ============================================================================
-- 40_acc_packages.sql — TUGADI
-- Keyingi: 41_acc_views (UI viewlar), 42_acc_seed (test hisoblar),
--   core_acc_aml / core_acc_nibbd REAL adapter, парный счёт (контрсчёт) avto-ochish
--   (Справочник парных счетов), Update/Block/Freeze/Close service procedurelar.
-- ============================================================================
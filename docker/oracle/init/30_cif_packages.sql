-- gvenzl init (sqlplus / as sysdba, CDB-root) -> XEPDB1.BANKUSER. Manual load: no-op (USER<>SYS).
BEGIN
  IF USER = 'SYS' THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = XEPDB1';
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = BANKUSER';
  END IF;
END;
/
-- ============================================================================
-- MARS ABS — core_cif moduli
-- 30_cif_packages.sql — KLIENT OCHISH (registratsiya) — SIRIUS PL/SQL qatlamlari
-- Qamrov: физлицо (P) / юрлицо (J) / ИП (I) klient ochish (Создать -> Утвердить)
-- Asoslanadi: SIRIUS «Клиенты» spec (fiz/yur) + TZ-003 + 10_cif_schema contract
-- Target: Oracle 21c XE
--
-- Qatlamlar (dependency tartibi, L-1):
--   const -> types -> util -> logger -> data_reader -> repo -> rules -> service
--   COMMIT/ROLLBACK FAQAT service qatlamda (E-5).
--   repo  — faqat INSERT/UPDATE (COMMIT yo'q).
--   rules — faqat tekshiradi, qoida buzilsa RAISE_APPLICATION_ERROR(-20xxx).
--   data_reader — faqat SELECT (read-only).
--   service public proc: o_code/o_message/o_ora_message bilan tugaydi (SC-1),
--     boshida init (SC-2), tanasi: rules+repo -> COMMIT, keyin
--     EXCEPTION WHEN OTHERS -> ROLLBACK + o_code/o_message/o_ora_message.
--
-- DIQQAT (trigger bilan koordinatsiya — 10_cif_schema):
--   core_cif_clients_biu_trg INSERT da o'zi beradi:
--     client_id (NULL bo'lsa), created_at, r_uid=0, updated_at,
--     физ client_code (kind='P' & code NULL -> phys-code-seq, LPAD 8),
--     nibbd_temp_expiry (temp kod bor & expiry NULL -> SYSDATE+10).
--   Shuning uchun repo BU ustunlarni KIRITMAYDI (ikki marta generatsiya YO'Q).
--   Юр/ИП (J/I) client_code'ni trigger TEGMAYDI -> service vaqtinchalik `I%`
--     kodni o'zi GENERATSIYA qiladi (caller kod bermasa) -> repo io_rec dan beradi.
--     «Иностранный банк» (`0009%`) yoki oldindan berilgan НИББД kodi -> caller dan.
-- ============================================================================

SET DEFINE OFF
SET SQLBLANKLINES ON


-- *************************************************************************
-- 1. core_cif_const — konstantalar (statuslar, turlar, xato kodlari)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_const AS

    -- --- Тип субъекта (client_kind, СПР 006) -------------------------------
    c_kind_phys         CONSTANT CHAR(1) := 'P';   -- физлицо
    c_kind_legal        CONSTANT CHAR(1) := 'J';   -- юрлицо
    c_kind_ip           CONSTANT CHAR(1) := 'I';   -- ИП (jismoniy shaxs-tadbirkor)

    -- --- Состояние / статус клиента (core_cif_status FK domeni) ------------
    c_st_created        CONSTANT VARCHAR2(20) := 'CREATED';        -- Создан
    c_st_to_approve     CONSTANT VARCHAR2(20) := 'TO_APPROVE';     -- на утверждение (sub)
    c_st_aml_check      CONSTANT VARCHAR2(20) := 'AML_CHECK';      -- На проверке AML (sub)
    c_st_aml_passed     CONSTANT VARCHAR2(20) := 'AML_PASSED';     -- Проверен AML (sub)
    c_st_nibbd_to_send  CONSTANT VARCHAR2(20) := 'NIBBD_TO_SEND';  -- На отправление НИББД (sub)
    c_st_nibbd_sent     CONSTANT VARCHAR2(20) := 'NIBBD_SENT';     -- Отправлен НИББД (sub)
    c_st_nibbd_done     CONSTANT VARCHAR2(20) := 'NIBBD_DONE';     -- Обработан НИББД (sub)
    c_st_approved       CONSTANT VARCHAR2(20) := 'APPROVED';       -- Утвержден
    c_st_temp_closed    CONSTANT VARCHAR2(20) := 'TEMP_CLOSED';    -- Временно закрыт
    c_st_closed         CONSTANT VARCHAR2(20) := 'CLOSED';         -- Закрыт
    c_st_archived       CONSTANT VARCHAR2(20) := 'ARCHIVED';       -- Архивирован
    c_st_deleted        CONSTANT VARCHAR2(20) := 'DELETED';        -- Удален (terminal)

    -- --- Rezidentlik (resident_flag, СПР 027) ------------------------------
    c_resident          CONSTANT CHAR(1) := 'Y';
    c_nonresident       CONSTANT CHAR(1) := 'N';
    -- Резидентность kodi (resident_code, NUMBER(1)) — UZ rezident belgisi.
    -- Spec «860» (UZ) ni sxema NUMBER(1) sifatida modellashtiradi -> belgi = 8.
    c_resident_code_uzb CONSTANT NUMBER(1) := 8;   -- Резидентность = UZ (860) — SIRIUS: doc != 4

    -- --- Rol (primary_role) ------------------------------------------------
    c_role_client       CONSTANT VARCHAR2(20) := 'CLIENT';
    c_role_related      CONSTANT VARCHAR2(20) := 'RELATED';

    -- --- AML --------------------------------------------------------------
    c_aml_in_check      CONSTANT VARCHAR2(20) := 'IN_CHECK';
    c_aml_passed        CONSTANT VARCHAR2(20) := 'PASSED';
    c_aml_failed        CONSTANT VARCHAR2(20) := 'FAILED';
    c_aml_risk_low      CONSTANT VARCHAR2(10) := 'LOW';

    -- --- НКО / НИББД konstantalari -----------------------------------------
    -- Физ client_code oralig'i — «Клиенты» moduli beradi (fiz l.2470-2474):
    --   8 xona, 1-raqam 6, 60000000..69999999.
    c_phys_code_len     CONSTANT PLS_INTEGER := 8;
    c_phys_code_lo      CONSTANT VARCHAR2(8) := '60000000';
    c_phys_code_hi      CONSTANT VARCHAR2(8) := '69999999';
    c_phys_code_first   CONSTANT CHAR(1)     := '6';
    -- Юр/ИП vaqtinchalik kod prefiksi (`I%`) va «Иностранный банк» (`0009%`).
    c_nibbd_temp_prefix CONSTANT VARCHAR2(1) := 'I';
    c_foreign_bank_pref CONSTANT VARCHAR2(4) := '0009';
    c_nibbd_temp_days   CONSTANT PLS_INTEGER := 10;   -- vaqtinchalik kod muddati (kun)
    c_legal_code_len    CONSTANT PLS_INTEGER := 8;    -- client_code VARCHAR2(8) cheki

    -- --- Hujjat turlari (СПР 008) — rezidentlik/ПИНФЛ qoidasi uchun --------
    --   doc_type IN (0,1,2,3,6,8) -> Резидент; doc_type IN (4,5) -> Нерезидент.
    --   ПИНФЛ majburiy: doc_type IN (0,6,8) (серия len=2, номер len=7).
    c_doc_passport      CONSTANT VARCHAR2(2) := '0';   -- паспорт гражданина РУз
    c_doc_id_card       CONSTANT VARCHAR2(2) := '6';   -- ID-карта
    c_doc_bio_passport  CONSTANT VARCHAR2(2) := '8';   -- биометрический паспорт
    c_doc_foreign_pass  CONSTANT VARCHAR2(2) := '4';   -- иностранный паспорт (нерезидент)
    c_doc_residence     CONSTANT VARCHAR2(2) := '5';   -- вид на жительство (физ нерезидент)
    -- 0/6/8 hujjat seriya/raqam uzunliklari (fiz l.2480, yur l.5514)
    c_doc_series_len    CONSTANT PLS_INTEGER := 2;
    c_doc_number_len    CONSTANT PLS_INTEGER := 7;

    -- --- Maydon uzunliklari (ПИНФЛ/ИНН format) -----------------------------
    c_pinfl_len         CONSTANT PLS_INTEGER := 14;
    c_inn_len           CONSTANT PLS_INTEGER := 9;

    -- --- Umumiy javob kodlari ----------------------------------------------
    c_code_ok           CONSTANT NUMBER := 0;
    c_code_error        CONSTANT NUMBER := -1;
    c_msg_ok            CONSTANT VARCHAR2(10) := 'OK';

    -- --- Xato kodlari (E-7: -202xx oralig'i, core_cif) ---------------------
    c_err_required          CONSTANT PLS_INTEGER := -20210;  -- majburiy maydon bo'sh
    c_err_invalid_kind      CONSTANT PLS_INTEGER := -20211;  -- noto'g'ri client_kind
    c_err_invalid_type      CONSTANT PLS_INTEGER := -20212;  -- client_type СПР 21 da yo'q
    c_err_invalid_region    CONSTANT PLS_INTEGER := -20213;  -- region/rayon СПР 52 ga mos emas
    c_err_dup_pinfl         CONSTANT PLS_INTEGER := -20214;  -- ПИНФЛ takrorlandi
    c_err_dup_doc           CONSTANT PLS_INTEGER := -20215;  -- тип+серия+номер takrorlandi
    c_err_dup_inn           CONSTANT PLS_INTEGER := -20216;  -- ИНН takrorlandi (юр)
    c_err_invalid_doc       CONSTANT PLS_INTEGER := -20217;  -- hujjat sana/format noto'g'ri
    c_err_pinfl_required    CONSTANT PLS_INTEGER := -20218;  -- ПИНФЛ majburiy (doc 0/6/8)
    c_err_invalid_pinfl     CONSTANT PLS_INTEGER := -20219;  -- ПИНФЛ format (14 raqam)
    c_err_invalid_inn       CONSTANT PLS_INTEGER := -20220;  -- ИНН format (9 raqam)
    c_err_invalid_code      CONSTANT PLS_INTEGER := -20221;  -- client_code format (юр/ИП)
    c_err_code_required     CONSTANT PLS_INTEGER := -20222;  -- юр/ИП client_code bo'sh
    c_err_client_not_found  CONSTANT PLS_INTEGER := -20223;  -- klient topilmadi
    c_err_invalid_state     CONSTANT PLS_INTEGER := -20224;  -- holat o'tishi ruxsat etilmagan
    c_err_maker_eq_checker  CONSTANT PLS_INTEGER := -20225;  -- maker = checker (ikki ko'z)
    c_err_aml_failed        CONSTANT PLS_INTEGER := -20226;  -- AML ro'yxatidan o'tmadi
    c_err_residency_doc     CONSTANT PLS_INTEGER := -20227;  -- rezidentlik <-> hujjat ziddiyati
    c_err_nibbd_failed      CONSTANT PLS_INTEGER := -20228;  -- НИББД ro'yxatga olish xatosi

    -- --- Xato xabarlari (foydalanuvchi tilida) -----------------------------
    c_msg_required          CONSTANT VARCHAR2(200) := 'Majburiy maydon to''ldirilmagan';
    c_msg_invalid_kind      CONSTANT VARCHAR2(200) := 'Subyekt turi noto''g''ri (P/J/I)';
    c_msg_invalid_type      CONSTANT VARCHAR2(200) := 'Mijoz turi (СПР 21) topilmadi';
    c_msg_invalid_region    CONSTANT VARCHAR2(200) := 'Viloyat/tuman (СПР 52) mos kelmaydi';
    c_msg_dup_pinfl         CONSTANT VARCHAR2(200) := 'Bu ПИНФЛ bilan mijoz allaqachon mavjud';
    c_msg_dup_doc           CONSTANT VARCHAR2(200) := 'Bu hujjat (тип+серия+номер) allaqachon mavjud';
    c_msg_dup_inn           CONSTANT VARCHAR2(200) := 'Bu ИНН bilan mijoz allaqachon mavjud';
    c_msg_invalid_doc       CONSTANT VARCHAR2(200) := 'Hujjat sanalari/formati noto''g''ri';
    c_msg_pinfl_required    CONSTANT VARCHAR2(200) := 'ПИНФЛ majburiy (hujjat turi 0/6/8)';
    c_msg_invalid_pinfl     CONSTANT VARCHAR2(200) := 'ПИНФЛ formati noto''g''ri (14 raqam)';
    c_msg_invalid_inn       CONSTANT VARCHAR2(200) := 'ИНН formati noto''g''ri (9 raqam)';
    c_msg_invalid_code      CONSTANT VARCHAR2(200) := 'Klient kodi formati noto''g''ri (юр/ИП: I%/0009%/8 raqam, <=8)';
    c_msg_code_required     CONSTANT VARCHAR2(200) := 'Юр/ИП uchun klient kodi (НИББД/vaqtinchalik) majburiy';
    c_msg_client_not_found  CONSTANT VARCHAR2(200) := 'Mijoz topilmadi';
    c_msg_invalid_state     CONSTANT VARCHAR2(200) := 'Mijoz holatini o''zgartirib bo''lmaydi';
    c_msg_maker_eq_checker  CONSTANT VARCHAR2(200) := 'Yaratuvchi va tasdiqlovchi bir xil bo''la olmaydi';
    c_msg_aml_failed        CONSTANT VARCHAR2(200) := 'Mijoz AML/shubhali shaxslar ro''yxatida — tasdiqlash to''xtatildi';
    c_msg_residency_doc     CONSTANT VARCHAR2(200) := 'Rezidentlik va hujjat turi mos emas';
    c_msg_nibbd_failed      CONSTANT VARCHAR2(200) := 'НИББД ro''yxatga olishda xato — hisob ochish taqiqlanadi';

END core_cif_const;
/


-- *************************************************************************
-- 2. core_cif_types — record tiplar (Mars RECORD orqali uzatiladi)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_types AS

    -- ---------------------------------------------------------------------------
    -- t_client_rec — klient ochish (registratsiya) yagona kirish rekordi
    --   3 turga umumiy yadro (core_cif_clients) + физ/юр/ИП kengaytma maydonlari.
    --   Boshqaruvchi/audit maydonlari (maker_user, created_by) ham shu yerda.
    --   %TYPE — sxemaga aniq bog'langan (drift YO'Q).
    -- ---------------------------------------------------------------------------
    TYPE t_client_rec IS RECORD (
        -- --- core_cif_clients (BAZA) --------------------------------------
        client_id           core_cif_clients.client_id%TYPE,
        client_code         core_cif_clients.client_code%TYPE,         -- физ: trigger; юр/ИП: tashqi/НИББД/temp
        client_kind         core_cif_clients.client_kind%TYPE,         -- P/J/I
        client_type         core_cif_clients.client_type%TYPE,         -- СПР 21
        primary_role        core_cif_clients.primary_role%TYPE,
        employee_referred   core_cif_clients.employee_referred%TYPE,
        full_name           core_cif_clients.full_name%TYPE,
        full_name_lat       core_cif_clients.full_name_lat%TYPE,
        short_name          core_cif_clients.short_name%TYPE,
        resident_flag       core_cif_clients.resident_flag%TYPE,       -- hujjatdan AUTO (rules)
        resident_code       core_cif_clients.resident_code%TYPE,
        residency_country   core_cif_clients.residency_country%TYPE,
        citizenship_country core_cif_clients.citizenship_country%TYPE,
        nationality         core_cif_clients.nationality%TYPE,
        region_code         core_cif_clients.region_code%TYPE,
        district_code       core_cif_clients.district_code%TYPE,
        client_status       core_cif_clients.client_status%TYPE,
        client_sub_status   core_cif_clients.client_sub_status%TYPE,
        client_flags        core_cif_clients.client_flags%TYPE,
        primary_branch_code core_cif_clients.primary_branch_code%TYPE,
        code_word           core_cif_clients.code_word%TYPE,
        nibbd_temp_code     core_cif_clients.nibbd_temp_code%TYPE,
        nibbd_registered    core_cif_clients.nibbd_registered%TYPE,
        maker_user          core_cif_clients.maker_user%TYPE,
        created_by          core_cif_clients.created_by%TYPE,

        -- --- core_cif_individual (физ — kind='P') -------------------------
        last_name           core_cif_individual.last_name%TYPE,
        first_name          core_cif_individual.first_name%TYPE,
        middle_name         core_cif_individual.middle_name%TYPE,
        last_name_lat       core_cif_individual.last_name_lat%TYPE,
        first_name_lat      core_cif_individual.first_name_lat%TYPE,
        middle_name_lat     core_cif_individual.middle_name_lat%TYPE,
        gender              core_cif_individual.gender%TYPE,
        birth_date          core_cif_individual.birth_date%TYPE,
        birth_country       core_cif_individual.birth_country%TYPE,
        doc_type            core_cif_individual.doc_type%TYPE,
        doc_series          core_cif_individual.doc_series%TYPE,
        doc_number          core_cif_individual.doc_number%TYPE,
        doc_issue_date      core_cif_individual.doc_issue_date%TYPE,
        doc_expiry_date     core_cif_individual.doc_expiry_date%TYPE,
        doc_issue_place     core_cif_individual.doc_issue_place%TYPE,
        doc_issue_country   core_cif_individual.doc_issue_country%TYPE,
        doc_issuer_name     core_cif_individual.doc_issuer_name%TYPE,
        pinfl               core_cif_individual.pinfl%TYPE,
        tin                 core_cif_individual.tin%TYPE,

        -- --- core_cif_legal (юр + ИП — kind='J'/'I') ----------------------
        inn                 core_cif_legal.inn%TYPE,
        org_name            core_cif_legal.name%TYPE,
        org_name_lat        core_cif_legal.name_lat%TYPE,
        org_name_short      core_cif_legal.name_short%TYPE,
        nonresident_type    core_cif_legal.nonresident_type%TYPE,
        -- ИП shaxsiy-identifikatsiya bloki (core_cif_legal ichida):
        ip_last_name        core_cif_legal.last_name%TYPE,
        ip_first_name       core_cif_legal.first_name%TYPE,
        ip_middle_name      core_cif_legal.middle_name%TYPE,
        ip_last_name_lat    core_cif_legal.last_name_lat%TYPE,
        ip_first_name_lat   core_cif_legal.first_name_lat%TYPE,
        ip_middle_name_lat  core_cif_legal.middle_name_lat%TYPE,
        ip_gender           core_cif_legal.gender%TYPE,
        ip_dob              core_cif_legal.dob%TYPE,
        ip_country_birth    core_cif_legal.country_birth%TYPE,
        ip_doc_type         core_cif_legal.ip_doc_type%TYPE,
        ip_doc_serial       core_cif_legal.ip_doc_serial%TYPE,
        ip_doc_number       core_cif_legal.ip_doc_number%TYPE,
        ip_doc_issue_date   core_cif_legal.ip_doc_issue_date%TYPE,
        ip_doc_expire_date  core_cif_legal.ip_doc_expire_date%TYPE,
        ip_doc_country      core_cif_legal.ip_doc_country%TYPE,
        ip_doc_place        core_cif_legal.ip_doc_place%TYPE,
        ip_pinfl            core_cif_legal.pinfl%TYPE,
        -- регистрационные / статистические реквизиты:
        num_registr         core_cif_legal.num_registr%TYPE,
        date_registr        core_cif_legal.date_registr%TYPE,
        country_registr     core_cif_legal.country_registr%TYPE,
        region_registr      core_cif_legal.region_registr%TYPE,
        district_registr    core_cif_legal.district_registr%TYPE,
        oked                core_cif_legal.oked%TYPE
    );

    -- ---------------------------------------------------------------------------
    -- t_aml_result — AML tekshiruvi natijasi (adapter qaytaradi; gate uchun)
    --   passed='Y'/'N'; risk darajasi; sabab matni.
    -- ---------------------------------------------------------------------------
    TYPE t_aml_result IS RECORD (
        passed   CHAR(1),
        risk     VARCHAR2(10),
        reason   VARCHAR2(200)
    );

    -- ---------------------------------------------------------------------------
    -- t_nibbd_result — НИББД ro'yxatga olish natijasi (adapter qaytaradi; gate)
    --   registered='Y'/'N'; haqiqiy НИББД kod (almashtirilsa); sabab matni.
    -- ---------------------------------------------------------------------------
    TYPE t_nibbd_result IS RECORD (
        registered CHAR(1),
        real_code  VARCHAR2(8),
        reason     VARCHAR2(200)
    );

END core_cif_types;
/


-- *************************************************************************
-- 3. core_cif_util — yordamchi funksiyalar (kod/format/rezidentlik)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_util AS

    -- ---------------------------------------------------------------------------
    -- Next_Phys_Code — физ client_code (8 xona, 60000001..69999999) generatori
    --   ESLATMA: oddiy oqimda kerak EMAS — trigger (kind='P' & code NULL) o'zi
    --   beradi. Bu helper faqat triggerdan tashqari (masalan reconciliation/
    --   migratsiya) talab bo'lganda ishlatiladi. service oqimi triggerga tayanadi.
    -- ---------------------------------------------------------------------------
    FUNCTION Next_Phys_Code RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Next_Temp_Legal_Code — юр/ИП vaqtinchalik `I%` kod generatori
    --   SIRIUS: Создать paytida tizim mijozga noyob vaqtinchalik kod beradi
    --   (yur l.592/l.832/l.979). `I` + 7 xonali surrogat (jami 8 belgi, VARCHAR2(8)).
    --   Haqiqiy НИББД kodga registratsiyada almashtiriladi (Set_Nibbd_Registered).
    -- ---------------------------------------------------------------------------
    FUNCTION Next_Temp_Legal_Code RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Pinfl — ПИНФЛ formati (14 ta raqam)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Pinfl(i_pinfl IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Inn — ИНН formati (9 ta raqam)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Inn(i_inn IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Resident_From_Doc — hujjat turidan rezidentlik (027) AUTO aniqlash
    --   doc IN (0,1,2,3,6,8) -> 'Y' (Резидент); doc IN (4,5) -> 'N' (Нерезидент).
    -- ---------------------------------------------------------------------------
    FUNCTION Resident_From_Doc(i_doc_type IN VARCHAR2) RETURN CHAR;

    -- ---------------------------------------------------------------------------
    -- Pinfl_Required_For_Doc — doc IN (0,6,8) bo'lsa ПИНФЛ majburiy (TRUE)
    -- ---------------------------------------------------------------------------
    FUNCTION Pinfl_Required_For_Doc(i_doc_type IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Legal_Code — юр/ИП client_code formati
    --   ruxsat: `I%` (vaqtinchalik), `0009%` («Иностранный банк»), yoki 8 raqam.
    --   Uzunlik <= 8 (client_code VARCHAR2(8) cheki — over-length rad etiladi).
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Legal_Code(i_code IN VARCHAR2) RETURN BOOLEAN;

END core_cif_util;
/


CREATE OR REPLACE PACKAGE BODY core_cif_util AS

    -- ---------------------------------------------------------------------------
    -- Next_Phys_Code — физ kod generatori (helper; oddiy oqim triggerga tayanadi)
    -- ---------------------------------------------------------------------------
    FUNCTION Next_Phys_Code RETURN VARCHAR2 IS
        v_code VARCHAR2(8);
    BEGIN
        SELECT LPAD(TO_CHAR(core_cif_phys_code_seq.NEXTVAL), core_cif_const.c_phys_code_len, '0')
          INTO v_code
          FROM dual;
        RETURN v_code;
    END Next_Phys_Code;

    -- ---------------------------------------------------------------------------
    -- Next_Temp_Legal_Code — юр/ИП vaqtinchalik `I%` kod (I + 7 xonali surrogat)
    --   client_id sequence (core_cif_clients_seq) dan foydalanmaymiz (u INSERT da
    --   trigger uchun kerak); shu yerda phys-code-seq EMAS, alohida emas —
    --   noyoblikni client_code UNIQUE constraint kafolatlaydi. surrogat sifatida
    --   ROWNUM emas, core_cif_clients_seq.NEXTVAL ni MOD bilan 7 xonaga siqamiz?
    --   YO'Q: oddiy va noyob bo'lishi uchun core_cif_clients_seq dan keyingi
    --   qiymatni olmaymiz. Buning o'rniga timestamp-asosli emas — UNIQUE
    --   constraint himoyasi ostida core_cif_phys_code_seq DIAPAZONIDAN tashqarida
    --   bo'lish uchun юр/ИП uchun ALOHIDA mantiq: `I` + LPAD(seq,7).
    --   Sodda yechim: core_cif_clients_seq.NEXTVAL (PK bilan ziddiyatsiz — temp
    --   kod faqat client_code domeni, PK emas) -> 7 xonaga LPAD.
    -- ---------------------------------------------------------------------------
    FUNCTION Next_Temp_Legal_Code RETURN VARCHAR2 IS
        v_seq NUMBER;
        v_code VARCHAR2(8);
    BEGIN
        SELECT core_cif_clients_seq.NEXTVAL INTO v_seq FROM dual;
        -- `I` + 7 xonali surrogat = 8 belgi (VARCHAR2(8) ga sig'adi).
        -- 7 xonadan oshsa MOD bilan o'rab olamiz (UNIQUE constraint backstop).
        v_code := core_cif_const.c_nibbd_temp_prefix
                  || LPAD(TO_CHAR(MOD(v_seq, 10000000)), 7, '0');
        RETURN v_code;
    END Next_Temp_Legal_Code;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Pinfl — 14 ta raqam (faqat 0-9)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Pinfl(i_pinfl IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN i_pinfl IS NOT NULL
           AND LENGTH(i_pinfl) = core_cif_const.c_pinfl_len
           AND REGEXP_LIKE(i_pinfl, '^[0-9]{14}$');
    END Is_Valid_Pinfl;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Inn — 9 ta raqam (faqat 0-9)
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Inn(i_inn IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN i_inn IS NOT NULL
           AND LENGTH(i_inn) = core_cif_const.c_inn_len
           AND REGEXP_LIKE(i_inn, '^[0-9]{9}$');
    END Is_Valid_Inn;

    -- ---------------------------------------------------------------------------
    -- Resident_From_Doc — hujjatdan rezidentlik (027) AUTO
    -- ---------------------------------------------------------------------------
    FUNCTION Resident_From_Doc(i_doc_type IN VARCHAR2) RETURN CHAR IS
    BEGIN
        -- Нерезидент: иностранный паспорт (4), вид на жительство (5)
        IF i_doc_type IN ('4', '5') THEN
            RETURN core_cif_const.c_nonresident;
        END IF;
        -- Резидент: 0,1,2,3,6,8 (default)
        RETURN core_cif_const.c_resident;
    END Resident_From_Doc;

    -- ---------------------------------------------------------------------------
    -- Pinfl_Required_For_Doc — doc IN (0,6,8) -> ПИНФЛ majburiy
    -- ---------------------------------------------------------------------------
    FUNCTION Pinfl_Required_For_Doc(i_doc_type IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN i_doc_type IN (core_cif_const.c_doc_passport,
                              core_cif_const.c_doc_id_card,
                              core_cif_const.c_doc_bio_passport);
    END Pinfl_Required_For_Doc;

    -- ---------------------------------------------------------------------------
    -- Is_Valid_Legal_Code — юр/ИП kod: `I%` | `0009%` | 8 raqam, uzunlik <= 8
    -- ---------------------------------------------------------------------------
    FUNCTION Is_Valid_Legal_Code(i_code IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        IF i_code IS NULL THEN
            RETURN FALSE;
        END IF;
        -- Uzunlik chegarasi: client_code VARCHAR2(8) (over-length -> rad)
        IF LENGTH(i_code) > core_cif_const.c_legal_code_len THEN
            RETURN FALSE;
        END IF;
        -- vaqtinchalik kod (`I%`)
        IF i_code LIKE core_cif_const.c_nibbd_temp_prefix || '%' THEN
            RETURN TRUE;
        END IF;
        -- «Иностранный банк» (`0009%`)
        IF i_code LIKE core_cif_const.c_foreign_bank_pref || '%' THEN
            RETURN TRUE;
        END IF;
        -- haqiqiy НИББД kodi: 8 ta raqam
        IF LENGTH(i_code) = 8 AND REGEXP_LIKE(i_code, '^[0-9]{8}$') THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END Is_Valid_Legal_Code;

END core_cif_util;
/


-- *************************************************************************
-- 4. core_cif_logger — audit/log (INSERT yo'q stub — COMMIT yo'q)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_logger AS

    -- ---------------------------------------------------------------------------
    -- Log — sodda audit log (hozir DBMS_OUTPUT stub; keyin core_cif_audit_log)
    --   COMMIT QILMAYDI (E-5) — service tranzaksiyasi tarkibida ishlaydi.
    -- ---------------------------------------------------------------------------
    PROCEDURE Log(
        i_client_id IN NUMBER,
        i_action    IN VARCHAR2,
        i_detail    IN VARCHAR2 DEFAULT NULL,
        i_user      IN NUMBER   DEFAULT NULL
    );

END core_cif_logger;
/


CREATE OR REPLACE PACKAGE BODY core_cif_logger AS

    -- ---------------------------------------------------------------------------
    -- Log — stub (audit jadval qo'shilganda INSERT bilan almashtiriladi)
    -- ---------------------------------------------------------------------------
    PROCEDURE Log(
        i_client_id IN NUMBER,
        i_action    IN VARCHAR2,
        i_detail    IN VARCHAR2 DEFAULT NULL,
        i_user      IN NUMBER   DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            'CIF-AUDIT [' || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') || '] '
            || 'client=' || NVL(TO_CHAR(i_client_id), '-')
            || ' user='  || NVL(TO_CHAR(i_user), '-')
            || ' action=' || i_action
            || CASE WHEN i_detail IS NOT NULL THEN ' detail=' || i_detail END);
    END Log;

END core_cif_logger;
/


-- *************************************************************************
-- 5. core_cif_aml — AML/KYC gate adapter (STUB; gate sifatida wired)
--    SIRIUS: Утвердить paytida shubhali shaxslar ro'yxati bilan tekshirish.
--    Hozir STUB = PASSED qaytaradi, lekin service uni GATE sifatida ishlatadi
--    (natija FAILED bo'lsa -> RAISE c_err_aml_failed -> approve to'xtaydi).
--    Real adapter (sanksiya/shubhali ro'yxat) keyin shu spec bilan ulanadi.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_aml AS

    -- ---------------------------------------------------------------------------
    -- Check — AML tekshiruvi (STUB). Natija: passed/risk/reason.
    --   COMMIT YO'Q (read-only stub). Real versiya tashqi ro'yxatni so'raydi.
    -- ---------------------------------------------------------------------------
    FUNCTION Check_Client(i_client_id IN NUMBER) RETURN core_cif_types.t_aml_result;

END core_cif_aml;
/


CREATE OR REPLACE PACKAGE BODY core_cif_aml AS

    -- ---------------------------------------------------------------------------
    -- Check — STUB: hozir har doim PASSED (LOW risk). Real adapter o'rnida gate.
    -- ---------------------------------------------------------------------------
    FUNCTION Check_Client(i_client_id IN NUMBER) RETURN core_cif_types.t_aml_result IS
        v_res core_cif_types.t_aml_result;
    BEGIN
        -- STUB natija — keyin shubhali shaxslar ro'yxati bilan almashtiriladi.
        v_res.passed := 'Y';
        v_res.risk   := core_cif_const.c_aml_risk_low;
        v_res.reason := NULL;
        RETURN v_res;
    END Check_Client;

END core_cif_aml;
/


-- *************************************************************************
-- 6. core_cif_nibbd — НИББД ro'yxatga olish gate adapter (STUB; wired)
--    SIRIUS: karta majburiy НИББД da ro'yxatga olinishi shart; xato bo'lsa
--    hisob ochish TAQIQLANADI (fiz l.108/l.524). Hozir STUB = registered='Y'
--    (real kod almashuvisiz), lekin service GATE sifatida ishlatadi (registered
--    != 'Y' bo'lsa -> RAISE c_err_nibbd_failed -> approve to'xtaydi).
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_nibbd AS

    -- ---------------------------------------------------------------------------
    -- Register — НИББД ro'yxatga olish (STUB). Natija: registered/real_code/reason.
    --   COMMIT YO'Q. Real versiya СПР 019 НИББД xizmatiga so'rov yuboradi va
    --   haqiqiy kodni qaytaradi (юр/ИП temp `I%` kod almashtiriladi).
    -- ---------------------------------------------------------------------------
    FUNCTION Register(i_client_id IN NUMBER) RETURN core_cif_types.t_nibbd_result;

END core_cif_nibbd;
/


CREATE OR REPLACE PACKAGE BODY core_cif_nibbd AS

    -- ---------------------------------------------------------------------------
    -- Register — STUB: registered='Y', real kod almashuvi YO'Q (real_code NULL).
    --   Real adapter o'rnida gate (registered != 'Y' -> service RAISE qiladi).
    -- ---------------------------------------------------------------------------
    FUNCTION Register(i_client_id IN NUMBER) RETURN core_cif_types.t_nibbd_result IS
        v_res core_cif_types.t_nibbd_result;
    BEGIN
        -- STUB natija — keyin real НИББД xizmati bilan almashtiriladi.
        v_res.registered := 'Y';
        v_res.real_code  := NULL;   -- temp `I%` kod hozircha saqlanadi (almashmaydi)
        v_res.reason     := NULL;
        RETURN v_res;
    END Register;

END core_cif_nibbd;
/


-- *************************************************************************
-- 7. core_cif_data_reader — faqat SELECT (read-only, DML YO'Q)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_data_reader AS

    -- ---------------------------------------------------------------------------
    -- Get_Client_By_Id — bitta klient (BAZA satr) id bo'yicha
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Client_By_Id(
        i_client_id IN  NUMBER,
        o_row       OUT core_cif_clients%ROWTYPE
    );

    -- ---------------------------------------------------------------------------
    -- Get_Client_By_Code — bitta klient client_code bo'yicha
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Client_By_Code(
        i_client_code IN  VARCHAR2,
        o_row         OUT core_cif_clients%ROWTYPE
    );

    -- ---------------------------------------------------------------------------
    -- Client_Exists — id bo'yicha klient bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Exists(i_client_id IN NUMBER) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Phys_Pinfl_Exists — физ ПИНФЛ takrorlanishmi (rezident noyoblik)
    -- ---------------------------------------------------------------------------
    FUNCTION Phys_Pinfl_Exists(i_pinfl IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Phys_Doc_Exists — физ тип+серия+номер takrorlanishmi
    -- ---------------------------------------------------------------------------
    FUNCTION Phys_Doc_Exists(
        i_doc_type   IN VARCHAR2,
        i_doc_series IN VARCHAR2,
        i_doc_number IN VARCHAR2
    ) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Legal_Inn_Exists — юр ИНН takrorlanishmi
    -- ---------------------------------------------------------------------------
    FUNCTION Legal_Inn_Exists(i_inn IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Ip_Pinfl_Exists — ИП ПИНФЛ takrorlanishmi (core_cif_legal.pinfl)
    -- ---------------------------------------------------------------------------
    FUNCTION Ip_Pinfl_Exists(i_pinfl IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Ip_Doc_Exists — ИП тип+серия+номер takrorlanishmi (core_cif_legal)
    -- ---------------------------------------------------------------------------
    FUNCTION Ip_Doc_Exists(
        i_doc_type   IN VARCHAR2,
        i_doc_serial IN VARCHAR2,
        i_doc_number IN VARCHAR2
    ) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Client_Type_Valid — client_type СПР 21 (core_ref_client_type) da bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Type_Valid(i_type IN VARCHAR2) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Region_Valid — region+rayon juftligi СПР 52 (core_ref_region) ga mosmi
    -- ---------------------------------------------------------------------------
    FUNCTION Region_Valid(
        i_region   IN VARCHAR2,
        i_district IN VARCHAR2
    ) RETURN BOOLEAN;

    -- ---------------------------------------------------------------------------
    -- Get_Status — klientning joriy client_status (state machine uchun)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Status(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Sub_Status — klientning joriy client_sub_status (pipeline guard uchun)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Sub_Status(i_client_id IN NUMBER) RETURN VARCHAR2;

    -- ---------------------------------------------------------------------------
    -- Get_Maker — klientni yaratgan maker_user (Maker-Checker tekshiruvi)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Maker(i_client_id IN NUMBER) RETURN NUMBER;

END core_cif_data_reader;
/


CREATE OR REPLACE PACKAGE BODY core_cif_data_reader AS

    -- ---------------------------------------------------------------------------
    -- Get_Client_By_Id — id bo'yicha BAZA satr
    --   (NO_DATA_FOUND -> bo'sh record; %ROWTYPE ga NULL literal berib BO'LMAYDI)
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Client_By_Id(
        i_client_id IN  NUMBER,
        o_row       OUT core_cif_clients%ROWTYPE
    ) IS
        v_empty core_cif_clients%ROWTYPE;
    BEGIN
        SELECT *
          INTO o_row
          FROM core_cif_clients
         WHERE client_id = i_client_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_row := v_empty;
    END Get_Client_By_Id;

    -- ---------------------------------------------------------------------------
    -- Get_Client_By_Code — client_code bo'yicha BAZA satr
    --   (NO_DATA_FOUND -> bo'sh record; %ROWTYPE ga NULL literal berib BO'LMAYDI)
    -- ---------------------------------------------------------------------------
    PROCEDURE Get_Client_By_Code(
        i_client_code IN  VARCHAR2,
        o_row         OUT core_cif_clients%ROWTYPE
    ) IS
        v_empty core_cif_clients%ROWTYPE;
    BEGIN
        SELECT *
          INTO o_row
          FROM core_cif_clients
         WHERE client_code = i_client_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_row := v_empty;
    END Get_Client_By_Code;

    -- ---------------------------------------------------------------------------
    -- Client_Exists — id bormi
    -- ---------------------------------------------------------------------------
    FUNCTION Client_Exists(i_client_id IN NUMBER) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_cnt > 0;
    END Client_Exists;

    -- ---------------------------------------------------------------------------
    -- Phys_Pinfl_Exists — физ ПИНФЛ noyoblik
    -- ---------------------------------------------------------------------------
    FUNCTION Phys_Pinfl_Exists(i_pinfl IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_pinfl IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_individual
         WHERE pinfl = i_pinfl;
        RETURN v_cnt > 0;
    END Phys_Pinfl_Exists;

    -- ---------------------------------------------------------------------------
    -- Phys_Doc_Exists — физ тип+серия+номер noyoblik
    -- ---------------------------------------------------------------------------
    FUNCTION Phys_Doc_Exists(
        i_doc_type   IN VARCHAR2,
        i_doc_series IN VARCHAR2,
        i_doc_number IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_individual
         WHERE doc_type   = i_doc_type
           AND doc_series = i_doc_series
           AND doc_number = i_doc_number;
        RETURN v_cnt > 0;
    END Phys_Doc_Exists;

    -- ---------------------------------------------------------------------------
    -- Legal_Inn_Exists — юр ИНН noyoblik
    -- ---------------------------------------------------------------------------
    FUNCTION Legal_Inn_Exists(i_inn IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_inn IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_legal
         WHERE inn = i_inn;
        RETURN v_cnt > 0;
    END Legal_Inn_Exists;

    -- ---------------------------------------------------------------------------
    -- Ip_Pinfl_Exists — ИП ПИНФЛ noyoblik (core_cif_legal.pinfl)
    -- ---------------------------------------------------------------------------
    FUNCTION Ip_Pinfl_Exists(i_pinfl IN VARCHAR2) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_pinfl IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_legal
         WHERE pinfl = i_pinfl;
        RETURN v_cnt > 0;
    END Ip_Pinfl_Exists;

    -- ---------------------------------------------------------------------------
    -- Ip_Doc_Exists — ИП тип+серия+номер noyoblik (core_cif_legal)
    -- ---------------------------------------------------------------------------
    FUNCTION Ip_Doc_Exists(
        i_doc_type   IN VARCHAR2,
        i_doc_serial IN VARCHAR2,
        i_doc_number IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
          FROM core_cif_legal
         WHERE ip_doc_type   = i_doc_type
           AND ip_doc_serial = i_doc_serial
           AND ip_doc_number = i_doc_number;
        RETURN v_cnt > 0;
    END Ip_Doc_Exists;

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
    -- Region_Valid — СПР 52 (core_ref_region) — region+rayon juftligi
    -- ---------------------------------------------------------------------------
    FUNCTION Region_Valid(
        i_region   IN VARCHAR2,
        i_district IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_cnt PLS_INTEGER;
    BEGIN
        IF i_region IS NULL OR i_district IS NULL THEN
            RETURN FALSE;
        END IF;
        SELECT COUNT(*) INTO v_cnt
          FROM core_ref_region
         WHERE region_code = i_region
           AND code        = i_district;
        RETURN v_cnt > 0;
    END Region_Valid;

    -- ---------------------------------------------------------------------------
    -- Get_Status — joriy client_status
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Status(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_status core_cif_clients.client_status%TYPE;
    BEGIN
        SELECT client_status INTO v_status
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Status;

    -- ---------------------------------------------------------------------------
    -- Get_Sub_Status — joriy client_sub_status (approval pipeline guard)
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Sub_Status(i_client_id IN NUMBER) RETURN VARCHAR2 IS
        v_sub core_cif_clients.client_sub_status%TYPE;
    BEGIN
        SELECT client_sub_status INTO v_sub
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_sub;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Sub_Status;

    -- ---------------------------------------------------------------------------
    -- Get_Maker — yaratgan maker_user
    -- ---------------------------------------------------------------------------
    FUNCTION Get_Maker(i_client_id IN NUMBER) RETURN NUMBER IS
        v_maker core_cif_clients.maker_user%TYPE;
    BEGIN
        SELECT maker_user INTO v_maker
          FROM core_cif_clients
         WHERE client_id = i_client_id;
        RETURN v_maker;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Maker;

END core_cif_data_reader;
/


-- *************************************************************************
-- 8. core_cif_repo — faqat DML (INSERT/UPDATE) — COMMIT YO'Q (E-5)
--    Trigger bilan koordinatsiya: client_id, created_at, r_uid, updated_at,
--    физ client_code, nibbd_temp_expiry — trigger beradi, repo TEGMAYDI.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_repo AS

    -- ---------------------------------------------------------------------------
    -- Insert_Client — core_cif_clients (BAZA) INSERT, client_id RETURNING
    --   физ: client_code KIRITILMAYDI (trigger beradi).
    --   юр/ИП: io_rec.client_code MAJBURIY (trigger tegmaydi) — repo kiritadi.
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Client(io_rec IN OUT core_cif_types.t_client_rec);

    -- ---------------------------------------------------------------------------
    -- Insert_Individual — core_cif_individual (физ 1:1) INSERT
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Individual(i_rec IN core_cif_types.t_client_rec);

    -- ---------------------------------------------------------------------------
    -- Insert_Legal — core_cif_legal (юр + ИП 1:1) INSERT
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Legal(i_rec IN core_cif_types.t_client_rec);

    -- ---------------------------------------------------------------------------
    -- Set_Status — client_status / client_sub_status yangilash (state machine)
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Status(
        i_client_id  IN NUMBER,
        i_status     IN VARCHAR2,
        i_sub_status IN VARCHAR2,
        i_user       IN NUMBER
    );

    -- ---------------------------------------------------------------------------
    -- Set_Aml — AML natijasi (aml_status/risk/checked_at) yozish
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Aml(
        i_client_id IN NUMBER,
        i_status    IN VARCHAR2,
        i_risk      IN VARCHAR2,
        i_user      IN NUMBER
    );

    -- ---------------------------------------------------------------------------
    -- Set_Nibbd_Registered — НИББД ro'yxat natijasi (registered=Y, reg_at)
    --   юр/ИП: vaqtinchalik kodni haqiqiy НИББД kodiga almashtirish ham shu yerda
    --   (i_real_code berilsa client_code yangilanadi, temp tozalanadi).
    --   Param tartibi: majburiylar oldin, defaulted (i_real_code) oxirda.
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Nibbd_Registered(
        i_client_id IN NUMBER,
        i_user      IN NUMBER,
        i_real_code IN VARCHAR2 DEFAULT NULL
    );

    -- ---------------------------------------------------------------------------
    -- Approve — APPROVED holatga o'tkazish (checker_user/approved_at)
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve(
        i_client_id IN NUMBER,
        i_checker   IN NUMBER
    );

END core_cif_repo;
/


CREATE OR REPLACE PACKAGE BODY core_cif_repo AS

    -- ---------------------------------------------------------------------------
    -- Insert_Client — BAZA satr (trigger-set ustunlar KIRITILMAYDI)
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Client(io_rec IN OUT core_cif_types.t_client_rec) IS
    BEGIN
        -- Boshlang'ich qiymatlar (default'lar — trigger beradiganlar EMAS):
        io_rec.client_status := core_cif_const.c_st_created;
        IF io_rec.primary_role IS NULL THEN
            io_rec.primary_role := core_cif_const.c_role_client;
        END IF;
        IF io_rec.nibbd_registered IS NULL THEN
            io_rec.nibbd_registered := 'N';
        END IF;

        -- OMIT: client_id, r_uid, created_at, updated_at (trigger beradi).
        -- физ: client_code OMIT (trigger beradi). юр/ИП: client_code MAJBURIY.
        INSERT INTO core_cif_clients (
            client_code, client_kind, client_type, primary_role, employee_referred,
            full_name, full_name_lat, short_name,
            resident_flag, resident_code, residency_country, citizenship_country, nationality,
            region_code, district_code,
            client_status, client_sub_status, client_flags,
            primary_branch_code, code_word,
            nibbd_temp_code, nibbd_registered,
            maker_user, created_by
        ) VALUES (
            -- физ: NULL -> trigger phys-code-seq beradi; юр/ИП: io_rec dan keladi
            CASE WHEN io_rec.client_kind = core_cif_const.c_kind_phys
                 THEN NULL ELSE io_rec.client_code END,
            io_rec.client_kind, io_rec.client_type, io_rec.primary_role, io_rec.employee_referred,
            io_rec.full_name, io_rec.full_name_lat, io_rec.short_name,
            io_rec.resident_flag, io_rec.resident_code, io_rec.residency_country,
            io_rec.citizenship_country, io_rec.nationality,
            io_rec.region_code, io_rec.district_code,
            io_rec.client_status, io_rec.client_sub_status, io_rec.client_flags,
            io_rec.primary_branch_code, io_rec.code_word,
            io_rec.nibbd_temp_code, io_rec.nibbd_registered,
            io_rec.maker_user, io_rec.created_by
        ) RETURNING client_id, client_code INTO io_rec.client_id, io_rec.client_code;
    END Insert_Client;

    -- ---------------------------------------------------------------------------
    -- Insert_Individual — физ kengaytma (PK = client_id, trigger faqat audit)
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Individual(i_rec IN core_cif_types.t_client_rec) IS
    BEGIN
        INSERT INTO core_cif_individual (
            client_id,
            last_name, first_name, middle_name,
            last_name_lat, first_name_lat, middle_name_lat,
            gender, birth_date, birth_country,
            doc_type, doc_series, doc_number,
            doc_issue_date, doc_expiry_date, doc_issue_place, doc_issue_country, doc_issuer_name,
            pinfl, tin
        ) VALUES (
            i_rec.client_id,
            i_rec.last_name, i_rec.first_name, i_rec.middle_name,
            i_rec.last_name_lat, i_rec.first_name_lat, i_rec.middle_name_lat,
            i_rec.gender, i_rec.birth_date, i_rec.birth_country,
            i_rec.doc_type, i_rec.doc_series, i_rec.doc_number,
            i_rec.doc_issue_date, i_rec.doc_expiry_date, i_rec.doc_issue_place,
            i_rec.doc_issue_country, i_rec.doc_issuer_name,
            i_rec.pinfl, i_rec.tin
        );
    END Insert_Individual;

    -- ---------------------------------------------------------------------------
    -- Insert_Legal — юр + ИП kengaytma (PK = client_id, trigger faqat audit)
    --   ИП (kind='I'): shaxsiy blok (last_name..pinfl, ip_doc_*) to'ldiriladi.
    --   юр (kind='J'): inn/name + регистрационные реквизиты.
    -- ---------------------------------------------------------------------------
    PROCEDURE Insert_Legal(i_rec IN core_cif_types.t_client_rec) IS
    BEGIN
        INSERT INTO core_cif_legal (
            client_id,
            inn, name, name_lat, name_short, nonresident_type,
            last_name, first_name, middle_name,
            last_name_lat, first_name_lat, middle_name_lat,
            gender, dob, country_birth,
            ip_doc_type, ip_doc_serial, ip_doc_number,
            ip_doc_issue_date, ip_doc_expire_date, ip_doc_country, ip_doc_place,
            pinfl,
            num_registr, date_registr, country_registr,
            region_registr, district_registr, oked
        ) VALUES (
            i_rec.client_id,
            i_rec.inn, i_rec.org_name, i_rec.org_name_lat, i_rec.org_name_short, i_rec.nonresident_type,
            i_rec.ip_last_name, i_rec.ip_first_name, i_rec.ip_middle_name,
            i_rec.ip_last_name_lat, i_rec.ip_first_name_lat, i_rec.ip_middle_name_lat,
            i_rec.ip_gender, i_rec.ip_dob, i_rec.ip_country_birth,
            i_rec.ip_doc_type, i_rec.ip_doc_serial, i_rec.ip_doc_number,
            i_rec.ip_doc_issue_date, i_rec.ip_doc_expire_date, i_rec.ip_doc_country, i_rec.ip_doc_place,
            i_rec.ip_pinfl,
            i_rec.num_registr, i_rec.date_registr, i_rec.country_registr,
            i_rec.region_registr, i_rec.district_registr, i_rec.oked
        );
    END Insert_Legal;

    -- ---------------------------------------------------------------------------
    -- Set_Status — client_status/sub_status yangilash
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Status(
        i_client_id  IN NUMBER,
        i_status     IN VARCHAR2,
        i_sub_status IN VARCHAR2,
        i_user       IN NUMBER
    ) IS
    BEGIN
        UPDATE core_cif_clients
           SET client_status     = i_status,
               client_sub_status = i_sub_status,
               updated_by        = i_user
         WHERE client_id = i_client_id;
    END Set_Status;

    -- ---------------------------------------------------------------------------
    -- Set_Aml — AML natijasi
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Aml(
        i_client_id IN NUMBER,
        i_status    IN VARCHAR2,
        i_risk      IN VARCHAR2,
        i_user      IN NUMBER
    ) IS
    BEGIN
        UPDATE core_cif_clients
           SET aml_status     = i_status,
               aml_risk_level = i_risk,
               aml_checked_at = SYSTIMESTAMP,
               updated_by     = i_user
         WHERE client_id = i_client_id;
    END Set_Aml;

    -- ---------------------------------------------------------------------------
    -- Set_Nibbd_Registered — НИББД ro'yxat (registered=Y); юр/ИП: real kod almash
    -- ---------------------------------------------------------------------------
    PROCEDURE Set_Nibbd_Registered(
        i_client_id IN NUMBER,
        i_user      IN NUMBER,
        i_real_code IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE core_cif_clients
           SET nibbd_registered = 'Y',
               nibbd_reg_at     = SYSTIMESTAMP,
               -- haqiqiy НИББД kod berilsa: client_code almashtiriladi, temp tozalanadi
               client_code      = NVL(i_real_code, client_code),
               nibbd_temp_code  = CASE WHEN i_real_code IS NOT NULL THEN NULL ELSE nibbd_temp_code END,
               nibbd_temp_expiry= CASE WHEN i_real_code IS NOT NULL THEN NULL ELSE nibbd_temp_expiry END,
               updated_by       = i_user
         WHERE client_id = i_client_id;
    END Set_Nibbd_Registered;

    -- ---------------------------------------------------------------------------
    -- Approve — APPROVED holatga o'tkazish (faqat CREATED holatdan)
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve(
        i_client_id IN NUMBER,
        i_checker   IN NUMBER
    ) IS
    BEGIN
        UPDATE core_cif_clients
           SET client_status     = core_cif_const.c_st_approved,
               client_sub_status = NULL,
               checker_user      = i_checker,
               approved_at       = SYSTIMESTAMP,
               updated_by        = i_checker
         WHERE client_id = i_client_id;
    END Approve;

END core_cif_repo;
/


-- *************************************************************************
-- 9. core_cif_rules — validatsiya (DML YO'Q; qoida buzilsa RAISE -20xxx)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_rules AS

    -- ---------------------------------------------------------------------------
    -- Validate_For_Register — registratsiya uchun to'liq tekshiruv (kind-aware)
    --   io_rec — IN OUT: rezidentlik (resident_flag) hujjatdan AUTO to'ldiriladi.
    --   Tekshiradi: majburiy maydonlar, client_type (СПР 21), region (СПР 52),
    --     hujjat sanalari/uzunliklari, rezidentlik<->hujjat ziddiyati,
    --     ПИНФЛ/ИНН format, noyoblik (физ/юр/ИП), юр/ИП kod.
    --   Buzilsa RAISE_APPLICATION_ERROR(-20xxx).
    --   ESLATMA: юр/ИП uchun vaqtinchalik `I%` kodni service GENERATSIYA qiladi
    --     (caller bermasa) -> bu yerga kelganda io_rec.client_code DOIM mavjud.
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_For_Register(io_rec IN OUT core_cif_types.t_client_rec);

    -- ---------------------------------------------------------------------------
    -- Validate_Approve — Утвердить uchun (holat + Maker-Checker)
    --   i_current_status CREATED bo'lishi shart; maker <> checker (ikki ko'z).
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_Approve(
        i_client_id      IN NUMBER,
        i_current_status IN VARCHAR2,
        i_maker          IN NUMBER,
        i_checker        IN NUMBER
    );

END core_cif_rules;
/


CREATE OR REPLACE PACKAGE BODY core_cif_rules AS

    -- ---------------------------------------------------------------------------
    -- p_require — lokal yordamchi: qiymat bo'sh bo'lsa -20210 ko'taradi
    -- ---------------------------------------------------------------------------
    PROCEDURE p_require(i_value IN VARCHAR2, i_field IN VARCHAR2) IS
    BEGIN
        IF i_value IS NULL THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_required,
                core_cif_const.c_msg_required || ': ' || i_field);
        END IF;
    END p_require;

    -- ---------------------------------------------------------------------------
    -- p_require_date — lokal yordamchi: DATE bo'sh bo'lsa -20210
    -- ---------------------------------------------------------------------------
    PROCEDURE p_require_date(i_value IN DATE, i_field IN VARCHAR2) IS
    BEGIN
        IF i_value IS NULL THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_required,
                core_cif_const.c_msg_required || ': ' || i_field);
        END IF;
    END p_require_date;

    -- ---------------------------------------------------------------------------
    -- p_validate_doc_lengths — 0/6/8 hujjat: серия len=2, номер len=7 (spec)
    --   fiz l.2480 / yur l.5514. Boshqa turlarda uzunlik cheklanmaydi.
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_doc_lengths(
        i_doc_type   IN VARCHAR2,
        i_doc_series IN VARCHAR2,
        i_doc_number IN VARCHAR2,
        i_prefix     IN VARCHAR2
    ) IS
    BEGIN
        IF core_cif_util.Pinfl_Required_For_Doc(i_doc_type) THEN
            IF NVL(LENGTH(i_doc_series), 0) <> core_cif_const.c_doc_series_len THEN
                RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                    core_cif_const.c_msg_invalid_doc
                    || ': ' || i_prefix || 'doc_series uzunligi = 2 bo''lishi shart (тип 0/6/8)');
            END IF;
            IF NVL(LENGTH(i_doc_number), 0) <> core_cif_const.c_doc_number_len THEN
                RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                    core_cif_const.c_msg_invalid_doc
                    || ': ' || i_prefix || 'doc_number uzunligi = 7 bo''lishi shart (тип 0/6/8)');
            END IF;
        END IF;
    END p_validate_doc_lengths;

    -- ---------------------------------------------------------------------------
    -- p_validate_residency_doc — rezidentlik(027 kod) <-> hujjat turi ziddiyati
    --   Spec (fiz l.2484-2486, yur l.5518-5520):
    --     resident_code = UZ (860) bo'lsa -> hujjat turi 4 (chet pasporti) MUMKIN EMAS.
    --     resident_code <> UZ bo'lsa -> hujjat turi 0,1,2,6,7,8 MUMKIN EMAS.
    --   Hamda hujjatdan kelib chiqqan resident_flag bilan resident_code mosligi.
    --   resident_code berilmagan (NULL) bo'lsa -> derived flag dan to'ldiriladi
    --   (io_rec ga yoziladi), ziddiyat tekshirilmaydi (faqat AUTO).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_residency_doc(
        io_rec       IN OUT core_cif_types.t_client_rec,
        i_doc_type   IN VARCHAR2
    ) IS
        v_is_uz BOOLEAN;
    BEGIN
        -- resident_code berilmagan -> derived flag dan AUTO (UZ=8 yoki NULL norezident)
        IF io_rec.resident_code IS NULL THEN
            IF io_rec.resident_flag = core_cif_const.c_resident THEN
                io_rec.resident_code := core_cif_const.c_resident_code_uzb;
            END IF;
            RETURN;   -- caller kod bermagan -> AUTO, ziddiyat yo'q
        END IF;

        v_is_uz := (io_rec.resident_code = core_cif_const.c_resident_code_uzb);

        -- UZ rezident -> chet pasporti (4) bo'lishi mumkin emas
        IF v_is_uz AND i_doc_type = core_cif_const.c_doc_foreign_pass THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_residency_doc,
                core_cif_const.c_msg_residency_doc
                || ': UZ rezident uchun hujjat turi 4 mumkin emas');
        END IF;

        -- norezident -> milliy/rezident hujjatlari (0,1,2,6,7,8) bo'lishi mumkin emas
        IF NOT v_is_uz AND i_doc_type IN ('0', '1', '2', '6', '7', '8') THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_residency_doc,
                core_cif_const.c_msg_residency_doc
                || ': norezident uchun hujjat turi ' || i_doc_type || ' mumkin emas');
        END IF;

        -- resident_code <-> derived resident_flag mosligi (rekonsiliatsiya)
        IF v_is_uz AND io_rec.resident_flag = core_cif_const.c_nonresident THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_residency_doc,
                core_cif_const.c_msg_residency_doc
                || ': resident_code UZ, lekin hujjat norezident');
        END IF;
        IF NOT v_is_uz AND io_rec.resident_flag = core_cif_const.c_resident THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_residency_doc,
                core_cif_const.c_msg_residency_doc
                || ': resident_code norezident, lekin hujjat rezident');
        END IF;
    END p_validate_residency_doc;

    -- ---------------------------------------------------------------------------
    -- p_validate_common — 3 turga umumiy yadro tekshiruvi (тип/region)
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_common(i_rec IN core_cif_types.t_client_rec) IS
    BEGIN
        -- Тип клиента (СПР 21) majburiy + mavjud bo'lishi shart
        p_require(i_rec.client_type, 'client_type');
        IF NOT core_cif_data_reader.Client_Type_Valid(i_rec.client_type) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_type,
                core_cif_const.c_msg_invalid_type || ': ' || i_rec.client_type);
        END IF;
        -- Nomi (header) majburiy
        p_require(i_rec.full_name, 'full_name');
    END p_validate_common;

    -- ---------------------------------------------------------------------------
    -- p_validate_phys — физлицо (P) majburiy + noyoblik + rezidentlik
    --   io_rec.resident_flag hujjatdan AUTO to'ldiriladi (SIRIUS: не редактируемое).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_phys(io_rec IN OUT core_cif_types.t_client_rec) IS
    BEGIN
        -- Ism (majburiy: фамилия/имя + латин)
        p_require(io_rec.last_name,      'last_name');
        p_require(io_rec.first_name,     'first_name');
        p_require(io_rec.last_name_lat,  'last_name_lat');
        p_require(io_rec.first_name_lat, 'first_name_lat');
        -- Пол / Дата рождения
        p_require(io_rec.gender, 'gender');
        p_require_date(io_rec.birth_date, 'birth_date');
        -- Hujjat (тип/серия/номер/дата выдачи)
        p_require(io_rec.doc_type,   'doc_type');
        p_require(io_rec.doc_series, 'doc_series');
        p_require(io_rec.doc_number, 'doc_number');
        p_require_date(io_rec.doc_issue_date, 'doc_issue_date');

        -- Hujjat серия/номер uzunliklari (тип 0/6/8 -> 2/7)
        p_validate_doc_lengths(io_rec.doc_type, io_rec.doc_series, io_rec.doc_number, '');

        -- Sana mantig'i: выдача <= bugun; срок > выдачи (agar berilgan bo'lsa)
        IF io_rec.doc_issue_date > TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': doc_issue_date > bugun');
        END IF;
        IF io_rec.birth_date > TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': birth_date > bugun');
        END IF;
        IF io_rec.doc_expiry_date IS NOT NULL
           AND io_rec.doc_expiry_date <= io_rec.doc_issue_date THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': doc_expiry_date <= doc_issue_date');
        END IF;

        -- Rezidentlik (027) hujjatdan AUTO (не редактируемое)
        io_rec.resident_flag := core_cif_util.Resident_From_Doc(io_rec.doc_type);
        -- Rezidentlik kodi <-> hujjat turi ziddiyati (860 <=> doc!=4, ...)
        p_validate_residency_doc(io_rec, io_rec.doc_type);

        -- ПИНФЛ qoidasi: doc 0/6/8 -> majburiy; berilgan bo'lsa format tekshir
        IF core_cif_util.Pinfl_Required_For_Doc(io_rec.doc_type) THEN
            IF io_rec.pinfl IS NULL THEN
                RAISE_APPLICATION_ERROR(core_cif_const.c_err_pinfl_required,
                    core_cif_const.c_msg_pinfl_required);
            END IF;
        END IF;
        IF io_rec.pinfl IS NOT NULL AND NOT core_cif_util.Is_Valid_Pinfl(io_rec.pinfl) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_pinfl,
                core_cif_const.c_msg_invalid_pinfl);
        END IF;
        IF io_rec.tin IS NOT NULL AND NOT core_cif_util.Is_Valid_Inn(io_rec.tin) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_inn,
                core_cif_const.c_msg_invalid_inn || ': tin');
        END IF;

        -- Noyoblik: rezident -> ПИНФЛ + (тип+серия+номер); норезидент -> (тип+серия+номер)
        IF io_rec.resident_flag = core_cif_const.c_resident
           AND core_cif_data_reader.Phys_Pinfl_Exists(io_rec.pinfl) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_dup_pinfl,
                core_cif_const.c_msg_dup_pinfl);
        END IF;
        IF core_cif_data_reader.Phys_Doc_Exists(io_rec.doc_type, io_rec.doc_series, io_rec.doc_number) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_dup_doc,
                core_cif_const.c_msg_dup_doc);
        END IF;
    END p_validate_phys;

    -- ---------------------------------------------------------------------------
    -- p_validate_legal — юрлицо (J) majburiy + ИНН format/noyoblik + kod
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_legal(io_rec IN OUT core_cif_types.t_client_rec) IS
    BEGIN
        -- Наименование (kirill + латин)
        p_require(io_rec.org_name,     'org_name');
        p_require(io_rec.org_name_lat, 'org_name_lat');
        -- ИНН — юрлицо noyoblik kaliti (majburiy + format + noyob)
        p_require(io_rec.inn, 'inn');
        IF NOT core_cif_util.Is_Valid_Inn(io_rec.inn) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_inn,
                core_cif_const.c_msg_invalid_inn);
        END IF;
        IF core_cif_data_reader.Legal_Inn_Exists(io_rec.inn) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_dup_inn,
                core_cif_const.c_msg_dup_inn);
        END IF;
        -- Регистрационные реквизиты (номер/дата/страна регистрации, ОКЭД)
        p_require(io_rec.num_registr, 'num_registr');
        p_require_date(io_rec.date_registr, 'date_registr');
        p_require(io_rec.country_registr, 'country_registr');
        p_require(io_rec.oked, 'oked');
        IF io_rec.date_registr > TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': date_registr > bugun');
        END IF;

        -- Rezidentlik (027): nonresident_type belgilangan bo'lsa норезидент, aks holda резидент
        IF io_rec.nonresident_type IS NOT NULL THEN
            io_rec.resident_flag := core_cif_const.c_nonresident;
        ELSE
            io_rec.resident_flag := core_cif_const.c_resident;
            io_rec.resident_code := NVL(io_rec.resident_code, core_cif_const.c_resident_code_uzb);
        END IF;
    END p_validate_legal;

    -- ---------------------------------------------------------------------------
    -- p_validate_ip — ИП (I): shaxsiy blok + rezidentlik + noyoblik
    --   io_rec.resident_flag ИП hujjatidan (ip_doc_type) AUTO.
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_ip(io_rec IN OUT core_cif_types.t_client_rec) IS
    BEGIN
        -- Наименование субъекта (кирилл + латин) — ИП uchun majburiy (legal.name NOT NULL)
        p_require(io_rec.org_name,     'org_name');
        p_require(io_rec.org_name_lat, 'org_name_lat (jur_name)');
        -- Shaxsiy blok (фамилия/имя + латин)
        p_require(io_rec.ip_last_name,      'ip_last_name');
        p_require(io_rec.ip_first_name,     'ip_first_name');
        p_require(io_rec.ip_last_name_lat,  'ip_last_name_lat');
        p_require(io_rec.ip_first_name_lat, 'ip_first_name_lat');
        p_require(io_rec.ip_gender, 'ip_gender');
        p_require_date(io_rec.ip_dob, 'ip_dob');
        -- Hujjat (тип/серия/номер/дата выдачи/срок)
        p_require(io_rec.ip_doc_type,   'ip_doc_type');
        p_require(io_rec.ip_doc_serial, 'ip_doc_serial');
        p_require(io_rec.ip_doc_number, 'ip_doc_number');
        p_require_date(io_rec.ip_doc_issue_date, 'ip_doc_issue_date');

        -- Hujjat серия/номер uzunliklari (тип 0/6/8 -> 2/7)
        p_validate_doc_lengths(io_rec.ip_doc_type, io_rec.ip_doc_serial, io_rec.ip_doc_number, 'ip_');

        IF io_rec.ip_doc_issue_date > TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': ip_doc_issue_date > bugun');
        END IF;
        IF io_rec.ip_dob > TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': ip_dob > bugun');
        END IF;
        IF io_rec.ip_doc_expire_date IS NOT NULL
           AND io_rec.ip_doc_expire_date <= io_rec.ip_doc_issue_date THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_doc,
                core_cif_const.c_msg_invalid_doc || ': ip_doc_expire_date <= ip_doc_issue_date');
        END IF;

        -- Rezidentlik (027) ИП hujjatidan AUTO
        io_rec.resident_flag := core_cif_util.Resident_From_Doc(io_rec.ip_doc_type);
        -- Rezidentlik kodi <-> hujjat turi ziddiyati (860 <=> doc!=4, ...)
        p_validate_residency_doc(io_rec, io_rec.ip_doc_type);

        -- ПИНФЛ qoidasi: rezident & doc 0/6/8 -> majburiy; format
        IF io_rec.resident_flag = core_cif_const.c_resident
           AND core_cif_util.Pinfl_Required_For_Doc(io_rec.ip_doc_type)
           AND io_rec.ip_pinfl IS NULL THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_pinfl_required,
                core_cif_const.c_msg_pinfl_required);
        END IF;
        IF io_rec.ip_pinfl IS NOT NULL AND NOT core_cif_util.Is_Valid_Pinfl(io_rec.ip_pinfl) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_pinfl,
                core_cif_const.c_msg_invalid_pinfl);
        END IF;
        IF io_rec.inn IS NOT NULL AND NOT core_cif_util.Is_Valid_Inn(io_rec.inn) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_inn,
                core_cif_const.c_msg_invalid_inn);
        END IF;

        -- Noyoblik: rezident -> ПИНФЛ + (тип+серия+номер); норезидент -> doc triple
        IF io_rec.resident_flag = core_cif_const.c_resident
           AND core_cif_data_reader.Ip_Pinfl_Exists(io_rec.ip_pinfl) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_dup_pinfl,
                core_cif_const.c_msg_dup_pinfl);
        END IF;
        IF core_cif_data_reader.Ip_Doc_Exists(io_rec.ip_doc_type, io_rec.ip_doc_serial, io_rec.ip_doc_number) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_dup_doc,
                core_cif_const.c_msg_dup_doc);
        END IF;
    END p_validate_ip;

    -- ---------------------------------------------------------------------------
    -- p_validate_legal_code — юр/ИП client_code (НИББД/vaqtinchalik) format
    --   ESLATMA: service vaqtinchalik `I%` kodni oldin generatsiya qiladi (caller
    --   bermasa) -> bu yerda client_code DOIM mavjud. NULL bo'lsa (caller temp
    --   kodni o'chgan holatda) -> -20222 (himoya).
    -- ---------------------------------------------------------------------------
    PROCEDURE p_validate_legal_code(i_rec IN core_cif_types.t_client_rec) IS
    BEGIN
        IF i_rec.client_code IS NULL THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_code_required,
                core_cif_const.c_msg_code_required);
        END IF;
        IF NOT core_cif_util.Is_Valid_Legal_Code(i_rec.client_code) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_code,
                core_cif_const.c_msg_invalid_code || ': ' || i_rec.client_code);
        END IF;
    END p_validate_legal_code;

    -- ---------------------------------------------------------------------------
    -- Validate_For_Register — kind-aware to'liq registratsiya tekshiruvi (PUBLIC)
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_For_Register(io_rec IN OUT core_cif_types.t_client_rec) IS
    BEGIN
        -- Тип субъекта (P/J/I) majburiy + to'g'ri
        IF io_rec.client_kind IS NULL
           OR io_rec.client_kind NOT IN (core_cif_const.c_kind_phys,
                                         core_cif_const.c_kind_legal,
                                         core_cif_const.c_kind_ip) THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_kind,
                core_cif_const.c_msg_invalid_kind);
        END IF;

        -- Umumiy yadro (тип клиента + nom)
        p_validate_common(io_rec);

        -- Region/rayon (berilgan bo'lsa СПР 52 ga mos kelishi shart)
        IF io_rec.region_code IS NOT NULL OR io_rec.district_code IS NOT NULL THEN
            IF NOT core_cif_data_reader.Region_Valid(io_rec.region_code, io_rec.district_code) THEN
                RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_region,
                    core_cif_const.c_msg_invalid_region);
            END IF;
        END IF;

        -- Turga xos blok
        IF io_rec.client_kind = core_cif_const.c_kind_phys THEN
            p_validate_phys(io_rec);
            -- физ kod modul/trigger beradi — io_rec dan kod TALAB QILINMAYDI.
        ELSIF io_rec.client_kind = core_cif_const.c_kind_legal THEN
            p_validate_legal(io_rec);
            p_validate_legal_code(io_rec);   -- юр: client_code НИББД/vaqtinchalik
        ELSE  -- ИП
            p_validate_ip(io_rec);
            p_validate_legal_code(io_rec);   -- ИП: client_code НИББД/vaqtinchalik
        END IF;
    END Validate_For_Register;

    -- ---------------------------------------------------------------------------
    -- Validate_Approve — Утвердить (holat CREATED + Maker-Checker)
    -- ---------------------------------------------------------------------------
    PROCEDURE Validate_Approve(
        i_client_id      IN NUMBER,
        i_current_status IN VARCHAR2,
        i_maker          IN NUMBER,
        i_checker        IN NUMBER
    ) IS
    BEGIN
        -- Klient mavjudligi
        IF i_current_status IS NULL THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_client_not_found,
                core_cif_const.c_msg_client_not_found);
        END IF;
        -- Faqat «Создан» (CREATED) holatdan tasdiqlash mumkin
        IF i_current_status <> core_cif_const.c_st_created THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_state,
                core_cif_const.c_msg_invalid_state
                || ' (joriy: ' || i_current_status || ', kutilgan: CREATED)');
        END IF;
        -- Maker-Checker (ikki ko'z): tasdiqlovchi yaratuvchidan farq qilishi shart
        IF i_checker IS NOT NULL AND i_maker IS NOT NULL AND i_checker = i_maker THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_maker_eq_checker,
                core_cif_const.c_msg_maker_eq_checker);
        END IF;
    END Validate_Approve;

END core_cif_rules;
/


-- *************************************************************************
-- 10. core_cif_service — biznes logika (COMMIT/ROLLBACK FAQAT shu yerda, E-5)
--    Public proc: o_code/o_message/o_ora_message (SC-1), boshida init (SC-2),
--    tanasi rules+repo -> COMMIT; WHEN OTHERS -> ROLLBACK + xato triple.
--
--    KECHIKTIRILGAN operatsiyalar (kelajak skript — bu faylda YO'Q):
--      - Update_Client  (core_cif_service.update_customer, RECORD)
--      - Block_Client / Unblock_Client (APPROVED -> TEMP_CLOSED/BLOCKED)
--      - Close_Client   (APPROVED/TEMP_CLOSED -> CLOSED, hisoblar 0)
--      - Archive_Client / Delete_Client (faqat CREATED dan Удалить)
--      - НИББД/AML REAL adapterlari (core_cif_nibbd.Register / core_cif_aml.Check
--        hozir STUB; gate ulangan, real logika F2-F3 da).
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_service AS

    -- ---------------------------------------------------------------------------
    -- Register_Client — «Создать/Добавить»: klient ochish (физ/юр/ИП)
    --   rules -> repo.Insert_Client (+Individual/Legal) -> status CREATED -> COMMIT.
    --   физ client_code: trigger beradi (io_rec ga RETURNING orqali qaytadi).
    --   юр/ИП client_code: caller bermasa SERVICE vaqtinchalik `I%` kod beradi
    --     (core_cif_util.Next_Temp_Legal_Code) -> io_rec.nibbd_temp_code/client_code.
    --     «Иностранный банк» (`0009%`) yoki НИББД kodi -> caller dan (saqlanadi).
    -- ---------------------------------------------------------------------------
    PROCEDURE Register_Client(
        io_rec        IN OUT core_cif_types.t_client_rec,
        o_client_id   OUT NUMBER,
        o_client_code OUT VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2,
        o_ora_message OUT VARCHAR2
    );

    -- ---------------------------------------------------------------------------
    -- Approve_Client — «Утвердить»: Maker-Checker + AML + НИББД -> APPROVED
    --   AML/НИББД GATE (stub adapter): natija FAILED bo'lsa RAISE (-20226/-20228)
    --   -> ROLLBACK -> APPROVED ga O'TMAYDI (hisob ochish taqiqlanadi).
    --   STUB adapterlar hozir PASSED qaytaradi, lekin gate boshqaruvi mavjud.
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve_Client(
        i_client_id    IN  NUMBER,
        i_checker_user IN  NUMBER,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2,
        o_ora_message  OUT VARCHAR2
    );

END core_cif_service;
/


CREATE OR REPLACE PACKAGE BODY core_cif_service AS

    -- ---------------------------------------------------------------------------
    -- Register_Client — klient ochish orkestratsiyasi (физ/юр/ИП)
    -- ---------------------------------------------------------------------------
    PROCEDURE Register_Client(
        io_rec        IN OUT core_cif_types.t_client_rec,
        o_client_id   OUT NUMBER,
        o_client_code OUT VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2,
        o_ora_message OUT VARCHAR2
    ) IS
        v_temp_code core_cif_clients.client_code%TYPE;
    BEGIN
        -- SC-2: OUT init
        o_code        := core_cif_const.c_code_ok;
        o_message     := NULL;
        o_ora_message := NULL;
        o_client_id   := NULL;
        o_client_code := NULL;

        -- 0) Юр/ИП vaqtinchalik `I%` kodni SYSTEM generatsiya qiladi (caller
        --    bermagan bo'lsa). «Иностранный банк» (0009%) yoki oldindan berilgan
        --    НИББД kodi -> caller dan (TEGILMAYDI). Trigger nibbd_temp_expiry
        --    ni temp kod bo'lsa created+10 qiladi.
        IF io_rec.client_kind IN (core_cif_const.c_kind_legal, core_cif_const.c_kind_ip)
           AND io_rec.client_code IS NULL THEN
            v_temp_code          := core_cif_util.Next_Temp_Legal_Code;
            io_rec.client_code   := v_temp_code;
            io_rec.nibbd_temp_code := v_temp_code;
        END IF;

        -- 1) Qoidalar (kind-aware) — rezidentlik AUTO io_rec ga yoziladi
        core_cif_rules.Validate_For_Register(io_rec);

        -- 2) Boshlang'ich status (Создан) — sub-status hozircha NULL
        io_rec.client_status     := core_cif_const.c_st_created;
        io_rec.client_sub_status := NULL;

        -- 3) BAZA satr (client_id + физ client_code RETURNING orqali qaytadi)
        core_cif_repo.Insert_Client(io_rec);

        -- 4) Turga xos kengaytma (1:1)
        IF io_rec.client_kind = core_cif_const.c_kind_phys THEN
            core_cif_repo.Insert_Individual(io_rec);
        ELSE  -- 'J' (юр) yoki 'I' (ИП) — ikkalasi ham core_cif_legal
            core_cif_repo.Insert_Legal(io_rec);
        END IF;

        -- 5) Audit log
        core_cif_logger.Log(io_rec.client_id, 'REGISTER',
            'kind=' || io_rec.client_kind || ' code=' || io_rec.client_code,
            io_rec.maker_user);

        -- 6) COMMIT (E-5 — faqat service)
        COMMIT;

        o_client_id   := io_rec.client_id;
        o_client_code := io_rec.client_code;
        o_message     := 'Mijoz yaratildi (Создан): ' || io_rec.client_code;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := SQLCODE;
            o_message     := NVL(REGEXP_SUBSTR(SQLERRM, '[^:]+:\s*(.*)', 1, 1, NULL, 1),
                                 'Mijoz yaratishda xato');
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Register_Client;

    -- ---------------------------------------------------------------------------
    -- Approve_Client — «Утвердить»: Maker-Checker -> AML(gate) -> НИББД(gate) -> APPROVED
    --   AML va НИББД GATE: adapter FAILED qaytarsa RAISE -> ROLLBACK -> NOT APPROVED.
    --   Sub-status pipeline guard: har qadamdan oldin kutilgan predshart tekshiriladi
    --   (re-entrancy/qisman bajarilishdan himoya).
    -- ---------------------------------------------------------------------------
    PROCEDURE Approve_Client(
        i_client_id    IN  NUMBER,
        i_checker_user IN  NUMBER,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2,
        o_ora_message  OUT VARCHAR2
    ) IS
        v_status core_cif_clients.client_status%TYPE;
        v_maker  core_cif_clients.maker_user%TYPE;
        v_sub    core_cif_clients.client_sub_status%TYPE;
        v_aml    core_cif_types.t_aml_result;
        v_nibbd  core_cif_types.t_nibbd_result;
    BEGIN
        -- SC-2: OUT init
        o_code        := core_cif_const.c_code_ok;
        o_message     := NULL;
        o_ora_message := NULL;

        -- 1) Joriy holat + maker (Maker-Checker)
        v_status := core_cif_data_reader.Get_Status(i_client_id);
        v_maker  := core_cif_data_reader.Get_Maker(i_client_id);

        -- 2) Qoidalar (holat CREATED + maker <> checker)
        core_cif_rules.Validate_Approve(i_client_id, v_status, v_maker, i_checker_user);

        -- 3) «на утверждение» (sub-status) — approval boshlandi
        --    Guard: boshlashdan oldin sub-status NULL yoki TO_APPROVE bo'lishi kerak
        --    (CREATED holatda yangi mijoz sub-status NULL).
        v_sub := core_cif_data_reader.Get_Sub_Status(i_client_id);
        IF v_sub IS NOT NULL AND v_sub <> core_cif_const.c_st_to_approve THEN
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_invalid_state,
                core_cif_const.c_msg_invalid_state
                || ' (kutilmagan sub-status: ' || v_sub || ')');
        END IF;
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_to_approve, i_checker_user);

        -- 4) AML bosqichi (GATE): На проверке AML -> adapter -> Проверен AML
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_aml_check, i_checker_user);
        v_aml := core_cif_aml.Check_Client(i_client_id);
        IF NVL(v_aml.passed, 'N') <> 'Y' THEN
            -- AML rad etdi -> aml_status FAILED yozib, RAISE (ROLLBACK service da)
            core_cif_repo.Set_Aml(i_client_id, core_cif_const.c_aml_failed,
                v_aml.risk, i_checker_user);
            core_cif_logger.Log(i_client_id, 'AML_CHECK',
                'FAILED: ' || v_aml.reason, i_checker_user);
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_aml_failed,
                core_cif_const.c_msg_aml_failed
                || CASE WHEN v_aml.reason IS NOT NULL THEN ' (' || v_aml.reason || ')' END);
        END IF;
        core_cif_repo.Set_Aml(i_client_id, core_cif_const.c_aml_passed,
            NVL(v_aml.risk, core_cif_const.c_aml_risk_low), i_checker_user);
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_aml_passed, i_checker_user);
        core_cif_logger.Log(i_client_id, 'AML_CHECK', 'PASSED', i_checker_user);

        -- 5) НИББД bosqichi (GATE): На отправление -> Отправлен -> adapter -> Обработан
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_nibbd_to_send, i_checker_user);
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_nibbd_sent, i_checker_user);
        v_nibbd := core_cif_nibbd.Register(i_client_id);
        IF NVL(v_nibbd.registered, 'N') <> 'Y' THEN
            -- НИББД rad etdi -> RAISE -> hisob ochish taqiqlanadi (fiz l.108/524)
            core_cif_logger.Log(i_client_id, 'NIBBD_REG',
                'FAILED: ' || v_nibbd.reason, i_checker_user);
            RAISE_APPLICATION_ERROR(core_cif_const.c_err_nibbd_failed,
                core_cif_const.c_msg_nibbd_failed
                || CASE WHEN v_nibbd.reason IS NOT NULL THEN ' (' || v_nibbd.reason || ')' END);
        END IF;
        -- registered=Y; haqiqiy kod berilsa temp `I%` -> real НИББД kodga almashadi
        core_cif_repo.Set_Nibbd_Registered(i_client_id, i_checker_user, v_nibbd.real_code);
        core_cif_repo.Set_Status(i_client_id, core_cif_const.c_st_created,
            core_cif_const.c_st_nibbd_done, i_checker_user);
        core_cif_logger.Log(i_client_id, 'NIBBD_REG', 'registered', i_checker_user);

        -- 6) Yakuniy tasdiqlash (Утвержден) — Maker-Checker yopiladi
        core_cif_repo.Approve(i_client_id, i_checker_user);
        core_cif_logger.Log(i_client_id, 'APPROVE', 'status=APPROVED', i_checker_user);

        -- 7) COMMIT (E-5 — faqat service)
        COMMIT;

        o_message := 'Mijoz tasdiqlandi (Утвержден) — hisob ochish ochildi';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := SQLCODE;
            o_message     := NVL(REGEXP_SUBSTR(SQLERRM, '[^:]+:\s*(.*)', 1, 1, NULL, 1),
                                 'Mijozni tasdiqlashda xato');
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Approve_Client;

END core_cif_service;
/

-- ============================================================================
-- 30_cif_packages.sql — TUGADI
-- Keyingi: 31_cif_views (UI viewlar), 32_cif_seed (test ma'lumotlar),
--   core_cif_nibbd / core_cif_aml REAL adapter (F2-F3), Update/Block/Close service.
-- ============================================================================
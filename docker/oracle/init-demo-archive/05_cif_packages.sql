-- ============================================================================
-- MARS ABS - core_cif moduli
-- 05_cif_packages.sql - PL/SQL paketlar (SIRIUS qatlam arxitekturasi)
-- Sana: 2026-05-26
--
-- Qatlamlar (L-1):
--   CONST       -> konstantalar
--   TYPES       -> record type'lar (t_customer_rec, t_customer_tab)
--   UTIL        -> yordamchi funksiyalar (pure)
--   LOGGER      -> audit log (side-effect writes + reads from audit_log)
--   DATA_READER -> faqat SELECT (core_cif_customers) — type'lar TYPES'da
--   REPO        -> faqat DML: INSERT/UPDATE/DELETE (COMMIT yo'q!)
--   RULES       -> validatsiya (DML yo'q!)
--   SERVICE     -> biznes logika (COMMIT/ROLLBACK faqat shu yerda)
--
-- Naming (N-1..N-6):
--   i_ = IN, o_ = OUT, io_ = IN OUT
--   v_ = local variable, cr_ = cursor, c_ = constant
--   e_ = exception, t_ = type
--
-- Kompilatsiya tartibi:
--   1. core_cif_const (spec only)
--   2. core_cif_types (spec only) — t_customer_rec, t_customer_tab
--   3. core_cif_util (spec + body)
--   4. core_cif_logger (spec + body)
--   5. core_cif_data_reader (spec + body) — faqat SELECT, type'lar core_cif_types'da
--   6. core_cif_repo (spec + body) — faqat DML
--   7. core_cif_rules (spec + body) — data_reader ishlatadi
--   8. core_cif_service (spec + body) — barcha qatlamlarni ishlatadi
-- ============================================================================


-- *************************************************************************
-- 1. core_cif_const - CONST qatlami (konstantalar)
--    Hech qanday logika yo'q, faqat konstantalar.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_const AS
    -- Statuslar
    c_status_pending    CONSTANT VARCHAR2(20) := 'PENDING';
    c_status_active     CONSTANT VARCHAR2(20) := 'ACTIVE';
    c_status_blocked    CONSTANT VARCHAR2(20) := 'BLOCKED';
    c_status_closed     CONSTANT VARCHAR2(20) := 'CLOSED';
    c_status_rejected   CONSTANT VARCHAR2(20) := 'REJECTED';

    -- Mijoz turlari
    c_type_individual   CONSTANT VARCHAR2(20) := 'INDIVIDUAL';
    c_type_corporate    CONSTANT VARCHAR2(20) := 'CORPORATE';

    -- Risk kategoriyalari
    c_risk_low          CONSTANT VARCHAR2(10) := 'LOW';
    c_risk_medium       CONSTANT VARCHAR2(10) := 'MEDIUM';
    c_risk_high         CONSTANT VARCHAR2(10) := 'HIGH';

    -- Xato kodlari (E-7: -20000..-20999 oralig'ida)
    c_err_duplicate_pinfl           CONSTANT NUMBER := -20001;
    c_err_duplicate_inn             CONSTANT NUMBER := -20002;
    c_err_invalid_status_change     CONSTANT NUMBER := -20003;
    c_err_underage                  CONSTANT NUMBER := -20004;
    c_err_maker_equals_checker      CONSTANT NUMBER := -20005;
    c_err_invalid_pinfl             CONSTANT NUMBER := -20006;
    c_err_invalid_inn               CONSTANT NUMBER := -20007;
    c_err_required_field            CONSTANT NUMBER := -20008;
    c_err_invalid_phone             CONSTANT NUMBER := -20009;
    c_err_customer_not_found        CONSTANT NUMBER := -20010;
    c_err_not_pending               CONSTANT NUMBER := -20011;

    -- Xato xabarlari
    c_msg_duplicate_pinfl           CONSTANT VARCHAR2(200) := 'Bu PINFL tizimda mavjud';
    c_msg_duplicate_inn             CONSTANT VARCHAR2(200) := 'Bu STIR tizimda mavjud';
    c_msg_invalid_status_change     CONSTANT VARCHAR2(200) := 'Holat o''zgartirish mumkin emas';
    c_msg_underage                  CONSTANT VARCHAR2(200) := 'Mijoz yoshi 18 dan kichik';
    c_msg_maker_equals_checker      CONSTANT VARCHAR2(200) := 'Yaratuvchi va tasdiqlovchi bir xil bo''la olmaydi';
    c_msg_invalid_pinfl             CONSTANT VARCHAR2(200) := 'PINFL formati noto''g''ri (14 xonali raqam bo''lishi kerak)';
    c_msg_invalid_inn               CONSTANT VARCHAR2(200) := 'STIR formati noto''g''ri (9 xonali raqam bo''lishi kerak)';
    c_msg_required_field            CONSTANT VARCHAR2(200) := 'Majburiy maydon to''ldirilmagan';
    c_msg_invalid_phone             CONSTANT VARCHAR2(200) := 'Telefon formati noto''g''ri (+998XXXXXXXXX)';
    c_msg_customer_not_found        CONSTANT VARCHAR2(200) := 'Mijoz topilmadi';
    c_msg_not_pending               CONSTANT VARCHAR2(200) := 'Mijoz PENDING holatda emas';
    c_msg_ok                        CONSTANT VARCHAR2(10)  := 'OK';

    -- Umumiy kodlar
    c_code_ok           CONSTANT NUMBER := 0;
    c_code_error        CONSTANT NUMBER := -1;

    -- Sahifalash
    c_default_page_size CONSTANT NUMBER := 20;
END core_cif_const;
/


-- *************************************************************************
-- 2. core_cif_types - TYPES qatlami (record type'lar)
--    CONST darajasida — body yo'q, faqat spec.
--    Barcha qatlamlar (DATA_READER, REPO, RULES, SERVICE) shu type'larga
--    murojaat qiladi: core_cif_types.t_customer_rec
--
--    SIRIUS qoidasi: DATA_READER faqat SELECT o'z ichiga olishi kerak.
--    Type'lar alohida TYPES paketida bo'lishi shart.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_types AS
    -- Record type'lar — barcha qatlamlar tomonidan ishlatiladi
    -- CONST darajasida, body yo'q (faqat spec)

    TYPE t_customer_rec IS RECORD (
        customer_id         core_cif_customers.customer_id%TYPE,
        cif_number          core_cif_customers.cif_number%TYPE,
        customer_type       core_cif_customers.customer_type%TYPE,
        first_name          core_cif_customers.first_name%TYPE,
        last_name           core_cif_customers.last_name%TYPE,
        middle_name         core_cif_customers.middle_name%TYPE,
        org_name            core_cif_customers.org_name%TYPE,
        org_full_name       core_cif_customers.org_full_name%TYPE,
        org_form            core_cif_customers.org_form%TYPE,
        oked                core_cif_customers.oked%TYPE,
        reg_number          core_cif_customers.reg_number%TYPE,
        reg_date            core_cif_customers.reg_date%TYPE,
        reg_authority       core_cif_customers.reg_authority%TYPE,
        director_name       core_cif_customers.director_name%TYPE,
        director_position   core_cif_customers.director_position%TYPE,
        accountant_name     core_cif_customers.accountant_name%TYPE,
        director_pinfl      core_cif_customers.director_pinfl%TYPE,
        pinfl               core_cif_customers.pinfl%TYPE,
        inn                 core_cif_customers.inn%TYPE,
        birth_date          core_cif_customers.birth_date%TYPE,
        birth_place         core_cif_customers.birth_place%TYPE,
        gender              core_cif_customers.gender%TYPE,
        phone               core_cif_customers.phone%TYPE,
        email               core_cif_customers.email%TYPE,
        legal_address       core_cif_customers.legal_address%TYPE,
        actual_address      core_cif_customers.actual_address%TYPE,
        resident_flag       core_cif_customers.resident_flag%TYPE,
        country_code        core_cif_customers.country_code%TYPE,
        branch_code         core_cif_customers.branch_code%TYPE,
        sector_code         core_cif_customers.sector_code%TYPE,
        risk_category       core_cif_customers.risk_category%TYPE,
        is_pep              core_cif_customers.is_pep%TYPE,
        opening_purpose     core_cif_customers.opening_purpose%TYPE,
        employer_name       core_cif_customers.employer_name%TYPE,
        employer_position   core_cif_customers.employer_position%TYPE,
        employer_address    core_cif_customers.employer_address%TYPE,
        employer_phone      core_cif_customers.employer_phone%TYPE,
        other_bank_name     core_cif_customers.other_bank_name%TYPE,
        other_bank_mfo      core_cif_customers.other_bank_mfo%TYPE,
        other_bank_account  core_cif_customers.other_bank_account%TYPE,
        status              core_cif_customers.status%TYPE,
        approved_by         core_cif_customers.approved_by%TYPE,
        approved_at         core_cif_customers.approved_at%TYPE,
        created_by          core_cif_customers.created_by%TYPE,
        created_at          core_cif_customers.created_at%TYPE,
        updated_by          core_cif_customers.updated_by%TYPE,
        updated_at          core_cif_customers.updated_at%TYPE
    );

    TYPE t_customer_tab IS TABLE OF t_customer_rec;
END core_cif_types;
/


-- *************************************************************************
-- 3. core_cif_util - UTIL qatlami (yordamchi funksiyalar)
--    Pure funksiyalar — hech qanday DML, hech qanday SELECT (jadvallardan).
--    Faqat hisob-kitob va formatlash.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_util AS

    -- CIF raqam generatsiya (sequence + format)
    FUNCTION Generate_Cif_Number RETURN VARCHAR2;

    -- Telefon formatlash (+998 bilan boshlanishi kerak)
    FUNCTION Format_Phone(
        i_phone     IN VARCHAR2
    ) RETURN VARCHAR2;

    -- PINFL validatsiya (14 xona, hammasi raqam)
    FUNCTION Is_Valid_Pinfl(
        i_pinfl     IN VARCHAR2
    ) RETURN BOOLEAN;

    -- INN/STIR validatsiya (9 xona, hammasi raqam)
    FUNCTION Is_Valid_Inn(
        i_inn       IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Yosh hisoblash (bugungi sanadan)
    FUNCTION Calculate_Age(
        i_birth_date IN DATE
    ) RETURN NUMBER;

END core_cif_util;
/

CREATE OR REPLACE PACKAGE BODY core_cif_util AS

    -- =======================================================================
    FUNCTION Generate_Cif_Number RETURN VARCHAR2 IS
        v_seq_val   NUMBER;
        v_cif       VARCHAR2(20);
    BEGIN
        SELECT core_cif_seq.NEXTVAL INTO v_seq_val FROM DUAL;
        -- S-4: TO_CHAR format mask bilan
        v_cif := 'CIF-'
            || TO_CHAR(SYSDATE, 'YYYYMMDD')
            || '-'
            || LPAD(TO_CHAR(v_seq_val), 6, '0');
        RETURN v_cif;
    END Generate_Cif_Number;

    -- =======================================================================
    FUNCTION Format_Phone(
        i_phone     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_phone     VARCHAR2(20);
    BEGIN
        IF i_phone IS NULL THEN
            RETURN NULL;
        END IF;
        -- Probellarni olib tashlash
        v_phone := REPLACE(REPLACE(REPLACE(i_phone, ' ', ''), '-', ''), '(', '');
        v_phone := REPLACE(v_phone, ')', '');
        -- 998 bilan boshlansa, + qo'shish
        IF SUBSTR(v_phone, 1, 3) = '998' AND SUBSTR(v_phone, 1, 1) != '+' THEN
            v_phone := '+' || v_phone;
        END IF;
        RETURN v_phone;
    END Format_Phone;

    -- =======================================================================
    FUNCTION Is_Valid_Pinfl(
        i_pinfl     IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        -- E-4: IS NULL ishlatish (= NULL emas)
        IF i_pinfl IS NULL THEN
            RETURN FALSE;
        END IF;
        -- 14 xona, hammasi raqam
        IF LENGTH(i_pinfl) != 14 THEN
            RETURN FALSE;
        END IF;
        IF REGEXP_LIKE(i_pinfl, '^\d{14}$') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END Is_Valid_Pinfl;

    -- =======================================================================
    FUNCTION Is_Valid_Inn(
        i_inn       IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_inn IS NULL THEN
            RETURN FALSE;
        END IF;
        IF LENGTH(i_inn) != 9 THEN
            RETURN FALSE;
        END IF;
        IF REGEXP_LIKE(i_inn, '^\d{9}$') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END Is_Valid_Inn;

    -- =======================================================================
    FUNCTION Calculate_Age(
        i_birth_date IN DATE
    ) RETURN NUMBER IS
        v_age   NUMBER;
    BEGIN
        IF i_birth_date IS NULL THEN
            RETURN NULL;
        END IF;
        -- S-4: TO_CHAR format mask bilan
        v_age := TRUNC(MONTHS_BETWEEN(SYSDATE, i_birth_date) / 12);
        RETURN v_age;
    END Calculate_Age;

END core_cif_util;
/


-- *************************************************************************
-- 4. core_cif_logger - LOGGER qatlami (audit log)
--    Side-effect yozuvlar: INSERT into core_cif_audit_log (COMMIT yo'q!)
--    Audit log'dan o'qish: SELECT from core_cif_audit_log
--    Bu qatlam faqat audit_log jadvali bilan ishlaydi.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_logger AS

    -- WRITE: Audit log yozish (INSERT, COMMIT yo'q!)
    -- S-3: INSERT ustun ro'yxati bilan
    PROCEDURE Log_Audit(
        i_customer_id   IN NUMBER,
        i_action_type   IN VARCHAR2,
        i_field_name    IN VARCHAR2 DEFAULT NULL,
        i_old_value     IN VARCHAR2 DEFAULT NULL,
        i_new_value     IN VARCHAR2 DEFAULT NULL,
        i_changed_by    IN VARCHAR2
    );

    -- READ: Mijoz bo'yicha audit log (sahifalash bilan)
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    );

    -- READ: Mijoz bo'yicha audit log soni
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER;

    -- READ: Amal turi bo'yicha audit log
    PROCEDURE Find_By_Action(
        i_customer_id   IN  NUMBER,
        i_action_type   IN  VARCHAR2,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    );

    -- READ: Sana oralig'i bo'yicha audit log
    PROCEDURE Find_By_Date_Range(
        i_customer_id   IN  NUMBER,
        i_date_from     IN  TIMESTAMP,
        i_date_to       IN  TIMESTAMP DEFAULT SYSTIMESTAMP,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    );

END core_cif_logger;
/

CREATE OR REPLACE PACKAGE BODY core_cif_logger AS

    -- =======================================================================
    -- Log_Audit - Audit log yozish
    -- S-3: INSERT ustun ro'yxati bilan
    -- E-5: COMMIT yo'q (LOGGER qatlam — SERVICE commit qiladi)
    -- =======================================================================
    PROCEDURE Log_Audit(
        i_customer_id   IN NUMBER,
        i_action_type   IN VARCHAR2,
        i_field_name    IN VARCHAR2 DEFAULT NULL,
        i_old_value     IN VARCHAR2 DEFAULT NULL,
        i_new_value     IN VARCHAR2 DEFAULT NULL,
        i_changed_by    IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO core_cif_audit_log (
            customer_id, action_type, field_name,
            old_value, new_value, changed_by, changed_at
        ) VALUES (
            i_customer_id, i_action_type, i_field_name,
            i_old_value, i_new_value, i_changed_by, SYSTIMESTAMP
        );
    END Log_Audit;

    -- =======================================================================
    -- Find_By_Customer - Mijoz bo'yicha audit log (sahifalash bilan)
    -- S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT log_id, customer_id, action_type, field_name,
                   old_value, new_value, changed_by, changed_at
              FROM core_cif_audit_log
             WHERE customer_id = i_customer_id
             ORDER BY changed_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_By_Customer;

    -- =======================================================================
    -- Count_By_Customer - Mijoz bo'yicha audit log soni
    -- =======================================================================
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count
          FROM core_cif_audit_log
         WHERE customer_id = i_customer_id;
        RETURN v_count;
    END Count_By_Customer;

    -- =======================================================================
    -- Find_By_Action - Amal turi bo'yicha audit log
    -- S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Action(
        i_customer_id   IN  NUMBER,
        i_action_type   IN  VARCHAR2,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT log_id, customer_id, action_type, field_name,
                   old_value, new_value, changed_by, changed_at
              FROM core_cif_audit_log
             WHERE customer_id = i_customer_id
               AND action_type = i_action_type
             ORDER BY changed_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_By_Action;

    -- =======================================================================
    -- Find_By_Date_Range - Sana oralig'i bo'yicha audit log
    -- S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Date_Range(
        i_customer_id   IN  NUMBER,
        i_date_from     IN  TIMESTAMP,
        i_date_to       IN  TIMESTAMP DEFAULT SYSTIMESTAMP,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT log_id, customer_id, action_type, field_name,
                   old_value, new_value, changed_by, changed_at
              FROM core_cif_audit_log
             WHERE customer_id = i_customer_id
               AND changed_at >= i_date_from
               AND changed_at <= i_date_to
             ORDER BY changed_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_By_Date_Range;

END core_cif_logger;
/


-- *************************************************************************
-- 5. core_cif_data_reader - DATA_READER qatlami (faqat SELECT)
--    core_cif_customers jadvalidan faqat o'qish operatsiyalari.
--    DML yo'q! COMMIT yo'q!
--    Type'lar core_cif_types paketiga ko'chirilgan (SIRIUS L-1 qoidasi).
--    DATA_READER faqat SELECT o'z ichiga olishi kerak.
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_data_reader AS

    -- SELECT by ID (S-2: aniq ustun ro'yxati)
    PROCEDURE Find_By_Id(
        i_id        IN  NUMBER,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    );

    -- SELECT by CIF number
    PROCEDURE Find_By_Cif(
        i_cif       IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    );

    -- SELECT by PINFL
    PROCEDURE Find_By_Pinfl(
        i_pinfl     IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    );

    -- SELECT by INN
    PROCEDURE Find_By_Inn(
        i_inn       IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    );

    -- Dinamik qidiruv (S-1: statik SQL, bind variables bilan)
    PROCEDURE Search(
        i_name          IN  VARCHAR2 DEFAULT NULL,
        i_phone         IN  VARCHAR2 DEFAULT NULL,
        i_status        IN  VARCHAR2 DEFAULT NULL,
        i_customer_type IN  VARCHAR2 DEFAULT NULL,
        i_branch_code   IN  VARCHAR2 DEFAULT NULL,
        i_page          IN  NUMBER   DEFAULT 1,
        i_page_size     IN  NUMBER   DEFAULT 20,
        o_results       OUT SYS_REFCURSOR
    );

    -- Sahifalash bilan ro'yxat
    PROCEDURE Find_All(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    );

    -- PENDING holatdagilar (Maker-Checker)
    PROCEDURE Find_Pending(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    );

    -- Jami mijozlar soni
    FUNCTION Count_All RETURN NUMBER;

    -- Status bo'yicha soni
    FUNCTION Count_By_Status(
        i_status    IN VARCHAR2
    ) RETURN NUMBER;

    -- Qidiruv natijalari soni (sahifalash uchun total)
    FUNCTION Count_Search(
        i_name          IN  VARCHAR2 DEFAULT NULL,
        i_phone         IN  VARCHAR2 DEFAULT NULL,
        i_status        IN  VARCHAR2 DEFAULT NULL,
        i_customer_type IN  VARCHAR2 DEFAULT NULL,
        i_branch_code   IN  VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

END core_cif_data_reader;
/

CREATE OR REPLACE PACKAGE BODY core_cif_data_reader AS

    -- =======================================================================
    -- Find_By_Id - S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Id(
        i_id        IN  NUMBER,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT customer_id, cif_number, customer_type,
               first_name, last_name, middle_name,
               org_name, org_full_name, org_form, oked,
               reg_number, reg_date, reg_authority,
               director_name, director_position, accountant_name, director_pinfl,
               pinfl, inn, birth_date, birth_place, gender,
               phone, email, legal_address, actual_address,
               resident_flag, country_code, branch_code, sector_code,
               risk_category, is_pep, opening_purpose,
               employer_name, employer_position, employer_address, employer_phone,
               other_bank_name, other_bank_mfo, other_bank_account,
               status, approved_by, approved_at,
               created_by, created_at, updated_by, updated_at
          INTO o_rec.customer_id, o_rec.cif_number, o_rec.customer_type,
               o_rec.first_name, o_rec.last_name, o_rec.middle_name,
               o_rec.org_name, o_rec.org_full_name, o_rec.org_form, o_rec.oked,
               o_rec.reg_number, o_rec.reg_date, o_rec.reg_authority,
               o_rec.director_name, o_rec.director_position, o_rec.accountant_name, o_rec.director_pinfl,
               o_rec.pinfl, o_rec.inn, o_rec.birth_date, o_rec.birth_place, o_rec.gender,
               o_rec.phone, o_rec.email, o_rec.legal_address, o_rec.actual_address,
               o_rec.resident_flag, o_rec.country_code, o_rec.branch_code, o_rec.sector_code,
               o_rec.risk_category, o_rec.is_pep, o_rec.opening_purpose,
               o_rec.employer_name, o_rec.employer_position, o_rec.employer_address, o_rec.employer_phone,
               o_rec.other_bank_name, o_rec.other_bank_mfo, o_rec.other_bank_account,
               o_rec.status, o_rec.approved_by, o_rec.approved_at,
               o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_cif_customers
         WHERE customer_id = i_id;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Id;

    -- =======================================================================
    -- Find_By_Cif
    -- =======================================================================
    PROCEDURE Find_By_Cif(
        i_cif       IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT customer_id, cif_number, customer_type,
               first_name, last_name, middle_name,
               org_name, org_full_name, org_form, oked,
               reg_number, reg_date, reg_authority,
               director_name, director_position, accountant_name, director_pinfl,
               pinfl, inn, birth_date, birth_place, gender,
               phone, email, legal_address, actual_address,
               resident_flag, country_code, branch_code, sector_code,
               risk_category, is_pep, opening_purpose,
               employer_name, employer_position, employer_address, employer_phone,
               other_bank_name, other_bank_mfo, other_bank_account,
               status, approved_by, approved_at,
               created_by, created_at, updated_by, updated_at
          INTO o_rec.customer_id, o_rec.cif_number, o_rec.customer_type,
               o_rec.first_name, o_rec.last_name, o_rec.middle_name,
               o_rec.org_name, o_rec.org_full_name, o_rec.org_form, o_rec.oked,
               o_rec.reg_number, o_rec.reg_date, o_rec.reg_authority,
               o_rec.director_name, o_rec.director_position, o_rec.accountant_name, o_rec.director_pinfl,
               o_rec.pinfl, o_rec.inn, o_rec.birth_date, o_rec.birth_place, o_rec.gender,
               o_rec.phone, o_rec.email, o_rec.legal_address, o_rec.actual_address,
               o_rec.resident_flag, o_rec.country_code, o_rec.branch_code, o_rec.sector_code,
               o_rec.risk_category, o_rec.is_pep, o_rec.opening_purpose,
               o_rec.employer_name, o_rec.employer_position, o_rec.employer_address, o_rec.employer_phone,
               o_rec.other_bank_name, o_rec.other_bank_mfo, o_rec.other_bank_account,
               o_rec.status, o_rec.approved_by, o_rec.approved_at,
               o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_cif_customers
         WHERE cif_number = i_cif;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Cif;

    -- =======================================================================
    -- Find_By_Pinfl
    -- =======================================================================
    PROCEDURE Find_By_Pinfl(
        i_pinfl     IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT customer_id, cif_number, customer_type,
               first_name, last_name, middle_name,
               org_name, org_full_name, org_form, oked,
               reg_number, reg_date, reg_authority,
               director_name, director_position, accountant_name, director_pinfl,
               pinfl, inn, birth_date, birth_place, gender,
               phone, email, legal_address, actual_address,
               resident_flag, country_code, branch_code, sector_code,
               risk_category, is_pep, opening_purpose,
               employer_name, employer_position, employer_address, employer_phone,
               other_bank_name, other_bank_mfo, other_bank_account,
               status, approved_by, approved_at,
               created_by, created_at, updated_by, updated_at
          INTO o_rec.customer_id, o_rec.cif_number, o_rec.customer_type,
               o_rec.first_name, o_rec.last_name, o_rec.middle_name,
               o_rec.org_name, o_rec.org_full_name, o_rec.org_form, o_rec.oked,
               o_rec.reg_number, o_rec.reg_date, o_rec.reg_authority,
               o_rec.director_name, o_rec.director_position, o_rec.accountant_name, o_rec.director_pinfl,
               o_rec.pinfl, o_rec.inn, o_rec.birth_date, o_rec.birth_place, o_rec.gender,
               o_rec.phone, o_rec.email, o_rec.legal_address, o_rec.actual_address,
               o_rec.resident_flag, o_rec.country_code, o_rec.branch_code, o_rec.sector_code,
               o_rec.risk_category, o_rec.is_pep, o_rec.opening_purpose,
               o_rec.employer_name, o_rec.employer_position, o_rec.employer_address, o_rec.employer_phone,
               o_rec.other_bank_name, o_rec.other_bank_mfo, o_rec.other_bank_account,
               o_rec.status, o_rec.approved_by, o_rec.approved_at,
               o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_cif_customers
         WHERE pinfl = i_pinfl;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Pinfl;

    -- =======================================================================
    -- Find_By_Inn
    -- =======================================================================
    PROCEDURE Find_By_Inn(
        i_inn       IN  VARCHAR2,
        o_rec       OUT core_cif_types.t_customer_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT customer_id, cif_number, customer_type,
               first_name, last_name, middle_name,
               org_name, org_full_name, org_form, oked,
               reg_number, reg_date, reg_authority,
               director_name, director_position, accountant_name, director_pinfl,
               pinfl, inn, birth_date, birth_place, gender,
               phone, email, legal_address, actual_address,
               resident_flag, country_code, branch_code, sector_code,
               risk_category, is_pep, opening_purpose,
               employer_name, employer_position, employer_address, employer_phone,
               other_bank_name, other_bank_mfo, other_bank_account,
               status, approved_by, approved_at,
               created_by, created_at, updated_by, updated_at
          INTO o_rec.customer_id, o_rec.cif_number, o_rec.customer_type,
               o_rec.first_name, o_rec.last_name, o_rec.middle_name,
               o_rec.org_name, o_rec.org_full_name, o_rec.org_form, o_rec.oked,
               o_rec.reg_number, o_rec.reg_date, o_rec.reg_authority,
               o_rec.director_name, o_rec.director_position, o_rec.accountant_name, o_rec.director_pinfl,
               o_rec.pinfl, o_rec.inn, o_rec.birth_date, o_rec.birth_place, o_rec.gender,
               o_rec.phone, o_rec.email, o_rec.legal_address, o_rec.actual_address,
               o_rec.resident_flag, o_rec.country_code, o_rec.branch_code, o_rec.sector_code,
               o_rec.risk_category, o_rec.is_pep, o_rec.opening_purpose,
               o_rec.employer_name, o_rec.employer_position, o_rec.employer_address, o_rec.employer_phone,
               o_rec.other_bank_name, o_rec.other_bank_mfo, o_rec.other_bank_account,
               o_rec.status, o_rec.approved_by, o_rec.approved_at,
               o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_cif_customers
         WHERE inn = i_inn;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Inn;

    -- =======================================================================
    -- Search - Dinamik qidiruv
    -- S-1: statik SQL, bind variables bilan (SQL injection himoyasi)
    -- S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Search(
        i_name          IN  VARCHAR2 DEFAULT NULL,
        i_phone         IN  VARCHAR2 DEFAULT NULL,
        i_status        IN  VARCHAR2 DEFAULT NULL,
        i_customer_type IN  VARCHAR2 DEFAULT NULL,
        i_branch_code   IN  VARCHAR2 DEFAULT NULL,
        i_page          IN  NUMBER   DEFAULT 1,
        i_page_size     IN  NUMBER   DEFAULT 20,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
        v_name      VARCHAR2(200);
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        v_name   := UPPER('%' || i_name || '%');

        OPEN o_results FOR
            SELECT customer_id, cif_number, customer_type,
                   first_name, last_name, middle_name,
                   org_name, phone, status, branch_code,
                   risk_category, is_pep, created_at
              FROM core_cif_customers
             WHERE (i_name IS NULL
                    OR UPPER(last_name || ' ' || first_name) LIKE v_name
                    OR UPPER(org_name) LIKE v_name)
               AND (i_phone IS NULL OR phone LIKE '%' || i_phone || '%')
               AND (i_status IS NULL OR status = i_status)
               AND (i_customer_type IS NULL OR customer_type = i_customer_type)
               AND (i_branch_code IS NULL OR branch_code = i_branch_code)
             ORDER BY created_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Search;

    -- =======================================================================
    -- Find_All - Sahifalash bilan
    -- =======================================================================
    PROCEDURE Find_All(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT customer_id, cif_number, customer_type,
                   first_name, last_name, middle_name,
                   org_name, phone, status, branch_code,
                   risk_category, is_pep, created_at
              FROM core_cif_customers
             ORDER BY created_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_All;

    -- =======================================================================
    -- Find_Pending - PENDING holatdagilar (Maker-Checker)
    -- =======================================================================
    PROCEDURE Find_Pending(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT customer_id, cif_number, customer_type,
                   first_name, last_name, middle_name,
                   org_name, phone, status, branch_code,
                   risk_category, is_pep, created_by, created_at
              FROM core_cif_customers
             WHERE status = core_cif_const.c_status_pending
             ORDER BY created_at ASC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_Pending;

    -- =======================================================================
    -- Count_All - Jami mijozlar soni
    -- =======================================================================
    FUNCTION Count_All RETURN NUMBER IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count FROM core_cif_customers;
        RETURN v_count;
    END Count_All;

    -- =======================================================================
    -- Count_By_Status - Status bo'yicha soni
    -- =======================================================================
    FUNCTION Count_By_Status(
        i_status    IN VARCHAR2
    ) RETURN NUMBER IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count
          FROM core_cif_customers
         WHERE status = i_status;
        RETURN v_count;
    END Count_By_Status;

    -- =======================================================================
    -- Count_Search - Qidiruv natijalari soni (sahifalash uchun total)
    -- Search protsedurasi bilan bir xil WHERE sharti
    -- =======================================================================
    FUNCTION Count_Search(
        i_name          IN  VARCHAR2 DEFAULT NULL,
        i_phone         IN  VARCHAR2 DEFAULT NULL,
        i_status        IN  VARCHAR2 DEFAULT NULL,
        i_customer_type IN  VARCHAR2 DEFAULT NULL,
        i_branch_code   IN  VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_count     NUMBER;
        v_name      VARCHAR2(200);
    BEGIN
        v_name := UPPER('%' || i_name || '%');

        SELECT COUNT(1) INTO v_count
          FROM core_cif_customers
         WHERE (i_name IS NULL
                OR UPPER(last_name || ' ' || first_name) LIKE v_name
                OR UPPER(org_name) LIKE v_name)
           AND (i_phone IS NULL OR phone LIKE '%' || i_phone || '%')
           AND (i_status IS NULL OR status = i_status)
           AND (i_customer_type IS NULL OR customer_type = i_customer_type)
           AND (i_branch_code IS NULL OR branch_code = i_branch_code);

        RETURN v_count;
    END Count_Search;

END core_cif_data_reader;
/


-- *************************************************************************
-- 6. core_cif_repo - REPO qatlami (faqat DML: INSERT/UPDATE/DELETE)
--    MUHIM: SELECT yo'q! COMMIT/ROLLBACK yo'q! (E-5)
--    Type'lar core_cif_types paketida aniqlangan.
--    Naming: i_, o_, io_, v_ (N-1..N-5)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_repo AS

    -- INSERT + CIF generatsiya
    PROCEDURE Create_Customer(
        io_rec      IN OUT core_cif_types.t_customer_rec
    );

    -- UPDATE
    PROCEDURE Update_Customer(
        i_rec       IN core_cif_types.t_customer_rec
    );

    -- Status o'zgartirish (UPDATE faqat status)
    PROCEDURE Change_Status(
        i_id        IN NUMBER,
        i_status    IN VARCHAR2,
        i_user      IN VARCHAR2
    );

    -- PENDING -> ACTIVE (approve)
    PROCEDURE Approve(
        i_id            IN NUMBER,
        i_approved_by   IN VARCHAR2
    );

END core_cif_repo;
/

CREATE OR REPLACE PACKAGE BODY core_cif_repo AS

    -- =======================================================================
    -- Create_Customer - INSERT + CIF raqam generatsiya
    -- S-3: INSERT ustun ro'yxati bilan
    -- E-5: COMMIT yo'q (REPO qatlam)
    -- =======================================================================
    PROCEDURE Create_Customer(
        io_rec      IN OUT core_cif_types.t_customer_rec
    ) IS
    BEGIN
        -- CIF raqam generatsiya
        io_rec.cif_number := core_cif_util.Generate_Cif_Number;
        io_rec.status     := core_cif_const.c_status_pending;
        io_rec.created_at := SYSTIMESTAMP;

        INSERT INTO core_cif_customers (
            cif_number, customer_type,
            first_name, last_name, middle_name,
            org_name, org_full_name, org_form, oked,
            reg_number, reg_date, reg_authority,
            director_name, director_position, accountant_name, director_pinfl,
            pinfl, inn, birth_date, birth_place, gender,
            phone, email, legal_address, actual_address,
            resident_flag, country_code, branch_code, sector_code,
            risk_category, is_pep, opening_purpose,
            employer_name, employer_position, employer_address, employer_phone,
            other_bank_name, other_bank_mfo, other_bank_account,
            status, created_by, created_at
        ) VALUES (
            io_rec.cif_number, io_rec.customer_type,
            io_rec.first_name, io_rec.last_name, io_rec.middle_name,
            io_rec.org_name, io_rec.org_full_name, io_rec.org_form, io_rec.oked,
            io_rec.reg_number, io_rec.reg_date, io_rec.reg_authority,
            io_rec.director_name, io_rec.director_position, io_rec.accountant_name, io_rec.director_pinfl,
            io_rec.pinfl, io_rec.inn, io_rec.birth_date, io_rec.birth_place, io_rec.gender,
            io_rec.phone, io_rec.email, io_rec.legal_address, io_rec.actual_address,
            io_rec.resident_flag, io_rec.country_code, io_rec.branch_code, io_rec.sector_code,
            io_rec.risk_category, io_rec.is_pep, io_rec.opening_purpose,
            io_rec.employer_name, io_rec.employer_position, io_rec.employer_address, io_rec.employer_phone,
            io_rec.other_bank_name, io_rec.other_bank_mfo, io_rec.other_bank_account,
            io_rec.status, io_rec.created_by, io_rec.created_at
        ) RETURNING customer_id INTO io_rec.customer_id;
    END Create_Customer;

    -- =======================================================================
    -- Update_Customer
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Update_Customer(
        i_rec       IN core_cif_types.t_customer_rec
    ) IS
    BEGIN
        UPDATE core_cif_customers
           SET first_name       = i_rec.first_name,
               last_name        = i_rec.last_name,
               middle_name      = i_rec.middle_name,
               org_name         = i_rec.org_name,
               org_full_name    = i_rec.org_full_name,
               org_form         = i_rec.org_form,
               oked             = i_rec.oked,
               reg_number       = i_rec.reg_number,
               reg_date         = i_rec.reg_date,
               reg_authority    = i_rec.reg_authority,
               director_name    = i_rec.director_name,
               director_position = i_rec.director_position,
               accountant_name  = i_rec.accountant_name,
               director_pinfl   = i_rec.director_pinfl,
               pinfl            = i_rec.pinfl,
               inn              = i_rec.inn,
               birth_date       = i_rec.birth_date,
               birth_place      = i_rec.birth_place,
               gender           = i_rec.gender,
               phone            = i_rec.phone,
               email            = i_rec.email,
               legal_address    = i_rec.legal_address,
               actual_address   = i_rec.actual_address,
               resident_flag    = i_rec.resident_flag,
               country_code     = i_rec.country_code,
               branch_code      = i_rec.branch_code,
               sector_code      = i_rec.sector_code,
               risk_category    = i_rec.risk_category,
               is_pep           = i_rec.is_pep,
               opening_purpose  = i_rec.opening_purpose,
               employer_name    = i_rec.employer_name,
               employer_position = i_rec.employer_position,
               employer_address = i_rec.employer_address,
               employer_phone   = i_rec.employer_phone,
               other_bank_name  = i_rec.other_bank_name,
               other_bank_mfo   = i_rec.other_bank_mfo,
               other_bank_account = i_rec.other_bank_account,
               updated_by       = i_rec.updated_by,
               updated_at       = SYSTIMESTAMP
         WHERE customer_id = i_rec.customer_id;
    END Update_Customer;

    -- =======================================================================
    -- Change_Status
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Change_Status(
        i_id        IN NUMBER,
        i_status    IN VARCHAR2,
        i_user      IN VARCHAR2
    ) IS
    BEGIN
        UPDATE core_cif_customers
           SET status     = i_status,
               updated_by = i_user,
               updated_at = SYSTIMESTAMP
         WHERE customer_id = i_id;
    END Change_Status;

    -- =======================================================================
    -- Approve - PENDING -> ACTIVE
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Approve(
        i_id            IN NUMBER,
        i_approved_by   IN VARCHAR2
    ) IS
    BEGIN
        UPDATE core_cif_customers
           SET status       = core_cif_const.c_status_active,
               approved_by  = i_approved_by,
               approved_at  = SYSTIMESTAMP,
               updated_by   = i_approved_by,
               updated_at   = SYSTIMESTAMP
         WHERE customer_id  = i_id
           AND status       = core_cif_const.c_status_pending;
    END Approve;

END core_cif_repo;
/


-- *************************************************************************
-- 7. core_cif_rules - RULES qatlami (validatsiya)
--    DML YO'Q! (L-1)
--    Dublikat tekshiruvlar core_cif_data_reader orqali (SELECT).
--    Type'lar core_cif_types paketida aniqlangan.
--    o_code/o_message qaytarish (SC-1, SC-2)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_rules AS

    -- Yaratish uchun validatsiya
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    -- Yangilash uchun validatsiya
    PROCEDURE Validate_Update(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    -- Holat o'zgartirish validatsiyasi
    PROCEDURE Validate_Status_Change(
        i_current_status    IN VARCHAR2,
        i_new_status        IN VARCHAR2,
        o_code              OUT NUMBER,
        o_message           OUT VARCHAR2
    );

    -- Maker != Checker tekshiruvi
    PROCEDURE Validate_Approval(
        i_created_by    IN VARCHAR2,
        i_approved_by   IN VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    );

    -- FYaSh specific validatsiya
    PROCEDURE Validate_Individual(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    -- YuSh specific validatsiya
    PROCEDURE Validate_Corporate(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

END core_cif_rules;
/

CREATE OR REPLACE PACKAGE BODY core_cif_rules AS

    -- =======================================================================
    -- Validate_Create
    -- DML YO'Q (L-1)
    -- SC-2: OUT parametrlarni boshida init
    -- Dublikat tekshiruv: core_cif_data_reader orqali (REPO emas!)
    -- =======================================================================
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        -- SC-2: MAJBURIY init
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- Umumiy majburiy maydonlar
        -- E-4: IS NULL ishlatish
        IF i_rec.customer_type IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': customer_type';
            RETURN;
        END IF;

        IF i_rec.phone IS NULL THEN
            o_code    := core_cif_const.c_err_invalid_phone;
            o_message := core_cif_const.c_msg_invalid_phone;
            RETURN;
        END IF;

        IF i_rec.resident_flag IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': resident_flag';
            RETURN;
        END IF;

        IF i_rec.country_code IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': country_code';
            RETURN;
        END IF;

        IF i_rec.branch_code IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': branch_code';
            RETURN;
        END IF;

        IF i_rec.sector_code IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': sector_code';
            RETURN;
        END IF;

        IF i_rec.risk_category IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': risk_category';
            RETURN;
        END IF;

        -- Tur bo'yicha validatsiya
        IF i_rec.customer_type = core_cif_const.c_type_individual THEN
            Validate_Individual(i_rec, o_code, o_message);
            IF o_code != core_cif_const.c_code_ok THEN
                RETURN;
            END IF;
        ELSIF i_rec.customer_type = core_cif_const.c_type_corporate THEN
            Validate_Corporate(i_rec, o_code, o_message);
            IF o_code != core_cif_const.c_code_ok THEN
                RETURN;
            END IF;
        END IF;

        -- PINFL dublikat tekshiruv (FYaSh uchun)
        -- DATA_READER orqali SELECT (REPO emas!)
        IF i_rec.pinfl IS NOT NULL THEN
            core_cif_data_reader.Find_By_Pinfl(i_rec.pinfl, v_existing, v_found);
            IF v_found THEN
                o_code    := core_cif_const.c_err_duplicate_pinfl;
                o_message := core_cif_const.c_msg_duplicate_pinfl;
                RETURN;
            END IF;
        END IF;

        -- INN dublikat tekshiruv (YuSh uchun)
        -- DATA_READER orqali SELECT (REPO emas!)
        IF i_rec.inn IS NOT NULL THEN
            core_cif_data_reader.Find_By_Inn(i_rec.inn, v_existing, v_found);
            IF v_found THEN
                o_code    := core_cif_const.c_err_duplicate_inn;
                o_message := core_cif_const.c_msg_duplicate_inn;
                RETURN;
            END IF;
        END IF;
    END Validate_Create;

    -- =======================================================================
    -- Validate_Update
    -- Dublikat tekshiruv: core_cif_data_reader orqali (REPO emas!)
    -- =======================================================================
    PROCEDURE Validate_Update(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- Mijoz mavjudligini tekshirish
        IF i_rec.customer_id IS NULL THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- Tur bo'yicha validatsiya
        IF i_rec.customer_type = core_cif_const.c_type_individual THEN
            Validate_Individual(i_rec, o_code, o_message);
            IF o_code != core_cif_const.c_code_ok THEN
                RETURN;
            END IF;
        ELSIF i_rec.customer_type = core_cif_const.c_type_corporate THEN
            Validate_Corporate(i_rec, o_code, o_message);
            IF o_code != core_cif_const.c_code_ok THEN
                RETURN;
            END IF;
        END IF;

        -- PINFL dublikat tekshiruv (boshqa mijozda)
        -- DATA_READER orqali SELECT
        IF i_rec.pinfl IS NOT NULL THEN
            core_cif_data_reader.Find_By_Pinfl(i_rec.pinfl, v_existing, v_found);
            IF v_found AND v_existing.customer_id != i_rec.customer_id THEN
                o_code    := core_cif_const.c_err_duplicate_pinfl;
                o_message := core_cif_const.c_msg_duplicate_pinfl;
                RETURN;
            END IF;
        END IF;

        -- INN dublikat tekshiruv (boshqa mijozda)
        -- DATA_READER orqali SELECT
        IF i_rec.inn IS NOT NULL THEN
            core_cif_data_reader.Find_By_Inn(i_rec.inn, v_existing, v_found);
            IF v_found AND v_existing.customer_id != i_rec.customer_id THEN
                o_code    := core_cif_const.c_err_duplicate_inn;
                o_message := core_cif_const.c_msg_duplicate_inn;
                RETURN;
            END IF;
        END IF;
    END Validate_Update;

    -- =======================================================================
    -- Validate_Status_Change
    -- Ruxsat etilgan o'tishlar:
    --   PENDING  -> ACTIVE  (approve)
    --   PENDING  -> REJECTED (reject)
    --   ACTIVE   -> BLOCKED
    --   BLOCKED  -> ACTIVE
    --   ACTIVE   -> CLOSED
    --   BLOCKED  -> CLOSED
    -- =======================================================================
    PROCEDURE Validate_Status_Change(
        i_current_status    IN VARCHAR2,
        i_new_status        IN VARCHAR2,
        o_code              OUT NUMBER,
        o_message           OUT VARCHAR2
    ) IS
        v_valid     BOOLEAN := FALSE;
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        IF i_current_status = core_cif_const.c_status_pending
           AND i_new_status IN (core_cif_const.c_status_active,
                                core_cif_const.c_status_rejected) THEN
            v_valid := TRUE;
        ELSIF i_current_status = core_cif_const.c_status_active
              AND i_new_status IN (core_cif_const.c_status_blocked,
                                   core_cif_const.c_status_closed) THEN
            v_valid := TRUE;
        ELSIF i_current_status = core_cif_const.c_status_blocked
              AND i_new_status IN (core_cif_const.c_status_active,
                                   core_cif_const.c_status_closed) THEN
            v_valid := TRUE;
        END IF;

        IF NOT v_valid THEN
            o_code    := core_cif_const.c_err_invalid_status_change;
            o_message := core_cif_const.c_msg_invalid_status_change
                || ': ' || i_current_status || ' -> ' || i_new_status;
        END IF;
    END Validate_Status_Change;

    -- =======================================================================
    -- Validate_Approval - Maker != Checker
    -- =======================================================================
    PROCEDURE Validate_Approval(
        i_created_by    IN VARCHAR2,
        i_approved_by   IN VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        IF UPPER(i_created_by) = UPPER(i_approved_by) THEN
            o_code    := core_cif_const.c_err_maker_equals_checker;
            o_message := core_cif_const.c_msg_maker_equals_checker;
        END IF;
    END Validate_Approval;

    -- =======================================================================
    -- Validate_Individual - FYaSh validatsiya
    -- Yosh >= 18, PINFL format, majburiy maydonlar
    -- =======================================================================
    PROCEDURE Validate_Individual(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
        v_age       NUMBER;
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- Ism majburiy
        IF i_rec.first_name IS NULL OR LENGTH(TRIM(i_rec.first_name)) < 2 THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': first_name (kamida 2 belgi)';
            RETURN;
        END IF;

        -- Familiya majburiy
        IF i_rec.last_name IS NULL OR LENGTH(TRIM(i_rec.last_name)) < 2 THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': last_name (kamida 2 belgi)';
            RETURN;
        END IF;

        -- PINFL majburiy va format tekshiruvi
        IF i_rec.pinfl IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': pinfl';
            RETURN;
        END IF;

        IF NOT core_cif_util.Is_Valid_Pinfl(i_rec.pinfl) THEN
            o_code    := core_cif_const.c_err_invalid_pinfl;
            o_message := core_cif_const.c_msg_invalid_pinfl;
            RETURN;
        END IF;

        -- Tug'ilgan sana majburiy
        IF i_rec.birth_date IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': birth_date';
            RETURN;
        END IF;

        -- Yosh >= 18
        v_age := core_cif_util.Calculate_Age(i_rec.birth_date);
        IF v_age < 18 THEN
            o_code    := core_cif_const.c_err_underage;
            o_message := core_cif_const.c_msg_underage || ' (yosh: ' || TO_CHAR(v_age) || ')';
            RETURN;
        END IF;

        -- Tug'ilgan joyi majburiy
        IF i_rec.birth_place IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': birth_place';
            RETURN;
        END IF;
    END Validate_Individual;

    -- =======================================================================
    -- Validate_Corporate - YuSh validatsiya
    -- INN format, majburiy maydonlar
    -- =======================================================================
    PROCEDURE Validate_Corporate(
        i_rec       IN  core_cif_types.t_customer_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- Tashkilot nomi majburiy
        IF i_rec.org_name IS NULL OR LENGTH(TRIM(i_rec.org_name)) < 3 THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': org_name (kamida 3 belgi)';
            RETURN;
        END IF;

        -- INN majburiy va format tekshiruvi
        IF i_rec.inn IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': inn';
            RETURN;
        END IF;

        IF NOT core_cif_util.Is_Valid_Inn(i_rec.inn) THEN
            o_code    := core_cif_const.c_err_invalid_inn;
            o_message := core_cif_const.c_msg_invalid_inn;
            RETURN;
        END IF;

        -- Tashkiliy shakl majburiy
        IF i_rec.org_form IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': org_form';
            RETURN;
        END IF;

        -- OKED majburiy
        IF i_rec.oked IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': oked';
            RETURN;
        END IF;

        -- Ro'yxatga olish ma'lumotlari
        IF i_rec.reg_number IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': reg_number';
            RETURN;
        END IF;

        IF i_rec.reg_date IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': reg_date';
            RETURN;
        END IF;

        IF i_rec.reg_authority IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': reg_authority';
            RETURN;
        END IF;

        -- Rahbar majburiy
        IF i_rec.director_name IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': director_name';
            RETURN;
        END IF;

        -- Rahbar PINFL majburiy va format tekshiruvi
        IF i_rec.director_pinfl IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': director_pinfl';
            RETURN;
        END IF;

        IF NOT core_cif_util.Is_Valid_Pinfl(i_rec.director_pinfl) THEN
            o_code    := core_cif_const.c_err_invalid_pinfl;
            o_message := 'Rahbar PINFL formati noto''g''ri (14 xonali raqam bo''lishi kerak)';
            RETURN;
        END IF;

        -- Bosh hisobchi majburiy
        IF i_rec.accountant_name IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': accountant_name';
            RETURN;
        END IF;

        -- Yuridik manzil majburiy
        IF i_rec.legal_address IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': legal_address';
            RETURN;
        END IF;
    END Validate_Corporate;

END core_cif_rules;
/


-- *************************************************************************
-- 8. core_cif_service - SERVICE qatlami (biznes logika)
--    COMMIT/ROLLBACK faqat shu qatlamda! (E-5)
--    SC-1: o_code/o_message/o_ora_message
--    SC-2: OUT parametrlar boshida init
--    E-2: WHEN OTHERS THEN — ROLLBACK + o_code set (NULL emas!)
--    Type'lar core_cif_types paketida aniqlangan.
--
--    Qatlamlar ishlatish tartibi:
--      DATA_READER  — o'qish (Find_By_Id va h.k.)
--      RULES        — validatsiya
--      REPO         — DML (Create, Update, Change_Status, Approve)
--      LOGGER       — audit log (Log_Audit)
--      COMMIT/ROLLBACK
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_cif_service AS

    -- Yangi mijoz yaratish
    -- BC-1: barcha parametrlar DEFAULT bilan (backward compatibility)
    PROCEDURE Create_Customer(
        io_rec          IN OUT core_cif_types.t_customer_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Mijoz yangilash
    PROCEDURE Update_Customer(
        i_rec           IN  core_cif_types.t_customer_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Holat o'zgartirish
    PROCEDURE Change_Status(
        i_customer_id   IN  NUMBER,
        i_new_status    IN  VARCHAR2,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Tasdiqlash (Maker-Checker: PENDING -> ACTIVE)
    PROCEDURE Approve_Customer(
        i_customer_id   IN  NUMBER,
        i_approved_by   IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Rad etish (PENDING -> REJECTED)
    PROCEDURE Reject_Customer(
        i_customer_id   IN  NUMBER,
        i_rejected_by   IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

END core_cif_service;
/

CREATE OR REPLACE PACKAGE BODY core_cif_service AS

    -- =======================================================================
    -- Create_Customer
    -- Flow: PEP->HIGH | Format_Phone | RULES.Validate -> REPO.Create
    --       -> LOGGER.Log_Audit -> COMMIT
    -- SC-1: o_code/o_message/o_ora_message
    -- SC-2: boshida init
    -- E-2: WHEN OTHERS — ROLLBACK + o_code (NULL emas!)
    -- E-5: COMMIT faqat shu qatlamda
    -- =======================================================================
    PROCEDURE Create_Customer(
        io_rec          IN OUT core_cif_types.t_customer_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
    BEGIN
        -- SC-2: MAJBURIY init
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- PEP -> HIGH risk
        IF io_rec.is_pep = 'Y' THEN
            io_rec.risk_category := core_cif_const.c_risk_high;
        END IF;

        -- Telefon formatlash
        io_rec.phone := core_cif_util.Format_Phone(io_rec.phone);

        -- 1. RULES: Validatsiya
        core_cif_rules.Validate_Create(io_rec, o_code, o_message);
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: INSERT
        core_cif_repo.Create_Customer(io_rec);

        -- 3. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => io_rec.customer_id,
            i_action_type   => 'CREATE',
            i_field_name    => NULL,
            i_old_value     => NULL,
            i_new_value     => 'Yangi mijoz: ' || io_rec.cif_number,
            i_changed_by    => io_rec.created_by
        );

        -- E-5: COMMIT faqat SERVICE'da
        COMMIT;

        o_message := 'Mijoz muvaffaqiyatli yaratildi: ' || io_rec.cif_number;

    EXCEPTION
        -- E-2: WHEN OTHERS — ROLLBACK + o_code (NULL emas!)
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Mijoz yaratishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Create_Customer;

    -- =======================================================================
    -- Update_Customer
    -- Flow: DATA_READER.Find_By_Id -> RULES.Validate -> REPO.Update
    --       -> LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Update_Customer(
        i_rec           IN  core_cif_types.t_customer_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- DATA_READER: Mavjudligini tekshirish
        core_cif_data_reader.Find_By_Id(i_rec.customer_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- 1. RULES: Validatsiya
        core_cif_rules.Validate_Update(i_rec, o_code, o_message);
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: UPDATE
        core_cif_repo.Update_Customer(i_rec);

        -- 3. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => i_rec.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => NULL,
            i_old_value     => NULL,
            i_new_value     => 'Mijoz yangilandi',
            i_changed_by    => NVL(i_rec.updated_by, i_rec.created_by)
        );

        COMMIT;

        o_message := 'Mijoz muvaffaqiyatli yangilandi';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Mijoz yangilashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Update_Customer;

    -- =======================================================================
    -- Change_Status
    -- Flow: DATA_READER.Find_By_Id -> RULES.Validate_Status_Change
    --       -> REPO.Change_Status -> LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Change_Status(
        i_customer_id   IN  NUMBER,
        i_new_status    IN  VARCHAR2,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- DATA_READER: Mavjudligini tekshirish
        core_cif_data_reader.Find_By_Id(i_customer_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- 1. RULES: Status o'zgartirish validatsiyasi
        core_cif_rules.Validate_Status_Change(
            v_existing.status, i_new_status, o_code, o_message
        );
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: Status o'zgartirish
        core_cif_repo.Change_Status(i_customer_id, i_new_status, i_user);

        -- 3. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => i_customer_id,
            i_action_type   => 'STATUS_CHANGE',
            i_field_name    => 'status',
            i_old_value     => v_existing.status,
            i_new_value     => i_new_status,
            i_changed_by    => i_user
        );

        COMMIT;

        o_message := 'Holat o''zgartirildi: '
            || v_existing.status || ' -> ' || i_new_status;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Holat o''zgartirishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Change_Status;

    -- =======================================================================
    -- Approve_Customer - Maker-Checker: PENDING -> ACTIVE
    -- Flow: DATA_READER.Find_By_Id -> check PENDING
    --       -> RULES.Validate_Approval -> REPO.Approve
    --       -> LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Approve_Customer(
        i_customer_id   IN  NUMBER,
        i_approved_by   IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- DATA_READER: Mavjudligini tekshirish
        core_cif_data_reader.Find_By_Id(i_customer_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- PENDING holatda bo'lishi kerak
        IF v_existing.status != core_cif_const.c_status_pending THEN
            o_code    := core_cif_const.c_err_not_pending;
            o_message := core_cif_const.c_msg_not_pending;
            RETURN;
        END IF;

        -- 1. RULES: Maker != Checker
        core_cif_rules.Validate_Approval(
            v_existing.created_by, i_approved_by, o_code, o_message
        );
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: Approve
        core_cif_repo.Approve(i_customer_id, i_approved_by);

        -- 3. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => i_customer_id,
            i_action_type   => 'APPROVE',
            i_field_name    => 'status',
            i_old_value     => core_cif_const.c_status_pending,
            i_new_value     => core_cif_const.c_status_active,
            i_changed_by    => i_approved_by
        );

        COMMIT;

        o_message := 'Mijoz tasdiqlandi: '
            || v_existing.cif_number;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Tasdiqlashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Approve_Customer;

    -- =======================================================================
    -- Reject_Customer - PENDING -> REJECTED
    -- Flow: DATA_READER.Find_By_Id -> check PENDING
    --       -> REPO.Change_Status(REJECTED) -> LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Reject_Customer(
        i_customer_id   IN  NUMBER,
        i_rejected_by   IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_cif_types.t_customer_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- DATA_READER: Mavjudligini tekshirish
        core_cif_data_reader.Find_By_Id(i_customer_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- PENDING holatda bo'lishi kerak
        IF v_existing.status != core_cif_const.c_status_pending THEN
            o_code    := core_cif_const.c_err_not_pending;
            o_message := core_cif_const.c_msg_not_pending;
            RETURN;
        END IF;

        -- 1. REPO: Status -> REJECTED
        core_cif_repo.Change_Status(
            i_customer_id,
            core_cif_const.c_status_rejected,
            i_rejected_by
        );

        -- 2. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => i_customer_id,
            i_action_type   => 'REJECT',
            i_field_name    => 'status',
            i_old_value     => core_cif_const.c_status_pending,
            i_new_value     => core_cif_const.c_status_rejected
                || CASE WHEN i_reason IS NOT NULL
                        THEN ' (' || i_reason || ')'
                   END,
            i_changed_by    => i_rejected_by
        );

        COMMIT;

        o_message := 'Mijoz rad etildi: ' || v_existing.cif_number;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Rad etishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Reject_Customer;

END core_cif_service;
/

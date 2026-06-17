-- ============================================================================
-- MARS ABS - core_cif moduli
-- 08_cif_doc_contact_packages.sql - Hujjatlar, Kontaktlar paketlari
-- Sana: 2026-05-26
--
-- SIRIUS qatlamlar (L-1):
--   CONST       -> konstantalar (core_cif_const — 05 da yaratilgan)
--   TYPES       -> record type'lar (core_cif_types — 05 da yaratilgan)
--   UTIL        -> yordamchi funksiyalar (core_cif_util — qayta ta'riflanadi)
--   DATA_READER -> faqat SELECT so'rovlar — type'lar TYPES'da
--   REPO        -> faqat DML (INSERT/UPDATE/DELETE), COMMIT yo'q!
--   RULES       -> validatsiya (DML yo'q!)
--   SERVICE     -> biznes logika (COMMIT/ROLLBACK faqat shu yerda)
--   LOGGER      -> audit log yozish va o'qish (core_cif_logger — 05 da yaratilgan)
--
-- Naming (N-1..N-6):
--   i_ = IN, o_ = OUT, io_ = IN OUT
--   v_ = local variable, cr_ = cursor, c_ = constant
--   e_ = exception, t_ = type
--
-- Paketlar:
--   1.  core_cif_util                — kengaytirilgan (Is_Valid_Phone, Is_Valid_Email)
--   2.  core_cif_doc_types           — Hujjatlar TYPES (spec only)
--   3.  core_cif_doc_data_reader     — Hujjatlar SELECT (DATA_READER qatlam)
--   4.  core_cif_doc_repo            — Hujjatlar DML (REPO qatlam)
--   5.  core_cif_doc_rules           — Hujjatlar validatsiya (RULES qatlam)
--   6.  core_cif_doc_service         — Hujjatlar biznes logika (SERVICE qatlam)
--   7.  core_cif_contact_types       — Kontaktlar TYPES (spec only)
--   8.  core_cif_contact_data_reader — Kontaktlar SELECT (DATA_READER qatlam)
--   9.  core_cif_contact_repo        — Kontaktlar DML (REPO qatlam)
--   10. core_cif_contact_rules       — Kontaktlar validatsiya (RULES qatlam)
--   11. core_cif_contact_service     — Kontaktlar biznes logika (SERVICE qatlam)
--
-- MUHIM: core_cif_audit_repo bu faylda YO'Q — audit log funksionalligi
--        core_cif_logger (05_cif_packages.sql) ga ko'chirilgan
-- ============================================================================


-- **************************************************************************
-- 1. core_cif_util - UTIL qatlami (kengaytirilgan)
--    CREATE OR REPLACE — 05_cif_packages dagi mavjud funksiyalar + yangilari
--    Bu 08 fayl 05 dan keyin ishlaydi, shuning uchun xavfsiz
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_util AS

    -- ---- Mavjud funksiyalar (05 dan ko'chirilgan) ----
    FUNCTION Generate_Cif_Number RETURN VARCHAR2;

    FUNCTION Format_Phone(
        i_phone     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION Is_Valid_Pinfl(
        i_pinfl     IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION Is_Valid_Inn(
        i_inn       IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION Calculate_Age(
        i_birth_date IN DATE
    ) RETURN NUMBER;

    -- ---- Yangi funksiyalar ----

    -- Telefon raqam validatsiyasi (+998XXXXXXXXX format)
    FUNCTION Is_Valid_Phone(
        i_phone     IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Email validatsiyasi (asosiy format tekshiruv)
    FUNCTION Is_Valid_Email(
        i_email     IN VARCHAR2
    ) RETURN BOOLEAN;

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

    -- =======================================================================
    -- Is_Valid_Phone - Telefon raqam validatsiyasi
    -- Format: +998XXXXXXXXX (12 raqam + prefix)
    -- =======================================================================
    FUNCTION Is_Valid_Phone(
        i_phone     IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        -- E-4: IS NULL ishlatish
        IF i_phone IS NULL THEN
            RETURN FALSE;
        END IF;
        -- +998 dan boshlanib, 9 ta raqam (jami +998XXXXXXXXX = 13 belgi)
        IF REGEXP_LIKE(i_phone, '^\+998\d{9}$') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END Is_Valid_Phone;

    -- =======================================================================
    -- Is_Valid_Email - Email validatsiyasi
    -- Asosiy format: xxx@xxx.xxx
    -- =======================================================================
    FUNCTION Is_Valid_Email(
        i_email     IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_email IS NULL THEN
            RETURN FALSE;
        END IF;
        -- Asosiy email format tekshiruvi
        IF REGEXP_LIKE(i_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END Is_Valid_Email;

END core_cif_util;
/


-- **************************************************************************
-- 2. core_cif_doc_types - TYPES qatlami (Hujjatlar record type'lar)
--    CONST darajasida — body yo'q, faqat spec.
--    Barcha qatlamlar (DOC_DATA_READER, DOC_REPO, DOC_RULES, DOC_SERVICE)
--    shu type'larga murojaat qiladi: core_cif_doc_types.t_document_rec
--
--    SIRIUS qoidasi: DATA_READER faqat SELECT o'z ichiga olishi kerak.
--    Type'lar alohida TYPES paketida bo'lishi shart.
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_doc_types AS
    -- Record type'lar — hujjat qatlamlari tomonidan ishlatiladi

    TYPE t_document_rec IS RECORD (
        doc_id              core_cif_documents.doc_id%TYPE,
        customer_id         core_cif_documents.customer_id%TYPE,
        doc_type            core_cif_documents.doc_type%TYPE,
        doc_series          core_cif_documents.doc_series%TYPE,
        doc_number          core_cif_documents.doc_number%TYPE,
        issued_by           core_cif_documents.issued_by%TYPE,
        issued_date         core_cif_documents.issued_date%TYPE,
        expiry_date         core_cif_documents.expiry_date%TYPE,
        is_primary          core_cif_documents.is_primary%TYPE,
        created_at          core_cif_documents.created_at%TYPE,
        created_by          core_cif_documents.created_by%TYPE
    );

    TYPE t_document_tab IS TABLE OF t_document_rec;
END core_cif_doc_types;
/


-- **************************************************************************
-- 3. core_cif_doc_data_reader - DATA_READER qatlami (Hujjatlar SELECT)
--    Faqat SELECT so'rovlar! DML YO'Q! (L-1)
--    Type'lar core_cif_doc_types paketiga ko'chirilgan (SIRIUS L-1 qoidasi).
--    Naming: i_, o_, io_, v_, cr_, t_ (N-1..N-6)
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_doc_data_reader AS

    -- Xato kodlari (E-7: -20020..-20030 oraligi)
    c_err_doc_not_found         CONSTANT NUMBER       := -20020;
    c_msg_doc_not_found         CONSTANT VARCHAR2(200) := 'Hujjat topilmadi';
    c_err_doc_type_invalid      CONSTANT NUMBER       := -20021;
    c_msg_doc_type_invalid      CONSTANT VARCHAR2(200) := 'Hujjat turi noto''g''ri';
    c_err_doc_expired           CONSTANT NUMBER       := -20022;
    c_msg_doc_expired           CONSTANT VARCHAR2(200) := 'Hujjat muddati tugagan';

    -- SELECT by ID
    -- S-2: SELECT * yo'q, aniq ustunlar
    PROCEDURE Find_By_Id(
        i_doc_id    IN  NUMBER,
        o_rec       OUT core_cif_doc_types.t_document_rec,
        o_found     OUT BOOLEAN
    );

    -- SELECT by customer_id (barcha hujjatlar)
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        o_results       OUT SYS_REFCURSOR
    );

    -- Jami soni (customer_id bo'yicha)
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER;

    -- Asosiy hujjat bormi?
    FUNCTION Has_Primary(
        i_customer_id   IN NUMBER
    ) RETURN BOOLEAN;

END core_cif_doc_data_reader;
/

CREATE OR REPLACE PACKAGE BODY core_cif_doc_data_reader AS

    -- =======================================================================
    -- Find_By_Id - S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Id(
        i_doc_id    IN  NUMBER,
        o_rec       OUT core_cif_doc_types.t_document_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT doc_id, customer_id, doc_type, doc_series, doc_number,
               issued_by, issued_date, expiry_date,
               is_primary, created_at, created_by
          INTO o_rec.doc_id, o_rec.customer_id, o_rec.doc_type,
               o_rec.doc_series, o_rec.doc_number,
               o_rec.issued_by, o_rec.issued_date, o_rec.expiry_date,
               o_rec.is_primary, o_rec.created_at, o_rec.created_by
          FROM core_cif_documents
         WHERE doc_id = i_doc_id;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Id;

    -- =======================================================================
    -- Find_By_Customer - Mijozning barcha hujjatlari
    -- S-2: aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        o_results       OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN o_results FOR
            SELECT doc_id, customer_id, doc_type, doc_series, doc_number,
                   issued_by, issued_date, expiry_date,
                   is_primary, created_at, created_by
              FROM core_cif_documents
             WHERE customer_id = i_customer_id
             ORDER BY is_primary DESC, created_at DESC;
    END Find_By_Customer;

    -- =======================================================================
    -- Count_By_Customer
    -- =======================================================================
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO v_count
          FROM core_cif_documents
         WHERE customer_id = i_customer_id;
        RETURN v_count;
    END Count_By_Customer;

    -- =======================================================================
    -- Has_Primary - Asosiy hujjat bormi?
    -- =======================================================================
    FUNCTION Has_Primary(
        i_customer_id   IN NUMBER
    ) RETURN BOOLEAN IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO v_count
          FROM core_cif_documents
         WHERE customer_id = i_customer_id
           AND is_primary = 'Y';
        RETURN (v_count > 0);
    END Has_Primary;

END core_cif_doc_data_reader;
/


-- **************************************************************************
-- 3. core_cif_doc_repo - REPO qatlami (Hujjatlar DML)
--    Faqat DML (INSERT/UPDATE/DELETE)! SELECT yo'q!
--    MUHIM: COMMIT/ROLLBACK yo'q! (E-5)
--    Type'lar core_cif_doc_data_reader dan olinadi
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_doc_repo AS

    -- INSERT + doc_id qaytarish
    -- S-3: INSERT ustun ro'yxati bilan
    PROCEDURE Create_Document(
        io_rec      IN OUT core_cif_doc_types.t_document_rec
    );

    -- UPDATE (issued_by, issued_date, expiry_date, doc_series, doc_number, is_primary)
    PROCEDURE Update_Document(
        i_rec       IN core_cif_doc_types.t_document_rec
    );

    -- DELETE
    PROCEDURE Delete_Document(
        i_doc_id    IN NUMBER
    );

END core_cif_doc_repo;
/

CREATE OR REPLACE PACKAGE BODY core_cif_doc_repo AS

    -- =======================================================================
    -- Create_Document - INSERT + doc_id qaytarish
    -- S-3: INSERT ustun ro'yxati bilan
    -- E-5: COMMIT yo'q (REPO qatlam)
    -- =======================================================================
    PROCEDURE Create_Document(
        io_rec      IN OUT core_cif_doc_types.t_document_rec
    ) IS
    BEGIN
        io_rec.created_at := SYSTIMESTAMP;

        INSERT INTO core_cif_documents (
            customer_id, doc_type, doc_series, doc_number,
            issued_by, issued_date, expiry_date,
            is_primary, created_at, created_by
        ) VALUES (
            io_rec.customer_id, io_rec.doc_type, io_rec.doc_series, io_rec.doc_number,
            io_rec.issued_by, io_rec.issued_date, io_rec.expiry_date,
            NVL(io_rec.is_primary, 'N'), io_rec.created_at, io_rec.created_by
        ) RETURNING doc_id INTO io_rec.doc_id;
    END Create_Document;

    -- =======================================================================
    -- Update_Document
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Update_Document(
        i_rec       IN core_cif_doc_types.t_document_rec
    ) IS
    BEGIN
        UPDATE core_cif_documents
           SET doc_type     = i_rec.doc_type,
               doc_series   = i_rec.doc_series,
               doc_number   = i_rec.doc_number,
               issued_by    = i_rec.issued_by,
               issued_date  = i_rec.issued_date,
               expiry_date  = i_rec.expiry_date,
               is_primary   = i_rec.is_primary
         WHERE doc_id = i_rec.doc_id;
    END Update_Document;

    -- =======================================================================
    -- Delete_Document
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Delete_Document(
        i_doc_id    IN NUMBER
    ) IS
    BEGIN
        DELETE FROM core_cif_documents
         WHERE doc_id = i_doc_id;
    END Delete_Document;

END core_cif_doc_repo;
/


-- **************************************************************************
-- 4. core_cif_doc_rules - RULES qatlami (Hujjatlar validatsiya)
--    DML YO'Q! (L-1)
--    o_code/o_message qaytarish (SC-1, SC-2)
--    Type'lar core_cif_doc_data_reader dan olinadi
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_doc_rules AS

    -- Yaratish uchun validatsiya
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_doc_types.t_document_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    -- Muddat tekshiruvi (ogohlantirish)
    PROCEDURE Validate_Expiry(
        i_expiry_date   IN  DATE,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    );

END core_cif_doc_rules;
/

CREATE OR REPLACE PACKAGE BODY core_cif_doc_rules AS

    -- =======================================================================
    -- Validate_Create
    -- DML YO'Q (L-1)
    -- SC-2: OUT parametrlarni boshida init
    -- =======================================================================
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_doc_types.t_document_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
    BEGIN
        -- SC-2: MAJBURIY init
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- customer_id majburiy
        -- E-4: IS NULL ishlatish
        IF i_rec.customer_id IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': customer_id';
            RETURN;
        END IF;

        -- doc_type majburiy
        IF i_rec.doc_type IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': doc_type';
            RETURN;
        END IF;

        -- doc_type qiymati tekshiruvi
        IF i_rec.doc_type NOT IN ('PASSPORT', 'ID_CARD', 'FOREIGN_PASSPORT',
                                   'CERTIFICATE', 'LICENSE', 'POWER_OF_ATTORNEY') THEN
            o_code    := core_cif_doc_data_reader.c_err_doc_type_invalid;
            o_message := core_cif_doc_data_reader.c_msg_doc_type_invalid
                || ': ' || i_rec.doc_type;
            RETURN;
        END IF;

        -- doc_number majburiy
        IF i_rec.doc_number IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': doc_number';
            RETURN;
        END IF;

        -- issued_by majburiy
        IF i_rec.issued_by IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': issued_by';
            RETURN;
        END IF;

        -- issued_date majburiy
        IF i_rec.issued_date IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': issued_date';
            RETURN;
        END IF;

        -- created_by majburiy
        IF i_rec.created_by IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': created_by';
            RETURN;
        END IF;

        -- Muddat tekshiruvi (ogohlantirish, xato emas)
        IF i_rec.expiry_date IS NOT NULL THEN
            Validate_Expiry(i_rec.expiry_date, o_code, o_message);
            -- Ogohlantirish — kodni qayta o'rnatamiz, lekin message'ni saqlaymiz
            -- Xato emas, shuning uchun davom etamiz
            IF o_code = core_cif_doc_data_reader.c_err_doc_expired THEN
                -- Ogohlantirish sifatida log qilamiz, lekin bloklamaymiz
                o_code    := core_cif_const.c_code_ok;
                -- o_message ni saqlaymiz (warning message)
            END IF;
        END IF;
    END Validate_Create;

    -- =======================================================================
    -- Validate_Expiry - Muddat tekshiruvi
    -- Agar muddati tugagan bo'lsa, ogohlantirish
    -- =======================================================================
    PROCEDURE Validate_Expiry(
        i_expiry_date   IN  DATE,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- E-4: IS NULL ishlatish
        IF i_expiry_date IS NULL THEN
            RETURN;
        END IF;

        IF i_expiry_date < TRUNC(SYSDATE) THEN
            o_code    := core_cif_doc_data_reader.c_err_doc_expired;
            o_message := core_cif_doc_data_reader.c_msg_doc_expired
                || ' (muddati: ' || TO_CHAR(i_expiry_date, 'DD.MM.YYYY') || ')';
        END IF;
    END Validate_Expiry;

END core_cif_doc_rules;
/


-- **************************************************************************
-- 5. core_cif_doc_service - SERVICE qatlami (Hujjatlar biznes logika)
--    COMMIT/ROLLBACK faqat shu qatlamda! (E-5)
--    SC-1: o_code/o_message/o_ora_message
--    SC-2: OUT parametrlar boshida init
--    E-2: WHEN OTHERS THEN — log + o_code set (NULL emas!)
--
--    Qatlam bog'liqliklari:
--      core_cif_data_reader.Find_By_Id   — mijoz mavjudligini tekshirish (05 dan)
--      core_cif_doc_data_reader           — hujjat type va SELECT
--      core_cif_doc_repo                  — hujjat DML
--      core_cif_doc_rules                 — hujjat validatsiya
--      core_cif_logger.Log_Audit          — audit log yozish (05 dan)
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_doc_service AS

    -- Yangi hujjat yaratish
    PROCEDURE Create_Document(
        io_rec          IN OUT core_cif_doc_types.t_document_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Hujjat yangilash
    PROCEDURE Update_Document(
        i_rec           IN  core_cif_doc_types.t_document_rec,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Hujjat o'chirish
    PROCEDURE Delete_Document(
        i_doc_id        IN  NUMBER,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

END core_cif_doc_service;
/

CREATE OR REPLACE PACKAGE BODY core_cif_doc_service AS

    -- =======================================================================
    -- Create_Document
    -- Qatlam: DATA_READER.Find_By_Id (customer) -> RULES.Validate ->
    --         REPO.Create -> LOGGER.Log_Audit -> COMMIT
    -- SC-1: o_code/o_message/o_ora_message
    -- SC-2: boshida init
    -- E-2: WHEN OTHERS — log + o_code (NULL emas!)
    -- E-5: COMMIT faqat shu qatlamda
    -- =======================================================================
    PROCEDURE Create_Document(
        io_rec          IN OUT core_cif_doc_types.t_document_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_cust_rec      core_cif_types.t_customer_rec;
        v_cust_found    BOOLEAN;
    BEGIN
        -- SC-2: MAJBURIY init
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- Mijoz mavjudligini tekshirish (DATA_READER — 05 dan)
        core_cif_data_reader.Find_By_Id(io_rec.customer_id, v_cust_rec, v_cust_found);
        IF NOT v_cust_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- 1. RULES: Validatsiya
        core_cif_doc_rules.Validate_Create(io_rec, o_code, o_message);
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: INSERT
        core_cif_doc_repo.Create_Document(io_rec);

        -- 3. LOGGER: Audit log (core_cif_logger — 05 dan)
        core_cif_logger.Log_Audit(
            i_customer_id   => io_rec.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'document',
            i_old_value     => NULL,
            i_new_value     => 'Yangi hujjat: ' || io_rec.doc_type
                || ' #' || io_rec.doc_number,
            i_changed_by    => io_rec.created_by
        );

        -- E-5: COMMIT faqat SERVICE'da
        COMMIT;

        o_message := 'Hujjat muvaffaqiyatli yaratildi (doc_id: '
            || TO_CHAR(io_rec.doc_id) || ')';

    EXCEPTION
        -- E-2: WHEN OTHERS — log + o_code (NULL emas!)
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Hujjat yaratishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Create_Document;

    -- =======================================================================
    -- Update_Document
    -- Qatlam: DOC_DATA_READER.Find_By_Id -> REPO.Update ->
    --         LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Update_Document(
        i_rec           IN  core_cif_doc_types.t_document_rec,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing      core_cif_doc_types.t_document_rec;
        v_found         BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- E-4: IS NULL ishlatish
        IF i_rec.doc_id IS NULL THEN
            o_code    := core_cif_doc_data_reader.c_err_doc_not_found;
            o_message := core_cif_doc_data_reader.c_msg_doc_not_found;
            RETURN;
        END IF;

        -- Mavjudligini tekshirish (DATA_READER)
        core_cif_doc_data_reader.Find_By_Id(i_rec.doc_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_doc_data_reader.c_err_doc_not_found;
            o_message := core_cif_doc_data_reader.c_msg_doc_not_found;
            RETURN;
        END IF;

        -- 1. REPO: UPDATE
        core_cif_doc_repo.Update_Document(i_rec);

        -- 2. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => v_existing.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'document',
            i_old_value     => v_existing.doc_type || ' #' || v_existing.doc_number,
            i_new_value     => i_rec.doc_type || ' #' || i_rec.doc_number,
            i_changed_by    => i_user
        );

        COMMIT;

        o_message := 'Hujjat muvaffaqiyatli yangilandi (doc_id: '
            || TO_CHAR(i_rec.doc_id) || ')';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Hujjat yangilashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Update_Document;

    -- =======================================================================
    -- Delete_Document
    -- Qatlam: DOC_DATA_READER.Find_By_Id -> REPO.Delete ->
    --         LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Delete_Document(
        i_doc_id        IN  NUMBER,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing      core_cif_doc_types.t_document_rec;
        v_found         BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- Mavjudligini tekshirish (DATA_READER)
        core_cif_doc_data_reader.Find_By_Id(i_doc_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_doc_data_reader.c_err_doc_not_found;
            o_message := core_cif_doc_data_reader.c_msg_doc_not_found;
            RETURN;
        END IF;

        -- 1. REPO: DELETE
        core_cif_doc_repo.Delete_Document(i_doc_id);

        -- 2. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => v_existing.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'document',
            i_old_value     => 'Hujjat o''chirildi: ' || v_existing.doc_type
                || ' #' || v_existing.doc_number,
            i_new_value     => NULL,
            i_changed_by    => i_user
        );

        COMMIT;

        o_message := 'Hujjat muvaffaqiyatli o''chirildi (doc_id: '
            || TO_CHAR(i_doc_id) || ')';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Hujjat o''chirishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Delete_Document;

END core_cif_doc_service;
/


-- **************************************************************************
-- 7. core_cif_contact_types - TYPES qatlami (Kontaktlar record type'lar)
--    CONST darajasida — body yo'q, faqat spec.
--    Barcha qatlamlar (CONTACT_DATA_READER, CONTACT_REPO, CONTACT_RULES,
--    CONTACT_SERVICE) shu type'larga murojaat qiladi.
--
--    SIRIUS qoidasi: DATA_READER faqat SELECT o'z ichiga olishi kerak.
--    Type'lar alohida TYPES paketida bo'lishi shart.
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_contact_types AS
    -- Record type'lar — kontakt qatlamlari tomonidan ishlatiladi

    TYPE t_contact_rec IS RECORD (
        contact_id          core_cif_contacts.contact_id%TYPE,
        customer_id         core_cif_contacts.customer_id%TYPE,
        contact_type        core_cif_contacts.contact_type%TYPE,
        contact_value       core_cif_contacts.contact_value%TYPE,
        is_primary          core_cif_contacts.is_primary%TYPE,
        description         core_cif_contacts.description%TYPE,
        created_at          core_cif_contacts.created_at%TYPE
    );

    TYPE t_contact_tab IS TABLE OF t_contact_rec;
END core_cif_contact_types;
/


-- **************************************************************************
-- 8. core_cif_contact_data_reader - DATA_READER qatlami (Kontaktlar SELECT)
--    Faqat SELECT so'rovlar! DML YO'Q! (L-1)
--    Type'lar core_cif_contact_types paketiga ko'chirilgan (SIRIUS L-1 qoidasi).
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_contact_data_reader AS

    -- Xato kodlari (E-7: -20025..-20029 oraligi)
    c_err_contact_not_found     CONSTANT NUMBER       := -20025;
    c_msg_contact_not_found     CONSTANT VARCHAR2(200) := 'Kontakt topilmadi';
    c_err_invalid_email         CONSTANT NUMBER       := -20026;
    c_msg_invalid_email         CONSTANT VARCHAR2(200) := 'Email formati noto''g''ri';
    c_err_contact_type_invalid  CONSTANT NUMBER       := -20027;
    c_msg_contact_type_invalid  CONSTANT VARCHAR2(200) := 'Kontakt turi noto''g''ri';

    -- SELECT by ID
    -- S-2: SELECT * yo'q, aniq ustunlar
    PROCEDURE Find_By_Id(
        i_contact_id    IN  NUMBER,
        o_rec           OUT core_cif_contact_types.t_contact_rec,
        o_found         OUT BOOLEAN
    );

    -- SELECT by customer_id (barcha kontaktlar)
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        o_results       OUT SYS_REFCURSOR
    );

    -- Jami soni (customer_id bo'yicha)
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER;

END core_cif_contact_data_reader;
/

CREATE OR REPLACE PACKAGE BODY core_cif_contact_data_reader AS

    -- =======================================================================
    -- Find_By_Id - S-2: SELECT * yo'q, aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Id(
        i_contact_id    IN  NUMBER,
        o_rec           OUT core_cif_contact_types.t_contact_rec,
        o_found         OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT contact_id, customer_id, contact_type, contact_value,
               is_primary, description, created_at
          INTO o_rec.contact_id, o_rec.customer_id, o_rec.contact_type,
               o_rec.contact_value, o_rec.is_primary,
               o_rec.description, o_rec.created_at
          FROM core_cif_contacts
         WHERE contact_id = i_contact_id;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Id;

    -- =======================================================================
    -- Find_By_Customer - Mijozning barcha kontaktlari
    -- S-2: aniq ustunlar
    -- =======================================================================
    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        o_results       OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN o_results FOR
            SELECT contact_id, customer_id, contact_type, contact_value,
                   is_primary, description, created_at
              FROM core_cif_contacts
             WHERE customer_id = i_customer_id
             ORDER BY is_primary DESC, contact_type, created_at DESC;
    END Find_By_Customer;

    -- =======================================================================
    -- Count_By_Customer
    -- =======================================================================
    FUNCTION Count_By_Customer(
        i_customer_id   IN NUMBER
    ) RETURN NUMBER IS
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO v_count
          FROM core_cif_contacts
         WHERE customer_id = i_customer_id;
        RETURN v_count;
    END Count_By_Customer;

END core_cif_contact_data_reader;
/


-- **************************************************************************
-- 7. core_cif_contact_repo - REPO qatlami (Kontaktlar DML)
--    Faqat DML (INSERT/UPDATE/DELETE)! SELECT yo'q!
--    MUHIM: COMMIT/ROLLBACK yo'q! (E-5)
--    Type'lar core_cif_contact_data_reader dan olinadi
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_contact_repo AS

    -- INSERT + contact_id qaytarish
    PROCEDURE Create_Contact(
        io_rec      IN OUT core_cif_contact_types.t_contact_rec
    );

    -- UPDATE
    PROCEDURE Update_Contact(
        i_rec       IN core_cif_contact_types.t_contact_rec
    );

    -- DELETE
    PROCEDURE Delete_Contact(
        i_contact_id    IN NUMBER
    );

END core_cif_contact_repo;
/

CREATE OR REPLACE PACKAGE BODY core_cif_contact_repo AS

    -- =======================================================================
    -- Create_Contact - INSERT + contact_id qaytarish
    -- S-3: INSERT ustun ro'yxati bilan
    -- E-5: COMMIT yo'q (REPO qatlam)
    -- =======================================================================
    PROCEDURE Create_Contact(
        io_rec      IN OUT core_cif_contact_types.t_contact_rec
    ) IS
    BEGIN
        io_rec.created_at := SYSTIMESTAMP;

        INSERT INTO core_cif_contacts (
            customer_id, contact_type, contact_value,
            is_primary, description, created_at
        ) VALUES (
            io_rec.customer_id, io_rec.contact_type, io_rec.contact_value,
            NVL(io_rec.is_primary, 'N'), io_rec.description, io_rec.created_at
        ) RETURNING contact_id INTO io_rec.contact_id;
    END Create_Contact;

    -- =======================================================================
    -- Update_Contact
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Update_Contact(
        i_rec       IN core_cif_contact_types.t_contact_rec
    ) IS
    BEGIN
        UPDATE core_cif_contacts
           SET contact_type    = i_rec.contact_type,
               contact_value   = i_rec.contact_value,
               is_primary      = i_rec.is_primary,
               description     = i_rec.description
         WHERE contact_id = i_rec.contact_id;
    END Update_Contact;

    -- =======================================================================
    -- Delete_Contact
    -- E-5: COMMIT yo'q
    -- =======================================================================
    PROCEDURE Delete_Contact(
        i_contact_id    IN NUMBER
    ) IS
    BEGIN
        DELETE FROM core_cif_contacts
         WHERE contact_id = i_contact_id;
    END Delete_Contact;

END core_cif_contact_repo;
/


-- **************************************************************************
-- 8. core_cif_contact_rules - RULES qatlami (Kontaktlar validatsiya)
--    DML YO'Q! (L-1)
--    Type'lar core_cif_contact_data_reader dan olinadi
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_contact_rules AS

    -- Yaratish uchun validatsiya
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_contact_types.t_contact_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

END core_cif_contact_rules;
/

CREATE OR REPLACE PACKAGE BODY core_cif_contact_rules AS

    -- =======================================================================
    -- Validate_Create
    -- DML YO'Q (L-1)
    -- SC-2: OUT parametrlarni boshida init
    -- =======================================================================
    PROCEDURE Validate_Create(
        i_rec       IN  core_cif_contact_types.t_contact_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
    BEGIN
        -- SC-2: MAJBURIY init
        o_code    := core_cif_const.c_code_ok;
        o_message := core_cif_const.c_msg_ok;

        -- customer_id majburiy
        -- E-4: IS NULL ishlatish
        IF i_rec.customer_id IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': customer_id';
            RETURN;
        END IF;

        -- contact_type majburiy
        IF i_rec.contact_type IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': contact_type';
            RETURN;
        END IF;

        -- contact_type qiymati tekshiruvi
        IF i_rec.contact_type NOT IN ('PHONE', 'EMAIL', 'FAX', 'TELEGRAM', 'OTHER') THEN
            o_code    := core_cif_contact_data_reader.c_err_contact_type_invalid;
            o_message := core_cif_contact_data_reader.c_msg_contact_type_invalid
                || ': ' || i_rec.contact_type;
            RETURN;
        END IF;

        -- contact_value majburiy
        IF i_rec.contact_value IS NULL THEN
            o_code    := core_cif_const.c_err_required_field;
            o_message := core_cif_const.c_msg_required_field || ': contact_value';
            RETURN;
        END IF;

        -- Tur bo'yicha format validatsiyasi
        -- PHONE: +998XXXXXXXXX format
        IF i_rec.contact_type = 'PHONE' THEN
            IF NOT core_cif_util.Is_Valid_Phone(i_rec.contact_value) THEN
                o_code    := core_cif_const.c_err_invalid_phone;
                o_message := core_cif_const.c_msg_invalid_phone
                    || ' (kiritilgan: ' || i_rec.contact_value || ')';
                RETURN;
            END IF;
        END IF;

        -- EMAIL: asosiy format tekshiruvi
        IF i_rec.contact_type = 'EMAIL' THEN
            IF NOT core_cif_util.Is_Valid_Email(i_rec.contact_value) THEN
                o_code    := core_cif_contact_data_reader.c_err_invalid_email;
                o_message := core_cif_contact_data_reader.c_msg_invalid_email
                    || ' (kiritilgan: ' || i_rec.contact_value || ')';
                RETURN;
            END IF;
        END IF;

    END Validate_Create;

END core_cif_contact_rules;
/


-- **************************************************************************
-- 9. core_cif_contact_service - SERVICE qatlami (Kontaktlar biznes logika)
--    COMMIT/ROLLBACK faqat shu qatlamda! (E-5)
--    SC-1: o_code/o_message/o_ora_message
--    SC-2: OUT parametrlar boshida init
--    E-2: WHEN OTHERS THEN — log + o_code set (NULL emas!)
--
--    Qatlam bog'liqliklari:
--      core_cif_data_reader.Find_By_Id   — mijoz mavjudligini tekshirish (05 dan)
--      core_cif_contact_data_reader       — kontakt type va SELECT
--      core_cif_contact_repo              — kontakt DML
--      core_cif_contact_rules             — kontakt validatsiya
--      core_cif_logger.Log_Audit          — audit log yozish (05 dan)
-- **************************************************************************
CREATE OR REPLACE PACKAGE core_cif_contact_service AS

    -- Yangi kontakt yaratish
    PROCEDURE Create_Contact(
        io_rec          IN OUT core_cif_contact_types.t_contact_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Kontakt yangilash
    PROCEDURE Update_Contact(
        i_rec           IN  core_cif_contact_types.t_contact_rec,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    -- Kontakt o'chirish
    PROCEDURE Delete_Contact(
        i_contact_id    IN  NUMBER,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

END core_cif_contact_service;
/

CREATE OR REPLACE PACKAGE BODY core_cif_contact_service AS

    -- =======================================================================
    -- Create_Contact
    -- Qatlam: DATA_READER.Find_By_Id (customer) -> RULES.Validate ->
    --         REPO.Create -> LOGGER.Log_Audit -> COMMIT
    -- SC-1: o_code/o_message/o_ora_message
    -- SC-2: boshida init
    -- E-2: WHEN OTHERS — log + o_code (NULL emas!)
    -- E-5: COMMIT faqat shu qatlamda
    -- =======================================================================
    PROCEDURE Create_Contact(
        io_rec          IN OUT core_cif_contact_types.t_contact_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_cust_rec      core_cif_types.t_customer_rec;
        v_cust_found    BOOLEAN;
    BEGIN
        -- SC-2: MAJBURIY init
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- Mijoz mavjudligini tekshirish (DATA_READER — 05 dan)
        core_cif_data_reader.Find_By_Id(io_rec.customer_id, v_cust_rec, v_cust_found);
        IF NOT v_cust_found THEN
            o_code    := core_cif_const.c_err_customer_not_found;
            o_message := core_cif_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- PHONE turi uchun format qo'llash
        IF io_rec.contact_type = 'PHONE' THEN
            io_rec.contact_value := core_cif_util.Format_Phone(io_rec.contact_value);
        END IF;

        -- 1. RULES: Validatsiya
        core_cif_contact_rules.Validate_Create(io_rec, o_code, o_message);
        IF o_code != core_cif_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO: INSERT
        core_cif_contact_repo.Create_Contact(io_rec);

        -- 3. LOGGER: Audit log (core_cif_logger — 05 dan)
        core_cif_logger.Log_Audit(
            i_customer_id   => io_rec.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'contact',
            i_old_value     => NULL,
            i_new_value     => 'Yangi kontakt: ' || io_rec.contact_type
                || ' = ' || io_rec.contact_value,
            i_changed_by    => NVL(v_cust_rec.created_by, 'SYSTEM')
        );

        -- E-5: COMMIT faqat SERVICE'da
        COMMIT;

        o_message := 'Kontakt muvaffaqiyatli yaratildi (contact_id: '
            || TO_CHAR(io_rec.contact_id) || ')';

    EXCEPTION
        -- E-2: WHEN OTHERS — log + o_code (NULL emas!)
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Kontakt yaratishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Create_Contact;

    -- =======================================================================
    -- Update_Contact
    -- Qatlam: CONTACT_DATA_READER.Find_By_Id -> REPO.Update ->
    --         LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Update_Contact(
        i_rec           IN  core_cif_contact_types.t_contact_rec,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing      core_cif_contact_types.t_contact_rec;
        v_found         BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- Mavjudligini tekshirish (DATA_READER)
        core_cif_contact_data_reader.Find_By_Id(i_rec.contact_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_contact_data_reader.c_err_contact_not_found;
            o_message := core_cif_contact_data_reader.c_msg_contact_not_found;
            RETURN;
        END IF;

        -- 1. REPO: UPDATE
        core_cif_contact_repo.Update_Contact(i_rec);

        -- 2. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => v_existing.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'contact',
            i_old_value     => v_existing.contact_type || ' = ' || v_existing.contact_value,
            i_new_value     => i_rec.contact_type || ' = ' || i_rec.contact_value,
            i_changed_by    => i_user
        );

        COMMIT;

        o_message := 'Kontakt muvaffaqiyatli yangilandi (contact_id: '
            || TO_CHAR(i_rec.contact_id) || ')';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Kontakt yangilashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Update_Contact;

    -- =======================================================================
    -- Delete_Contact
    -- Qatlam: CONTACT_DATA_READER.Find_By_Id -> REPO.Delete ->
    --         LOGGER.Log_Audit -> COMMIT
    -- =======================================================================
    PROCEDURE Delete_Contact(
        i_contact_id    IN  NUMBER,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing      core_cif_contact_types.t_contact_rec;
        v_found         BOOLEAN;
    BEGIN
        o_code        := core_cif_const.c_code_ok;
        o_message     := core_cif_const.c_msg_ok;
        o_ora_message := NULL;

        -- Mavjudligini tekshirish (DATA_READER)
        core_cif_contact_data_reader.Find_By_Id(i_contact_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_cif_contact_data_reader.c_err_contact_not_found;
            o_message := core_cif_contact_data_reader.c_msg_contact_not_found;
            RETURN;
        END IF;

        -- 1. REPO: DELETE
        core_cif_contact_repo.Delete_Contact(i_contact_id);

        -- 2. LOGGER: Audit log
        core_cif_logger.Log_Audit(
            i_customer_id   => v_existing.customer_id,
            i_action_type   => 'UPDATE',
            i_field_name    => 'contact',
            i_old_value     => 'Kontakt o''chirildi: ' || v_existing.contact_type
                || ' = ' || v_existing.contact_value,
            i_new_value     => NULL,
            i_changed_by    => i_user
        );

        COMMIT;

        o_message := 'Kontakt muvaffaqiyatli o''chirildi (contact_id: '
            || TO_CHAR(i_contact_id) || ')';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_cif_const.c_code_error;
            o_message     := 'Kontakt o''chirishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Delete_Contact;

END core_cif_contact_service;
/

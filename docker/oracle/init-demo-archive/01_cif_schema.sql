-- ============================================================================
-- MARS ABS - core_cif moduli
-- 01_cif_schema.sql - Jadvallar va constraintlar
-- Modul: Mijozlar (Customer Information File)
-- Sana: 2026-05-26
-- ============================================================================

-- ==========================================================================
-- 1. core_cif_customers - Asosiy mijozlar jadvali
--    FYaSh (INDIVIDUAL) va YuSh (CORPORATE) bitta jadvalda
--    Maker-Checker: DEFAULT status = 'PENDING'
-- ==========================================================================
CREATE TABLE core_cif_customers (
    customer_id         NUMBER GENERATED ALWAYS AS IDENTITY,
    cif_number          VARCHAR2(20)    NOT NULL,
    customer_type       VARCHAR2(20)    NOT NULL,
    -- FYaSh (Jismoniy shaxs) maydonlari
    first_name          VARCHAR2(100),
    last_name           VARCHAR2(100),
    middle_name         VARCHAR2(100),
    -- YuSh (Yuridik shaxs) maydonlari
    org_name            VARCHAR2(300),
    org_full_name       VARCHAR2(500),
    org_form            VARCHAR2(30),
    oked                VARCHAR2(10),
    reg_number          VARCHAR2(30),
    reg_date            DATE,
    reg_authority       VARCHAR2(200),
    director_name       VARCHAR2(200),
    director_position   VARCHAR2(100),
    accountant_name     VARCHAR2(200),
    director_pinfl      VARCHAR2(14),
    -- Identifikatsiya
    pinfl               VARCHAR2(14),
    inn                 VARCHAR2(9),
    -- FYaSh shaxsiy ma'lumotlar
    birth_date          DATE,
    birth_place         VARCHAR2(200),
    gender              VARCHAR2(1),
    -- Aloqa
    phone               VARCHAR2(20)    NOT NULL,
    email               VARCHAR2(150),
    -- Manzillar
    legal_address       VARCHAR2(500),
    actual_address      VARCHAR2(500),
    -- Klassifikatsiya
    resident_flag       CHAR(1)         NOT NULL,
    country_code        VARCHAR2(3)     NOT NULL,
    branch_code         VARCHAR2(5)     NOT NULL,
    sector_code         VARCHAR2(10)    NOT NULL,
    risk_category       VARCHAR2(10)    NOT NULL,
    is_pep              CHAR(1)         DEFAULT 'N' NOT NULL,
    opening_purpose     VARCHAR2(200),
    -- FYaSh ish joyi
    employer_name       VARCHAR2(300),
    employer_position   VARCHAR2(100),
    employer_address    VARCHAR2(500),
    employer_phone      VARCHAR2(20),
    -- YuSh boshqa bank ma'lumotlari
    other_bank_name     VARCHAR2(200),
    other_bank_mfo      VARCHAR2(5),
    other_bank_account  VARCHAR2(20),
    -- Maker-Checker
    status              VARCHAR2(20)    DEFAULT 'PENDING' NOT NULL,
    approved_by         VARCHAR2(50),
    approved_at         TIMESTAMP,
    -- Audit
    created_by          VARCHAR2(50)    NOT NULL,
    created_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by          VARCHAR2(50),
    updated_at          TIMESTAMP,
    -- Constraintlar
    CONSTRAINT core_cif_customers_pk PRIMARY KEY (customer_id),
    CONSTRAINT core_cif_customers_cif_uk UNIQUE (cif_number),
    CONSTRAINT core_cif_customers_pinfl_uk UNIQUE (pinfl),
    CONSTRAINT core_cif_customers_inn_uk UNIQUE (inn),
    CONSTRAINT core_cif_customers_type_ck CHECK (
        customer_type IN ('INDIVIDUAL', 'CORPORATE')
    ),
    CONSTRAINT core_cif_customers_gender_ck CHECK (
        gender IN ('M', 'F') OR gender IS NULL
    ),
    CONSTRAINT core_cif_customers_resident_ck CHECK (
        resident_flag IN ('Y', 'N')
    ),
    CONSTRAINT core_cif_customers_risk_ck CHECK (
        risk_category IN ('LOW', 'MEDIUM', 'HIGH')
    ),
    CONSTRAINT core_cif_customers_pep_ck CHECK (
        is_pep IN ('Y', 'N')
    ),
    CONSTRAINT core_cif_customers_status_ck CHECK (
        status IN ('PENDING', 'ACTIVE', 'BLOCKED', 'CLOSED', 'REJECTED')
    )
);

COMMENT ON TABLE core_cif_customers IS 'Asosiy mijozlar jadvali - FYaSh va YuSh';
COMMENT ON COLUMN core_cif_customers.cif_number IS 'CIF raqam, format: CIF-YYYYMMDD-NNNNNN';
COMMENT ON COLUMN core_cif_customers.customer_type IS 'INDIVIDUAL=FYaSh, CORPORATE=YuSh';
COMMENT ON COLUMN core_cif_customers.pinfl IS 'PINFL - 14 xonali (FYaSh uchun)';
COMMENT ON COLUMN core_cif_customers.inn IS 'STIR - 9 xonali (YuSh uchun)';
COMMENT ON COLUMN core_cif_customers.status IS 'Holat: PENDING(yangi) -> ACTIVE(tasdiqlangan) -> BLOCKED/CLOSED';
COMMENT ON COLUMN core_cif_customers.approved_by IS 'Checker - tasdiqlagan foydalanuvchi';

-- ==========================================================================
-- 2. core_cif_documents - Mijoz hujjatlari
-- ==========================================================================
CREATE TABLE core_cif_documents (
    doc_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    customer_id         NUMBER          NOT NULL,
    doc_type            VARCHAR2(30)    NOT NULL,
    doc_series          VARCHAR2(10),
    doc_number          VARCHAR2(20)    NOT NULL,
    issued_by           VARCHAR2(200)   NOT NULL,
    issued_date         DATE            NOT NULL,
    expiry_date         DATE,
    is_primary          CHAR(1)         DEFAULT 'N' NOT NULL,
    created_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    created_by          VARCHAR2(50)    NOT NULL,
    CONSTRAINT core_cif_documents_pk PRIMARY KEY (doc_id),
    CONSTRAINT core_cif_documents_cust_fk FOREIGN KEY (customer_id)
        REFERENCES core_cif_customers (customer_id),
    CONSTRAINT core_cif_documents_type_ck CHECK (
        doc_type IN ('PASSPORT', 'ID_CARD', 'FOREIGN_PASSPORT',
                     'CERTIFICATE', 'LICENSE', 'POWER_OF_ATTORNEY')
    ),
    CONSTRAINT core_cif_documents_primary_ck CHECK (
        is_primary IN ('Y', 'N')
    )
);

COMMENT ON TABLE core_cif_documents IS 'Mijoz identifikatsiya hujjatlari';

-- ==========================================================================
-- 3. core_cif_contacts - Qo''shimcha aloqa ma''lumotlari
-- ==========================================================================
CREATE TABLE core_cif_contacts (
    contact_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    customer_id         NUMBER          NOT NULL,
    contact_type        VARCHAR2(20)    NOT NULL,
    contact_value       VARCHAR2(200)   NOT NULL,
    is_primary          CHAR(1)         DEFAULT 'N' NOT NULL,
    description         VARCHAR2(200),
    created_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT core_cif_contacts_pk PRIMARY KEY (contact_id),
    CONSTRAINT core_cif_contacts_cust_fk FOREIGN KEY (customer_id)
        REFERENCES core_cif_customers (customer_id),
    CONSTRAINT core_cif_contacts_type_ck CHECK (
        contact_type IN ('PHONE', 'EMAIL', 'FAX', 'TELEGRAM', 'OTHER')
    ),
    CONSTRAINT core_cif_contacts_primary_ck CHECK (
        is_primary IN ('Y', 'N')
    )
);

COMMENT ON TABLE core_cif_contacts IS 'Qo''shimcha aloqa ma''lumotlari';

-- ==========================================================================
-- 4. core_cif_audit_log - Audit log (faqat INSERT, UPDATE/DELETE taqiqlangan)
-- ==========================================================================
CREATE TABLE core_cif_audit_log (
    log_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    customer_id         NUMBER          NOT NULL,
    action_type         VARCHAR2(20)    NOT NULL,
    field_name          VARCHAR2(100),
    old_value           VARCHAR2(500),
    new_value           VARCHAR2(500),
    changed_by          VARCHAR2(50)    NOT NULL,
    changed_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT core_cif_audit_log_pk PRIMARY KEY (log_id),
    CONSTRAINT core_cif_audit_log_cust_fk FOREIGN KEY (customer_id)
        REFERENCES core_cif_customers (customer_id),
    CONSTRAINT core_cif_audit_log_action_ck CHECK (
        action_type IN ('CREATE', 'UPDATE', 'STATUS_CHANGE', 'APPROVE', 'REJECT')
    )
);

COMMENT ON TABLE core_cif_audit_log IS 'Mijoz ma''lumotlari o''zgarishlar tarixi - faqat INSERT';

-- ============================================================================
-- MARS ABS - core_acc moduli
-- 11_acc_schema.sql - Jadvallar, constraintlar, indekslar, sequence
-- Modul: Hisoblar (Accounts Management)
-- Asoslanadi: BT-002, TZ-002
-- Sana: 2026-06-17
--
-- Bog'lanish: core_cif_customers (1) ──< (N) core_acc_accounts
--             core_acc_accounts  (1) ──< (N) core_acc_signatories
--             core_acc_accounts  (1) ──< (N) core_acc_audit_log
-- ============================================================================

-- ==========================================================================
-- 1. core_acc_accounts - Asosiy hisoblar jadvali
--    Barcha hisob turlari bitta jadvalda (account_type orqali farqlanadi)
--    Maker-Checker: DEFAULT status = 'PENDING'
--    Pul summalari: NUMBER(20,2) — BigDecimal (double/float HECH QACHON)
-- ==========================================================================
CREATE TABLE core_acc_accounts (
    account_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    account_number      VARCHAR2(20)    NOT NULL,
    customer_id         NUMBER          NOT NULL,
    account_type        VARCHAR2(20)    NOT NULL,
    currency            VARCHAR2(3)     NOT NULL,
    gl_code             VARCHAR2(5)     NOT NULL,
    account_name        VARCHAR2(200),
    -- Holat (Maker-Checker + workflow)
    status              VARCHAR2(20)    DEFAULT 'PENDING' NOT NULL,
    -- Moliyaviy
    balance             NUMBER(20,2)    DEFAULT 0 NOT NULL,
    available_balance   NUMBER(20,2)    DEFAULT 0 NOT NULL,
    min_balance         NUMBER(20,2)    DEFAULT 0 NOT NULL,
    daily_limit         NUMBER(20,2),
    monthly_limit       NUMBER(20,2),
    interest_rate       NUMBER(5,2),
    -- Klassifikatsiya
    branch_code         VARCHAR2(5)     NOT NULL,
    -- Sanalar
    opened_at           TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    last_activity_at    TIMESTAMP,
    closed_at           TIMESTAMP,
    close_reason        VARCHAR2(500),
    -- Maker-Checker
    approved_by         VARCHAR2(50),
    approved_at         TIMESTAMP,
    -- Audit
    created_by          VARCHAR2(50)    NOT NULL,
    created_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by          VARCHAR2(50),
    updated_at          TIMESTAMP,
    -- Constraintlar
    CONSTRAINT core_acc_accounts_pk PRIMARY KEY (account_id),
    CONSTRAINT core_acc_accounts_num_uk UNIQUE (account_number),
    CONSTRAINT core_acc_accounts_cust_fk FOREIGN KEY (customer_id)
        REFERENCES core_cif_customers (customer_id),
    CONSTRAINT core_acc_accounts_type_ck CHECK (
        account_type IN ('CURRENT', 'SAVINGS', 'DEPOSIT', 'LOAN', 'SPECIAL')
    ),
    CONSTRAINT core_acc_accounts_ccy_ck CHECK (
        currency IN ('UZS', 'USD', 'EUR')
    ),
    CONSTRAINT core_acc_accounts_status_ck CHECK (
        status IN ('PENDING', 'ACTIVE', 'FROZEN', 'BLOCKED', 'CLOSED', 'REJECTED')
    ),
    -- Overdraft himoyasi: qoldiq manfiy bo'lmaydi (BR-010).
    -- Minimal qoldiq chegarasi chiqim vaqtida core_trx da tekshiriladi
    -- (ochilishda balance=0, min_balance>0 holatini buzmaslik uchun).
    CONSTRAINT core_acc_accounts_bal_ck CHECK (balance >= 0),
    CONSTRAINT core_acc_accounts_minbal_ck CHECK (min_balance >= 0)
);

COMMENT ON TABLE core_acc_accounts IS 'Asosiy hisoblar jadvali - barcha turlar';
COMMENT ON COLUMN core_acc_accounts.account_number IS '20 xonali hisob raqami: GL(5)+TUR(3)+KONTROL(1)+TARTIB(8)+VALYUTA(3)';
COMMENT ON COLUMN core_acc_accounts.customer_id IS 'Hisob egasi - core_cif_customers (FK)';
COMMENT ON COLUMN core_acc_accounts.status IS 'PENDING->ACTIVE->FROZEN/BLOCKED->CLOSED';
COMMENT ON COLUMN core_acc_accounts.balance IS 'Joriy qoldiq (BigDecimal)';
COMMENT ON COLUMN core_acc_accounts.gl_code IS 'Balans hisobi kodi (raqamning 1-5 xonasi)';

-- Indekslar
CREATE INDEX core_acc_accounts_cust_idx   ON core_acc_accounts (customer_id);
CREATE INDEX core_acc_accounts_status_idx ON core_acc_accounts (status);
CREATE INDEX core_acc_accounts_ccy_idx    ON core_acc_accounts (currency);
CREATE INDEX core_acc_accounts_branch_idx ON core_acc_accounts (branch_code);
CREATE INDEX core_acc_accounts_pending_idx ON core_acc_accounts (status, created_at);


-- ==========================================================================
-- 2. core_acc_signatories - Imzo huquqiga ega shaxslar (asosan YuSh)
-- ==========================================================================
CREATE TABLE core_acc_signatories (
    signatory_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    account_id          NUMBER          NOT NULL,
    person_name         VARCHAR2(200)   NOT NULL,
    person_pinfl        VARCHAR2(14),
    signer_position     VARCHAR2(100),
    signature_type      VARCHAR2(10)    NOT NULL,
    is_active           CHAR(1)         DEFAULT 'Y' NOT NULL,
    created_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    created_by          VARCHAR2(50)    NOT NULL,
    CONSTRAINT core_acc_signatories_pk PRIMARY KEY (signatory_id),
    CONSTRAINT core_acc_signatories_acc_fk FOREIGN KEY (account_id)
        REFERENCES core_acc_accounts (account_id) ON DELETE CASCADE,
    CONSTRAINT core_acc_signatories_type_ck CHECK (
        signature_type IN ('FIRST', 'SECOND')
    ),
    CONSTRAINT core_acc_signatories_active_ck CHECK (
        is_active IN ('Y', 'N')
    )
);

COMMENT ON TABLE core_acc_signatories IS 'Imzo huquqiga ega shaxslar (FIRST/SECOND)';

CREATE INDEX core_acc_signatories_acc_idx ON core_acc_signatories (account_id);


-- ==========================================================================
-- 3. core_acc_audit_log - Audit log (faqat INSERT; UPDATE/DELETE taqiqlangan)
-- ==========================================================================
CREATE TABLE core_acc_audit_log (
    log_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    account_id          NUMBER          NOT NULL,
    action_type         VARCHAR2(20)    NOT NULL,
    field_name          VARCHAR2(100),
    old_value           VARCHAR2(500),
    new_value           VARCHAR2(500),
    reason              VARCHAR2(500),
    changed_by          VARCHAR2(50)    NOT NULL,
    changed_at          TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT core_acc_audit_log_pk PRIMARY KEY (log_id),
    CONSTRAINT core_acc_audit_log_acc_fk FOREIGN KEY (account_id)
        REFERENCES core_acc_accounts (account_id),
    CONSTRAINT core_acc_audit_log_action_ck CHECK (
        action_type IN ('CREATE', 'UPDATE', 'STATUS_CHANGE', 'APPROVE', 'REJECT', 'CLOSE')
    )
);

COMMENT ON TABLE core_acc_audit_log IS 'Hisob o''zgarishlar tarixi - faqat INSERT';

CREATE INDEX core_acc_audit_log_acc_idx ON core_acc_audit_log (account_id);


-- ==========================================================================
-- 4. Sequence - hisob raqamining tartib qismi (8 xona)
-- ==========================================================================
CREATE SEQUENCE core_acc_number_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

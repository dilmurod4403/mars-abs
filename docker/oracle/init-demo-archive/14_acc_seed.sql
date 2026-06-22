-- ============================================================================
-- MARS ABS - core_acc moduli
-- 14_acc_seed.sql - Test ma'lumotlar (seed)
-- Asoslanadi: TZ-002
-- Sana: 2026-06-17
--
-- Hisoblar faqat ACTIVE mijozlarga (core_cif seed: 1,2,5,6,8).
-- account_number va gl_code trigger tomonidan generatsiya qilinadi.
-- ============================================================================

-- 1. Cust 1 (Dilmurod) — CURRENT UZS, ACTIVE
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, daily_limit, monthly_limit,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    1, 'CURRENT', 'UZS', 'Asosiy joriy hisob',
    'ACTIVE', 5000000, 0, 20000000, 100000000,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator1'
);

-- 2. Cust 1 (Dilmurod) — SAVINGS USD, ACTIVE, harakatsiz (dormant)
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, interest_rate,
    branch_code, opened_at, last_activity_at,
    approved_by, approved_at, created_by
) VALUES (
    1, 'SAVINGS', 'USD', 'Jamg''arma hisob',
    'ACTIVE', 1200.50, 100, 4.5,
    '00191', SYSTIMESTAMP - NUMTODSINTERVAL(200, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(120, 'DAY'),
    'supervisor1', SYSTIMESTAMP - NUMTODSINTERVAL(200, 'DAY'), 'operator1'
);

-- 3. Cust 2 (Aziza) — CURRENT UZS, ACTIVE
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, daily_limit,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    2, 'CURRENT', 'UZS', 'Joriy hisob',
    'ACTIVE', 750000, 0, 5000000,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator2'
);

-- 4. Cust 2 (Aziza) — DEPOSIT UZS, FROZEN
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, interest_rate,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    2, 'DEPOSIT', 'UZS', 'Muddatli depozit',
    'FROZEN', 10000000, 0, 18.5,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator2'
);

-- 5. Cust 5 (Ivan) — CURRENT EUR, ACTIVE, qoldiq 0 (yopish testi uchun)
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    5, 'CURRENT', 'EUR', 'Valyuta hisobi',
    'ACTIVE', 0, 0,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator1'
);

-- 6. Cust 6 (Fido Soft MChJ) — CURRENT UZS, ACTIVE (imzo huquqi bilan)
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, daily_limit, monthly_limit,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    6, 'CURRENT', 'UZS', 'Operatsion hisob',
    'ACTIVE', 25000000, 1000000, 50000000, 500000000,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator1'
);

-- 7. Cust 6 (Fido Soft MChJ) — SPECIAL UZS, PENDING (tasdiqlash kutmoqda)
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance,
    branch_code, created_by
) VALUES (
    6, 'SPECIAL', 'UZS', 'Maxsus maqsadli hisob',
    'PENDING', 0, 0,
    '00191', 'operator2'
);

-- 8. Cust 8 (Abdullayev YaTT) — CURRENT UZS, PENDING
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance,
    branch_code, created_by
) VALUES (
    8, 'CURRENT', 'UZS', 'Tadbirkor joriy hisobi',
    'PENDING', 0, 0,
    '00191', 'operator1'
);

-- 9. Cust 8 (Abdullayev YaTT) — SAVINGS UZS, BLOCKED
INSERT INTO core_acc_accounts (
    customer_id, account_type, currency, account_name,
    status, balance, min_balance, interest_rate,
    branch_code, approved_by, approved_at, created_by
) VALUES (
    8, 'SAVINGS', 'UZS', 'Jamg''arma',
    'BLOCKED', 300000, 0, 4.0,
    '00191', 'supervisor1', SYSTIMESTAMP, 'operator1'
);


-- ==========================================================================
-- Imzo huquqi (core_acc_signatories) — Fido Soft MChJ CURRENT UZS hisobi
--   account_id (customer_id=6, CURRENT, UZS) bo'yicha aniqlanadi
-- ==========================================================================
INSERT INTO core_acc_signatories (
    account_id, person_name, person_pinfl, signer_position, signature_type, is_active, created_by
)
SELECT account_id, 'Karimov Alisher Nabijonovich', '67890123456789', 'Direktor', 'FIRST', 'Y', 'operator1'
  FROM core_acc_accounts
 WHERE customer_id = 6 AND account_type = 'CURRENT' AND currency = 'UZS';

INSERT INTO core_acc_signatories (
    account_id, person_name, person_pinfl, signer_position, signature_type, is_active, created_by
)
SELECT account_id, 'Rahimova Gulnora Shavkatovna', NULL, 'Bosh hisobchi', 'SECOND', 'Y', 'operator1'
  FROM core_acc_accounts
 WHERE customer_id = 6 AND account_type = 'CURRENT' AND currency = 'UZS';

COMMIT;

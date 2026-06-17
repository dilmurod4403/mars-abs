-- ============================================================================
-- MARS ABS - core_cif moduli
-- 06_cif_views.sql - View'lar
-- Sana: 2026-05-26
--
-- Qoidalar:
--   V-1: WITH READ ONLY (DML taqiqlangan)
--   V-2: SELECT * TAQIQLANGAN — aniq ustunlar
--   V-4: View ichida paket funksiyasi DUAL wrapper bilan
--        Faqat UTIL va REPO ruxsat etilgan
--   N-7: View nomlash: <module>_<nom>_<usage>_v
--        _ui_v  = UI uchun
--        _i_v   = internal uchun
--        _c_v   = communication/tashqi uchun
-- ============================================================================


-- ==========================================================================
-- 1. core_cif_customers_ui_v — UI uchun asosiy ko'rinish
--    Ro'yxat sahifasi uchun (qisqa ma'lumot)
--    V-4: UTIL funksiyalar DUAL wrapper bilan
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_customers_ui_v AS
SELECT c.customer_id,
       c.cif_number,
       c.customer_type,
       -- FIO formatlash (FYaSh uchun: Familiya I.O., YuSh uchun: org_name)
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' '
               || SUBSTR(c.first_name, 1, 1) || '.'
               || CASE
                      WHEN c.middle_name IS NOT NULL
                      THEN SUBSTR(c.middle_name, 1, 1) || '.'
                  END
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       c.first_name,
       c.last_name,
       c.org_name,
       c.phone,
       c.status,
       c.branch_code,
       c.risk_category,
       c.is_pep,
       c.created_by,
       c.created_at,
       -- V-4: UTIL funksiya DUAL wrapper bilan
       (SELECT core_cif_util.Calculate_Age(c.birth_date) FROM DUAL) AS age
  FROM core_cif_customers c
WITH READ ONLY;


-- ==========================================================================
-- 2. core_cif_active_customers_ui_v — Faqat ACTIVE mijozlar
--    Operatorlar uchun ish ekrani
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_active_customers_ui_v AS
SELECT c.customer_id,
       c.cif_number,
       c.customer_type,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' '
               || SUBSTR(c.first_name, 1, 1) || '.'
               || CASE
                      WHEN c.middle_name IS NOT NULL
                      THEN SUBSTR(c.middle_name, 1, 1) || '.'
                  END
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       c.first_name,
       c.last_name,
       c.org_name,
       c.phone,
       c.branch_code,
       c.risk_category,
       c.is_pep,
       c.approved_by,
       c.approved_at,
       c.created_at
  FROM core_cif_customers c
 WHERE c.status = 'ACTIVE'
WITH READ ONLY;


-- ==========================================================================
-- 3. core_cif_pending_customers_ui_v — PENDING holatdagilar
--    Supervisor uchun tasdiqlash ekrani (Maker-Checker)
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_pending_customers_ui_v AS
SELECT c.customer_id,
       c.cif_number,
       c.customer_type,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || c.first_name
               || CASE
                      WHEN c.middle_name IS NOT NULL
                      THEN ' ' || c.middle_name
                  END
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       c.first_name,
       c.last_name,
       c.org_name,
       c.phone,
       c.branch_code,
       c.risk_category,
       c.is_pep,
       c.created_by,
       c.created_at,
       -- Qancha vaqtdan beri kutmoqda (soatlarda)
       ROUND((SYSDATE - CAST(c.created_at AS DATE)) * 24, 1) AS waiting_hours
  FROM core_cif_customers c
 WHERE c.status = 'PENDING'
WITH READ ONLY;


-- ==========================================================================
-- 4. core_cif_customer_detail_i_v — Internal to'liq ko'rinish
--    Tafsilot sahifasi uchun (barcha maydonlar)
--    _i_v = internal (ichki foydalanish uchun)
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_customer_detail_i_v AS
SELECT c.customer_id,
       c.cif_number,
       c.customer_type,
       -- FIO / Tashkilot nomi
       c.first_name,
       c.last_name,
       c.middle_name,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || c.first_name
               || CASE
                      WHEN c.middle_name IS NOT NULL
                      THEN ' ' || c.middle_name
                  END
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_full_name
       END AS full_name,
       c.org_name,
       c.org_full_name,
       c.org_form,
       c.oked,
       c.reg_number,
       c.reg_date,
       c.reg_authority,
       c.director_name,
       c.director_position,
       c.accountant_name,
       c.director_pinfl,
       -- Identifikatsiya
       c.pinfl,
       c.inn,
       c.birth_date,
       c.birth_place,
       c.gender,
       -- V-4: UTIL funksiya DUAL wrapper bilan
       (SELECT core_cif_util.Calculate_Age(c.birth_date) FROM DUAL) AS age,
       -- Aloqa
       c.phone,
       c.email,
       -- Manzillar
       c.legal_address,
       c.actual_address,
       -- Klassifikatsiya
       c.resident_flag,
       c.country_code,
       c.branch_code,
       c.sector_code,
       c.risk_category,
       c.is_pep,
       c.opening_purpose,
       -- Ish joyi (FYaSh)
       c.employer_name,
       c.employer_position,
       c.employer_address,
       c.employer_phone,
       -- Boshqa bank (YuSh)
       c.other_bank_name,
       c.other_bank_mfo,
       c.other_bank_account,
       -- Holat
       c.status,
       c.approved_by,
       c.approved_at,
       -- Audit
       c.created_by,
       c.created_at,
       c.updated_by,
       c.updated_at
  FROM core_cif_customers c
WITH READ ONLY;

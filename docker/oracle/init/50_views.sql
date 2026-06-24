-- gvenzl init (sqlplus / as sysdba, CDB-root) -> XEPDB1.BANKUSER. Manual load: no-op (USER<>SYS).
BEGIN
  IF USER = 'SYS' THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = XEPDB1';
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = BANKUSER';
  END IF;
END;
/
-- ============================================================================
-- MARS ABS (mars-abs) — REAL SIRIUS build, F0
-- 50_views.sql — UI viewlar (ro'yxat/detail) — t:table datagrid uchun
--   Ref-jadvallar bilan join qilib o'qiladigan nomlar (kod -> nom).
--   Pul: saldo tiyinda saqlanadi -> _som ustunlari /100 (ko'rsatish uchun).
--   Old shart: core_cif_*, core_acc_*, core_ref_* o'rnatilgan bo'lsin.
-- ============================================================================
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- 1. core_cif_clients_ui_v — KLIENTLAR ro'yxati/detali
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW core_cif_clients_ui_v AS
SELECT
    c.client_id,
    c.client_code,
    c.client_kind,
    CASE c.client_kind WHEN 'P' THEN 'Jismoniy shaxs'
                       WHEN 'J' THEN 'Yuridik shaxs'
                       WHEN 'I' THEN 'YaTT (ИП)' END           AS kind_name,
    c.full_name,
    c.client_type,
    ct.name                                                    AS client_type_name,
    c.resident_flag,
    CASE c.resident_flag WHEN 'Y' THEN 'Rezident' ELSE 'Norezident' END AS resident_name,
    c.client_status,
    st.name_ru                                                 AS status_name,
    c.client_sub_status,
    c.nibbd_registered,
    c.nibbd_temp_code,
    c.region_code,
    c.maker_user,
    c.checker_user,
    c.created_at,
    c.updated_at
FROM core_cif_clients c
LEFT JOIN core_ref_client_type ct ON ct.code   = c.client_type
LEFT JOIN core_cif_status      st ON st.code    = c.client_status;

-- ----------------------------------------------------------------------------
-- 2. core_acc_accounts_ui_v — HISOBLAR ro'yxati/detali
--    saldo_som / saldo_in_som — tiyindan so'mga (/100) ko'rsatish uchun
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW core_acc_accounts_ui_v AS
SELECT
    a.account_id,
    a.account_number,
    a.balance_account,
    coa.name                                                   AS balance_account_name,
    a.currency_code,
    cur.char_code                                             AS currency_char,
    cur.name                                                   AS currency_name,
    a.client_id,
    a.client_code,
    a.client_name,
    a.client_type,
    a.acc_type,
    a.status                                                   AS mo_status,
    CASE a.status WHEN 'M' THEN 'Birlamchi (asosiy)' WHEN 'O' THEN 'Ikkilamchi' END AS mo_name,
    a.state,
    ast.name_ru                                                AS state_name,
    a.branch_code,
    br.name                                                    AS branch_name,
    a.saldo_out,
    a.saldo_out / 100                                          AS saldo_som,
    a.saldo_in,
    a.saldo_in / 100                                           AS saldo_in_som,
    a.reg_nibd,
    a.resident_flag,
    a.maker_user,
    a.checker_user,
    a.open_date,
    a.created_at,
    a.updated_at
FROM core_acc_accounts a
LEFT JOIN core_ref_coa      coa ON coa.code = a.balance_account
LEFT JOIN core_ref_currency cur ON cur.code = a.currency_code
LEFT JOIN core_acc_status   ast ON ast.code = a.state
LEFT JOIN core_ref_branch   br  ON br.code  = a.branch_code;

-- ----------------------------------------------------------------------------
-- 3. core_cif_pending_clients_v — tasdiq KUTAYOTGAN klientlar (Maker-Checker)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW core_cif_pending_clients_v AS
SELECT * FROM core_cif_clients_ui_v
WHERE client_status = 'CREATED';

-- ----------------------------------------------------------------------------
-- 4. core_acc_pending_accounts_v — tasdiq KUTAYOTGAN hisoblar (Maker-Checker)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW core_acc_pending_accounts_v AS
SELECT * FROM core_acc_accounts_ui_v
WHERE state = 'CREATED';

-- ----------------------------------------------------------------------------
-- 5. core_cif_statistics_i_v — dashboard statistikasi (1 qator, real schema)
--    Eski demo dashboard.jsp shu view'ni so'raydi — real core_cif_clients ustida.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW core_cif_statistics_i_v AS
SELECT
    (SELECT COUNT(*) FROM core_cif_clients)                                      AS total_customers,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_kind = 'P')             AS individual_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_kind IN ('J','I'))      AS corporate_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_status = 'CREATED')     AS pending_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_status = 'APPROVED')    AS active_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_status = 'BLOCKED')     AS blocked_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE client_status IN ('CLOSED','ARCHIVED','DELETED')) AS closed_count,
    (SELECT COUNT(*) FROM core_cif_clients WHERE aml_risk_level = 'HIGH')       AS high_risk_count,
    0                                                                           AS pep_count,
    (SELECT COUNT(*) FROM core_cif_documents)                                   AS total_documents,
    0                                                                           AS expired_documents,
    (SELECT COUNT(*) FROM core_cif_contacts)                                    AS total_contacts
FROM dual;

-- ============================================================================
-- 50_views.sql — tugadi.
-- ============================================================================
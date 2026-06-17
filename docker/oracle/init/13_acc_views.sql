-- ============================================================================
-- MARS ABS - core_acc moduli
-- 13_acc_views.sql - View'lar
-- Asoslanadi: TZ-002
-- Sana: 2026-06-17
--
-- Qoidalar: V-1 (WITH READ ONLY), V-2 (aniq ustunlar), N-7 (_ui_v / _i_v)
-- ============================================================================


-- ==========================================================================
-- 1. core_acc_accounts_ui_v - asosiy ro'yxat (SCR-001)
--    Mijoz nomi core_cif_customers'dan (display_name)
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_accounts_ui_v AS
SELECT a.account_id,
       a.account_number,
       a.customer_id,
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
       a.account_type,
       a.currency,
       a.balance,
       a.status,
       a.branch_code,
       a.opened_at
  FROM core_acc_accounts a
  JOIN core_cif_customers c ON c.customer_id = a.customer_id
WITH READ ONLY;


-- ==========================================================================
-- 2. core_acc_active_accounts_ui_v - faqat ACTIVE (operator ish ekrani)
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_active_accounts_ui_v AS
SELECT a.account_id,
       a.account_number,
       a.customer_id,
       c.customer_type,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || SUBSTR(c.first_name, 1, 1) || '.'
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       a.account_type,
       a.currency,
       a.balance,
       a.available_balance,
       a.branch_code,
       a.opened_at
  FROM core_acc_accounts a
  JOIN core_cif_customers c ON c.customer_id = a.customer_id
 WHERE a.status = 'ACTIVE'
WITH READ ONLY;


-- ==========================================================================
-- 3. core_acc_pending_accounts_ui_v - PENDING (Maker-Checker)
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_pending_accounts_ui_v AS
SELECT a.account_id,
       a.account_number,
       a.customer_id,
       c.customer_type,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || c.first_name
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       a.account_type,
       a.currency,
       a.balance,
       a.status,
       a.created_by,
       a.created_at,
       ROUND((SYSDATE - CAST(a.created_at AS DATE)) * 24, 1) AS waiting_hours
  FROM core_acc_accounts a
  JOIN core_cif_customers c ON c.customer_id = a.customer_id
 WHERE a.status = 'PENDING'
WITH READ ONLY;


-- ==========================================================================
-- 4. core_acc_account_detail_i_v - to'liq tafsilot (SCR-003)
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_account_detail_i_v AS
SELECT a.account_id,
       a.account_number,
       a.customer_id,
       c.cif_number,
       c.customer_type,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || c.first_name
               || CASE WHEN c.middle_name IS NOT NULL THEN ' ' || c.middle_name END
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_full_name
       END AS customer_name,
       c.phone AS customer_phone,
       a.account_type,
       a.currency,
       a.gl_code,
       a.account_name,
       a.status,
       a.balance,
       a.available_balance,
       a.min_balance,
       a.daily_limit,
       a.monthly_limit,
       a.interest_rate,
       a.branch_code,
       a.opened_at,
       a.last_activity_at,
       a.closed_at,
       a.close_reason,
       a.approved_by,
       a.approved_at,
       a.created_by,
       a.created_at,
       a.updated_by,
       a.updated_at
  FROM core_acc_accounts a
  JOIN core_cif_customers c ON c.customer_id = a.customer_id
WITH READ ONLY;


-- ==========================================================================
-- 5. core_acc_dormant_accounts_ui_v - harakatsiz hisoblar (RPT-005)
--    90 kundan beri operatsiya bo'lmagan ACTIVE hisoblar
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_dormant_accounts_ui_v AS
SELECT a.account_id,
       a.account_number,
       a.customer_id,
       CASE
           WHEN c.customer_type = 'INDIVIDUAL' THEN
               c.last_name || ' ' || SUBSTR(c.first_name, 1, 1) || '.'
           WHEN c.customer_type = 'CORPORATE' THEN
               c.org_name
       END AS display_name,
       a.account_type,
       a.currency,
       a.balance,
       a.last_activity_at,
       a.opened_at,
       ROUND(SYSDATE - CAST(NVL(a.last_activity_at, a.opened_at) AS DATE)) AS idle_days
  FROM core_acc_accounts a
  JOIN core_cif_customers c ON c.customer_id = a.customer_id
 WHERE a.status = 'ACTIVE'
   AND NVL(a.last_activity_at, a.opened_at) < SYSTIMESTAMP - NUMTODSINTERVAL(90, 'DAY')
WITH READ ONLY;


-- ==========================================================================
-- 6. core_acc_currency_stats_v - valyuta bo'yicha statistika (RPT-003)
-- ==========================================================================
CREATE OR REPLACE VIEW core_acc_currency_stats_v AS
SELECT a.currency,
       COUNT(*)            AS account_count,
       SUM(a.balance)      AS total_balance,
       ROUND(AVG(a.balance), 2) AS avg_balance,
       SUM(CASE WHEN a.status = 'ACTIVE' THEN 1 ELSE 0 END) AS active_count
  FROM core_acc_accounts a
 GROUP BY a.currency
WITH READ ONLY;

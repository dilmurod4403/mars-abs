-- ============================================================================
-- MARS ABS - core_cif moduli
-- 09_cif_additional_views.sql - Qo'shimcha view'lar (TZ-001)
-- Sana: 2026-05-26
--
-- Maqsad:
--   Hujjatlar, Kontaktlar, Audit log, Statistika,
--   Muddati o'tgan hujjatlar va PEP hisobotlari uchun view'lar
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
-- 1. core_cif_documents_ui_v — UI uchun hujjatlar ro'yxati
--    Mijoz display_name bilan hujjat ma'lumotlarini ko'rsatadi.
--    Computed: is_expired (Y/N), days_to_expiry
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_documents_ui_v AS
SELECT d.doc_id,
       d.customer_id,
       c.cif_number,
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
       END AS customer_display_name,
       d.doc_type,
       d.doc_series,
       d.doc_number,
       d.issued_by,
       d.issued_date,
       d.expiry_date,
       d.is_primary,
       -- Muddati o'tganmi?
       CASE
           WHEN d.expiry_date < TRUNC(SYSDATE) THEN 'Y'
           ELSE 'N'
       END AS is_expired,
       -- Muddatgacha qolgan kunlar (expiry_date bo'lmasa NULL)
       CASE
           WHEN d.expiry_date IS NOT NULL
           THEN TRUNC(d.expiry_date - SYSDATE)
       END AS days_to_expiry,
       d.created_at,
       d.created_by
  FROM core_cif_documents d
  JOIN core_cif_customers c ON c.customer_id = d.customer_id
WITH READ ONLY;


-- ==========================================================================
-- 2. core_cif_contacts_ui_v — UI uchun kontaktlar ro'yxati
--    Mijoz display_name bilan kontakt ma'lumotlarini ko'rsatadi.
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_contacts_ui_v AS
SELECT ct.contact_id,
       ct.customer_id,
       c.cif_number,
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
       END AS customer_display_name,
       ct.contact_type,
       ct.contact_value,
       ct.is_primary,
       ct.description,
       ct.created_at
  FROM core_cif_contacts ct
  JOIN core_cif_customers c ON c.customer_id = ct.customer_id
WITH READ ONLY;


-- ==========================================================================
-- 3. core_cif_audit_log_ui_v — UI uchun audit log ko'rinishi
--    Audit log yozuvlarini mijoz CIF raqami va display_name bilan
--    ko'rsatadi. O'zgarishlar tarixini kuzatish uchun.
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_audit_log_ui_v AS
SELECT al.log_id,
       al.customer_id,
       c.cif_number,
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
       END AS customer_display_name,
       al.action_type,
       al.field_name,
       al.old_value,
       al.new_value,
       al.changed_by,
       al.changed_at
  FROM core_cif_audit_log al
  JOIN core_cif_customers c ON c.customer_id = al.customer_id
WITH READ ONLY;


-- ==========================================================================
-- 4. core_cif_expired_docs_ui_v — Muddati o'tgan hujjatlar hisoboti
--    RPT-003 (BT-001). Compliance uchun — faqat ACTIVE/PENDING
--    mijozlarning muddati o'tgan hujjatlari.
--    Computed: days_expired (muddati o'tganidan beri kunlar)
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_expired_docs_ui_v AS
SELECT d.doc_id,
       d.customer_id,
       c.cif_number,
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
       END AS customer_display_name,
       c.status           AS customer_status,
       d.doc_type,
       d.doc_series,
       d.doc_number,
       d.issued_by,
       d.issued_date,
       d.expiry_date,
       -- Muddati o'tganidan beri necha kun
       TRUNC(SYSDATE - d.expiry_date) AS days_expired,
       c.customer_type,
       c.branch_code,
       c.phone
  FROM core_cif_documents d
  JOIN core_cif_customers c ON c.customer_id = d.customer_id
 WHERE d.expiry_date < TRUNC(SYSDATE)
   AND c.status IN ('ACTIVE', 'PENDING')
WITH READ ONLY;


-- ==========================================================================
-- 5. core_cif_statistics_i_v — Dashboard statistikasi (internal)
--    Bitta qator: jamlanma sonlar. GROUP BY yo'q — subquery'lar bilan.
--    Mijozlar, hujjatlar va kontaktlar bo'yicha umumiy ko'rsatkichlar.
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_statistics_i_v AS
SELECT
       -- Mijozlar soni
       (SELECT COUNT(1)
          FROM core_cif_customers)                             AS total_customers,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE customer_type = 'INDIVIDUAL')                   AS individual_count,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE customer_type = 'CORPORATE')                    AS corporate_count,
       -- Holatlar bo'yicha
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE status = 'PENDING')                             AS pending_count,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE status = 'ACTIVE')                              AS active_count,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE status = 'BLOCKED')                             AS blocked_count,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE status = 'CLOSED')                              AS closed_count,
       -- Risk va PEP
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE risk_category = 'HIGH')                         AS high_risk_count,
       (SELECT COUNT(1)
          FROM core_cif_customers
         WHERE is_pep = 'Y')                                   AS pep_count,
       -- Hujjatlar
       (SELECT COUNT(1)
          FROM core_cif_documents)                             AS total_documents,
       (SELECT COUNT(1)
          FROM core_cif_documents
         WHERE expiry_date < TRUNC(SYSDATE))                   AS expired_documents,
       -- Kontaktlar
       (SELECT COUNT(1)
          FROM core_cif_contacts)                              AS total_contacts
  FROM DUAL
WITH READ ONLY;


-- ==========================================================================
-- 6. core_cif_pep_customers_ui_v — PEP mijozlar hisoboti
--    RPT-006 (BT-001). Faqat is_pep = 'Y' bo'lgan mijozlar.
--    Compliance va AML monitoring uchun.
-- ==========================================================================
CREATE OR REPLACE VIEW core_cif_pep_customers_ui_v AS
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
       c.pinfl,
       c.inn,
       c.phone,
       c.risk_category,
       c.status,
       c.branch_code,
       c.created_by,
       c.created_at
  FROM core_cif_customers c
 WHERE c.is_pep = 'Y'
WITH READ ONLY;

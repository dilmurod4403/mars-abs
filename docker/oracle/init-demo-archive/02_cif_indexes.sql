-- ============================================================================
-- MARS ABS - core_cif moduli
-- 02_cif_indexes.sql - Indekslar
-- Sana: 2026-05-26
-- ============================================================================
-- UNIQUE indekslar UNIQUE constraint orqali avtomatik yaratiladi:
--   core_cif_customers_cif_uk   (cif_number)
--   core_cif_customers_pinfl_uk (pinfl)
--   core_cif_customers_inn_uk   (inn)
-- Quyida NON-UNIQUE indekslar:

-- FIO bo'yicha qidiruv (FYaSh)
CREATE INDEX core_cif_customers_name_idx
    ON core_cif_customers (last_name, first_name);

-- Tashkilot nomi bo'yicha qidiruv (YuSh)
CREATE INDEX core_cif_customers_org_idx
    ON core_cif_customers (org_name);

-- Telefon bo'yicha qidiruv
CREATE INDEX core_cif_customers_phone_idx
    ON core_cif_customers (phone);

-- Status bo'yicha filtrlash
CREATE INDEX core_cif_customers_status_idx
    ON core_cif_customers (status);

-- Filial bo'yicha filtrlash
CREATE INDEX core_cif_customers_branch_idx
    ON core_cif_customers (branch_code);

-- Maker-Checker: PENDING holatdagilarni topish uchun
CREATE INDEX core_cif_customers_approved_idx
    ON core_cif_customers (status, approved_by);

-- Hujjatlar: mijoz bo'yicha tez qidiruv
CREATE INDEX core_cif_documents_cust_idx
    ON core_cif_documents (customer_id);

-- Hujjatlar: muddati o'tayotganlarni topish
CREATE INDEX core_cif_documents_expiry_idx
    ON core_cif_documents (expiry_date);

-- Kontaktlar: mijoz bo'yicha tez qidiruv
CREATE INDEX core_cif_contacts_cust_idx
    ON core_cif_contacts (customer_id);

-- Audit log: mijoz bo'yicha tarix
CREATE INDEX core_cif_audit_log_cust_idx
    ON core_cif_audit_log (customer_id);

-- Audit log: vaqt bo'yicha qidiruv
CREATE INDEX core_cif_audit_log_date_idx
    ON core_cif_audit_log (changed_at);

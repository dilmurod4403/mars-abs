-- ============================================================================
-- MARS ABS - core_cif moduli
-- 04_cif_triggers.sql - Triggerlar
-- Sana: 2026-05-26
-- Naming: N-2 (v_ prefix), N-3 (cr_ prefix)
-- ============================================================================

-- ==========================================================================
-- 1. core_cif_customers_bi_trg - CIF raqam avtomatik generatsiya
--    BEFORE INSERT trigger
--    Format: CIF-YYYYMMDD-NNNNNN
-- ==========================================================================
CREATE OR REPLACE TRIGGER core_cif_customers_bi_trg
    BEFORE INSERT ON core_cif_customers
    FOR EACH ROW
DECLARE
    v_seq_val   NUMBER;
BEGIN
    -- CIF raqam generatsiya (agar berilmagan bo'lsa)
    IF :NEW.cif_number IS NULL THEN
        SELECT core_cif_seq.NEXTVAL INTO v_seq_val FROM DUAL;
        :NEW.cif_number := 'CIF-'
            || TO_CHAR(SYSDATE, 'YYYYMMDD')
            || '-'
            || LPAD(TO_CHAR(v_seq_val), 6, '0');
    END IF;

    -- created_at ni SYSTIMESTAMP bilan to'ldirish
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/

-- ==========================================================================
-- 2. core_cif_customers_audit_trg - Audit log trigger
--    AFTER INSERT OR UPDATE trigger
--    Har bir INSERT/UPDATE da core_cif_audit_log ga yozadi
--    S-3: INSERT ustun ro'yxati bilan
-- ==========================================================================
CREATE OR REPLACE TRIGGER core_cif_customers_audit_trg
    AFTER INSERT OR UPDATE ON core_cif_customers
    FOR EACH ROW
DECLARE
    v_action    VARCHAR2(20);
    v_user      VARCHAR2(50);
BEGIN
    IF INSERTING THEN
        v_action := 'CREATE';
        v_user   := :NEW.created_by;

        INSERT INTO core_cif_audit_log (
            customer_id, action_type, field_name,
            old_value, new_value, changed_by, changed_at
        ) VALUES (
            :NEW.customer_id, v_action, NULL,
            NULL, 'Yangi mijoz yaratildi', v_user, SYSTIMESTAMP
        );

    ELSIF UPDATING THEN
        v_user := NVL(:NEW.updated_by, :NEW.created_by);

        -- Status o'zgarishini alohida log qilish
        IF NVL(:OLD.status, '~') != NVL(:NEW.status, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'STATUS_CHANGE', 'status',
                :OLD.status, :NEW.status, v_user, SYSTIMESTAMP
            );
        END IF;

        -- FIO o'zgarishini log qilish
        IF NVL(:OLD.first_name, '~') != NVL(:NEW.first_name, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'UPDATE', 'first_name',
                :OLD.first_name, :NEW.first_name, v_user, SYSTIMESTAMP
            );
        END IF;

        IF NVL(:OLD.last_name, '~') != NVL(:NEW.last_name, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'UPDATE', 'last_name',
                :OLD.last_name, :NEW.last_name, v_user, SYSTIMESTAMP
            );
        END IF;

        -- Telefon o'zgarishi
        IF NVL(:OLD.phone, '~') != NVL(:NEW.phone, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'UPDATE', 'phone',
                :OLD.phone, :NEW.phone, v_user, SYSTIMESTAMP
            );
        END IF;

        -- Risk category o'zgarishi
        IF NVL(:OLD.risk_category, '~') != NVL(:NEW.risk_category, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'UPDATE', 'risk_category',
                :OLD.risk_category, :NEW.risk_category, v_user, SYSTIMESTAMP
            );
        END IF;

        -- Manzil o'zgarishi
        IF NVL(:OLD.actual_address, '~') != NVL(:NEW.actual_address, '~') THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'UPDATE', 'actual_address',
                :OLD.actual_address, :NEW.actual_address, v_user, SYSTIMESTAMP
            );
        END IF;

        -- Tasdiqlash (approve)
        IF :OLD.approved_by IS NULL AND :NEW.approved_by IS NOT NULL THEN
            INSERT INTO core_cif_audit_log (
                customer_id, action_type, field_name,
                old_value, new_value, changed_by, changed_at
            ) VALUES (
                :NEW.customer_id, 'APPROVE', 'approved_by',
                NULL, :NEW.approved_by, v_user, SYSTIMESTAMP
            );
        END IF;
    END IF;
END;
/

-- ============================================================================
-- MARS ABS - core_acc moduli
-- 12_acc_packages.sql - PL/SQL paketlar (SIRIUS qatlam arxitekturasi) + trigger
-- Asoslanadi: TZ-002
-- Sana: 2026-06-17
--
-- Qatlamlar (L-1):
--   CONST -> TYPES -> UTIL -> LOGGER -> DATA_READER -> REPO -> RULES -> SERVICE
--   COMMIT/ROLLBACK faqat SERVICE qatlamda (E-5)
--   _service paketda o_code/o_message/o_ora_message majburiy (SC-1), boshida init (SC-2)
--
-- Trigger fayl oxirida (core_acc_util mavjud bo'lgandan keyin).
-- ============================================================================


-- *************************************************************************
-- 1. core_acc_const - konstantalar
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_const AS
    -- Statuslar
    c_status_pending    CONSTANT VARCHAR2(20) := 'PENDING';
    c_status_active     CONSTANT VARCHAR2(20) := 'ACTIVE';
    c_status_frozen     CONSTANT VARCHAR2(20) := 'FROZEN';
    c_status_blocked    CONSTANT VARCHAR2(20) := 'BLOCKED';
    c_status_closed     CONSTANT VARCHAR2(20) := 'CLOSED';
    c_status_rejected   CONSTANT VARCHAR2(20) := 'REJECTED';

    -- Hisob turlari
    c_type_current      CONSTANT VARCHAR2(20) := 'CURRENT';
    c_type_savings      CONSTANT VARCHAR2(20) := 'SAVINGS';
    c_type_deposit      CONSTANT VARCHAR2(20) := 'DEPOSIT';
    c_type_loan         CONSTANT VARCHAR2(20) := 'LOAN';
    c_type_special      CONSTANT VARCHAR2(20) := 'SPECIAL';

    -- Valyutalar
    c_ccy_uzs           CONSTANT VARCHAR2(3) := 'UZS';
    c_ccy_usd           CONSTANT VARCHAR2(3) := 'USD';
    c_ccy_eur           CONSTANT VARCHAR2(3) := 'EUR';

    -- Valyuta kodlari (3 xona) — BT-002
    c_ccy_code_uzs      CONSTANT VARCHAR2(3) := '000';
    c_ccy_code_usd      CONSTANT VARCHAR2(3) := '840';
    c_ccy_code_eur      CONSTANT VARCHAR2(3) := '978';

    -- Hisob turi kodlari (3 xona)
    c_typecode_current  CONSTANT VARCHAR2(3) := '001';
    c_typecode_savings  CONSTANT VARCHAR2(3) := '002';
    c_typecode_deposit  CONSTANT VARCHAR2(3) := '003';
    c_typecode_loan     CONSTANT VARCHAR2(3) := '004';
    c_typecode_special  CONSTANT VARCHAR2(3) := '005';

    -- GL (balans hisobi) kodlari (5 xona) — core_gl integratsiyada aniqlanadi
    c_gl_current        CONSTANT VARCHAR2(5) := '10101';
    c_gl_savings        CONSTANT VARCHAR2(5) := '10501';
    c_gl_deposit        CONSTANT VARCHAR2(5) := '10601';
    c_gl_loan           CONSTANT VARCHAR2(5) := '12401';
    c_gl_special        CONSTANT VARCHAR2(5) := '10901';

    -- Xato kodlari (E-7: -20000..-20999)
    c_err_customer_not_found    CONSTANT NUMBER := -20101;
    c_err_customer_not_active   CONSTANT NUMBER := -20102;
    c_err_invalid_status_change CONSTANT NUMBER := -20104;
    c_err_balance_not_zero      CONSTANT NUMBER := -20105;
    c_err_pending_trx           CONSTANT NUMBER := -20106;
    c_err_maker_equals_checker  CONSTANT NUMBER := -20107;
    c_err_account_not_found     CONSTANT NUMBER := -20108;
    c_err_not_pending           CONSTANT NUMBER := -20109;
    c_err_required_field        CONSTANT NUMBER := -20111;
    c_err_invalid_type          CONSTANT NUMBER := -20112;
    c_err_invalid_currency      CONSTANT NUMBER := -20113;

    -- Xato xabarlari
    c_msg_customer_not_found    CONSTANT VARCHAR2(200) := 'Mijoz topilmadi';
    c_msg_customer_not_active   CONSTANT VARCHAR2(200) := 'Mijoz FAOL holatda emas — hisob ochib bo''lmaydi';
    c_msg_invalid_status_change CONSTANT VARCHAR2(200) := 'Hisob holatini o''zgartirib bo''lmaydi';
    c_msg_balance_not_zero      CONSTANT VARCHAR2(200) := 'Hisob qoldig''i nolga teng emas — yopib bo''lmaydi';
    c_msg_pending_trx           CONSTANT VARCHAR2(200) := 'Kutilayotgan tranzaksiyalar mavjud';
    c_msg_maker_equals_checker  CONSTANT VARCHAR2(200) := 'Yaratuvchi va tasdiqlovchi bir xil bo''la olmaydi';
    c_msg_account_not_found     CONSTANT VARCHAR2(200) := 'Hisob topilmadi';
    c_msg_not_pending           CONSTANT VARCHAR2(200) := 'Hisob PENDING holatda emas';
    c_msg_required_field        CONSTANT VARCHAR2(200) := 'Majburiy maydon to''ldirilmagan';
    c_msg_invalid_type          CONSTANT VARCHAR2(200) := 'Hisob turi noto''g''ri';
    c_msg_invalid_currency      CONSTANT VARCHAR2(200) := 'Valyuta noto''g''ri';
    c_msg_ok                    CONSTANT VARCHAR2(10)  := 'OK';

    -- Umumiy kodlar
    c_code_ok           CONSTANT NUMBER := 0;
    c_code_error        CONSTANT NUMBER := -1;

    c_default_page_size CONSTANT NUMBER := 20;
END core_acc_const;
/


-- *************************************************************************
-- 2. core_acc_types - record type'lar
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_types AS
    TYPE t_account_rec IS RECORD (
        account_id          core_acc_accounts.account_id%TYPE,
        account_number      core_acc_accounts.account_number%TYPE,
        customer_id         core_acc_accounts.customer_id%TYPE,
        account_type        core_acc_accounts.account_type%TYPE,
        currency            core_acc_accounts.currency%TYPE,
        gl_code             core_acc_accounts.gl_code%TYPE,
        account_name        core_acc_accounts.account_name%TYPE,
        status              core_acc_accounts.status%TYPE,
        balance             core_acc_accounts.balance%TYPE,
        available_balance   core_acc_accounts.available_balance%TYPE,
        min_balance         core_acc_accounts.min_balance%TYPE,
        daily_limit         core_acc_accounts.daily_limit%TYPE,
        monthly_limit       core_acc_accounts.monthly_limit%TYPE,
        interest_rate       core_acc_accounts.interest_rate%TYPE,
        branch_code         core_acc_accounts.branch_code%TYPE,
        opened_at           core_acc_accounts.opened_at%TYPE,
        last_activity_at    core_acc_accounts.last_activity_at%TYPE,
        closed_at           core_acc_accounts.closed_at%TYPE,
        close_reason        core_acc_accounts.close_reason%TYPE,
        approved_by         core_acc_accounts.approved_by%TYPE,
        approved_at         core_acc_accounts.approved_at%TYPE,
        created_by          core_acc_accounts.created_by%TYPE,
        created_at          core_acc_accounts.created_at%TYPE,
        updated_by          core_acc_accounts.updated_by%TYPE,
        updated_at          core_acc_accounts.updated_at%TYPE
    );

    TYPE t_account_tab IS TABLE OF t_account_rec;
END core_acc_types;
/


-- *************************************************************************
-- 3. core_acc_util - pure funksiyalar (DML yo'q)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_util AS
    FUNCTION Get_Gl_Code(i_account_type IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION Get_Type_Code(i_account_type IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION Get_Currency_Code(i_currency IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION Calc_Control_Digit(i_digits IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION Generate_Account_Number(i_account_type IN VARCHAR2, i_currency IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION Is_Valid_Account_Number(i_num IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION Format_Account(i_num IN VARCHAR2) RETURN VARCHAR2;
END core_acc_util;
/

CREATE OR REPLACE PACKAGE BODY core_acc_util AS

    FUNCTION Get_Gl_Code(i_account_type IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE i_account_type
            WHEN core_acc_const.c_type_current THEN core_acc_const.c_gl_current
            WHEN core_acc_const.c_type_savings THEN core_acc_const.c_gl_savings
            WHEN core_acc_const.c_type_deposit THEN core_acc_const.c_gl_deposit
            WHEN core_acc_const.c_type_loan    THEN core_acc_const.c_gl_loan
            WHEN core_acc_const.c_type_special THEN core_acc_const.c_gl_special
            ELSE core_acc_const.c_gl_current
        END;
    END Get_Gl_Code;

    FUNCTION Get_Type_Code(i_account_type IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE i_account_type
            WHEN core_acc_const.c_type_current THEN core_acc_const.c_typecode_current
            WHEN core_acc_const.c_type_savings THEN core_acc_const.c_typecode_savings
            WHEN core_acc_const.c_type_deposit THEN core_acc_const.c_typecode_deposit
            WHEN core_acc_const.c_type_loan    THEN core_acc_const.c_typecode_loan
            WHEN core_acc_const.c_type_special THEN core_acc_const.c_typecode_special
            ELSE core_acc_const.c_typecode_current
        END;
    END Get_Type_Code;

    FUNCTION Get_Currency_Code(i_currency IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE i_currency
            WHEN core_acc_const.c_ccy_uzs THEN core_acc_const.c_ccy_code_uzs
            WHEN core_acc_const.c_ccy_usd THEN core_acc_const.c_ccy_code_usd
            WHEN core_acc_const.c_ccy_eur THEN core_acc_const.c_ccy_code_eur
            ELSE core_acc_const.c_ccy_code_uzs
        END;
    END Get_Currency_Code;

    -- Kontrol raqam: 7-3-1 vaznli MOD 10 (chapdan o'ngga)
    FUNCTION Calc_Control_Digit(i_digits IN VARCHAR2) RETURN VARCHAR2 IS
        v_sum       NUMBER := 0;
        v_weight    NUMBER;
        c_weights   CONSTANT VARCHAR2(3) := '731';
    BEGIN
        IF i_digits IS NULL THEN
            RETURN '0';
        END IF;
        FOR i IN 1 .. LENGTH(i_digits) LOOP
            v_weight := TO_NUMBER(SUBSTR(c_weights, MOD(i - 1, 3) + 1, 1));
            v_sum := v_sum + TO_NUMBER(SUBSTR(i_digits, i, 1)) * v_weight;
        END LOOP;
        RETURN TO_CHAR(MOD(v_sum, 10));
    END Calc_Control_Digit;

    -- 20 xonali raqam: GL(5)+TUR(3)+KONTROL(1)+TARTIB(8)+VALYUTA(3)
    FUNCTION Generate_Account_Number(i_account_type IN VARCHAR2, i_currency IN VARCHAR2) RETURN VARCHAR2 IS
        v_gl        VARCHAR2(5);
        v_type      VARCHAR2(3);
        v_ccy       VARCHAR2(3);
        v_seq       VARCHAR2(8);
        v_ctrl      VARCHAR2(1);
        v_seqval    NUMBER;
    BEGIN
        v_gl   := Get_Gl_Code(i_account_type);
        v_type := Get_Type_Code(i_account_type);
        v_ccy  := Get_Currency_Code(i_currency);
        SELECT core_acc_number_seq.NEXTVAL INTO v_seqval FROM DUAL;
        v_seq  := LPAD(TO_CHAR(v_seqval), 8, '0');
        v_ctrl := Calc_Control_Digit(v_gl || v_type || v_seq || v_ccy);
        RETURN v_gl || v_type || v_ctrl || v_seq || v_ccy;
    END Generate_Account_Number;

    FUNCTION Is_Valid_Account_Number(i_num IN VARCHAR2) RETURN BOOLEAN IS
        v_gl    VARCHAR2(5);
        v_type  VARCHAR2(3);
        v_ctrl  VARCHAR2(1);
        v_seq   VARCHAR2(8);
        v_ccy   VARCHAR2(3);
    BEGIN
        IF i_num IS NULL OR LENGTH(i_num) != 20 THEN
            RETURN FALSE;
        END IF;
        IF NOT REGEXP_LIKE(i_num, '^\d{20}$') THEN
            RETURN FALSE;
        END IF;
        v_gl   := SUBSTR(i_num, 1, 5);
        v_type := SUBSTR(i_num, 6, 3);
        v_ctrl := SUBSTR(i_num, 9, 1);
        v_seq  := SUBSTR(i_num, 10, 8);
        v_ccy  := SUBSTR(i_num, 18, 3);
        RETURN v_ctrl = Calc_Control_Digit(v_gl || v_type || v_seq || v_ccy);
    END Is_Valid_Account_Number;

    FUNCTION Format_Account(i_num IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF i_num IS NULL OR LENGTH(i_num) != 20 THEN
            RETURN i_num;
        END IF;
        RETURN SUBSTR(i_num, 1, 5) || ' ' || SUBSTR(i_num, 6, 3) || ' '
            || SUBSTR(i_num, 9, 1) || ' ' || SUBSTR(i_num, 10, 8) || ' '
            || SUBSTR(i_num, 18, 3);
    END Format_Account;

END core_acc_util;
/


-- *************************************************************************
-- 4. core_acc_logger - audit log (INSERT, COMMIT yo'q)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_logger AS
    PROCEDURE Log_Audit(
        i_account_id    IN NUMBER,
        i_action_type   IN VARCHAR2,
        i_field_name    IN VARCHAR2 DEFAULT NULL,
        i_old_value     IN VARCHAR2 DEFAULT NULL,
        i_new_value     IN VARCHAR2 DEFAULT NULL,
        i_reason        IN VARCHAR2 DEFAULT NULL,
        i_changed_by    IN VARCHAR2
    );

    PROCEDURE Find_By_Account(
        i_account_id    IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    );

    FUNCTION Count_By_Account(i_account_id IN NUMBER) RETURN NUMBER;
END core_acc_logger;
/

CREATE OR REPLACE PACKAGE BODY core_acc_logger AS

    PROCEDURE Log_Audit(
        i_account_id    IN NUMBER,
        i_action_type   IN VARCHAR2,
        i_field_name    IN VARCHAR2 DEFAULT NULL,
        i_old_value     IN VARCHAR2 DEFAULT NULL,
        i_new_value     IN VARCHAR2 DEFAULT NULL,
        i_reason        IN VARCHAR2 DEFAULT NULL,
        i_changed_by    IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO core_acc_audit_log (
            account_id, action_type, field_name,
            old_value, new_value, reason, changed_by, changed_at
        ) VALUES (
            i_account_id, i_action_type, i_field_name,
            i_old_value, i_new_value, i_reason, i_changed_by, SYSTIMESTAMP
        );
    END Log_Audit;

    PROCEDURE Find_By_Account(
        i_account_id    IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT log_id, account_id, action_type, field_name,
                   old_value, new_value, reason, changed_by, changed_at
              FROM core_acc_audit_log
             WHERE account_id = i_account_id
             ORDER BY changed_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_By_Account;

    FUNCTION Count_By_Account(i_account_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count
          FROM core_acc_audit_log
         WHERE account_id = i_account_id;
        RETURN v_count;
    END Count_By_Account;

END core_acc_logger;
/


-- *************************************************************************
-- 5. core_acc_data_reader - faqat SELECT
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_data_reader AS
    PROCEDURE Find_By_Id(
        i_id        IN  NUMBER,
        o_rec       OUT core_acc_types.t_account_rec,
        o_found     OUT BOOLEAN
    );

    PROCEDURE Find_By_Number(
        i_number    IN  VARCHAR2,
        o_rec       OUT core_acc_types.t_account_rec,
        o_found     OUT BOOLEAN
    );

    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    );

    PROCEDURE Find_All(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    );

    PROCEDURE Find_Pending(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    );

    -- Cross-module: mijoz holatini o'qish (core_cif_customers)
    FUNCTION Get_Customer_Status(i_customer_id IN NUMBER) RETURN VARCHAR2;

    -- Kutilayotgan tranzaksiya (core_trx — hozircha stub)
    FUNCTION Has_Pending_Trx(i_account_id IN NUMBER) RETURN BOOLEAN;

    FUNCTION Count_All RETURN NUMBER;
    FUNCTION Count_By_Status(i_status IN VARCHAR2) RETURN NUMBER;
END core_acc_data_reader;
/

CREATE OR REPLACE PACKAGE BODY core_acc_data_reader AS

    PROCEDURE Find_By_Id(
        i_id        IN  NUMBER,
        o_rec       OUT core_acc_types.t_account_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT account_id, account_number, customer_id, account_type, currency,
               gl_code, account_name, status, balance, available_balance,
               min_balance, daily_limit, monthly_limit, interest_rate, branch_code,
               opened_at, last_activity_at, closed_at, close_reason,
               approved_by, approved_at, created_by, created_at, updated_by, updated_at
          INTO o_rec.account_id, o_rec.account_number, o_rec.customer_id, o_rec.account_type, o_rec.currency,
               o_rec.gl_code, o_rec.account_name, o_rec.status, o_rec.balance, o_rec.available_balance,
               o_rec.min_balance, o_rec.daily_limit, o_rec.monthly_limit, o_rec.interest_rate, o_rec.branch_code,
               o_rec.opened_at, o_rec.last_activity_at, o_rec.closed_at, o_rec.close_reason,
               o_rec.approved_by, o_rec.approved_at, o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_acc_accounts
         WHERE account_id = i_id;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Id;

    PROCEDURE Find_By_Number(
        i_number    IN  VARCHAR2,
        o_rec       OUT core_acc_types.t_account_rec,
        o_found     OUT BOOLEAN
    ) IS
    BEGIN
        o_found := FALSE;
        SELECT account_id, account_number, customer_id, account_type, currency,
               gl_code, account_name, status, balance, available_balance,
               min_balance, daily_limit, monthly_limit, interest_rate, branch_code,
               opened_at, last_activity_at, closed_at, close_reason,
               approved_by, approved_at, created_by, created_at, updated_by, updated_at
          INTO o_rec.account_id, o_rec.account_number, o_rec.customer_id, o_rec.account_type, o_rec.currency,
               o_rec.gl_code, o_rec.account_name, o_rec.status, o_rec.balance, o_rec.available_balance,
               o_rec.min_balance, o_rec.daily_limit, o_rec.monthly_limit, o_rec.interest_rate, o_rec.branch_code,
               o_rec.opened_at, o_rec.last_activity_at, o_rec.closed_at, o_rec.close_reason,
               o_rec.approved_by, o_rec.approved_at, o_rec.created_by, o_rec.created_at, o_rec.updated_by, o_rec.updated_at
          FROM core_acc_accounts
         WHERE account_number = i_number;
        o_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_found := FALSE;
    END Find_By_Number;

    PROCEDURE Find_By_Customer(
        i_customer_id   IN  NUMBER,
        i_page          IN  NUMBER DEFAULT 1,
        i_page_size     IN  NUMBER DEFAULT 50,
        o_results       OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT account_id, account_number, account_type, currency,
                   balance, status, opened_at
              FROM core_acc_accounts
             WHERE customer_id = i_customer_id
             ORDER BY opened_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_By_Customer;

    PROCEDURE Find_All(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT account_id, account_number, customer_id, account_type,
                   currency, balance, status, branch_code, opened_at
              FROM core_acc_accounts
             ORDER BY opened_at DESC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_All;

    PROCEDURE Find_Pending(
        i_page      IN  NUMBER DEFAULT 1,
        i_page_size IN  NUMBER DEFAULT 20,
        o_results   OUT SYS_REFCURSOR
    ) IS
        v_offset    NUMBER;
    BEGIN
        v_offset := (i_page - 1) * i_page_size;
        OPEN o_results FOR
            SELECT account_id, account_number, customer_id, account_type,
                   currency, balance, status, created_by, created_at
              FROM core_acc_accounts
             WHERE status = core_acc_const.c_status_pending
             ORDER BY created_at ASC
            OFFSET v_offset ROWS FETCH NEXT i_page_size ROWS ONLY;
    END Find_Pending;

    FUNCTION Get_Customer_Status(i_customer_id IN NUMBER) RETURN VARCHAR2 IS
        v_status core_cif_customers.status%TYPE;
    BEGIN
        SELECT status INTO v_status
          FROM core_cif_customers
         WHERE customer_id = i_customer_id;
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END Get_Customer_Status;

    FUNCTION Has_Pending_Trx(i_account_id IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        -- core_trx moduli hali yo'q — kutilayotgan tranzaksiya yo'q deb hisoblanadi
        RETURN FALSE;
    END Has_Pending_Trx;

    FUNCTION Count_All RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count FROM core_acc_accounts;
        RETURN v_count;
    END Count_All;

    FUNCTION Count_By_Status(i_status IN VARCHAR2) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count
          FROM core_acc_accounts
         WHERE status = i_status;
        RETURN v_count;
    END Count_By_Status;

END core_acc_data_reader;
/


-- *************************************************************************
-- 6. core_acc_repo - faqat DML (COMMIT yo'q, E-5)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_repo AS
    PROCEDURE Insert_Account(io_rec IN OUT core_acc_types.t_account_rec);
    PROCEDURE Update_Account(i_rec IN core_acc_types.t_account_rec);
    PROCEDURE Change_Status(i_id IN NUMBER, i_status IN VARCHAR2, i_user IN VARCHAR2);
    PROCEDURE Set_Closed(i_id IN NUMBER, i_reason IN VARCHAR2, i_user IN VARCHAR2);
    PROCEDURE Approve(i_id IN NUMBER, i_approved_by IN VARCHAR2);
END core_acc_repo;
/

CREATE OR REPLACE PACKAGE BODY core_acc_repo AS

    PROCEDURE Insert_Account(io_rec IN OUT core_acc_types.t_account_rec) IS
    BEGIN
        -- Raqam va GL kodi generatsiya (S-3: ustun ro'yxati bilan)
        io_rec.account_number := core_acc_util.Generate_Account_Number(io_rec.account_type, io_rec.currency);
        io_rec.gl_code        := core_acc_util.Get_Gl_Code(io_rec.account_type);
        io_rec.status         := core_acc_const.c_status_pending;
        io_rec.opened_at      := SYSTIMESTAMP;

        INSERT INTO core_acc_accounts (
            account_number, customer_id, account_type, currency, gl_code, account_name,
            status, balance, available_balance, min_balance,
            daily_limit, monthly_limit, interest_rate, branch_code,
            opened_at, created_by, created_at
        ) VALUES (
            io_rec.account_number, io_rec.customer_id, io_rec.account_type, io_rec.currency, io_rec.gl_code, io_rec.account_name,
            io_rec.status, NVL(io_rec.balance, 0), NVL(io_rec.balance, 0), NVL(io_rec.min_balance, 0),
            io_rec.daily_limit, io_rec.monthly_limit, io_rec.interest_rate, io_rec.branch_code,
            io_rec.opened_at, io_rec.created_by, SYSTIMESTAMP
        ) RETURNING account_id INTO io_rec.account_id;
    END Insert_Account;

    PROCEDURE Update_Account(i_rec IN core_acc_types.t_account_rec) IS
    BEGIN
        -- Raqam, valyuta, tur, holat O'ZGARMAYDI (BP-002)
        UPDATE core_acc_accounts
           SET account_name   = i_rec.account_name,
               min_balance    = NVL(i_rec.min_balance, 0),
               daily_limit    = i_rec.daily_limit,
               monthly_limit  = i_rec.monthly_limit,
               interest_rate  = i_rec.interest_rate,
               updated_by     = i_rec.updated_by,
               updated_at     = SYSTIMESTAMP
         WHERE account_id = i_rec.account_id;
    END Update_Account;

    PROCEDURE Change_Status(i_id IN NUMBER, i_status IN VARCHAR2, i_user IN VARCHAR2) IS
    BEGIN
        UPDATE core_acc_accounts
           SET status     = i_status,
               updated_by = i_user,
               updated_at = SYSTIMESTAMP
         WHERE account_id = i_id;
    END Change_Status;

    PROCEDURE Set_Closed(i_id IN NUMBER, i_reason IN VARCHAR2, i_user IN VARCHAR2) IS
    BEGIN
        UPDATE core_acc_accounts
           SET status       = core_acc_const.c_status_closed,
               closed_at    = SYSTIMESTAMP,
               close_reason = i_reason,
               updated_by   = i_user,
               updated_at   = SYSTIMESTAMP
         WHERE account_id = i_id;
    END Set_Closed;

    PROCEDURE Approve(i_id IN NUMBER, i_approved_by IN VARCHAR2) IS
    BEGIN
        UPDATE core_acc_accounts
           SET status      = core_acc_const.c_status_active,
               approved_by = i_approved_by,
               approved_at = SYSTIMESTAMP,
               updated_by  = i_approved_by,
               updated_at  = SYSTIMESTAMP
         WHERE account_id = i_id
           AND status     = core_acc_const.c_status_pending;
    END Approve;

END core_acc_repo;
/


-- *************************************************************************
-- 7. core_acc_rules - validatsiya (DML yo'q, SC-2 init)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_rules AS
    PROCEDURE Check_Customer_Eligible(
        i_customer_id   IN  NUMBER,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    );

    PROCEDURE Validate_Open(
        i_rec       IN  core_acc_types.t_account_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    PROCEDURE Validate_Update(
        i_rec       IN  core_acc_types.t_account_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    );

    PROCEDURE Validate_Status_Change(
        i_current_status    IN VARCHAR2,
        i_new_status        IN VARCHAR2,
        o_code              OUT NUMBER,
        o_message           OUT VARCHAR2
    );

    PROCEDURE Validate_Close(
        i_account_id    IN  NUMBER,
        i_balance       IN  NUMBER,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    );

    PROCEDURE Validate_Approval(
        i_created_by    IN VARCHAR2,
        i_approved_by   IN VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    );
END core_acc_rules;
/

CREATE OR REPLACE PACKAGE BODY core_acc_rules AS

    PROCEDURE Check_Customer_Eligible(
        i_customer_id   IN  NUMBER,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    ) IS
        v_status    VARCHAR2(20);
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        IF i_customer_id IS NULL THEN
            o_code    := core_acc_const.c_err_required_field;
            o_message := core_acc_const.c_msg_required_field || ': customer_id';
            RETURN;
        END IF;

        -- DATA_READER orqali mijoz holatini o'qish (BR-001)
        v_status := core_acc_data_reader.Get_Customer_Status(i_customer_id);
        IF v_status IS NULL THEN
            o_code    := core_acc_const.c_err_customer_not_found;
            o_message := core_acc_const.c_msg_customer_not_found;
            RETURN;
        END IF;

        -- BR-001/BR-002: faqat FAOL (tasdiqlangan, KYC to'liq) mijozga ochiladi
        IF v_status != core_acc_const.c_status_active THEN
            o_code    := core_acc_const.c_err_customer_not_active;
            o_message := core_acc_const.c_msg_customer_not_active;
            RETURN;
        END IF;
    END Check_Customer_Eligible;

    PROCEDURE Validate_Open(
        i_rec       IN  core_acc_types.t_account_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        -- Hisob turi
        IF i_rec.account_type IS NULL THEN
            o_code    := core_acc_const.c_err_required_field;
            o_message := core_acc_const.c_msg_required_field || ': account_type';
            RETURN;
        END IF;
        IF i_rec.account_type NOT IN (core_acc_const.c_type_current, core_acc_const.c_type_savings,
                                      core_acc_const.c_type_deposit, core_acc_const.c_type_loan,
                                      core_acc_const.c_type_special) THEN
            o_code    := core_acc_const.c_err_invalid_type;
            o_message := core_acc_const.c_msg_invalid_type;
            RETURN;
        END IF;

        -- Valyuta
        IF i_rec.currency IS NULL THEN
            o_code    := core_acc_const.c_err_required_field;
            o_message := core_acc_const.c_msg_required_field || ': currency';
            RETURN;
        END IF;
        IF i_rec.currency NOT IN (core_acc_const.c_ccy_uzs, core_acc_const.c_ccy_usd, core_acc_const.c_ccy_eur) THEN
            o_code    := core_acc_const.c_err_invalid_currency;
            o_message := core_acc_const.c_msg_invalid_currency;
            RETURN;
        END IF;

        -- Filial
        IF i_rec.branch_code IS NULL THEN
            o_code    := core_acc_const.c_err_required_field;
            o_message := core_acc_const.c_msg_required_field || ': branch_code';
            RETURN;
        END IF;

        -- Mijoz mosligi (BR-001, BR-002)
        Check_Customer_Eligible(i_rec.customer_id, o_code, o_message);
        IF o_code != core_acc_const.c_code_ok THEN
            RETURN;
        END IF;
    END Validate_Open;

    PROCEDURE Validate_Update(
        i_rec       IN  core_acc_types.t_account_rec,
        o_code      OUT NUMBER,
        o_message   OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        IF i_rec.account_id IS NULL THEN
            o_code    := core_acc_const.c_err_account_not_found;
            o_message := core_acc_const.c_msg_account_not_found;
            RETURN;
        END IF;

        IF i_rec.min_balance IS NOT NULL AND i_rec.min_balance < 0 THEN
            o_code    := core_acc_const.c_err_required_field;
            o_message := 'Minimal qoldiq manfiy bo''lishi mumkin emas';
            RETURN;
        END IF;
    END Validate_Update;

    -- Holat o'tish matritsasi (BR-004):
    --   PENDING -> ACTIVE | REJECTED
    --   ACTIVE  -> FROZEN | BLOCKED | CLOSED
    --   FROZEN  -> ACTIVE | BLOCKED
    --   BLOCKED -> ACTIVE | CLOSED
    --   CLOSED/REJECTED -> (yo'q)
    PROCEDURE Validate_Status_Change(
        i_current_status    IN VARCHAR2,
        i_new_status        IN VARCHAR2,
        o_code              OUT NUMBER,
        o_message           OUT VARCHAR2
    ) IS
        v_valid     BOOLEAN := FALSE;
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        IF i_current_status = core_acc_const.c_status_pending
           AND i_new_status IN (core_acc_const.c_status_active, core_acc_const.c_status_rejected) THEN
            v_valid := TRUE;
        ELSIF i_current_status = core_acc_const.c_status_active
              AND i_new_status IN (core_acc_const.c_status_frozen, core_acc_const.c_status_blocked,
                                   core_acc_const.c_status_closed) THEN
            v_valid := TRUE;
        ELSIF i_current_status = core_acc_const.c_status_frozen
              AND i_new_status IN (core_acc_const.c_status_active, core_acc_const.c_status_blocked) THEN
            v_valid := TRUE;
        ELSIF i_current_status = core_acc_const.c_status_blocked
              AND i_new_status IN (core_acc_const.c_status_active, core_acc_const.c_status_closed) THEN
            v_valid := TRUE;
        END IF;

        IF NOT v_valid THEN
            o_code    := core_acc_const.c_err_invalid_status_change;
            o_message := core_acc_const.c_msg_invalid_status_change
                || ': ' || i_current_status || ' -> ' || i_new_status;
        END IF;
    END Validate_Status_Change;

    PROCEDURE Validate_Close(
        i_account_id    IN  NUMBER,
        i_balance       IN  NUMBER,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        -- BR-005: qoldiq 0 bo'lishi shart
        IF NVL(i_balance, 0) != 0 THEN
            o_code    := core_acc_const.c_err_balance_not_zero;
            o_message := core_acc_const.c_msg_balance_not_zero;
            RETURN;
        END IF;

        -- BR-006: kutilayotgan tranzaksiya bo'lmasligi shart
        IF core_acc_data_reader.Has_Pending_Trx(i_account_id) THEN
            o_code    := core_acc_const.c_err_pending_trx;
            o_message := core_acc_const.c_msg_pending_trx;
            RETURN;
        END IF;
    END Validate_Close;

    PROCEDURE Validate_Approval(
        i_created_by    IN VARCHAR2,
        i_approved_by   IN VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2
    ) IS
    BEGIN
        o_code    := core_acc_const.c_code_ok;
        o_message := core_acc_const.c_msg_ok;

        -- BR-013: Maker != Checker
        IF UPPER(i_created_by) = UPPER(i_approved_by) THEN
            o_code    := core_acc_const.c_err_maker_equals_checker;
            o_message := core_acc_const.c_msg_maker_equals_checker;
        END IF;
    END Validate_Approval;

END core_acc_rules;
/


-- *************************************************************************
-- 8. core_acc_service - biznes logika (COMMIT/ROLLBACK faqat shu yerda, E-5)
--    SC-1: o_code/o_message/o_ora_message; SC-2: boshida init
--    E-2: WHEN OTHERS -> ROLLBACK + o_code (NULL emas)
-- *************************************************************************
CREATE OR REPLACE PACKAGE core_acc_service AS
    PROCEDURE Open_Account(
        io_rec          IN OUT core_acc_types.t_account_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    PROCEDURE Update_Account(
        i_rec           IN  core_acc_types.t_account_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    PROCEDURE Change_Status(
        i_account_id    IN  NUMBER,
        i_new_status    IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    PROCEDURE Approve_Account(
        i_account_id    IN  NUMBER,
        i_approved_by   IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    PROCEDURE Reject_Account(
        i_account_id    IN  NUMBER,
        i_rejected_by   IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );

    PROCEDURE Close_Account(
        i_account_id    IN  NUMBER,
        i_reason        IN  VARCHAR2,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    );
END core_acc_service;
/

CREATE OR REPLACE PACKAGE BODY core_acc_service AS

    -- =======================================================================
    -- Open_Account: Validate -> REPO.Insert -> LOGGER -> COMMIT
    -- =======================================================================
    PROCEDURE Open_Account(
        io_rec          IN OUT core_acc_types.t_account_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
    BEGIN
        o_code        := core_acc_const.c_code_ok;
        o_message     := core_acc_const.c_msg_ok;
        o_ora_message := NULL;

        -- 1. RULES
        core_acc_rules.Validate_Open(io_rec, o_code, o_message);
        IF o_code != core_acc_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO
        core_acc_repo.Insert_Account(io_rec);

        -- 3. LOGGER
        core_acc_logger.Log_Audit(
            i_account_id => io_rec.account_id,
            i_action_type => 'CREATE',
            i_new_value   => 'Yangi hisob: ' || io_rec.account_number,
            i_changed_by  => io_rec.created_by
        );

        COMMIT;
        o_message := 'Hisob yaratildi: ' || io_rec.account_number;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_acc_const.c_code_error;
            o_message     := 'Hisob ochishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Open_Account;

    -- =======================================================================
    -- Update_Account
    -- =======================================================================
    PROCEDURE Update_Account(
        i_rec           IN  core_acc_types.t_account_rec,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_acc_types.t_account_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_acc_const.c_code_ok;
        o_message     := core_acc_const.c_msg_ok;
        o_ora_message := NULL;

        core_acc_data_reader.Find_By_Id(i_rec.account_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_acc_const.c_err_account_not_found;
            o_message := core_acc_const.c_msg_account_not_found;
            RETURN;
        END IF;

        core_acc_rules.Validate_Update(i_rec, o_code, o_message);
        IF o_code != core_acc_const.c_code_ok THEN
            RETURN;
        END IF;

        core_acc_repo.Update_Account(i_rec);

        core_acc_logger.Log_Audit(
            i_account_id  => i_rec.account_id,
            i_action_type => 'UPDATE',
            i_new_value   => 'Hisob parametrlari yangilandi',
            i_changed_by  => NVL(i_rec.updated_by, i_rec.created_by)
        );

        COMMIT;
        o_message := 'Hisob yangilandi';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_acc_const.c_code_error;
            o_message     := 'Hisob yangilashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Update_Account;

    -- =======================================================================
    -- Change_Status (CLOSED bo'lsa qoldiq tekshiruvi bilan)
    -- =======================================================================
    PROCEDURE Change_Status(
        i_account_id    IN  NUMBER,
        i_new_status    IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_acc_types.t_account_rec;
        v_found     BOOLEAN;
        v_action    VARCHAR2(20);
    BEGIN
        o_code        := core_acc_const.c_code_ok;
        o_message     := core_acc_const.c_msg_ok;
        o_ora_message := NULL;

        core_acc_data_reader.Find_By_Id(i_account_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_acc_const.c_err_account_not_found;
            o_message := core_acc_const.c_msg_account_not_found;
            RETURN;
        END IF;

        -- 1. RULES: o'tish matritsasi
        core_acc_rules.Validate_Status_Change(v_existing.status, i_new_status, o_code, o_message);
        IF o_code != core_acc_const.c_code_ok THEN
            RETURN;
        END IF;

        -- 2. REPO (CLOSED bo'lsa qoldiq tekshiruvi + close fields)
        IF i_new_status = core_acc_const.c_status_closed THEN
            core_acc_rules.Validate_Close(i_account_id, v_existing.balance, o_code, o_message);
            IF o_code != core_acc_const.c_code_ok THEN
                RETURN;
            END IF;
            core_acc_repo.Set_Closed(i_account_id, i_reason, i_user);
            v_action := 'CLOSE';
        ELSE
            core_acc_repo.Change_Status(i_account_id, i_new_status, i_user);
            v_action := 'STATUS_CHANGE';
        END IF;

        -- 3. LOGGER
        core_acc_logger.Log_Audit(
            i_account_id  => i_account_id,
            i_action_type => v_action,
            i_field_name  => 'status',
            i_old_value   => v_existing.status,
            i_new_value   => i_new_status,
            i_reason      => i_reason,
            i_changed_by  => i_user
        );

        COMMIT;
        o_message := 'Holat o''zgartirildi: ' || v_existing.status || ' -> ' || i_new_status;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_acc_const.c_code_error;
            o_message     := 'Holat o''zgartirishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Change_Status;

    -- =======================================================================
    -- Approve_Account: Maker-Checker PENDING -> ACTIVE
    -- =======================================================================
    PROCEDURE Approve_Account(
        i_account_id    IN  NUMBER,
        i_approved_by   IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_acc_types.t_account_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_acc_const.c_code_ok;
        o_message     := core_acc_const.c_msg_ok;
        o_ora_message := NULL;

        core_acc_data_reader.Find_By_Id(i_account_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_acc_const.c_err_account_not_found;
            o_message := core_acc_const.c_msg_account_not_found;
            RETURN;
        END IF;

        IF v_existing.status != core_acc_const.c_status_pending THEN
            o_code    := core_acc_const.c_err_not_pending;
            o_message := core_acc_const.c_msg_not_pending;
            RETURN;
        END IF;

        -- BR-013: Maker != Checker
        core_acc_rules.Validate_Approval(v_existing.created_by, i_approved_by, o_code, o_message);
        IF o_code != core_acc_const.c_code_ok THEN
            RETURN;
        END IF;

        core_acc_repo.Approve(i_account_id, i_approved_by);

        core_acc_logger.Log_Audit(
            i_account_id  => i_account_id,
            i_action_type => 'APPROVE',
            i_field_name  => 'status',
            i_old_value   => core_acc_const.c_status_pending,
            i_new_value   => core_acc_const.c_status_active,
            i_changed_by  => i_approved_by
        );

        COMMIT;
        o_message := 'Hisob tasdiqlandi: ' || v_existing.account_number;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_acc_const.c_code_error;
            o_message     := 'Tasdiqlashda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Approve_Account;

    -- =======================================================================
    -- Reject_Account: PENDING -> REJECTED
    -- =======================================================================
    PROCEDURE Reject_Account(
        i_account_id    IN  NUMBER,
        i_rejected_by   IN  VARCHAR2,
        i_reason        IN  VARCHAR2 DEFAULT NULL,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
        v_existing  core_acc_types.t_account_rec;
        v_found     BOOLEAN;
    BEGIN
        o_code        := core_acc_const.c_code_ok;
        o_message     := core_acc_const.c_msg_ok;
        o_ora_message := NULL;

        core_acc_data_reader.Find_By_Id(i_account_id, v_existing, v_found);
        IF NOT v_found THEN
            o_code    := core_acc_const.c_err_account_not_found;
            o_message := core_acc_const.c_msg_account_not_found;
            RETURN;
        END IF;

        IF v_existing.status != core_acc_const.c_status_pending THEN
            o_code    := core_acc_const.c_err_not_pending;
            o_message := core_acc_const.c_msg_not_pending;
            RETURN;
        END IF;

        core_acc_repo.Change_Status(i_account_id, core_acc_const.c_status_rejected, i_rejected_by);

        core_acc_logger.Log_Audit(
            i_account_id  => i_account_id,
            i_action_type => 'REJECT',
            i_field_name  => 'status',
            i_old_value   => core_acc_const.c_status_pending,
            i_new_value   => core_acc_const.c_status_rejected,
            i_reason      => i_reason,
            i_changed_by  => i_rejected_by
        );

        COMMIT;
        o_message := 'Hisob rad etildi: ' || v_existing.account_number;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code        := core_acc_const.c_code_error;
            o_message     := 'Rad etishda xatolik yuz berdi';
            o_ora_message := SUBSTR(SQLERRM, 1, 4000);
    END Reject_Account;

    -- =======================================================================
    -- Close_Account: Change_Status(CLOSED) wrapper (BP-005)
    -- =======================================================================
    PROCEDURE Close_Account(
        i_account_id    IN  NUMBER,
        i_reason        IN  VARCHAR2,
        i_user          IN  VARCHAR2,
        o_code          OUT NUMBER,
        o_message       OUT VARCHAR2,
        o_ora_message   OUT VARCHAR2
    ) IS
    BEGIN
        Change_Status(
            i_account_id  => i_account_id,
            i_new_status  => core_acc_const.c_status_closed,
            i_reason      => i_reason,
            i_user        => i_user,
            o_code        => o_code,
            o_message     => o_message,
            o_ora_message => o_ora_message
        );
        IF o_code = core_acc_const.c_code_ok THEN
            o_message := 'Hisob yopildi';
        END IF;
    END Close_Account;

END core_acc_service;
/


-- *************************************************************************
-- TRIGGER - hisob raqami/GL/default'lar (core_acc_util mavjud bo'lgach)
-- core_cif pattern: raqamni asosan REPO generatsiya qiladi; trigger zaxira
-- (to'g'ridan-to'g'ri INSERT, masalan seed, uchun).
-- Audit: SERVICE qatlamida core_acc_logger orqali (qo'sh log bo'lmasligi uchun
-- audit trigger ishlatilmaydi).
-- *************************************************************************
CREATE OR REPLACE TRIGGER core_acc_accounts_bi_trg
    BEFORE INSERT ON core_acc_accounts
    FOR EACH ROW
BEGIN
    IF :NEW.gl_code IS NULL THEN
        :NEW.gl_code := core_acc_util.Get_Gl_Code(:NEW.account_type);
    END IF;
    IF :NEW.account_number IS NULL THEN
        :NEW.account_number := core_acc_util.Generate_Account_Number(:NEW.account_type, :NEW.currency);
    END IF;
    IF :NEW.opened_at IS NULL THEN
        :NEW.opened_at := SYSTIMESTAMP;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    IF :NEW.available_balance IS NULL THEN
        :NEW.available_balance := NVL(:NEW.balance, 0);
    END IF;
END;
/

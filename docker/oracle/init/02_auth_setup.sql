-- gvenzl init (sqlplus / as sysdba, CDB-root) -> XEPDB1.BANKUSER. Manual load: no-op (USER<>SYS).
BEGIN
  IF USER = 'SYS' THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = XEPDB1';
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = BANKUSER';
  END IF;
END;
/
-- 15_auth_setup.sql — MARS ABS Autentifikatsiya va foydalanuvchilar
-- ============================================================================
-- MARS ABS - Autentifikatsiya moduli
-- 15_auth_setup.sql - Jadvallar, ko'rinishlar, paketlar va boshlang'ich ma'lumotlar
-- Modul: Foydalanuvchilar va autentifikatsiya (Authentication & Users)
-- Sana: 2026-06-14
-- ============================================================================

-- ==========================================================================
-- 1. core_users - Tizim foydalanuvchilari jadvali
--    Rollar: ADMIN, SUPERVISOR, OPERATOR
--    Status: ACTIVE, BLOCKED
-- ==========================================================================
CREATE TABLE core_users (
    user_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(50)   NOT NULL UNIQUE,
    password_hash   VARCHAR2(128)  NOT NULL,
    full_name       VARCHAR2(200)  NOT NULL,
    email           VARCHAR2(200),
    role            VARCHAR2(30)   NOT NULL,
    branch_code     VARCHAR2(10),
    status          VARCHAR2(20)   DEFAULT 'ACTIVE' NOT NULL,
    last_login_at   TIMESTAMP,
    login_attempts  NUMBER         DEFAULT 0,
    created_by      VARCHAR2(50),
    created_at      TIMESTAMP      DEFAULT SYSTIMESTAMP,
    updated_by      VARCHAR2(50),
    updated_at      TIMESTAMP,
    -- Cheklovlar
    CONSTRAINT chk_core_users_role   CHECK (role   IN ('ADMIN', 'SUPERVISOR', 'OPERATOR')),
    CONSTRAINT chk_core_users_status CHECK (status IN ('ACTIVE', 'BLOCKED'))
);

COMMENT ON TABLE  core_users                IS 'Tizim foydalanuvchilari';
COMMENT ON COLUMN core_users.user_id        IS 'Foydalanuvchi identifikatori (auto-increment)';
COMMENT ON COLUMN core_users.username       IS 'Login nomi (yagona)';
COMMENT ON COLUMN core_users.password_hash  IS 'Parol xeshi (SHA-256)';
COMMENT ON COLUMN core_users.full_name      IS 'F.I.Sh.';
COMMENT ON COLUMN core_users.email          IS 'Elektron pochta';
COMMENT ON COLUMN core_users.role           IS 'Roli: ADMIN, SUPERVISOR, OPERATOR';
COMMENT ON COLUMN core_users.branch_code    IS 'Filial kodi';
COMMENT ON COLUMN core_users.status         IS 'Holati: ACTIVE yoki BLOCKED';
COMMENT ON COLUMN core_users.last_login_at  IS 'Oxirgi kirish vaqti';
COMMENT ON COLUMN core_users.login_attempts IS 'Muvaffaqiyatsiz kirish urinishlari soni';
COMMENT ON COLUMN core_users.created_by     IS 'Yaratgan foydalanuvchi';
COMMENT ON COLUMN core_users.created_at     IS 'Yaratilgan vaqti';
COMMENT ON COLUMN core_users.updated_by     IS 'O''zgartirgan foydalanuvchi';
COMMENT ON COLUMN core_users.updated_at     IS 'O''zgartirilgan vaqti';

-- ==========================================================================
-- 2. core_auth_log - Autentifikatsiya loglari jadvali
--    Harakatlar: LOGIN_SUCCESS, LOGIN_FAIL, LOGOUT, PASSWORD_CHANGE
-- ==========================================================================
CREATE TABLE core_auth_log (
    log_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     NUMBER,
    username    VARCHAR2(50),
    action_type VARCHAR2(30),
    ip_address  VARCHAR2(50),
    details     VARCHAR2(500),
    created_at  TIMESTAMP DEFAULT SYSTIMESTAMP
);

COMMENT ON TABLE  core_auth_log             IS 'Autentifikatsiya loglari';
COMMENT ON COLUMN core_auth_log.log_id      IS 'Log yozuvi identifikatori';
COMMENT ON COLUMN core_auth_log.user_id     IS 'Foydalanuvchi identifikatori';
COMMENT ON COLUMN core_auth_log.username    IS 'Login nomi';
COMMENT ON COLUMN core_auth_log.action_type IS 'Harakat turi: LOGIN_SUCCESS, LOGIN_FAIL, LOGOUT, PASSWORD_CHANGE';
COMMENT ON COLUMN core_auth_log.ip_address  IS 'IP manzil';
COMMENT ON COLUMN core_auth_log.details     IS 'Qo''shimcha tafsilotlar';
COMMENT ON COLUMN core_auth_log.created_at  IS 'Yozuv yaratilgan vaqti';

-- ==========================================================================
-- 3. core_users_ui_v - Foydalanuvchilar ko'rinishi (UI uchun)
--    Barcha aktiv foydalanuvchilar (o'chirilmaganlar)
-- ==========================================================================
CREATE OR REPLACE VIEW core_users_ui_v AS
SELECT
    user_id,
    username,
    full_name,
    email,
    role,
    branch_code,
    status,
    last_login_at,
    login_attempts,
    created_by,
    created_at
FROM core_users;

COMMENT ON TABLE core_users_ui_v IS 'Foydalanuvchilar ro''yxati - UI uchun ko''rinish';

-- ==========================================================================
-- 4. core_auth_service - Autentifikatsiya paketi (spetsifikatsiya)
--    Protseduralar: Authenticate_User, Create_User, Update_User,
--                   Reset_Password, Change_Password
-- ==========================================================================
CREATE OR REPLACE PACKAGE core_auth_service AS

    -- Foydalanuvchini autentifikatsiya qilish
    PROCEDURE Authenticate_User(
        i_username    IN  VARCHAR2,
        i_password    IN  VARCHAR2,
        o_user_id     OUT NUMBER,
        o_full_name   OUT VARCHAR2,
        o_role        OUT VARCHAR2,
        o_branch_code OUT VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    );

    -- Yangi foydalanuvchi yaratish
    PROCEDURE Create_User(
        i_username    IN  VARCHAR2,
        i_password    IN  VARCHAR2,
        i_full_name   IN  VARCHAR2,
        i_email       IN  VARCHAR2,
        i_role        IN  VARCHAR2,
        i_branch_code IN  VARCHAR2,
        i_created_by  IN  VARCHAR2,
        o_user_id     OUT NUMBER,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    );

    -- Foydalanuvchi ma'lumotlarini yangilash
    PROCEDURE Update_User(
        i_user_id     IN  NUMBER,
        i_full_name   IN  VARCHAR2,
        i_email       IN  VARCHAR2,
        i_role        IN  VARCHAR2,
        i_branch_code IN  VARCHAR2,
        i_status      IN  VARCHAR2,
        i_updated_by  IN  VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    );

    -- Parolni tiklash (administrator tomonidan)
    PROCEDURE Reset_Password(
        i_user_id      IN  NUMBER,
        i_new_password IN  VARCHAR2,
        i_updated_by   IN  VARCHAR2,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2
    );

    -- Parolni o'zgartirish (foydalanuvchi o'zi)
    PROCEDURE Change_Password(
        i_user_id      IN  NUMBER,
        i_old_password IN  VARCHAR2,
        i_new_password IN  VARCHAR2,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2
    );

END core_auth_service;
/

-- ==========================================================================
-- 4b. core_auth_service - Autentifikatsiya paketi (tanasi)
-- ==========================================================================
CREATE OR REPLACE PACKAGE BODY core_auth_service AS

    -- ======================================================================
    -- Authenticate_User — Foydalanuvchini tizimga kiritish
    -- Login va parolni tekshiradi, muvaffaqiyatsiz urinishlarni hisoblaydi,
    -- 5 ta muvaffaqiyatsiz urinishdan keyin hisobni bloklaydi
    -- ======================================================================
    PROCEDURE Authenticate_User(
        i_username    IN  VARCHAR2,
        i_password    IN  VARCHAR2,
        o_user_id     OUT NUMBER,
        o_full_name   OUT VARCHAR2,
        o_role        OUT VARCHAR2,
        o_branch_code OUT VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    ) IS
        v_password_hash  VARCHAR2(128);
        v_stored_hash    VARCHAR2(128);
        v_status         VARCHAR2(20);
        v_login_attempts NUMBER;
    BEGIN
        -- Parol xeshini hisoblash (STANDARD_HASH faqat SQL kontekstda)
        SELECT RAWTOHEX(STANDARD_HASH(i_password, 'SHA256')) INTO v_password_hash FROM DUAL;

        -- Foydalanuvchini qidirish
        BEGIN
            SELECT user_id, full_name, role, branch_code,
                   password_hash, status, login_attempts
              INTO o_user_id, o_full_name, o_role, o_branch_code,
                   v_stored_hash, v_status, v_login_attempts
              FROM core_users
             WHERE username = i_username;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Foydalanuvchi topilmadi
                INSERT INTO core_auth_log (username, action_type, details)
                VALUES (i_username, 'LOGIN_FAIL', 'Foydalanuvchi topilmadi');
                COMMIT;

                o_user_id := NULL;
                o_code    := 1;
                o_message := 'Foydalanuvchi topilmadi yoki parol noto''g''ri';
                RETURN;
        END;

        -- Bloklangan foydalanuvchini tekshirish
        IF v_status = 'BLOCKED' THEN
            INSERT INTO core_auth_log (user_id, username, action_type, details)
            VALUES (o_user_id, i_username, 'LOGIN_FAIL', 'Hisob bloklangan');
            COMMIT;

            o_user_id := NULL;
            o_code    := 1;
            o_message := 'Foydalanuvchi hisobi bloklangan. Administratorga murojaat qiling';
            RETURN;
        END IF;

        -- Parolni tekshirish
        IF v_stored_hash = v_password_hash THEN
            -- Muvaffaqiyatli kirish
            UPDATE core_users
               SET login_attempts = 0,
                   last_login_at  = SYSTIMESTAMP
             WHERE user_id = o_user_id;

            INSERT INTO core_auth_log (user_id, username, action_type, details)
            VALUES (o_user_id, i_username, 'LOGIN_SUCCESS', 'Muvaffaqiyatli kirish');
            COMMIT;

            o_code    := 0;
            o_message := 'Muvaffaqiyatli';
        ELSE
            -- Parol noto'g'ri
            v_login_attempts := v_login_attempts + 1;

            IF v_login_attempts >= 5 THEN
                -- Hisobni bloklash
                UPDATE core_users
                   SET login_attempts = v_login_attempts,
                       status         = 'BLOCKED',
                       updated_at     = SYSTIMESTAMP
                 WHERE user_id = o_user_id;

                INSERT INTO core_auth_log (user_id, username, action_type, details)
                VALUES (o_user_id, i_username, 'LOGIN_FAIL',
                        'Parol noto''g''ri. Hisob bloklandi (5 ta muvaffaqiyatsiz urinish)');
                COMMIT;

                o_user_id := NULL;
                o_code    := 1;
                o_message := 'Hisob bloklangan: 5 ta muvaffaqiyatsiz urinish. Administratorga murojaat qiling';
            ELSE
                -- Urinishlar sonini oshirish
                UPDATE core_users
                   SET login_attempts = v_login_attempts,
                       updated_at     = SYSTIMESTAMP
                 WHERE user_id = o_user_id;

                INSERT INTO core_auth_log (user_id, username, action_type, details)
                VALUES (o_user_id, i_username, 'LOGIN_FAIL',
                        'Parol noto''g''ri. Urinishlar: ' || v_login_attempts || '/5');
                COMMIT;

                o_user_id := NULL;
                o_code    := 1;
                o_message := 'Foydalanuvchi topilmadi yoki parol noto''g''ri';
            END IF;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code    := 1;
            o_message := 'Tizim xatosi: ' || SQLERRM;
    END Authenticate_User;

    -- ======================================================================
    -- Create_User — Yangi foydalanuvchi yaratish
    -- Username, parol va rolni tekshiradi, parolni xeshlab saqlaydi
    -- ======================================================================
    PROCEDURE Create_User(
        i_username    IN  VARCHAR2,
        i_password    IN  VARCHAR2,
        i_full_name   IN  VARCHAR2,
        i_email       IN  VARCHAR2,
        i_role        IN  VARCHAR2,
        i_branch_code IN  VARCHAR2,
        i_created_by  IN  VARCHAR2,
        o_user_id     OUT NUMBER,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    ) IS
        v_count         NUMBER;
        v_password_hash VARCHAR2(128);
    BEGIN
        -- Username bo'shligini tekshirish
        IF i_username IS NULL OR TRIM(i_username) IS NULL THEN
            o_code    := 1;
            o_message := 'Username bo''sh bo''lishi mumkin emas';
            RETURN;
        END IF;

        -- Parol uzunligini tekshirish (kamida 6 belgi)
        IF i_password IS NULL OR LENGTH(i_password) < 6 THEN
            o_code    := 1;
            o_message := 'Parol kamida 6 belgidan iborat bo''lishi kerak';
            RETURN;
        END IF;

        -- Rolni tekshirish
        IF i_role NOT IN ('ADMIN', 'SUPERVISOR', 'OPERATOR') THEN
            o_code    := 1;
            o_message := 'Noto''g''ri rol. Ruxsat etilgan rollar: ADMIN, SUPERVISOR, OPERATOR';
            RETURN;
        END IF;

        -- Username yagonaligini tekshirish
        SELECT COUNT(*)
          INTO v_count
          FROM core_users
         WHERE username = i_username;

        IF v_count > 0 THEN
            o_code    := 1;
            o_message := 'Bu username allaqachon mavjud: ' || i_username;
            RETURN;
        END IF;

        -- Parol xeshini hisoblash
        SELECT RAWTOHEX(STANDARD_HASH(i_password, 'SHA256')) INTO v_password_hash FROM DUAL;

        -- Foydalanuvchini qo'shish
        INSERT INTO core_users (
            username, password_hash, full_name, email,
            role, branch_code, created_by
        ) VALUES (
            i_username,
            v_password_hash,
            i_full_name,
            i_email,
            i_role,
            i_branch_code,
            i_created_by
        ) RETURNING user_id INTO o_user_id;

        COMMIT;

        o_code    := 0;
        o_message := 'Foydalanuvchi muvaffaqiyatli yaratildi';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code    := 1;
            o_message := 'Foydalanuvchi yaratishda xato: ' || SQLERRM;
    END Create_User;

    -- ======================================================================
    -- Update_User — Foydalanuvchi ma'lumotlarini yangilash
    -- Parol va username o'zgartirilmaydi
    -- ======================================================================
    PROCEDURE Update_User(
        i_user_id     IN  NUMBER,
        i_full_name   IN  VARCHAR2,
        i_email       IN  VARCHAR2,
        i_role        IN  VARCHAR2,
        i_branch_code IN  VARCHAR2,
        i_status      IN  VARCHAR2,
        i_updated_by  IN  VARCHAR2,
        o_code        OUT NUMBER,
        o_message     OUT VARCHAR2
    ) IS
        v_count NUMBER;
    BEGIN
        -- Foydalanuvchi mavjudligini tekshirish
        SELECT COUNT(*)
          INTO v_count
          FROM core_users
         WHERE user_id = i_user_id;

        IF v_count = 0 THEN
            o_code    := 1;
            o_message := 'Foydalanuvchi topilmadi: ID=' || i_user_id;
            RETURN;
        END IF;

        -- Ma'lumotlarni yangilash
        UPDATE core_users
           SET full_name   = i_full_name,
               email       = i_email,
               role        = i_role,
               branch_code = i_branch_code,
               status      = i_status,
               updated_by  = i_updated_by,
               updated_at  = SYSTIMESTAMP
         WHERE user_id = i_user_id;

        COMMIT;

        o_code    := 0;
        o_message := 'Foydalanuvchi ma''lumotlari yangilandi';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code    := 1;
            o_message := 'Foydalanuvchini yangilashda xato: ' || SQLERRM;
    END Update_User;

    -- ======================================================================
    -- Reset_Password — Parolni tiklash (administrator tomonidan)
    -- Login urinishlarini nolga tushiradi, statusni ACTIVE qiladi
    -- ======================================================================
    PROCEDURE Reset_Password(
        i_user_id      IN  NUMBER,
        i_new_password IN  VARCHAR2,
        i_updated_by   IN  VARCHAR2,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2
    ) IS
        v_count         NUMBER;
        v_username      VARCHAR2(50);
        v_password_hash VARCHAR2(128);
    BEGIN
        -- Parol uzunligini tekshirish
        IF i_new_password IS NULL OR LENGTH(i_new_password) < 6 THEN
            o_code    := 1;
            o_message := 'Yangi parol kamida 6 belgidan iborat bo''lishi kerak';
            RETURN;
        END IF;

        -- Foydalanuvchi mavjudligini tekshirish
        BEGIN
            SELECT username
              INTO v_username
              FROM core_users
             WHERE user_id = i_user_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_code    := 1;
                o_message := 'Foydalanuvchi topilmadi: ID=' || i_user_id;
                RETURN;
        END;

        -- Parol xeshini hisoblash
        SELECT RAWTOHEX(STANDARD_HASH(i_new_password, 'SHA256')) INTO v_password_hash FROM DUAL;

        -- Parolni yangilash, urinishlarni nolga tushirish, statusni ACTIVE qilish
        UPDATE core_users
           SET password_hash  = v_password_hash,
               login_attempts = 0,
               status         = 'ACTIVE',
               updated_by     = i_updated_by,
               updated_at     = SYSTIMESTAMP
         WHERE user_id = i_user_id;

        -- Logga yozish
        INSERT INTO core_auth_log (user_id, username, action_type, details)
        VALUES (i_user_id, v_username, 'PASSWORD_CHANGE',
                'Parol tiklandi. Amalga oshiruvchi: ' || i_updated_by);

        COMMIT;

        o_code    := 0;
        o_message := 'Parol muvaffaqiyatli tiklandi';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code    := 1;
            o_message := 'Parolni tiklashda xato: ' || SQLERRM;
    END Reset_Password;

    -- ======================================================================
    -- Change_Password — Parolni o'zgartirish (foydalanuvchi o'zi)
    -- Eski parolni tekshiradi, yangi parolni saqlaydi
    -- ======================================================================
    PROCEDURE Change_Password(
        i_user_id      IN  NUMBER,
        i_old_password IN  VARCHAR2,
        i_new_password IN  VARCHAR2,
        o_code         OUT NUMBER,
        o_message      OUT VARCHAR2
    ) IS
        v_stored_hash VARCHAR2(128);
        v_old_hash    VARCHAR2(128);
        v_username    VARCHAR2(50);
    BEGIN
        -- Eski parol xeshini hisoblash (SQL kontekstda)
        SELECT RAWTOHEX(STANDARD_HASH(i_old_password, 'SHA256')) INTO v_old_hash FROM DUAL;

        -- Foydalanuvchini topish va parolni tekshirish
        BEGIN
            SELECT password_hash, username
              INTO v_stored_hash, v_username
              FROM core_users
             WHERE user_id = i_user_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_code    := 1;
                o_message := 'Foydalanuvchi topilmadi: ID=' || i_user_id;
                RETURN;
        END;

        -- Eski parolni tekshirish
        IF v_stored_hash != v_old_hash THEN
            o_code    := 1;
            o_message := 'Joriy parol noto''g''ri';
            RETURN;
        END IF;

        -- Yangi parol uzunligini tekshirish
        IF i_new_password IS NULL OR LENGTH(i_new_password) < 6 THEN
            o_code    := 1;
            o_message := 'Yangi parol kamida 6 belgidan iborat bo''lishi kerak';
            RETURN;
        END IF;

        -- Yangi parol xeshini hisoblash
        SELECT RAWTOHEX(STANDARD_HASH(i_new_password, 'SHA256')) INTO v_old_hash FROM DUAL;

        -- Parolni yangilash
        UPDATE core_users
           SET password_hash = v_old_hash,
               updated_at    = SYSTIMESTAMP
         WHERE user_id = i_user_id;

        -- Logga yozish
        INSERT INTO core_auth_log (user_id, username, action_type, details)
        VALUES (i_user_id, v_username, 'PASSWORD_CHANGE',
                'Parol foydalanuvchi tomonidan o''zgartirildi');

        COMMIT;

        o_code    := 0;
        o_message := 'Parol muvaffaqiyatli o''zgartirildi';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_code    := 1;
            o_message := 'Parolni o''zgartirishda xato: ' || SQLERRM;
    END Change_Password;

END core_auth_service;
/

-- ==========================================================================
-- 5. Boshlang'ich ma'lumotlar - Standart foydalanuvchilar
--    Parollar SHA-256 xesh bilan saqlanadi
-- ==========================================================================

-- admin / Admin@123 / ADMIN / Administrator
INSERT INTO core_users (username, password_hash, full_name, email, role, branch_code, created_by)
SELECT 'admin', RAWTOHEX(STANDARD_HASH('Admin@123', 'SHA256')),
       'Administrator', 'admin@fidobank.uz', 'ADMIN', NULL, 'SYSTEM' FROM DUAL;

-- supervisor / Super@123 / SUPERVISOR / Nazoratchi
INSERT INTO core_users (username, password_hash, full_name, email, role, branch_code, created_by)
SELECT 'supervisor', RAWTOHEX(STANDARD_HASH('Super@123', 'SHA256')),
       'Nazoratchi', NULL, 'SUPERVISOR', '00191', 'SYSTEM' FROM DUAL;

-- operator1 / Oper@123 / OPERATOR / Operator Aliyev
INSERT INTO core_users (username, password_hash, full_name, email, role, branch_code, created_by)
SELECT 'operator1', RAWTOHEX(STANDARD_HASH('Oper@123', 'SHA256')),
       'Operator Aliyev', NULL, 'OPERATOR', '00191', 'SYSTEM' FROM DUAL;

COMMIT;

-- ==========================================================================
-- 6. Tekshiruv — Yaratilgan ob'ektlar holati
-- ==========================================================================
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name LIKE 'CORE_AUTH%'
    OR object_name LIKE 'CORE_USERS%'
 ORDER BY object_type, object_name;
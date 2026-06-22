-- ============================================================================
-- MARS ABS (mars-abs) — REAL SIRIUS build, F0
-- 10_cif_schema.sql — core_cif «Клиенты» (mijozlar moduli) — BAZA SXEMA (DDL)
--
-- Oracle 21c XE. Naming: MARS konvensiyasi (core_cif_*; PK ..._pk, FK ..._fk,
--   index ..._idx, sequence ..._seq, check ..._ck, trigger ..._biu_trg).
-- Pul ustunlari — har doim NUMBER (float/double HECH QACHON).
-- Izohlar qisqa (o'zbekcha) + asl SIRIUS rus terminlari ichida keltirilgan.
--
-- MANBA (avtoritetli SIRIUS spec): «Физическое лицо» (fiz.txt),
--   «Юридическое лицо и ИП» (yur.txt), «Счета» (scheta.txt), TZ-003 dizayn.
--
-- SPEC CODE-NAME CONTRACT (3 mijoz turi uchun umumiy yadro):
--   * ID Клиента (surrogat PK)                = client_id  (NUMBER(10) — account FK targeti!)
--   * Код клиента (НИББД, tashqi identifikator)= client_code (UNIQUE, НИББД beradi — AUTO-GEN EMAS)
--   * Тип субъекта (физ/юр/ИП ajratuvchi)     = client_kind (P/J/I, CHECK)
--   * Тип клиента (typeof, СПР 21)            = client_type (FK core_ref_client_type)
--   * Состояние клиента (lifecycle, С01)      = client_status (FK core_cif_status)
--   * Резидентство (027, hujjatdan AUTO)      = resident_flag (Y/N kesh)
--   * версия записи                           = r_uid
--
-- MUHIM KELISHUVLAR:
--   * client_id NUMBER(10) — core_acc_accounts.client_id (NUMBER(10)) FK targeti.
--     Tip ANIQ mos: 20_acc_schema dagi kechiktirilgan FK keyin shu PK ga ulanadi.
--   * client_code — TURGA BOG'LIQ generatsiya (KIND-AWARE):
--       - Физ (kind='P'): kodni «Клиенты» MODULI o'zi beradi — 8 xona,
--         60000000–69999999 oralig'i (1-raqam 6), noyoblik modul tomonidan
--         kafolatlanadi (fiz spec: «Код клиента физического лица присваивается
--         ПМ Клиенты ... от 60000001 до 69999999»). Trigger maxsus sequence
--         (core_cif_phys_code_seq, 60000001 dan) + CHECK bilan ta'minlaydi.
--       - Юр/ИП (kind='J'/'I'): kod НИББД tomonidan TASHQI beriladi (TRIGGER
--         YARATMAYDI). Vaqtinchalik `I%` kod 10 kunlik (almashtirilmasa karta
--         o'chiriladi); «Иностранный банк» = `0009%`.
--   * Резидентность hujjat turidan AUTO chiqariladi
--     (0,1,2,3,6,8→Rezident; 4,5→Norezident). ESLATMA: spec ichki ziddiyat —
--     fiz l.1781 (4 VA 5 → Нерезидент) vs Ограничения l.2478 (faqat 4); karta
--     darajasidagi qoida 5 ni ham qamrab oladi — yakuniy mapping rules qatlamida.
--   * Noyoblik: rezident — ПИНФЛ + (тип+серия+номер); norezident — (тип+серия+номер).
--     ИП uchun ham shu (PINFL + doc triple) — ИНН EMAS.
--   * Pul (o'rtacha maosh, ustav kapitali, ulush) — NUMBER(20,2).
--
-- Old shartlar: core_ref_* (00_ref_spravochniklar.sql) allaqachon o'rnatilgan
--   bo'lsin (core_ref_client_type СПР21 = code VARCHAR2(2),
--   core_ref_region СПР52 = COMPOSITE (region_code VARCHAR2(3), code VARCHAR2(3))).
-- core_acc_accounts.client_id FK ulanishi ALOHIDA bajariladi — bu fayl
--   20_acc_schema ni O'ZGARTIRMAYDI.
-- ============================================================================

-- SQL*Plus sozlamalari (runner-mustaqil): bo'sh qatorlar bayonotni uzmasin
-- (CREATE TABLE/trigger ichidagi bo'limlar orasida bo'sh qatorlar bor), va
-- &-substitution o'chirilsin (matnlarda & bo'lishi mumkin).
SET SQLBLANKLINES ON
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- 1. Idempotent DROP — FK-xavfsiz tartibda (avval bola, keyin ota)
--    Triggerlar -> bola jadvallar (1:N) -> 1:1 kengaytmalar -> baza ->
--    status lug'ati -> sequencelar.
-- ----------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_clients_biu_trg';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_individual_biu_trg';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_legal_biu_trg';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_founders_biu_trg';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_managers_biu_trg';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_documents_biu_trg';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_addresses_biu_trg';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_contacts_biu_trg';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_beneficiaries_biu_trg';EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_client_roles_biu_trg'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_cif_arrests_biu_trg';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Bola jadvallar (1:N)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_arrests      CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_client_roles CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_beneficiaries CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_contacts   CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_addresses  CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_documents  CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_managers   CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_founders   CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- 1:1 kengaytmalar
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_legal      CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_individual CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Baza (ota)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_clients    CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Status lug'ati
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_cif_status     CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Sequencelar
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_clients_seq';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_phys_code_seq';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_founders_seq';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_managers_seq';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_documents_seq';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_addresses_seq';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_contacts_seq';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_beneficiaries_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_client_roles_seq';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_cif_arrests_seq';       EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- 2. core_cif_status — mijoz holatlar lug'ati («Состояние клиента», СПР С01)
--    SIRIUS ikki-darajali model: dag'al «состояние» + «Создан» ichidagi
--    nozik «статус» (AML -> НИББД bosqichlari). Mijoz va hisob bitta lifecycle
--    state-mashinasidan foydalanadi (core_acc_status bilan bir xil tuzilma).
--    is_substate='Y' — «Создан» ichidagi ichki statuslar.
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_status (
    code         VARCHAR2(20)  NOT NULL,                       -- holat kodi (ichki)
    name_ru      VARCHAR2(100) NOT NULL,                       -- Russian SIRIUS nomi (состояние/статус)
    is_substate  CHAR(1)       DEFAULT 'N' NOT NULL,           -- 'Y' = «Создан» ichki statusi (статус клиента)
    is_terminal  CHAR(1)       DEFAULT 'N' NOT NULL,           -- 'Y' = terminal holat
    sort_order   NUMBER(3)     DEFAULT 0   NOT NULL,
    CONSTRAINT core_cif_status_pk      PRIMARY KEY (code),
    CONSTRAINT core_cif_status_sub_ck  CHECK (is_substate IN ('Y','N')),
    CONSTRAINT core_cif_status_term_ck CHECK (is_terminal IN ('Y','N'))
);

COMMENT ON TABLE  core_cif_status             IS 'SIRIUS «Состояние клиента» (СПР С01) — mijoz holatlari lug''ati (state + «Создан» AML/НИББД sub-state)';
COMMENT ON COLUMN core_cif_status.code        IS 'Holat kodi (ichki, core_cif_clients.client_status FK manbasi)';
COMMENT ON COLUMN core_cif_status.name_ru     IS 'Состояние клиента — Russian SIRIUS nomi';
COMMENT ON COLUMN core_cif_status.is_substate IS '«Создан» holatining «на утверждение»/AML/НИББД ichki statusimi (статус клиента)';
COMMENT ON COLUMN core_cif_status.is_terminal IS 'Terminal holat (Удален)';

-- 13 holat (физ + юр/ИП uchun bir xil): Создан + 6 ichki status
-- (на утверждение, AML x2, НИББД x3) -> Утвержден -> Временно закрыт ->
-- Закрыт -> Архивирован -> Удален. (SIRIUS: Закрыт/Архивирован -> Утвержден
-- qayta faollashtirish MUMKIN — terminal faqat Удален.)
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('CREATED',       'Создан',               'N', 'N',  1);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('TO_APPROVE',    'на утверждение',       'Y', 'N',  2);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('AML_CHECK',     'На проверке AML',      'Y', 'N',  3);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('AML_PASSED',    'Проверен AML',         'Y', 'N',  4);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_TO_SEND', 'На отправление НИББД', 'Y', 'N',  5);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_SENT',    'Отправлен НИББД',      'Y', 'N',  6);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_DONE',    'Обработан НИББД',      'Y', 'N',  7);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('APPROVED',      'Утвержден',            'N', 'N',  8);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('TEMP_CLOSED',   'Временно закрыт',      'N', 'N',  9);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('CLOSED',        'Закрыт',               'N', 'N', 10);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('ARCHIVED',      'Архивирован',          'N', 'N', 11);
INSERT INTO core_cif_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('DELETED',       'Удален',               'N', 'Y', 12);
COMMIT;

-- ----------------------------------------------------------------------------
-- 3. Sequencelar — surrogat PK lar uchun + физ client_code generatori
--    Eslatma: юр/ИП client_code (НИББД kodi) sequence EMAS — НИББД tashqi beradi.
--    Lekin физ client_code «Клиенты» MODULI tomonidan beriladi (8 xona,
--    60000000–69999999) — core_cif_phys_code_seq 60000001 dan boshlanadi,
--    MAXVALUE 69999999 (oraliqdan chiqmaslik kafolati), NOCYCLE.
-- ----------------------------------------------------------------------------
CREATE SEQUENCE core_cif_clients_seq       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
-- Физ client_code: 60000001..69999999 (fiz spec l.2470-2474)
CREATE SEQUENCE core_cif_phys_code_seq     START WITH 60000001 INCREMENT BY 1 MAXVALUE 69999999 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_founders_seq      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_managers_seq      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_documents_seq     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_addresses_seq     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_contacts_seq      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_beneficiaries_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_client_roles_seq  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE core_cif_arrests_seq       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ----------------------------------------------------------------------------
-- 4. core_cif_clients — BAZA (3 turga umumiy yadro: физ/юр/ИП)
--    «Заголовок» + «Общие реквизиты» (umumiy qism) + lifecycle + НИББД + AML +
--    Maker-Checker + audit. Турга xos maydonlar 1:1 kengaytmalarda
--    (core_cif_individual / core_cif_legal).
--    client_id NUMBER(10) — core_acc_accounts.client_id FK targeti (tip ANIQ mos).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_clients (
    -- --- Заголовок (header) / surrogat kalit -------------------------------
    client_id          NUMBER(10)    NOT NULL,                 -- ID Клиента — surrogat PK (account FK targeti)
    r_uid              NUMBER(12)    DEFAULT 0 NOT NULL,        -- версия записи (row version, auto)

    -- --- Код клиента — TURGA BOG'LIQ (kind-aware) generatsiya -------------
    --     Физ (kind='P'): «Клиенты» MODULI o'zi beradi — 8 xona,
    --       60000000–69999999 (1-raqam 6); trigger phys-code-seq dan oladi.
    --     Юр/ИП (kind='J'/'I'): НИББД tashqi beradi (AUTO-GEN EMAS).
    --       vaqtinchalik `I%` -> haqiqiy kod; «Иностранный банк» `0009%`.
    --     VARCHAR2 — `I%`/`0009%` matn kodlarni ham saqlash uchun.
    client_code        VARCHAR2(8),                            -- Код клиента — UNIQUE (физ=modul, юр/ИП=НИББД)

    -- --- Тип субъекта (физ/юр/ИП ajratuvchi) + Тип клиента -----------------
    client_kind        CHAR(1)       NOT NULL,                 -- Тип субъекта: P=физлицо, J=юрлицо, I=ИП (СПР 006)
    client_type        VARCHAR2(2),                            -- Тип клиента (typeof) — FK core_ref_client_type (СПР 21)
    primary_role       VARCHAR2(20)  DEFAULT 'CLIENT' NOT NULL,-- Признак: Клиент yoki Связанное лицо (auto kesh; to'liq ro'yxat core_cif_client_roles)
    employee_referred  NUMBER(9),                              -- Привлёкший сотрудник (mijozni jalb qilgan xodim, fiz/yur card)

    -- --- Nomi (umumiy header nusxasi) -------------------------------------
    full_name          VARCHAR2(200) NOT NULL,                 -- ФИО / Наименование организации (на кирилл)
    full_name_lat      VARCHAR2(200),                          -- ФИО / Наименование (на латинском)
    short_name         VARCHAR2(200),                          -- Краткое наименование (юр) / ko'rsatish nomi

    -- --- Rezidentlik (hujjatdan AUTO) -------------------------------------
    resident_flag      CHAR(1)       DEFAULT 'Y' NOT NULL,     -- Резидентство (027): Y=Резидент, N=Нерезидент (auto)
    resident_code      NUMBER(1),                              -- Резидентность kodi (СПР 027)
    residency_country  VARCHAR2(3),                            -- Страна резидентства (СПР 018)
    citizenship_country VARCHAR2(3),                           -- Страна гражданства (СПР 018)
    nationality        VARCHAR2(2),                            -- Национальность (СПР 072)

    -- --- Yashash/faoliyat geografiyasi (СПР 052 — region+rayon juftligi) ---
    region_code        VARCHAR2(3),                            -- Область (СПР 016 / СПР 052 region qismi)
    district_code      VARCHAR2(3),                            -- Район (СПР 052 — region bilan mos kelishi shart)

    -- --- Состояние клиента (lifecycle) ------------------------------------
    client_status      VARCHAR2(20)  DEFAULT 'CREATED' NOT NULL,-- Состояние клиента — FK core_cif_status
    client_sub_status  VARCHAR2(20),                           -- «Создан» ichki statusi (статус, FK core_cif_status)

    -- --- Mijoz segment/bayroqlari + xizmat sharti -------------------------
    client_flags       VARCHAR2(100),                          -- Статус клиента: VIP/Аффилирован/Связан с банком
    primary_branch_code VARCHAR2(5),                           -- основной код обслуживания (auto = 1-filial)
    code_word          VARCHAR2(50),                           -- Кодовое слово
    tenure_period      NUMBER(10),                             -- период клиентности (kun, registratsiyadan)
    last_operation_date DATE,                                  -- дата последней операции (faol mijoz hisobi)
    identification_type NUMBER(1),                             -- Тип идентификации (auto)
    validity_end_date  DATE,                                   -- Дата оконч. действ. клиента
    liquidation_reason_code VARCHAR2(10),                      -- Код вида причины ликвидации (СПР 010)

    -- --- НИББД vaqtinchalik kod (10 kunlik qoida) -------------------------
    --     Юр/ИП: `I%` vaqtinchalik kod — haqiqiy НИББД kodga 10 kunda
    --     almashtirilmasa karta o'chiriladi. Trigger nibbd_temp_expiry ni
    --     created + 10 kun qilib qo'yadi (temp kod mavjud bo'lsa).
    nibbd_temp_code    VARCHAR2(8),                            -- Vaqtinchalik НИББД kod (`I%`)
    nibbd_temp_expiry  DATE,                                   -- Vaqtinchalik kod amal qilish muddati (created+10)
    nibbd_registered   CHAR(1)       DEFAULT 'N' NOT NULL,     -- НИББД da ro'yxatga olinganmi (Y/N)
    nibbd_reg_at       TIMESTAMP,                              -- НИББД ro'yxatga olingan vaqt

    -- --- AML / KYC --------------------------------------------------------
    aml_status         VARCHAR2(20),                           -- AML holati (На проверке/Проверен)
    aml_checked_at     TIMESTAMP,                              -- AML tekshiruvi vaqti
    aml_risk_level     VARCHAR2(10),                           -- AML risk darajasi (LOW/MEDIUM/HIGH)

    -- --- Maker-Checker (ikki bosqichli tasdiqlash) ------------------------
    maker_user         NUMBER(9),                              -- Yaratuvchi (Maker) user id
    checker_user       NUMBER(9),                              -- Tasdiqlovchi (Checker) user id
    approved_at        TIMESTAMP,                              -- Утвердить vaqti (APPROVED ga o'tish)

    -- --- Hayotiy holat / arxivlash ----------------------------------------
    life_status        VARCHAR2(10),                           -- жизненный статус (tirik/vafot etgan)
    death_date         DATE,                                   -- Дата смерти
    archived_at        DATE,                                   -- Дата архивации данных о клиенте

    -- --- Audit trail (har jadvalda) ---------------------------------------
    created_by         NUMBER(9),                              -- Кем создан (user id)
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,  -- Дата открытия / дата создания
    updated_by         NUMBER(9),                              -- Кем изменен (user id)
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,  -- Дата изменения

    -- --- Constraints ------------------------------------------------------
    CONSTRAINT core_cif_clients_pk        PRIMARY KEY (client_id),
    CONSTRAINT core_cif_clients_code_uk   UNIQUE (client_code),                -- Код клиента noyob (физ=modul, юр/ИП=НИББД)
    CONSTRAINT core_cif_clients_kind_ck   CHECK (client_kind IN ('P','J','I')),-- P=физ, J=юр, I=ИП
    CONSTRAINT core_cif_clients_res_ck    CHECK (resident_flag IN ('Y','N')),
    CONSTRAINT core_cif_clients_nibreg_ck CHECK (nibbd_registered IN ('Y','N')),
    -- Физ client_code modul tomonidan beriladi: 8 xona, 60000000–69999999
    -- (fiz spec l.2470-2474). Boshqa turlar (J/I) НИББД formatlariga (`I%`/`0009%`)
    -- erkin. Faqat физ kod oralig'ini cheklaymiz (kod mavjud bo'lsa).
    CONSTRAINT core_cif_clients_pcode_ck  CHECK (
        client_kind <> 'P' OR client_code IS NULL
        OR (LENGTH(client_code) = 8 AND client_code BETWEEN '60000000' AND '69999999')),
    -- FK lar — ref-contracts'dagi ANIQ PK ustunlariga
    CONSTRAINT core_cif_clients_type_fk   FOREIGN KEY (client_type)
        REFERENCES core_ref_client_type(code),                               -- СПР 21
    CONSTRAINT core_cif_clients_region_fk FOREIGN KEY (region_code, district_code)
        REFERENCES core_ref_region(region_code, code),                       -- СПР 52 (KOMPOZIT)
    CONSTRAINT core_cif_clients_status_fk FOREIGN KEY (client_status)
        REFERENCES core_cif_status(code),
    CONSTRAINT core_cif_clients_sstat_fk  FOREIGN KEY (client_sub_status)
        REFERENCES core_cif_status(code)
);

COMMENT ON TABLE  core_cif_clients                  IS 'SIRIUS «Клиенты» — mijoz bazasi (физ/юр/ИП umumiy yadro). client_id = core_acc_accounts.client_id FK targeti';
COMMENT ON COLUMN core_cif_clients.client_id        IS 'ID Клиента — surrogat PK (sequence); core_acc_accounts.client_id (NUMBER(10)) FK targeti';
COMMENT ON COLUMN core_cif_clients.r_uid            IS 'версия записи — row version (auto)';
COMMENT ON COLUMN core_cif_clients.client_code      IS 'Код клиента — UNIQUE. Физ (P): «Клиенты» MODULI beradi 8 xona 60000000–69999999 (1-raqam 6); Юр/ИП (J/I): НИББД TASHQI beradi (`I%`/`0009%`)';
COMMENT ON COLUMN core_cif_clients.client_kind      IS 'Тип субъекта (СПР 006) — P=физлицо, J=юрлицо, I=ИП (физ/юр/ИП ajratuvchi)';
COMMENT ON COLUMN core_cif_clients.client_type      IS 'Тип клиента (typeof) — FK core_ref_client_type (СПР 21)';
COMMENT ON COLUMN core_cif_clients.primary_role     IS 'Признаки клиента — Клиент/Связанное лицо asosiy roli (kesh; to''liq ko''p-rol core_cif_client_roles 1:N)';
COMMENT ON COLUMN core_cif_clients.employee_referred IS 'Привлёкший сотрудник — mijozni jalb qilgan xodim id (yur l.2280)';
COMMENT ON COLUMN core_cif_clients.full_name        IS 'ФИО (физ) / Наименование организации (юр) — на кирилл, header';
COMMENT ON COLUMN core_cif_clients.full_name_lat    IS 'ФИО / Наименование — на латинском';
COMMENT ON COLUMN core_cif_clients.short_name       IS 'Краткое наименование организации (юр) / ko''rsatish nomi';
COMMENT ON COLUMN core_cif_clients.resident_flag    IS 'Резидентство (СПР 027) — Y=Резидент, N=Нерезидент; hujjat turidan AUTO (0,1,2,3,6,8→Y; 4,5→N). Spec ziddiyat: fiz l.1781 (4,5) vs l.2478 (4) — rules qatlami hal qiladi';
COMMENT ON COLUMN core_cif_clients.resident_code    IS 'Резидентность kodi (СПР 027)';
COMMENT ON COLUMN core_cif_clients.residency_country IS 'Страна резидентства (СПР 018)';
COMMENT ON COLUMN core_cif_clients.citizenship_country IS 'Страна гражданства (СПР 018)';
COMMENT ON COLUMN core_cif_clients.nationality      IS 'Национальность (СПР 072)';
COMMENT ON COLUMN core_cif_clients.region_code      IS 'Область (СПР 016 / СПР 052 region qismi)';
COMMENT ON COLUMN core_cif_clients.district_code    IS 'Район (СПР 052) — region_code bilan mos kelishi shart (ЦБ №052)';
COMMENT ON COLUMN core_cif_clients.client_status    IS 'Состояние клиента (СПР С01) — FK core_cif_status (lifecycle)';
COMMENT ON COLUMN core_cif_clients.client_sub_status IS '«Создан» ichki statusi (статус клиента: AML/НИББД bosqichi) — FK core_cif_status';
COMMENT ON COLUMN core_cif_clients.client_flags     IS 'Статус клиента — VIP/Аффилирован с банком/Связано с банком segment bayroqlari';
COMMENT ON COLUMN core_cif_clients.primary_branch_code IS 'основной код обслуживания (auto = ochilgan birinchi filial)';
COMMENT ON COLUMN core_cif_clients.code_word        IS 'Кодовое слово (maxfiy so''z)';
COMMENT ON COLUMN core_cif_clients.last_operation_date IS 'дата последней операции — faol mijoz hisobi uchun';
COMMENT ON COLUMN core_cif_clients.liquidation_reason_code IS 'Код вида причины ликвидации клиента (СПР 010)';
COMMENT ON COLUMN core_cif_clients.nibbd_temp_code  IS 'Vaqtinchalik НИББД kod (юр/ИП: `I%`) — haqiqiy kodga almashguncha';
COMMENT ON COLUMN core_cif_clients.nibbd_temp_expiry IS 'Vaqtinchalik kod muddati (created + 10 kun); almashtirilmasa karta o''chiriladi';
COMMENT ON COLUMN core_cif_clients.nibbd_registered IS 'НИББД da ro''yxatga olinganmi (Y/N) — hisob ochish uchun shart';
COMMENT ON COLUMN core_cif_clients.aml_status       IS 'AML holati (На проверке AML / Проверен AML)';
COMMENT ON COLUMN core_cif_clients.maker_user       IS 'Maker — yaratuvchi user (ikki bosqichli tasdiq)';
COMMENT ON COLUMN core_cif_clients.checker_user     IS 'Checker — tasdiqlovchi user (Утвердить)';
COMMENT ON COLUMN core_cif_clients.approved_at      IS 'Утвердить vaqti — APPROVED holatga o''tish';
COMMENT ON COLUMN core_cif_clients.life_status      IS 'жизненный статус (tirik/vafot etgan)';
COMMENT ON COLUMN core_cif_clients.created_at       IS 'Дата открытия / дата создания — audit';
COMMENT ON COLUMN core_cif_clients.updated_at       IS 'Дата изменения — audit';

-- ----------------------------------------------------------------------------
-- 5. core_cif_individual — ФИЗИЧЕСКОЕ ЛИЦО (1:1 core_cif_clients bilan)
--    «Физическое лицо» kartasi: ism, hujjat (yagona), tug'ilish, ПИНФЛ, ИНН,
--    ish/ta'lim, qo'shimcha rekvizitlar. PK = client_id (1:1 kafolat).
--    Noyoblik: rezident — ПИНФЛ + (тип+серия+номер); norezident — (тип+серия+номер).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_individual (
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients (1:1)

    -- --- Ism (Общие реквизиты) --------------------------------------------
    last_name          VARCHAR2(35)  NOT NULL,                 -- Фамилия (на кирилл)
    first_name         VARCHAR2(35)  NOT NULL,                 -- Имя
    middle_name        VARCHAR2(35),                           -- Отчество
    last_name_lat      VARCHAR2(35)  NOT NULL,                 -- Фамилия (латин)
    first_name_lat     VARCHAR2(35)  NOT NULL,                 -- Имя (латин)
    middle_name_lat    VARCHAR2(35),                           -- Отчество (латин)
    gender             NUMBER(1)     NOT NULL,                 -- Пол (СПР 007)
    birth_date         DATE          NOT NULL,                 -- Дата рождения (<= operatsion kun)
    birth_country      VARCHAR2(3),                            -- Страна рождения (СПР 018)

    -- --- Yagona shaxsiy hujjat (kartada bitta hujjat) ---------------------
    --     0,6,8 -> серия len=2, номер len=7, ПИНФЛ majburiy.
    doc_type           VARCHAR2(2)   NOT NULL,                 -- Тип документа (СПР 008) — noyoblik qismi
    doc_series         VARCHAR2(4)   NOT NULL,                 -- серия документа — noyoblik qismi (0/6/8 -> 2)
    doc_number         VARCHAR2(9)   NOT NULL,                 -- Номер документа — noyoblik qismi (0/6/8 -> 7)
    doc_issue_date     DATE          NOT NULL,                 -- дата выдачи документа (<= operatsion kun)
    -- Quyidagilar shartli-majburiy (hujjat turiga bog'liq) — ba'zi hujjatlarda
    -- muddatsiz/joysiz bo'lishi mumkin; majburiylik rules qatlamida (NOT NULL EMAS).
    doc_expiry_date    DATE,                                   -- Срок действия документа (> выдачи; shartli)
    doc_issue_place    VARCHAR2(255),                          -- Место выдачи документа (shartli)
    doc_issue_country  VARCHAR2(3),                            -- Страна выдачи документа (СПР 018; shartli)
    doc_issuer_name    VARCHAR2(255),                          -- Наименование органа выдавшего документ

    -- --- Soliq / ПИНФЛ ----------------------------------------------------
    pinfl              VARCHAR2(14),                           -- ПИНФЛ (0/6/8 da majburiy; rezident noyoblik)
    tin                VARCHAR2(9),                            -- ИНН (soliq to'lovchi raqami)
    gni_code           VARCHAR2(4),                            -- код ГНИ (СПР 054)
    gni_name           VARCHAR2(255),                          -- наименование ГНИ
    pension_cert_number VARCHAR2(50),                          -- Номер пенсионного удостоверения

    -- --- Ish va ta'lim (Работа и образование) -----------------------------
    work_capacity      NUMBER(2),                              -- Работоспособность (СПР 068)
    workplace          VARCHAR2(255),                          -- Место работы
    avg_monthly_salary NUMBER(20,2),                           -- Ежемесячная средняя зарплата (NUMBER, pul!)
    education          NUMBER(2),                              -- Образование (СПР 074)
    is_civil_servant   CHAR(1),                                -- Является ли гос. служащим (Y/N)

    -- --- Qo'shimcha rekvizitlar (Дополнительные) --------------------------
    ownership_form     NUMBER(3),                              -- форма собственности (СПР 057)
    marital_status     NUMBER(1),                              -- Семейное положение (СПР)
    has_movable_property   CHAR(1),                            -- Имеется ли движимое имущество (Y/N)
    has_immovable_property CHAR(1),                            -- Имеется ли недвижимое имущество (Y/N)
    housing_info       VARCHAR2(255),                          -- Информация о жилье
    passport_mrz       VARCHAR2(100),                          -- Машиночитаемые данные паспорта (MRZ)
    cadastre_number    VARCHAR2(28),                           -- Номер кадастра

    -- --- Audit ------------------------------------------------------------
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    -- --- Constraints ------------------------------------------------------
    CONSTRAINT core_cif_individual_pk      PRIMARY KEY (client_id),
    CONSTRAINT core_cif_individual_cl_fk   FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_individual_civ_ck  CHECK (is_civil_servant IN ('Y','N')),
    CONSTRAINT core_cif_individual_mov_ck  CHECK (has_movable_property IN ('Y','N')),
    CONSTRAINT core_cif_individual_imm_ck  CHECK (has_immovable_property IN ('Y','N')),
    -- Hujjat noyobligi: тип+серия+номер (rezident/norezident umumiy qism)
    CONSTRAINT core_cif_individual_doc_uk  UNIQUE (doc_type, doc_series, doc_number)
);

COMMENT ON TABLE  core_cif_individual                IS 'SIRIUS «Физическое лицо» — jismoniy shaxs kartasi (1:1 core_cif_clients)';
COMMENT ON COLUMN core_cif_individual.client_id      IS 'FK -> core_cif_clients (1:1)';
COMMENT ON COLUMN core_cif_individual.last_name      IS 'Фамилия (на кириллице)';
COMMENT ON COLUMN core_cif_individual.first_name     IS 'Имя';
COMMENT ON COLUMN core_cif_individual.middle_name    IS 'Отчество';
COMMENT ON COLUMN core_cif_individual.gender         IS 'Пол (СПР 007)';
COMMENT ON COLUMN core_cif_individual.birth_date     IS 'Дата рождения (<= operatsion kun)';
COMMENT ON COLUMN core_cif_individual.doc_type       IS 'Тип документа (СПР 008) — 0/6/8 milliy (серия 2 + номер 7, ПИНФЛ majburiy); 4 chet pasporti';
COMMENT ON COLUMN core_cif_individual.doc_series     IS 'серия документа (0/6/8 -> uzunlik 2)';
COMMENT ON COLUMN core_cif_individual.doc_number     IS 'Номер документа (0/6/8 -> uzunlik 7)';
COMMENT ON COLUMN core_cif_individual.doc_expiry_date IS 'Срок действия документа (> дата выдачи)';
COMMENT ON COLUMN core_cif_individual.pinfl          IS 'ПИНФЛ — 14 raqam; doc_type 0/6/8 da majburiy; rezident noyoblik kaliti';
COMMENT ON COLUMN core_cif_individual.tin            IS 'ИНН — soliq to''lovchi identifikatori';
COMMENT ON COLUMN core_cif_individual.avg_monthly_salary IS 'Ежемесячная средняя заработная зарплата (NUMBER(20,2), BigDecimal — float YO''Q)';
COMMENT ON COLUMN core_cif_individual.education      IS 'Образование (СПР 074)';
COMMENT ON COLUMN core_cif_individual.work_capacity  IS 'Работоспособность (СПР 068)';
COMMENT ON COLUMN core_cif_individual.ownership_form IS 'форма собственности (СПР 057)';
COMMENT ON COLUMN core_cif_individual.passport_mrz   IS 'Машиночитаемые данные в паспорте (MRZ)';

-- ----------------------------------------------------------------------------
-- 6. core_cif_legal — ЮРИДИЧЕСКОЕ ЛИЦО / ИП (1:1 core_cif_clients bilan)
--    «Юридическое лицо и ИП» kartasi: общие/статистические/регистрационные
--    реквизиты, ИНН (noyob), ОКЭД/ОКПО/СООГУ, tashkiliy shakl, ustav kapitali.
--    ИП uchun shaxsiy-identifikatsiya maydonlari (last_name..pinfl) ham shu yerda.
--    PK = client_id (1:1). client_kind ('J' yoki 'I') bazada saqlanadi.
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_legal (
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients (1:1)

    -- --- Общие реквизиты (юрлицо) -----------------------------------------
    --     ИНН — юрлицо (J) uchun majburiy+noyob, lekin ИП (I) uchun IXTIYORIY
    --     (yur l.4393 '+' belgisi yo'q). Shu sabab NOT NULL EMAS; noyoblik
    --     faqat юрлицо qatorlariga (kind='J') shartli unikal index orqali
    --     (J uchun majburiylik rules qatlamida tekshiriladi).
    inn                VARCHAR2(9),                            -- ИНН (юрлицо: majburiy+noyob; ИП: ixtiyoriy)
    name               VARCHAR2(200) NOT NULL,                 -- Наименование организации
    name_lat           VARCHAR2(200),                          -- Наименование организации (на латинском)
    name_short         VARCHAR2(200),                          -- Краткое наименование организации
    nonresident_type   VARCHAR2(10),                           -- Тип нерезидента (norezident bo'lsa)
    business_sign_s    NUMBER(1),                              -- Признак малого бизнеса
    business_sign_m    NUMBER(1),                              -- Признак среднего бизнеса
    business_sign_c    NUMBER(1),                              -- Признак корпоративного клиента

    -- --- ИП shaxsiy-identifikatsiya bloki (client_kind='I' uchun) ----------
    last_name          VARCHAR2(35),                           -- Фамилия (ИП)
    first_name         VARCHAR2(35),                           -- Имя (ИП)
    middle_name        VARCHAR2(35),                           -- Отчество (ИП)
    last_name_lat      VARCHAR2(35),                           -- Фамилия (латин, ИП)
    first_name_lat     VARCHAR2(35),                           -- Имя (латин, ИП)
    middle_name_lat    VARCHAR2(35),                           -- Отчество (латин, ИП)
    gender             NUMBER(1),                              -- Пол (СПР 007, ИП)
    dob                DATE,                                   -- Дата рождения (ИП)
    country_birth      VARCHAR2(3),                            -- Страна рождения (СПР 018, ИП)
    ip_doc_type        VARCHAR2(2),                            -- Тип документа (СПР 008, ИП) — noyoblik qismi
    ip_doc_serial      VARCHAR2(4),                            -- серия документа (ИП) — noyoblik qismi
    ip_doc_number      VARCHAR2(9),                            -- Номер документа (ИП) — noyoblik qismi
    ip_doc_issue_date  DATE,                                   -- дата выдачи документа (ИП)
    ip_doc_expire_date DATE,                                   -- Срок действия документа (ИП)
    ip_doc_country     VARCHAR2(3),                            -- Страна выдачи документа (СПР 018, ИП)
    ip_doc_place       VARCHAR2(255),                          -- Место выдачи документа (ИП)
    pinfl              VARCHAR2(14),                           -- ПИНФЛ (ИП rezident: majburiy + noyob)

    -- --- Регистрационные / статистические реквизиты -----------------------
    num_registr        VARCHAR2(20),                           -- Номер регистрации
    date_registr       DATE,                                   -- Дата регистрации (<= operatsion kun)
    registr_expire_date DATE,                                  -- срок действия регистрации (ИП)
    country_registr    VARCHAR2(3),                            -- Страна регистрации (СПР 018, НИББД)
    region_registr     VARCHAR2(3),                            -- Область регистрации (СПР 052 region qismi — core_ref_region.region_code(3) ga ANIQ mos)
    district_registr   VARCHAR2(3),                            -- Район регистрации (СПР 052)
    registration_place VARCHAR2(300),                          -- Место регистрации
    oked               VARCHAR2(5),                            -- Код ОКЭД (СПР 013, НИББД)
    oknx               VARCHAR2(5),                            -- ОКОНХ — эконом. сектор (СПР 023)
    okpo               VARCHAR2(8),                            -- ОКПО
    soogu              VARCHAR2(5),                            -- СООГУ (СПР 071, НИББД)
    tax_organization_code VARCHAR2(4),                         -- Код ГНИ (СПР 054)
    property_form_code NUMBER(3),                              -- Код формы собственности (СПР 057, НИББД)
    organization_legal_form NUMBER(3),                         -- Организационно-правовая форма (СПР 093, НИББД)
    soato              NUMBER(10),                             -- Адрес субъекта (СОАТО, СПР 104, НИББД)
    organization_head_cl_code VARCHAR2(8),                     -- Код вышестоящей организации (СПР 071)
    organization_head_inn     VARCHAR2(9),                     -- ИНН вышестоящей организации

    -- --- Ustav kapitali (Учредители bloki boshlanishi — pul!) -------------
    capital_amount     NUMBER(20,2),                           -- Уставный капитал (NUMBER(20,2), pul — float YO'Q)

    -- --- Bank korrespondent (юрлицо) --------------------------------------
    bic                VARCHAR2(11),                           -- BIC код
    swift_id           VARCHAR2(11),                           -- SWIFT код банка-корреспондента (СПР 047)

    -- --- Audit ------------------------------------------------------------
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    -- --- Constraints ------------------------------------------------------
    CONSTRAINT core_cif_legal_pk      PRIMARY KEY (client_id),
    CONSTRAINT core_cif_legal_cl_fk   FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    -- ИНН noyobligi UNCONDITIONAL EMAS: ИП (kind='I') uchun ИНН ixtiyoriy va
    -- noyoblik kaliti ПИНФЛ+(doc triple) — global UNIQUE(inn) ИП ni buzardi.
    -- Shuning uchun юрлицо noyobligi quyida shartli FUNCTION-BASED UNIQUE index
    -- bilan beriladi (core_cif_legal_inn_uix). ИП noyobligi ham alohida indexlar.
    -- Регистрация region/rayon juftligi -> СПР 52 (kompozit)
    CONSTRAINT core_cif_legal_reg_fk  FOREIGN KEY (region_registr, district_registr)
        REFERENCES core_ref_region(region_code, code)
);

COMMENT ON TABLE  core_cif_legal                 IS 'SIRIUS «Юридическое лицо и ИП» — yuridik shaxs/ИП kartasi (1:1 core_cif_clients)';
COMMENT ON COLUMN core_cif_legal.client_id       IS 'FK -> core_cif_clients (1:1)';
COMMENT ON COLUMN core_cif_legal.inn             IS 'ИНН — 9 raqam; юрлицо (J): majburiy+noyob (shartli unikal index); ИП (I): ixtiyoriy (yur l.4393)';
COMMENT ON COLUMN core_cif_legal.name            IS 'Наименование организации (НИББД)';
COMMENT ON COLUMN core_cif_legal.name_lat        IS 'Наименование организации (на латинском)';
COMMENT ON COLUMN core_cif_legal.name_short      IS 'Краткое наименование организации';
COMMENT ON COLUMN core_cif_legal.pinfl           IS 'ПИНФЛ (ИП) — rezident bo''lsa majburiy + noyob';
COMMENT ON COLUMN core_cif_legal.ip_doc_type     IS 'Тип документа (СПР 008, ИП) — тип+серия+номер noyoblik';
COMMENT ON COLUMN core_cif_legal.num_registr     IS 'Номер регистрации';
COMMENT ON COLUMN core_cif_legal.date_registr    IS 'Дата регистрации (<= operatsion kun)';
COMMENT ON COLUMN core_cif_legal.country_registr IS 'Страна регистрации (СПР 018) — НИББД (бюджет 01/06/12 da o''zgarmas)';
COMMENT ON COLUMN core_cif_legal.oked            IS 'Код ОКЭД — эконом. faoliyat klassifikatori (СПР 013, НИББД)';
COMMENT ON COLUMN core_cif_legal.oknx            IS 'ОКОНХ — эконом. sektor (СПР 023)';
COMMENT ON COLUMN core_cif_legal.okpo            IS 'ОКПО — korxonalar klassifikatori';
COMMENT ON COLUMN core_cif_legal.soogu           IS 'СООГУ (СПР 071, НИББД)';
COMMENT ON COLUMN core_cif_legal.property_form_code IS 'Код формы собственности (СПР 057, НИББД)';
COMMENT ON COLUMN core_cif_legal.organization_legal_form IS 'Организационно-правовая форма (СПР 093, НИББД)';
COMMENT ON COLUMN core_cif_legal.soato           IS 'СОАТО — Адрес субъекта (СПР 104, НИББД)';
COMMENT ON COLUMN core_cif_legal.capital_amount  IS 'Уставный капитал (NUMBER(20,2), BigDecimal — float YO''Q)';
COMMENT ON COLUMN core_cif_legal.bic             IS 'BIC код (юрлицо)';
COMMENT ON COLUMN core_cif_legal.swift_id        IS 'SWIFT код банка-корреспондента (СПР 047)';

-- ----------------------------------------------------------------------------
-- 7. core_cif_founders — УЧРЕДИТЕЛИ (1:N, юрлицо) — физ/юр diskriminator
--    Har qator bitta ta'sischi: физ (ПИНФЛ + hujjat) yoki юр (ИНН + nom),
--    ulush номинал + foiz. NUMBER(20,2) — pul/foiz (float YO'Q).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_founders (
    founder_id         NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients (ota юрлицо)
    founder_kind       CHAR(1)       NOT NULL,                 -- P=физ. лицо, J=юр. лицо (diskriminator)

    -- --- Учредитель = физ. лицо -------------------------------------------
    founder_name       VARCHAR2(200),                          -- Ф.И.О. учредителя (физ)
    founder_pinfl      VARCHAR2(14),                           -- ПИНФЛ учредителя (физ)
    founder_doc_type   VARCHAR2(2),                            -- тип документа (СПР 008)
    founder_doc_serial VARCHAR2(4),                            -- серия паспорт учредителя
    founder_doc_number VARCHAR2(9),                            -- номер паспорт учредителя

    -- --- Учредитель = юр. лицо --------------------------------------------
    founder_inn        VARCHAR2(9),                            -- ИНН учредителя (юр)
    founder_client_name VARCHAR2(200),                         -- наименование учредителя (юр)

    -- --- Ulush (pul/foiz) -------------------------------------------------
    founder_paid_amount NUMBER(20,2),                          -- доля в уставном капитале (номинал, pul!)
    founder_share_percent NUMBER(20,2),                        -- доля в уставном капитале (%)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_founders_pk    PRIMARY KEY (founder_id),
    CONSTRAINT core_cif_founders_cl_fk FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_founders_kind_ck CHECK (founder_kind IN ('P','J'))
);

COMMENT ON TABLE  core_cif_founders                 IS 'SIRIUS «Учредители» — ta''sischilar (1:N, юрлицо). founder_kind: P=физ, J=юр';
COMMENT ON COLUMN core_cif_founders.client_id       IS 'FK -> core_cif_clients (ota юрлицо)';
COMMENT ON COLUMN core_cif_founders.founder_kind    IS 'Ta''sischi turi: P=физ. лицо, J=юр. лицо (diskriminator)';
COMMENT ON COLUMN core_cif_founders.founder_pinfl   IS 'ПИНФЛ учредителя (физ)';
COMMENT ON COLUMN core_cif_founders.founder_inn     IS 'ИНН учредителя (юр)';
COMMENT ON COLUMN core_cif_founders.founder_paid_amount   IS 'доля в уставном капитале (номинал) — NUMBER(20,2), pul (float YO''Q)';
COMMENT ON COLUMN core_cif_founders.founder_share_percent IS 'доля в уставном капитале (%) — NUMBER(20,2)';

-- ----------------------------------------------------------------------------
-- 8. core_cif_managers — ДИРЕКТОР / БУХГАЛТЕР / УПОЛНОМОЧЕННОЕ ЛИЦО (1:N, юрлицо)
--    E-GOV ПИНФЛ orqali yuklanadi; har biri Связанное лицо kartasi sifatida
--    yaratiladi. manager_role: DIRECTOR (1:1 majburiy), ACCOUNTANT (1:1 ixtiyoriy),
--    AUTHORIZED (umumiy уполномоченное лицо).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_managers (
    manager_id         NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients (ota юрлицо)
    manager_role       VARCHAR2(20)  NOT NULL,                 -- DIRECTOR/ACCOUNTANT/AUTHORIZED (уполномоченное лицо)
    related_client_id  NUMBER(10),                             -- yaratilgan Связанное лицо kartasi (ixtiyoriy FK)

    manager_name       VARCHAR2(100) NOT NULL,                 -- Ф.И.О (директора/бухгалтера)
    manager_pinfl      VARCHAR2(14)  NOT NULL,                 -- ПИНФЛ (E-GOV yuklash kaliti)
    manager_doc_type   VARCHAR2(2),                            -- тип документа (СПР 008)
    manager_doc_serial VARCHAR2(4),                            -- серия паспорта
    manager_doc_number VARCHAR2(9),                            -- номер паспорта

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_managers_pk      PRIMARY KEY (manager_id),
    CONSTRAINT core_cif_managers_cl_fk   FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_managers_rel_fk  FOREIGN KEY (related_client_id)
        REFERENCES core_cif_clients(client_id),
    CONSTRAINT core_cif_managers_role_ck CHECK (manager_role IN ('DIRECTOR','ACCOUNTANT','AUTHORIZED'))
);

COMMENT ON TABLE  core_cif_managers                IS 'SIRIUS «Уполномоченные лица» — Директор/Бухгалтер/упол. лицо (1:N, юрлицо; E-GOV ПИНФЛ)';
COMMENT ON COLUMN core_cif_managers.client_id      IS 'FK -> core_cif_clients (ota юрлицо)';
COMMENT ON COLUMN core_cif_managers.manager_role   IS 'Rol: DIRECTOR (Директор) / ACCOUNTANT (Бухгалтер) / AUTHORIZED (уполномоченное лицо)';
COMMENT ON COLUMN core_cif_managers.related_client_id IS 'Связанное лицо kartasi (E-GOV dan yaratilgan) — ixtiyoriy FK';
COMMENT ON COLUMN core_cif_managers.manager_pinfl  IS 'ПИНФЛ — E-GOV ma''lumot yuklash kaliti';

-- ----------------------------------------------------------------------------
-- 9. core_cif_documents — HUJJATLAR (1:N) — qo'shimcha/tarixiy hujjatlar
--    BAZA karta bitta asosiy hujjatni saqlaydi (individual/legal ichida); bu
--    jadval qo'shimcha hujjatlar va tarix uchun (NIBBD log o'rnida emas).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_documents (
    document_id        NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients
    doc_type           VARCHAR2(2)   NOT NULL,                 -- Тип документа (СПР 008)
    doc_series         VARCHAR2(4),                            -- серия документа
    doc_number         VARCHAR2(9)   NOT NULL,                 -- Номер документа
    doc_issue_date     DATE,                                   -- дата выдачи документа
    doc_expiry_date    DATE,                                   -- Срок действия документа
    doc_issue_place    VARCHAR2(255),                          -- Место выдачи документа
    doc_issue_country  VARCHAR2(3),                            -- Страна выдачи документа (СПР 018)
    doc_issuer_name    VARCHAR2(255),                          -- Наименование органа выдавшего документ
    is_primary         CHAR(1)       DEFAULT 'N' NOT NULL,     -- asosiy hujjatmi (Y/N)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_documents_pk    PRIMARY KEY (document_id),
    CONSTRAINT core_cif_documents_cl_fk FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_documents_pri_ck CHECK (is_primary IN ('Y','N'))
);

COMMENT ON TABLE  core_cif_documents              IS 'SIRIUS mijoz hujjatlari (1:N) — qo''shimcha/tarixiy удостоверяющий документ';
COMMENT ON COLUMN core_cif_documents.client_id    IS 'FK -> core_cif_clients';
COMMENT ON COLUMN core_cif_documents.doc_type     IS 'Тип документа (СПР 008)';
COMMENT ON COLUMN core_cif_documents.is_primary   IS 'Asosiy hujjatmi (Y/N)';

-- ----------------------------------------------------------------------------
-- 10. core_cif_addresses — АДРЕСА (1:N) — проживание / деятельность
--     Доимий + vaqtinchalik + faoliyat manzili. region/rayon -> СПР 52 (kompozit).
--     addr_type: REGISTRATION (проживание/регистрация), ACTUAL (фактический),
--     ACTIVITY (осуществления деятельности).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_addresses (
    address_id         NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients
    addr_type          VARCHAR2(20)  NOT NULL,                 -- REGISTRATION/ACTUAL/ACTIVITY
    addr_country       VARCHAR2(3),                            -- Страна проживания/деятельности (СПР 018)
    addr_region        VARCHAR2(3),                            -- Область (СПР 016 / 052 region qismi)
    addr_district      VARCHAR2(3),                            -- Район (СПР 052 — region bilan mos)
    addr_settlement    NUMBER(10),                             -- Населённый пункт / СОАТО (СПР 104)
    addr_line          VARCHAR2(300) NOT NULL,                 -- Адрес (ko'cha, uy)
    postal_code        VARCHAR2(6),                            -- Почтовый индекс
    cadastre_number    VARCHAR2(28),                           -- Номер кадастра
    is_primary         CHAR(1)       DEFAULT 'N' NOT NULL,     -- asosiy manzilmi (Y/N)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_addresses_pk     PRIMARY KEY (address_id),
    CONSTRAINT core_cif_addresses_cl_fk  FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_addresses_reg_fk FOREIGN KEY (addr_region, addr_district)
        REFERENCES core_ref_region(region_code, code),                       -- СПР 52 (KOMPOZIT)
    CONSTRAINT core_cif_addresses_type_ck CHECK (addr_type IN ('REGISTRATION','ACTUAL','ACTIVITY')),
    CONSTRAINT core_cif_addresses_pri_ck  CHECK (is_primary IN ('Y','N'))
);

COMMENT ON TABLE  core_cif_addresses               IS 'SIRIUS «Адрес» (1:N) — проживание/фактический/деятельность; region+rayon -> СПР 52';
COMMENT ON COLUMN core_cif_addresses.client_id     IS 'FK -> core_cif_clients';
COMMENT ON COLUMN core_cif_addresses.addr_type     IS 'Manzil turi: REGISTRATION (проживание), ACTUAL (фактический), ACTIVITY (деятельность)';
COMMENT ON COLUMN core_cif_addresses.addr_settlement IS 'Населённый пункт / СОАТО (СПР 104)';
COMMENT ON COLUMN core_cif_addresses.addr_district IS 'Район (СПР 052) — addr_region bilan mos kelishi shart';

-- ----------------------------------------------------------------------------
-- 11. core_cif_contacts — КОНТАКТЫ (1:N) — telefon/email/fax/web
--     contact_type: PHONE, MOBILE, WORK_PHONE, FAX, EMAIL, WEB.
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_contacts (
    contact_id         NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients
    contact_type       VARCHAR2(20)  NOT NULL,                 -- PHONE/MOBILE/WORK_PHONE/FAX/EMAIL/WEB
    contact_value      VARCHAR2(255) NOT NULL,                 -- qiymat (raqam/email/url)
    is_primary         CHAR(1)       DEFAULT 'N' NOT NULL,     -- asosiy kontaktmi (Y/N)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_contacts_pk     PRIMARY KEY (contact_id),
    CONSTRAINT core_cif_contacts_cl_fk  FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_contacts_type_ck CHECK (contact_type IN ('PHONE','MOBILE','WORK_PHONE','FAX','EMAIL','WEB')),
    CONSTRAINT core_cif_contacts_pri_ck  CHECK (is_primary IN ('Y','N'))
);

COMMENT ON TABLE  core_cif_contacts              IS 'SIRIUS «Контакты» (1:N) — Телефон/Мобильный/Рабочий/fax/E-mail/web';
COMMENT ON COLUMN core_cif_contacts.client_id    IS 'FK -> core_cif_clients';
COMMENT ON COLUMN core_cif_contacts.contact_type IS 'Kontakt turi: PHONE (Телефон), MOBILE (Мобильный), WORK_PHONE (Рабочий), FAX, EMAIL, WEB';

-- ----------------------------------------------------------------------------
-- 11a. core_cif_beneficiaries — БЕНЕФИЦИАРНЫЕ СОБСТВЕННИКИ (1:N, юрлицо)
--     Yur kartasida «Бенефициарные собственники» bo'limi (yur l.3279) — AML
--     uchun muhim. Har qator bitta benefitsiar (физ/юр), ulush номинал+foiz.
--     founder/manager person-blokiga o'xshash; NUMBER(20,2) ulush (float YO'Q).
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_beneficiaries (
    beneficiary_id     NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients (ota юрлицо)
    beneficiary_kind   CHAR(1)       NOT NULL,                 -- P=физ. лицо, J=юр. лицо (diskriminator)

    -- --- Бенефициар = физ. лицо -------------------------------------------
    benef_name         VARCHAR2(200),                          -- Ф.И.О бенефициара (физ)
    benef_pinfl        VARCHAR2(14),                           -- ПИНФЛ бенефициара (физ)
    benef_doc_type     VARCHAR2(2),                            -- тип документа (СПР 008)
    benef_doc_serial   VARCHAR2(4),                            -- серия документа
    benef_doc_number   VARCHAR2(9),                            -- номер документа

    -- --- Бенефициар = юр. лицо --------------------------------------------
    benef_inn          VARCHAR2(9),                            -- ИНН бенефициара (юр)
    benef_client_name  VARCHAR2(200),                          -- наименование бенефициара (юр)

    -- --- Ulush (foiz/pul) -------------------------------------------------
    benef_share_percent NUMBER(20,2),                          -- доля бенефициара (%)
    benef_paid_amount   NUMBER(20,2),                          -- доля бенефициара (номинал, pul!)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_benef_pk      PRIMARY KEY (beneficiary_id),
    CONSTRAINT core_cif_benef_cl_fk   FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_benef_kind_ck CHECK (beneficiary_kind IN ('P','J'))
);

COMMENT ON TABLE  core_cif_beneficiaries               IS 'SIRIUS «Бенефициарные собственники» (1:N, юрлицо; yur l.3279) — AML benefitsiar egalar';
COMMENT ON COLUMN core_cif_beneficiaries.client_id      IS 'FK -> core_cif_clients (ota юрлицо)';
COMMENT ON COLUMN core_cif_beneficiaries.beneficiary_kind IS 'Benefitsiar turi: P=физ. лицо, J=юр. лицо';
COMMENT ON COLUMN core_cif_beneficiaries.benef_pinfl    IS 'ПИНФЛ бенефициара (физ)';
COMMENT ON COLUMN core_cif_beneficiaries.benef_inn      IS 'ИНН бенефициара (юр)';
COMMENT ON COLUMN core_cif_beneficiaries.benef_share_percent IS 'доля бенефициара (%) — NUMBER(20,2)';
COMMENT ON COLUMN core_cif_beneficiaries.benef_paid_amount   IS 'доля бенефициара (номинал) — NUMBER(20,2), pul (float YO''Q)';

-- ----------------------------------------------------------------------------
-- 11b. core_cif_client_roles — РОЛИ КЛИЕНТА (1:N) — ko'p-rolli to'plam
--     Mijoz bir vaqtda bir nechta rolda bo'lishi mumkin: заёмщик, залогодатель,
--     поручитель, депозитор, картадержатель, уполномоченное лицо, сотрудник,
--     Связанное лицо (fiz l.1994-2003, yur l.3552 — additional_role СПР).
--     primary_role (kesh) faqat asosiy rolni saqlaydi; bu jadval to'liq to'plam.
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_client_roles (
    role_pk            NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients
    role_code          VARCHAR2(20)  NOT NULL,                 -- rol kodi (СПР роли клиента, masalan BORROWER/PLEDGER/GUARANTOR/DEPOSITOR/CARDHOLDER/AUTHORIZED/EMPLOYEE/RELATED)
    is_primary         CHAR(1)       DEFAULT 'N' NOT NULL,     -- asosiy rolmi (Y/N)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_roles_pk      PRIMARY KEY (role_pk),
    CONSTRAINT core_cif_roles_cl_fk   FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_roles_pri_ck  CHECK (is_primary IN ('Y','N')),
    -- bir mijozda bir rol bir marta
    CONSTRAINT core_cif_roles_uk      UNIQUE (client_id, role_code)
);

COMMENT ON TABLE  core_cif_client_roles            IS 'SIRIUS «Роли клиента» (1:N) — ko''p-rolli to''plam (заёмщик/залогодатель/поручитель/депозитор/картадержатель/уполномоченное лицо/сотрудник/Связанное лицо; fiz l.1994-2003, yur l.3552)';
COMMENT ON COLUMN core_cif_client_roles.client_id  IS 'FK -> core_cif_clients';
COMMENT ON COLUMN core_cif_client_roles.role_code  IS 'Rol kodi (СПР роли клиента)';
COMMENT ON COLUMN core_cif_client_roles.is_primary IS 'Asosiy rolmi (Y/N) — primary_role kesh bilan mos';

-- ----------------------------------------------------------------------------
-- 11c. core_cif_arrests — АРЕСТ И БЛОКИРОВКА (1:N)
--     Mijoz kartasidagi «Арест и блокировка» bo'limi (fiz l.2195-2235):
--     дата ареста / организация / причина ареста. Operatsion ahamiyatli.
-- ----------------------------------------------------------------------------
CREATE TABLE core_cif_arrests (
    arrest_id          NUMBER(12)    NOT NULL,                 -- surrogat PK
    client_id          NUMBER(10)    NOT NULL,                 -- FK -> core_cif_clients
    arrest_date        DATE,                                   -- дата ареста
    organization       VARCHAR2(255),                          -- организация (qaror chiqargan organ)
    reason             VARCHAR2(500),                          -- причина ареста / блокировки
    release_date       DATE,                                   -- дата снятия ареста (yechilgan sana)
    is_active          CHAR(1)       DEFAULT 'Y' NOT NULL,     -- amaldagi cheklov (Y/N)

    -- --- Audit ------------------------------------------------------------
    created_by         NUMBER(9),
    created_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by         NUMBER(9),
    updated_at         TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT core_cif_arrests_pk    PRIMARY KEY (arrest_id),
    CONSTRAINT core_cif_arrests_cl_fk FOREIGN KEY (client_id)
        REFERENCES core_cif_clients(client_id) ON DELETE CASCADE,
    CONSTRAINT core_cif_arrests_act_ck CHECK (is_active IN ('Y','N'))
);

COMMENT ON TABLE  core_cif_arrests              IS 'SIRIUS «Арест и блокировка» (1:N; fiz l.2195-2235) — hisob/mijoz arest va bloklash yozuvlari';
COMMENT ON COLUMN core_cif_arrests.client_id    IS 'FK -> core_cif_clients';
COMMENT ON COLUMN core_cif_arrests.arrest_date  IS 'дата ареста';
COMMENT ON COLUMN core_cif_arrests.organization IS 'организация — qaror chiqargan organ';
COMMENT ON COLUMN core_cif_arrests.reason       IS 'причина ареста / блокировки';

-- ----------------------------------------------------------------------------
-- 11d. ДОСТУП ПОДКЛЮЧЕНИЙ / ДБО (connection_access) — kanal ulanishi
--     fiz l.2182-2192, yur l.3808 «Доступ подключений» (SMS/Mobile/Internet
--     banking kanallari). Sodda skalar kesh — core_cif_clients.connection_access
--     (СПР kanal kodlari, vergul bilan); kengaytirilsa 1:N jadval qo'shiladi.
-- ----------------------------------------------------------------------------
ALTER TABLE core_cif_clients ADD (
    connection_access VARCHAR2(100)                            -- Доступ подключений (ДБО kanallar, СПР; vergulli)
);
COMMENT ON COLUMN core_cif_clients.connection_access IS 'Доступ подключений / ДБО kanallari (SMS/Mobile/Internet; fiz l.2182-2192, yur l.3808)';

-- ----------------------------------------------------------------------------
-- 12. Indexlar — qidiruv/FK ustunlari (client_code, type, status, INN, PINFL, region)
-- ----------------------------------------------------------------------------
-- BAZA
-- Код клиента (НИББД): client_code qidiruv indexi core_cif_clients_code_uk
-- UNIQUE constraint tomonidan AVTOMATIK yaratiladi — alohida index KERAK EMAS.
-- Тип клиента (СПР 21) FK
CREATE INDEX core_cif_clients_type_idx   ON core_cif_clients (client_type);
-- Состояние клиента FK
CREATE INDEX core_cif_clients_status_idx ON core_cif_clients (client_status);
-- физ/юр/ИП filtr
CREATE INDEX core_cif_clients_kind_idx   ON core_cif_clients (client_kind);
-- СПР 52 FK (region+rayon)
CREATE INDEX core_cif_clients_region_idx ON core_cif_clients (region_code, district_code);
-- nom bo'yicha qidiruv
CREATE INDEX core_cif_clients_name_idx   ON core_cif_clients (full_name);
-- НИББД vaqtinchalik kod 10-kun muddati skani
CREATE INDEX core_cif_clients_temp_idx   ON core_cif_clients (nibbd_temp_expiry);
-- ФИЗ
-- ПИНФЛ qidiruv (rezident kaliti)
CREATE INDEX core_cif_individual_pinfl_idx ON core_cif_individual (pinfl);
-- ИНН qidiruv
CREATE INDEX core_cif_individual_tin_idx   ON core_cif_individual (tin);
-- ЮР/ИП
-- ПИНФЛ (ИП) — oddiy qidiruv
CREATE INDEX core_cif_legal_pinfl_idx    ON core_cif_legal (pinfl);
-- СПР 52 FK (registratsiya region+rayon)
CREATE INDEX core_cif_legal_reg_idx      ON core_cif_legal (region_registr, district_registr);
-- юрлицо ИНН noyobligi — SHARTLI (NULL bo'lsa indekslanmaydi -> ИП ИНН'siz OK).
-- ИП ham ИНН qo'ysa shu kalit bo'yicha dedup bo'ladi (ИНН tabiatan global noyob).
CREATE UNIQUE INDEX core_cif_legal_inn_uix ON core_cif_legal
    (CASE WHEN inn IS NOT NULL THEN inn END);
-- ИП noyobligi: ПИНФЛ (rezident kaliti) — NULL bo'lsa indekslanmaydi
CREATE UNIQUE INDEX core_cif_legal_ip_pinfl_uix ON core_cif_legal
    (CASE WHEN pinfl IS NOT NULL THEN pinfl END);
-- ИП noyobligi: hujjat uchligi (тип+серия+номер) — norezident kaliti
CREATE UNIQUE INDEX core_cif_legal_ip_doc_uix ON core_cif_legal
    (CASE WHEN ip_doc_number IS NOT NULL
          THEN ip_doc_type || ':' || ip_doc_serial || ':' || ip_doc_number END);
-- Bola jadvallar FK indexlari (ota o'chirilganda lock/skan tezligi uchun)
CREATE INDEX core_cif_founders_cl_idx    ON core_cif_founders (client_id);
CREATE INDEX core_cif_managers_cl_idx    ON core_cif_managers (client_id);
CREATE INDEX core_cif_managers_rel_idx   ON core_cif_managers (related_client_id);
CREATE INDEX core_cif_managers_pinfl_idx ON core_cif_managers (manager_pinfl);
CREATE INDEX core_cif_documents_cl_idx   ON core_cif_documents (client_id);
CREATE INDEX core_cif_addresses_cl_idx   ON core_cif_addresses (client_id);
CREATE INDEX core_cif_addresses_reg_idx  ON core_cif_addresses (addr_region, addr_district);
CREATE INDEX core_cif_contacts_cl_idx    ON core_cif_contacts (client_id);
-- Yangi 1:N bola jadvallar FK indexlari
CREATE INDEX core_cif_benef_cl_idx       ON core_cif_beneficiaries (client_id);
CREATE INDEX core_cif_roles_cl_idx       ON core_cif_client_roles (client_id);
CREATE INDEX core_cif_arrests_cl_idx     ON core_cif_arrests (client_id);

-- ----------------------------------------------------------------------------
-- 13. BIU Triggerlar — surrogat id (sequence) + audit (created/updated_at,
--     r_uid). client_code generatsiyasi TURGA BOG'LIQ:
--       - Физ (kind='P'): kod berilmagan bo'lsa MODUL beradi —
--         core_cif_phys_code_seq (60000001..69999999); 8 xona LPAD.
--       - Юр/ИП (kind='J'/'I'): kod НИББД tashqi beradi — trigger TEGMAYDI.
--     Trigger yana:
--       - INSERT da surrogat PK ni sequence dan oladi (agar berilmagan bo'lsa),
--       - created_at/updated_at ni SYSTIMESTAMP qiladi, r_uid ni oshiradi,
--       - nibbd_temp_expiry ni created + 10 kun qiladi (temp kod mavjud bo'lsa).
-- ----------------------------------------------------------------------------

-- 13.1 core_cif_clients BIU
CREATE OR REPLACE TRIGGER core_cif_clients_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_clients
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.client_id IS NULL THEN
            :NEW.client_id := core_cif_clients_seq.NEXTVAL;     -- surrogat PK
        END IF;
        :NEW.created_at := SYSTIMESTAMP;                        -- Дата открытия
        :NEW.r_uid := 0;                                        -- versiya 0 dan
        -- Физ client_code MODUL tomonidan beriladi (fiz l.2470-2474):
        -- 8 xona, 60000001..69999999. Юр/ИП kodi НИББД'dan — TEGMAYDI.
        IF :NEW.client_kind = 'P' AND :NEW.client_code IS NULL THEN
            :NEW.client_code := LPAD(TO_CHAR(core_cif_phys_code_seq.NEXTVAL), 8, '0');
        END IF;
        -- НИББД vaqtinchalik kod (10-kun qoidasi): temp kod bor, muddat yo'q -> +10 kun
        IF :NEW.nibbd_temp_code IS NOT NULL AND :NEW.nibbd_temp_expiry IS NULL THEN
            :NEW.nibbd_temp_expiry := TRUNC(SYSDATE) + 10;
        END IF;
        -- Юр/ИП (J/I) client_code AVTO-GEN QILINMAYDI — НИББД kiritadi.
    END IF;
    IF UPDATING THEN
        :NEW.r_uid := NVL(:OLD.r_uid, 0) + 1;                  -- версия записи +1
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;                           -- Дата изменения
END;
/

-- 13.2 core_cif_individual BIU (PK = client_id, sequence YO'Q — 1:1 ota PK)
CREATE OR REPLACE TRIGGER core_cif_individual_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_individual
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.3 core_cif_legal BIU (PK = client_id, sequence YO'Q — 1:1 ota PK)
CREATE OR REPLACE TRIGGER core_cif_legal_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_legal
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.4 core_cif_founders BIU
CREATE OR REPLACE TRIGGER core_cif_founders_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_founders
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.founder_id IS NULL THEN
            :NEW.founder_id := core_cif_founders_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.5 core_cif_managers BIU
CREATE OR REPLACE TRIGGER core_cif_managers_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_managers
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.manager_id IS NULL THEN
            :NEW.manager_id := core_cif_managers_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.6 core_cif_documents BIU
CREATE OR REPLACE TRIGGER core_cif_documents_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_documents
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.document_id IS NULL THEN
            :NEW.document_id := core_cif_documents_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.7 core_cif_addresses BIU
CREATE OR REPLACE TRIGGER core_cif_addresses_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_addresses
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.address_id IS NULL THEN
            :NEW.address_id := core_cif_addresses_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.8 core_cif_contacts BIU
CREATE OR REPLACE TRIGGER core_cif_contacts_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_contacts
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.contact_id IS NULL THEN
            :NEW.contact_id := core_cif_contacts_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.9 core_cif_beneficiaries BIU
CREATE OR REPLACE TRIGGER core_cif_beneficiaries_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_beneficiaries
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.beneficiary_id IS NULL THEN
            :NEW.beneficiary_id := core_cif_beneficiaries_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.10 core_cif_client_roles BIU
CREATE OR REPLACE TRIGGER core_cif_client_roles_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_client_roles
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.role_pk IS NULL THEN
            :NEW.role_pk := core_cif_client_roles_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- 13.11 core_cif_arrests BIU
CREATE OR REPLACE TRIGGER core_cif_arrests_biu_trg
BEFORE INSERT OR UPDATE ON core_cif_arrests
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.arrest_id IS NULL THEN
            :NEW.arrest_id := core_cif_arrests_seq.NEXTVAL;
        END IF;
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/

-- ============================================================================
-- 10_cif_schema.sql — TUGADI
-- Keyingi: 11_cif_packages (SIRIUS PL/SQL qatlamlar: const/types/util/logger/
--   data_reader/repo/rules/service + НИББД interfeysi), 12_cif_views,
--   13_cif_seed, va core_acc_accounts.client_id FK ulanishi (alohida skript).
-- ============================================================================

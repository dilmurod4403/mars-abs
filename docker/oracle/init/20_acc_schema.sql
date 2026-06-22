-- ============================================================================
-- MARS ABS (mars-abs) — REAL SIRIUS build, F0
-- 20_acc_schema.sql — core_acc_accounts (SIRIUS «Счета» — hisoblar moduli)
--
-- Oracle 21c XE. Naming: MARS konvensiyasi (core_acc_*).
-- Pul/saldo/oborot — eng kichik birlikda (TIYIN/cent), butun son NUMBER(20).
-- Scale/float/double HECH QACHON. 1 so'm = 100 tiyin (UI da /100 ko'rsatiladi).
-- Hisob raqami (20 xona): CMMSS(5) + VVV(3) + K(1) + XXXXXXXX(8) + NNN(3)
--   CMMSS    — Балансовый номер (balans hisobi, core_ref_coa, СПР 19)
--   VVV      — Код валюты (valyuta, core_ref_currency, СПР 017; so'm = '000')
--   K        — Контрольный ключ (kontrol kalit, Mod-11, ASCII qo'shni-raqam)
--   XXXXXXXX — код клиента = client_code (НИББД 8 xona; mijozning yagona kodi)
--   NNN      — Порядковый номер счета (tartib raqami, 001..999)
--
-- SPEC CODE-NAME CONTRACT (Счета.doc «Структура данных счета»):
--   * 20-xonali hisob raqami реквизит kod-nomi  = `code`  (DDL: account_number, izoh alias)
--   * Lifecycle «Состояние счета»                = `state`  (FK core_acc_status)
--   * M/O «Статус счета» (O-ВТОРИЧНЫЙ/M-ПЕРВИЧНЫЙ)= `status` (CHECK M/O, auto-assign)
--   * Pul (F tipi) — eng kichik birlikda (tiyin)  → NUMBER(20) butun son
--   * mijoz kodi `client_code` (XXXXXXXX) = 8 знаков → VARCHAR2(8) (реквiz-jadval "5" XATO; bnd 1837/1843)
--
-- Old shartlar: core_ref_* (00_ref_spravochniklar.sql) va
--               core_acc_util (01_acc_util.sql) allaqachon o'rnatilgan bo'lsin.
-- ============================================================================

-- SQL*Plus sozlamalari (runner-mustaqil): bo'sh qatorlar bayonotni uzmasin
-- (CREATE TABLE/trigger ichidagi bo'limlar orasida bo'sh qatorlar bor), va
-- &-substitution o'chirilsin (matnlarda & bo'lishi mumkin).
SET SQLBLANKLINES ON
SET DEFINE OFF

-- ----------------------------------------------------------------------------
-- 1. Idempotent DROP — FK-xavfsiz tartibda (avval bola, keyin ota)
-- ----------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER core_acc_accounts_biu_trg'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_acc_accounts CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_acc_status CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE core_acc_accounts_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- 2. core_acc_status — holatlar lug'ati («Виды состояния счета», SIRIUS §3)
--    Bare CHECK o'rniga FK-li lookup — sodiqroq (state + sub-state lar bilan).
--    is_substate = 'Y' — «Создан» holatining ichki statuslari (статус клиента):
--    «на утверждение», AML va НИББД sub-state lari.
--
--    14 holat (spec «Виды состояния счета» to'liq to'plami):
--      Создан, на утверждение, На проверке AML, Проверен AML,
--      На отправление НИББД, Отправлен НИББД, Обработан НИББД, Утвержден,
--      Временно закрыт, Закрыт, Блокирован, Архивирован, Удален,
--      в ожидании перевода.
-- ----------------------------------------------------------------------------
CREATE TABLE core_acc_status (
    code         VARCHAR2(20)  NOT NULL,   -- holat kodi (ichki)
    name_ru      VARCHAR2(100) NOT NULL,   -- Russian SIRIUS nomi (состояние)
    is_substate  CHAR(1)       DEFAULT 'N' NOT NULL,  -- 'Y' = ichki status (статус)
    is_terminal  CHAR(1)       DEFAULT 'N' NOT NULL,  -- 'Y' = terminal holat
    sort_order   NUMBER(3)     DEFAULT 0   NOT NULL,
    CONSTRAINT core_acc_status_pk PRIMARY KEY (code),
    CONSTRAINT core_acc_status_sub_ck      CHECK (is_substate IN ('Y','N')),
    CONSTRAINT core_acc_status_term_ck     CHECK (is_terminal IN ('Y','N'))
);

COMMENT ON TABLE  core_acc_status            IS 'SIRIUS «Виды состояния счета» — hisob holatlari lug''ati (14 holat: state + «на утверждение»/AML/НИББД sub-state)';
COMMENT ON COLUMN core_acc_status.code        IS 'Holat kodi (ichki, core_acc_accounts.state FK manbasi)';
COMMENT ON COLUMN core_acc_status.name_ru     IS 'Состояние счета — Russian SIRIUS nomi';
COMMENT ON COLUMN core_acc_status.is_substate IS '«Создан» holatining «на утверждение»/AML/НИББД ichki statusimi (статус клиента)';

-- 14 holat: Создан + «на утверждение» + 5 AML/НИББД sub-state ->
--           Утвержден -> Временно закрыт -> Закрыт -> Блокирован ->
--           Архивирован -> Удален -> в ожидании перевода
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('CREATED',       'Создан',                  'N', 'N',  1);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('TO_APPROVE',    'на утверждение',          'Y', 'N',  2);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('AML_CHECK',     'На проверке AML',         'Y', 'N',  3);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('AML_PASSED',    'Проверен AML',            'Y', 'N',  4);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_TO_SEND', 'На отправление НИББД',    'Y', 'N',  5);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_SENT',    'Отправлен НИББД',         'Y', 'N',  6);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('NIBBD_DONE',    'Обработан НИББД',         'Y', 'N',  7);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('APPROVED',      'Утвержден',               'N', 'N',  8);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('TEMP_CLOSED',   'Временно закрыт',         'N', 'N',  9);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('CLOSED',        'Закрыт',                  'N', 'N', 10);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('BLOCKED',       'Блокирован',              'N', 'N', 11);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('ARCHIVED',      'Архивирован',             'N', 'N', 12);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('DELETED',       'Удален',                  'N', 'Y', 13);
INSERT INTO core_acc_status (code, name_ru, is_substate, is_terminal, sort_order) VALUES ('AWAIT_TRANSFER','в ожидании перевода',     'N', 'N', 14);
COMMIT;

-- ----------------------------------------------------------------------------
-- 3. Sequence — surrogat PK (account_id) uchun
--    Eslatma: NNN (seq_number, 3 xona) bu sequence EMAS. NNN har bir
--    (mijoz + balans + valyuta) guruhi ichida 001..999 bo'yicha alohida
--    hisoblanadi (service/repo qatlamida: MAX(seq_number)+1 lock ostida yoki
--    maxsus sanagich). Bu jadval-sath sequence faqat texnik PK uchun.
-- ----------------------------------------------------------------------------
CREATE SEQUENCE core_acc_accounts_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ----------------------------------------------------------------------------
-- 4. core_acc_accounts — «Структура данных счета» (SIRIUS §13)
-- ----------------------------------------------------------------------------
CREATE TABLE core_acc_accounts (
    -- --- Surrogat kalit (texnik) -------------------------------------------
    account_id        NUMBER(12)    NOT NULL,                 -- ID счета (surrogat PK)
    r_uid             NUMBER(12)    DEFAULT 0 NOT NULL,        -- версия записи (row version)

    -- --- Hisob raqami va uning 5 komponenti --------------------------------
    --     SIRIUS реквизит kod-nomi: `code` (DDL alias = account_number).
    account_number    VARCHAR2(20)  NOT NULL,                 -- Счет (SIRIUS `code`) — 20 xonali raqam
    balance_account   VARCHAR2(5)   NOT NULL,                 -- CMMSS — Балансовый номер (core_ref_coa)
    currency_code     VARCHAR2(3)   NOT NULL,                 -- VVV — Код валюты (core_ref_currency)
    control_key       VARCHAR2(1),                            -- K — Контрольный ключ (Mod-11, trigger)
    client_code       VARCHAR2(8)   NOT NULL,                 -- XXXXXXXX — код клиента (НИББД 8 xona; mijozning yagona kodi, hisob raqamiga kiradi)
    seq_number        VARCHAR2(3)   NOT NULL,                 -- NNN — Порядковый номер счета (001..999)

    -- --- Mijoz bog'lanishi (client_code yuqorida = XXXXXXXX; core_cif qurilgach FK) -----
    client_id         NUMBER(10),                             -- Клиент ID (core_cif_clients.id — FK keyin)
    client_name       VARCHAR2(200),                          -- Владелец счета (mijoz nomi)
    client_type       VARCHAR2(2),                            -- typeof — mijoz turi (core_ref_client_type, СПР 21)

    -- --- Nomi va tasnif ----------------------------------------------------
    name              VARCHAR2(200) NOT NULL,                 -- Наименование счета
    acc_type          VARCHAR2(6)   NOT NULL,                 -- Тип счета (produkt, masalan SSUDA)
    sub_coa           VARCHAR2(6)   DEFAULT '000000' NOT NULL,-- Субсчет (3 guruh + 3 produkt; baza 000000)
    special_code      VARCHAR2(3),                            -- Специальная характеристика (produkt/deal)
    module_code       VARCHAR2(20),                           -- Код модуля
    group_code        VARCHAR2(9),                            -- Код группы (account group)
    category          NUMBER(3),                              -- Категория
    security_level    NUMBER(4),                              -- Степень доступа
    deal_id           NUMBER(12),                             -- Сделка ID (shartnoma; НИББД 1/2/3 da majburiy)

    -- --- Aktiv/passiv, balans turi, lifecycle + M/O statusi -----------------
    liability_active  VARCHAR2(1),                            -- Признак актив-пассив (СПР 019, balansdan)
    balance_out       VARCHAR2(1),                            -- Признак баланса: B=балансовый, O=внебалансовый
    state             VARCHAR2(20)  DEFAULT 'CREATED' NOT NULL,-- Состояние счета (SIRIUS `state`, FK core_acc_status)
    status            CHAR(1)       NOT NULL,                 -- Статус счета (SIRIUS `status`): M=ПЕРВИЧНЫЙ, O=ВТОРИЧНЫЙ

    -- --- Filial / ofis (СПР 012) -------------------------------------------
    branch_code       VARCHAR2(5)   NOT NULL,                 -- Код филиала (core_ref_branch, СПР 012)
    branch_cb_code    VARCHAR2(5),                            -- Код офиса банковских услуг (СПР 012)

    -- --- Saldo / oborot — barchasi NUMBER (F tipi = number(20,2), float YO'Q)
    saldo_in          NUMBER(20)  DEFAULT 0 NOT NULL,       -- Входящий сальдо
    saldo_out         NUMBER(20)  DEFAULT 0 NOT NULL,       -- Исходящий сальдо (= Остаток счета)
    saldo_equival_in  NUMBER(20)  DEFAULT 0 NOT NULL,       -- Входящий сальдо в эквиваленте
    saldo_equival_out NUMBER(20)  DEFAULT 0 NOT NULL,       -- Исходящий сальдо в эквиваленте
    saldo_unlead      NUMBER(20)  DEFAULT 0 NOT NULL,       -- Непроведённый сальдо (Не проведённый остаток)
    turnover_debit       NUMBER(20) DEFAULT 0 NOT NULL,     -- Дебетовый оборот за день
    turnover_credit      NUMBER(20) DEFAULT 0 NOT NULL,     -- Кредитовый оборот за день
    turnover_all_debit   NUMBER(20) DEFAULT 0 NOT NULL,     -- Дебетовый оборот за весь период
    turnover_all_credit  NUMBER(20) DEFAULT 0 NOT NULL,     -- Кредитовый оборот за весь период
    eqv_turnover_debit       NUMBER(20) DEFAULT 0 NOT NULL, -- Дебетовый оборот за день, в эквиваленте
    eqv_turnover_credit      NUMBER(20) DEFAULT 0 NOT NULL, -- Кредитовый оборот за день, в эквиваленте
    eqv_turnover_all_debit   NUMBER(20) DEFAULT 0 NOT NULL, -- Дебетовый оборот за весь период, в эквиваленте
    eqv_turnover_all_credit  NUMBER(20) DEFAULT 0 NOT NULL, -- Кредитовый оборот за весь период, в эквиваленте

    -- --- Парные счета (контрсчёт) ------------------------------------------
    --     Avtoritetli manba: SIRIUS «Справочник парных счетов»
    --     (balans-nomer + valyuta bo'yicha). Bu ustun faqat hal qilingan
    --     bog'lanishni KESHLAYDI (self-ref), реквизit emas.
    paired_account_id NUMBER(12),                             -- Парный счет ID (контрсчёт kesh, self FK)

    -- --- AML / НИББД -------------------------------------------------------
    reg_nibd          VARCHAR2(1),                            -- Признак регистрации в НИББД (СПР 19: 0/1/2/3/9)
    aml_checked_at    TIMESTAMP,                              -- AML tekshiruvi vaqti (sub-state ilovasi)
    nibbd_reg_at      TIMESTAMP,                              -- НИББД ro'yxatga olingan vaqt

    -- --- Rezidentlik / Единое окно (DENORMALIZED — реквизit EMAS) ----------
    --     resident_flag — biznes QOIDA (norezident -> faqat 20296 balans),
    --     mijoz/hujjat ma'lumotidan kelib chiqadi; bu ustun keshdir.
    --     single_window_ref — yaratish KANALI (ЦГУ/E-GOV), реквизit emas.
    resident_flag     CHAR(1),                                -- Резидентство kesh (Y=rezident, N=norezident)
    single_window_ref VARCHAR2(50),                           -- Единое окно (ЦГУ/E-GOV) kanal havolasi

    -- --- Sanalar -----------------------------------------------------------
    open_date         DATE,                                   -- Hisob ochilgan operatsion kun
    created_oper_day  DATE,                                   -- Дата создания (операционный день)
    modified_oper_day DATE,                                   -- Дата корректировки (операционный день)
    date_last_oper    TIMESTAMP,                              -- Дата последней операции (dormant uchun)
    date_deactivate   TIMESTAMP,                              -- Дата закрытия / деактивации
    close_date        DATE,                                   -- Yopilgan operatsion kun

    -- --- Maker-Checker (ikki bosqichli tasdiqlash) -------------------------
    maker_user        NUMBER(9),                              -- Yaratuvchi (Maker) user id
    checker_user      NUMBER(9),                              -- Tasdiqlovchi (Checker) user id
    approved_at       TIMESTAMP,                              -- Утвердить vaqti (APPROVED ga o'tish)

    -- --- Audit trail -------------------------------------------------------
    created_by        NUMBER(9),                              -- Кем создана (user id)
    created_at        TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,  -- Дата создание счета
    updated_by        NUMBER(9),                              -- Кем корректирован (user id)
    updated_at        TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,  -- Время корректировки

    -- --- Constraints -------------------------------------------------------
    CONSTRAINT core_acc_accounts_pk        PRIMARY KEY (account_id),
    CONSTRAINT core_acc_accounts_num_uk    UNIQUE (account_number),
    CONSTRAINT core_acc_accounts_status_ck CHECK (status IN ('M','O')),             -- M=первичный, O=вторичный
    CONSTRAINT core_acc_accounts_bal_ck    CHECK (balance_out IN ('B','O')),         -- B=балансовый, O=внебалансовый
    CONSTRAINT core_acc_accounts_res_ck    CHECK (resident_flag IN ('Y','N')),
    CONSTRAINT core_acc_accounts_regn_ck   CHECK (reg_nibd IN ('0','1','2','3','9')), -- СПР 19
    CONSTRAINT core_acc_accounts_seqn_ck   CHECK (REGEXP_LIKE(seq_number, '^[0-9]{3}$')),
    -- FK lar — ref-contracts'dagi ANIQ PK ustunlariga
    CONSTRAINT core_acc_accounts_state_fk  FOREIGN KEY (state)           REFERENCES core_acc_status(code),
    CONSTRAINT core_acc_accounts_coa_fk    FOREIGN KEY (balance_account) REFERENCES core_ref_coa(code),
    CONSTRAINT core_acc_accounts_curr_fk   FOREIGN KEY (currency_code)   REFERENCES core_ref_currency(code),
    CONSTRAINT core_acc_accounts_branch_fk FOREIGN KEY (branch_code)     REFERENCES core_ref_branch(code),
    CONSTRAINT core_acc_accounts_pair_fk   FOREIGN KEY (paired_account_id) REFERENCES core_acc_accounts(account_id),
    -- client_id -> core_cif_clients (10_cif_schema 20_acc'dan oldin yuklanadi)
    CONSTRAINT core_acc_accounts_client_fk FOREIGN KEY (client_id)         REFERENCES core_cif_clients(client_id)
);

-- --- Jadval / ustun izohlari (SIRIUS terminlarga moslash) ------------------
COMMENT ON TABLE  core_acc_accounts                   IS 'SIRIUS «Счета» — hisoblar (CMMSS+VVV+K+kod+NNN, state, M/O status, COA, тип, субсчет, saldo/oborot/eqv)';
COMMENT ON COLUMN core_acc_accounts.account_id         IS 'ID счета — surrogat PK (sequence)';
COMMENT ON COLUMN core_acc_accounts.r_uid              IS 'версия записи — row version';
COMMENT ON COLUMN core_acc_accounts.account_number     IS 'Счет — SIRIUS реквизит kod-nomi `code` — 20 xonali hisob raqami (CMMSS+VVV+K+XXXXXXXX+NNN)';
COMMENT ON COLUMN core_acc_accounts.balance_account    IS 'CMMSS — Балансовый номер (FK core_ref_coa, СПР 19)';
COMMENT ON COLUMN core_acc_accounts.currency_code      IS 'VVV — Код валюты (FK core_ref_currency, СПР 017; so''m=000)';
COMMENT ON COLUMN core_acc_accounts.control_key        IS 'K — Контрольный ключ (Mod-11, trigger hisob raqamning 9-pozitsiyasidan ajratadi)';
COMMENT ON COLUMN core_acc_accounts.client_code        IS 'XXXXXXXX — код клиента (НИББД 8 xona; mijoz yagona kodi, hisob raqami segmenti). Fiz: ПМ Клиенты 60000000-69999999; yur/ИП: НИББД';
COMMENT ON COLUMN core_acc_accounts.seq_number         IS 'NNN — Порядковый номер счета (001..999, mijoz+balans+valyuta guruhi bo''yicha)';
COMMENT ON COLUMN core_acc_accounts.client_id          IS 'Клиент ID — core_cif_clients (FK keyin qo''shiladi)';
COMMENT ON COLUMN core_acc_accounts.client_name        IS 'Владелец счета — mijoz nomi';
COMMENT ON COLUMN core_acc_accounts.client_type        IS 'typeof — mijoz turi (СПР 21), balans hisobini tanlash uchun';
COMMENT ON COLUMN core_acc_accounts.name               IS 'Наименование счета';
COMMENT ON COLUMN core_acc_accounts.acc_type           IS 'Тип счета — produkt (masalan SSUDA, RASCH, VKLAD)';
COMMENT ON COLUMN core_acc_accounts.sub_coa            IS 'Субсчет — 3 guruh + 3 produkt (baza 000000)';
COMMENT ON COLUMN core_acc_accounts.special_code       IS 'Специальная характеристика — produkt/deal noyob parametri';
COMMENT ON COLUMN core_acc_accounts.module_code        IS 'Код модуля';
COMMENT ON COLUMN core_acc_accounts.group_code         IS 'Код группы — account group';
COMMENT ON COLUMN core_acc_accounts.deal_id            IS 'Сделка ID — shartnoma raqami (Reg_nibd 1/2/3 da majburiy)';
COMMENT ON COLUMN core_acc_accounts.liability_active   IS 'Признак актив-пассив — balansdan (СПР 019)';
COMMENT ON COLUMN core_acc_accounts.balance_out        IS 'Признак баланса: B=балансовый, O=внебалансовый (9xxxx)';
COMMENT ON COLUMN core_acc_accounts.state              IS 'Состояние счета — SIRIUS реквизит kod-nomi `state`, FK core_acc_status (lifecycle)';
COMMENT ON COLUMN core_acc_accounts.status             IS 'Статус счета — SIRIUS реквизит kod-nomi `status`: M=ПЕРВИЧНЫЙ (asosiy), O=ВТОРИЧНЫЙ (auto-assign справочник bo''yicha)';
COMMENT ON COLUMN core_acc_accounts.branch_code        IS 'Код филиала — FK core_ref_branch (СПР 012)';
COMMENT ON COLUMN core_acc_accounts.branch_cb_code     IS 'Код офиса банковских услуг (СПР 012)';
COMMENT ON COLUMN core_acc_accounts.saldo_out          IS 'Исходящий сальдо = Остаток счета (TIYIN — eng kichik birlik, NUMBER(20) butun)';
COMMENT ON COLUMN core_acc_accounts.saldo_unlead       IS 'Непроведённый сальдо — Не проведённый остаток';
COMMENT ON COLUMN core_acc_accounts.turnover_all_debit IS 'Дебетовый оборот за весь период';
COMMENT ON COLUMN core_acc_accounts.turnover_all_credit IS 'Кредитовый оборот за весь период';
COMMENT ON COLUMN core_acc_accounts.eqv_turnover_debit  IS 'Дебетовый оборот за день, в эквиваленте';
COMMENT ON COLUMN core_acc_accounts.eqv_turnover_credit IS 'Кредитовый оборот за день, в эквиваленте';
COMMENT ON COLUMN core_acc_accounts.eqv_turnover_all_debit  IS 'Дебетовый оборот за весь период, в эквиваленте';
COMMENT ON COLUMN core_acc_accounts.eqv_turnover_all_credit IS 'Кредитовый оборот за весь период, в эквиваленте';
COMMENT ON COLUMN core_acc_accounts.paired_account_id  IS 'Парный счет ID — контрсчёт KESH (self FK). Avtoritetli manba: SIRIUS «Справочник парных счетов» (balans-nomer + valyuta)';
COMMENT ON COLUMN core_acc_accounts.reg_nibd           IS 'Признак регистрации в НИББД (СПР 19: 0/1/2/3/9)';
COMMENT ON COLUMN core_acc_accounts.aml_checked_at     IS 'AML tekshiruvi vaqti (Проверен AML sub-state)';
COMMENT ON COLUMN core_acc_accounts.nibbd_reg_at       IS 'НИББД ro''yxatga olingan vaqt (Обработан НИББД)';
COMMENT ON COLUMN core_acc_accounts.resident_flag      IS 'Резидентство KESH (Y/N) — биznes qoida (norezident -> 20296); реквизit emas, mijoz/hujjatdan kelib chiqadi';
COMMENT ON COLUMN core_acc_accounts.single_window_ref  IS 'Единое окно (ЦГУ/E-GOV) — yaratish KANAL atributi (реквизit emas)';
COMMENT ON COLUMN core_acc_accounts.date_last_oper     IS 'Дата последней операции — dormant (9 oy) hisobi uchun';
COMMENT ON COLUMN core_acc_accounts.date_deactivate    IS 'Дата закрытия / деактивации';
COMMENT ON COLUMN core_acc_accounts.maker_user         IS 'Maker — yaratuvchi user (ikki bosqichli tasdiq)';
COMMENT ON COLUMN core_acc_accounts.checker_user       IS 'Checker — tasdiqlovchi user (Утвердить)';
COMMENT ON COLUMN core_acc_accounts.approved_at        IS 'Утвердить vaqti — APPROVED holatga o''tish';
COMMENT ON COLUMN core_acc_accounts.created_at         IS 'Дата создание счета — audit';
COMMENT ON COLUMN core_acc_accounts.updated_at         IS 'Время корректировки — audit';

-- ----------------------------------------------------------------------------
-- 5. Indekslar — qidiruv / hisobot yo'llari
--    Eslatma: account_number bo'yicha indeks UNIQUE constraint
--    (core_acc_accounts_num_uk) tomonidan AVTOMATIK yaratiladi — alohida
--    CREATE INDEX qo'shilsa ORA-01408 (column list already indexed). Shu sabab
--    bu yerda account_number indeksi YO'Q.
-- ----------------------------------------------------------------------------
-- mijoz реквизit bo'yicha
CREATE INDEX core_acc_accounts_client_idx ON core_acc_accounts (client_code);
-- balans hisobi bo'yicha
CREATE INDEX core_acc_accounts_coa_idx    ON core_acc_accounts (balance_account);
-- holat (lifecycle) bo'yicha (ro'yxat/filtr)
CREATE INDEX core_acc_accounts_state_idx  ON core_acc_accounts (state);

-- ----------------------------------------------------------------------------
-- 6. Trigger — core_acc_accounts_biu_trg (BEFORE INSERT OR UPDATE)
--    INSERT:  account_id <- sequence; agar account_number berilmagan bo'lsa,
--             core_acc_util.Generate_Account_Number(balance, currency,
--             client_code, seq) ANIQ imzosi bilan generatsiya; control_key
--             9-pozitsiyadan ajratiladi; M/O status (agar berilmagan bo'lsa)
--             SIRIUS «справочник» semantikasi bo'yicha avto: pair mavjud emas
--             bo'lsa default M (первичный); created/updated_at <- SYSTIMESTAMP.
--    UPDATE:  updated_at <- SYSTIMESTAMP; r_uid oshiriladi.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER core_acc_accounts_biu_trg
BEFORE INSERT OR UPDATE ON core_acc_accounts
FOR EACH ROW
DECLARE
    v_acc VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        -- Surrogat PK
        IF :NEW.account_id IS NULL THEN
            :NEW.account_id := core_acc_accounts_seq.NEXTVAL;
        END IF;

        -- 20 xonali hisob raqami: util ANIQ imzosi (barchasi VARCHAR2, qat'iy en)
        --   CMMSS(5) + VVV(3) + client_code(8) + NNN(3) ; util K ni 9-pozitsiyaga qo'yadi
        IF :NEW.account_number IS NULL THEN
            v_acc := core_acc_util.Generate_Account_Number(
                         LPAD(:NEW.balance_account, 5, '0'),   -- i_balance — CMMSS
                         LPAD(:NEW.currency_code,   3, '0'),   -- i_currency — VVV
                         LPAD(:NEW.client_code,     8, '0'),   -- i_client — XXXXXXXX (НИББД mijoz kodi)
                         LPAD(:NEW.seq_number,      3, '0'));  -- i_seq — NNN
            :NEW.account_number := v_acc;
        END IF;

        -- Kontrol kalitni hisob raqamining 9-pozitsiyasidan ajratish (K)
        IF :NEW.account_number IS NOT NULL AND LENGTH(:NEW.account_number) = 20 THEN
            :NEW.control_key := SUBSTR(:NEW.account_number, 9, 1);
        END IF;

        -- M/O statusi (SIRIUS «Присваивается автоматически»): caller bermasa,
        -- default M (ПЕРВИЧНЫЙ). To'liq qoida — «справочник парных счетов»
        -- (balans-nomer+valyuta+NNN) bo'yicha service qatlamida aniqlanadi.
        IF :NEW.status IS NULL THEN
            :NEW.status := 'M';
        END IF;

        -- Audit vaqtlari
        :NEW.created_at := SYSTIMESTAMP;
        :NEW.updated_at := SYSTIMESTAMP;
        IF :NEW.r_uid IS NULL THEN
            :NEW.r_uid := 0;
        END IF;

    ELSIF UPDATING THEN
        :NEW.updated_at := SYSTIMESTAMP;
        :NEW.r_uid := NVL(:OLD.r_uid, 0) + 1;   -- версия записи oshiriladi
    END IF;
END core_acc_accounts_biu_trg;
/

-- ============================================================================
-- 20_acc_schema.sql — tugadi.
-- ============================================================================

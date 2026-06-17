-- Bank tizimi schema (BANKUSER sxemasida)

CREATE TABLE customers (
    customer_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR2(100)  NOT NULL,
    last_name     VARCHAR2(100)  NOT NULL,
    phone         VARCHAR2(20),
    email         VARCHAR2(150),
    passport_num  VARCHAR2(20)   NOT NULL UNIQUE,
    birth_date    DATE,
    address       VARCHAR2(500),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BLOCKED', 'CLOSED'))
);

CREATE TABLE accounts (
    account_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   NUMBER         NOT NULL REFERENCES customers(customer_id),
    account_num   VARCHAR2(20)   NOT NULL UNIQUE,
    account_type  VARCHAR2(20)   NOT NULL CHECK (account_type IN ('SAVINGS', 'CHECKING', 'DEPOSIT')),
    currency      VARCHAR2(3)    DEFAULT 'UZS' CHECK (currency IN ('UZS', 'USD', 'EUR')),
    balance       NUMBER(18,2)   DEFAULT 0 CHECK (balance >= 0),
    opened_at     TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR2(20)   DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED'))
);

CREATE TABLE transactions (
    txn_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_account  NUMBER         REFERENCES accounts(account_id),
    to_account    NUMBER         REFERENCES accounts(account_id),
    txn_type      VARCHAR2(20)   NOT NULL CHECK (txn_type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL')),
    amount        NUMBER(18,2)   NOT NULL CHECK (amount > 0),
    currency      VARCHAR2(3)    DEFAULT 'UZS',
    description   VARCHAR2(500),
    txn_date      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR2(20)   DEFAULT 'COMPLETED' CHECK (status IN ('COMPLETED', 'PENDING', 'FAILED', 'REVERSED'))
);

CREATE INDEX idx_txn_from ON transactions(from_account);
CREATE INDEX idx_txn_to   ON transactions(to_account);
CREATE INDEX idx_txn_date ON transactions(txn_date);
CREATE INDEX idx_acc_cust ON accounts(customer_id);

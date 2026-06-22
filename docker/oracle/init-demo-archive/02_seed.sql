-- Test ma'lumotlar

INSERT INTO customers (first_name, last_name, phone, email, passport_num, birth_date, address)
VALUES ('Dilmurod', 'Qayyumov', '+998901234567', 'dilmurod@fido.uz', 'AA1234567', DATE '1995-03-15', 'Toshkent sh., Chilonzor t.');

INSERT INTO customers (first_name, last_name, phone, email, passport_num, birth_date, address)
VALUES ('Aziza', 'Karimova', '+998931112233', 'aziza@fido.uz', 'AB7654321', DATE '1998-07-22', 'Toshkent sh., Yunusobod t.');

INSERT INTO customers (first_name, last_name, phone, email, passport_num, birth_date, address)
VALUES ('Jasur', 'Toshmatov', '+998945556677', 'jasur@fido.uz', 'AC1122334', DATE '1990-11-05', 'Samarqand sh., Registon k.');

INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
VALUES (1, '86001001000001', 'CHECKING', 'UZS', 15000000.00);

INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
VALUES (1, '86001001000002', 'SAVINGS', 'USD', 5200.50);

INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
VALUES (2, '86001002000001', 'CHECKING', 'UZS', 8500000.00);

INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
VALUES (3, '86001003000001', 'CHECKING', 'UZS', 22000000.00);

INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
VALUES (3, '86001003000002', 'DEPOSIT', 'UZS', 50000000.00);

INSERT INTO transactions (from_account, to_account, txn_type, amount, currency, description)
VALUES (1, 3, 'TRANSFER', 1000000.00, 'UZS', 'Oylik tolov');

INSERT INTO transactions (from_account, to_account, txn_type, amount, currency, description)
VALUES (4, 1, 'TRANSFER', 500000.00, 'UZS', 'Qaytarilgan qarz');

INSERT INTO transactions (from_account, to_account, txn_type, amount, currency, description)
VALUES (NULL, 1, 'DEPOSIT', 5000000.00, 'UZS', 'Naqd pul kiritish');

INSERT INTO transactions (from_account, to_account, txn_type, amount, currency, description)
VALUES (3, NULL, 'WITHDRAWAL', 2000000.00, 'UZS', 'Bankomat orqali yechish');

COMMIT;

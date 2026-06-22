-- ============================================================================
-- MARS ABS - core_cif moduli
-- 07_cif_seed.sql - Test ma'lumotlar (seed data)
-- Sana: 2026-05-26
--
-- Qoidalar:
--   S-3: INSERT ustun ro'yxati bilan
--   S-4: TO_DATE format mask bilan
-- ============================================================================

-- ==========================================================================
-- 1. FYaSh (INDIVIDUAL) mijozlar
-- ==========================================================================

-- 1.1 FYaSh — ACTIVE holatda
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    first_name, last_name, middle_name,
    pinfl, birth_date, birth_place, gender,
    phone, email,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep, opening_purpose,
    employer_name, employer_position,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260501-000001', 'INDIVIDUAL',
    'Dilmurod', 'Qayyumov', 'Baxtiyorovich',
    '12345678901234', TO_DATE('1995-03-15', 'YYYY-MM-DD'), 'Toshkent shahri', 'M',
    '+998901234567', 'dilmurod@fido.uz',
    'Toshkent sh., Chilonzor t., 7-mavze', 'Toshkent sh., Chilonzor t., 7-mavze',
    'Y', 'UZB', '00191', '1001',
    'LOW', 'N', 'Shaxsiy ehtiyojlar',
    'Fido Bank', 'Dasturchi',
    'ACTIVE', 'supervisor1', SYSTIMESTAMP,
    'operator1', SYSTIMESTAMP
);

-- 1.2 FYaSh — ACTIVE, PEP=Y -> HIGH risk
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    first_name, last_name, middle_name,
    pinfl, birth_date, birth_place, gender,
    phone, email,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep, opening_purpose,
    employer_name, employer_position,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260501-000002', 'INDIVIDUAL',
    'Aziza', 'Karimova', 'Rustamovna',
    '23456789012345', TO_DATE('1988-07-22', 'YYYY-MM-DD'), 'Samarqand shahri', 'F',
    '+998931112233', 'aziza.k@mail.uz',
    'Toshkent sh., Yunusobod t., 4-kvartal', 'Toshkent sh., Yunusobod t., 4-kvartal',
    'Y', 'UZB', '00191', '1001',
    'HIGH', 'Y', 'Investitsiya',
    'O''zbekiston Davlat Soliq Qo''mitasi', 'Bosh mutaxassis',
    'ACTIVE', 'supervisor1', SYSTIMESTAMP,
    'operator2', SYSTIMESTAMP
);

-- 1.3 FYaSh — PENDING (tasdiqlash kutmoqda)
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    first_name, last_name, middle_name,
    pinfl, birth_date, birth_place, gender,
    phone,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    employer_name, employer_position,
    status,
    created_by, created_at
) VALUES (
    'CIF-20260520-000003', 'INDIVIDUAL',
    'Jasur', 'Toshmatov', 'Abdullayevich',
    '34567890123456', TO_DATE('1990-11-05', 'YYYY-MM-DD'), 'Samarqand shahri', 'M',
    '+998945556677',
    'Samarqand sh., Registon ko''chasi 12', 'Samarqand sh., Registon ko''chasi 12',
    'Y', 'UZB', '00191', '1001',
    'LOW', 'N',
    'Samarqand viloyat hokimligi', 'Mutaxassis',
    'PENDING',
    'operator1', SYSTIMESTAMP
);

-- 1.4 FYaSh — BLOCKED holatda
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    first_name, last_name, middle_name,
    pinfl, birth_date, birth_place, gender,
    phone, email,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260401-000004', 'INDIVIDUAL',
    'Nodira', 'Aliyeva', 'Shamsiddinovna',
    '45678901234567', TO_DATE('1992-01-10', 'YYYY-MM-DD'), 'Buxoro shahri', 'F',
    '+998977778899', 'nodira.a@gmail.com',
    'Buxoro sh., Mustaqillik ko''chasi 5', 'Toshkent sh., Mirzo Ulug''bek t.',
    'Y', 'UZB', '00191', '1001',
    'MEDIUM', 'N',
    'BLOCKED', 'supervisor1', SYSTIMESTAMP,
    'operator2', SYSTIMESTAMP
);

-- 1.5 FYaSh — Norezident
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    first_name, last_name,
    pinfl, birth_date, birth_place, gender,
    phone, email,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260510-000005', 'INDIVIDUAL',
    'Ivan', 'Petrov',
    '56789012345678', TO_DATE('1985-05-20', 'YYYY-MM-DD'), 'Moskva, Rossiya', 'M',
    '+79161234567', 'ivan.petrov@mail.ru',
    'Rossiya, Moskva, Tverskaya 10', 'Toshkent sh., Shayxontohur t.',
    'N', 'RUS', '00191', '1001',
    'HIGH', 'N',
    'ACTIVE', 'supervisor1', SYSTIMESTAMP,
    'operator1', SYSTIMESTAMP
);


-- ==========================================================================
-- 2. YuSh (CORPORATE) mijozlar
-- ==========================================================================

-- 2.1 YuSh — ACTIVE, MChJ
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    org_name, org_full_name, org_form, oked,
    reg_number, reg_date, reg_authority,
    director_name, director_position, accountant_name, director_pinfl,
    inn,
    phone, email,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    other_bank_name, other_bank_mfo, other_bank_account,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260501-000006', 'CORPORATE',
    'Fido Soft MChJ', 'Fido Soft Mas''uliyati Cheklangan Jamiyat', 'MChJ', '62010',
    '789456', TO_DATE('2020-03-10', 'YYYY-MM-DD'), 'Toshkent shahri Adliya boshqarmasi',
    'Karimov Alisher Nabijonovich', 'Direktor', 'Rahimova Gulnora Shavkatovna', '67890123456789',
    '123456789',
    '+998712345678', 'info@fidosoft.uz',
    'Toshkent sh., Amir Temur ko''chasi 100', 'Toshkent sh., Amir Temur ko''chasi 100',
    'Y', 'UZB', '00191', '2001',
    'LOW', 'N',
    'NBU', '00014', '20208000900100001010',
    'ACTIVE', 'supervisor1', SYSTIMESTAMP,
    'operator1', SYSTIMESTAMP
);

-- 2.2 YuSh — PENDING, AJ
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    org_name, org_full_name, org_form, oked,
    reg_number, reg_date, reg_authority,
    director_name, director_position, accountant_name, director_pinfl,
    inn,
    phone,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    status,
    created_by, created_at
) VALUES (
    'CIF-20260520-000007', 'CORPORATE',
    'O''zbekiston Temir Yo''llari AJ', 'O''zbekiston Temir Yo''llari Aksiyadorlik Jamiyati', 'AJ', '49100',
    '112233', TO_DATE('1994-11-01', 'YYYY-MM-DD'), 'O''zbekiston Respublikasi Vazirlar Mahkamasi',
    'Xodjayev Sardor Tulqinovich', 'Bosh direktor', 'Mirzayeva Dilfuza Anvarovna', '78901234567890',
    '987654321',
    '+998712001234',
    'Toshkent sh., Turob Tula ko''chasi 7', 'Toshkent sh., Turob Tula ko''chasi 7',
    'Y', 'UZB', '00191', '3001',
    'LOW', 'N',
    'PENDING',
    'operator2', SYSTIMESTAMP
);

-- 2.3 YuSh — ACTIVE, YaTT
INSERT INTO core_cif_customers (
    cif_number, customer_type,
    org_name, org_full_name, org_form, oked,
    reg_number, reg_date, reg_authority,
    director_name, director_position, accountant_name, director_pinfl,
    inn,
    phone,
    legal_address, actual_address,
    resident_flag, country_code, branch_code, sector_code,
    risk_category, is_pep,
    status, approved_by, approved_at,
    created_by, created_at
) VALUES (
    'CIF-20260515-000008', 'CORPORATE',
    'Abdullayev S. YaTT', 'Abdullayev Sardor Yakka Tartibdagi Tadbirkor', 'YaTT', '47110',
    '556677', TO_DATE('2022-06-15', 'YYYY-MM-DD'), 'Toshkent sh. Soliq inspeksiyasi',
    'Abdullayev Sardor Kamoliddinovich', 'Yakka tartibdagi tadbirkor', 'Abdullayev Sardor Kamoliddinovich', '89012345678901',
    '111222333',
    '+998901234500',
    'Toshkent sh., Beruniy ko''chasi 44', 'Toshkent sh., Beruniy ko''chasi 44',
    'Y', 'UZB', '00191', '4001',
    'LOW', 'N',
    'ACTIVE', 'supervisor1', SYSTIMESTAMP,
    'operator1', SYSTIMESTAMP
);


-- ==========================================================================
-- 3. Hujjatlar (core_cif_documents)
--    S-3: INSERT ustun ro'yxati bilan
--    S-4: TO_DATE format mask bilan
-- ==========================================================================

-- Dilmurod Qayyumov uchun passport
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, expiry_date, is_primary, created_by
) VALUES (
    1, 'ID_CARD', 'AA', '1234567',
    'Chilonzor IIB', TO_DATE('2020-01-15', 'YYYY-MM-DD'),
    TO_DATE('2030-01-15', 'YYYY-MM-DD'), 'Y', 'operator1'
);

-- Aziza Karimova uchun passport
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, expiry_date, is_primary, created_by
) VALUES (
    2, 'PASSPORT', 'AB', '7654321',
    'Yunusobod IIB', TO_DATE('2019-05-20', 'YYYY-MM-DD'),
    TO_DATE('2029-05-20', 'YYYY-MM-DD'), 'Y', 'operator2'
);

-- Jasur Toshmatov uchun passport (PENDING)
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, expiry_date, is_primary, created_by
) VALUES (
    3, 'ID_CARD', 'AC', '1122334',
    'Samarqand IIB', TO_DATE('2021-08-10', 'YYYY-MM-DD'),
    TO_DATE('2031-08-10', 'YYYY-MM-DD'), 'Y', 'operator1'
);

-- Ivan Petrov uchun xorijiy passport
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, expiry_date, is_primary, created_by
) VALUES (
    5, 'FOREIGN_PASSPORT', '', '750123456',
    'FMS Rossiya', TO_DATE('2023-02-14', 'YYYY-MM-DD'),
    TO_DATE('2033-02-14', 'YYYY-MM-DD'), 'Y', 'operator1'
);

-- Fido Soft MChJ uchun guvohnoma
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, is_primary, created_by
) VALUES (
    6, 'CERTIFICATE', '', '789456',
    'Toshkent shahri Adliya boshqarmasi', TO_DATE('2020-03-10', 'YYYY-MM-DD'),
    'Y', 'operator1'
);

-- Fido Soft MChJ uchun litsenziya
INSERT INTO core_cif_documents (
    customer_id, doc_type, doc_series, doc_number,
    issued_by, issued_date, expiry_date, is_primary, created_by
) VALUES (
    6, 'LICENSE', '', 'LIC-2020-001',
    'Aloqa vazirligi', TO_DATE('2020-06-01', 'YYYY-MM-DD'),
    TO_DATE('2025-06-01', 'YYYY-MM-DD'), 'N', 'operator1'
);


-- ==========================================================================
-- 4. Kontaktlar (core_cif_contacts)
-- ==========================================================================

-- Dilmurod — asosiy telefon
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    1, 'PHONE', '+998901234567', 'Y', 'Asosiy mobil telefon'
);

-- Dilmurod — email
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    1, 'EMAIL', 'dilmurod@fido.uz', 'Y', 'Ish email'
);

-- Dilmurod — telegram
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    1, 'TELEGRAM', '@dilmurod_q', 'N', 'Telegram'
);

-- Aziza — telefon
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    2, 'PHONE', '+998931112233', 'Y', 'Asosiy telefon'
);

-- Fido Soft — ish telefon
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    6, 'PHONE', '+998712345678', 'Y', 'Ofis telefoni'
);

-- Fido Soft — faks
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    6, 'FAX', '+998712345679', 'N', 'Ofis faks'
);

-- Fido Soft — email
INSERT INTO core_cif_contacts (
    customer_id, contact_type, contact_value, is_primary, description
) VALUES (
    6, 'EMAIL', 'info@fidosoft.uz', 'Y', 'Rasmiy email'
);

COMMIT;

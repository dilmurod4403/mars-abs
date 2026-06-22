-- ============================================================================
-- MARS ABS - core_cif moduli
-- 03_cif_sequences.sql - Sequencelar
-- Sana: 2026-05-26
-- ============================================================================

-- CIF raqam generatsiya uchun
-- Format: CIF-YYYYMMDD-NNNNNN (masalan: CIF-20260526-000001)
CREATE SEQUENCE core_cif_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

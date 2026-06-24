-- gvenzl init (sqlplus / as sysdba, CDB-root) -> XEPDB1.BANKUSER. Manual load: no-op (USER<>SYS).
BEGIN
  IF USER = 'SYS' THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = XEPDB1';
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = BANKUSER';
  END IF;
END;
/
-- ============================================================================
-- MARS ABS (mars-abs) — REAL build, F0
-- 02_acc_util.sql — Hisob raqami + Mod-11 kontrol kalit (SIRIUS «Счета» §2.2)
--
-- Hisob raqami (20 xona): CMMSS(5) + VVV(3) + K(1) + XXXXXXXX(8) + NNN(3)
--   CMMSS  — balans hisobi (core_ref_coa, СПР 19)
--   VVV    — valyuta kodi (core_ref_currency, СПР 17; so'm = 000)
--   K      — kontrol kalit (Mod-11, ASCII qo'shni-raqam)
--   XXXXXXXX — mijoz kodi (НИББД, 8 xona)
--   NNN    — balans hisobi bo'yicha tartib raqami (001..999)
--
-- Kalit kombinatsiyasi (27 xona): NKO_kodi(8) + CMMSS(5) + VVV(3) + mijoz(8) + NNN(3)
-- ============================================================================

CREATE OR REPLACE PACKAGE core_acc_util AS
    -- Bankning НИББД'dagi kodi (konfiguratsiya; real qiymat o'rnatilsin)
    c_nko_code CONSTANT VARCHAR2(8) := '04654791';

    -- Mod-11 kontrol kalit: i_combo (raqamlar satri) ustidan
    FUNCTION Calc_Control_Key(i_combo IN VARCHAR2) RETURN VARCHAR2;

    -- 20 xonali hisob raqami yig'ish
    FUNCTION Generate_Account_Number(
        i_balance   IN VARCHAR2,   -- CMMSS (5)
        i_currency  IN VARCHAR2,   -- VVV (3)
        i_client    IN VARCHAR2,   -- mijoz kodi (8)
        i_seq       IN VARCHAR2    -- NNN (3)
    ) RETURN VARCHAR2;

    -- 20 xonali hisob raqamini tekshirish (uzunlik + kontrol kalit)
    FUNCTION Is_Valid_Account_Number(i_acc IN VARCHAR2) RETURN BOOLEAN;
END core_acc_util;
/

CREATE OR REPLACE PACKAGE BODY core_acc_util AS

    -- Mod-11: S = Σ ASCII(c_i)*ASCII(c_i+1) + ASCII(c_oxirgi)*9 ; X = MOD(S,11);
    -- X=0 -> 9 ; X=1 -> 0 ; aks holda |11-X|
    FUNCTION Calc_Control_Key(i_combo IN VARCHAR2) RETURN VARCHAR2 IS
        v_len   PLS_INTEGER;
        v_s     NUMBER := 0;
        v_x     PLS_INTEGER;
    BEGIN
        IF i_combo IS NULL THEN
            RETURN '0';
        END IF;
        v_len := LENGTH(i_combo);
        FOR i IN 1 .. v_len - 1 LOOP
            v_s := v_s + ASCII(SUBSTR(i_combo, i, 1)) * ASCII(SUBSTR(i_combo, i + 1, 1));
        END LOOP;
        v_s := v_s + ASCII(SUBSTR(i_combo, v_len, 1)) * 9;
        v_x := MOD(v_s, 11);
        IF v_x = 0 THEN
            v_x := 9;
        ELSIF v_x = 1 THEN
            v_x := 0;
        ELSE
            v_x := ABS(11 - v_x);
        END IF;
        RETURN TO_CHAR(v_x);
    END Calc_Control_Key;

    FUNCTION Generate_Account_Number(
        i_balance   IN VARCHAR2,
        i_currency  IN VARCHAR2,
        i_client    IN VARCHAR2,
        i_seq       IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_combo VARCHAR2(27);
        v_key   VARCHAR2(1);
    BEGIN
        v_combo := c_nko_code || i_balance || i_currency || i_client || i_seq;  -- 8+5+3+8+3
        v_key   := Calc_Control_Key(v_combo);
        RETURN i_balance || i_currency || v_key || i_client || i_seq;            -- 5+3+1+8+3 = 20
    END Generate_Account_Number;

    FUNCTION Is_Valid_Account_Number(i_acc IN VARCHAR2) RETURN BOOLEAN IS
        v_balance   VARCHAR2(5);
        v_currency  VARCHAR2(3);
        v_key       VARCHAR2(1);
        v_client    VARCHAR2(8);
        v_seq       VARCHAR2(3);
    BEGIN
        IF i_acc IS NULL OR LENGTH(i_acc) != 20 OR NOT REGEXP_LIKE(i_acc, '^\d{20}$') THEN
            RETURN FALSE;
        END IF;
        v_balance  := SUBSTR(i_acc, 1, 5);
        v_currency := SUBSTR(i_acc, 6, 3);
        v_key      := SUBSTR(i_acc, 9, 1);
        v_client   := SUBSTR(i_acc, 10, 8);
        v_seq      := SUBSTR(i_acc, 18, 3);
        RETURN v_key = Calc_Control_Key(c_nko_code || v_balance || v_currency || v_client || v_seq);
    END Is_Valid_Account_Number;

END core_acc_util;
/
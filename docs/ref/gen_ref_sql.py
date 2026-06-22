#!/usr/bin/env python3
# MARS ABS (mars-abs) — F0 reference layer generator
# spr-*.xlsx (SIRIUS spravochniklar) -> core_ref_* DDL + seed SQL
# spr-12 (.xls binar) — xlrd orqali o'qiladi (pip install --user xlrd kerak).
import zipfile, re, os
from datetime import date, timedelta
from xml.etree import ElementTree as ET

REF = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(REF, "generated")
os.makedirs(OUT, exist_ok=True)
EPOCH = date(1899, 12, 30)

def strip(t): return t.split('}')[-1]
def colnum(ref):
    m = re.match(r'([A-Z]+)', ref or 'A'); n = 0
    for ch in m.group(1): n = n * 26 + (ord(ch) - 64)
    return n - 1

def parse(path):
    z = zipfile.ZipFile(path); shared = []
    if 'xl/sharedStrings.xml' in z.namelist():
        for si in ET.fromstring(z.read('xl/sharedStrings.xml')):
            shared.append(''.join(t.text or '' for t in si.iter() if strip(t.tag) == 't'))
    sh = sorted(n for n in z.namelist() if re.match(r'xl/worksheets/sheet\d+\.xml', n))[0]
    rows = []
    for row in ET.fromstring(z.read(sh)).iter():
        if strip(row.tag) != 'row': continue
        cells = {}; mx = 0
        for cc in row:
            if strip(cc.tag) != 'c': continue
            t = cc.get('t', ''); ci = colnum(cc.get('r', 'A')); v = ''
            vt = cc.find('{*}v'); ist = cc.find('{*}is')
            if t == 's' and vt is not None and vt.text is not None: v = shared[int(vt.text)]
            elif t == 'inlineStr' and ist is not None: v = ''.join(x.text or '' for x in ist.iter() if strip(x.tag) == 't')
            elif vt is not None: v = vt.text or ''
            cells[ci] = v.strip(); mx = max(mx, ci)
        rows.append([cells.get(i, '') for i in range(mx + 1)])
    return [r for r in rows if any(r)]

def parse_xls(path):
    # Eski .xls (BIFF) — xlrd 2.x orqali (pip install xlrd)
    import xlrd
    wb = xlrd.open_workbook(path); ws = wb.sheet_by_index(0); rows = []
    for r in range(ws.nrows):
        out = []
        for c in range(ws.ncols):
            v = ws.cell_value(r, c)
            if isinstance(v, float):
                out.append(str(int(v)) if v == int(v) else str(v))
            else:
                out.append(str(v).strip())
        if any(out):
            rows.append(out)
    return rows

def hmap(rows):
    for i, r in enumerate(rows):
        up = [c.upper() for c in r]
        if 'CODE' in up and 'NAME' in up:
            return {name: idx for idx, name in enumerate(up) if name}, i
    raise RuntimeError("header topilmadi")

def q(v):
    if v is None or v == '': return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

def qd(v):
    if not v: return "NULL"
    try:
        d = EPOCH + timedelta(days=int(float(v)))
        return "TO_DATE('%s','YYYY-MM-DD')" % d.isoformat()
    except Exception:
        return "NULL"

def emit(table, ddl, rows, cols, hdr, valfns, fout):
    fout.write("-- ============================================================\n")
    fout.write("-- %s\n-- ============================================================\n" % table)
    fout.write("BEGIN EXECUTE IMMEDIATE 'DROP TABLE %s CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;\n/\n" % table)
    fout.write(ddl.strip() + "\n\n")
    n = 0
    for r in rows:
        def g(col):
            i = hdr.get(col)
            return r[i] if (i is not None and i < len(r)) else ''
        vals = [fn(g) for fn in valfns]
        fout.write("INSERT INTO %s (%s) VALUES (%s);\n" % (table, ", ".join(cols), ", ".join(vals)))
        n += 1
    fout.write("COMMIT;\n\n")
    return n

def main():
    out = os.path.join(OUT, "00_ref_spravochniklar.sql")
    counts = {}
    with open(out, "w") as f:
        f.write("-- MARS ABS (mars-abs) — F0 reference qatlami (SIRIUS spravochniklar)\n")
        f.write("-- Generator: docs/ref/gen_ref_sql.py — qayta yaratish uchun ishga tushiring.\n")
        f.write("-- Manba: docs/ref/spr-17/19/21/52.xlsx + spr-12.xls (xlrd).\n\n")

        # --- spr-17 currency ---
        rows = parse(os.path.join(REF, "spr-17.xlsx")); hdr, hi = hmap(rows); data = rows[hi+1:]
        ddl = """CREATE TABLE core_ref_currency (
    code        VARCHAR2(3)  NOT NULL,
    char_code   VARCHAR2(10),  -- ba'zi qiymatlarda Kirill belgi bor (bayt > belgi)
    name        VARCHAR2(300),
    scale       NUMBER(2),
    scale_name  VARCHAR2(50),
    is_hard     CHAR(1),
    allow_flag  CHAR(1),
    condition   CHAR(1),
    CONSTRAINT core_ref_currency_pk PRIMARY KEY (code)
);"""
        counts['currency'] = emit("core_ref_currency", ddl, data,
            ["code","char_code","name","scale","scale_name","is_hard","allow_flag","condition"], hdr,
            [lambda g: q(g('CODE')), lambda g: q(g('CHAR_CODE')), lambda g: q(g('NAME')),
             lambda g: (g('SCALE') or 'NULL') if re.match(r'^\d+$', g('SCALE') or '') else 'NULL',
             lambda g: q(g('SCALE_NAME')), lambda g: q(g('HARD')), lambda g: q(g('ALLOW')), lambda g: q(g('CONDITION'))], f)

        # --- spr-21 client type ---
        rows = parse(os.path.join(REF, "spr-21.xlsx")); hdr, hi = hmap(rows); data = rows[hi+1:]
        ddl = """CREATE TABLE core_ref_client_type (
    code        VARCHAR2(2)  NOT NULL,
    code_char   VARCHAR2(10),
    name        VARCHAR2(300),
    condition   CHAR(1),
    CONSTRAINT core_ref_client_type_pk PRIMARY KEY (code)
);"""
        counts['client_type'] = emit("core_ref_client_type", ddl, data,
            ["code","code_char","name","condition"], hdr,
            [lambda g: q(g('CODE') or '00'), lambda g: q(g('CODE_CHAR')), lambda g: q(g('NAME')), lambda g: q(g('CONDITION'))], f)

        # --- spr-52 region/district ---
        rows = parse(os.path.join(REF, "spr-52.xlsx")); hdr, hi = hmap(rows); data = rows[hi+1:]
        ddl = """CREATE TABLE core_ref_region (
    region_code VARCHAR2(3)  NOT NULL,
    code        VARCHAR2(3)  NOT NULL,
    name        VARCHAR2(300),
    condition   CHAR(1),
    CONSTRAINT core_ref_region_pk PRIMARY KEY (region_code, code)
);"""
        counts['region'] = emit("core_ref_region", ddl, data,
            ["region_code","code","name","condition"], hdr,
            [lambda g: q(g('REGION_CODE')), lambda g: q(g('CODE')), lambda g: q(g('NAME')), lambda g: q(g('CONDITION'))], f)

        # --- spr-19 COA (План счетов) ---
        rows = parse(os.path.join(REF, "spr-19.xlsx")); hdr, hi = hmap(rows); data = rows[hi+1:]
        ddl = """CREATE TABLE core_ref_coa (
    code          VARCHAR2(5)  NOT NULL,
    name          VARCHAR2(400),
    section_code  VARCHAR2(5),
    type_acc_code VARCHAR2(2),
    reverse_code  VARCHAR2(5),
    client_code   VARCHAR2(2),
    gr_risk_code  VARCHAR2(5),
    sign_nibbd    VARCHAR2(1),
    condition     CHAR(1),
    date_activ    DATE,
    date_deact    DATE,
    CONSTRAINT core_ref_coa_pk PRIMARY KEY (code)
);"""
        # COA: dublikat code bo'lsa (kategoriya sarlavhalar) — birinchisi
        seen = set(); coa = []
        for r in data:
            i = hdr.get('CODE'); cd = r[i] if i is not None and i < len(r) else ''
            if cd and cd not in seen and re.match(r'^\d{4,5}$', cd):
                seen.add(cd); coa.append(r)
        counts['coa'] = emit("core_ref_coa", ddl, coa,
            ["code","name","section_code","type_acc_code","reverse_code","client_code","gr_risk_code","sign_nibbd","condition","date_activ","date_deact"], hdr,
            [lambda g: q(g('CODE')), lambda g: q(g('NAME')), lambda g: q(g('SECTION_CODE')), lambda g: q(g('TYPE_ACC_CODE')),
             lambda g: q(g('REVERSE_CODE')), lambda g: q(g('CLIENT_CODE')), lambda g: q(g('GR_RISK_CODE')), lambda g: q(g('SIGN_NIBBD')),
             lambda g: q(g('CONDITION')), lambda g: qd(g('DATE_ACTIV')), lambda g: qd(g('DATE_DEACT'))], f)

        # --- spr-12 branch / MFO (.xls, xlrd) ---
        try:
            rows = parse_xls(os.path.join(REF, "spr-12.xls")); hdr, hi = hmap(rows); data = rows[hi+1:]
            ddl = """CREATE TABLE core_ref_branch (
    code            VARCHAR2(5)  NOT NULL,
    name            VARCHAR2(500),
    adress          VARCHAR2(500),
    bank_type_code  VARCHAR2(3),
    region_code     VARCHAR2(3),
    district_code   VARCHAR2(4),
    header_code     VARCHAR2(5),
    status_code     VARCHAR2(2),
    account_type    VARCHAR2(3),
    active          VARCHAR2(1),
    condition       CHAR(1),
    CONSTRAINT core_ref_branch_pk PRIMARY KEY (code)
);"""
            seen = set(); br = []
            for r in data:
                i = hdr.get('CODE'); cd = r[i] if (i is not None and i < len(r)) else ''
                if cd and cd not in seen:
                    seen.add(cd); br.append(r)
            counts['branch'] = emit("core_ref_branch", ddl, br,
                ["code","name","adress","bank_type_code","region_code","district_code","header_code","status_code","account_type","active","condition"], hdr,
                [lambda g: q(g('CODE')), lambda g: q(g('NAME')), lambda g: q(g('ADRESS')), lambda g: q(g('BANK_TYPE_CODE')),
                 lambda g: q(g('REGION_CODE')), lambda g: q(g('DISTRICT_CODE')), lambda g: q(g('HEADER_CODE')), lambda g: q(g('STATUS_CODE')),
                 lambda g: q(g('ACCOUNT_TYPE')), lambda g: q(g('ACTIVE')), lambda g: q(g('CONDITION'))], f)
        except Exception as e:
            print("spr-12 (branch) o'tkazib yuborildi:", e)

    print("Generated:", out)
    for k, v in counts.items(): print(f"  core_ref_{k}: {v} qator")

main()

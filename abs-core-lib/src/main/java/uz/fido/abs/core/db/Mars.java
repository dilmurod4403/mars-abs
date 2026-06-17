package uz.fido.abs.core.db;

import java.sql.*;
import java.util.*;

/**
 * ABS Core — Oracle procedure/funksiya chaqirish yordamchisi.
 *
 * Ishlatish (Procedure):
 *   Map<String,Object> result = Mars.procedure("core_cif_service.Create_Customer")
 *       .in("customer_type", "INDIVIDUAL")
 *       .in("first_name", "Alisher")
 *       .in("phone", "+998901234567")
 *       .outNumber("code")
 *       .outString("message")
 *       .execute();
 *   int code = ((Number) result.get("code")).intValue();
 *
 * Ishlatish (Function):
 *   Object result = Mars.function("core_cif_util.Generate_Cif_Number")
 *       .in("customer_type", "INDIVIDUAL")
 *       .returnType(Types.VARCHAR)
 *       .execute();
 */
public class Mars {

    private final String programName;
    private final boolean isFunction;
    private final List<Param> params = new ArrayList<>();
    private int returnType = Types.VARCHAR; // for functions

    // RECORD type support
    private String recordVarName;     // e.g. "v_rec"
    private String recordTypeName;    // e.g. "core_cif_types.t_customer_rec"
    private final List<RecordField> recordFields = new ArrayList<>();
    private final List<RecordOut> recordOuts = new ArrayList<>();

    private Mars(String programName, boolean isFunction) {
        this.programName = programName;
        this.isFunction = isFunction;
    }

    public static Mars procedure(String name) {
        return new Mars(name, false);
    }

    public static Mars function(String name) {
        return new Mars(name, true);
    }

    /**
     * Declare a RECORD variable for procedures that take PL/SQL RECORD type params.
     *
     * Usage:
     *   Mars.procedure("core_cif_service.Create_Customer")
     *       .record("v_rec", "core_cif_types.t_customer_rec")
     *       .field("customer_type", "INDIVIDUAL")
     *       .field("first_name", "Alisher")
     *       .field("phone", "+998901234567")
     *       .fieldDate("birth_date", "2000-01-15", "YYYY-MM-DD")
     *       .outField("customer_id", Types.NUMERIC)
     *       .outField("cif_number", Types.VARCHAR)
     *       .outNumber("code")
     *       .outString("message")
     *       .outString("ora_message")
     *       .execute();
     */
    public Mars record(String varName, String typeName) {
        this.recordVarName = varName;
        this.recordTypeName = typeName;
        return this;
    }

    /** Set a RECORD field (String value) */
    public Mars field(String fieldName, String value) {
        recordFields.add(new RecordField(fieldName, value, Types.VARCHAR, null));
        return this;
    }

    /** Set a RECORD field (Long value) */
    public Mars field(String fieldName, long value) {
        recordFields.add(new RecordField(fieldName, value, Types.NUMERIC, null));
        return this;
    }

    /** Set a RECORD field with TO_DATE conversion */
    public Mars fieldDate(String fieldName, String dateStr, String format) {
        recordFields.add(new RecordField(fieldName, dateStr, Types.VARCHAR, format));
        return this;
    }

    /** Read a RECORD field as OUT after procedure execution */
    public Mars outField(String fieldName, int sqlType) {
        recordOuts.add(new RecordOut(fieldName, sqlType));
        return this;
    }

    /** Add IN parameter (String) */
    public Mars in(String name, String value) {
        params.add(new Param(name, value, Types.VARCHAR, ParamDir.IN));
        return this;
    }

    /** Add IN parameter (Long/Number) */
    public Mars in(String name, long value) {
        params.add(new Param(name, value, Types.NUMERIC, ParamDir.IN));
        return this;
    }

    /** Add IN parameter (Object, auto-detect type) */
    public Mars in(String name, Object value, int sqlType) {
        params.add(new Param(name, value, sqlType, ParamDir.IN));
        return this;
    }

    /** Add OUT parameter (NUMBER) */
    public Mars outNumber(String name) {
        params.add(new Param(name, null, Types.NUMERIC, ParamDir.OUT));
        return this;
    }

    /** Add OUT parameter (VARCHAR) */
    public Mars outString(String name) {
        params.add(new Param(name, null, Types.VARCHAR, ParamDir.OUT));
        return this;
    }

    /** Add OUT parameter with specific SQL type */
    public Mars out(String name, int sqlType) {
        params.add(new Param(name, null, sqlType, ParamDir.OUT));
        return this;
    }

    /** Set return type for functions */
    public Mars returnType(int sqlType) {
        this.returnType = sqlType;
        return this;
    }

    /**
     * Execute the procedure/function.
     * Uses auto-obtained connection from AbsDb.
     * Returns Map of OUT parameter values (keyed by param name).
     * For functions, result is under key "return".
     * For record-based calls, includes both record OUT fields and simple OUT params.
     */
    public Map<String, Object> execute() throws SQLException {
        try (Connection conn = AbsDb.getConnection()) {
            return execute(conn);
        }
    }

    /**
     * Execute with provided connection (does NOT close it).
     */
    public Map<String, Object> execute(Connection conn) throws SQLException {
        if (recordVarName != null) {
            return executeWithRecord(conn);
        }
        return executeSimple(conn);
    }

    // --- Simple execution (no RECORD) ---

    private Map<String, Object> executeSimple(Connection conn) throws SQLException {
        String plsql = buildSimplePlSql();

        try (CallableStatement cs = conn.prepareCall(plsql)) {
            int idx = 1;

            if (isFunction) {
                cs.registerOutParameter(idx, returnType);
                idx++;
            }

            Map<String, Integer> outIndices = new LinkedHashMap<>();
            for (Param p : params) {
                if (p.dir == ParamDir.IN) {
                    bindParam(cs, idx, p);
                } else {
                    cs.registerOutParameter(idx, p.sqlType);
                    outIndices.put(p.name, idx);
                }
                idx++;
            }

            cs.execute();

            Map<String, Object> result = new LinkedHashMap<>();
            if (isFunction) {
                result.put("return", cs.getObject(1));
            }
            for (Map.Entry<String, Integer> e : outIndices.entrySet()) {
                result.put(e.getKey(), cs.getObject(e.getValue()));
            }
            return result;
        }
    }

    // --- RECORD-based execution ---

    private Map<String, Object> executeWithRecord(Connection conn) throws SQLException {
        String plsql = buildRecordPlSql();

        try (CallableStatement cs = conn.prepareCall(plsql)) {
            int idx = 1;

            // 1) Bind RECORD field values (IN)
            for (RecordField rf : recordFields) {
                if (rf.value == null) {
                    cs.setNull(idx, rf.sqlType);
                } else if (rf.value instanceof String) {
                    cs.setString(idx, (String) rf.value);
                } else if (rf.value instanceof Long) {
                    cs.setLong(idx, (Long) rf.value);
                } else if (rf.value instanceof Integer) {
                    cs.setInt(idx, (Integer) rf.value);
                } else {
                    cs.setObject(idx, rf.value);
                }
                idx++;
            }

            // 2) Register RECORD OUT fields
            Map<String, Integer> recOutIndices = new LinkedHashMap<>();
            for (RecordOut ro : recordOuts) {
                cs.registerOutParameter(idx, ro.sqlType);
                recOutIndices.put(ro.fieldName, idx);
                idx++;
            }

            // 3) Register simple OUT params
            Map<String, Integer> outIndices = new LinkedHashMap<>();
            for (Param p : params) {
                if (p.dir == ParamDir.OUT) {
                    cs.registerOutParameter(idx, p.sqlType);
                    outIndices.put(p.name, idx);
                    idx++;
                }
            }

            cs.execute();

            // Collect results
            Map<String, Object> result = new LinkedHashMap<>();
            for (Map.Entry<String, Integer> e : recOutIndices.entrySet()) {
                result.put(e.getKey(), cs.getObject(e.getValue()));
            }
            for (Map.Entry<String, Integer> e : outIndices.entrySet()) {
                result.put(e.getKey(), cs.getObject(e.getValue()));
            }
            return result;
        }
    }

    private String buildSimplePlSql() {
        StringBuilder sb = new StringBuilder();
        sb.append("BEGIN ");

        if (isFunction) {
            sb.append("? := ");
        }

        sb.append(programName).append("(");

        List<String> placeholders = new ArrayList<>();
        for (int i = 0; i < params.size(); i++) {
            placeholders.add("?");
        }
        sb.append(String.join(", ", placeholders));
        sb.append("); END;");

        return sb.toString();
    }

    private String buildRecordPlSql() {
        StringBuilder sb = new StringBuilder();
        sb.append("DECLARE\n");
        sb.append("  ").append(recordVarName).append(" ").append(recordTypeName).append(";\n");

        // Declare local variables for simple OUT params
        for (Param p : params) {
            if (p.dir == ParamDir.OUT) {
                String sqlTypeName = sqlTypeToPl(p.sqlType);
                sb.append("  v_").append(p.name).append(" ").append(sqlTypeName).append(";\n");
            }
        }

        sb.append("BEGIN\n");

        // Assign RECORD fields from bind variables
        for (RecordField rf : recordFields) {
            if (rf.dateFormat != null) {
                sb.append("  ").append(recordVarName).append(".").append(rf.fieldName)
                  .append(" := TO_DATE(?, '").append(rf.dateFormat).append("');\n");
            } else {
                sb.append("  ").append(recordVarName).append(".").append(rf.fieldName)
                  .append(" := ?;\n");
            }
        }

        // Call the procedure: proc(v_rec, v_code, v_message, v_ora_message)
        sb.append("  ").append(programName).append("(").append(recordVarName);
        for (Param p : params) {
            if (p.dir == ParamDir.OUT) {
                sb.append(", v_").append(p.name);
            }
        }
        sb.append(");\n");

        // Assign RECORD OUT fields to bind variables
        for (RecordOut ro : recordOuts) {
            sb.append("  ? := ").append(recordVarName).append(".").append(ro.fieldName).append(";\n");
        }

        // Assign simple OUT variables to bind variables
        for (Param p : params) {
            if (p.dir == ParamDir.OUT) {
                sb.append("  ? := v_").append(p.name).append(";\n");
            }
        }

        sb.append("END;");
        return sb.toString();
    }

    private void bindParam(CallableStatement cs, int idx, Param p) throws SQLException {
        if (p.value == null) {
            cs.setNull(idx, p.sqlType);
        } else if (p.value instanceof String) {
            cs.setString(idx, (String) p.value);
        } else if (p.value instanceof Number) {
            if (p.value instanceof Long) cs.setLong(idx, (Long) p.value);
            else if (p.value instanceof Integer) cs.setInt(idx, (Integer) p.value);
            else cs.setObject(idx, p.value);
        } else {
            cs.setObject(idx, p.value);
        }
    }

    private String sqlTypeToPl(int sqlType) {
        switch (sqlType) {
            case Types.NUMERIC: case Types.INTEGER: case Types.BIGINT: return "NUMBER";
            case Types.VARCHAR: case Types.CHAR: return "VARCHAR2(4000)";
            case Types.DATE: case Types.TIMESTAMP: return "DATE";
            default: return "VARCHAR2(4000)";
        }
    }

    // --- Inner classes ---

    private enum ParamDir { IN, OUT }

    private static class Param {
        final String name;
        final Object value;
        final int sqlType;
        final ParamDir dir;

        Param(String name, Object value, int sqlType, ParamDir dir) {
            this.name = name;
            this.value = value;
            this.sqlType = sqlType;
            this.dir = dir;
        }
    }

    private static class RecordField {
        final String fieldName;
        final Object value;
        final int sqlType;
        final String dateFormat; // null if not a date

        RecordField(String fieldName, Object value, int sqlType, String dateFormat) {
            this.fieldName = fieldName;
            this.value = value;
            this.sqlType = sqlType;
            this.dateFormat = dateFormat;
        }
    }

    private static class RecordOut {
        final String fieldName;
        final int sqlType;

        RecordOut(String fieldName, int sqlType) {
            this.fieldName = fieldName;
            this.sqlType = sqlType;
        }
    }
}

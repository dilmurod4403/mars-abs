package uz.fido.abs.core.tag;

import uz.fido.abs.core.db.AbsDb;
import uz.fido.abs.core.model.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.*;
import javax.servlet.jsp.tagext.*;
import java.sql.*;
import java.util.*;

public class DataTag extends BodyTagSupport {

    private String var;          // Variable name to store GridModel
    private String view;         // Oracle view/table name
    private String orderBy;      // ORDER BY clause (default: null)
    private int pageSize = 20;   // Rows per page
    private String columns;      // Optional: specific columns (default: *)

    // Child FilterTags register themselves here
    private List<FilterDef> filterDefs = new ArrayList<>();

    // Setters for tag attributes
    public void setVar(String var) { this.var = var; }
    public void setView(String view) { this.view = view; }
    public void setOrderBy(String orderBy) { this.orderBy = orderBy; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }
    public void setColumns(String columns) { this.columns = columns; }

    /** Called by child FilterTag to register a filter */
    public void addFilter(FilterDef fd) { filterDefs.add(fd); }

    @Override
    public int doStartTag() throws JspException {
        filterDefs = new ArrayList<>(); // Reset for each invocation
        return EVAL_BODY_BUFFERED; // Need to evaluate body to collect FilterTags
    }

    @Override
    public int doAfterBody() throws JspException {
        return SKIP_BODY; // Body evaluated once (just to register filters)
    }

    @Override
    public int doEndTag() throws JspException {
        HttpServletRequest request = (HttpServletRequest) pageContext.getRequest();
        GridModel model = new GridModel();
        model.setView(view);
        model.setPageSize(pageSize);
        model.setOrderBy(orderBy);

        // Determine current page URL for pagination
        String requestUri = request.getRequestURI();
        model.setBaseUrl(requestUri);

        // Read page param
        String pageStr = request.getParameter("page");
        int currentPage = 1;
        if (pageStr != null) {
            try { currentPage = Integer.parseInt(pageStr); } catch (NumberFormatException e) {}
        }
        if (currentPage < 1) currentPage = 1;
        model.setPage(currentPage);

        // Read filter values from request params (f_{field})
        for (FilterDef fd : filterDefs) {
            String val = request.getParameter("f_" + fd.getField());
            if (val != null && !val.trim().isEmpty()) {
                fd.setValue(val.trim());
            }
            model.addFilter(fd);
        }

        // Build WHERE clause from active filters
        StringBuilder where = new StringBuilder();
        List<String> whereParams = new ArrayList<>();
        for (FilterDef fd : filterDefs) {
            if (fd.getValue() != null && !fd.getValue().isEmpty()) {
                if (where.length() > 0) where.append(" AND ");
                if ("select".equals(fd.getType())) {
                    where.append("UPPER(").append(fd.getField()).append(") = UPPER(?)");
                    whereParams.add(fd.getValue());
                } else {
                    // text search — use LIKE with UPPER for case-insensitive
                    where.append("UPPER(").append(fd.getField()).append(") LIKE UPPER(?)");
                    whereParams.add("%" + fd.getValue() + "%");
                }
            }
        }

        String selectCols = (columns != null && !columns.isEmpty()) ? columns : "*";
        String whereClause = where.length() > 0 ? " WHERE " + where : "";
        String orderClause = (orderBy != null && !orderBy.isEmpty()) ? " ORDER BY " + orderBy : "";

        // Execute queries
        Connection conn = null;
        try {
            conn = AbsDb.getConnection();

            // 1) Count total rows
            String countSql = "SELECT COUNT(*) FROM " + view + whereClause;
            try (PreparedStatement ps = conn.prepareStatement(countSql)) {
                for (int i = 0; i < whereParams.size(); i++) {
                    ps.setString(i + 1, whereParams.get(i));
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        model.setTotalRows(rs.getInt(1));
                    }
                }
            }

            model.calculatePages();

            // 2) Fetch current page rows
            int offset = (model.getPage() - 1) * pageSize;
            String dataSql = "SELECT " + selectCols + " FROM " + view
                + whereClause + orderClause
                + " OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

            try (PreparedStatement ps = conn.prepareStatement(dataSql)) {
                int idx = 1;
                for (String p : whereParams) {
                    ps.setString(idx++, p);
                }
                ps.setInt(idx++, offset);
                ps.setInt(idx++, pageSize);

                try (ResultSet rs = ps.executeQuery()) {
                    ResultSetMetaData md = rs.getMetaData();
                    int colCount = md.getColumnCount();

                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        for (int i = 1; i <= colCount; i++) {
                            String colName = md.getColumnName(i).toLowerCase();
                            int colType = md.getColumnType(i);
                            Object val;
                            // Convert Oracle TIMESTAMP types to java.util.Date for JSTL
                            if (colType == Types.TIMESTAMP || colType == Types.DATE
                                    || colType == -101 || colType == -102) {
                                Timestamp ts = rs.getTimestamp(i);
                                val = (ts != null) ? new java.util.Date(ts.getTime()) : null;
                            } else {
                                val = rs.getObject(i);
                            }
                            row.put(colName, val);
                        }
                        model.addRow(row);
                    }
                }
            }

        } catch (SQLException e) {
            throw new JspException("Grid data query error: " + e.getMessage(), e);
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }

        // Store model in page scope
        pageContext.setAttribute(var, model, PageContext.PAGE_SCOPE);

        return EVAL_PAGE;
    }

    @Override
    public void release() {
        super.release();
        var = null;
        view = null;
        orderBy = null;
        pageSize = 20;
        columns = null;
        filterDefs = new ArrayList<>();
    }
}

package uz.fido.abs.core.tag;

import uz.fido.abs.core.db.AbsDb;
import uz.fido.abs.core.model.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.*;
import javax.servlet.jsp.tagext.*;
import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Unified table tag — data fetching + HTML/JSON rendering.
 *
 * HTML mode (default):
 *   <t:table view="core_cif_customers_ui_v" orderBy="created_at DESC" pageSize="20" emptyText="...">
 *       <t:filter field="status" label="Holat" type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda"/>
 *       <t:col field="cif_number" title="CIF" link="detail.jsp?id={customer_id}"/>
 *       <t:col field="status" title="Holat" badge="ACTIVE:Faol:active,PENDING:Pending:pending"/>
 *   </t:table>
 *
 * JSON mode (for editable datagrids):
 *   <t:table view="..." mode="json" var="data" id="myGrid">
 *       <t:col field="name" title="Nomi" editable="true" editType="text"/>
 *       <t:col field="status" title="Holat" editable="true" editType="select" editOptions="ACTIVE:Faol,BLOCKED:Bloklangan"/>
 *   </t:table>
 *
 * Data-only mode (no t:col children, only var set):
 *   <t:table view="..." var="data" orderBy="..." pageSize="100">
 *       <t:filter ... />
 *   </t:table>
 *   Then use ${data.rows}, ${data.totalRows} manually.
 */
public class TableTag extends BodyTagSupport {

    // --- Data attributes ---
    private String var;
    private String view;
    private String orderBy;
    private int pageSize = 20;
    private String columns;  // SELECT columns (default: *)

    // --- Rendering attributes ---
    private String mode = "html";  // "html" or "json"
    private String emptyText = "Ma'lumot topilmadi";
    private String id;
    private String title;
    private boolean linkModal = false;   // link'lar modal oynada ochiladimi
    private String linkModalSize;        // modal o'lchami: sm/md/lg/xl
    private boolean selectable = false;  // qator tanlash (checkbox ustun + bulk toolbar)
    private boolean stickyHeader = true; // sticky thead (scroll'da tepada qotadi)
    private String saveUrl;              // inline tahrir / bulk amal saqlash POST manzili
    private String rowId;                // qator PK ustuni (bulk amal uchun id manbai)
    private String bulkStatus;           // bulk status o'zgartirish variantlari: "ACTIVE:Faollashtirish,BLOCKED:Bloklash"

    // Ruxsat etilgan sahifa o'lchamlari
    private static final int[] PAGE_SIZE_OPTIONS = { 20, 50, 100 };

    // --- Collected from child tags ---
    private List<FilterDef> filterDefs = new ArrayList<>();
    private List<ColumnDef> columnDefs = new ArrayList<>();

    // --- Field metadata (registered by t:field, used by t:col) ---
    private Map<String, String[]> fieldMetas = new LinkedHashMap<>();  // field -> [title, format]

    // --- Fetched data ---
    private GridModel model;

    // Setters
    public void setVar(String var) { this.var = var; }
    public void setView(String view) { this.view = view; }
    public void setOrderBy(String orderBy) { this.orderBy = orderBy; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }
    public void setColumns(String columns) { this.columns = columns; }
    public void setMode(String mode) { this.mode = mode; }
    public void setEmptyText(String emptyText) { this.emptyText = emptyText; }
    public void setId(String id) { this.id = id; }
    public void setTitle(String title) { this.title = title; }
    public void setLinkModal(boolean linkModal) { this.linkModal = linkModal; }
    public void setLinkModalSize(String linkModalSize) { this.linkModalSize = linkModalSize; }
    public void setSelectable(boolean selectable) { this.selectable = selectable; }
    public void setStickyHeader(boolean stickyHeader) { this.stickyHeader = stickyHeader; }
    public void setSaveUrl(String saveUrl) { this.saveUrl = saveUrl; }
    public void setRowId(String rowId) { this.rowId = rowId; }
    public void setBulkStatus(String bulkStatus) { this.bulkStatus = bulkStatus; }

    /** Called by child FilterTag */
    public void addFilter(FilterDef fd) { filterDefs.add(fd); }

    /** Called by child ColumnTag */
    public void addColumn(ColumnDef col) { columnDefs.add(col); }

    /** Called by child FieldTag — register field metadata */
    public void registerField(String field, String title, String format) {
        fieldMetas.put(field, new String[]{ title, format });
    }

    /** Get field title (used by ColumnTag to resolve defaults) */
    public String getFieldTitle(String field) {
        String[] meta = fieldMetas.get(field);
        return (meta != null && meta[0] != null) ? meta[0] : field;
    }

    /** Get field format (used by ColumnTag to resolve defaults) */
    public String getFieldFormat(String field) {
        String[] meta = fieldMetas.get(field);
        return (meta != null) ? meta[1] : null;
    }

    @Override
    public int doStartTag() throws JspException {
        filterDefs = new ArrayList<>();
        columnDefs = new ArrayList<>();
        fieldMetas = new LinkedHashMap<>();
        linkModal = false;
        linkModalSize = null;
        selectable = false;
        stickyHeader = true;
        saveUrl = null;
        rowId = null;
        bulkStatus = null;
        model = null;
        return EVAL_BODY_BUFFERED;
    }

    @Override
    public int doAfterBody() throws JspException {
        return SKIP_BODY;
    }

    @Override
    public int doEndTag() throws JspException {
        // 1) Fetch data
        fetchData();

        // 2) Store in var if requested
        if (var != null && !var.isEmpty()) {
            pageContext.setAttribute(var, model, PageContext.PAGE_SCOPE);
        }

        // 3) Render (only if columns defined)
        if (!columnDefs.isEmpty()) {
            try {
                if ("json".equals(mode)) {
                    renderJson();
                } else {
                    renderHtml();
                }
            } catch (IOException e) {
                throw new JspException("Table render error", e);
            }
        }

        return EVAL_PAGE;
    }

    // ================================================================
    //  DATA FETCHING
    // ================================================================

    private void fetchData() throws JspException {
        HttpServletRequest request = (HttpServletRequest) pageContext.getRequest();
        model = new GridModel();
        model.setView(view);
        model.setBaseUrl(request.getRequestURI());

        // --- Page size (param "ps") — faqat ruxsat etilgan qiymatlar ---
        int effectivePageSize = pageSize;
        String psStr = request.getParameter("ps");
        if (psStr != null) {
            try {
                int ps = Integer.parseInt(psStr.trim());
                for (int allowed : PAGE_SIZE_OPTIONS) {
                    if (ps == allowed) { effectivePageSize = ps; break; }
                }
            } catch (NumberFormatException e) {}
        }
        if (effectivePageSize < 1) effectivePageSize = 20;
        pageSize = effectivePageSize;
        model.setPageSize(effectivePageSize);

        // --- Sort (params "s" = column, "d" = direction) ---
        // SQL-injection himoyasi: "s" faqat ma'lum field nomlari bilan solishtiriladi.
        String sortCol = sanitizeSortColumn(request.getParameter("s"));
        String sortDir = "asc";
        String dParam = request.getParameter("d");
        if (dParam != null && dParam.trim().equalsIgnoreCase("desc")) {
            sortDir = "desc";
        }
        String effectiveOrderBy = orderBy;
        if (sortCol != null) {
            // Whitelisted ustun + qat'iy asc|desc — xavfsiz
            effectiveOrderBy = sortCol + " " + sortDir.toUpperCase();
            model.setSortCol(sortCol);
            model.setSortDir(sortDir);
        }
        model.setOrderBy(effectiveOrderBy);

        // Page
        String pageStr = request.getParameter("page");
        int currentPage = 1;
        if (pageStr != null) {
            try { currentPage = Integer.parseInt(pageStr); } catch (NumberFormatException e) {}
        }
        if (currentPage < 1) currentPage = 1;
        model.setPage(currentPage);

        // Read filter values from request
        for (FilterDef fd : filterDefs) {
            String val = request.getParameter("f_" + fd.getField());
            if (val != null && !val.trim().isEmpty()) {
                fd.setValue(val.trim());
            }
            model.addFilter(fd);
        }

        // Build WHERE
        StringBuilder where = new StringBuilder();
        List<String> whereParams = new ArrayList<>();
        for (FilterDef fd : filterDefs) {
            if (fd.getValue() != null && !fd.getValue().isEmpty()) {
                if (where.length() > 0) where.append(" AND ");
                if ("select".equals(fd.getType())) {
                    where.append("UPPER(").append(fd.getField()).append(") = UPPER(?)");
                    whereParams.add(fd.getValue());
                } else {
                    where.append("UPPER(").append(fd.getField()).append(") LIKE UPPER(?)");
                    whereParams.add("%" + fd.getValue() + "%");
                }
            }
        }

        String selectCols = (columns != null && !columns.isEmpty()) ? columns : "*";
        String whereClause = where.length() > 0 ? " WHERE " + where : "";
        String orderClause = (effectiveOrderBy != null && !effectiveOrderBy.isEmpty())
                ? " ORDER BY " + effectiveOrderBy : "";

        Connection conn = null;
        try {
            conn = AbsDb.getConnection();

            // COUNT
            String countSql = "SELECT COUNT(*) FROM " + view + whereClause;
            try (PreparedStatement ps = conn.prepareStatement(countSql)) {
                for (int i = 0; i < whereParams.size(); i++) {
                    ps.setString(i + 1, whereParams.get(i));
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) model.setTotalRows(rs.getInt(1));
                }
            }

            model.calculatePages();

            // DATA
            int offset = (model.getPage() - 1) * pageSize;
            String dataSql = "SELECT " + selectCols + " FROM " + view
                + whereClause + orderClause
                + " OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

            try (PreparedStatement ps = conn.prepareStatement(dataSql)) {
                int idx = 1;
                for (String p : whereParams) ps.setString(idx++, p);
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
            throw new JspException("Table data query error: " + e.getMessage(), e);
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }

    /**
     * SQL-injection himoyasi: foydalanuvchidan kelgan "s" param'ini
     * faqat ma'lum (whitelisted) ustun nomlari bilan solishtiradi.
     * Whitelist: t:col field'lari (sortable=false bo'lmaganlar) + t:field field'lari.
     * Ro'yxatda bo'lmasa null qaytaradi (saralash e'tiborsiz qoladi).
     */
    private String sanitizeSortColumn(String raw) {
        if (raw == null) return null;
        String candidate = raw.trim();
        if (candidate.isEmpty()) return null;

        // Ruxsat etilgan ustunlar to'plamini yig'ish
        Set<String> allowed = new LinkedHashSet<>();
        for (ColumnDef col : columnDefs) {
            if (col.getField() != null && col.isSortable()) {
                allowed.add(col.getField());
            }
        }
        // t:col bo'lmasa (data-only / json), t:field nomlariga tayanamiz
        if (columnDefs.isEmpty()) {
            allowed.addAll(fieldMetas.keySet());
        }

        // Aniq (case-insensitive) moslik — qo'shimcha belgilar (;, bo'sh joy) o'tmaydi
        for (String field : allowed) {
            if (field != null && field.equalsIgnoreCase(candidate)) {
                return field; // ro'yxatdagi kanonik nomni qaytaramiz
            }
        }
        return null;
    }

    /** Joriy ustun bo'yicha keyingi saralash yo'nalishi: yo'q→asc→desc→yo'q */
    private String nextSortDir(ColumnDef col) {
        String active = model.getSortCol();
        if (active == null || !active.equalsIgnoreCase(col.getField())) return "asc";
        return "desc".equalsIgnoreCase(model.getSortDir()) ? null : "desc";
    }

    // ================================================================
    //  HTML RENDERING
    // ================================================================

    private void renderHtml() throws IOException {
        JspWriter out = pageContext.getOut();
        String gridId = (id != null) ? id : "grid_" + System.identityHashCode(this);

        // Filter bar
        if (!model.getFilters().isEmpty()) {
            renderFilterBar(out);
        }

        // Grid root — JS hook'lari (zichlik, ustun ko'rsatish/yashirish,
        // eksport, qator tanlash) shu konteyner atributlariga tayanadi.
        out.write("<div class=\"grid-root\" data-grid=\"" + escHtml(gridId) + "\"");
        if (selectable) out.write(" data-selectable=\"true\"");
        if (saveUrl != null) out.write(" data-save-url=\"" + escHtml(saveUrl) + "\"");
        out.write(">\n");

        // Toolbar — chap: yozuv soni · o'ng: boshqaruv tugmalari
        renderToolbar(out, gridId);

        // Bulk toolbar (tanlangan qatorlar uchun) — boshida yashirin
        if (selectable) {
            out.write("<div class=\"bulk-toolbar\" data-bulk-toolbar hidden>\n");
            out.write("<span class=\"bulk-count\">Tanlangan: <strong data-bulk-count>0</strong></span>\n");
            out.write("<div class=\"bulk-actions\">\n");
            // Bulk status o'zgartirish (saveUrl + bulkStatus berilgan bo'lsa)
            if (saveUrl != null && bulkStatus != null) {
                out.write("<select class=\"form-control form-control-sm\" data-bulk-status-select>\n");
                out.write("<option value=\"\">Status o'zgartirish...</option>\n");
                for (String pair : bulkStatus.split(",")) {
                    String[] kv = pair.split(":", 2);
                    String val = kv[0].trim();
                    String label = (kv.length > 1) ? kv[1].trim() : val;
                    out.write("<option value=\"" + escHtml(val) + "\">" + escHtml(label) + "</option>\n");
                }
                out.write("</select>\n");
                out.write("<button type=\"button\" class=\"btn btn-sm btn-primary\" data-bulk-action=\"status\">Qo'llash</button>\n");
            }
            out.write("<button type=\"button\" class=\"btn btn-sm\" data-bulk-action=\"export-csv\">⬇ Eksport</button>\n");
            out.write("<button type=\"button\" class=\"btn btn-sm\" data-bulk-action=\"clear\">Bekor qilish</button>\n");
            out.write("</div>\n");
            out.write("</div>\n");
        }

        // Table
        String wrapClass = "table-wrapper" + (stickyHeader ? " grid-sticky" : "");
        out.write("<div class=\"" + wrapClass + "\">\n");
        out.write("<table id=\"" + escHtml(gridId) + "\">\n");

        // thead
        out.write("<thead><tr>\n");
        if (selectable) {
            out.write("<th class=\"col-select\"><input type=\"checkbox\" data-select-all aria-label=\"Hammasini tanlash\"></th>\n");
        }
        for (ColumnDef col : columnDefs) {
            renderHeaderCell(out, col);
        }
        out.write("</tr></thead>\n");

        // tbody
        int colCount = columnDefs.size() + (selectable ? 1 : 0);
        out.write("<tbody>\n");
        if (model.getRows().isEmpty()) {
            out.write("<tr><td colspan=\"" + colCount + "\" class=\"empty-state\">");
            out.write("<div class=\"message\">" + escHtml(emptyText) + "</div>");
            out.write("</td></tr>\n");
        } else {
            for (Map<String, Object> row : model.getRows()) {
                out.write("<tr>\n");
                if (selectable) {
                    String rid = (rowId != null && row.get(rowId) != null) ? String.valueOf(row.get(rowId)) : "";
                    out.write("<td class=\"col-select\"><input type=\"checkbox\" data-select-row data-id=\"" + escHtml(rid) + "\" aria-label=\"Qatorni tanlash\"></td>\n");
                }
                for (ColumnDef col : columnDefs) {
                    renderCell(out, col, row);
                }
                out.write("</tr>\n");
            }
        }
        out.write("</tbody>\n");

        // tfoot
        boolean hasFooter = columnDefs.stream().anyMatch(ColumnDef::isFooter);
        if (hasFooter && !model.getRows().isEmpty()) {
            renderFooter(out);
        }

        out.write("</table>\n</div>\n");

        // Pagination
        if (model.getTotalPages() > 1) {
            renderPagination(out);
        }

        out.write("</div>\n"); // .grid-root
    }

    /**
     * Boshqaruv paneli (toolbar):
     *  - chap: jami yozuv soni / sahifa
     *  - o'ng: zichlik, ustunlar, eksport, sahifa o'lchami
     */
    private void renderToolbar(JspWriter out, String gridId) throws IOException {
        out.write("<div class=\"grid-toolbar\">\n");

        // Chap blok — yozuv soni
        out.write("<span class=\"grid-meta\">Jami: <strong>" + model.getTotalRows() + "</strong> ta yozuv");
        if (model.getTotalPages() > 1) {
            out.write(" &middot; Sahifa " + model.getPage() + " / " + model.getTotalPages());
        }
        out.write("</span>\n");

        // O'ng blok — harakatlar
        out.write("<div class=\"grid-tools\">\n");

        // Zichlik (compact / keng) toggle
        out.write("<button type=\"button\" class=\"grid-tool-btn\" data-grid-density title=\"Zichlik\" aria-label=\"Zichlik\">");
        out.write("<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><line x1=\"3\" y1=\"6\" x2=\"21\" y2=\"6\"/><line x1=\"3\" y1=\"10\" x2=\"21\" y2=\"10\"/><line x1=\"3\" y1=\"14\" x2=\"21\" y2=\"14\"/><line x1=\"3\" y1=\"18\" x2=\"21\" y2=\"18\"/></svg>");
        out.write("<span>Zichlik</span></button>\n");

        // Ustunlar dropdown — har ustun uchun checkbox
        out.write("<div class=\"grid-dropdown\" data-col-menu>\n");
        out.write("<button type=\"button\" class=\"grid-tool-btn\" data-col-toggle aria-haspopup=\"true\" aria-expanded=\"false\">");
        out.write("<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z\"/><path d=\"M12 8v8M8 12h8\"/></svg>");
        out.write("<span>Ustunlar</span></button>\n");
        out.write("<div class=\"grid-menu\" data-col-list hidden>\n");
        int ci = 0;
        for (ColumnDef col : columnDefs) {
            out.write("<label class=\"grid-menu-item\">");
            out.write("<input type=\"checkbox\" data-col-index=\"" + ci + "\" checked> ");
            out.write("<span>" + escHtml(col.getTitle()) + "</span></label>\n");
            ci++;
        }
        out.write("</div>\n</div>\n");

        // Eksport tugmalari
        out.write("<button type=\"button\" class=\"grid-tool-btn\" data-grid-export=\"csv\" title=\"CSV yuklab olish\">");
        out.write("<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\"/><polyline points=\"7 10 12 15 17 10\"/><line x1=\"12\" y1=\"15\" x2=\"12\" y2=\"3\"/></svg>");
        out.write("<span>CSV</span></button>\n");
        out.write("<button type=\"button\" class=\"grid-tool-btn\" data-grid-export=\"excel\" title=\"Excel yuklab olish\">");
        out.write("<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\"/><polyline points=\"7 10 12 15 17 10\"/><line x1=\"12\" y1=\"15\" x2=\"12\" y2=\"3\"/></svg>");
        out.write("<span>Excel</span></button>\n");

        // Sahifa o'lchami tanlash
        out.write("<label class=\"grid-pagesize\">");
        out.write("<span>Ko'rsatish:</span>");
        out.write("<select class=\"form-control\" data-page-size>\n");
        for (int opt : PAGE_SIZE_OPTIONS) {
            String sel = (opt == model.getPageSize()) ? " selected" : "";
            String url = escHtml(model.pageSizeUrl(opt));
            out.write("<option value=\"" + url + "\"" + sel + ">" + opt + "</option>\n");
        }
        out.write("</select></label>\n");

        out.write("</div>\n"); // .grid-tools
        out.write("</div>\n"); // .grid-toolbar
    }

    /** Saralanadigan / oddiy header katakcha (th) chizish */
    private void renderHeaderCell(JspWriter out, ColumnDef col) throws IOException {
        String style = (col.getWidth() != null) ? " style=\"width:" + col.getWidth() + "\"" : "";
        boolean isActive = model.getSortCol() != null
                && model.getSortCol().equalsIgnoreCase(col.getField());
        String dir = isActive ? model.getSortDir() : null;

        if (!col.isSortable()) {
            out.write("<th" + style + ">" + escHtml(col.getTitle()) + "</th>\n");
            return;
        }

        String nextDir = nextSortDir(col);
        String href = escHtml(model.sortUrl(col.getField(), nextDir));
        String thClass = "th-sortable" + (isActive ? " is-sorted" : "");
        out.write("<th" + style + " class=\"" + thClass + "\" aria-sort=\""
                + ("asc".equals(dir) ? "ascending" : "desc".equals(dir) ? "descending" : "none") + "\">");
        out.write("<a class=\"th-sort\" href=\"" + href + "\">");
        out.write("<span>" + escHtml(col.getTitle()) + "</span>");
        out.write("<span class=\"sort-ind\" aria-hidden=\"true\">");
        if ("asc".equals(dir)) out.write("↑");
        else if ("desc".equals(dir)) out.write("↓");
        else out.write("⇅");
        out.write("</span>");
        out.write("</a></th>\n");
    }

    // ================================================================
    //  JSON RENDERING (for editable datagrids)
    // ================================================================

    private void renderJson() throws IOException {
        JspWriter out = pageContext.getOut();
        String gridId = (id != null) ? id : "grid_" + System.identityHashCode(this);

        StringBuilder json = new StringBuilder();
        json.append("{");

        // columns
        json.append("\"columns\":[");
        for (int i = 0; i < columnDefs.size(); i++) {
            if (i > 0) json.append(",");
            ColumnDef col = columnDefs.get(i);
            json.append("{");
            json.append("\"field\":\"").append(escJson(col.getField())).append("\"");
            json.append(",\"title\":\"").append(escJson(col.getTitle())).append("\"");
            if (col.getLink() != null) json.append(",\"link\":\"").append(escJson(col.getLink())).append("\"");
            if (col.getBadge() != null) json.append(",\"badge\":\"").append(escJson(col.getBadge())).append("\"");
            if (col.getFormat() != null) json.append(",\"format\":\"").append(escJson(col.getFormat())).append("\"");
            if (col.getAlign() != null) json.append(",\"align\":\"").append(escJson(col.getAlign())).append("\"");
            if (col.getWidth() != null) json.append(",\"width\":\"").append(escJson(col.getWidth())).append("\"");
            if (col.isEditable()) json.append(",\"editable\":true");
            if (col.getEditType() != null) json.append(",\"editType\":\"").append(escJson(col.getEditType())).append("\"");
            if (col.getEditOptions() != null) json.append(",\"editOptions\":\"").append(escJson(col.getEditOptions())).append("\"");
            if (!col.isSortable()) json.append(",\"sortable\":false");
            json.append("}");
        }
        json.append("]");

        // filters
        json.append(",\"filters\":[");
        for (int i = 0; i < model.getFilters().size(); i++) {
            if (i > 0) json.append(",");
            FilterDef f = model.getFilters().get(i);
            json.append("{");
            json.append("\"field\":\"").append(escJson(f.getField())).append("\"");
            json.append(",\"label\":\"").append(escJson(f.getLabel())).append("\"");
            json.append(",\"type\":\"").append(escJson(f.getType())).append("\"");
            if (f.getValue() != null) json.append(",\"value\":\"").append(escJson(f.getValue())).append("\"");
            if (f.getOptions() != null) {
                json.append(",\"options\":[");
                for (int j = 0; j < f.getOptions().size(); j++) {
                    if (j > 0) json.append(",");
                    String[] opt = f.getOptions().get(j);
                    json.append("[\"").append(escJson(opt[0])).append("\",\"").append(escJson(opt[1])).append("\"]");
                }
                json.append("]");
            }
            json.append("}");
        }
        json.append("]");

        // rows
        json.append(",\"rows\":[");
        List<Map<String, Object>> rows = model.getRows();
        for (int r = 0; r < rows.size(); r++) {
            if (r > 0) json.append(",");
            json.append("{");
            Map<String, Object> row = rows.get(r);
            int fc = 0;
            for (Map.Entry<String, Object> e : row.entrySet()) {
                if (fc > 0) json.append(",");
                json.append("\"").append(escJson(e.getKey())).append("\":");
                appendJsonValue(json, e.getValue());
                fc++;
            }
            json.append("}");
        }
        json.append("]");

        // pagination
        json.append(",\"page\":").append(model.getPage());
        json.append(",\"pageSize\":").append(model.getPageSize());
        json.append(",\"totalRows\":").append(model.getTotalRows());
        json.append(",\"totalPages\":").append(model.getTotalPages());
        json.append(",\"baseUrl\":\"").append(escJson(model.getBaseUrl() != null ? model.getBaseUrl() : "")).append("\"");
        if (model.getSortCol() != null) {
            json.append(",\"sortCol\":\"").append(escJson(model.getSortCol())).append("\"");
            json.append(",\"sortDir\":\"").append(escJson(model.getSortDir())).append("\"");
        }

        // feature flags + emptyText
        json.append(",\"pageSizeOptions\":[20,50,100]");
        if (selectable) json.append(",\"selectable\":true");
        if (stickyHeader) json.append(",\"stickyHeader\":true");
        if (saveUrl != null) json.append(",\"saveUrl\":\"").append(escJson(saveUrl)).append("\"");
        json.append(",\"emptyText\":\"").append(escJson(emptyText)).append("\"");

        json.append("}");

        out.write("<div id=\"" + escHtml(gridId) + "\" class=\"abs-datagrid\" data-config='");
        out.write(json.toString().replace("'", "&#39;"));
        out.write("'></div>\n");
    }

    private void appendJsonValue(StringBuilder sb, Object val) {
        if (val == null) {
            sb.append("null");
        } else if (val instanceof Number) {
            sb.append(val);
        } else if (val instanceof Boolean) {
            sb.append(val);
        } else if (val instanceof java.util.Date) {
            sb.append("\"").append(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(val)).append("\"");
        } else {
            sb.append("\"").append(escJson(val.toString())).append("\"");
        }
    }

    // ================================================================
    //  SHARED RENDER HELPERS
    // ================================================================

    private void renderFilterBar(JspWriter out) throws IOException {
        String baseUrl = model.getBaseUrl() != null ? model.getBaseUrl() : "";
        out.write("<form method=\"get\" action=\"" + escHtml(baseUrl) + "\" class=\"filter-bar\" style=\"margin-bottom:1rem;\">\n");

        for (FilterDef f : model.getFilters()) {
            out.write("<div class=\"form-group\" style=\"margin-bottom:0;\">\n");
            out.write("<label style=\"font-size:0.8rem; margin-bottom:0.2rem;\">" + escHtml(f.getLabel()) + "</label>\n");

            if ("select".equals(f.getType()) && f.getOptions() != null) {
                out.write("<select name=\"f_" + f.getField() + "\" class=\"form-control\" style=\"min-width:120px;\">\n");
                out.write("<option value=\"\">Barchasi</option>\n");
                for (String[] opt : f.getOptions()) {
                    String selected = opt[0].equals(f.getValue()) ? " selected" : "";
                    out.write("<option value=\"" + escHtml(opt[0]) + "\"" + selected + ">" + escHtml(opt[1]) + "</option>\n");
                }
                out.write("</select>\n");
            } else {
                String val = f.getValue() != null ? f.getValue() : "";
                out.write("<input type=\"text\" name=\"f_" + f.getField() + "\" class=\"form-control\" ");
                out.write("value=\"" + escHtml(val) + "\" placeholder=\"" + escHtml(f.getLabel()) + "...\">\n");
            }
            out.write("</div>\n");
        }

        out.write("<div class=\"form-group\" style=\"margin-bottom:0; align-self:end;\">\n");
        out.write("<button type=\"submit\" class=\"btn btn-primary\" style=\"margin-top:auto;\">Qidirish</button>\n");
        out.write("</div>\n");
        out.write("<div class=\"form-group\" style=\"margin-bottom:0; align-self:end;\">\n");
        out.write("<a href=\"" + escHtml(baseUrl) + "\" class=\"btn\">Tozalash</a>\n");
        out.write("</div>\n");
        out.write("</form>\n");
    }

    private void renderCell(JspWriter out, ColumnDef col, Map<String, Object> row) throws IOException {
        Object value = row.get(col.getField());
        String displayVal = formatValue(value, col.getFormat());

        String style = col.getAlign() != null ? " style=\"text-align:" + col.getAlign() + "\"" : "";
        String cls = col.getCssClass() != null ? " class=\"" + col.getCssClass() + "\"" : "";

        out.write("<td" + style + cls + ">");

        if (col.getBadge() != null && value != null) {
            String badgeClass = col.resolveBadgeClassFull(value);
            String badgeText = col.resolveBadgeText(value);
            out.write("<span class=\"badge badge-" + escHtml(badgeClass) + "\">" + escHtml(badgeText) + "</span>");
        } else if (col.getLink() != null && value != null) {
            String href = col.resolveLink(row);
            String modalAttr = "";
            if (linkModal) {
                modalAttr = " data-modal";
                if (linkModalSize != null) modalAttr += " data-modal-size=\"" + escHtml(linkModalSize) + "\"";
            }
            out.write("<a href=\"" + escHtml(href) + "\" class=\"link\"" + modalAttr + ">" + escHtml(displayVal) + "</a>");
        } else {
            out.write(displayVal != null ? escHtml(displayVal) : "");
        }

        out.write("</td>\n");
    }

    private void renderFooter(JspWriter out) throws IOException {
        out.write("<tfoot><tr>\n");
        for (ColumnDef col : columnDefs) {
            out.write("<td>");
            if (col.isFooter() && col.getFooterFunc() != null) {
                double result = calculateFooter(col);
                out.write("<strong>" + formatValue(result, col.getFormat()) + "</strong>");
            }
            out.write("</td>\n");
        }
        out.write("</tr></tfoot>\n");
    }

    private double calculateFooter(ColumnDef col) {
        String func = col.getFooterFunc();
        double sum = 0; int count = 0;
        for (Map<String, Object> row : model.getRows()) {
            Object val = row.get(col.getField());
            if (val instanceof Number) { sum += ((Number) val).doubleValue(); count++; }
        }
        if ("sum".equals(func)) return sum;
        if ("avg".equals(func) && count > 0) return sum / count;
        if ("count".equals(func)) return count;
        return sum;
    }

    private void renderPagination(JspWriter out) throws IOException {
        int page = model.getPage();
        int total = model.getTotalPages();

        out.write("<div class=\"pagination\" style=\"margin-top:1rem;\">\n");

        if (page > 1) {
            out.write("<a href=\"" + escHtml(model.pageUrl(page - 1)) + "\" class=\"btn btn-sm\">&laquo; Oldingi</a> ");
        }

        int start = Math.max(1, page - 3);
        int end = Math.min(total, page + 3);

        if (start > 1) {
            out.write("<a href=\"" + escHtml(model.pageUrl(1)) + "\" class=\"btn btn-sm\">1</a> ");
            if (start > 2) out.write("<span style=\"padding:0 0.3rem;\">...</span> ");
        }

        for (int i = start; i <= end; i++) {
            if (i == page) {
                out.write("<span class=\"btn btn-sm btn-primary\">" + i + "</span> ");
            } else {
                out.write("<a href=\"" + escHtml(model.pageUrl(i)) + "\" class=\"btn btn-sm\">" + i + "</a> ");
            }
        }

        if (end < total) {
            if (end < total - 1) out.write("<span style=\"padding:0 0.3rem;\">...</span> ");
            out.write("<a href=\"" + escHtml(model.pageUrl(total)) + "\" class=\"btn btn-sm\">" + total + "</a> ");
        }

        if (page < total) {
            out.write("<a href=\"" + escHtml(model.pageUrl(page + 1)) + "\" class=\"btn btn-sm\">Keyingi &raquo;</a>");
        }

        out.write("\n</div>\n");
    }

    private String formatValue(Object value, String format) {
        if (value == null) return null;
        if (format != null && !format.isEmpty()) {
            if (value instanceof java.util.Date) return new SimpleDateFormat(format).format(value);
            if (value instanceof Number) return new java.text.DecimalFormat(format).format(value);
        }
        return value.toString();
    }

    private String escHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }

    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    @Override
    public void release() {
        super.release();
        var = null; view = null; orderBy = null; pageSize = 20;
        columns = null; mode = "html"; emptyText = "Ma'lumot topilmadi";
        id = null; title = null; linkModal = false; linkModalSize = null;
        selectable = false; stickyHeader = true; saveUrl = null;
        rowId = null; bulkStatus = null;
        filterDefs = new ArrayList<>();
        columnDefs = new ArrayList<>();
        fieldMetas = new LinkedHashMap<>();
        model = null;
    }
}

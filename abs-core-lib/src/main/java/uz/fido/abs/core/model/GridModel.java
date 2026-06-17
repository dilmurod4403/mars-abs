package uz.fido.abs.core.model;

import java.io.Serializable;
import java.util.*;

/**
 * Grid ma'lumot modeli — <abs:data> dan <abs:grid> ga uzatiladi.
 * View dan o'qilgan qatorlar, filtrlar, pagination ma'lumotlari.
 */
public class GridModel implements Serializable {
    private String view;
    private List<Map<String, Object>> rows;
    private List<FilterDef> filters;
    private int totalRows;
    private int page;
    private int pageSize;
    private int totalPages;
    private String orderBy;
    private String baseUrl; // Current page URL for pagination links
    private String sortCol; // Faol saralash ustuni (request param "s")
    private String sortDir; // Saralash yo'nalishi: "asc" yoki "desc" (request param "d")

    public GridModel() {
        this.rows = new ArrayList<>();
        this.filters = new ArrayList<>();
        this.page = 1;
        this.pageSize = 20;
    }

    // Calculate total pages
    public void calculatePages() {
        this.totalPages = (totalRows + pageSize - 1) / pageSize;
        if (this.page > this.totalPages && this.totalPages > 0) {
            this.page = this.totalPages;
        }
    }

    // All getters and setters
    public String getView() { return view; }
    public void setView(String view) { this.view = view; }
    public List<Map<String, Object>> getRows() { return rows; }
    public void setRows(List<Map<String, Object>> rows) { this.rows = rows; }
    public List<FilterDef> getFilters() { return filters; }
    public void setFilters(List<FilterDef> filters) { this.filters = filters; }
    public int getTotalRows() { return totalRows; }
    public void setTotalRows(int totalRows) { this.totalRows = totalRows; }
    public int getPage() { return page; }
    public void setPage(int page) { this.page = page; }
    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }
    public int getTotalPages() { return totalPages; }
    public void setTotalPages(int totalPages) { this.totalPages = totalPages; }
    public String getOrderBy() { return orderBy; }
    public void setOrderBy(String orderBy) { this.orderBy = orderBy; }
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
    public String getSortCol() { return sortCol; }
    public void setSortCol(String sortCol) { this.sortCol = sortCol; }
    public String getSortDir() { return sortDir; }
    public void setSortDir(String sortDir) { this.sortDir = sortDir; }

    public void addFilter(FilterDef filter) { this.filters.add(filter); }
    public void addRow(Map<String, Object> row) { this.rows.add(row); }

    private void appendEncoded(StringBuilder sb, String key, String value) {
        sb.append('&').append(key).append('=');
        try {
            sb.append(java.net.URLEncoder.encode(value, "UTF-8"));
        } catch (Exception e) {
            sb.append(value);
        }
    }

    /** Joriy filter param'larini URL ga qo'shadi (page/sort/ps dan tashqari) */
    private void appendFilters(StringBuilder sb) {
        for (FilterDef f : filters) {
            if (f.getValue() != null && !f.getValue().isEmpty()) {
                appendEncoded(sb, "f_" + f.getField(), f.getValue());
            }
        }
    }

    /**
     * Build pagination URL with query parameters.
     * Preserves existing filter params, active sort and page-size.
     */
    public String pageUrl(int targetPage) {
        StringBuilder sb = new StringBuilder(baseUrl != null ? baseUrl : "");
        sb.append("?page=").append(targetPage);
        appendFilters(sb);
        if (sortCol != null && !sortCol.isEmpty()) {
            appendEncoded(sb, "s", sortCol);
            appendEncoded(sb, "d", sortDir != null ? sortDir : "asc");
        }
        if (pageSize > 0) sb.append("&ps=").append(pageSize);
        return sb.toString();
    }

    /**
     * Build a sort URL for a column header.
     * Preserves filters and current page-size; resets to page 1.
     * targetDir null => saralashni o'chirish (faqat filter/ps qoladi).
     */
    public String sortUrl(String field, String targetDir) {
        StringBuilder sb = new StringBuilder(baseUrl != null ? baseUrl : "");
        sb.append("?page=1");
        appendFilters(sb);
        if (targetDir != null) {
            appendEncoded(sb, "s", field);
            appendEncoded(sb, "d", targetDir);
        }
        if (pageSize > 0) sb.append("&ps=").append(pageSize);
        return sb.toString();
    }

    /**
     * Build a page-size change URL.
     * Preserves filters and active sort; resets to page 1.
     */
    public String pageSizeUrl(int newSize) {
        StringBuilder sb = new StringBuilder(baseUrl != null ? baseUrl : "");
        sb.append("?page=1");
        appendFilters(sb);
        if (sortCol != null && !sortCol.isEmpty()) {
            appendEncoded(sb, "s", sortCol);
            appendEncoded(sb, "d", sortDir != null ? sortDir : "asc");
        }
        sb.append("&ps=").append(newSize);
        return sb.toString();
    }
}

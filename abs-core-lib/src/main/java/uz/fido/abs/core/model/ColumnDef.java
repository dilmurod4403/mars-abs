package uz.fido.abs.core.model;

import java.io.Serializable;

/**
 * Grid ustun ta'rifi — qanday ko'rinishda chiziladi.
 */
public class ColumnDef implements Serializable {
    private String field;       // DB column name
    private String title;       // Column header text
    private String link;        // URL template: "detail.jsp?id={customer_id}"
    private String badge;       // Badge mapping: "ACTIVE:active,PENDING:pending" or "true" for auto
    private String format;      // Date/number format: "dd.MM.yyyy", "#,##0.00"
    private String align;       // "left", "center", "right"
    private String width;       // CSS width: "120px", "15%"
    private String cssClass;    // Additional CSS class
    private boolean footer;     // Show in footer (for totals)
    private String footerFunc;  // Footer function: "sum", "count", "avg"
    private boolean editable;   // Editable in JSON/datagrid mode
    private String editType;    // Edit input type: "text", "select", "number", "date"
    private String editOptions; // Select options for editing: "ACTIVE:Faol,BLOCKED:Bloklangan"
    private boolean sortable = true; // Server-side ORDER BY ustun sifatida saralash mumkin

    public ColumnDef() {}

    // All getters/setters
    public String getField() { return field; }
    public void setField(String field) { this.field = field; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getLink() { return link; }
    public void setLink(String link) { this.link = link; }
    public String getBadge() { return badge; }
    public void setBadge(String badge) { this.badge = badge; }
    public String getFormat() { return format; }
    public void setFormat(String format) { this.format = format; }
    public String getAlign() { return align; }
    public void setAlign(String align) { this.align = align; }
    public String getWidth() { return width; }
    public void setWidth(String width) { this.width = width; }
    public String getCssClass() { return cssClass; }
    public void setCssClass(String cssClass) { this.cssClass = cssClass; }
    public boolean isFooter() { return footer; }
    public void setFooter(boolean footer) { this.footer = footer; }
    public String getFooterFunc() { return footerFunc; }
    public void setFooterFunc(String footerFunc) { this.footerFunc = footerFunc; }
    public boolean isEditable() { return editable; }
    public void setEditable(boolean editable) { this.editable = editable; }
    public String getEditType() { return editType; }
    public void setEditType(String editType) { this.editType = editType; }
    public String getEditOptions() { return editOptions; }
    public void setEditOptions(String editOptions) { this.editOptions = editOptions; }
    public boolean isSortable() { return sortable; }
    public void setSortable(boolean sortable) { this.sortable = sortable; }

    /**
     * Resolve link template with row data.
     * Example: "detail.jsp?id={customer_id}" + row → "detail.jsp?id=123"
     */
    public String resolveLink(java.util.Map<String, Object> row) {
        if (link == null) return null;
        String result = link;
        for (java.util.Map.Entry<String, Object> e : row.entrySet()) {
            result = result.replace("{" + e.getKey() + "}",
                e.getValue() != null ? e.getValue().toString() : "");
        }
        return result;
    }

    /**
     * Resolve badge class from mapping.
     * "ACTIVE:active,PENDING:pending" → for value "ACTIVE" returns "active"
     */
    public String resolveBadgeClass(Object value) {
        if (badge == null || value == null) return null;
        if ("true".equals(badge)) {
            // Auto: use lowercase value as badge class
            return value.toString().toLowerCase();
        }
        String strVal = value.toString();
        for (String mapping : badge.split(",")) {
            String[] parts = mapping.trim().split(":");
            if (parts.length >= 2 && parts[0].equals(strVal)) {
                return parts[1];
            }
        }
        return strVal.toLowerCase();
    }

    /**
     * Resolve badge display text from mapping.
     * "INDIVIDUAL:FYaSh:individual,CORPORATE:YuSh:corporate" → for "INDIVIDUAL" returns "FYaSh"
     */
    public String resolveBadgeText(Object value) {
        if (badge == null || value == null) return value.toString();
        String strVal = value.toString();
        for (String mapping : badge.split(",")) {
            String[] parts = mapping.trim().split(":");
            if (parts.length >= 3 && parts[0].equals(strVal)) {
                return parts[1]; // display text
            }
        }
        return strVal;
    }

    /**
     * For 3-part badge: "VALUE:DisplayText:cssClass"
     * Returns cssClass part
     */
    public String resolveBadgeClassFull(Object value) {
        if (badge == null || value == null) return null;
        if ("true".equals(badge)) return value.toString().toLowerCase();
        String strVal = value.toString();
        for (String mapping : badge.split(",")) {
            String[] parts = mapping.trim().split(":");
            if (parts[0].equals(strVal)) {
                return parts.length >= 3 ? parts[2] : (parts.length >= 2 ? parts[1] : strVal.toLowerCase());
            }
        }
        return strVal.toLowerCase();
    }
}

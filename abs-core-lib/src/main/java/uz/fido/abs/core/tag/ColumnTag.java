package uz.fido.abs.core.tag;

import uz.fido.abs.core.model.ColumnDef;
import javax.servlet.jsp.JspException;
import javax.servlet.jsp.tagext.TagSupport;

/**
 * UI ustun ta'rifi — t:grid ichida ishlatiladi.
 * Qaysi field UI da qanday ko'rinishda chiqishini belgilaydi.
 * title va format — t:field dan olinadi, t:col da override qilish mumkin.
 *
 * Ishlatish:
 *   <t:grid pageSize="20">
 *       <t:col field="username" link="edit.jsp?id={user_id}" />
 *       <t:col field="status" badge="ACTIVE:Faol:active" />
 *       <t:col field="created_at" />
 *   </t:grid>
 */
public class ColumnTag extends TagSupport {

    private String field;
    private String title;       // override (default: from t:field)
    private String format;      // override (default: from t:field)
    private String link;
    private String badge;
    private String align;
    private String width;
    private String cssClass;
    private boolean footer = false;
    private String footerFunc;
    private boolean editable = false;
    private String editType;
    private String editOptions;
    private boolean sortable = true;   // default: saralanadi

    public void setField(String field) { this.field = field; }
    public void setTitle(String title) { this.title = title; }
    public void setFormat(String format) { this.format = format; }
    public void setLink(String link) { this.link = link; }
    public void setBadge(String badge) { this.badge = badge; }
    public void setAlign(String align) { this.align = align; }
    public void setWidth(String width) { this.width = width; }
    public void setCssClass(String cssClass) { this.cssClass = cssClass; }
    public void setFooter(boolean footer) { this.footer = footer; }
    public void setFooterFunc(String footerFunc) { this.footerFunc = footerFunc; }
    public void setEditable(boolean editable) { this.editable = editable; }
    public void setEditType(String editType) { this.editType = editType; }
    public void setEditOptions(String editOptions) { this.editOptions = editOptions; }
    public void setSortable(boolean sortable) { this.sortable = sortable; }

    @Override
    public int doStartTag() throws JspException {
        GridTag gridParent = (GridTag) findAncestorWithClass(this, GridTag.class);
        if (gridParent == null) {
            throw new JspException("<t:col> must be nested inside <t:grid>");
        }

        TableTag tableParent = (TableTag) findAncestorWithClass(this, TableTag.class);
        if (tableParent == null) {
            throw new JspException("<t:col> must be inside <t:table>");
        }

        // Resolve title: explicit > from t:field > field name
        String resolvedTitle = (title != null) ? title : tableParent.getFieldTitle(field);
        // Resolve format: explicit > from t:field
        String resolvedFormat = (format != null) ? format : tableParent.getFieldFormat(field);

        ColumnDef cd = new ColumnDef();
        cd.setField(field);
        cd.setTitle(resolvedTitle);
        cd.setFormat(resolvedFormat);
        cd.setLink(link);
        cd.setBadge(badge);
        cd.setAlign(align);
        cd.setWidth(width);
        cd.setCssClass(cssClass);
        cd.setFooter(footer);
        cd.setFooterFunc(footerFunc);
        cd.setEditable(editable);
        cd.setEditType(editType);
        cd.setEditOptions(editOptions);
        cd.setSortable(sortable);

        tableParent.addColumn(cd);

        return SKIP_BODY;
    }

    @Override
    public void release() {
        super.release();
        field = null; title = null; format = null;
        link = null; badge = null;
        align = null; width = null; cssClass = null;
        footer = false; footerFunc = null;
        editable = false; editType = null; editOptions = null;
        sortable = true;
    }
}

package uz.fido.abs.core.tag;

import uz.fido.abs.core.model.FilterDef;
import javax.servlet.jsp.JspException;
import javax.servlet.jsp.tagext.TagSupport;

/**
 * Ma'lumot maydoni ta'rifi — t:table ichida ishlatiladi.
 * field nomi, sarlavha, format va ixtiyoriy filter belgilanadi.
 * UI da qanday chiqishi t:grid > t:col orqali belgilanadi.
 *
 * Ishlatish:
 *   <t:table view="...">
 *       <t:field field="status" title="Holat">
 *           <t:filter type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda" />
 *       </t:field>
 *       <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />
 *
 *       <t:grid pageSize="20">
 *           <t:col field="status" badge="ACTIVE:Faol:active" />
 *           <t:col field="created_at" />
 *       </t:grid>
 *   </t:table>
 */
public class FieldTag extends TagSupport {

    private String field;
    private String title;
    private String format;

    // Filter (set by child FilterTag)
    private boolean hasFilter = false;
    private String filterType;
    private String filterOptions;

    public void setField(String field) { this.field = field; }
    public void setTitle(String title) { this.title = title; }
    public void setFormat(String format) { this.format = format; }

    // Getters for child FilterTag
    public String getField() { return field; }
    public String getTitle() { return title != null ? title : field; }

    /** Called by child FilterTag */
    void setFilterConfig(String type, String options) {
        this.hasFilter = true;
        this.filterType = type;
        this.filterOptions = options;
    }

    @Override
    public int doStartTag() throws JspException {
        hasFilter = false;
        filterType = null;
        filterOptions = null;
        return EVAL_BODY_INCLUDE;  // allow child t:filter
    }

    @Override
    public int doEndTag() throws JspException {
        TableTag tableParent = (TableTag) findAncestorWithClass(this, TableTag.class);
        if (tableParent == null) {
            throw new JspException("<t:field> must be nested inside <t:table>");
        }

        // 1) Register field metadata (title, format) for t:col to use later
        tableParent.registerField(field, title != null ? title : field, format);

        // 2) Register filter if child t:filter was present
        if (hasFilter) {
            String fType = (filterType != null) ? filterType : "text";
            String fLabel = (title != null) ? title : field;
            FilterDef fd = new FilterDef(field, fLabel, fType);
            if (filterOptions != null && !filterOptions.isEmpty()) {
                fd.parseOptions(filterOptions);
            }
            tableParent.addFilter(fd);
        }

        return EVAL_PAGE;
    }

    @Override
    public void release() {
        super.release();
        field = null; title = null; format = null;
        hasFilter = false; filterType = null; filterOptions = null;
    }
}

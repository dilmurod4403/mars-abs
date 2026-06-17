package uz.fido.abs.core.tag;

import uz.fido.abs.core.model.FilterDef;
import javax.servlet.jsp.JspException;
import javax.servlet.jsp.tagext.TagSupport;

/**
 * Filter tegi — t:field ichida ishlatiladi.
 * field va label parent t:field dan olinadi.
 *
 * Ishlatish:
 *   <t:field field="status" title="Holat">
 *       <t:filter type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda" />
 *   </t:field>
 */
public class FilterTag extends TagSupport {

    private String type = "text";   // "text", "select", "date"
    private String options;         // For select: "ACTIVE:Faol,PENDING:Kutilmoqda"

    public void setType(String type) { this.type = type; }
    public void setOptions(String options) { this.options = options; }

    @Override
    public int doStartTag() throws JspException {
        // Inside t:field
        FieldTag fieldParent = (FieldTag) findAncestorWithClass(this, FieldTag.class);
        if (fieldParent != null) {
            fieldParent.setFilterConfig(type, options);
            return SKIP_BODY;
        }

        // Legacy: inside t:data (DataTag)
        DataTag dataParent = (DataTag) findAncestorWithClass(this, DataTag.class);
        if (dataParent != null) {
            // Legacy mode — field/label from attributes (kept for backward compat)
            throw new JspException("<t:filter> must be nested inside <t:field>");
        }

        throw new JspException("<t:filter> must be nested inside <t:field>");
    }

    @Override
    public void release() {
        super.release();
        type = "text";
        options = null;
    }
}

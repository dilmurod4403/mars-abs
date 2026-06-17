package uz.fido.abs.core.tag;

import javax.servlet.jsp.JspException;
import javax.servlet.jsp.tagext.TagSupport;

/**
 * Grid sozlamalari tegi — t:table ichida ishlatiladi.
 * Ichida t:col teglar bilan qaysi ustunlar UI ga chiqishi belgilanadi.
 *
 * Ishlatish:
 *   <t:table view="..." var="data">
 *       <t:field field="username" title="Username">
 *           <t:filter type="text" />
 *       </t:field>
 *       <t:field field="status" title="Holat" />
 *
 *       <t:grid pageSize="20" emptyText="Ma'lumot topilmadi">
 *           <t:col field="username" link="edit.jsp?id={user_id}" />
 *           <t:col field="status" badge="ACTIVE:Faol:active" />
 *       </t:grid>
 *   </t:table>
 */
public class GridTag extends TagSupport {

    private int pageSize = 0;       // 0 = default (TableTag decides)
    private String mode;            // "html" or "json"
    private String emptyText;       // Empty state message
    private String id;              // HTML table / grid container id
    private String title;           // Grid title
    private String modal;           // "true" = link'lar modal oynada ochiladi
    private String modalSize;       // modal o'lchami: sm/md/lg/xl
    private String selectable;      // "true" = qator tanlash (checkbox + bulk toolbar)
    private String stickyHeader;    // "true"/"false" = sticky thead (default: true)
    private String saveUrl;         // inline tahrir / bulk amal saqlash POST manzili
    private String rowId;           // qator PK ustuni (bulk amal id manbai)
    private String bulkStatus;      // bulk status variantlari

    public void setPageSize(int pageSize) { this.pageSize = pageSize; }
    public void setMode(String mode) { this.mode = mode; }
    public void setEmptyText(String emptyText) { this.emptyText = emptyText; }
    public void setId(String id) { this.id = id; }
    public void setTitle(String title) { this.title = title; }
    public void setModal(String modal) { this.modal = modal; }
    public void setModalSize(String modalSize) { this.modalSize = modalSize; }
    public void setSelectable(String selectable) { this.selectable = selectable; }
    public void setStickyHeader(String stickyHeader) { this.stickyHeader = stickyHeader; }
    public void setSaveUrl(String saveUrl) { this.saveUrl = saveUrl; }
    public void setRowId(String rowId) { this.rowId = rowId; }
    public void setBulkStatus(String bulkStatus) { this.bulkStatus = bulkStatus; }

    @Override
    public int doStartTag() throws JspException {
        TableTag parent = (TableTag) findAncestorWithClass(this, TableTag.class);
        if (parent == null) {
            throw new JspException("<t:grid> must be nested inside <t:table>");
        }

        // Pass settings to parent TableTag
        if (pageSize > 0) parent.setPageSize(pageSize);
        if (mode != null) parent.setMode(mode);
        if (emptyText != null) parent.setEmptyText(emptyText);
        if (id != null) parent.setId(id);
        if (title != null) parent.setTitle(title);
        if (modal != null) parent.setLinkModal("true".equalsIgnoreCase(modal));
        if (modalSize != null) parent.setLinkModalSize(modalSize);
        if (selectable != null) parent.setSelectable("true".equalsIgnoreCase(selectable));
        if (stickyHeader != null) parent.setStickyHeader("true".equalsIgnoreCase(stickyHeader));
        if (saveUrl != null) parent.setSaveUrl(saveUrl);
        if (rowId != null) parent.setRowId(rowId);
        if (bulkStatus != null) parent.setBulkStatus(bulkStatus);

        return EVAL_BODY_INCLUDE;  // allow child t:col tags
    }

    @Override
    public void release() {
        super.release();
        pageSize = 0;
        mode = null;
        emptyText = null;
        id = null;
        title = null;
        modal = null;
        modalSize = null;
        selectable = null;
        stickyHeader = null;
        saveUrl = null;
        rowId = null;
        bulkStatus = null;
    }
}

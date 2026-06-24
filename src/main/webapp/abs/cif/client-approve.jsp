<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Klient tasdiqlash"/>
    <jsp:param name="page" value="client-approve"/>
</jsp:include>

<div class="page-header">
    <h1>Klient tasdiqlash</h1>
</div>

<%-- Maker-Checker tushuntirishi --%>
<div class="alert alert-info" style="display:flex; align-items:flex-start; gap:0.75rem; margin-bottom:1.5rem;">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0; margin-top:1px; color:var(--info,#2563eb)"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    <span>Yaratuvchi (Maker) o'zi yaratgan klientni tasdiqlay olmaydi — boshqa foydalanuvchi (Checker) tasdiqlaydi.</span>
</div>

<t:table view="core_cif_pending_clients_v" var="data" orderBy="created_at DESC">

    <t:field field="client_code" title="Klient kodi">
        <t:filter type="text" />
    </t:field>
    <t:field field="full_name" title="To'liq nomi">
        <t:filter type="text" />
    </t:field>
    <t:field field="kind_name" title="Turi" />
    <t:field field="client_type_name" title="Klient kategoriyasi">
        <t:filter type="text" />
    </t:field>
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Tasdiq kutayotgan klient yo'q" modal="true" modalSize="lg"
            selectable="true" rowId="client_id"
            saveUrl="${pageContext.request.contextPath}/abs/cif/client-bulk-save.jsp"
            bulkStatus="APPROVED:Tasdiqlash">
        <t:col field="client_code" link="client-detail.jsp?id={client_id}" width="140px" />
        <t:col field="full_name"   link="client-detail.jsp?id={client_id}" />
        <t:col field="kind_name"   width="120px" />
        <t:col field="client_type_name" />
        <t:col field="created_at" width="110px" />
    </t:grid>

</t:table>

<jsp:include page="cif-footer.jsp"/>

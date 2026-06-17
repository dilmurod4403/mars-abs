<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Muddati o'tgan hujjatlar"/>
    <jsp:param name="page" value="expired"/>
</jsp:include>

<div class="page-header">
    <h1>Muddati o'tgan hujjatlar</h1>
</div>

<t:table view="core_cif_expired_docs_ui_v" var="data" orderBy="days_expired DESC">

    <t:field field="cif_number" title="CIF" />
    <t:field field="customer_display_name" title="Mijoz nomi">
        <t:filter type="text" />
    </t:field>
    <t:field field="customer_status" title="Holat" />
    <t:field field="doc_type" title="Hujjat turi">
        <t:filter type="text" />
    </t:field>
    <t:field field="doc_number" title="Raqam" />
    <t:field field="issued_date" title="Berilgan sana" format="dd.MM.yyyy" />
    <t:field field="expiry_date" title="Amal qilish" format="dd.MM.yyyy" />
    <t:field field="days_expired" title="O'tgan kunlar" />
    <t:field field="branch_code" title="Filial">
        <t:filter type="text" />
    </t:field>
    <t:field field="phone" title="Telefon" />

    <t:grid pageSize="20" emptyText="Muddati o'tgan hujjat topilmadi">
        <t:col field="cif_number" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="customer_display_name" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="customer_status" badge="ACTIVE:ACTIVE:active,PENDING:PENDING:pending,BLOCKED:BLOCKED:blocked,CLOSED:CLOSED:closed" />
        <t:col field="doc_type" badge="true" />
        <t:col field="doc_number" />
        <t:col field="issued_date" />
        <t:col field="expiry_date" />
        <t:col field="days_expired" align="right" />
        <t:col field="branch_code" />
        <t:col field="phone" />
    </t:grid>

</t:table>

<jsp:include page="cif-footer.jsp"/>

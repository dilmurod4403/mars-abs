<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="PEP mijozlar hisoboti"/>
    <jsp:param name="page" value="pep"/>
</jsp:include>

<div class="page-header">
    <h1>PEP mijozlar hisoboti</h1>
</div>

<t:table view="core_cif_pep_customers_ui_v" var="data" orderBy="created_at DESC">

    <t:field field="cif_number" title="CIF">
        <t:filter type="text" />
    </t:field>
    <t:field field="customer_type" title="Turi" />
    <t:field field="display_name" title="Mijoz nomi">
        <t:filter type="text" />
    </t:field>
    <t:field field="pinfl" title="PINFL" />
    <t:field field="inn" title="INN" />
    <t:field field="phone" title="Telefon" />
    <t:field field="risk_category" title="Risk">
        <t:filter type="select" options="HIGH,MEDIUM,LOW" />
    </t:field>
    <t:field field="status" title="Holat">
        <t:filter type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda,BLOCKED:Bloklangan,CLOSED:Yopilgan" />
    </t:field>
    <t:field field="branch_code" title="Filial" />
    <t:field field="created_by" title="Yaratgan" />
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy HH:mm" />

    <t:grid pageSize="20" emptyText="PEP mijoz topilmadi">
        <t:col field="cif_number" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="customer_type" badge="INDIVIDUAL:FYaSh:individual,CORPORATE:YuSh:corporate" />
        <t:col field="display_name" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="pinfl" />
        <t:col field="inn" />
        <t:col field="phone" />
        <t:col field="risk_category" badge="HIGH:HIGH:high,MEDIUM:MEDIUM:medium,LOW:LOW:low" />
        <t:col field="status" badge="ACTIVE:Faol:active,PENDING:Pending:pending,BLOCKED:Bloklangan:blocked,CLOSED:Yopilgan:closed" />
        <t:col field="branch_code" />
        <t:col field="created_by" />
        <t:col field="created_at" />
    </t:grid>

</t:table>

<jsp:include page="cif-footer.jsp"/>

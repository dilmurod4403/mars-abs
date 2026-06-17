<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Mijozlar (JSON grid)"/>
    <jsp:param name="page" value="customers-json"/>
</jsp:include>

<script src="${pageContext.request.contextPath}/js/abs-grid.js"></script>

<div class="page-header">
    <h1>Mijozlar ro'yxati <span style="font-size:0.6em; color:var(--gray-400);">(JSON grid)</span></h1>
    <a href="${pageContext.request.contextPath}/abs/cif/customer-list.jsp" class="btn">HTML rejim</a>
</div>

<t:table view="core_cif_customers_ui_v" var="data" orderBy="created_at DESC">

    <t:field field="cif_number" title="CIF">
        <t:filter type="text" />
    </t:field>
    <t:field field="customer_type" title="Turi">
        <t:filter type="select" options="INDIVIDUAL:Jismoniy,CORPORATE:Yuridik" />
    </t:field>
    <t:field field="display_name" title="Mijoz nomi">
        <t:filter type="text" />
    </t:field>
    <t:field field="phone" title="Telefon" />
    <t:field field="status" title="Holat">
        <t:filter type="select" options="ACTIVE:Faol,PENDING:Kutilmoqda,BLOCKED:Bloklangan,CLOSED:Yopilgan" />
    </t:field>
    <t:field field="risk_category" title="Risk" />
    <t:field field="branch_code" title="Filial" />
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" mode="json" id="customerGrid" emptyText="Mijoz topilmadi">
        <t:col field="cif_number" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="customer_type" badge="INDIVIDUAL:FYaSh:individual,CORPORATE:YuSh:corporate" />
        <t:col field="display_name" link="customer-detail.jsp?id={customer_id}" />
        <t:col field="phone" />
        <t:col field="status" badge="ACTIVE:Faol:active,PENDING:Pending:pending,BLOCKED:Bloklangan:blocked,CLOSED:Yopilgan:closed" />
        <t:col field="risk_category" badge="HIGH:HIGH:high,MEDIUM:MEDIUM:medium,LOW:LOW:low" />
        <t:col field="branch_code" />
        <t:col field="created_at" />
    </t:grid>

</t:table>

<jsp:include page="cif-footer.jsp"/>

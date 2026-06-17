<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>
<%--
  MARS ABS - ACC Harakatsiz hisoblar (RPT-005)
  View: core_acc_dormant_accounts_ui_v
--%>

<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Harakatsiz hisoblar"/>
    <jsp:param name="page" value="dormant"/>
</jsp:include>

<div class="page-header">
    <div>
        <h1>Harakatsiz hisoblar</h1>
        <div class="subtitle">RPT-005 — Uzoq vaqt harakatsiz qolgan hisoblar</div>
    </div>
</div>

<t:table view="core_acc_dormant_accounts_ui_v" var="data" orderBy="idle_days DESC">

    <t:field field="account_number" title="Hisob raqami">
        <t:filter type="text" />
    </t:field>
    <t:field field="display_name" title="Mijoz">
        <t:filter type="text" />
    </t:field>
    <t:field field="account_type" title="Turi">
        <t:filter type="select" options="CURRENT:Joriy,SAVINGS:Jamg'arma,DEPOSIT:Depozit,LOAN:Kredit,SPECIAL:Maxsus" />
    </t:field>
    <t:field field="currency" title="Valyuta">
        <t:filter type="select" options="UZS:UZS,USD:USD,EUR:EUR" />
    </t:field>
    <t:field field="status" title="Holat">
        <t:filter type="select" options="ACTIVE:Faol,FROZEN:Muzlatilgan,BLOCKED:Bloklangan" />
    </t:field>
    <t:field field="balance"   title="Qoldiq" />
    <t:field field="idle_days" title="Harakatsiz (kun)" />
    <t:field field="branch_code" title="Filial" />

    <t:grid pageSize="20" emptyText="Harakatsiz hisob topilmadi">
        <t:col field="account_number" link="account-detail.jsp?id={account_id}" />
        <t:col field="display_name"   link="account-detail.jsp?id={account_id}" />
        <t:col field="account_type"   badge="CURRENT:Joriy:individual,SAVINGS:Jamg'arma:active,DEPOSIT:Depozit:corporate,LOAN:Kredit:blocked,SPECIAL:Maxsus:pending" />
        <t:col field="currency"       />
        <t:col field="balance"        align="right" />
        <t:col field="status"         badge="ACTIVE:Faol:active,FROZEN:Muzlatilgan:blocked,BLOCKED:Bloklangan:blocked" />
        <t:col field="idle_days"      align="right" />
        <t:col field="branch_code"    />
    </t:grid>

</t:table>

<jsp:include page="acc-footer.jsp"/>

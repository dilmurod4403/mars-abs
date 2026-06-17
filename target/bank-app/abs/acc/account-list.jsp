<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Hisoblar ro'yxati"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Hisoblar ro'yxati</h1>
    <a href="${pageContext.request.contextPath}/abs/acc/account-create.jsp" class="btn btn-primary">+ Yangi hisob</a>
</div>

<t:table view="core_acc_accounts_ui_v" var="data" orderBy="opened_at DESC">

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
        <t:filter type="select" options="PENDING:Kutilmoqda,ACTIVE:Faol,FROZEN:Muzlatilgan,BLOCKED:Bloklangan,CLOSED:Yopiq,REJECTED:Rad etilgan" />
    </t:field>
    <t:field field="branch_code" title="Filial">
        <t:filter type="text" />
    </t:field>
    <t:field field="balance" title="Qoldiq" />
    <t:field field="opened_at" title="Ochilgan sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Hisob topilmadi"
            selectable="true" rowId="account_id"
            saveUrl="${pageContext.request.contextPath}/abs/acc/account-bulk-save.jsp"
            bulkStatus="FROZEN:Muzlatish,BLOCKED:Bloklash,ACTIVE:Faollashtirish">
        <t:col field="account_number" link="account-detail.jsp?id={account_id}" />
        <t:col field="display_name" link="account-detail.jsp?id={account_id}" />
        <t:col field="account_type" badge="CURRENT:Joriy:individual,SAVINGS:Jamg'arma:active,DEPOSIT:Depozit:corporate,LOAN:Kredit:blocked,SPECIAL:Maxsus:pending" />
        <t:col field="currency" />
        <t:col field="balance" align="right" />
        <t:col field="status" badge="PENDING:Kutilmoqda:pending,ACTIVE:Faol:active,FROZEN:Muzlatilgan:blocked,BLOCKED:Bloklangan:blocked,CLOSED:Yopiq:closed,REJECTED:Rad:closed" />
        <t:col field="branch_code" />
        <t:col field="opened_at" />
    </t:grid>

</t:table>

<jsp:include page="acc-footer.jsp"/>

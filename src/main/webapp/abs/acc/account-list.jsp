<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="../cif/cif-header.jsp">
    <jsp:param name="title" value="Hisoblar ro'yxati"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Hisoblar ro'yxati</h1>
    <a href="${pageContext.request.contextPath}/abs/acc/account-create.jsp" class="btn btn-primary">+ Yangi hisob</a>
</div>

<t:table view="core_acc_accounts_ui_v" var="data" orderBy="created_at DESC">

    <t:field field="account_number" title="Hisob raqami">
        <t:filter type="text" />
    </t:field>
    <t:field field="client_name" title="Klient">
        <t:filter type="text" />
    </t:field>
    <t:field field="balance_account_name" title="Balans hisobi" />
    <t:field field="currency_char" title="Valyuta" />
    <t:field field="mo_status" title="M/O">
        <t:filter type="select" options="M:Birlamchi,O:Ikkilamchi" />
    </t:field>
    <t:field field="state" title="Holat">
        <t:filter type="select" options="CREATED:Yaratilgan,APPROVED:Tasdiqlangan,BLOCKED:Bloklangan,TEMP_CLOSED:Vaqtincha yopilgan,CLOSED:Yopilgan" />
    </t:field>
    <t:field field="currency_code" title="Valyuta kodi">
        <t:filter type="select" options="000:So'm (UZS),840:USD,978:EUR" />
    </t:field>
    <t:field field="saldo_som" title="Saldo (so'm)" />
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Hisob topilmadi" modal="true" modalSize="lg"
            selectable="true" rowId="account_id"
            saveUrl="${pageContext.request.contextPath}/abs/acc/account-bulk-save.jsp"
            bulkStatus="APPROVED:Tasdiqlash">
        <t:col field="account_number" link="account-detail.jsp?id={account_id}" width="200px" />
        <t:col field="client_name" />
        <t:col field="balance_account_name" />
        <t:col field="currency_char" align="center" width="80px" />
        <t:col field="mo_status"
               badge="M:Birlamchi:active,O:Ikkilamchi:secondary" />
        <t:col field="state"
               badge="CREATED:Yaratilgan:pending,APPROVED:Tasdiqlangan:active,BLOCKED:Bloklangan:blocked,TEMP_CLOSED:Vaqt. yopiq:blocked,CLOSED:Yopilgan:closed,DELETED:O'chirilgan:blocked" />
        <t:col field="saldo_som" align="right" width="140px" />
        <t:col field="created_at" width="110px" />
    </t:grid>

</t:table>

<jsp:include page="../cif/cif-footer.jsp"/>

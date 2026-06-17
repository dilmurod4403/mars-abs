<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>
<%--
  MARS ABS - ACC Valyuta statistikasi (RPT-003)
  View: core_acc_currency_stats_v
--%>

<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Valyuta statistikasi"/>
    <jsp:param name="page" value="currency-stats"/>
</jsp:include>

<div class="page-header">
    <div>
        <h1>Valyuta statistikasi</h1>
        <div class="subtitle">RPT-003 — Hisoblar valyuta bo'yicha tahlili</div>
    </div>
</div>

<t:table view="core_acc_currency_stats_v" var="data" orderBy="account_count DESC">

    <t:field field="currency"      title="Valyuta" />
    <t:field field="account_count" title="Hisoblar soni" />
    <t:field field="active_count"  title="Faol hisoblar" />
    <t:field field="total_balance" title="Jami qoldiq" />
    <t:field field="avg_balance"   title="O'rtacha qoldiq" />

    <t:grid pageSize="20" emptyText="Ma'lumot topilmadi">
        <t:col field="currency"      />
        <t:col field="account_count" align="right" />
        <t:col field="active_count"  align="right" />
        <t:col field="total_balance" align="right" />
        <t:col field="avg_balance"   align="right" />
    </t:grid>

</t:table>

<jsp:include page="acc-footer.jsp"/>

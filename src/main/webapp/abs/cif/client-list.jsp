<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Klientlar ro'yxati"/>
    <jsp:param name="page" value="clients"/>
</jsp:include>

<div class="page-header">
    <h1>Klientlar ro'yxati</h1>
    <a href="${pageContext.request.contextPath}/abs/cif/client-create.jsp" class="btn btn-primary">+ Yangi klient</a>
</div>

<t:table view="core_cif_clients_ui_v" var="data" orderBy="created_at DESC">

    <t:field field="client_code" title="Klient kodi">
        <t:filter type="text" />
    </t:field>
    <t:field field="full_name" title="To'liq nomi">
        <t:filter type="text" />
    </t:field>
    <t:field field="client_kind" title="Turi">
        <t:filter type="select" options="P:Jismoniy,J:Yuridik,I:YaTT-IP" />
    </t:field>
    <t:field field="client_type_name" title="Klient kategoriyasi">
        <t:filter type="text" />
    </t:field>
    <t:field field="client_status" title="Holat">
        <t:filter type="select" options="CREATED:Yaratilgan,APPROVED:Tasdiqlangan,BLOCKED:Bloklangan,CLOSED:Yopilgan" />
    </t:field>
    <t:field field="nibbd_registered" title="НИББД" />
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Klient topilmadi" modal="true" modalSize="lg"
            selectable="true" rowId="client_id"
            saveUrl="${pageContext.request.contextPath}/abs/cif/client-bulk-save.jsp"
            bulkStatus="APPROVED:Tasdiqlash">
        <t:col field="client_code" link="client-detail.jsp?id={client_id}" width="140px" />
        <t:col field="full_name"   link="client-detail.jsp?id={client_id}" />
        <t:col field="client_kind"
               badge="P:Jismoniy:individual,J:Yuridik:corporate,I:YaTT-IP:corporate" />
        <t:col field="client_type_name" />
        <t:col field="client_status"
               badge="CREATED:Yaratilgan:pending,APPROVED:Tasdiqlangan:active,BLOCKED:Bloklangan:blocked,CLOSED:Yopilgan:blocked,DELETED:O'chirilgan:blocked" />
        <t:col field="nibbd_registered" align="center" width="90px" />
        <t:col field="created_at" width="110px" />
    </t:grid>

</t:table>

<jsp:include page="cif-footer.jsp"/>

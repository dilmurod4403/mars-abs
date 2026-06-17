<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>

<jsp:include page="admin-header.jsp">
    <jsp:param name="title" value="Foydalanuvchilar"/>
    <jsp:param name="page" value="users"/>
</jsp:include>

<div class="page-header">
    <h1>Foydalanuvchilar</h1>
    <a href="${pageContext.request.contextPath}/abs/admin/user-create.jsp" class="btn btn-primary"
       data-modal data-modal-title="Yangi foydalanuvchi" data-modal-size="md">+ Yangi foydalanuvchi</a>
</div>

<t:table view="core_users_ui_v" var="data" orderBy="created_at DESC">

    <t:field field="username" title="Username">
        <t:filter type="text" />
    </t:field>
    <t:field field="full_name" title="To'liq ism">
        <t:filter type="text" />
    </t:field>
    <t:field field="email" title="Email" />
    <t:field field="role" title="Rol">
        <t:filter type="select" options="ADMIN,SUPERVISOR,OPERATOR" />
    </t:field>
    <t:field field="branch_code" title="Filial" />
    <t:field field="status" title="Holat">
        <t:filter type="select" options="ACTIVE,BLOCKED" />
    </t:field>
    <t:field field="last_login_at" title="Oxirgi kirish" format="dd.MM.yyyy HH:mm" />
    <t:field field="created_at" title="Sana" format="dd.MM.yyyy" />

    <t:grid pageSize="20" emptyText="Foydalanuvchi topilmadi" modal="true" modalSize="md">
        <t:col field="username" link="user-edit.jsp?id={user_id}" />
        <t:col field="full_name" />
        <t:col field="email" />
        <t:col field="role" badge="ADMIN:ADMIN:high,SUPERVISOR:SUPERVISOR:pending,OPERATOR:OPERATOR:active" />
        <t:col field="branch_code" />
        <t:col field="status" badge="ACTIVE:ACTIVE:active,BLOCKED:BLOCKED:blocked" />
        <t:col field="last_login_at" />
        <t:col field="created_at" />
    </t:grid>

</t:table>

<jsp:include page="admin-footer.jsp"/>

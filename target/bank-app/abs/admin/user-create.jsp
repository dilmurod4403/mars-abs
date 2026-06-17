<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Types, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - Admin: Yangi foydalanuvchi yaratish
  Procedure: core_auth_service.Create_User
--%>
<%
    // ---- POST: Foydalanuvchi yaratish ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username        = request.getParameter("username");
        String password        = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");
        String fullName        = request.getParameter("full_name");
        String email           = request.getParameter("email");
        String role            = request.getParameter("role");
        String branchCode      = request.getParameter("branch_code");

        // Parol tekshiruvi
        if (password == null || password.length() < 6) {
            request.setAttribute("errorMsg", "Parol kamida 6 ta belgidan iborat bo'lishi kerak");
        } else if (!password.equals(confirmPassword)) {
            request.setAttribute("errorMsg", "Parollar mos kelmadi");
        } else {
            String createdBy = (String) session.getAttribute("currentUsername");
            if (createdBy == null || createdBy.isEmpty()) createdBy = "ADMIN";

            try {
                java.util.Map<String,Object> result = Mars.procedure("core_auth_service.Create_User")
                    .in("username", username)
                    .in("password", password)
                    .in("full_name", fullName)
                    .in("email", email)
                    .in("role", role)
                    .in("branch_code", branchCode)
                    .in("created_by", createdBy)
                    .outNumber("user_id")
                    .outNumber("code")
                    .outString("message")
                    .execute();

                int code = ((Number) result.get("code")).intValue();
                String message = (String) result.get("message");

                if (code == 0) {
                    response.sendRedirect("user-list.jsp?msg=" +
                        java.net.URLEncoder.encode("Foydalanuvchi yaratildi", "UTF-8"));
                    return;
                } else {
                    request.setAttribute("errorMsg", message);
                }
            } catch (Exception e) {
                request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
            }
        }
    }
%>
<jsp:include page="admin-header.jsp">
    <jsp:param name="title" value="Yangi foydalanuvchi"/>
    <jsp:param name="page" value="users"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi foydalanuvchi yaratish</h1>
    <a href="${pageContext.request.contextPath}/abs/admin/user-list.jsp" class="btn">Ortga</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><%= request.getAttribute("errorMsg") %></div>
<% } %>

<form method="post" data-validate>
    <div class="form-section">
        <div class="form-section-title">Kirish ma'lumotlari</div>
        <div class="form-row">
            <div class="form-group">
                <label for="username">Username *</label>
                <input type="text" id="username" name="username" class="form-control" required
                       value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
            </div>
            <div></div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="password">Parol * (kamida 6 belgi)</label>
                <input type="password" id="password" name="password" class="form-control" required minlength="6">
            </div>
            <div class="form-group">
                <label for="confirm_password">Parolni tasdiqlang *</label>
                <input type="password" id="confirm_password" name="confirm_password" class="form-control" required minlength="6">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Shaxsiy ma'lumotlar</div>
        <div class="form-row">
            <div class="form-group">
                <label for="full_name">To'liq ism *</label>
                <input type="text" id="full_name" name="full_name" class="form-control" required
                       value="<%= request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" class="form-control"
                       value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Ruxsatlar</div>
        <div class="form-row">
            <div class="form-group">
                <label for="role">Rol *</label>
                <select id="role" name="role" class="form-control" required>
                    <option value="OPERATOR" <%= "OPERATOR".equals(request.getParameter("role")) || request.getParameter("role") == null ? "selected" : "" %>>OPERATOR</option>
                    <option value="SUPERVISOR" <%= "SUPERVISOR".equals(request.getParameter("role")) ? "selected" : "" %>>SUPERVISOR</option>
                    <option value="ADMIN" <%= "ADMIN".equals(request.getParameter("role")) ? "selected" : "" %>>ADMIN</option>
                </select>
            </div>
            <div class="form-group">
                <label for="branch_code">Filial kodi</label>
                <input type="text" id="branch_code" name="branch_code" class="form-control"
                       value="<%= request.getParameter("branch_code") != null ? request.getParameter("branch_code") : "" %>">
            </div>
        </div>
    </div>

    <div style="margin-top: 1rem;">
        <button type="submit" class="btn btn-primary">Yaratish</button>
        <a href="${pageContext.request.contextPath}/abs/admin/user-list.jsp" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
    </div>
</form>

<jsp:include page="admin-footer.jsp"/>

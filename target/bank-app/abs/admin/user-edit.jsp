<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - Admin: Foydalanuvchini tahrirlash
  Procedures: core_auth_service.Update_User, core_auth_service.Reset_Password
  View: core_users_ui_v
--%>
<%
    String userIdStr = request.getParameter("id");
    if (userIdStr == null || userIdStr.isEmpty()) {
        response.sendRedirect("user-list.jsp?err=" +
            java.net.URLEncoder.encode("Foydalanuvchi ID ko'rsatilmagan", "UTF-8"));
        return;
    }
    long userId = 0;
    try { userId = Long.parseLong(userIdStr); } catch (Exception e) {
        response.sendRedirect("user-list.jsp?err=" +
            java.net.URLEncoder.encode("Noto'g'ri ID", "UTF-8"));
        return;
    }

    // ---- POST: Yangilash yoki Parol o'zgartirish ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if ("UPDATE".equals(action)) {
            String fullName   = request.getParameter("full_name");
            String email      = request.getParameter("email");
            String role       = request.getParameter("role");
            String branchCode = request.getParameter("branch_code");
            String status     = request.getParameter("status");
            String updatedBy  = (String) session.getAttribute("currentUsername");
            if (updatedBy == null || updatedBy.isEmpty()) updatedBy = "ADMIN";

            try {
                java.util.Map<String,Object> result = Mars.procedure("core_auth_service.Update_User")
                    .in("user_id", userId)
                    .in("full_name", fullName)
                    .in("email", email)
                    .in("role", role)
                    .in("branch_code", branchCode)
                    .in("status", status)
                    .in("updated_by", updatedBy)
                    .outNumber("code")
                    .outString("message")
                    .execute();

                int code = ((Number) result.get("code")).intValue();
                String message = (String) result.get("message");

                if (code == 0) {
                    response.sendRedirect("user-list.jsp?msg=" +
                        java.net.URLEncoder.encode("Foydalanuvchi yangilandi", "UTF-8"));
                    return;
                } else {
                    request.setAttribute("errorMsg", message);
                }
            } catch (Exception e) {
                request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
            }

        } else if ("RESET_PASSWORD".equals(action)) {
            String newPassword = request.getParameter("new_password");
            if (newPassword == null || newPassword.length() < 6) {
                request.setAttribute("errorMsg", "Yangi parol kamida 6 ta belgidan iborat bo'lishi kerak");
            } else {
                String updatedBy = (String) session.getAttribute("currentUsername");
                if (updatedBy == null || updatedBy.isEmpty()) updatedBy = "ADMIN";

                try {
                    java.util.Map<String,Object> result = Mars.procedure("core_auth_service.Reset_Password")
                        .in("user_id", userId)
                        .in("new_password", newPassword)
                        .in("updated_by", updatedBy)
                        .outNumber("code")
                        .outString("message")
                        .execute();

                    int code = ((Number) result.get("code")).intValue();
                    String message = (String) result.get("message");

                    if (code == 0) {
                        response.sendRedirect("user-edit.jsp?id=" + userId + "&msg=" +
                            java.net.URLEncoder.encode("Parol muvaffaqiyatli o'zgartirildi", "UTF-8"));
                        return;
                    } else {
                        request.setAttribute("errorMsg", message);
                    }
                } catch (Exception e) {
                    request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
                }
            }
        }
    }

    // ---- GET: Foydalanuvchi ma'lumotlarini yuklash ----
    java.util.Map<String, Object> user = null;
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();
        String sql = "SELECT user_id, username, full_name, email, role, branch_code, " +
                     "       status, last_login_at, login_attempts, created_by, created_at " +
                     "  FROM core_users_ui_v WHERE user_id = ?";
        ps = conn.prepareStatement(sql);
        ps.setLong(1, userId);
        rs = ps.executeQuery();

        if (rs.next()) {
            user = new java.util.LinkedHashMap<>();
            user.put("user_id",        rs.getLong("user_id"));
            user.put("username",       rs.getString("username"));
            user.put("full_name",      rs.getString("full_name"));
            user.put("email",          rs.getString("email"));
            user.put("role",           rs.getString("role"));
            user.put("branch_code",    rs.getString("branch_code"));
            user.put("status",         rs.getString("status"));

            Timestamp tsLogin = rs.getTimestamp("last_login_at");
            user.put("last_login_at", tsLogin != null ? new java.util.Date(tsLogin.getTime()) : null);

            user.put("login_attempts", rs.getInt("login_attempts"));
            user.put("created_by",     rs.getString("created_by"));

            Timestamp tsCreated = rs.getTimestamp("created_at");
            user.put("created_at", tsCreated != null ? new java.util.Date(tsCreated.getTime()) : null);
        }
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (ps != null) try { ps.close(); } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    if (user == null) {
        response.sendRedirect("user-list.jsp?err=" +
            java.net.URLEncoder.encode("Foydalanuvchi topilmadi", "UTF-8"));
        return;
    }

    request.setAttribute("u", user);
%>
<jsp:include page="admin-header.jsp">
    <jsp:param name="title" value="Foydalanuvchini tahrirlash"/>
    <jsp:param name="page" value="users"/>
</jsp:include>

<div class="page-header">
    <h1>Foydalanuvchini tahrirlash</h1>
    <a href="${pageContext.request.contextPath}/abs/admin/user-list.jsp" class="btn">Ortga</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><%= request.getAttribute("errorMsg") %></div>
<% } %>

<!-- ---- Asosiy ma'lumotlarni tahrirlash ---- -->
<form method="post" data-validate>
    <input type="hidden" name="action" value="UPDATE">

    <div class="form-section">
        <div class="form-section-title">Foydalanuvchi ma'lumotlari</div>
        <div class="form-row">
            <div class="form-group">
                <label>Username</label>
                <input type="text" class="form-control" value="${u.username}" disabled readonly
                       style="background:var(--gray-100); color:var(--gray-500);">
            </div>
            <div class="form-group">
                <label>Yaratilgan</label>
                <input type="text" class="form-control" disabled readonly
                       style="background:var(--gray-100); color:var(--gray-500);"
                       value="<fmt:formatDate value='${u.created_at}' pattern='dd.MM.yyyy HH:mm'/> (${u.created_by})">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="full_name">To'liq ism *</label>
                <input type="text" id="full_name" name="full_name" class="form-control" required
                       value="${u.full_name}">
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" class="form-control"
                       value="${u.email}">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="role">Rol *</label>
                <select id="role" name="role" class="form-control" required>
                    <option value="OPERATOR" ${u.role == 'OPERATOR' ? 'selected' : ''}>OPERATOR</option>
                    <option value="SUPERVISOR" ${u.role == 'SUPERVISOR' ? 'selected' : ''}>SUPERVISOR</option>
                    <option value="ADMIN" ${u.role == 'ADMIN' ? 'selected' : ''}>ADMIN</option>
                </select>
            </div>
            <div class="form-group">
                <label for="branch_code">Filial kodi</label>
                <input type="text" id="branch_code" name="branch_code" class="form-control"
                       value="${u.branch_code}">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="status">Holat *</label>
                <select id="status" name="status" class="form-control" required>
                    <option value="ACTIVE" ${u.status == 'ACTIVE' ? 'selected' : ''}>ACTIVE</option>
                    <option value="BLOCKED" ${u.status == 'BLOCKED' ? 'selected' : ''}>BLOCKED</option>
                </select>
            </div>
            <div class="form-group">
                <label>Oxirgi kirish</label>
                <input type="text" class="form-control" disabled readonly
                       style="background:var(--gray-100); color:var(--gray-500);"
                       value="<c:choose><c:when test='${u.last_login_at != null}'><fmt:formatDate value='${u.last_login_at}' pattern='dd.MM.yyyy HH:mm'/></c:when><c:otherwise>Hech qachon</c:otherwise></c:choose> | Urinishlar: ${u.login_attempts}">
            </div>
        </div>
    </div>

    <div style="margin-top: 1rem;">
        <button type="submit" class="btn btn-primary">Saqlash</button>
        <a href="${pageContext.request.contextPath}/abs/admin/user-list.jsp" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
    </div>
</form>

<!-- ---- Parolni qayta o'rnatish ---- -->
<div style="margin-top: 2rem;">
    <form method="post">
        <input type="hidden" name="action" value="RESET_PASSWORD">
        <div class="form-section">
            <div class="form-section-title">Parolni qayta o'rnatish</div>
            <div class="form-row">
                <div class="form-group">
                    <label for="new_password">Yangi parol * (kamida 6 belgi)</label>
                    <input type="password" id="new_password" name="new_password" class="form-control" required minlength="6">
                </div>
                <div class="form-group" style="display:flex; align-items:end;">
                    <button type="submit" class="btn btn-warning">O'zgartirish</button>
                </div>
            </div>
        </div>
    </form>
</div>

<jsp:include page="admin-footer.jsp"/>

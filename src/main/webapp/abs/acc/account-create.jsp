<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, uz.fido.abs.core.db.AbsDb, java.util.Map, java.util.List, java.util.ArrayList, java.sql.*" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  MARS ABS — REAL SIRIUS: Yangi hisob ochish
  Procedure: core_acc_service.Open_Account
  Imzo: Open_Account(io_rec t_account_rec, o_account_id, o_account_number, o_code, o_message, o_ora_message)
--%>
<%!
    /** APPROVED klientlar ro'yxatini olish */
    private static List<long[]> getApprovedClients(javax.servlet.http.HttpServletRequest req) throws Exception {
        // long[0]=client_id, va map list'i yo'q — oddiy wrapper classiga o'tamiz
        return null; // haqiqiy logika quyida
    }
%>
<%
    // =====================================================================
    // APPROVED klientlar ro'yxati (SELECT element uchun)
    // =====================================================================
    List<Object[]> clients = new ArrayList<>();  // [client_id, client_code, full_name]
    String clientLoadError = null;
    try (Connection conn = AbsDb.getConnection()) {
        String sql = "SELECT client_id, client_code, full_name " +
                     "FROM core_cif_clients_ui_v " +
                     "WHERE client_status = 'APPROVED' " +
                     "ORDER BY full_name";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                clients.add(new Object[]{
                    rs.getLong("client_id"),
                    rs.getString("client_code"),
                    rs.getString("full_name")
                });
            }
        }
    } catch (Exception ex) {
        clientLoadError = ex.getMessage();
    }

    // =====================================================================
    // POST: Open_Account chaqiruv
    // =====================================================================
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String clientIdStr  = request.getParameter("client_id");
        String currency     = request.getParameter("currency_code");
        String name         = request.getParameter("name");
        String accType      = request.getParameter("acc_type");
        String branchCode   = request.getParameter("branch_code");
        if (branchCode == null || branchCode.isEmpty()) branchCode = "00014";
        if (accType   == null || accType.isEmpty())   accType   = "VKLAD";

        // maker_user — session dan, yo'q bo'lsa 101
        long makerUser = 101L;
        try {
            Object sessionUser = session.getAttribute("currentUser");
            if (sessionUser != null) {
                java.lang.reflect.Method m = sessionUser.getClass().getMethod("getId");
                makerUser = ((Number) m.invoke(sessionUser)).longValue();
            }
        } catch (Exception ignored) {}

        if (clientIdStr == null || clientIdStr.isEmpty()) {
            request.setAttribute("errorMsg", "Klient tanlanmadi");
        } else if (currency == null || currency.isEmpty()) {
            request.setAttribute("errorMsg", "Valyuta tanlanmadi");
        } else if (name == null || name.trim().isEmpty()) {
            request.setAttribute("errorMsg", "Hisob nomi kiritilmadi");
        } else {
            try {
                long clientId = Long.parseLong(clientIdStr.trim());

                Map<String, Object> res = Mars.procedure("core_acc_service.Open_Account")
                    .record("v_rec", "core_acc_types.t_account_rec")
                        .field("client_id",   clientId)
                        .field("currency_code", currency)
                        .field("name",          name.trim())
                        .field("acc_type",      accType)
                        .field("branch_code",   branchCode)
                        .field("maker_user",    makerUser)
                    .outNumber("o_account_id")
                    .outString("o_account_number")
                    .outNumber("o_code")
                    .outString("o_message")
                    .outString("o_ora_message")
                    .execute();

                long code    = ((Number) res.get("o_code")).longValue();
                String msg   = (String) res.get("o_message");
                String accNum = (String) res.get("o_account_number");

                if (code == 0) {
                    response.sendRedirect(request.getContextPath()
                        + "/abs/acc/account-list.jsp"
                        + "?msg=" + java.net.URLEncoder.encode(
                            "Hisob ochildi: " + (accNum != null ? accNum : ""), "UTF-8"));
                    return;
                } else {
                    String oraMsg = (String) res.get("o_ora_message");
                    request.setAttribute("errorMsg", msg != null ? msg : oraMsg);
                }
            } catch (NumberFormatException nfe) {
                request.setAttribute("errorMsg", "Noto'g'ri klient ID");
            } catch (Exception ex) {
                request.setAttribute("errorMsg", "Tizim xatosi: " + ex.getMessage());
            }
        }
        // POST xato — formni qayta ko'rsat (sticky values)
        request.setAttribute("sv_client_id",  request.getParameter("client_id"));
        request.setAttribute("sv_currency",   request.getParameter("currency_code"));
        request.setAttribute("sv_name",       request.getParameter("name"));
        request.setAttribute("sv_acc_type",   request.getParameter("acc_type"));
        request.setAttribute("sv_branch",     request.getParameter("branch_code"));
    }

    boolean __modal = "1".equals(request.getParameter("modal"));
%>

<%-- Modal-aware chrome --%>
<% if (!__modal) { %>
<jsp:include page="../cif/cif-header.jsp">
    <jsp:param name="title" value="Yangi hisob"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi hisob ochish</h1>
    <a href="${pageContext.request.contextPath}/abs/acc/account-list.jsp" class="btn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Orqaga
    </a>
</div>
<% } %>

<%-- DB yuklab xatosi --%>
<% if (clientLoadError != null) { %>
<div class="alert alert-danger">Klientlar ro'yxatini yuklab bo'lmadi: <%= clientLoadError %></div>
<% } %>

<%-- POST xatosi --%>
<c:if test="${not empty errorMsg}">
    <div class="alert alert-danger">${errorMsg}</div>
</c:if>

<%-- Tasdiqlangan klient yo'q --%>
<% if (clients.isEmpty() && clientLoadError == null) { %>
<div class="card" style="text-align:center; padding:3rem 1.5rem;">
    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--gray-300)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 1rem; display:block;"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><line x1="17" y1="11" x2="23" y2="11"/></svg>
    <p style="color:var(--gray-500); margin:0 0 1.5rem; font-size:0.9375rem;">Hisob ochish uchun avval klientni tasdiqlang.</p>
    <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="btn btn-primary">Klientlar ro'yxatiga o'tish</a>
</div>
<% if (!__modal) { %><jsp:include page="../cif/cif-footer.jsp"/><% } %>
<%
    return;
} %>

<%-- ================================================================
     FORMA
     ================================================================ --%>
<form method="post" action="" data-validate>
    <div class="form-section">
        <div class="form-section-title">Hisob ma'lumotlari</div>

        <div class="form-row">
            <div class="form-group">
                <label for="client_id">Klient *</label>
                <select id="client_id" name="client_id" class="form-control" required>
                    <option value="">— Klientni tanlang —</option>
                    <%
                        String svClientId = (String) request.getAttribute("sv_client_id");
                        for (Object[] row : clients) {
                            long   cid   = (Long)   row[0];
                            String ccode = (String) row[1];
                            String cname = (String) row[2];
                            boolean sel  = String.valueOf(cid).equals(svClientId);
                    %>
                    <option value="<%= cid %>"<%= sel ? " selected" : "" %>>
                        <%= ccode != null ? ccode : "" %> — <%= cname != null ? cname : "" %>
                    </option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="name">Hisob nomi *</label>
                <input type="text" id="name" name="name" class="form-control" required
                       placeholder="Masalan: Depozit hisob"
                       value="<c:out value='${sv_name}'/>">
            </div>
            <div class="form-group">
                <label for="acc_type">Hisob turi</label>
                <select id="acc_type" name="acc_type" class="form-control">
                    <option value="VKLAD"   ${sv_acc_type == 'VKLAD'   || empty sv_acc_type ? 'selected' : ''}>VKLAD — Depozit</option>
                    <option value="CURRENT" ${sv_acc_type == 'CURRENT' ? 'selected' : ''}>CURRENT — Joriy</option>
                    <option value="CARD"    ${sv_acc_type == 'CARD'    ? 'selected' : ''}>CARD — Karta</option>
                    <option value="LOAN"    ${sv_acc_type == 'LOAN'    ? 'selected' : ''}>LOAN — Kredit</option>
                </select>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="currency_code">Valyuta *</label>
                <select id="currency_code" name="currency_code" class="form-control" required>
                    <option value="">— Valyutani tanlang —</option>
                    <option value="000" ${sv_currency == '000' || empty sv_currency ? 'selected' : ''}>So'm (UZS) — 000</option>
                    <option value="840" ${sv_currency == '840' ? 'selected' : ''}>USD — 840</option>
                    <option value="978" ${sv_currency == '978' ? 'selected' : ''}>EUR — 978</option>
                </select>
            </div>
            <div class="form-group">
                <label for="branch_code">Filial kodi</label>
                <input type="text" id="branch_code" name="branch_code" class="form-control"
                       maxlength="10" placeholder="00014"
                       value="<c:out value='${not empty sv_branch ? sv_branch : \"00014\"}'/>">
                <small class="form-hint">Standart: 00014</small>
            </div>
        </div>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            Hisob ochish
        </button>
        <a href="${pageContext.request.contextPath}/abs/acc/account-list.jsp" class="btn">Bekor qilish</a>
    </div>
</form>

<% if (!__modal) { %>
<jsp:include page="../cif/cif-footer.jsp"/>
<% } %>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.AbsDb, java.sql.*, java.text.SimpleDateFormat, java.math.BigDecimal" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  account-detail.jsp — Hisob detali sahifasi
  Modal kontrakt: modal=1 → faqat fragment (cif-header/cif-footer yo'q)
  To'g'ridan-to'g'ri kirish → to'liq sahifa (cif-header page="accounts")
--%>
<%!
    private static String e(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
    private static String e(Object o) {
        return o == null ? "" : e(o.toString());
    }
    private static String fmtDate(java.sql.Date d) {
        if (d == null) return "";
        return new SimpleDateFormat("dd.MM.yyyy").format(d);
    }
    private static String fmtTs(java.sql.Timestamp ts) {
        if (ts == null) return "";
        return new SimpleDateFormat("dd.MM.yyyy HH:mm").format(ts);
    }
    private static String fmtAmount(BigDecimal bd) {
        if (bd == null) return "0,00";
        return String.format("%,.2f", bd).replace(",", " ").replace(".", ",");
    }
%>
<%
    boolean modal = "1".equals(request.getParameter("modal"));

    long accountId = -1L;
    String idParam = request.getParameter("id");
    if (idParam != null && !idParam.isEmpty()) {
        try { accountId = Long.parseLong(idParam.trim()); } catch (NumberFormatException ignored) {}
    }

    // =====================================================================
    // MA'LUMOTLARNI O'QISH — core_acc_accounts_ui_v
    // =====================================================================
    String accountNumber = null, balanceAccount = null, balanceAccountName = null;
    String currencyCode = null, currencyChar = null, currencyName = null;
    String clientId = null, clientCode = null, clientName = null, clientType = null;
    String accType = null, moStatus = null, moName = null;
    String state = null, stateName = null;
    String branchCode = null, branchName = null;
    String makerUser = null, checkerUser = null;
    BigDecimal saldoSom = null, saldoInSom = null;
    java.sql.Date openDate = null;
    java.sql.Timestamp createdAt = null, updatedAt = null;

    boolean found = false;
    String dbError = null;

    if (accountId > 0) {
        try (Connection conn = AbsDb.getConnection()) {
            String sql =
                "SELECT account_number, balance_account, balance_account_name, " +
                "       currency_code, currency_char, currency_name, " +
                "       client_id, client_code, client_name, client_type, " +
                "       acc_type, mo_status, mo_name, " +
                "       state, state_name, " +
                "       branch_code, branch_name, " +
                "       saldo_som, saldo_in_som, " +
                "       maker_user, checker_user, " +
                "       open_date, created_at, updated_at " +
                "FROM core_acc_accounts_ui_v WHERE account_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, accountId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        found              = true;
                        accountNumber      = rs.getString("account_number");
                        balanceAccount     = rs.getString("balance_account");
                        balanceAccountName = rs.getString("balance_account_name");
                        currencyCode       = rs.getString("currency_code");
                        currencyChar       = rs.getString("currency_char");
                        currencyName       = rs.getString("currency_name");
                        clientId           = rs.getString("client_id");
                        clientCode         = rs.getString("client_code");
                        clientName         = rs.getString("client_name");
                        clientType         = rs.getString("client_type");
                        accType            = rs.getString("acc_type");
                        moStatus           = rs.getString("mo_status");
                        moName             = rs.getString("mo_name");
                        state              = rs.getString("state");
                        stateName          = rs.getString("state_name");
                        branchCode         = rs.getString("branch_code");
                        branchName         = rs.getString("branch_name");
                        saldoSom           = rs.getBigDecimal("saldo_som");
                        saldoInSom         = rs.getBigDecimal("saldo_in_som");
                        makerUser          = rs.getString("maker_user");
                        checkerUser        = rs.getString("checker_user");
                        openDate           = rs.getDate("open_date");
                        createdAt          = rs.getTimestamp("created_at");
                        updatedAt          = rs.getTimestamp("updated_at");
                    }
                }
            }
        } catch (Exception ex) {
            dbError = ex.getMessage();
        }
    }

    // Holat badge CSS
    String stateCss = "badge";
    if      ("APPROVED".equals(state))    stateCss += " badge-active";
    else if ("BLOCKED".equals(state))     stateCss += " badge-blocked";
    else if ("CLOSED".equals(state))      stateCss += " badge-closed";
    else if ("DELETED".equals(state))     stateCss += " badge-blocked";
    else if ("TEMP_CLOSED".equals(state)) stateCss += " badge-blocked";
    else                                  stateCss += " badge-pending";

    // M/O badge CSS
    String moCss = "badge" + ("M".equals(moStatus) ? " badge-active" : " badge-secondary");
%>

<%-- Chrome — modal bo'lmasa --%>
<% if (!modal) { %>
<jsp:include page="../cif/cif-header.jsp">
    <jsp:param name="title" value="Hisob detali"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>
<% } %>

<%-- DB xatosi --%>
<% if (dbError != null) { %>
<div class="alert alert-danger">
    Ma'lumot yuklashda xatolik: <%= e(dbError) %>
</div>
<% } else if (accountId <= 0) { %>

<div class="page-header"><h1>Hisob topilmadi</h1></div>
<div class="card" style="text-align:center; padding:3rem 1.5rem;">
    <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="var(--gray-300)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 1rem; display:block;"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
    <p style="color:var(--gray-500); margin:0 0 1.5rem;">Hisob identifikatori ko'rsatilmagan.</p>
    <% if (!modal) { %>
    <a href="account-list.jsp" class="btn btn-secondary">Ro'yxatga qaytish</a>
    <% } %>
</div>

<% } else if (!found) { %>

<div class="page-header"><h1>Hisob topilmadi</h1></div>
<div class="card" style="text-align:center; padding:3rem 1.5rem;">
    <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="var(--gray-300)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 1rem; display:block;"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
    <p style="color:var(--gray-500); margin:0 0 1.5rem;">ID <strong><%= accountId %></strong> raqamli hisob topilmadi.</p>
    <% if (!modal) { %>
    <a href="account-list.jsp" class="btn btn-secondary">Ro'yxatga qaytish</a>
    <% } %>
</div>

<% } else { %>

<%-- Sarlavha — abs-modal.js h1 dan sarlavha oladi --%>
<div class="page-header">
    <div>
        <div style="display:flex; align-items:center; gap:0.75rem; flex-wrap:wrap;">
            <h1 style="margin:0; font-family:monospace; font-size:1.25rem; letter-spacing:0.02em;"><%= e(accountNumber) %></h1>
            <span class="<%= stateCss %>"><%= e(stateName) %></span>
            <span class="<%= moCss %>"><%= e(moName) %></span>
        </div>
        <% if (balanceAccountName != null) { %>
        <div class="subtitle" style="margin-top:0.25rem; font-size:0.82rem; color:var(--gray-500);">
            <%= e(balanceAccountName) %>
            <% if (currencyChar != null) { %>
            &nbsp;&middot;&nbsp; <span style="font-family:monospace; font-weight:600;"><%= e(currencyChar) %></span>
            <% } %>
        </div>
        <% } %>
    </div>
    <% if (!modal) { %>
    <a href="account-list.jsp" class="btn btn-secondary">Orqaga</a>
    <% } %>
</div>

<%-- BO'LIM 1: Hisob ma'lumotlari --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Hisob ma'lumotlari</div>
    <dl class="detail-grid-wide">
        <dt>Hisob raqami</dt>
        <dd><span style="font-family:monospace; font-weight:700; letter-spacing:0.04em; font-size:1rem;"><%= e(accountNumber) %></span></dd>

        <dt>Holat</dt>
        <dd><span class="<%= stateCss %>"><%= e(stateName) %></span></dd>

        <dt>M/O turi</dt>
        <dd><span class="<%= moCss %>"><%= e(moName) %></span></dd>

        <dt>Balans hisobi</dt>
        <dd>
            <span style="font-family:monospace;"><%= e(balanceAccount) %></span>
            <% if (balanceAccountName != null && !balanceAccountName.isEmpty()) { %>
            <span style="color:var(--gray-500); margin-left:0.5rem; font-size:0.875rem;">— <%= e(balanceAccountName) %></span>
            <% } %>
        </dd>

        <dt>Hisob turi</dt>
        <dd><%= e(accType) %></dd>

        <dt>Valyuta</dt>
        <dd>
            <span style="font-family:monospace; font-weight:600;"><%= e(currencyChar) %></span>
            <% if (currencyName != null && !currencyName.isEmpty()) { %>
            <span style="color:var(--gray-500); margin-left:0.5rem; font-size:0.875rem;">— <%= e(currencyName) %> (<%= e(currencyCode) %>)</span>
            <% } %>
        </dd>

        <dt>Filial</dt>
        <dd>
            <% if (branchName != null && !branchName.isEmpty()) { %>
            <%= e(branchName) %> <span style="color:var(--gray-500); font-size:0.875rem;">(<%= e(branchCode) %>)</span>
            <% } else { %>
            <span style="font-family:monospace;"><%= e(branchCode) %></span>
            <% } %>
        </dd>

        <% if (openDate != null) { %>
        <dt>Ochilgan sana</dt>
        <dd><%= fmtDate(openDate) %></dd>
        <% } %>

        <dt>Yaratilgan</dt>
        <dd><%= fmtTs(createdAt) %></dd>

        <% if (updatedAt != null) { %>
        <dt>Yangilangan</dt>
        <dd><%= fmtTs(updatedAt) %></dd>
        <% } %>
    </dl>
</div>

<%-- BO'LIM 2: Klient ma'lumotlari --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Klient</div>
    <dl class="detail-grid-wide">
        <dt>Klient nomi</dt>
        <dd>
            <% if (clientId != null && !clientId.isEmpty()) { %>
            <a href="${pageContext.request.contextPath}/abs/cif/client-detail.jsp?id=<%= e(clientId) %>"
               style="color:var(--primary); text-decoration:none; font-weight:500;">
                <%= e(clientName) %>
            </a>
            <% } else { %>
            <%= e(clientName) %>
            <% } %>
        </dd>

        <% if (clientCode != null && !clientCode.isEmpty()) { %>
        <dt>Klient kodi</dt>
        <dd><span style="font-family:monospace; font-weight:600;"><%= e(clientCode) %></span></dd>
        <% } %>

        <% if (clientId != null && !clientId.isEmpty()) { %>
        <dt>Klient ID</dt>
        <dd><span style="font-family:monospace; color:var(--gray-500);"><%= e(clientId) %></span></dd>
        <% } %>
    </dl>
</div>

<%-- BO'LIM 3: Saldo --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Balans</div>
    <dl class="detail-grid-wide">
        <dt>Saldo (chiquvchi, so'm)</dt>
        <dd>
            <span class="amount" style="font-size:1.25rem; font-weight:700; color:var(--gray-900);">
                <%= fmtAmount(saldoSom) %>
            </span>
            <span style="color:var(--gray-500); margin-left:0.25rem; font-size:0.875rem;">so'm</span>
        </dd>

        <% if (saldoInSom != null) { %>
        <dt>Saldo (kiruvchi, so'm)</dt>
        <dd>
            <span class="amount"><%= fmtAmount(saldoInSom) %></span>
            <span style="color:var(--gray-500); margin-left:0.25rem; font-size:0.875rem;">so'm</span>
        </dd>
        <% } %>
    </dl>
</div>

<%-- BO'LIM 4: Audit --%>
<% if (makerUser != null || checkerUser != null) { %>
<div class="card">
    <div class="section-title">Maker-Checker</div>
    <dl class="detail-grid-wide">
        <% if (makerUser != null && !makerUser.isEmpty()) { %>
        <dt>Yaratuvchi (Maker)</dt>
        <dd><%= e(makerUser) %></dd>
        <% } %>
        <% if (checkerUser != null && !checkerUser.isEmpty()) { %>
        <dt>Tasdiqlagan (Checker)</dt>
        <dd><%= e(checkerUser) %></dd>
        <% } %>
    </dl>
</div>
<% } %>

<% } /* end found */ %>

<% if (!modal) { %>
<jsp:include page="../cif/cif-footer.jsp"/>
<% } %>

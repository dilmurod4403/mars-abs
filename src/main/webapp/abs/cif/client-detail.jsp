<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.AbsDb, java.sql.*, java.text.SimpleDateFormat" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  client-detail.jsp — Klient detali sahifasi
  Modal kontrakt: modal=1 → faqat fragment (cif-header/cif-footer yo'q)
  To'g'ridan-to'g'ri kirish → to'liq sahifa
--%>
<%!
    /** XSS himoya — chiqish oldida escape qilish */
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
%>
<%
    boolean modal = "1".equals(request.getParameter("modal"));

    /* --- ID parametrini tekshirish --- */
    long clientId = -1L;
    String idParam = request.getParameter("id");
    if (idParam != null && !idParam.isEmpty()) {
        try { clientId = Long.parseLong(idParam.trim()); } catch (NumberFormatException ignored) {}
    }

    /* =====================================================================
       MA'LUMOTLARNI O'QISH
       ===================================================================== */
    /* -- Asosiy klient ma'lumotlari (core_cif_clients_ui_v) -- */
    String clientCode = null, clientKind = null, kindName = null, fullName = null;
    String clientTypeName = null, residentName = null, clientStatus = null, statusName = null;
    String nibbd_registered = null, nibbd_temp_code = null, regionCode = null;
    java.sql.Timestamp createdAt = null, updatedAt = null;

    /* -- Jismoniy shaxs (core_cif_individual) -- */
    String ind_last = null, ind_first = null, ind_middle = null;
    String ind_gender = null, ind_birth = null;
    String ind_docType = null, ind_docSeries = null, ind_docNumber = null;
    String ind_docIssue = null, ind_docExpiry = null;
    String ind_pinfl = null, ind_tin = null;

    /* -- Yuridik shaxs / YaTT (core_cif_legal) -- */
    String leg_inn = null, leg_name = null, leg_numRegistr = null;
    String leg_dateRegistr = null, leg_oked = null;
    /* ИП qo'shimcha */
    String ip_last = null, ip_first = null, ip_middle = null;
    String ip_pinfl = null, ip_docType = null, ip_docSerial = null, ip_docNumber = null;

    /* -- Hisoblar (core_acc_accounts_ui_v) -- */
    java.util.List<java.util.Map<String, String>> accounts = new java.util.ArrayList<>();

    boolean found = false;
    String dbError = null;

    if (clientId > 0) {
        try (Connection conn = AbsDb.getConnection()) {

            /* 1. Asosiy klient — core_cif_clients_ui_v */
            String sqlMain =
                "SELECT client_code, client_kind, kind_name, full_name, " +
                "       client_type_name, resident_name, client_status, status_name, " +
                "       nibbd_registered, nibbd_temp_code, region_code, created_at, updated_at " +
                "FROM core_cif_clients_ui_v WHERE client_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlMain)) {
                ps.setLong(1, clientId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        found        = true;
                        clientCode   = rs.getString("client_code");
                        clientKind   = rs.getString("client_kind");
                        kindName     = rs.getString("kind_name");
                        fullName     = rs.getString("full_name");
                        clientTypeName  = rs.getString("client_type_name");
                        residentName = rs.getString("resident_name");
                        clientStatus = rs.getString("client_status");
                        statusName   = rs.getString("status_name");
                        nibbd_registered = rs.getString("nibbd_registered");
                        nibbd_temp_code  = rs.getString("nibbd_temp_code");
                        regionCode   = rs.getString("region_code");
                        createdAt    = rs.getTimestamp("created_at");
                        updatedAt    = rs.getTimestamp("updated_at");
                    }
                }
            }

            if (found) {
                /* 2. Kengaytma — kind ga qarab */
                if ("P".equals(clientKind)) {
                    /* Jismoniy shaxs */
                    String sqlInd =
                        "SELECT last_name, first_name, middle_name, gender, birth_date, " +
                        "       doc_type, doc_series, doc_number, doc_issue_date, doc_expiry_date, " +
                        "       pinfl, tin " +
                        "FROM core_cif_individual WHERE client_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlInd)) {
                        ps.setLong(1, clientId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                ind_last    = rs.getString("last_name");
                                ind_first   = rs.getString("first_name");
                                ind_middle  = rs.getString("middle_name");
                                int g = rs.getInt("gender");
                                ind_gender  = (g == 1) ? "Erkak" : (g == 2) ? "Ayol" : "";
                                java.sql.Date bd = rs.getDate("birth_date");
                                ind_birth   = (bd != null) ? fmtDate(bd) : "";
                                ind_docType   = rs.getString("doc_type");
                                ind_docSeries = rs.getString("doc_series");
                                ind_docNumber = rs.getString("doc_number");
                                java.sql.Date di = rs.getDate("doc_issue_date");
                                java.sql.Date de = rs.getDate("doc_expiry_date");
                                ind_docIssue  = (di != null) ? fmtDate(di) : "";
                                ind_docExpiry = (de != null) ? fmtDate(de) : "";
                                ind_pinfl   = rs.getString("pinfl");
                                ind_tin     = rs.getString("tin");
                            }
                        }
                    }
                } else {
                    /* Yuridik shaxs (J) yoki YaTT (I) */
                    String sqlLeg =
                        "SELECT inn, name, num_registr, date_registr, oked, " +
                        "       last_name, first_name, middle_name, pinfl, " +
                        "       ip_doc_type, ip_doc_serial, ip_doc_number " +
                        "FROM core_cif_legal WHERE client_id = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlLeg)) {
                        ps.setLong(1, clientId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                leg_inn       = rs.getString("inn");
                                leg_name      = rs.getString("name");
                                leg_numRegistr = rs.getString("num_registr");
                                java.sql.Date dr = rs.getDate("date_registr");
                                leg_dateRegistr = (dr != null) ? fmtDate(dr) : "";
                                leg_oked      = rs.getString("oked");
                                /* ИП shaxsiy bloki */
                                ip_last       = rs.getString("last_name");
                                ip_first      = rs.getString("first_name");
                                ip_middle     = rs.getString("middle_name");
                                ip_pinfl      = rs.getString("pinfl");
                                ip_docType    = rs.getString("ip_doc_type");
                                ip_docSerial  = rs.getString("ip_doc_serial");
                                ip_docNumber  = rs.getString("ip_doc_number");
                            }
                        }
                    }
                }

                /* 3. Hisoblar — core_acc_accounts_ui_v */
                String sqlAcc =
                    "SELECT account_number, balance_account_name, currency_char, " +
                    "       mo_name, state_name, saldo_som " +
                    "FROM core_acc_accounts_ui_v WHERE client_id = ? ORDER BY account_id";
                try (PreparedStatement ps = conn.prepareStatement(sqlAcc)) {
                    ps.setLong(1, clientId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            java.util.Map<String, String> row = new java.util.LinkedHashMap<>();
                            row.put("account_number",      rs.getString("account_number"));
                            row.put("balance_account_name", rs.getString("balance_account_name"));
                            row.put("currency_char",       rs.getString("currency_char"));
                            row.put("mo_name",             rs.getString("mo_name"));
                            row.put("state_name",          rs.getString("state_name"));
                            java.math.BigDecimal saldo = rs.getBigDecimal("saldo_som");
                            row.put("saldo_som", saldo != null
                                ? String.format("%,.2f", saldo).replace(",", " ")
                                : "0,00");
                            accounts.add(row);
                        }
                    }
                }
            }

        } catch (Exception ex) {
            dbError = ex.getMessage();
        }
    }

    /* Status badge CSS klassi */
    String statusCss = "badge";
    if ("APPROVED".equals(clientStatus))     statusCss += " badge-active";
    else if ("BLOCKED".equals(clientStatus)) statusCss += " badge-blocked";
    else if ("CLOSED".equals(clientStatus))  statusCss += " badge-closed";
    else if ("DELETED".equals(clientStatus)) statusCss += " badge-rejected";
    else                                     statusCss += " badge-pending"; /* CREATED, TEMP_CLOSED, ... */
%>

<%-- ============================================================
     MODAL BO'LMASA: to'liq sahifa chrome
     ============================================================ --%>
<% if (!modal) { %>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Klient detali"/>
    <jsp:param name="page" value="clients"/>
</jsp:include>
<% } %>

<%-- ============================================================
     KONTENT — modal va to'liq sahifada bir xil
     ============================================================ --%>
<% if (dbError != null) { %>
<div class="alert alert-danger">
    Ma'lumot yuklashda xatolik: <%= e(dbError) %>
</div>
<% } else if (clientId <= 0) { %>

<%-- ID ko'rsatilmagan --%>
<div class="page-header">
    <h1>Klient topilmadi</h1>
</div>
<div class="card" style="text-align:center; padding: 3rem 1.5rem;">
    <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="var(--gray-300)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 1rem"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><line x1="17" y1="11" x2="23" y2="11"/></svg>
    <p style="color:var(--gray-500); margin:0 0 1.5rem;">Klient identifikatori ko'rsatilmagan.</p>
    <% if (!modal) { %>
    <a href="client-list.jsp" class="btn btn-secondary">Ro'yxatga qaytish</a>
    <% } %>
</div>

<% } else if (!found) { %>

<%-- Topilmadi --%>
<div class="page-header">
    <h1>Klient topilmadi</h1>
</div>
<div class="card" style="text-align:center; padding: 3rem 1.5rem;">
    <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="var(--gray-300)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 1rem"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
    <p style="color:var(--gray-500); margin:0 0 1.5rem;">ID <strong><%= clientId %></strong> raqamli klient topilmadi.</p>
    <% if (!modal) { %>
    <a href="client-list.jsp" class="btn btn-secondary">Ro'yxatga qaytish</a>
    <% } %>
</div>

<% } else { %>

<%-- ============================================================
     SARLAVHA: .page-header → abs-modal.js h1 dan modal sarlavha oladi
     ============================================================ --%>
<div class="page-header">
    <div>
        <div style="display:flex; align-items:center; gap:0.75rem; flex-wrap:wrap;">
            <h1 style="margin:0;"><%= e(fullName) %></h1>
            <span class="<%= statusCss %>"><%= e(statusName) %></span>
        </div>
        <% if (clientCode != null) { %>
        <div class="subtitle" style="margin-top:0.25rem; font-size:0.82rem; color:var(--gray-500); font-family:monospace;">
            <%= e(clientCode) %> &nbsp;&middot;&nbsp; <%= e(kindName) %>
        </div>
        <% } %>
    </div>
    <% if (!modal) { %>
    <div style="display:flex; gap:0.5rem;">
        <a href="client-list.jsp" class="btn btn-secondary">Orqaga</a>
    </div>
    <% } %>
</div>

<%-- ============================================================
     BO'LIM 1: ASOSIY MA'LUMOTLAR
     ============================================================ --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Asosiy ma'lumotlar</div>
    <dl class="detail-grid-wide">
        <dt>Klient kodi</dt>
        <dd><span style="font-family:monospace; font-weight:600;"><%= e(clientCode) %></span></dd>

        <dt>Tur (sub'ekt)</dt>
        <dd><%= e(kindName) %></dd>

        <dt>Klient kategoriyasi</dt>
        <dd><%= e(clientTypeName) %></dd>

        <dt>Holat</dt>
        <dd><span class="<%= statusCss %>"><%= e(statusName) %></span></dd>

        <dt>Rezidentlik</dt>
        <dd><%= e(residentName) %></dd>

        <dt>НИББД</dt>
        <dd>
            <% if ("Y".equals(nibbd_registered)) { %>
            <span class="badge badge-active">Ro'yxatga olingan</span>
            <% } else { %>
            <span class="badge badge-pending">Ro'yxatga olinmagan</span>
            <% } %>
            <% if (nibbd_temp_code != null && !nibbd_temp_code.isEmpty()) { %>
            <span style="margin-left:0.5rem; font-size:0.78rem; color:var(--gray-500); font-family:monospace;">Vaqtinchalik: <%= e(nibbd_temp_code) %></span>
            <% } %>
        </dd>

        <% if (regionCode != null && !regionCode.isEmpty()) { %>
        <dt>Viloyat kodi</dt>
        <dd><%= e(regionCode) %></dd>
        <% } %>

        <dt>Yaratilgan</dt>
        <dd><%= fmtTs(createdAt) %></dd>

        <% if (updatedAt != null) { %>
        <dt>Yangilangan</dt>
        <dd><%= fmtTs(updatedAt) %></dd>
        <% } %>
    </dl>
</div>

<%-- ============================================================
     BO'LIM 2: SHAXS / TASHKILOT MA'LUMOTLARI
     ============================================================ --%>
<% if ("P".equals(clientKind)) { %>
<%-- ----- Jismoniy shaxs ----- --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Shaxsiy ma'lumotlar</div>
    <dl class="detail-grid-wide">
        <dt>Familiya</dt>
        <dd><%= e(ind_last) %></dd>

        <dt>Ismi</dt>
        <dd><%= e(ind_first) %></dd>

        <% if (ind_middle != null && !ind_middle.isEmpty()) { %>
        <dt>Otasining ismi</dt>
        <dd><%= e(ind_middle) %></dd>
        <% } %>

        <dt>Jinsi</dt>
        <dd><%= e(ind_gender) %></dd>

        <dt>Tug'ilgan sana</dt>
        <dd><%= e(ind_birth) %></dd>

        <dt>Hujjat turi</dt>
        <dd><%= e(ind_docType) %></dd>

        <dt>Hujjat seriya / raqam</dt>
        <dd>
            <span style="font-family:monospace;"><%= e(ind_docSeries) %> <%= e(ind_docNumber) %></span>
        </dd>

        <% if (ind_docIssue != null && !ind_docIssue.isEmpty()) { %>
        <dt>Berilgan sana</dt>
        <dd><%= e(ind_docIssue) %></dd>
        <% } %>

        <% if (ind_docExpiry != null && !ind_docExpiry.isEmpty()) { %>
        <dt>Amal qilish muddati</dt>
        <dd><%= e(ind_docExpiry) %></dd>
        <% } %>

        <% if (ind_pinfl != null && !ind_pinfl.isEmpty()) { %>
        <dt>PINFL</dt>
        <dd><span style="font-family:monospace; letter-spacing:0.04em;"><%= e(ind_pinfl) %></span></dd>
        <% } %>

        <% if (ind_tin != null && !ind_tin.isEmpty()) { %>
        <dt>INN</dt>
        <dd><span style="font-family:monospace;"><%= e(ind_tin) %></span></dd>
        <% } %>
    </dl>
</div>

<% } else if ("J".equals(clientKind)) { %>
<%-- ----- Yuridik shaxs ----- --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">Tashkilot ma'lumotlari</div>
    <dl class="detail-grid-wide">
        <% if (leg_inn != null && !leg_inn.isEmpty()) { %>
        <dt>INN</dt>
        <dd><span style="font-family:monospace; font-weight:600;"><%= e(leg_inn) %></span></dd>
        <% } %>

        <dt>Tashkilot nomi</dt>
        <dd><%= e(leg_name) %></dd>

        <% if (leg_numRegistr != null && !leg_numRegistr.isEmpty()) { %>
        <dt>Ro'yxatga olish raqami</dt>
        <dd><span style="font-family:monospace;"><%= e(leg_numRegistr) %></span></dd>
        <% } %>

        <% if (leg_dateRegistr != null && !leg_dateRegistr.isEmpty()) { %>
        <dt>Ro'yxatga olish sanasi</dt>
        <dd><%= e(leg_dateRegistr) %></dd>
        <% } %>

        <% if (leg_oked != null && !leg_oked.isEmpty()) { %>
        <dt>OKED</dt>
        <dd><span style="font-family:monospace;"><%= e(leg_oked) %></span></dd>
        <% } %>
    </dl>
</div>

<% } else if ("I".equals(clientKind)) { %>
<%-- ----- YaTT (ИП) ----- --%>
<div class="card" style="margin-bottom:1rem;">
    <div class="section-title">YaTT (ИП) ma'lumotlari</div>
    <dl class="detail-grid-wide">
        <% if (leg_inn != null && !leg_inn.isEmpty()) { %>
        <dt>INN</dt>
        <dd><span style="font-family:monospace; font-weight:600;"><%= e(leg_inn) %></span></dd>
        <% } %>

        <% if (ip_last != null && !ip_last.isEmpty()) { %>
        <dt>Familiyasi</dt>
        <dd><%= e(ip_last) %></dd>
        <% } %>

        <% if (ip_first != null && !ip_first.isEmpty()) { %>
        <dt>Ismi</dt>
        <dd><%= e(ip_first) %></dd>
        <% } %>

        <% if (ip_middle != null && !ip_middle.isEmpty()) { %>
        <dt>Otasining ismi</dt>
        <dd><%= e(ip_middle) %></dd>
        <% } %>

        <% if (ip_pinfl != null && !ip_pinfl.isEmpty()) { %>
        <dt>PINFL</dt>
        <dd><span style="font-family:monospace; letter-spacing:0.04em;"><%= e(ip_pinfl) %></span></dd>
        <% } %>

        <% if (ip_docType != null && !ip_docType.isEmpty()) { %>
        <dt>Hujjat turi</dt>
        <dd><%= e(ip_docType) %></dd>
        <% } %>

        <% if (ip_docSerial != null || ip_docNumber != null) { %>
        <dt>Hujjat seriya / raqam</dt>
        <dd><span style="font-family:monospace;"><%= e(ip_docSerial) %> <%= e(ip_docNumber) %></span></dd>
        <% } %>

        <% if (leg_numRegistr != null && !leg_numRegistr.isEmpty()) { %>
        <dt>Ro'yxatga olish raqami</dt>
        <dd><span style="font-family:monospace;"><%= e(leg_numRegistr) %></span></dd>
        <% } %>

        <% if (leg_dateRegistr != null && !leg_dateRegistr.isEmpty()) { %>
        <dt>Ro'yxatga olish sanasi</dt>
        <dd><%= e(leg_dateRegistr) %></dd>
        <% } %>

        <% if (leg_oked != null && !leg_oked.isEmpty()) { %>
        <dt>OKED</dt>
        <dd><span style="font-family:monospace;"><%= e(leg_oked) %></span></dd>
        <% } %>
    </dl>
</div>
<% } %>

<%-- ============================================================
     BO'LIM 3: HISOBLAR
     ============================================================ --%>
<div class="card">
    <div class="section-title">Hisoblar</div>
    <% if (accounts.isEmpty()) { %>
    <div style="text-align:center; padding: 2rem 1rem; color:var(--gray-400);">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin:0 auto 0.75rem; display:block; opacity:0.4;"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
        <p style="margin:0; font-size:0.875rem;">Ushbu klient uchun hisob mavjud emas.</p>
    </div>
    <% } else { %>
    <div style="overflow-x:auto;">
        <table style="width:100%; border-collapse:collapse; font-size:0.875rem;">
            <thead>
                <tr style="border-bottom:2px solid var(--border);">
                    <th style="text-align:left; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em; white-space:nowrap;">Hisob raqami</th>
                    <th style="text-align:left; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em;">Balans hisobi</th>
                    <th style="text-align:center; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em; width:70px;">Valyuta</th>
                    <th style="text-align:center; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em; width:100px;">M/O</th>
                    <th style="text-align:center; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em; width:110px;">Holat</th>
                    <th style="text-align:right; padding:0.5rem 0.75rem; font-weight:600; color:var(--gray-500); font-size:0.78rem; text-transform:uppercase; letter-spacing:0.04em; white-space:nowrap;">Saldo (so'm)</th>
                </tr>
            </thead>
            <tbody>
                <%
                    for (java.util.Map<String, String> acc : accounts) {
                        String accState = acc.get("state_name");
                        String stateClass = "badge badge-pending";
                        String stateVal = acc.get("state_name");
                        if (stateVal != null) {
                            String sv = stateVal.toLowerCase();
                            if (sv.contains("утвержден") || sv.contains("tasdiqlangan"))
                                stateClass = "badge badge-active";
                            else if (sv.contains("закрыт") || sv.contains("yopilgan") || sv.contains("удален"))
                                stateClass = "badge badge-closed";
                            else if (sv.contains("блокирован"))
                                stateClass = "badge badge-blocked";
                        }
                %>
                <tr style="border-bottom:1px solid var(--border);">
                    <td style="padding:0.6rem 0.75rem; font-family:monospace; font-size:0.82rem; white-space:nowrap; font-weight:600; color:var(--gray-800);">
                        <%= e(acc.get("account_number")) %>
                    </td>
                    <td style="padding:0.6rem 0.75rem; color:var(--gray-700); max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
                        <%= e(acc.get("balance_account_name")) %>
                    </td>
                    <td style="padding:0.6rem 0.75rem; text-align:center;">
                        <span style="font-family:monospace; font-size:0.82rem; color:var(--gray-600); font-weight:600;">
                            <%= e(acc.get("currency_char")) %>
                        </span>
                    </td>
                    <td style="padding:0.6rem 0.75rem; text-align:center; font-size:0.78rem; color:var(--gray-600);">
                        <%= e(acc.get("mo_name")) %>
                    </td>
                    <td style="padding:0.6rem 0.75rem; text-align:center;">
                        <span class="<%= stateClass %>"><%= e(acc.get("state_name")) %></span>
                    </td>
                    <td style="padding:0.6rem 0.75rem; text-align:right;" class="amount">
                        <%= e(acc.get("saldo_som")) %>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<% } /* end found */ %>

<%-- ============================================================
     MODAL BO'LMASA: footer
     ============================================================ --%>
<% if (!modal) { %>
<jsp:include page="cif-footer.jsp"/>
<% } %>

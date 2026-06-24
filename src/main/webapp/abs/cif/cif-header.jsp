<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%-- HTML kesh AuthFilter da o'chiriladi (include ichida setHeader ishlamaydi) --%>
<%-- modal=1 bo'lsa: faqat kontent fragmenti (sidebar/topbar'siz) --%>
<% boolean __modal = "1".equals(request.getParameter("modal")); if (!__modal) {
   String __cp = request.getContextPath();
   long __v = 0L;
   try { __v = new java.io.File(application.getRealPath("/css/style.css")).lastModified(); } catch (Exception e) { __v = System.currentTimeMillis(); } %>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MARS ABS — ${param.title}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= __cp %>/css/style.css?v=<%= __v %>">
    <script src="<%= __cp %>/js/abs.js?v=<%= __v %>" defer></script>
    <script src="<%= __cp %>/js/abs-modal.js?v=<%= __v %>" defer></script>
    <script src="<%= __cp %>/js/abs-datagrid.js?v=<%= __v %>" defer></script>
</head>
<body>
<div class="app-layout">

    <%-- ==================== SIDEBAR ==================== --%>
    <aside class="sidebar" id="sidebar">
        <a href="${__cp}/abs/cif/dashboard.jsp" class="sidebar-brand" style="text-decoration:none;">
            <span class="logo-mark">M</span>
            <span>MARS <span class="brand-sub">ABS</span></span>
        </a>

        <nav class="sidebar-nav">
            <div class="nav-section">
                <div class="nav-section-title">Asosiy</div>
                <a class="nav-item ${param.page == 'dashboard' ? 'active' : ''}" href="${__cp}/abs/cif/dashboard.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>
                    Dashboard
                </a>
            </div>


            <div class="nav-section">
                <div class="nav-section-title">CIF — Klientlar</div>
                <a class="nav-item ${param.page == 'clients' ? 'active' : ''}" href="${__cp}/abs/cif/client-list.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/><path d="M21 21v-2a4 4 0 0 0-3-3.87"/></svg>
                    Klientlar
                </a>
                <a class="nav-item ${param.page == 'client-create' ? 'active' : ''}" href="${__cp}/abs/cif/client-create.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8.5" cy="7" r="4"/><path d="M2 21v-2a4 4 0 0 1 4-4h6"/><path d="M20 8v6"/><path d="M23 11h-6"/></svg>
                    Yangi klient
                </a>
                <a class="nav-item ${param.page == 'client-approve' ? 'active' : ''}" href="${__cp}/abs/cif/client-approve.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                    Tasdiqlash
                </a>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">ACC — Hisoblar</div>
                <a class="nav-item ${param.page == 'accounts' ? 'active' : ''}" href="${__cp}/abs/acc/account-list.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
                    Hisoblar
                </a>
                <a class="nav-item ${param.page == 'account-create' ? 'active' : ''}" href="${__cp}/abs/acc/account-create.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/><line x1="12" y1="14" x2="12" y2="18"/><line x1="10" y1="16" x2="14" y2="16"/></svg>
                    Yangi hisob
                </a>
            </div>

            <c:if test="${sessionScope.currentUser.role == 'ADMIN'}">
            <div class="nav-section">
                <div class="nav-section-title">Tizim</div>
                <a class="nav-item" href="${__cp}/abs/admin/user-list.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
                    Administratorlik
                </a>
            </div>
            </c:if>
        </nav>

        <div class="sidebar-footer">
            <div class="avatar">${fn:toUpperCase(fn:substring(sessionScope.currentUser.full_name, 0, 1))}</div>
            <div class="user-meta">
                <div class="user-name">${sessionScope.currentUser.full_name}</div>
                <div class="user-role">${sessionScope.currentUser.role}</div>
            </div>
            <a class="logout" href="${__cp}/abs/logout.jsp" title="Chiqish">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </a>
        </div>
    </aside>

    <%-- ==================== MAIN ==================== --%>
    <div class="app-main">
        <div class="sidebar-scrim" onclick="document.getElementById('sidebar').classList.remove('open');this.classList.remove('show')"></div>
        <header class="topbar">
            <button class="topbar-icon-btn sidebar-toggle" onclick="var s=document.getElementById('sidebar');s.classList.toggle('open');document.querySelector('.sidebar-scrim').classList.toggle('show', s.classList.contains('open'))" aria-label="Menyu">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
            </button>
            <div class="breadcrumb">
                <% boolean __isAcc = "accounts".equals(request.getParameter("page"))
                                  || "account-create".equals(request.getParameter("page")); %>
                <span><%= __isAcc ? "ACC" : "CIF" %></span>
                <span class="sep">›</span>
                <span class="crumb-current">${param.title}</span>
            </div>
            <div class="topbar-search">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                <input type="text" placeholder="Mijoz, CIF, telefon bo'yicha qidirish..." aria-label="Qidirish">
            </div>
            <div class="topbar-actions">
                <button class="topbar-icon-btn" aria-label="Bildirishnomalar">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                    <span class="dot"></span>
                </button>
            </div>
        </header>

        <main class="content">
<%-- Xabar ko'rsatish (success/error) — faqat to'liq sahifada --%>
<%
    String msg = request.getParameter("msg");
    String err = request.getParameter("err");
    if (msg != null && !msg.isEmpty()) {
%>
            <div class="alert alert-success"><%= msg %></div>
<%  }
    if (err != null && !err.isEmpty()) {
%>
            <div class="alert alert-danger"><%= err %></div>
<%  }
   } /* end if !__modal */ %>

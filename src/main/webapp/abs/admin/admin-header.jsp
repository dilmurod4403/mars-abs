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
                <div class="nav-section-title">Tizim</div>
                <a class="nav-item ${param.page == 'users' ? 'active' : ''}" href="${__cp}/abs/admin/user-list.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/><path d="M21 21v-2a4 4 0 0 0-3-3.87"/></svg>
                    Foydalanuvchilar
                </a>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Modullar</div>
                <a class="nav-item" href="${__cp}/abs/cif/dashboard.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>
                    CIF moduli
                </a>
            </div>
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
                <span>Admin</span>
                <span class="sep">›</span>
                <span class="crumb-current">${param.title}</span>
            </div>
            <div class="topbar-actions">
                <a class="topbar-icon-btn" href="${__cp}/abs/cif/dashboard.jsp" aria-label="CIF moduliga" title="CIF moduliga">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>
                </a>
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

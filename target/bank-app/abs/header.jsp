<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%
   String __cp = request.getContextPath();
   long __v = 0L;
   try { __v = new java.io.File(application.getRealPath("/css/style.css")).lastModified(); } catch (Exception e) { __v = System.currentTimeMillis(); }
%>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fido Bank — ${param.title}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= __cp %>/css/style.css?v=<%= __v %>">
    <script src="<%= __cp %>/js/abs.js?v=<%= __v %>" defer></script>
    <script src="<%= __cp %>/js/abs-datagrid.js?v=<%= __v %>" defer></script>
</head>
<body>
<div class="app-layout">

    <%-- ==================== SIDEBAR ==================== --%>
    <aside class="sidebar" id="sidebar">
        <a href="<%= __cp %>/" class="sidebar-brand" style="text-decoration:none;">
            <span class="logo-mark">F</span>
            <span>FIDO <span class="brand-sub">Bank</span></span>
        </a>

        <nav class="sidebar-nav">
            <div class="nav-section">
                <div class="nav-section-title">Asosiy</div>
                <a class="nav-item ${param.page == 'dashboard' ? 'active' : ''}" href="<%= __cp %>/">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9.5L12 3l9 6.5"/><path d="M5 10v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V10"/></svg>
                    Bosh sahifa
                </a>
                <a class="nav-item ${param.page == 'customers' ? 'active' : ''}" href="<%= __cp %>/customers">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                    Mijozlar
                </a>
                <a class="nav-item ${param.page == 'accounts' ? 'active' : ''}" href="<%= __cp %>/accounts">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
                    Hisoblar
                </a>
                <a class="nav-item ${param.page == 'transfer' ? 'active' : ''}" href="<%= __cp %>/transfer">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>
                    O'tkazma
                </a>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">MARS ABS</div>
                <a class="nav-item" href="<%= __cp %>/abs/cif/dashboard.jsp">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>
                    CIF moduli
                </a>
            </div>
        </nav>

        <div class="sidebar-footer">
            <div class="avatar">F</div>
            <div class="user-meta">
                <div class="user-name">Fido Bank</div>
                <div class="user-role">Demo modul</div>
            </div>
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
                <span>Bank</span>
                <span class="sep">›</span>
                <span class="crumb-current">${param.title}</span>
            </div>
            <div class="topbar-search">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                <input type="text" placeholder="Qidirish..." aria-label="Qidirish">
            </div>
            <div class="topbar-actions">
                <button class="topbar-icon-btn" aria-label="Bildirishnomalar">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                </button>
            </div>
        </header>

        <main class="content">

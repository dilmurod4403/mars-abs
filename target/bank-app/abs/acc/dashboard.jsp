<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - ACC Dashboard
  Statistika: core_acc_accounts_ui_v (COUNT holat bo'yicha)
  Valyuta: core_acc_currency_stats_v
--%>
<%
    int totalAccounts = 0, activeCount = 0, pendingCount = 0, frozenCount = 0;
    int blockedCount = 0, closedCount = 0, rejectedCount = 0;
    java.util.List<java.util.Map<String,Object>> currencyStats = new java.util.ArrayList<>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();

        // Holat bo'yicha statistika
        ps = conn.prepareStatement(
            "SELECT COUNT(*) AS total," +
            "       SUM(CASE WHEN status='ACTIVE'   THEN 1 ELSE 0 END) AS active_cnt," +
            "       SUM(CASE WHEN status='PENDING'  THEN 1 ELSE 0 END) AS pending_cnt," +
            "       SUM(CASE WHEN status='FROZEN'   THEN 1 ELSE 0 END) AS frozen_cnt," +
            "       SUM(CASE WHEN status='BLOCKED'  THEN 1 ELSE 0 END) AS blocked_cnt," +
            "       SUM(CASE WHEN status='CLOSED'   THEN 1 ELSE 0 END) AS closed_cnt," +
            "       SUM(CASE WHEN status='REJECTED' THEN 1 ELSE 0 END) AS rejected_cnt" +
            "  FROM core_acc_accounts_ui_v"
        );
        rs = ps.executeQuery();
        if (rs.next()) {
            totalAccounts = rs.getInt("total");
            activeCount   = rs.getInt("active_cnt");
            pendingCount  = rs.getInt("pending_cnt");
            frozenCount   = rs.getInt("frozen_cnt");
            blockedCount  = rs.getInt("blocked_cnt");
            closedCount   = rs.getInt("closed_cnt");
            rejectedCount = rs.getInt("rejected_cnt");
        }
        rs.close(); ps.close();

        // Valyuta statistikasi
        ps = conn.prepareStatement(
            "SELECT currency, account_count, total_balance, avg_balance, active_count" +
            "  FROM core_acc_currency_stats_v ORDER BY account_count DESC"
        );
        rs = ps.executeQuery();
        while (rs.next()) {
            java.util.Map<String,Object> row = new java.util.LinkedHashMap<>();
            row.put("currency",      rs.getString("currency"));
            row.put("account_count", rs.getInt("account_count"));
            row.put("total_balance", rs.getBigDecimal("total_balance"));
            row.put("avg_balance",   rs.getBigDecimal("avg_balance"));
            row.put("active_count",  rs.getInt("active_count"));
            currencyStats.add(row);
        }
        rs.close(); ps.close();

    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (ps != null) try { ps.close(); } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    int pctActive  = totalAccounts > 0 ? (int) Math.round(activeCount  * 100.0 / totalAccounts) : 0;
    int pctPending = totalAccounts > 0 ? (int) Math.round(pendingCount * 100.0 / totalAccounts) : 0;
    int pctFrozen  = totalAccounts > 0 ? (int) Math.round(frozenCount  * 100.0 / totalAccounts) : 0;
    int pctBlocked = totalAccounts > 0 ? (int) Math.round(blockedCount * 100.0 / totalAccounts) : 0;
    int pctClosed  = totalAccounts > 0 ? (int) Math.round(closedCount  * 100.0 / totalAccounts) : 0;

    request.setAttribute("currencyStats", currencyStats);
%>
<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Dashboard"/>
    <jsp:param name="page" value="dashboard"/>
</jsp:include>

<style>
.dash-metrics { display:grid; grid-template-columns:repeat(auto-fit,minmax(210px,1fr)); gap:1rem; margin-bottom:1.5rem; }
.dash-metric { background:var(--bg-surface); border:1px solid var(--border); border-radius:var(--radius); padding:1.25rem 1.35rem; box-shadow:var(--shadow-sm); display:flex; align-items:flex-start; gap:1rem; transition:box-shadow var(--t) var(--ease),transform var(--t) var(--ease),border-color var(--t) var(--ease); }
.dash-metric:hover { box-shadow:var(--shadow-md); transform:translateY(-2px); border-color:var(--border-strong); }
.dash-metric-icon { width:42px; height:42px; border-radius:10px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.dash-metric-icon svg { width:20px; height:20px; }
.dash-metric-icon.indigo { background:var(--primary-100); color:var(--primary); }
.dash-metric-icon.green  { background:#ecfdf5; color:#047857; }
.dash-metric-icon.amber  { background:#fffbeb; color:#b45309; }
.dash-metric-icon.blue   { background:#eff6ff; color:#1d4ed8; }
.dash-metric-body { min-width:0; flex:1; }
.dash-metric-label { font-size:.7rem; font-weight:600; text-transform:uppercase; letter-spacing:.06em; color:var(--gray-500); margin-bottom:.25rem; }
.dash-metric-value { font-size:2rem; font-weight:700; letter-spacing:-.04em; line-height:1; color:var(--gray-900); }
.dash-metric-sub { font-size:.72rem; color:var(--gray-400); margin-top:.3rem; font-weight:500; }

.dash-row { display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin-bottom:1.5rem; }
@media (max-width:900px) { .dash-row { grid-template-columns:1fr; } }

.status-list { display:flex; flex-direction:column; gap:.875rem; }
.status-row { display:flex; flex-direction:column; gap:.35rem; }
.status-row-header { display:flex; align-items:center; justify-content:space-between; gap:.5rem; }
.status-row-left { display:flex; align-items:center; gap:.5rem; }
.status-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }
.status-dot.active  { background:#059669; }
.status-dot.pending { background:#d97706; }
.status-dot.frozen  { background:#2563eb; }
.status-dot.blocked { background:#dc2626; }
.status-dot.closed  { background:#94a3b8; }
.status-name { font-size:.82rem; font-weight:500; color:var(--gray-700); }
.status-meta { display:flex; align-items:center; gap:.5rem; flex-shrink:0; }
.status-count { font-size:.82rem; font-weight:700; color:var(--gray-800); min-width:28px; text-align:right; }
.status-pct   { font-size:.72rem; color:var(--gray-400); font-weight:500; min-width:30px; text-align:right; }
.progress-track { height:6px; background:var(--gray-100); border-radius:99px; overflow:hidden; }
.progress-fill { height:100%; border-radius:99px; transition:width .6s cubic-bezier(.4,0,.2,1); }
.progress-fill.active  { background:#059669; }
.progress-fill.pending { background:#d97706; }
.progress-fill.frozen  { background:#2563eb; }
.progress-fill.blocked { background:#dc2626; }
.progress-fill.closed  { background:#94a3b8; }

.curr-table { width:100%; border-collapse:collapse; font-size:.84rem; }
.curr-table th { font-size:.7rem; font-weight:600; text-transform:uppercase; letter-spacing:.06em; color:var(--gray-500); padding:.5rem .75rem; border-bottom:1px solid var(--border); text-align:left; }
.curr-table td { padding:.65rem .75rem; border-bottom:1px solid var(--border); color:var(--gray-700); }
.curr-table tr:last-child td { border-bottom:none; }
.curr-table tr:hover td { background:var(--gray-50); }
.curr-badge { display:inline-flex; align-items:center; height:22px; padding:0 .5rem; border-radius:6px; font-size:.72rem; font-weight:700; letter-spacing:.03em; background:var(--primary-100); color:var(--primary); }

.quick-links { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:.875rem; }
.quick-link-card { display:flex; align-items:center; gap:.875rem; padding:1rem 1.125rem; background:var(--bg-surface); border:1px solid var(--border); border-radius:var(--radius); text-decoration:none; color:var(--gray-800); transition:box-shadow var(--t) var(--ease),transform var(--t) var(--ease),border-color var(--t) var(--ease); box-shadow:var(--shadow-xs); }
.quick-link-card:hover { box-shadow:var(--shadow-md); transform:translateY(-2px); border-color:var(--border-strong); background:#fff; }
.quick-link-icon { width:40px; height:40px; border-radius:9px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.quick-link-icon svg { width:19px; height:19px; }
.quick-link-icon.indigo { background:var(--primary-100); color:var(--primary); }
.quick-link-icon.amber  { background:#fffbeb; color:#b45309; }
.quick-link-icon.blue   { background:#eff6ff; color:#1d4ed8; }
.quick-link-icon.slate  { background:var(--gray-100); color:var(--gray-600); }
.quick-link-body { min-width:0; flex:1; }
.quick-link-title { font-size:.86rem; font-weight:600; color:var(--gray-800); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.quick-link-badge { display:inline-flex; align-items:center; height:18px; padding:0 .4rem; border-radius:99px; font-size:.68rem; font-weight:700; margin-top:.2rem; }
.quick-link-badge.amber { background:#fffbeb; color:#b45309; }
.quick-link-badge.blue  { background:#eff6ff; color:#1d4ed8; }
.quick-link-arrow { margin-left:auto; color:var(--gray-300); flex-shrink:0; transition:color var(--t-fast) var(--ease),transform var(--t) var(--ease); }
.quick-link-card:hover .quick-link-arrow { color:var(--gray-500); transform:translateX(3px); }
.quick-link-arrow svg { width:15px; height:15px; }
</style>

<div class="page-header">
    <div>
        <h1>Boshqaruv paneli</h1>
        <div class="subtitle">ACC — Hisoblar moduli</div>
    </div>
    <a href="${pageContext.request.contextPath}/abs/acc/account-create.jsp" class="btn btn-primary">
        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
        Yangi hisob
    </a>
</div>

<!-- Asosiy ko'rsatkichlar -->
<div class="dash-metrics">
    <div class="dash-metric">
        <div class="dash-metric-icon indigo">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Jami hisoblar</div>
            <div class="dash-metric-value"><%= totalAccounts %></div>
            <div class="dash-metric-sub">barcha holatlardagi</div>
        </div>
    </div>
    <div class="dash-metric">
        <div class="dash-metric-icon green">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Faol hisoblar</div>
            <div class="dash-metric-value"><%= activeCount %></div>
            <div class="dash-metric-sub">ACTIVE holat</div>
        </div>
    </div>
    <div class="dash-metric">
        <div class="dash-metric-icon amber">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Kutilmoqda</div>
            <div class="dash-metric-value"><%= pendingCount %></div>
            <div class="dash-metric-sub">tasdiqlanmagan</div>
        </div>
    </div>
    <div class="dash-metric">
        <div class="dash-metric-icon blue">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Muzlatilgan</div>
            <div class="dash-metric-value"><%= frozenCount %></div>
            <div class="dash-metric-sub">FROZEN holat</div>
        </div>
    </div>
</div>

<!-- Holat taqsimoti + Valyuta statistikasi -->
<div class="dash-row">
    <div class="card">
        <div class="card-title">Holatlar bo'yicha taqsimot</div>
        <div class="status-list">
            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left"><span class="status-dot active"></span><span class="status-name">Faol</span></div>
                    <div class="status-meta"><span class="status-count"><%= activeCount %></span><span class="status-pct"><%= pctActive %>%</span></div>
                </div>
                <div class="progress-track"><div class="progress-fill active" style="width:<%= pctActive %>%"></div></div>
            </div>
            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left"><span class="status-dot pending"></span><span class="status-name">Kutilmoqda</span></div>
                    <div class="status-meta"><span class="status-count"><%= pendingCount %></span><span class="status-pct"><%= pctPending %>%</span></div>
                </div>
                <div class="progress-track"><div class="progress-fill pending" style="width:<%= pctPending %>%"></div></div>
            </div>
            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left"><span class="status-dot frozen"></span><span class="status-name">Muzlatilgan</span></div>
                    <div class="status-meta"><span class="status-count"><%= frozenCount %></span><span class="status-pct"><%= pctFrozen %>%</span></div>
                </div>
                <div class="progress-track"><div class="progress-fill frozen" style="width:<%= pctFrozen %>%"></div></div>
            </div>
            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left"><span class="status-dot blocked"></span><span class="status-name">Bloklangan</span></div>
                    <div class="status-meta"><span class="status-count"><%= blockedCount %></span><span class="status-pct"><%= pctBlocked %>%</span></div>
                </div>
                <div class="progress-track"><div class="progress-fill blocked" style="width:<%= pctBlocked %>%"></div></div>
            </div>
            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left"><span class="status-dot closed"></span><span class="status-name">Yopilgan</span></div>
                    <div class="status-meta"><span class="status-count"><%= closedCount %></span><span class="status-pct"><%= pctClosed %>%</span></div>
                </div>
                <div class="progress-track"><div class="progress-fill closed" style="width:<%= pctClosed %>%"></div></div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-title">Valyuta bo'yicha statistika</div>
        <c:choose>
            <c:when test="${not empty currencyStats}">
                <table class="curr-table">
                    <thead>
                        <tr>
                            <th>Valyuta</th>
                            <th>Hisoblar</th>
                            <th>Faol</th>
                            <th style="text-align:right;">Jami qoldiq</th>
                            <th style="text-align:right;">O'rtacha</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="cs" items="${currencyStats}">
                            <tr>
                                <td><span class="curr-badge">${cs.currency}</span></td>
                                <td>${cs.account_count}</td>
                                <td>${cs.active_count}</td>
                                <td style="text-align:right; font-weight:600; font-variant-numeric:tabular-nums;">
                                    <fmt:formatNumber value="${cs.total_balance}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                                </td>
                                <td style="text-align:right; color:var(--gray-500); font-variant-numeric:tabular-nums;">
                                    <fmt:formatNumber value="${cs.avg_balance}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </c:when>
            <c:otherwise>
                <div class="empty-state"><div class="message">Ma'lumot topilmadi</div></div>
            </c:otherwise>
        </c:choose>
    </div>
</div>

<!-- Tezkor havolalar -->
<div class="card">
    <div class="card-title">Tezkor havolalar</div>
    <div class="quick-links">
        <a href="${pageContext.request.contextPath}/abs/acc/account-list.jsp" class="quick-link-card">
            <div class="quick-link-icon indigo">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Hisoblar ro'yxati</div>
                <div class="quick-link-badge" style="background:var(--primary-100);color:var(--primary)"><%= totalAccounts %> ta</div>
            </div>
            <div class="quick-link-arrow"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></div>
        </a>
        <a href="${pageContext.request.contextPath}/abs/acc/account-approve.jsp" class="quick-link-card">
            <div class="quick-link-icon amber">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Tasdiqlash</div>
                <% if (pendingCount > 0) { %>
                <div class="quick-link-badge amber"><%= pendingCount %> kutilmoqda</div>
                <% } else { %>
                <div class="quick-link-badge" style="background:var(--gray-100);color:var(--gray-500)">Hammasi tayyor</div>
                <% } %>
            </div>
            <div class="quick-link-arrow"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></div>
        </a>
        <a href="${pageContext.request.contextPath}/abs/acc/currency-stats.jsp" class="quick-link-card">
            <div class="quick-link-icon blue">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Valyuta statistikasi</div>
                <div class="quick-link-badge blue">RPT-003</div>
            </div>
            <div class="quick-link-arrow"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></div>
        </a>
        <a href="${pageContext.request.contextPath}/abs/acc/dormant-accounts.jsp" class="quick-link-card">
            <div class="quick-link-icon slate">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Harakatsiz hisoblar</div>
                <div class="quick-link-badge" style="background:var(--gray-100);color:var(--gray-500)">RPT-005</div>
            </div>
            <div class="quick-link-arrow"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></div>
        </a>
    </div>
</div>

<jsp:include page="acc-footer.jsp"/>

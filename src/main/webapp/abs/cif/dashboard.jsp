<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - CIF Dashboard
  View: core_cif_statistics_i_v (bitta qator — subquery'lar DUAL'dan)
  Servlet yo'q — to'g'ridan-to'g'ri JDBC
--%>
<%
    // ---- core_cif_statistics_i_v dan statistika olish ----
    int totalCustomers = 0, individualCount = 0, corporateCount = 0;
    int pendingCount = 0, activeCount = 0, blockedCount = 0, closedCount = 0;
    int highRiskCount = 0, pepCount = 0;
    int totalDocuments = 0, expiredDocuments = 0, totalContacts = 0;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();
        ps = conn.prepareStatement(
            "SELECT total_customers, individual_count, corporate_count, " +
            "       pending_count, active_count, blocked_count, closed_count, " +
            "       high_risk_count, pep_count, " +
            "       total_documents, expired_documents, total_contacts " +
            "  FROM core_cif_statistics_i_v"
        );
        rs = ps.executeQuery();
        if (rs.next()) {
            totalCustomers   = rs.getInt("total_customers");
            individualCount  = rs.getInt("individual_count");
            corporateCount   = rs.getInt("corporate_count");
            pendingCount     = rs.getInt("pending_count");
            activeCount      = rs.getInt("active_count");
            blockedCount     = rs.getInt("blocked_count");
            closedCount      = rs.getInt("closed_count");
            highRiskCount    = rs.getInt("high_risk_count");
            pepCount         = rs.getInt("pep_count");
            totalDocuments   = rs.getInt("total_documents");
            expiredDocuments = rs.getInt("expired_documents");
            totalContacts    = rs.getInt("total_contacts");
        }
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (ps != null) try { ps.close(); } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    // Foiz hisoblash (safe division)
    int pctPending  = totalCustomers > 0 ? (int) Math.round(pendingCount  * 100.0 / totalCustomers) : 0;
    int pctActive   = totalCustomers > 0 ? (int) Math.round(activeCount   * 100.0 / totalCustomers) : 0;
    int pctBlocked  = totalCustomers > 0 ? (int) Math.round(blockedCount  * 100.0 / totalCustomers) : 0;
    int pctClosed   = totalCustomers > 0 ? (int) Math.round(closedCount   * 100.0 / totalCustomers) : 0;
    int pctExpired  = totalDocuments > 0  ? (int) Math.round(expiredDocuments * 100.0 / totalDocuments) : 0;
%>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Dashboard"/>
    <jsp:param name="page" value="dashboard"/>
</jsp:include>

<style>
/* ---- Dashboard-specific styles ---- */

/* Metric kartalar (asosiy statistika) */
.dash-metrics {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
    gap: 1rem;
    margin-bottom: 1.5rem;
}
.dash-metric {
    background: var(--bg-surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 1.25rem 1.35rem;
    box-shadow: var(--shadow-sm);
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    transition: box-shadow var(--t) var(--ease), transform var(--t) var(--ease), border-color var(--t) var(--ease);
}
.dash-metric:hover {
    box-shadow: var(--shadow-md);
    transform: translateY(-2px);
    border-color: var(--border-strong);
}
.dash-metric-icon {
    width: 42px;
    height: 42px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.dash-metric-icon svg {
    width: 20px;
    height: 20px;
}
.dash-metric-icon.indigo  { background: var(--primary-100); color: var(--primary); }
.dash-metric-icon.slate   { background: var(--gray-100);    color: var(--gray-500); }
.dash-metric-icon.violet  { background: #f5f3ff;             color: #7c3aed; }
.dash-metric-icon.amber   { background: #fffbeb;             color: #b45309; }

.dash-metric-body { min-width: 0; flex: 1; }
.dash-metric-label {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--gray-500);
    margin-bottom: 0.25rem;
    white-space: nowrap;
}
.dash-metric-value {
    font-size: 2rem;
    font-weight: 700;
    letter-spacing: -0.04em;
    line-height: 1;
    color: var(--gray-900);
}
.dash-metric-sub {
    font-size: 0.72rem;
    color: var(--gray-400);
    margin-top: 0.3rem;
    font-weight: 500;
}

/* ---- Ikki ustunli qator ---- */
.dash-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 1.5rem;
}
@media (max-width: 900px) {
    .dash-row { grid-template-columns: 1fr; }
}

/* ---- Status taqsimoti (progress bar vizualizatsiya) ---- */
.status-list { display: flex; flex-direction: column; gap: 0.875rem; }
.status-row { display: flex; flex-direction: column; gap: 0.35rem; }
.status-row-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.5rem;
}
.status-row-left { display: flex; align-items: center; gap: 0.5rem; }
.status-dot {
    width: 8px; height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
}
.status-dot.active  { background: #059669; }
.status-dot.pending { background: #d97706; }
.status-dot.blocked { background: #dc2626; }
.status-dot.closed  { background: #94a3b8; }

.status-name {
    font-size: 0.82rem;
    font-weight: 500;
    color: var(--gray-700);
}
.status-meta {
    display: flex; align-items: center; gap: 0.5rem;
    flex-shrink: 0;
}
.status-count {
    font-size: 0.82rem;
    font-weight: 700;
    color: var(--gray-800);
    min-width: 28px;
    text-align: right;
}
.status-pct {
    font-size: 0.72rem;
    color: var(--gray-400);
    font-weight: 500;
    min-width: 30px;
    text-align: right;
}
.progress-track {
    height: 6px;
    background: var(--gray-100);
    border-radius: 99px;
    overflow: hidden;
}
.progress-fill {
    height: 100%;
    border-radius: 99px;
    transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}
.progress-fill.active  { background: #059669; }
.progress-fill.pending { background: #d97706; }
.progress-fill.blocked { background: #dc2626; }
.progress-fill.closed  { background: #94a3b8; }

/* ---- Risk va Compliance metrika ---- */
.risk-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
    margin-bottom: 1rem;
}
.risk-metric {
    background: var(--gray-50);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    padding: 1rem 1.1rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    transition: background var(--t-fast) var(--ease), border-color var(--t-fast) var(--ease);
}
.risk-metric:hover {
    background: #fff;
    border-color: var(--border-strong);
}
.risk-metric-icon {
    width: 36px; height: 36px;
    border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
}
.risk-metric-icon svg { width: 17px; height: 17px; }
.risk-metric-icon.danger  { background: #fef2f2; color: #b91c1c; }
.risk-metric-icon.pep     { background: #fdf2f8; color: #be185d; }
.risk-metric-icon.doc     { background: #ecfdf5; color: #047857; }
.risk-metric-icon.warn    { background: #fffbeb; color: #b45309; }
.risk-metric-icon.contact { background: var(--primary-50); color: var(--primary); }

.risk-metric-body {}
.risk-metric-val {
    font-size: 1.35rem;
    font-weight: 700;
    letter-spacing: -0.03em;
    color: var(--gray-900);
    line-height: 1.1;
}
.risk-metric-lbl {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--gray-500);
    margin-top: 0.15rem;
}

.contacts-row {
    display: flex;
    align-items: center;
    gap: 0.625rem;
    padding: 0.75rem 1rem;
    background: var(--gray-50);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
}
.contacts-row-icon {
    width: 32px; height: 32px;
    border-radius: 7px;
    background: var(--primary-50);
    color: var(--primary);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
}
.contacts-row-icon svg { width: 15px; height: 15px; }
.contacts-row-label {
    font-size: 0.8rem;
    color: var(--gray-600);
    font-weight: 500;
}
.contacts-row-val {
    margin-left: auto;
    font-size: 0.95rem;
    font-weight: 700;
    color: var(--gray-800);
}

/* ---- Tezkor havolalar (action kartalar) ---- */
.quick-links {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 0.875rem;
}
.quick-link-card {
    display: flex;
    align-items: center;
    gap: 0.875rem;
    padding: 1rem 1.125rem;
    background: var(--bg-surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    text-decoration: none;
    color: var(--gray-800);
    transition: box-shadow var(--t) var(--ease), transform var(--t) var(--ease),
                border-color var(--t) var(--ease), background var(--t-fast) var(--ease);
    box-shadow: var(--shadow-xs);
}
.quick-link-card:hover {
    box-shadow: var(--shadow-md);
    transform: translateY(-2px);
    border-color: var(--border-strong);
    background: #fff;
}
.quick-link-icon {
    width: 40px; height: 40px;
    border-radius: 9px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
}
.quick-link-icon svg { width: 19px; height: 19px; }
.quick-link-icon.indigo { background: var(--primary-100); color: var(--primary); }
.quick-link-icon.amber  { background: #fffbeb;             color: #b45309; }
.quick-link-icon.red    { background: #fef2f2;             color: #b91c1c; }
.quick-link-icon.pink   { background: #fdf2f8;             color: #be185d; }

.quick-link-body { min-width: 0; flex: 1; }
.quick-link-title {
    font-size: 0.86rem;
    font-weight: 600;
    color: var(--gray-800);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}
.quick-link-badge {
    display: inline-flex;
    align-items: center;
    height: 18px;
    padding: 0 0.4rem;
    border-radius: 99px;
    font-size: 0.68rem;
    font-weight: 700;
    margin-top: 0.2rem;
}
.quick-link-badge.amber { background: #fffbeb; color: #b45309; }
.quick-link-badge.red   { background: #fef2f2; color: #b91c1c; }
.quick-link-badge.pink  { background: #fdf2f8; color: #be185d; }

.quick-link-arrow {
    margin-left: auto;
    color: var(--gray-300);
    flex-shrink: 0;
    transition: color var(--t-fast) var(--ease), transform var(--t) var(--ease);
}
.quick-link-card:hover .quick-link-arrow {
    color: var(--gray-500);
    transform: translateX(3px);
}
.quick-link-arrow svg { width: 15px; height: 15px; }
</style>

<div class="page-header">
    <div>
        <h1>Boshqaruv paneli</h1>
        <div class="subtitle">CIF — Klientlar axborot tizimi</div>
    </div>
    <a href="${pageContext.request.contextPath}/abs/cif/client-create.jsp" class="btn btn-primary">
        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 5v14M5 12h14"/>
        </svg>
        Yangi klient
    </a>
</div>

<!-- ---- Asosiy ko'rsatkichlar ---- -->
<div class="dash-metrics">

    <div class="dash-metric">
        <div class="dash-metric-icon indigo">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                <circle cx="9" cy="7" r="4"/>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Jami klientlar</div>
            <div class="dash-metric-value"><%= totalCustomers %></div>
            <div class="dash-metric-sub">barcha holatlardagi klientlar</div>
        </div>
    </div>

    <div class="dash-metric">
        <div class="dash-metric-icon slate">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
            </svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Jismoniy shaxs</div>
            <div class="dash-metric-value"><%= individualCount %></div>
            <div class="dash-metric-sub">FYaSh klientlari</div>
        </div>
    </div>

    <div class="dash-metric">
        <div class="dash-metric-icon violet">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <rect x="2" y="7" width="20" height="14" rx="2" ry="2"/>
                <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
            </svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Yuridik shaxs</div>
            <div class="dash-metric-value"><%= corporateCount %></div>
            <div class="dash-metric-sub">YuSh klientlari</div>
        </div>
    </div>

    <div class="dash-metric">
        <div class="dash-metric-icon amber">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
            </svg>
        </div>
        <div class="dash-metric-body">
            <div class="dash-metric-label">Kutilmoqda</div>
            <div class="dash-metric-value"><%= pendingCount %></div>
            <div class="dash-metric-sub">tasdiqlanmagan</div>
        </div>
    </div>

</div>

<!-- ---- Holat taqsimoti + Risk/Compliance ---- -->
<div class="dash-row">

    <!-- Holatlar bo'yicha (progress-bar vizualizatsiya) -->
    <div class="card">
        <div class="card-title">Holatlar bo'yicha taqsimot</div>
        <div class="status-list">

            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left">
                        <span class="status-dot active"></span>
                        <span class="status-name">Faol</span>
                    </div>
                    <div class="status-meta">
                        <span class="status-count"><%= activeCount %></span>
                        <span class="status-pct"><%= pctActive %>%</span>
                    </div>
                </div>
                <div class="progress-track">
                    <div class="progress-fill active" style="width: <%= pctActive %>%"></div>
                </div>
            </div>

            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left">
                        <span class="status-dot pending"></span>
                        <span class="status-name">Kutilmoqda</span>
                    </div>
                    <div class="status-meta">
                        <span class="status-count"><%= pendingCount %></span>
                        <span class="status-pct"><%= pctPending %>%</span>
                    </div>
                </div>
                <div class="progress-track">
                    <div class="progress-fill pending" style="width: <%= pctPending %>%"></div>
                </div>
            </div>

            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left">
                        <span class="status-dot blocked"></span>
                        <span class="status-name">Bloklangan</span>
                    </div>
                    <div class="status-meta">
                        <span class="status-count"><%= blockedCount %></span>
                        <span class="status-pct"><%= pctBlocked %>%</span>
                    </div>
                </div>
                <div class="progress-track">
                    <div class="progress-fill blocked" style="width: <%= pctBlocked %>%"></div>
                </div>
            </div>

            <div class="status-row">
                <div class="status-row-header">
                    <div class="status-row-left">
                        <span class="status-dot closed"></span>
                        <span class="status-name">Yopilgan</span>
                    </div>
                    <div class="status-meta">
                        <span class="status-count"><%= closedCount %></span>
                        <span class="status-pct"><%= pctClosed %>%</span>
                    </div>
                </div>
                <div class="progress-track">
                    <div class="progress-fill closed" style="width: <%= pctClosed %>%"></div>
                </div>
            </div>

        </div>
    </div>

    <!-- Risk va Compliance -->
    <div class="card">
        <div class="card-title">Risk va Compliance</div>
        <div class="risk-grid">

            <div class="risk-metric">
                <div class="risk-metric-icon danger">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                </div>
                <div class="risk-metric-body">
                    <div class="risk-metric-val"><%= highRiskCount %></div>
                    <div class="risk-metric-lbl">Yuqori risk</div>
                </div>
            </div>

            <div class="risk-metric">
                <div class="risk-metric-icon pep">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="8" r="4"/>
                        <path d="M12 14c-4 0-7 2-7 4v1h14v-1c0-2-3-4-7-4z"/>
                        <path d="M17 4l2 2-2 2"/>
                    </svg>
                </div>
                <div class="risk-metric-body">
                    <div class="risk-metric-val"><%= pepCount %></div>
                    <div class="risk-metric-lbl">PEP shaxslar</div>
                </div>
            </div>

            <div class="risk-metric">
                <div class="risk-metric-icon doc">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                        <polyline points="14 2 14 8 20 8"/>
                        <line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
                        <polyline points="10 9 9 9 8 9"/>
                    </svg>
                </div>
                <div class="risk-metric-body">
                    <div class="risk-metric-val"><%= totalDocuments %></div>
                    <div class="risk-metric-lbl">Jami hujjat</div>
                </div>
            </div>

            <div class="risk-metric">
                <div class="risk-metric-icon warn">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/>
                        <line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                        <path d="M9 16l2 2 4-4"/>
                    </svg>
                </div>
                <div class="risk-metric-body">
                    <div class="risk-metric-val"><%= expiredDocuments %></div>
                    <div class="risk-metric-lbl">Muddati o'tgan</div>
                </div>
            </div>

        </div>

        <div class="contacts-row">
            <div class="contacts-row-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.37 2 2 0 0 1 3.61 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.59a16 16 0 0 0 6 6l.96-.96a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
                </svg>
            </div>
            <span class="contacts-row-label">Jami kontaktlar</span>
            <span class="contacts-row-val"><%= totalContacts %></span>
        </div>
    </div>

</div>

<!-- ---- Tezkor havolalar ---- -->
<div class="card">
    <div class="card-title">Tezkor havolalar</div>
    <div class="quick-links">

        <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="quick-link-card">
            <div class="quick-link-icon indigo">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Klientlar ro'yxati</div>
                <div class="quick-link-badge" style="background:var(--primary-100);color:var(--primary)"><%= totalCustomers %> ta</div>
            </div>
            <div class="quick-link-arrow">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 18l6-6-6-6"/>
                </svg>
            </div>
        </a>

        <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="quick-link-card">
            <div class="quick-link-icon amber">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20 6 9 17 4 12"/>
                </svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Tasdiqlash</div>
                <% if (pendingCount > 0) { %>
                <div class="quick-link-badge amber"><%= pendingCount %> kutilmoqda</div>
                <% } else { %>
                <div class="quick-link-badge" style="background:var(--gray-100);color:var(--gray-500)">Hammasi tayyor</div>
                <% } %>
            </div>
            <div class="quick-link-arrow">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 18l6-6-6-6"/>
                </svg>
            </div>
        </a>

        <a href="${pageContext.request.contextPath}/abs/cif/client-create.jsp" class="quick-link-card">
            <div class="quick-link-icon indigo" style="background:#ecfdf5;color:#047857;">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <line x1="19" y1="8" x2="19" y2="14"/>
                    <line x1="22" y1="11" x2="16" y2="11"/>
                </svg>
            </div>
            <div class="quick-link-body">
                <div class="quick-link-title">Yangi klient</div>
                <div class="quick-link-badge" style="background:#ecfdf5;color:#047857;">Qo'shish</div>
            </div>
            <div class="quick-link-arrow">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 18l6-6-6-6"/>
                </svg>
            </div>
        </a>

    </div>
</div>

<jsp:include page="cif-footer.jsp"/>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - ACC Hisob tafsiloti
  View: core_acc_account_detail_i_v
  Audit: core_acc_audit_log (oxirgi 20 ta)
  Holat o'zgartirish: account-status-save.jsp ga yo'naltirish
--%>
<%
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.isEmpty()) {
        response.sendRedirect("account-list.jsp");
        return;
    }
    long accountId = Long.parseLong(idStr);

    java.util.Map<String,Object> acc = null;
    java.util.List<java.util.Map<String,Object>> auditLogs = new java.util.ArrayList<>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();

        // Hisob tafsiloti
        ps = conn.prepareStatement(
            "SELECT account_id, account_number, customer_id, cif_number, customer_name, customer_phone," +
            "       account_type, currency, gl_code, account_name, status," +
            "       balance, available_balance, min_balance, daily_limit, monthly_limit," +
            "       interest_rate, branch_code, opened_at, closed_at, close_reason," +
            "       approved_by, approved_at, created_by, created_at, updated_by, updated_at" +
            "  FROM core_acc_account_detail_i_v WHERE account_id = ?"
        );
        ps.setLong(1, accountId);
        rs = ps.executeQuery();
        if (rs.next()) {
            acc = new java.util.LinkedHashMap<>();
            ResultSetMetaData md = rs.getMetaData();
            for (int i = 1; i <= md.getColumnCount(); i++) {
                String colName = md.getColumnName(i).toLowerCase();
                int colType    = md.getColumnType(i);
                Object val;
                if (colType == Types.TIMESTAMP || colType == Types.DATE || colType == -101 || colType == -102) {
                    Timestamp ts = rs.getTimestamp(i);
                    val = (ts != null) ? new java.util.Date(ts.getTime()) : null;
                } else {
                    val = rs.getObject(i);
                }
                acc.put(colName, val);
            }
        }
        rs.close(); ps.close();

        if (acc == null) {
            response.sendRedirect("account-list.jsp?err=" + java.net.URLEncoder.encode("Hisob topilmadi", "UTF-8"));
            return;
        }

        // Audit log (oxirgi 20 ta)
        try {
            ps = conn.prepareStatement(
                "SELECT * FROM (" +
                "  SELECT log_id, action_type, field_name, old_value, new_value, changed_by, changed_at" +
                "    FROM core_acc_audit_log" +
                "   WHERE account_id = ? ORDER BY changed_at DESC" +
                ") WHERE ROWNUM <= 20"
            );
            ps.setLong(1, accountId);
            rs = ps.executeQuery();
            while (rs.next()) {
                java.util.Map<String,Object> row = new java.util.LinkedHashMap<>();
                row.put("log_id",      rs.getLong("log_id"));
                row.put("action_type", rs.getString("action_type"));
                row.put("field_name",  rs.getString("field_name"));
                row.put("old_value",   rs.getString("old_value"));
                row.put("new_value",   rs.getString("new_value"));
                row.put("changed_by",  rs.getString("changed_by"));
                row.put("changed_at",  rs.getTimestamp("changed_at"));
                auditLogs.add(row);
            }
            rs.close(); ps.close();
        } catch (Exception auditEx) {
            // Audit jadval bo'lmasa ko'rsatmaslik (silent)
        }

    } finally {
        if (rs   != null) try { rs.close();   } catch (Exception e) {}
        if (ps   != null) try { ps.close();   } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    request.setAttribute("a", acc);
    request.setAttribute("auditLogs", auditLogs);

    String accStatus = (String) acc.get("status");
%>
<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="${a.account_number}"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>
        <span class="badge badge-<%= "ACTIVE".equals(accStatus) ? "active" : "PENDING".equals(accStatus) ? "pending" : "FROZEN".equals(accStatus) || "BLOCKED".equals(accStatus) ? "blocked" : "closed" %>">
            <c:out value="${a.status}"/>
        </span>
        <c:out value="${a.account_number}"/>
    </h1>
    <div class="action-buttons">
        <a href="account-edit.jsp?id=<%= accountId %>" class="btn btn-primary">Tahrirlash</a>
        <a href="account-list.jsp" class="btn">Ortga</a>
    </div>
</div>

<!-- Asosiy ma'lumotlar + Mijoz -->
<div class="info-row">
    <div class="card">
        <div class="card-title">Hisob ma'lumotlari</div>
        <dl class="detail-grid-wide">
            <dt>Hisob raqami</dt>
            <dd><strong><c:out value="${a.account_number}"/></strong></dd>
            <dt>Holat</dt>
            <dd>
                <span class="badge badge-<%= "ACTIVE".equals(accStatus) ? "active" : "PENDING".equals(accStatus) ? "pending" : "FROZEN".equals(accStatus) || "BLOCKED".equals(accStatus) ? "blocked" : "closed" %>">
                    <c:out value="${a.status}"/>
                </span>
            </dd>
            <dt>Hisob turi</dt>
            <dd>
                <c:choose>
                    <c:when test="${a.account_type == 'CURRENT'}">Joriy</c:when>
                    <c:when test="${a.account_type == 'SAVINGS'}">Jamg'arma</c:when>
                    <c:when test="${a.account_type == 'DEPOSIT'}">Depozit</c:when>
                    <c:when test="${a.account_type == 'LOAN'}">Kredit</c:when>
                    <c:when test="${a.account_type == 'SPECIAL'}">Maxsus</c:when>
                    <c:otherwise><c:out value="${a.account_type}"/></c:otherwise>
                </c:choose>
            </dd>
            <dt>Valyuta</dt>
            <dd><span class="badge badge-individual"><c:out value="${a.currency}"/></span></dd>
            <dt>GL kodi</dt>
            <dd><c:out value="${a.gl_code}"/></dd>
            <dt>Hisob nomi</dt>
            <dd><c:out value="${a.account_name}"/></dd>
            <dt>Qoldiq</dt>
            <dd style="font-weight:700; font-variant-numeric:tabular-nums;">
                <fmt:formatNumber value="${a.balance}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                <c:out value=" ${a.currency}"/>
            </dd>
            <dt>Mavjud qoldiq</dt>
            <dd style="font-variant-numeric:tabular-nums;">
                <fmt:formatNumber value="${a.available_balance}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                <c:out value=" ${a.currency}"/>
            </dd>
            <dt>Minimal qoldiq</dt>
            <dd style="font-variant-numeric:tabular-nums;">
                <fmt:formatNumber value="${a.min_balance}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
            </dd>
            <dt>Foiz stavkasi</dt>
            <dd><fmt:formatNumber value="${a.interest_rate}" type="number" minFractionDigits="2" maxFractionDigits="2"/>%</dd>
            <dt>Kunlik limit</dt>
            <dd>
                <c:choose>
                    <c:when test="${a.daily_limit != null}">
                        <fmt:formatNumber value="${a.daily_limit}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                    </c:when>
                    <c:otherwise>Cheklovsiz</c:otherwise>
                </c:choose>
            </dd>
            <dt>Oylik limit</dt>
            <dd>
                <c:choose>
                    <c:when test="${a.monthly_limit != null}">
                        <fmt:formatNumber value="${a.monthly_limit}" type="number" minFractionDigits="2" maxFractionDigits="2"/>
                    </c:when>
                    <c:otherwise>Cheklovsiz</c:otherwise>
                </c:choose>
            </dd>
            <dt>Filial</dt>
            <dd><c:out value="${a.branch_code}"/></dd>
            <dt>Ochilgan sana</dt>
            <dd><fmt:formatDate value="${a.opened_at}" pattern="dd.MM.yyyy HH:mm"/></dd>
            <c:if test="${a.closed_at != null}">
                <dt>Yopilgan sana</dt>
                <dd><fmt:formatDate value="${a.closed_at}" pattern="dd.MM.yyyy HH:mm"/></dd>
                <dt>Yopish sababi</dt>
                <dd><c:out value="${a.close_reason}"/></dd>
            </c:if>
        </dl>
    </div>

    <div class="card">
        <div class="card-title">Mijoz ma'lumotlari</div>
        <dl class="detail-grid-wide">
            <dt>CIF raqami</dt>
            <dd>
                <a href="${pageContext.request.contextPath}/abs/cif/customer-detail.jsp?id=${a.customer_id}" class="link">
                    <c:out value="${a.cif_number}"/>
                </a>
            </dd>
            <dt>Mijoz nomi</dt>
            <dd><c:out value="${a.customer_name}"/></dd>
            <dt>Telefon</dt>
            <dd><c:out value="${a.customer_phone}"/></dd>
        </dl>

        <div class="section-title" style="margin-top:1.5rem;">Audit</div>
        <dl class="detail-grid-wide">
            <dt>Yaratgan</dt>
            <dd><c:out value="${a.created_by}"/> — <fmt:formatDate value="${a.created_at}" pattern="dd.MM.yyyy HH:mm"/></dd>
            <dt>O'zgartirgan</dt>
            <dd>
                <c:choose>
                    <c:when test="${a.updated_by != null}">
                        <c:out value="${a.updated_by}"/> — <fmt:formatDate value="${a.updated_at}" pattern="dd.MM.yyyy HH:mm"/>
                    </c:when>
                    <c:otherwise>—</c:otherwise>
                </c:choose>
            </dd>
            <dt>Tasdiqlagan</dt>
            <dd>
                <c:choose>
                    <c:when test="${a.approved_by != null}">
                        <c:out value="${a.approved_by}"/> — <fmt:formatDate value="${a.approved_at}" pattern="dd.MM.yyyy HH:mm"/>
                    </c:when>
                    <c:otherwise>—</c:otherwise>
                </c:choose>
            </dd>
        </dl>
    </div>
</div>

<!-- Holat o'zgartirish -->
<% if (!"CLOSED".equals(accStatus) && !"REJECTED".equals(accStatus)) { %>
<div class="card">
    <div class="card-title">Holat o'zgartirish</div>

    <% if ("PENDING".equals(accStatus)) { %>
    <%-- PENDING: Approve / Reject --%>
    <div style="display:flex; gap:.5rem; flex-wrap:wrap;">
        <form method="post" action="account-status-save.jsp" style="display:inline;"
              data-confirm="Hisobni tasdiqlamoqchimisiz?">
            <input type="hidden" name="action" value="approve">
            <input type="hidden" name="id" value="<%= accountId %>">
            <input type="hidden" name="approved_by" value="SUPERVISOR">
            <button type="submit" class="btn btn-success">Tasdiqlash</button>
        </form>
        <form method="post" action="account-status-save.jsp" style="display:inline;"
              data-confirm="Hisobni rad etmoqchimisiz?">
            <input type="hidden" name="action" value="reject">
            <input type="hidden" name="id" value="<%= accountId %>">
            <input type="hidden" name="rejected_by" value="SUPERVISOR">
            <div style="display:inline-flex; gap:.5rem; align-items:center;">
                <input type="text" name="reason" class="form-control" placeholder="Rad etish sababi" style="width:200px;" required>
                <button type="submit" class="btn btn-danger">Rad etish</button>
            </div>
        </form>
    </div>
    <% } else { %>
    <%-- ACTIVE, FROZEN, BLOCKED: holat o'zgartirish --%>
    <form method="post" action="account-status-save.jsp" style="display:flex; gap:.5rem; align-items:end; flex-wrap:wrap;"
          data-confirm="Hisob holatini o'zgartirasizmi?">
        <input type="hidden" name="action" value="status">
        <input type="hidden" name="id" value="<%= accountId %>">
        <div class="form-group" style="margin-bottom:0;">
            <label>Yangi holat</label>
            <select name="status" class="form-control">
                <% if ("ACTIVE".equals(accStatus)) { %>
                    <option value="FROZEN">FROZEN — Muzlatish</option>
                    <option value="BLOCKED">BLOCKED — Bloklash</option>
                    <option value="CLOSED">CLOSED — Yopish</option>
                <% } else if ("FROZEN".equals(accStatus)) { %>
                    <option value="ACTIVE">ACTIVE — Faollashtirish</option>
                    <option value="BLOCKED">BLOCKED — Bloklash</option>
                <% } else if ("BLOCKED".equals(accStatus)) { %>
                    <option value="ACTIVE">ACTIVE — Faollashtirish</option>
                    <option value="CLOSED">CLOSED — Yopish</option>
                <% } %>
            </select>
        </div>
        <div class="form-group" style="margin-bottom:0;">
            <label>Sabab</label>
            <input type="text" name="reason" class="form-control" placeholder="Sabab (ixtiyoriy)" style="width:220px;">
        </div>
        <div class="form-group" style="margin-bottom:0;">
            <label>Operator</label>
            <input type="text" name="changed_by" class="form-control" value="OPERATOR" style="width:130px;">
        </div>
        <button type="submit" class="btn btn-warning">O'zgartirish</button>
    </form>
    <% } %>
</div>
<% } %>

<!-- Audit log -->
<div class="card">
    <div class="card-title">Audit log (oxirgi 20 ta)</div>
    <c:choose>
        <c:when test="${not empty auditLogs}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Amal</th>
                            <th>Maydon</th>
                            <th>Eski qiymat</th>
                            <th>Yangi qiymat</th>
                            <th>Kim</th>
                            <th>Qachon</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="al" items="${auditLogs}">
                            <tr>
                                <td>
                                    <span class="badge badge-${al.action_type == 'CREATE' ? 'active' : al.action_type == 'UPDATE' ? 'pending' : 'blocked'}">
                                        <c:out value="${al.action_type}"/>
                                    </span>
                                </td>
                                <td><c:out value="${al.field_name}"/></td>
                                <td style="max-width:180px; overflow:hidden; text-overflow:ellipsis;">
                                    <c:out value="${al.old_value}"/>
                                </td>
                                <td style="max-width:180px; overflow:hidden; text-overflow:ellipsis;">
                                    <c:out value="${al.new_value}"/>
                                </td>
                                <td><c:out value="${al.changed_by}"/></td>
                                <td><fmt:formatDate value="${al.changed_at}" pattern="dd.MM.yyyy HH:mm"/></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <div class="empty-state"><div class="message">Audit log topilmadi</div></div>
        </c:otherwise>
    </c:choose>
</div>

<jsp:include page="acc-footer.jsp"/>

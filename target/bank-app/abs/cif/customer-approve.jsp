<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Types, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>
<%--
  MARS ABS - CIF Tasdiqlash (Maker-Checker)
  View: core_cif_pending_customers_ui_v
  POST: core_cif_service.Approve_Customer / Reject_Customer
  Servlet yo'q — to'g'ridan-to'g'ri JDBC
--%>
<%
    // ==== POST handler — HTML chiqarishdan OLDIN ====
    if ("POST".equals(request.getMethod())) {
        String action     = request.getParameter("action");
        String custIdStr  = request.getParameter("customer_id");
        String actionBy   = "SUPERVISOR"; // hardcoded

        String redirectUrl = "customer-approve.jsp";

        if (action != null && custIdStr != null) {
            try {
                long customerId = Long.parseLong(custIdStr);
                String proc = "APPROVE".equals(action)
                    ? "core_cif_service.Approve_Customer"
                    : "core_cif_service.Reject_Customer";
                java.util.Map<String,Object> result = Mars.procedure(proc)
                    .in("customer_id", customerId)
                    .in("action_by", actionBy)
                    .outNumber("code")
                    .outString("message")
                    .outString("ora_message")
                    .execute();
                int code = ((Number) result.get("code")).intValue();
                String message = (String) result.get("message");

                if (code == 0) {
                    redirectUrl += "?msg=" + java.net.URLEncoder.encode(
                        ("APPROVE".equals(action) ? "Tasdiqlandi" : "Rad etildi") + ": " + message, "UTF-8");
                } else {
                    redirectUrl += "?err=" + java.net.URLEncoder.encode(
                        "Xatolik (code=" + code + "): " + message, "UTF-8");
                }
            } catch (Exception ex) {
                redirectUrl += "?err=" + java.net.URLEncoder.encode(
                    "Tizim xatoligi: " + ex.getMessage(), "UTF-8");
            }
        } else {
            redirectUrl += "?err=" + java.net.URLEncoder.encode("Noto'g'ri so'rov parametrlari", "UTF-8");
        }

        response.sendRedirect(redirectUrl);
        return;
    }

%>
<t:table var="data" view="core_cif_pending_customers_ui_v" orderBy="created_at ASC">
    <t:grid pageSize="100" />
</t:table>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Tasdiqlash"/>
    <jsp:param name="page" value="approve"/>
</jsp:include>

<div class="page-header">
    <h1>Tasdiqlash kutayotgan mijozlar (Maker-Checker)</h1>
</div>

<!-- ---- Natijalar soni ---- -->
<div style="margin-bottom:0.75rem; font-size:0.85rem; color:var(--gray-500);">
    Jami: <strong>${data.totalRows}</strong> ta kutayotgan mijoz
</div>

<!-- ---- Jadval ---- -->
<div class="card" style="padding:0;">
    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>CIF</th>
                    <th>Turi</th>
                    <th>Mijoz nomi</th>
                    <th>Telefon</th>
                    <th>Filial</th>
                    <th>Risk</th>
                    <th>PEP</th>
                    <th>Yaratgan</th>
                    <th>Sana</th>
                    <th>Kutish (soat)</th>
                    <th>Amallar</th>
                </tr>
            </thead>
            <tbody>
                <c:choose>
                    <c:when test="${not empty data.rows}">
                        <c:forEach var="r" items="${data.rows}">
                            <tr>
                                <td>
                                    <a href="${pageContext.request.contextPath}/abs/cif/customer-detail.jsp?id=${r.customer_id}" class="link">
                                        ${r.cif_number}
                                    </a>
                                </td>
                                <td>
                                    <span class="badge badge-${r.customer_type == 'INDIVIDUAL' ? 'individual' : 'corporate'}">
                                        ${r.customer_type == 'INDIVIDUAL' ? 'FYaSh' : 'YuSh'}
                                    </span>
                                </td>
                                <td>
                                    <a href="${pageContext.request.contextPath}/abs/cif/customer-detail.jsp?id=${r.customer_id}" class="link">
                                        ${r.display_name}
                                    </a>
                                </td>
                                <td>${r.phone}</td>
                                <td>${r.branch_code}</td>
                                <td>
                                    <span class="badge badge-${r.risk_category == 'HIGH' ? 'high' : r.risk_category == 'MEDIUM' ? 'medium' : 'low'}">
                                        ${r.risk_category}
                                    </span>
                                </td>
                                <td>
                                    <c:if test="${r.is_pep == 'Y'}">
                                        <span class="badge badge-pep">PEP</span>
                                    </c:if>
                                </td>
                                <td>${r.created_by}</td>
                                <td><fmt:formatDate value="${r.created_at}" pattern="dd.MM.yyyy HH:mm"/></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${r.waiting_hours > 24}">
                                            <span style="color: var(--danger); font-weight: 700;">${r.waiting_hours} s</span>
                                        </c:when>
                                        <c:otherwise>
                                            ${r.waiting_hours} s
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <form method="post" style="display:inline;" data-confirm="Mijozni tasdiqlaysizmi?">
                                            <input type="hidden" name="action" value="APPROVE">
                                            <input type="hidden" name="customer_id" value="${r.customer_id}">
                                            <button type="submit" class="btn btn-success btn-sm">Tasdiqlash</button>
                                        </form>
                                        <form method="post" style="display:inline;" data-confirm="Mijozni rad etasizmi?">
                                            <input type="hidden" name="action" value="REJECT">
                                            <input type="hidden" name="customer_id" value="${r.customer_id}">
                                            <button type="submit" class="btn btn-danger btn-sm">Rad etish</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr>
                            <td colspan="11" class="empty-state">
                                <div class="message">Tasdiqlash kutayotgan mijoz yo'q</div>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="cif-footer.jsp"/>

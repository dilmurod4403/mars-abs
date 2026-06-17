<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" uri="http://fido.uz/abs/tags" %>
<%--
  MARS ABS - ACC Tasdiqlash (Maker-Checker)
  View: core_acc_pending_accounts_ui_v
  POST: core_acc_service.Approve_Account / Reject_Account
  Eslatma: Maker-checker — created_by != approvedBy (xato -20107 agar bir xil bo'lsa)
--%>
<%
    // ==== POST handler — HTML chiqarishdan OLDIN ====
    if ("POST".equals(request.getMethod())) {
        String action    = request.getParameter("action");
        String accIdStr  = request.getParameter("account_id");
        String actionBy  = request.getParameter("action_by");
        if (actionBy == null || actionBy.isEmpty()) actionBy = "SUPERVISOR";

        String redirectUrl = "account-approve.jsp";

        if (action != null && accIdStr != null) {
            try {
                long accId = Long.parseLong(accIdStr);
                String reason = request.getParameter("reason");
                if (reason == null) reason = "";

                java.util.Map<String,Object> result;
                if ("APPROVE".equals(action)) {
                    result = Mars.procedure("core_acc_service.Approve_Account")
                        .in("i_account_id",  accId)
                        .in("i_approved_by", actionBy)
                        .outNumber("o_code")
                        .outString("o_message")
                        .outString("o_ora_message")
                        .execute();
                } else {
                    result = Mars.procedure("core_acc_service.Reject_Account")
                        .in("i_account_id",  accId)
                        .in("i_rejected_by", actionBy)
                        .in("i_reason",      reason)
                        .outNumber("o_code")
                        .outString("o_message")
                        .outString("o_ora_message")
                        .execute();
                }

                int code    = ((Number) result.get("o_code")).intValue();
                String message = (String) result.get("o_message");

                if (code == 0) {
                    redirectUrl += "?msg=" + java.net.URLEncoder.encode(
                        ("APPROVE".equals(action) ? "Tasdiqlandi" : "Rad etildi") +
                        (message != null && !message.isEmpty() ? ": " + message : ""), "UTF-8");
                } else {
                    // -20107: maker-checker xatosi
                    redirectUrl += "?err=" + java.net.URLEncoder.encode(
                        message != null ? message : "Noma'lum xato (code=" + code + ")", "UTF-8");
                }
            } catch (Exception ex) {
                redirectUrl += "?err=" + java.net.URLEncoder.encode("Tizim xatoligi: " + ex.getMessage(), "UTF-8");
            }
        } else {
            redirectUrl += "?err=" + java.net.URLEncoder.encode("Noto'g'ri so'rov parametrlari", "UTF-8");
        }
        response.sendRedirect(redirectUrl);
        return;
    }
%>

<t:table var="data" view="core_acc_pending_accounts_ui_v" orderBy="created_at ASC">
    <t:grid pageSize="100" />
</t:table>

<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Tasdiqlash"/>
    <jsp:param name="page" value="approve"/>
</jsp:include>

<div class="page-header">
    <h1>Tasdiqlash kutayotgan hisoblar (Maker-Checker)</h1>
</div>

<div style="margin-bottom:.75rem; font-size:.85rem; color:var(--gray-500);">
    Jami: <strong>${data.totalRows}</strong> ta kutayotgan hisob
</div>

<div class="card" style="padding:0;">
    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Hisob raqami</th>
                    <th>Mijoz</th>
                    <th>Turi</th>
                    <th>Valyuta</th>
                    <th>Filial</th>
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
                                    <a href="${pageContext.request.contextPath}/abs/acc/account-detail.jsp?id=${r.account_id}" class="link">
                                        <c:out value="${r.account_number}"/>
                                    </a>
                                </td>
                                <td>
                                    <a href="${pageContext.request.contextPath}/abs/acc/account-detail.jsp?id=${r.account_id}" class="link">
                                        <c:out value="${r.display_name}"/>
                                    </a>
                                </td>
                                <td>
                                    <span class="badge badge-individual">
                                        <c:choose>
                                            <c:when test="${r.account_type == 'CURRENT'}">Joriy</c:when>
                                            <c:when test="${r.account_type == 'SAVINGS'}">Jamg'arma</c:when>
                                            <c:when test="${r.account_type == 'DEPOSIT'}">Depozit</c:when>
                                            <c:when test="${r.account_type == 'LOAN'}">Kredit</c:when>
                                            <c:when test="${r.account_type == 'SPECIAL'}">Maxsus</c:when>
                                            <c:otherwise><c:out value="${r.account_type}"/></c:otherwise>
                                        </c:choose>
                                    </span>
                                </td>
                                <td><c:out value="${r.currency}"/></td>
                                <td><c:out value="${r.branch_code}"/></td>
                                <td><c:out value="${r.created_by}"/></td>
                                <td><fmt:formatDate value="${r.created_at}" pattern="dd.MM.yyyy HH:mm"/></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${r.waiting_hours > 24}">
                                            <span style="color:var(--danger); font-weight:700;">${r.waiting_hours} s</span>
                                        </c:when>
                                        <c:otherwise>${r.waiting_hours} s</c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <form method="post" style="display:inline;" data-confirm="Hisobni tasdiqlamoqchimisiz? Siz va yaratuvchi bir xil bo'lmasligi kerak (maker-checker).">
                                            <input type="hidden" name="action"     value="APPROVE">
                                            <input type="hidden" name="account_id" value="${r.account_id}">
                                            <input type="hidden" name="action_by"  value="SUPERVISOR">
                                            <button type="submit" class="btn btn-success btn-sm">Tasdiqlash</button>
                                        </form>
                                        <form method="post" style="display:inline;" data-confirm="Hisobni rad etasizmi?">
                                            <input type="hidden" name="action"     value="REJECT">
                                            <input type="hidden" name="account_id" value="${r.account_id}">
                                            <input type="hidden" name="action_by"  value="SUPERVISOR">
                                            <input type="hidden" name="reason"     value="Talabga javob bermaydi">
                                            <button type="submit" class="btn btn-danger btn-sm">Rad etish</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr>
                            <td colspan="9" class="empty-state">
                                <div class="message">Tasdiqlash kutayotgan hisob yo'q</div>
                            </td>
                        </tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="acc-footer.jsp"/>

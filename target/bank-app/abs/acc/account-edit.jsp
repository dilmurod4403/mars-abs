<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - ACC Hisob tahrirlash
  Procedure: core_acc_service.Update_Account (record IN)
  Tahrirlanadi: account_name, min_balance, daily_limit, monthly_limit, interest_rate
  O'zgarmaydi: account_number, currency, account_type, status
--%>
<%
    // ---- POST: Yangilash ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String accIdStr      = request.getParameter("account_id");
        String accountName   = request.getParameter("account_name");
        String minBalStr     = request.getParameter("min_balance");
        String dailyLimStr   = request.getParameter("daily_limit");
        String monthlyLimStr = request.getParameter("monthly_limit");
        String intRateStr    = request.getParameter("interest_rate");
        String updatedBy     = request.getParameter("updated_by");
        if (updatedBy == null || updatedBy.isEmpty()) updatedBy = "OPERATOR";

        try {
            long accId = Long.parseLong(accIdStr);
            java.math.BigDecimal minBal     = (minBalStr != null && !minBalStr.isEmpty())         ? new java.math.BigDecimal(minBalStr)     : java.math.BigDecimal.ZERO;
            java.math.BigDecimal dailyLim   = (dailyLimStr != null && !dailyLimStr.isEmpty())     ? new java.math.BigDecimal(dailyLimStr)   : null;
            java.math.BigDecimal monthlyLim = (monthlyLimStr != null && !monthlyLimStr.isEmpty()) ? new java.math.BigDecimal(monthlyLimStr) : null;
            java.math.BigDecimal intRate    = (intRateStr != null && !intRateStr.isEmpty())       ? new java.math.BigDecimal(intRateStr)    : java.math.BigDecimal.ZERO;

            java.util.Map<String,Object> result = Mars.procedure("core_acc_service.Update_Account")
                .record("i_account", "core_acc_types.t_account_rec")
                    .field("account_id",    accId)
                    .field("account_name",  accountName)
                    .field("min_balance",   minBal.toPlainString())
                    .field("daily_limit",   dailyLim != null ? dailyLim.toPlainString() : null)
                    .field("monthly_limit", monthlyLim != null ? monthlyLim.toPlainString() : null)
                    .field("interest_rate", intRate.toPlainString())
                    .field("updated_by",    updatedBy)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

            int code = ((Number) result.get("o_code")).intValue();
            String message = (String) result.get("o_message");
            if (code == 0) {
                response.sendRedirect("account-detail.jsp?id=" + accId
                    + "&msg=" + java.net.URLEncoder.encode("Hisob yangilandi", "UTF-8"));
                return;
            } else {
                request.setAttribute("errorMsg", message);
            }
        } catch (Exception e) {
            request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
        }
    }

    // ---- GET: Mavjud ma'lumotlarni yuklash ----
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.isEmpty()) {
        response.sendRedirect("account-list.jsp");
        return;
    }
    long accountId = Long.parseLong(idStr);

    java.util.Map<String,Object> acc = null;
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();
        ps = conn.prepareStatement(
            "SELECT account_id, account_number, account_type, currency, status, account_name," +
            "       min_balance, daily_limit, monthly_limit, interest_rate, branch_code" +
            "  FROM core_acc_account_detail_i_v WHERE account_id = ?"
        );
        ps.setLong(1, accountId);
        rs = ps.executeQuery();
        if (rs.next()) {
            acc = new java.util.LinkedHashMap<>();
            acc.put("account_id",     rs.getLong("account_id"));
            acc.put("account_number", rs.getString("account_number"));
            acc.put("account_type",   rs.getString("account_type"));
            acc.put("currency",       rs.getString("currency"));
            acc.put("status",         rs.getString("status"));
            acc.put("account_name",   rs.getString("account_name"));
            acc.put("min_balance",    rs.getBigDecimal("min_balance"));
            acc.put("daily_limit",    rs.getBigDecimal("daily_limit"));
            acc.put("monthly_limit",  rs.getBigDecimal("monthly_limit"));
            acc.put("interest_rate",  rs.getBigDecimal("interest_rate"));
            acc.put("branch_code",    rs.getString("branch_code"));
        }
    } finally {
        if (rs   != null) try { rs.close();   } catch (Exception e) {}
        if (ps   != null) try { ps.close();   } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    if (acc == null) {
        response.sendRedirect("account-list.jsp?err=" + java.net.URLEncoder.encode("Hisob topilmadi", "UTF-8"));
        return;
    }
    request.setAttribute("a", acc);

    // POST xato bo'lsa: forma qiymatlari prioritet
    String valName       = request.getParameter("account_name")   != null ? request.getParameter("account_name")   : (acc.get("account_name")   != null ? acc.get("account_name").toString()   : "");
    String valMinBal     = request.getParameter("min_balance")    != null ? request.getParameter("min_balance")    : (acc.get("min_balance")    != null ? acc.get("min_balance").toString()    : "");
    String valDailyLim   = request.getParameter("daily_limit")    != null ? request.getParameter("daily_limit")    : (acc.get("daily_limit")    != null ? acc.get("daily_limit").toString()    : "");
    String valMonthlyLim = request.getParameter("monthly_limit")  != null ? request.getParameter("monthly_limit")  : (acc.get("monthly_limit")  != null ? acc.get("monthly_limit").toString()  : "");
    String valIntRate    = request.getParameter("interest_rate")  != null ? request.getParameter("interest_rate")  : (acc.get("interest_rate")  != null ? acc.get("interest_rate").toString()  : "");
%>
<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Tahrirlash — ${a.account_number}"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Hisob tahrirlash</h1>
    <a href="account-detail.jsp?id=<%= accountId %>" class="btn">Bekor qilish</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><c:out value="${errorMsg}"/></div>
<% } %>

<!-- O'zgartib bo'lmaydigan ma'lumotlar -->
<div class="card">
    <div class="card-title">Asosiy ma'lumotlar (o'zgartib bo'lmaydi)</div>
    <dl class="detail-grid-wide">
        <dt>Hisob raqami</dt>
        <dd><strong><c:out value="${a.account_number}"/></strong></dd>
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
        <dt>Holat</dt>
        <dd><span class="badge badge-${a.status == 'ACTIVE' ? 'active' : a.status == 'PENDING' ? 'pending' : 'blocked'}"><c:out value="${a.status}"/></span></dd>
        <dt>Filial</dt>
        <dd><c:out value="${a.branch_code}"/></dd>
    </dl>
</div>

<!-- Tahrirlash formasi -->
<form method="post" data-validate>
    <input type="hidden" name="account_id" value="<%= accountId %>">

    <div class="form-section">
        <div class="form-section-title">Tahrirlash mumkin bo'lgan maydonlar</div>
        <div class="form-row">
            <div class="form-group">
                <label for="account_name">Hisob nomi</label>
                <input type="text" id="account_name" name="account_name" class="form-control"
                       value="<%= valName %>">
            </div>
            <div class="form-group">
                <label for="interest_rate">Foiz stavkasi (%)</label>
                <input type="number" id="interest_rate" name="interest_rate" class="form-control"
                       step="0.01" min="0" max="100"
                       value="<%= valIntRate %>">
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="min_balance">Minimal qoldiq</label>
                <input type="number" id="min_balance" name="min_balance" class="form-control"
                       step="0.01" min="0"
                       value="<%= valMinBal %>">
            </div>
            <div class="form-group">
                <label for="daily_limit">Kunlik limit</label>
                <input type="number" id="daily_limit" name="daily_limit" class="form-control"
                       step="0.01" min="0" placeholder="Bo'sh = cheklovsiz"
                       value="<%= valDailyLim %>">
            </div>
            <div class="form-group">
                <label for="monthly_limit">Oylik limit</label>
                <input type="number" id="monthly_limit" name="monthly_limit" class="form-control"
                       step="0.01" min="0" placeholder="Bo'sh = cheklovsiz"
                       value="<%= valMonthlyLim %>">
            </div>
        </div>
    </div>

    <div class="form-row">
        <div class="form-group">
            <label for="updated_by">Operator *</label>
            <input type="text" id="updated_by" name="updated_by" class="form-control" required value="OPERATOR">
        </div>
        <div></div>
    </div>

    <div style="margin-top:1rem;">
        <button type="submit" class="btn btn-primary">Saqlash</button>
        <a href="account-detail.jsp?id=<%= accountId %>" class="btn" style="margin-left:.5rem;">Bekor qilish</a>
    </div>
</form>

<jsp:include page="acc-footer.jsp"/>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  MARS ABS - ACC Yangi hisob ochish
  Procedure: core_acc_service.Open_Account (record IN OUT)
  Customers: core_cif_active_customers_ui_v
--%>
<%
    // ---- POST: Hisob ochish ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String customerIdStr = request.getParameter("customer_id");
        String accountType   = request.getParameter("account_type");
        String currency      = request.getParameter("currency");
        String accountName   = request.getParameter("account_name");
        String minBalStr     = request.getParameter("min_balance");
        String dailyLimStr   = request.getParameter("daily_limit");
        String monthlyLimStr = request.getParameter("monthly_limit");
        String intRateStr    = request.getParameter("interest_rate");
        String branchCode    = request.getParameter("branch_code");
        String createdBy     = request.getParameter("created_by");

        if (branchCode == null || branchCode.isEmpty()) branchCode = "00191";
        if (createdBy == null || createdBy.isEmpty()) createdBy = "OPERATOR";

        try {
            long customerId = Long.parseLong(customerIdStr);
            java.math.BigDecimal minBal     = (minBalStr    != null && !minBalStr.isEmpty())     ? new java.math.BigDecimal(minBalStr)     : java.math.BigDecimal.ZERO;
            java.math.BigDecimal dailyLim   = (dailyLimStr  != null && !dailyLimStr.isEmpty())   ? new java.math.BigDecimal(dailyLimStr)   : null;
            java.math.BigDecimal monthlyLim = (monthlyLimStr!= null && !monthlyLimStr.isEmpty()) ? new java.math.BigDecimal(monthlyLimStr) : null;
            java.math.BigDecimal intRate    = (intRateStr   != null && !intRateStr.isEmpty())    ? new java.math.BigDecimal(intRateStr)    : java.math.BigDecimal.ZERO;

            java.util.Map<String,Object> result = Mars.procedure("core_acc_service.Open_Account")
                .record("io_account", "core_acc_types.t_account_rec")
                    .field("customer_id",   customerId)
                    .field("account_type",  accountType)
                    .field("currency",      currency)
                    .field("account_name",  accountName)
                    .field("min_balance",   minBal.toPlainString())
                    .field("daily_limit",   dailyLim != null ? dailyLim.toPlainString() : null)
                    .field("monthly_limit", monthlyLim != null ? monthlyLim.toPlainString() : null)
                    .field("interest_rate", intRate.toPlainString())
                    .field("branch_code",   branchCode)
                    .field("created_by",    createdBy)
                    .outField("account_id",     Types.NUMERIC)
                    .outField("account_number", Types.VARCHAR)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

            int code = ((Number) result.get("o_code")).intValue();
            String message = (String) result.get("o_message");

            if (code == 0) {
                long newId = ((Number) result.get("account_id")).longValue();
                String accNum = (String) result.get("account_number");
                response.sendRedirect("account-detail.jsp?id=" + newId
                    + "&msg=" + java.net.URLEncoder.encode("Hisob ochildi: " + accNum, "UTF-8"));
                return;
            } else {
                request.setAttribute("errorMsg", message);
            }
        } catch (Exception e) {
            request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
        }
    }

    // Faol mijozlar ro'yxatini yuklash
    java.util.List<java.util.Map<String,Object>> customers = new java.util.ArrayList<>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();
        ps = conn.prepareStatement(
            "SELECT customer_id, cif_number, display_name FROM core_cif_active_customers_ui_v ORDER BY display_name"
        );
        rs = ps.executeQuery();
        while (rs.next()) {
            java.util.Map<String,Object> row = new java.util.LinkedHashMap<>();
            row.put("customer_id",  rs.getLong("customer_id"));
            row.put("cif_number",   rs.getString("cif_number"));
            row.put("display_name", rs.getString("display_name"));
            customers.add(row);
        }
    } finally {
        if (rs  != null) try { rs.close();   } catch (Exception e) {}
        if (ps  != null) try { ps.close();   } catch (Exception e) {}
        if (conn!= null) try { conn.close(); } catch (Exception e) {}
    }
    request.setAttribute("customers", customers);

    String selCustomerId = request.getParameter("customer_id");
%>
<jsp:include page="acc-header.jsp">
    <jsp:param name="title" value="Yangi hisob"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi hisob ochish</h1>
    <a href="${pageContext.request.contextPath}/abs/acc/account-list.jsp" class="btn">Ortga</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><c:out value="${errorMsg}"/></div>
<% } %>

<form method="post" data-validate>

    <div class="form-section">
        <div class="form-section-title">Mijoz va hisob turi</div>
        <div class="form-row">
            <div class="form-group">
                <label for="customer_id">Mijoz * (faqat faol)</label>
                <select id="customer_id" name="customer_id" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <c:forEach var="cust" items="${customers}">
                        <option value="${cust.customer_id}"
                            <c:if test="${cust.customer_id == param.customer_id}">selected</c:if>>
                            <c:out value="${cust.display_name}"/> (<c:out value="${cust.cif_number}"/>)
                        </option>
                    </c:forEach>
                </select>
            </div>
            <div class="form-group">
                <label for="account_type">Hisob turi *</label>
                <select id="account_type" name="account_type" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="CURRENT"  <%= "CURRENT".equals(request.getParameter("account_type"))  ? "selected" : "" %>>Joriy</option>
                    <option value="SAVINGS"  <%= "SAVINGS".equals(request.getParameter("account_type"))  ? "selected" : "" %>>Jamg'arma</option>
                    <option value="DEPOSIT"  <%= "DEPOSIT".equals(request.getParameter("account_type"))  ? "selected" : "" %>>Depozit</option>
                    <option value="LOAN"     <%= "LOAN".equals(request.getParameter("account_type"))     ? "selected" : "" %>>Kredit</option>
                    <option value="SPECIAL"  <%= "SPECIAL".equals(request.getParameter("account_type"))  ? "selected" : "" %>>Maxsus</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="currency">Valyuta *</label>
                <select id="currency" name="currency" class="form-control" required>
                    <option value="UZS" <%= "UZS".equals(request.getParameter("currency")) || request.getParameter("currency") == null ? "selected" : "" %>>UZS</option>
                    <option value="USD" <%= "USD".equals(request.getParameter("currency")) ? "selected" : "" %>>USD</option>
                    <option value="EUR" <%= "EUR".equals(request.getParameter("currency")) ? "selected" : "" %>>EUR</option>
                </select>
            </div>
            <div class="form-group">
                <label for="account_name">Hisob nomi</label>
                <input type="text" id="account_name" name="account_name" class="form-control"
                       placeholder="masalan: Asosiy joriy hisob"
                       value="<%= request.getParameter("account_name") != null ? request.getParameter("account_name") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Limitlar va foiz</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="min_balance">Minimal qoldiq</label>
                <input type="number" id="min_balance" name="min_balance" class="form-control"
                       step="0.01" min="0" placeholder="0.00"
                       value="<%= request.getParameter("min_balance") != null ? request.getParameter("min_balance") : "" %>">
            </div>
            <div class="form-group">
                <label for="daily_limit">Kunlik limit</label>
                <input type="number" id="daily_limit" name="daily_limit" class="form-control"
                       step="0.01" min="0" placeholder="Cheklovsiz"
                       value="<%= request.getParameter("daily_limit") != null ? request.getParameter("daily_limit") : "" %>">
            </div>
            <div class="form-group">
                <label for="monthly_limit">Oylik limit</label>
                <input type="number" id="monthly_limit" name="monthly_limit" class="form-control"
                       step="0.01" min="0" placeholder="Cheklovsiz"
                       value="<%= request.getParameter("monthly_limit") != null ? request.getParameter("monthly_limit") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="interest_rate">Foiz stavkasi (%)</label>
                <input type="number" id="interest_rate" name="interest_rate" class="form-control"
                       step="0.01" min="0" max="100" placeholder="0.00"
                       value="<%= request.getParameter("interest_rate") != null ? request.getParameter("interest_rate") : "" %>">
            </div>
            <div></div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Filial va operator</div>
        <div class="form-row">
            <div class="form-group">
                <label for="branch_code">Filial kodi *</label>
                <input type="text" id="branch_code" name="branch_code" class="form-control" required
                       value="<%= request.getParameter("branch_code") != null ? request.getParameter("branch_code") : "00191" %>">
            </div>
            <div class="form-group">
                <label for="created_by">Operator *</label>
                <input type="text" id="created_by" name="created_by" class="form-control" required
                       value="<%= request.getParameter("created_by") != null ? request.getParameter("created_by") : "OPERATOR" %>">
            </div>
        </div>
    </div>

    <%-- Eslatma: Imzo huquqlari (signatories) bu MVP versiyada kiritilmaydi. --%>
    <%-- Keyingi iteratsiyada core_acc_signatories jadvaliga tegishli forma qo'shiladi. --%>

    <div style="margin-top:1rem;">
        <button type="submit" class="btn btn-primary">Hisob ochish</button>
        <a href="${pageContext.request.contextPath}/abs/acc/account-list.jsp" class="btn" style="margin-left:.5rem;">Bekor qilish</a>
    </div>
</form>

<jsp:include page="acc-footer.jsp"/>

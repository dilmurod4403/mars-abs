<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Yangi hisob"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi hisob ochish</h1>
</div>

<div class="card">
    <form method="post" action="${pageContext.request.contextPath}/accounts">

        <div class="form-group">
            <label for="customerId">Mijoz</label>
            <select id="customerId" name="customerId" class="form-control" required>
                <option value="">-- Mijozni tanlang --</option>
                <c:forEach var="c" items="${customers}">
                    <option value="${c.customerId}">${c.fullName} (${c.passportNum})</option>
                </c:forEach>
            </select>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="accountNum">Hisob raqami</label>
                <input type="text" id="accountNum" name="accountNum" class="form-control"
                       required placeholder="86001001000001">
            </div>
            <div class="form-group">
                <label for="accountType">Hisob turi</label>
                <select id="accountType" name="accountType" class="form-control" required>
                    <option value="CHECKING">Joriy (CHECKING)</option>
                    <option value="SAVINGS">Jamg'arma (SAVINGS)</option>
                    <option value="DEPOSIT">Depozit (DEPOSIT)</option>
                </select>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="currency">Valyuta</label>
                <select id="currency" name="currency" class="form-control" required>
                    <option value="UZS">UZS - O'zbek so'mi</option>
                    <option value="USD">USD - AQSH dollari</option>
                    <option value="EUR">EUR - Yevro</option>
                </select>
            </div>
            <div class="form-group">
                <label for="balance">Boshlang'ich balans</label>
                <input type="number" id="balance" name="balance" class="form-control"
                       step="0.01" min="0" value="0">
            </div>
        </div>

        <div style="margin-top: 1rem;">
            <button type="submit" class="btn btn-primary">Hisob ochish</button>
            <a href="${pageContext.request.contextPath}/accounts" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
        </div>
    </form>
</div>

<jsp:include page="footer.jsp"/>

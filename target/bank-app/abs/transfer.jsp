<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="O'tkazma"/>
    <jsp:param name="page" value="transfer"/>
</jsp:include>

<div class="page-header">
    <h1>Pul o'tkazma</h1>
</div>

<c:if test="${not empty error}">
    <div class="alert alert-danger">${error}</div>
</c:if>

<div class="card">
    <form method="post" action="${pageContext.request.contextPath}/transfer">

        <div class="form-row">
            <div class="form-group">
                <label for="fromAccount">Qaysi hisobdan</label>
                <select id="fromAccount" name="fromAccount" class="form-control" required>
                    <option value="">-- Tanlang --</option>
                    <c:forEach var="a" items="${accounts}">
                        <option value="${a.accountId}" ${param.from == a.accountId ? 'selected' : ''}>
                            ${a.accountNum} — ${a.customerName}
                            (<fmt:formatNumber value="${a.balance}" type="number" groupingUsed="true" minFractionDigits="2"/> ${a.currency})
                        </option>
                    </c:forEach>
                </select>
            </div>
            <div class="form-group">
                <label for="toAccount">Qaysi hisobga</label>
                <select id="toAccount" name="toAccount" class="form-control" required>
                    <option value="">-- Tanlang --</option>
                    <c:forEach var="a" items="${accounts}">
                        <option value="${a.accountId}">
                            ${a.accountNum} — ${a.customerName} (${a.currency})
                        </option>
                    </c:forEach>
                </select>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="amount">Summa</label>
                <input type="number" id="amount" name="amount" class="form-control"
                       step="0.01" min="0.01" required placeholder="1000000">
            </div>
            <div class="form-group">
                <label for="description">Izoh</label>
                <input type="text" id="description" name="description" class="form-control"
                       placeholder="O'tkazma maqsadi">
            </div>
        </div>

        <div style="margin-top: 1rem;">
            <button type="submit" class="btn btn-success">O'tkazma qilish</button>
            <a href="${pageContext.request.contextPath}/" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
        </div>
    </form>
</div>

<jsp:include page="footer.jsp"/>

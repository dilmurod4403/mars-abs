<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Hisob: ${account.accountNum}"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<c:if test="${not empty sessionScope.success}">
    <div class="alert alert-success">${sessionScope.success}</div>
    <c:remove var="success" scope="session"/>
</c:if>

<div class="page-header">
    <h1>Hisob: ${account.accountNum}</h1>
    <a href="${pageContext.request.contextPath}/transfer?from=${account.accountId}" class="btn btn-success">O'tkazma qilish</a>
</div>

<div class="card">
    <div class="card-title">Hisob ma'lumotlari</div>
    <dl class="detail-grid">
        <dt>Hisob raqami</dt>
        <dd>${account.accountNum}</dd>
        <dt>Mijoz</dt>
        <dd>${account.customerName}</dd>
        <dt>Turi</dt>
        <dd>${account.accountType}</dd>
        <dt>Valyuta</dt>
        <dd>${account.currency}</dd>
        <dt>Balans</dt>
        <dd class="amount" style="font-size: 1.25rem;">
            <fmt:formatNumber value="${account.balance}" type="number" groupingUsed="true" minFractionDigits="2"/>
            ${account.currency}
        </dd>
        <dt>Ochilgan sana</dt>
        <dd>${account.openedAt}</dd>
        <dt>Holat</dt>
        <dd>
            <span class="badge badge-${account.status == 'ACTIVE' ? 'active' : account.status == 'FROZEN' ? 'frozen' : 'closed'}">
                ${account.status}
            </span>
        </dd>
    </dl>
</div>

<div class="card">
    <div class="card-title">Tranzaksiyalar tarixi</div>
    <c:choose>
        <c:when test="${not empty transactions}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Tur</th>
                            <th>Kimdan</th>
                            <th>Kimga</th>
                            <th>Summa</th>
                            <th>Izoh</th>
                            <th>Sana</th>
                            <th>Holat</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="t" items="${transactions}">
                            <tr>
                                <td>${t.txnId}</td>
                                <td>
                                    <span class="badge badge-${t.txnType == 'TRANSFER' ? 'transfer' : t.txnType == 'DEPOSIT' ? 'deposit' : 'withdrawal'}">
                                        ${t.txnType}
                                    </span>
                                </td>
                                <td>${t.fromAccountNum != null ? t.fromAccountNum : '—'}</td>
                                <td>${t.toAccountNum != null ? t.toAccountNum : '—'}</td>
                                <td class="amount">
                                    <fmt:formatNumber value="${t.amount}" type="number" groupingUsed="true" minFractionDigits="2"/>
                                    ${t.currency}
                                </td>
                                <td>${t.description}</td>
                                <td>${t.txnDate}</td>
                                <td>
                                    <span class="badge badge-active">${t.status}</span>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <p style="color: var(--gray-500);">Tranzaksiya topilmadi.</p>
        </c:otherwise>
    </c:choose>
</div>

<jsp:include page="footer.jsp"/>

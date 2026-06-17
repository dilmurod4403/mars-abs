<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Bosh sahifa"/>
    <jsp:param name="page" value="dashboard"/>
</jsp:include>

<div class="page-header">
    <h1>Boshqaruv paneli</h1>
</div>

<div class="stats-grid">
    <div class="stat-card">
        <div class="label">Jami mijozlar</div>
        <div class="value">${customers.size()}</div>
    </div>
    <div class="stat-card">
        <div class="label">Jami hisoblar</div>
        <div class="value">${accounts.size()}</div>
    </div>
    <div class="stat-card">
        <div class="label">Tranzaksiyalar</div>
        <div class="value">${transactions.size()}</div>
    </div>
</div>

<div class="card">
    <div class="card-title">So'nggi tranzaksiyalar</div>
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
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="footer.jsp"/>

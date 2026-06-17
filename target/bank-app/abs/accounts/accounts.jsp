<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Hisoblar"/>
    <jsp:param name="page" value="accounts"/>
</jsp:include>

<div class="page-header">
    <h1>Hisoblar ro'yxati</h1>
    <a href="${pageContext.request.contextPath}/accounts/new" class="btn btn-primary">+ Yangi hisob</a>
</div>

<div class="card">
    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Hisob raqami</th>
                    <th>Mijoz</th>
                    <th>Turi</th>
                    <th>Valyuta</th>
                    <th>Balans</th>
                    <th>Holat</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="a" items="${accounts}">
                    <tr>
                        <td>
                            <a href="${pageContext.request.contextPath}/accounts/${a.accountId}" class="link">
                                ${a.accountNum}
                            </a>
                        </td>
                        <td>${a.customerName}</td>
                        <td>${a.accountType}</td>
                        <td>${a.currency}</td>
                        <td class="amount">
                            <fmt:formatNumber value="${a.balance}" type="number" groupingUsed="true" minFractionDigits="2"/>
                        </td>
                        <td>
                            <span class="badge badge-${a.status == 'ACTIVE' ? 'active' : a.status == 'FROZEN' ? 'frozen' : 'closed'}">
                                ${a.status}
                            </span>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="footer.jsp"/>

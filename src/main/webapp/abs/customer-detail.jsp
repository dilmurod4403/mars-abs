<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="${customer.fullName}"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>${customer.fullName}</h1>
    <a href="${pageContext.request.contextPath}/customers/${customer.customerId}/edit" class="btn btn-primary">Tahrirlash</a>
</div>

<div class="card">
    <div class="card-title">Mijoz ma'lumotlari</div>
    <dl class="detail-grid">
        <dt>ID</dt>
        <dd>${customer.customerId}</dd>
        <dt>F.I.O.</dt>
        <dd>${customer.fullName}</dd>
        <dt>Telefon</dt>
        <dd>${customer.phone}</dd>
        <dt>Email</dt>
        <dd>${customer.email}</dd>
        <dt>Pasport</dt>
        <dd>${customer.passportNum}</dd>
        <dt>Tug'ilgan sana</dt>
        <dd>${customer.birthDate}</dd>
        <dt>Manzil</dt>
        <dd>${customer.address}</dd>
        <dt>Holat</dt>
        <dd>
            <span class="badge badge-${customer.status == 'ACTIVE' ? 'active' : customer.status == 'BLOCKED' ? 'blocked' : 'closed'}">
                ${customer.status}
            </span>
        </dd>
        <dt>Ro'yxatdan o'tgan</dt>
        <dd>${customer.createdAt}</dd>
    </dl>
</div>

<div class="card">
    <div class="card-title">Hisoblar</div>
    <c:choose>
        <c:when test="${not empty accounts}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Hisob raqami</th>
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
        </c:when>
        <c:otherwise>
            <p style="color: var(--gray-500);">Hisob topilmadi.</p>
        </c:otherwise>
    </c:choose>
</div>

<jsp:include page="footer.jsp"/>

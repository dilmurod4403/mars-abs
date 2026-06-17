<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="${customer != null ? 'Mijozni tahrirlash' : 'Yangi mijoz'}"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>${customer != null ? 'Mijozni tahrirlash' : 'Yangi mijoz qo\'shish'}</h1>
</div>

<div class="card">
    <form method="post"
          action="${pageContext.request.contextPath}/customers${customer != null ? '/'.concat(customer.customerId) : ''}">

        <div class="form-row">
            <div class="form-group">
                <label for="firstName">Ism</label>
                <input type="text" id="firstName" name="firstName" class="form-control"
                       value="${customer.firstName}" required>
            </div>
            <div class="form-group">
                <label for="lastName">Familiya</label>
                <input type="text" id="lastName" name="lastName" class="form-control"
                       value="${customer.lastName}" required>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="phone">Telefon</label>
                <input type="tel" id="phone" name="phone" class="form-control"
                       value="${customer.phone}" placeholder="+998901234567">
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" class="form-control"
                       value="${customer.email}">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="passportNum">Pasport raqami</label>
                <input type="text" id="passportNum" name="passportNum" class="form-control"
                       value="${customer.passportNum}" required placeholder="AA1234567">
            </div>
            <div class="form-group">
                <label for="birthDate">Tug'ilgan sana</label>
                <input type="date" id="birthDate" name="birthDate" class="form-control"
                       value="${customer.birthDate}">
            </div>
        </div>

        <div class="form-group">
            <label for="address">Manzil</label>
            <input type="text" id="address" name="address" class="form-control"
                   value="${customer.address}">
        </div>

        <c:if test="${customer != null}">
            <div class="form-group">
                <label for="status">Holat</label>
                <select id="status" name="status" class="form-control">
                    <option value="ACTIVE" ${customer.status == 'ACTIVE' ? 'selected' : ''}>Faol</option>
                    <option value="BLOCKED" ${customer.status == 'BLOCKED' ? 'selected' : ''}>Bloklangan</option>
                    <option value="CLOSED" ${customer.status == 'CLOSED' ? 'selected' : ''}>Yopilgan</option>
                </select>
            </div>
        </c:if>

        <div style="margin-top: 1rem;">
            <button type="submit" class="btn btn-primary">
                ${customer != null ? 'Saqlash' : 'Qo\'shish'}
            </button>
            <a href="${pageContext.request.contextPath}/customers" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
        </div>
    </form>
</div>

<jsp:include page="footer.jsp"/>

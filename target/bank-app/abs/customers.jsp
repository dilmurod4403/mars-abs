<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Mijozlar"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>Mijozlar ro'yxati</h1>
    <a href="${pageContext.request.contextPath}/customers/new" class="btn btn-primary">+ Yangi mijoz</a>
</div>

<div class="card">
    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>F.I.O.</th>
                    <th>Telefon</th>
                    <th>Email</th>
                    <th>Pasport</th>
                    <th>Holat</th>
                    <th>Amallar</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="c" items="${customers}">
                    <tr>
                        <td>${c.customerId}</td>
                        <td>
                            <a href="${pageContext.request.contextPath}/customers/${c.customerId}" class="link">
                                ${c.fullName}
                            </a>
                        </td>
                        <td>${c.phone}</td>
                        <td>${c.email}</td>
                        <td>${c.passportNum}</td>
                        <td>
                            <span class="badge badge-${c.status == 'ACTIVE' ? 'active' : c.status == 'BLOCKED' ? 'blocked' : 'closed'}">
                                ${c.status}
                            </span>
                        </td>
                        <td>
                            <a href="${pageContext.request.contextPath}/customers/${c.customerId}/edit" class="btn btn-sm btn-primary">Tahrirlash</a>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="footer.jsp"/>

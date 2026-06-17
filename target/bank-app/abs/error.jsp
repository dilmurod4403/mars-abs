<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<jsp:include page="header.jsp">
    <jsp:param name="title" value="Xatolik"/>
    <jsp:param name="page" value=""/>
</jsp:include>

<div class="card" style="text-align: center; padding: 3rem;">
    <h1 style="font-size: 3rem; color: var(--danger); margin-bottom: 0.5rem;">
        ${pageContext.errorData.statusCode}
    </h1>
    <p style="color: var(--gray-500); font-size: 1.1rem; margin-bottom: 1.5rem;">
        Kechirasiz, xatolik yuz berdi.
    </p>
    <a href="${pageContext.request.contextPath}/" class="btn btn-primary">Bosh sahifaga qaytish</a>
</div>

<jsp:include page="footer.jsp"/>

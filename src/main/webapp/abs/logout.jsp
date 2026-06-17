<%@ page contentType="text/html;charset=UTF-8" %>
<%
    session.invalidate();
    response.sendRedirect(request.getContextPath() + "/abs/login.jsp");
%>

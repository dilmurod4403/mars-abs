<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map, java.net.URLEncoder" %>
<%--
  MARS ABS - ACC Grid bulk amallari handler
  Datagrid bulk toolbar shu yerga POST qiladi.
  action=status → core_acc_service.Change_Status (har id uchun)
--%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("account-list.jsp");
        return;
    }

    String action   = request.getParameter("action");
    String idsParam = request.getParameter("ids");
    String status   = request.getParameter("status");

    // Joriy foydalanuvchi
    String currentUser = "OPERATOR";
    Object cu = session.getAttribute("currentUser");
    if (cu instanceof Map) {
        Object un = ((Map<?,?>) cu).get("username");
        if (un != null) currentUser = un.toString();
    }

    int ok = 0, fail = 0;
    String firstErr = null;

    if ("status".equals(action) && idsParam != null && status != null && !status.trim().isEmpty()) {
        for (String idStr : idsParam.split(",")) {
            idStr = idStr.trim();
            if (idStr.isEmpty()) continue;
            try {
                long id = Long.parseLong(idStr);
                Map<String,Object> r = Mars.procedure("core_acc_service.Change_Status")
                    .in("i_account_id", id)
                    .in("i_new_status",  status.trim())
                    .in("i_reason",      "Bulk amal")
                    .in("i_user",        currentUser)
                    .outNumber("o_code")
                    .outString("o_message")
                    .outString("o_ora_message")
                    .execute();
                Number code = (Number) r.get("o_code");
                if (code != null && code.intValue() == 0) {
                    ok++;
                } else {
                    fail++;
                    if (firstErr == null) firstErr = (String) r.get("o_message");
                }
            } catch (Exception e) {
                fail++;
                if (firstErr == null) firstErr = e.getMessage();
            }
        }
    } else {
        response.sendRedirect("account-list.jsp?err=" + URLEncoder.encode("Noto'g'ri so'rov", "UTF-8"));
        return;
    }

    String msg;
    boolean success = (fail == 0 && ok > 0);
    if (success) {
        msg = ok + " ta hisob statusi o'zgartirildi";
    } else if (ok > 0) {
        msg = ok + " ta o'zgartirildi, " + fail + " ta xato" + (firstErr != null ? ": " + firstErr : "");
    } else {
        msg = "Status o'zgartirib bo'lmadi" + (firstErr != null ? ": " + firstErr : "");
    }
    String key = success ? "msg=" : "err=";
    response.sendRedirect("account-list.jsp?" + key + URLEncoder.encode(msg, "UTF-8"));
%>

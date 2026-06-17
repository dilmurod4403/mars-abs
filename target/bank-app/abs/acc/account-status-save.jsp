<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map, java.net.URLEncoder" %>
<%--
  MARS ABS - ACC Holat o'zgartirish handler
  action=status   → core_acc_service.Change_Status(i_account_id, i_new_status, i_reason, i_user)
  action=approve  → core_acc_service.Approve_Account(i_account_id, i_approved_by)
  action=reject   → core_acc_service.Reject_Account(i_account_id, i_rejected_by, i_reason)
  action=close    → core_acc_service.Close_Account(i_account_id, i_reason, i_user)
  Muvaffaqiyat: account-detail.jsp?id=X&msg=... | Xato: account-detail.jsp?id=X&err=...
--%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("account-list.jsp");
        return;
    }

    String action    = request.getParameter("action");
    String idStr     = request.getParameter("id");
    if (idStr == null || idStr.isEmpty() || action == null) {
        response.sendRedirect("account-list.jsp?err=" + URLEncoder.encode("Noto'g'ri so'rov", "UTF-8"));
        return;
    }

    long accountId = Long.parseLong(idStr);
    String redirectBase = "account-detail.jsp?id=" + accountId;

    try {
        Map<String,Object> result;

        if ("approve".equals(action)) {
            String approvedBy = request.getParameter("approved_by");
            if (approvedBy == null || approvedBy.isEmpty()) approvedBy = "SUPERVISOR";
            result = Mars.procedure("core_acc_service.Approve_Account")
                .in("i_account_id", accountId)
                .in("i_approved_by", approvedBy)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

        } else if ("reject".equals(action)) {
            String rejectedBy = request.getParameter("rejected_by");
            String reason     = request.getParameter("reason");
            if (rejectedBy == null || rejectedBy.isEmpty()) rejectedBy = "SUPERVISOR";
            if (reason     == null) reason = "";
            result = Mars.procedure("core_acc_service.Reject_Account")
                .in("i_account_id",  accountId)
                .in("i_rejected_by", rejectedBy)
                .in("i_reason",      reason)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

        } else if ("close".equals(action)) {
            String reason  = request.getParameter("reason");
            String user    = request.getParameter("changed_by");
            if (user   == null || user.isEmpty())   user   = "OPERATOR";
            if (reason == null) reason = "";
            result = Mars.procedure("core_acc_service.Close_Account")
                .in("i_account_id", accountId)
                .in("i_reason",     reason)
                .in("i_user",       user)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

        } else {
            // action=status (FROZEN, BLOCKED, ACTIVE ...)
            String newStatus = request.getParameter("status");
            String reason    = request.getParameter("reason");
            String user      = request.getParameter("changed_by");
            if (user   == null || user.isEmpty())   user   = "OPERATOR";
            if (reason == null) reason = "";
            result = Mars.procedure("core_acc_service.Change_Status")
                .in("i_account_id", accountId)
                .in("i_new_status", newStatus)
                .in("i_reason",     reason)
                .in("i_user",       user)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();
        }

        int code     = ((Number) result.get("o_code")).intValue();
        String message = (String) result.get("o_message");

        if (code == 0) {
            String label;
            if      ("approve".equals(action)) label = "Hisob tasdiqlandi";
            else if ("reject".equals(action))  label = "Hisob rad etildi";
            else if ("close".equals(action))   label = "Hisob yopildi";
            else                               label = "Holat o'zgartirildi";
            response.sendRedirect(redirectBase + "&msg=" + URLEncoder.encode(label, "UTF-8"));
        } else {
            // Maker-checker xatosi -20107
            String errMsg = message != null ? message : "Noma'lum xato";
            response.sendRedirect(redirectBase + "&err=" + URLEncoder.encode(errMsg, "UTF-8"));
        }

    } catch (Exception e) {
        response.sendRedirect(redirectBase + "&err=" + URLEncoder.encode("Xatolik: " + e.getMessage(), "UTF-8"));
    }
%>

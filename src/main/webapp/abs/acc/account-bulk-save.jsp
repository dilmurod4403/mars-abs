<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map" %>
<%--
  MARS ABS — REAL SIRIUS: Hisoblarni ommaviy TASDIQLASH handler (Maker-Checker)
  POST parametrlar: action=status, ids=1,2,3, status=APPROVED
  Procedure: core_acc_service.Approve_Account(i_account_id, i_checker_user, o_code, o_message, o_ora_message)
  Eslatma: faqat APPROVED (Maker<>Checker) — reject alohida oqim.
  Response: JSON { ok: true|false, message: "..." }
--%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(405);
        out.print("{\"ok\":false,\"message\":\"Faqat POST\"}");
        return;
    }

    String action = request.getParameter("action");
    String idsRaw = request.getParameter("ids");
    String status = request.getParameter("status");

    if (!"status".equals(action) || idsRaw == null || idsRaw.isEmpty()
            || status == null || status.isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"message\":\"Parametr xatosi\"}");
        return;
    }

    // Real SIRIUS modelda bulk orqali faqat APPROVED (tasdiqlash)
    if (!"APPROVED".equals(status)) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"message\":\"Faqat APPROVED (tasdiqlash) qo'llab-quvvatlanadi\"}");
        return;
    }

    // checker_user — session dan, yo'q bo'lsa 101
    long checkerUser = 101L;
    try {
        Object sessionUser = session.getAttribute("currentUser");
        if (sessionUser != null) {
            java.lang.reflect.Method m = sessionUser.getClass().getMethod("getId");
            checkerUser = ((Number) m.invoke(sessionUser)).longValue();
        }
    } catch (Exception ignored) {}

    String[] ids = idsRaw.split(",");
    int successCount = 0;
    StringBuilder errors = new StringBuilder();

    for (String idStr : ids) {
        idStr = idStr.trim();
        if (idStr.isEmpty()) continue;
        try {
            long accountId = Long.parseLong(idStr);
            Map<String, Object> res = Mars.procedure("core_acc_service.Approve_Account")
                .in("i_account_id",   accountId)
                .in("i_checker_user", checkerUser)
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message")
                .execute();

            long code = ((Number) res.get("o_code")).longValue();
            if (code == 0) {
                successCount++;
            } else {
                String msg = (String) res.get("o_message");
                if (errors.length() > 0) errors.append("; ");
                errors.append("ID ").append(idStr).append(": ").append(msg);
            }
        } catch (NumberFormatException e) {
            if (errors.length() > 0) errors.append("; ");
            errors.append("Noto'g'ri ID: ").append(idStr);
        } catch (Exception e) {
            if (errors.length() > 0) errors.append("; ");
            errors.append("ID ").append(idStr).append(": ").append(e.getMessage());
        }
    }

    if (errors.length() == 0) {
        out.print("{\"ok\":true,\"message\":\"" + successCount + " ta hisob tasdiqlandi\"}");
    } else if (successCount > 0) {
        String errJson = errors.toString().replace("\\", "\\\\").replace("\"", "\\\"");
        out.print("{\"ok\":true,\"message\":\"" + successCount + " ta tasdiqlandi. Xatolar: " + errJson + "\"}");
    } else {
        String errJson = errors.toString().replace("\\", "\\\\").replace("\"", "\\\"");
        out.print("{\"ok\":false,\"message\":\"" + errJson + "\"}");
    }
%>

<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map" %>
<%--
  MARS ABS — REAL SIRIUS: Klientlarni ommaviy TASDIQLASH handler (Maker-Checker)
  POST parametrlar: action=status, ids=1,2,3, status=APPROVED
  Procedure: core_cif_service.Approve_Client(i_client_id, i_checker_user, o_code, o_message, o_ora_message)
  Eslatma: real SIRIUS modelda "reject" holati YO'Q — faqat APPROVED (Maker<>Checker, AML/НИББД gate).
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

    if (!"status".equals(action) || idsRaw == null || idsRaw.isEmpty() || status == null || status.isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"message\":\"Parametr xatosi\"}");
        return;
    }
    // Real modelda faqat APPROVED (tasdiqlash, Maker-Checker) — reject holati yo'q
    if (!"APPROVED".equals(status)) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"message\":\"Faqat APPROVED (tasdiqlash) qo'llab-quvvatlanadi\"}");
        return;
    }

    // maker_user — session dan, yo'q bo'lsa demo 101
    long makerUser = 101L;
    try {
        Object sessionUser = session.getAttribute("currentUser");
        if (sessionUser != null) {
            java.lang.reflect.Method m = sessionUser.getClass().getMethod("getId");
            makerUser = ((Number) m.invoke(sessionUser)).longValue();
        }
    } catch (Exception ignored) { /* default 101 */ }

    String[] ids = idsRaw.split(",");
    int successCount = 0;
    StringBuilder errors = new StringBuilder();

    for (String idStr : ids) {
        idStr = idStr.trim();
        if (idStr.isEmpty()) continue;
        try {
            long clientId = Long.parseLong(idStr);
            Map<String, Object> res = Mars.procedure("core_cif_service.Approve_Client")
                .in("i_client_id",    clientId)
                .in("i_checker_user", makerUser)
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
        out.print("{\"ok\":true,\"message\":\"" + successCount + " ta klient yangilandi\"}");
    } else if (successCount > 0) {
        String errJson = errors.toString().replace("\"", "\\\"");
        out.print("{\"ok\":true,\"message\":\"" + successCount + " ta yangilandi. Xatolar: " + errJson + "\"}");
    } else {
        String errJson = errors.toString().replace("\"", "\\\"");
        out.print("{\"ok\":false,\"message\":\"" + errJson + "\"}");
    }
%>

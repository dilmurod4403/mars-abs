<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map" %>
<%--
  MARS ABS — Hisob holat boshqaruvi handler
  POST: account_id (long), new_state (VARCHAR2)
  Procedure: core_acc_service.Change_Account_State(
      i_account_id, i_new_state, i_user, o_code, o_message, o_ora_message)
  Holat matritsasi:
    APPROVED  -> BLOCKED | TEMP_CLOSED | CLOSED
    BLOCKED   -> APPROVED | CLOSED
    TEMP_CLOSED -> APPROVED | BLOCKED | CLOSED
    CLOSED    -> terminal (tugma ko'rsatilmaydi)
  Muvaffaqiyat: account-detail.jsp?id={id}&msg=... ga redirect
  Xatolik:     account-detail.jsp?id={id}&err=... ga redirect
  abs-modal.js redirect'ni ushlaydi va modalning o'zida ko'rsatadi.
--%>
<%
    /* ------------------------------------------------------------------ */
    /* 1. Faqat POST                                                       */
    /* ------------------------------------------------------------------ */
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendError(405, "Faqat POST");
        return;
    }

    /* ------------------------------------------------------------------ */
    /* 2. Parametrlarni o'qish                                             */
    /* ------------------------------------------------------------------ */
    String idParam       = request.getParameter("account_id");
    String newState      = request.getParameter("new_state");

    long accountId = -1L;
    if (idParam != null && !idParam.trim().isEmpty()) {
        try { accountId = Long.parseLong(idParam.trim()); }
        catch (NumberFormatException ignored) {}
    }

    if (accountId <= 0 || newState == null || newState.trim().isEmpty()) {
        response.sendRedirect(
            request.getContextPath() +
            "/abs/acc/account-detail.jsp?id=" + accountId +
            "&err=" + java.net.URLEncoder.encode("Noto'g'ri parametrlar", "UTF-8"));
        return;
    }

    newState = newState.trim();

    /* ------------------------------------------------------------------ */
    /* 3. Ruxsat etilgan holat kodlarini tekshirish                        */
    /* ------------------------------------------------------------------ */
    java.util.Set<String> allowed = new java.util.HashSet<>(
        java.util.Arrays.asList("APPROVED", "BLOCKED", "TEMP_CLOSED", "CLOSED"));
    if (!allowed.contains(newState)) {
        response.sendRedirect(
            request.getContextPath() +
            "/abs/acc/account-detail.jsp?id=" + accountId +
            "&err=" + java.net.URLEncoder.encode("Noto'g'ri holat kodi: " + newState, "UTF-8"));
        return;
    }

    /* ------------------------------------------------------------------ */
    /* 4. Session — checker user id                                        */
    /* ------------------------------------------------------------------ */
    long checkerUid = 101L;
    try {
        Object su = session.getAttribute("currentUser");
        if (su instanceof java.util.Map) {
            Object uid = ((java.util.Map<?, ?>) su).get("user_id");
            if (uid != null) checkerUid = ((Number) uid).longValue();
        }
    } catch (Exception ignored) { /* fallback 101 */ }

    /* ------------------------------------------------------------------ */
    /* 5. Procedure chaqiruv                                               */
    /* ------------------------------------------------------------------ */
    String redirectBase = request.getContextPath() +
        "/abs/acc/account-detail.jsp?id=" + accountId;

    try {
        Map<String, Object> res = Mars
            .procedure("core_acc_service.Change_Account_State")
            .in("i_account_id", accountId)
            .in("i_new_state",  newState)
            .in("i_user",       checkerUid)
            .outNumber("o_code")
            .outString("o_message")
            .outString("o_ora_message")
            .execute();

        long code = ((Number) res.get("o_code")).longValue();

        if (code == 0) {
            /* Muvaffaqiyat — state label ni o'zbek tilida ko'rsatish */
            String label;
            switch (newState) {
                case "APPROVED":   label = "Faollashtirish amalga oshirildi";  break;
                case "BLOCKED":    label = "Hisob bloklandi";                  break;
                case "TEMP_CLOSED":label = "Hisob vaqtincha yopildi";          break;
                case "CLOSED":     label = "Hisob yopildi";                    break;
                default:           label = "Holat o'zgartirildi";              break;
            }
            response.sendRedirect(redirectBase +
                "&msg=" + java.net.URLEncoder.encode(label, "UTF-8"));
        } else {
            String errMsg = (String) res.get("o_message");
            if (errMsg == null || errMsg.isEmpty()) {
                errMsg = "Noma'lum xatolik (kod: " + code + ")";
            }
            response.sendRedirect(redirectBase +
                "&err=" + java.net.URLEncoder.encode(errMsg, "UTF-8"));
        }
    } catch (Exception ex) {
        String errMsg = ex.getMessage();
        if (errMsg == null) errMsg = "Ichki xatolik";
        response.sendRedirect(redirectBase +
            "&err=" + java.net.URLEncoder.encode(errMsg, "UTF-8"));
    }
%>

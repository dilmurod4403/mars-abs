<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.Map" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  MARS ABS — REAL SIRIUS: Yangi klient ro'yxatga olish
  Procedure: core_cif_service.Register_Client
  Imzo: Register_Client(io_rec t_client_rec, o_client_id, o_client_code, o_code, o_message, o_ora_message)
  KIND: P=Jismoniy / J=Yuridik / I=YaTT-IP
--%>
<%
    // =====================================================================
    // POST: Register_Client chaqiruv
    // =====================================================================
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String kind       = request.getParameter("kind");         // P / J / I
        String clientType = request.getParameter("client_type");  // 01..13

        // Umumiy maydonlar
        String fullName        = request.getParameter("full_name");
        String inn             = request.getParameter("inn");
        String numRegistr      = request.getParameter("num_registr");
        String dateRegistrStr  = request.getParameter("date_registr");
        String countryRegistr  = request.getParameter("country_registr");
        if (countryRegistr == null || countryRegistr.isEmpty()) countryRegistr = "860";
        String oked            = request.getParameter("oked");

        // P (Jismoniy) maydonlari
        String lastName        = request.getParameter("last_name");
        String firstName       = request.getParameter("first_name");
        String lastNameLat     = request.getParameter("last_name_lat");
        String firstNameLat    = request.getParameter("first_name_lat");
        String genderStr       = request.getParameter("gender");
        String birthDateStr    = request.getParameter("birth_date");
        String docType         = request.getParameter("doc_type");
        String docSeries       = request.getParameter("doc_series");
        String docNumber       = request.getParameter("doc_number");
        String docIssueDateStr = request.getParameter("doc_issue_date");
        String pinfl           = request.getParameter("pinfl");

        // J/I (Yuridik / YaTT) maydonlari
        String orgName         = request.getParameter("org_name");
        String orgNameLat      = request.getParameter("org_name_lat");

        // I (YaTT) — IP shaxsiy ma'lumotlari
        String ipLastName        = request.getParameter("ip_last_name");
        String ipFirstName       = request.getParameter("ip_first_name");
        String ipLastNameLat     = request.getParameter("ip_last_name_lat");
        String ipFirstNameLat    = request.getParameter("ip_first_name_lat");
        String ipGenderStr       = request.getParameter("ip_gender");
        String ipDobStr          = request.getParameter("ip_dob");
        String ipDocType         = request.getParameter("ip_doc_type");
        String ipDocSerial       = request.getParameter("ip_doc_serial");
        String ipDocNumber       = request.getParameter("ip_doc_number");
        String ipDocIssueDateStr = request.getParameter("ip_doc_issue_date");
        String ipPinfl           = request.getParameter("ip_pinfl");

        // maker_user — session dan, yo'q bo'lsa demo 101
        long makerUser = 101L;
        try {
            Object sessionUser = session.getAttribute("currentUser");
            if (sessionUser != null) {
                Object uid = ((java.util.Map) sessionUser).get("user_id");
                if (uid != null) makerUser = ((Number) uid).longValue();
            }
        } catch (Exception ignored) { /* session user topilmadi, default 101 */ }

        try {
            // Tarixiy bo'sh qiymatlarni null ga o'girish
            if (fullName       != null && fullName.isEmpty())       fullName       = null;
            if (inn            != null && inn.isEmpty())            inn            = null;
            if (numRegistr     != null && numRegistr.isEmpty())     numRegistr     = null;
            if (dateRegistrStr != null && dateRegistrStr.isEmpty()) dateRegistrStr = null;
            if (oked           != null && oked.isEmpty())           oked           = null;
            if (orgName        != null && orgName.isEmpty())        orgName        = null;
            if (orgNameLat     != null && orgNameLat.isEmpty())     orgNameLat     = null;

            // gender: String -> long (1=erkak, 2=ayol)
            long genderVal   = (genderStr   != null && !genderStr.isEmpty())   ? Long.parseLong(genderStr)   : 0L;
            long ipGenderVal = (ipGenderStr != null && !ipGenderStr.isEmpty()) ? Long.parseLong(ipGenderStr) : 0L;

            // Bo'sh sana qiymatlarini null ga
            if (birthDateStr    != null && birthDateStr.isEmpty())    birthDateStr    = null;
            if (docIssueDateStr != null && docIssueDateStr.isEmpty()) docIssueDateStr = null;
            if (ipDobStr        != null && ipDobStr.isEmpty())        ipDobStr        = null;
            if (ipDocIssueDateStr != null && ipDocIssueDateStr.isEmpty()) ipDocIssueDateStr = null;

            Mars proc = Mars.procedure("core_cif_service.Register_Client")
                .record("v_rec", "core_cif_types.t_client_rec")
                    .field("client_kind",    kind)
                    .field("client_type",    clientType)
                    .field("full_name",      fullName)
                    // --- P (Jismoniy) ---
                    .field("last_name",      lastName)
                    .field("first_name",     firstName)
                    .field("last_name_lat",  lastNameLat)
                    .field("first_name_lat", firstNameLat)
                    .field("gender",         genderVal)
                    .fieldDate("birth_date",     birthDateStr,    "YYYY-MM-DD")
                    .field("doc_type",       docType)
                    .field("doc_series",     docSeries)
                    .field("doc_number",     docNumber)
                    .fieldDate("doc_issue_date", docIssueDateStr, "YYYY-MM-DD")
                    .field("pinfl",          pinfl)
                    // --- J/I (Yuridik / YaTT) ---
                    .field("org_name",       orgName)
                    .field("org_name_lat",   orgNameLat)
                    .field("inn",            inn)
                    .field("num_registr",    numRegistr)
                    .fieldDate("date_registr",   dateRegistrStr,  "YYYY-MM-DD")
                    .field("country_registr", countryRegistr)
                    .field("oked",           oked)
                    // --- I (YaTT) shaxsiy ---
                    .field("ip_last_name",       ipLastName)
                    .field("ip_first_name",      ipFirstName)
                    .field("ip_last_name_lat",   ipLastNameLat)
                    .field("ip_first_name_lat",  ipFirstNameLat)
                    .field("ip_gender",          ipGenderVal)
                    .fieldDate("ip_dob",             ipDobStr,            "YYYY-MM-DD")
                    .field("ip_doc_type",        ipDocType)
                    .field("ip_doc_serial",      ipDocSerial)
                    .field("ip_doc_number",      ipDocNumber)
                    .fieldDate("ip_doc_issue_date",  ipDocIssueDateStr,   "YYYY-MM-DD")
                    .field("ip_pinfl",           ipPinfl)
                    // --- maker ---
                    .field("maker_user",     makerUser)
                // OUT parametrlar — imzoga mos tartibda:
                // Register_Client(io_rec, o_client_id, o_client_code, o_code, o_message, o_ora_message)
                .outNumber("o_client_id")
                .outString("o_client_code")
                .outNumber("o_code")
                .outString("o_message")
                .outString("o_ora_message");

            Map<String, Object> res = proc.execute();

            long code = ((Number) res.get("o_code")).longValue();
            String message    = (String) res.get("o_message");
            String clientCode = (String) res.get("o_client_code");

            if (code == 0) {
                long newId = ((Number) res.get("o_client_id")).longValue();
                response.sendRedirect(request.getContextPath()
                    + "/abs/cif/client-list.jsp"
                    + "?msg=" + java.net.URLEncoder.encode("Klient ro'yxatga olindi: " + clientCode + " (ID " + newId + ")", "UTF-8"));
                return;
            } else {
                String oraMsg = (String) res.get("o_ora_message");
                request.setAttribute("errorMsg", message != null ? message : oraMsg);
                request.setAttribute("activeKind", kind);
            }
        } catch (Exception e) {
            request.setAttribute("errorMsg", "Tizim xatosi: " + e.getMessage());
            request.setAttribute("activeKind", kind);
        }
    }
    // GET yoki POST xato bo'lsa — formani ko'rsat
    String activeKind = (String) request.getAttribute("activeKind");
    if (activeKind == null) activeKind = request.getParameter("kind");
    if (activeKind == null) activeKind = "P";
    request.setAttribute("ak", activeKind);
%>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Yangi klient"/>
    <jsp:param name="page" value="clients"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi klient ro'yxatga olish</h1>
    <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="btn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Orqaga
    </a>
</div>

<c:if test="${not empty errorMsg}">
    <div class="alert alert-danger">${errorMsg}</div>
</c:if>

<%-- =================== KIND TABS =================== --%>
<div class="tabs" id="kind-tabs">
    <button type="button" class="tab-btn ${ak == 'P' ? 'active' : ''}"
            data-kind="P" onclick="switchKind('P')">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="7" r="4"/><path d="M5.5 21v-2a4 4 0 0 1 4-4h5a4 4 0 0 1 4 4v2"/></svg>
        Jismoniy shaxs (P)
    </button>
    <button type="button" class="tab-btn ${ak == 'J' ? 'active' : ''}"
            data-kind="J" onclick="switchKind('J')">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/><line x1="12" y1="12" x2="12" y2="16"/><line x1="10" y1="14" x2="14" y2="14"/></svg>
        Yuridik shaxs (J)
    </button>
    <button type="button" class="tab-btn ${ak == 'I' ? 'active' : ''}"
            data-kind="I" onclick="switchKind('I')">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="7" r="4"/><path d="M5.5 21v-2a4 4 0 0 1 4-4h5a4 4 0 0 1 4 4v2"/><path d="M19 11l2 2-2 2"/></svg>
        YaTT — IP (I)
    </button>
</div>

<%-- ================================================================
     PANEL P — Jismoniy shaxs
     ================================================================ --%>
<div id="panel-P" class="kind-panel" style="${ak == 'P' ? '' : 'display:none'}">
<form method="post" action="" data-validate>
    <input type="hidden" name="kind" value="P">

    <%-- client_type P uchun har doim '08' --%>
    <input type="hidden" name="client_type" value="08">

    <div class="form-section">
        <div class="form-section-title">Shaxsiy ma'lumotlar</div>
        <div class="form-row">
            <div class="form-group">
                <label for="p_full_name">To'liq ism (kirilik) *</label>
                <input type="text" id="p_full_name" name="full_name" class="form-control" required
                       placeholder="ИВАНОВ ИВАН ИВАНОВИЧ"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>">
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="p_last_name">Familiya (kirilik) *</label>
                <input type="text" id="p_last_name" name="last_name" class="form-control" required
                       placeholder="ИВАНОВ"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("last_name") != null ? request.getParameter("last_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="p_first_name">Ism (kirilik) *</label>
                <input type="text" id="p_first_name" name="first_name" class="form-control" required
                       placeholder="ИВАН"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("first_name") != null ? request.getParameter("first_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="p_gender">Jinsi *</label>
                <select id="p_gender" name="gender" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="1" <%= "1".equals(request.getParameter("gender")) ? "selected" : "" %>>Erkak</option>
                    <option value="2" <%= "2".equals(request.getParameter("gender")) ? "selected" : "" %>>Ayol</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="p_last_name_lat">Familiya (lotin) *</label>
                <input type="text" id="p_last_name_lat" name="last_name_lat" class="form-control" required
                       placeholder="IVANOV"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("last_name_lat") != null ? request.getParameter("last_name_lat") : "" %>">
            </div>
            <div class="form-group">
                <label for="p_first_name_lat">Ism (lotin) *</label>
                <input type="text" id="p_first_name_lat" name="first_name_lat" class="form-control" required
                       placeholder="IVAN"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("first_name_lat") != null ? request.getParameter("first_name_lat") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="p_birth_date">Tug'ilgan sana *</label>
                <input type="date" id="p_birth_date" name="birth_date" class="form-control" required
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("birth_date") != null ? request.getParameter("birth_date") : "" %>">
            </div>
            <div class="form-group">
                <label for="p_pinfl">PINFL * (14 xona)</label>
                <input type="text" id="p_pinfl" name="pinfl" class="form-control" required
                       maxlength="14" pattern="\d{14}" title="14 xonali raqam"
                       placeholder="12345678901234"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("pinfl") != null ? request.getParameter("pinfl") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Hujjat ma'lumotlari</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="p_doc_type">Hujjat turi *</label>
                <select id="p_doc_type" name="doc_type" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="0" <%= "0".equals(request.getParameter("doc_type")) ? "selected" : "" %>>Pasport (0)</option>
                    <option value="6" <%= "6".equals(request.getParameter("doc_type")) ? "selected" : "" %>>ID karta (6)</option>
                    <option value="8" <%= "8".equals(request.getParameter("doc_type")) ? "selected" : "" %>>Haydovchilik guvohnomasi (8)</option>
                    <option value="1" <%= "1".equals(request.getParameter("doc_type")) ? "selected" : "" %>>Xorijiy pasport (1)</option>
                    <option value="2" <%= "2".equals(request.getParameter("doc_type")) ? "selected" : "" %>>Tug'ilganlik haqida guvohnoma (2)</option>
                </select>
            </div>
            <div class="form-group">
                <label for="p_doc_series">Seriya * (2 belgi)</label>
                <input type="text" id="p_doc_series" name="doc_series" class="form-control" required
                       maxlength="2" placeholder="AA"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("doc_series") != null ? request.getParameter("doc_series") : "" %>">
            </div>
            <div class="form-group">
                <label for="p_doc_number">Raqami * (7 xona)</label>
                <input type="text" id="p_doc_number" name="doc_number" class="form-control" required
                       maxlength="7" pattern="\d{7}" title="7 xonali raqam"
                       placeholder="1234567"
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("doc_number") != null ? request.getParameter("doc_number") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="p_doc_issue_date">Berilgan sana *</label>
                <input type="date" id="p_doc_issue_date" name="doc_issue_date" class="form-control" required
                       value="<%= "P".equals(request.getAttribute("ak")) && request.getParameter("doc_issue_date") != null ? request.getParameter("doc_issue_date") : "" %>">
            </div>
            <div></div>
        </div>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            Ro'yxatga olish
        </button>
        <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="btn">Bekor qilish</a>
    </div>
</form>
</div>

<%-- ================================================================
     PANEL J — Yuridik shaxs
     ================================================================ --%>
<div id="panel-J" class="kind-panel" style="${ak == 'J' ? '' : 'display:none'}">
<form method="post" action="" data-validate>
    <input type="hidden" name="kind" value="J">

    <div class="form-section">
        <div class="form-section-title">Asosiy ma'lumotlar</div>
        <div class="form-row">
            <div class="form-group">
                <label for="j_client_type">Klient kategoriyasi *</label>
                <select id="j_client_type" name="client_type" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="01" <%= "01".equals(request.getParameter("client_type")) ? "selected" : "" %>>01 — Hukumat</option>
                    <option value="02" <%= "02".equals(request.getParameter("client_type")) ? "selected" : "" %>>02 — Davlat tashkiloti</option>
                    <option value="03" <%= "03".equals(request.getParameter("client_type")) ? "selected" : "" %>>03 — Notijorat tashkiloti</option>
                    <option value="04" <%= "04".equals(request.getParameter("client_type")) ? "selected" : "" %>>04 — Bank bo'lmagan moliya tashkiloti</option>
                    <option value="05" <%= "05".equals(request.getParameter("client_type")) ? "selected" : "" %>>05 — Boshqa tashkilotlar</option>
                    <option value="09" <%= "09".equals(request.getParameter("client_type")) || request.getParameter("client_type") == null ? "selected" : "" %>>09 — Xususiy korxona</option>
                    <option value="10" <%= "10".equals(request.getParameter("client_type")) ? "selected" : "" %>>10 — Chet el kapitali bilan</option>
                    <option value="12" <%= "12".equals(request.getParameter("client_type")) ? "selected" : "" %>>12 — Byudjet tashkiloti</option>
                    <option value="13" <%= "13".equals(request.getParameter("client_type")) ? "selected" : "" %>>13 — Yo'l fondi</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="j_full_name">To'liq nomi (kirilik) *</label>
                <input type="text" id="j_full_name" name="full_name" class="form-control" required
                       placeholder="МЧЖ NAMUNA КОМПАНИЯ"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="j_org_name">Qisqa nomi (kirilik) *</label>
                <input type="text" id="j_org_name" name="org_name" class="form-control" required
                       placeholder="NAMUNA"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("org_name") != null ? request.getParameter("org_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="j_org_name_lat">Qisqa nomi (lotin) *</label>
                <input type="text" id="j_org_name_lat" name="org_name_lat" class="form-control" required
                       placeholder="NAMUNA"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("org_name_lat") != null ? request.getParameter("org_name_lat") : "" %>">
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="j_inn">STIR (INN) * (9 xona)</label>
                <input type="text" id="j_inn" name="inn" class="form-control" required
                       maxlength="9" pattern="\d{9}" title="9 xonali raqam"
                       placeholder="123456789"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("inn") != null ? request.getParameter("inn") : "" %>">
            </div>
            <div class="form-group">
                <label for="j_oked">IFUT (OKED)</label>
                <input type="text" id="j_oked" name="oked" class="form-control"
                       maxlength="10" placeholder="47111"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("oked") != null ? request.getParameter("oked") : "" %>">
            </div>
            <div class="form-group">
                <label for="j_country_registr">Ro'yxatdan o'tgan davlat *</label>
                <input type="text" id="j_country_registr" name="country_registr" class="form-control" required
                       maxlength="3" placeholder="860"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("country_registr") != null ? request.getParameter("country_registr") : "860" %>">
                <small class="form-hint">860 = O'zbekiston</small>
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Davlat ro'yxatidan o'tish</div>
        <div class="form-row">
            <div class="form-group">
                <label for="j_num_registr">Ro'yxat raqami *</label>
                <input type="text" id="j_num_registr" name="num_registr" class="form-control" required
                       placeholder="00-00-000"
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("num_registr") != null ? request.getParameter("num_registr") : "" %>">
            </div>
            <div class="form-group">
                <label for="j_date_registr">Ro'yxatga olingan sana *</label>
                <input type="date" id="j_date_registr" name="date_registr" class="form-control" required
                       value="<%= "J".equals(request.getAttribute("ak")) && request.getParameter("date_registr") != null ? request.getParameter("date_registr") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            Ro'yxatga olish
        </button>
        <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="btn">Bekor qilish</a>
    </div>
</form>
</div>

<%-- ================================================================
     PANEL I — YaTT (IP / ИП)
     ================================================================ --%>
<div id="panel-I" class="kind-panel" style="${ak == 'I' ? '' : 'display:none'}">
<form method="post" action="" data-validate>
    <input type="hidden" name="kind" value="I">

    <%-- YaTT uchun client_type har doim '11' --%>
    <input type="hidden" name="client_type" value="11">

    <div class="form-section">
        <div class="form-section-title">Tadbirkor ma'lumotlari (YaTT sifatida)</div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_full_name">To'liq nomi (kirilik) *</label>
                <input type="text" id="i_full_name" name="full_name" class="form-control" required
                       placeholder="ЯТТ ИВАНОВ ИВАН ИВАНОВИЧ"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_org_name">YaTT nomi (kirilik) *</label>
                <input type="text" id="i_org_name" name="org_name" class="form-control" required
                       placeholder="ИВАНОВ И.И."
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("org_name") != null ? request.getParameter("org_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_org_name_lat">YaTT nomi (lotin) *</label>
                <input type="text" id="i_org_name_lat" name="org_name_lat" class="form-control" required
                       placeholder="IVANOV I.I."
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("org_name_lat") != null ? request.getParameter("org_name_lat") : "" %>">
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="i_inn">STIR (INN) * (9 xona)</label>
                <input type="text" id="i_inn" name="inn" class="form-control" required
                       maxlength="9" pattern="\d{9}" title="9 xonali raqam"
                       placeholder="123456789"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("inn") != null ? request.getParameter("inn") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_oked">IFUT (OKED)</label>
                <input type="text" id="i_oked" name="oked" class="form-control"
                       maxlength="10" placeholder="47111"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("oked") != null ? request.getParameter("oked") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_country_registr">Davlat kodi *</label>
                <input type="text" id="i_country_registr" name="country_registr" class="form-control" required
                       maxlength="3" placeholder="860"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("country_registr") != null ? request.getParameter("country_registr") : "860" %>">
                <small class="form-hint">860 = O'zbekiston</small>
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Tadbirkorni davlat ro'yxatidan o'tishi</div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_num_registr">Ro'yxat raqami *</label>
                <input type="text" id="i_num_registr" name="num_registr" class="form-control" required
                       placeholder="00-00-000"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("num_registr") != null ? request.getParameter("num_registr") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_date_registr">Ro'yxatga olingan sana *</label>
                <input type="date" id="i_date_registr" name="date_registr" class="form-control" required
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("date_registr") != null ? request.getParameter("date_registr") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Egasining shaxsiy ma'lumotlari</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="i_ip_last_name">Familiya (kirilik) *</label>
                <input type="text" id="i_ip_last_name" name="ip_last_name" class="form-control" required
                       placeholder="ИВАНОВ"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_last_name") != null ? request.getParameter("ip_last_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_ip_first_name">Ism (kirilik) *</label>
                <input type="text" id="i_ip_first_name" name="ip_first_name" class="form-control" required
                       placeholder="ИВАН"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_first_name") != null ? request.getParameter("ip_first_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_ip_gender">Jinsi *</label>
                <select id="i_ip_gender" name="ip_gender" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="1" <%= "1".equals(request.getParameter("ip_gender")) ? "selected" : "" %>>Erkak</option>
                    <option value="2" <%= "2".equals(request.getParameter("ip_gender")) ? "selected" : "" %>>Ayol</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_ip_last_name_lat">Familiya (lotin) *</label>
                <input type="text" id="i_ip_last_name_lat" name="ip_last_name_lat" class="form-control" required
                       placeholder="IVANOV"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_last_name_lat") != null ? request.getParameter("ip_last_name_lat") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_ip_first_name_lat">Ism (lotin) *</label>
                <input type="text" id="i_ip_first_name_lat" name="ip_first_name_lat" class="form-control" required
                       placeholder="IVAN"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_first_name_lat") != null ? request.getParameter("ip_first_name_lat") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_ip_dob">Tug'ilgan sana *</label>
                <input type="date" id="i_ip_dob" name="ip_dob" class="form-control" required
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_dob") != null ? request.getParameter("ip_dob") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_ip_pinfl">PINFL * (14 xona)</label>
                <input type="text" id="i_ip_pinfl" name="ip_pinfl" class="form-control" required
                       maxlength="14" pattern="\d{14}" title="14 xonali raqam"
                       placeholder="12345678901234"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_pinfl") != null ? request.getParameter("ip_pinfl") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Egasining hujjat ma'lumotlari</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="i_ip_doc_type">Hujjat turi *</label>
                <select id="i_ip_doc_type" name="ip_doc_type" class="form-control" required>
                    <option value="">— Tanlang —</option>
                    <option value="0" <%= "0".equals(request.getParameter("ip_doc_type")) ? "selected" : "" %>>Pasport (0)</option>
                    <option value="6" <%= "6".equals(request.getParameter("ip_doc_type")) ? "selected" : "" %>>ID karta (6)</option>
                    <option value="8" <%= "8".equals(request.getParameter("ip_doc_type")) ? "selected" : "" %>>Haydovchilik guvohnomasi (8)</option>
                    <option value="1" <%= "1".equals(request.getParameter("ip_doc_type")) ? "selected" : "" %>>Xorijiy pasport (1)</option>
                </select>
            </div>
            <div class="form-group">
                <label for="i_ip_doc_serial">Seriya * (2 belgi)</label>
                <input type="text" id="i_ip_doc_serial" name="ip_doc_serial" class="form-control" required
                       maxlength="2" placeholder="AA"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_doc_serial") != null ? request.getParameter("ip_doc_serial") : "" %>">
            </div>
            <div class="form-group">
                <label for="i_ip_doc_number">Raqami * (7 xona)</label>
                <input type="text" id="i_ip_doc_number" name="ip_doc_number" class="form-control" required
                       maxlength="7" pattern="\d{7}" title="7 xonali raqam"
                       placeholder="1234567"
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_doc_number") != null ? request.getParameter("ip_doc_number") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="i_ip_doc_issue_date">Berilgan sana *</label>
                <input type="date" id="i_ip_doc_issue_date" name="ip_doc_issue_date" class="form-control" required
                       value="<%= "I".equals(request.getAttribute("ak")) && request.getParameter("ip_doc_issue_date") != null ? request.getParameter("ip_doc_issue_date") : "" %>">
            </div>
            <div></div>
        </div>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            Ro'yxatga olish
        </button>
        <a href="${pageContext.request.contextPath}/abs/cif/client-list.jsp" class="btn">Bekor qilish</a>
    </div>
</form>
</div>

<%-- ================================================================
     KIND SWITCHER — vanilla JS
     Panel switch + tab highlight
     ================================================================ --%>
<script>
(function () {
    var kinds = ['P', 'J', 'I'];

    function switchKind(kind) {
        // Panellarni ko'rsat/yashir
        kinds.forEach(function (k) {
            var panel = document.getElementById('panel-' + k);
            if (panel) panel.style.display = (k === kind) ? '' : 'none';
        });
        // Tab tugmalarini yangilash
        document.querySelectorAll('#kind-tabs .tab-btn').forEach(function (btn) {
            btn.classList.toggle('active', btn.dataset.kind === kind);
        });
    }

    // Global qil (onclick'lar uchun)
    window.switchKind = switchKind;
})();
</script>

<jsp:include page="cif-footer.jsp"/>

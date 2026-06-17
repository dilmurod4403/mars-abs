<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Types, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  MARS ABS - CIF Yangi mijoz yaratish
  Procedure: core_cif_service.Create_Customer (anonymous PL/SQL block)
  Tab'lar: Jismoniy shaxs (FYaSh) / Yuridik shaxs (YuSh)
--%>
<%
    // ---- POST: Mijoz yaratish ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String customerType = request.getParameter("customer_type");
        String firstName    = request.getParameter("first_name");
        String lastName     = request.getParameter("last_name");
        String middleName   = request.getParameter("middle_name");
        String orgName      = request.getParameter("org_name");
        String orgFullName  = request.getParameter("org_full_name");
        String orgForm      = request.getParameter("org_form");
        String oked         = request.getParameter("oked");
        String regNumber    = request.getParameter("reg_number");
        String regDateStr   = request.getParameter("reg_date");
        String regAuthority = request.getParameter("reg_authority");
        String directorName = request.getParameter("director_name");
        String directorPos  = request.getParameter("director_position");
        String accountant   = request.getParameter("accountant_name");
        String directorPinfl= request.getParameter("director_pinfl");
        String pinfl        = request.getParameter("pinfl");
        String inn          = request.getParameter("inn");
        String birthDateStr = request.getParameter("birth_date");
        String birthPlace   = request.getParameter("birth_place");
        String gender       = request.getParameter("gender");
        String phone        = request.getParameter("phone");
        String email        = request.getParameter("email");
        String legalAddress = request.getParameter("legal_address");
        String actualAddress= request.getParameter("actual_address");
        String residentFlag = request.getParameter("resident_flag");
        String countryCode  = request.getParameter("country_code");
        String branchCode   = request.getParameter("branch_code");
        String sectorCode   = request.getParameter("sector_code");
        String riskCategory = request.getParameter("risk_category");
        String isPep        = request.getParameter("is_pep");
        String openingPurpose = request.getParameter("opening_purpose");
        String employerName = request.getParameter("employer_name");
        String employerPos  = request.getParameter("employer_position");
        String employerAddr = request.getParameter("employer_address");
        String employerPhone= request.getParameter("employer_phone");
        String otherBankName= request.getParameter("other_bank_name");
        String otherBankMfo = request.getParameter("other_bank_mfo");
        String otherBankAcc = request.getParameter("other_bank_account");
        String createdBy    = request.getParameter("created_by");

        if (residentFlag == null || residentFlag.isEmpty()) residentFlag = "Y";
        if (countryCode == null || countryCode.isEmpty()) countryCode = "UZ";
        if (riskCategory == null || riskCategory.isEmpty()) riskCategory = "LOW";
        if (isPep == null) isPep = "N";
        if (createdBy == null || createdBy.isEmpty()) createdBy = "OPERATOR";

        try {
            java.util.Map<String,Object> result = Mars.procedure("core_cif_service.Create_Customer")
                .record("v_rec", "core_cif_types.t_customer_rec")
                .field("customer_type", customerType)
                .field("first_name", firstName)
                .field("last_name", lastName)
                .field("middle_name", middleName)
                .field("org_name", orgName)
                .field("org_full_name", orgFullName)
                .field("org_form", orgForm)
                .field("oked", oked)
                .field("reg_number", regNumber)
                .fieldDate("reg_date", regDateStr != null && !regDateStr.isEmpty() ? regDateStr : null, "YYYY-MM-DD")
                .field("reg_authority", regAuthority)
                .field("director_name", directorName)
                .field("director_position", directorPos)
                .field("accountant_name", accountant)
                .field("director_pinfl", directorPinfl)
                .field("pinfl", pinfl)
                .field("inn", inn)
                .fieldDate("birth_date", birthDateStr != null && !birthDateStr.isEmpty() ? birthDateStr : null, "YYYY-MM-DD")
                .field("birth_place", birthPlace)
                .field("gender", gender)
                .field("phone", phone)
                .field("email", email)
                .field("legal_address", legalAddress)
                .field("actual_address", actualAddress)
                .field("resident_flag", residentFlag)
                .field("country_code", countryCode)
                .field("branch_code", branchCode)
                .field("sector_code", sectorCode)
                .field("risk_category", riskCategory)
                .field("is_pep", isPep)
                .field("opening_purpose", openingPurpose)
                .field("employer_name", employerName)
                .field("employer_position", employerPos)
                .field("employer_address", employerAddr)
                .field("employer_phone", employerPhone)
                .field("other_bank_name", otherBankName)
                .field("other_bank_mfo", otherBankMfo)
                .field("other_bank_account", otherBankAcc)
                .field("created_by", createdBy)
                .outField("customer_id", Types.NUMERIC)
                .outField("cif_number", Types.VARCHAR)
                .outNumber("code")
                .outString("message")
                .outString("ora_message")
                .execute();

            int code = ((Number) result.get("code")).intValue();
            String message = (String) result.get("message");

            if (code == 0) {
                long newId = ((Number) result.get("customer_id")).longValue();
                String cifNum = (String) result.get("cif_number");
                response.sendRedirect("customer-detail.jsp?id=" + newId
                    + "&msg=" + java.net.URLEncoder.encode("Mijoz yaratildi: " + cifNum, "UTF-8"));
                return;
            } else {
                request.setAttribute("errorMsg", message);
            }
        } catch (Exception e) {
            request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
        }
    }
%>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Yangi mijoz"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>Yangi mijoz yaratish</h1>
    <a href="${pageContext.request.contextPath}/abs/cif/customer-list.jsp" class="btn">Ortga</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><%= request.getAttribute("errorMsg") %></div>
<% } %>

<!-- ---- Tab'lar ---- -->
<div class="tabs">
    <button type="button" class="tab-btn active" data-tab="individual">Jismoniy shaxs (FYaSh)</button>
    <button type="button" class="tab-btn" data-tab="corporate">Yuridik shaxs (YuSh)</button>
</div>

<!-- ============================================================
     TAB 1: Jismoniy shaxs (INDIVIDUAL)
     ============================================================ -->
<div id="tab-individual" class="tab-content active">
<form method="post" data-validate>
    <input type="hidden" name="customer_type" value="INDIVIDUAL">

    <div class="form-section">
        <div class="form-section-title">Shaxsiy ma'lumotlar</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="ind_last_name">Familiya *</label>
                <input type="text" id="ind_last_name" name="last_name" class="form-control" required
                       value="<%= request.getParameter("last_name") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("last_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_first_name">Ism *</label>
                <input type="text" id="ind_first_name" name="first_name" class="form-control" required
                       value="<%= request.getParameter("first_name") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("first_name") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_middle_name">Otasining ismi</label>
                <input type="text" id="ind_middle_name" name="middle_name" class="form-control"
                       value="<%= request.getParameter("middle_name") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("middle_name") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_pinfl">PINFL * (14 xonali)</label>
                <input type="text" id="ind_pinfl" name="pinfl" class="form-control" required
                       maxlength="14" pattern="\d{14}" title="14 xonali raqam"
                       value="<%= request.getParameter("pinfl") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("pinfl") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_birth_date">Tug'ilgan sana *</label>
                <input type="date" id="ind_birth_date" name="birth_date" class="form-control" required
                       value="<%= request.getParameter("birth_date") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("birth_date") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_birth_place">Tug'ilgan joy</label>
                <input type="text" id="ind_birth_place" name="birth_place" class="form-control"
                       value="<%= request.getParameter("birth_place") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("birth_place") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_gender">Jinsi</label>
                <select id="ind_gender" name="gender" class="form-control">
                    <option value="">—</option>
                    <option value="M">Erkak</option>
                    <option value="F">Ayol</option>
                </select>
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Aloqa ma'lumotlari</div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_phone">Telefon * (+998XXXXXXXXX)</label>
                <input type="tel" id="ind_phone" name="phone" class="form-control" required
                       placeholder="+998901234567"
                       value="<%= request.getParameter("phone") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("phone") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_email">Email</label>
                <input type="email" id="ind_email" name="email" class="form-control"
                       value="<%= request.getParameter("email") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("email") : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_legal_address">Ro'yxatdagi manzil</label>
                <input type="text" id="ind_legal_address" name="legal_address" class="form-control"
                       value="<%= request.getParameter("legal_address") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("legal_address") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_actual_address">Haqiqiy manzil</label>
                <input type="text" id="ind_actual_address" name="actual_address" class="form-control"
                       value="<%= request.getParameter("actual_address") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("actual_address") : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Ish joyi</div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_employer_name">Tashkilot nomi</label>
                <input type="text" id="ind_employer_name" name="employer_name" class="form-control">
            </div>
            <div class="form-group">
                <label for="ind_employer_position">Lavozimi</label>
                <input type="text" id="ind_employer_position" name="employer_position" class="form-control">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="ind_employer_address">Tashkilot manzili</label>
                <input type="text" id="ind_employer_address" name="employer_address" class="form-control">
            </div>
            <div class="form-group">
                <label for="ind_employer_phone">Tashkilot telefoni</label>
                <input type="text" id="ind_employer_phone" name="employer_phone" class="form-control">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Klassifikatsiya</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="ind_branch_code">Filial kodi *</label>
                <input type="text" id="ind_branch_code" name="branch_code" class="form-control" required
                       value="<%= request.getParameter("branch_code") != null && "INDIVIDUAL".equals(request.getParameter("customer_type")) ? request.getParameter("branch_code") : "" %>">
            </div>
            <div class="form-group">
                <label for="ind_risk_category">Risk kategoriyasi</label>
                <select id="ind_risk_category" name="risk_category" class="form-control">
                    <option value="LOW">LOW</option>
                    <option value="MEDIUM">MEDIUM</option>
                    <option value="HIGH">HIGH</option>
                </select>
            </div>
            <div class="form-group">
                <label for="ind_is_pep">PEP</label>
                <select id="ind_is_pep" name="is_pep" class="form-control">
                    <option value="N">Yo'q</option>
                    <option value="Y">Ha</option>
                </select>
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="ind_resident_flag">Rezident</label>
                <select id="ind_resident_flag" name="resident_flag" class="form-control">
                    <option value="Y">Ha</option>
                    <option value="N">Yo'q</option>
                </select>
            </div>
            <div class="form-group">
                <label for="ind_country_code">Davlat kodi</label>
                <input type="text" id="ind_country_code" name="country_code" class="form-control" value="UZ" maxlength="3">
            </div>
            <div class="form-group">
                <label for="ind_sector_code">Sektor kodi</label>
                <input type="text" id="ind_sector_code" name="sector_code" class="form-control">
            </div>
        </div>
        <div class="form-group">
            <label for="ind_opening_purpose">Hisob ochish maqsadi</label>
            <input type="text" id="ind_opening_purpose" name="opening_purpose" class="form-control"
                   value="<%= request.getParameter("opening_purpose") != null ? request.getParameter("opening_purpose") : "" %>">
        </div>
    </div>

    <div class="form-row">
        <div class="form-group">
            <label for="ind_created_by">Operator *</label>
            <input type="text" id="ind_created_by" name="created_by" class="form-control" required value="OPERATOR">
        </div>
        <div></div>
    </div>

    <div style="margin-top: 1rem;">
        <button type="submit" class="btn btn-primary">Yaratish</button>
        <a href="${pageContext.request.contextPath}/abs/cif/customer-list.jsp" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
    </div>
</form>
</div>

<!-- ============================================================
     TAB 2: Yuridik shaxs (CORPORATE)
     ============================================================ -->
<div id="tab-corporate" class="tab-content">
<form method="post" data-validate>
    <input type="hidden" name="customer_type" value="CORPORATE">

    <div class="form-section">
        <div class="form-section-title">Tashkilot ma'lumotlari</div>
        <div class="form-row">
            <div class="form-group">
                <label for="corp_org_name">Qisqa nomi *</label>
                <input type="text" id="corp_org_name" name="org_name" class="form-control" required>
            </div>
            <div class="form-group">
                <label for="corp_org_full_name">To'liq nomi</label>
                <input type="text" id="corp_org_full_name" name="org_full_name" class="form-control">
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="corp_org_form">Tashkiliy shakl</label>
                <select id="corp_org_form" name="org_form" class="form-control">
                    <option value="">—</option>
                    <option value="OOO">OOO (MChJ)</option>
                    <option value="AO">AO (AJ)</option>
                    <option value="UP">UP (UK)</option>
                    <option value="GP">GP (DK)</option>
                    <option value="IP">IP (YaTT)</option>
                </select>
            </div>
            <div class="form-group">
                <label for="corp_inn">STIR (INN) * (9 xonali)</label>
                <input type="text" id="corp_inn" name="inn" class="form-control" required
                       maxlength="9" pattern="\d{9}" title="9 xonali raqam">
            </div>
            <div class="form-group">
                <label for="corp_oked">IFUT (OKED)</label>
                <input type="text" id="corp_oked" name="oked" class="form-control" maxlength="10">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Ro'yxatdan o'tish</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="corp_reg_number">Ro'yxat raqami</label>
                <input type="text" id="corp_reg_number" name="reg_number" class="form-control">
            </div>
            <div class="form-group">
                <label for="corp_reg_date">Ro'yxat sanasi</label>
                <input type="date" id="corp_reg_date" name="reg_date" class="form-control">
            </div>
            <div class="form-group">
                <label for="corp_reg_authority">Ro'yxatdan o'tkazgan organ</label>
                <input type="text" id="corp_reg_authority" name="reg_authority" class="form-control">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Rahbariyat</div>
        <div class="form-row">
            <div class="form-group">
                <label for="corp_director_name">Rahbar FIO *</label>
                <input type="text" id="corp_director_name" name="director_name" class="form-control" required>
            </div>
            <div class="form-group">
                <label for="corp_director_position">Lavozimi</label>
                <input type="text" id="corp_director_position" name="director_position" class="form-control" value="Direktor">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="corp_director_pinfl">Rahbar PINFL * (14 xonali)</label>
                <input type="text" id="corp_director_pinfl" name="director_pinfl" class="form-control" required
                       maxlength="14" pattern="\d{14}" title="14 xonali raqam">
            </div>
            <div class="form-group">
                <label for="corp_accountant">Bosh hisobchi</label>
                <input type="text" id="corp_accountant" name="accountant_name" class="form-control">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Aloqa</div>
        <div class="form-row">
            <div class="form-group">
                <label for="corp_phone">Telefon * (+998XXXXXXXXX)</label>
                <input type="tel" id="corp_phone" name="phone" class="form-control" required placeholder="+998901234567">
            </div>
            <div class="form-group">
                <label for="corp_email">Email</label>
                <input type="email" id="corp_email" name="email" class="form-control">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="corp_legal_address">Yuridik manzil</label>
                <input type="text" id="corp_legal_address" name="legal_address" class="form-control">
            </div>
            <div class="form-group">
                <label for="corp_actual_address">Haqiqiy manzil</label>
                <input type="text" id="corp_actual_address" name="actual_address" class="form-control">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Boshqa bank ma'lumotlari</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="corp_other_bank">Bank nomi</label>
                <input type="text" id="corp_other_bank" name="other_bank_name" class="form-control">
            </div>
            <div class="form-group">
                <label for="corp_other_mfo">MFO</label>
                <input type="text" id="corp_other_mfo" name="other_bank_mfo" class="form-control" maxlength="5">
            </div>
            <div class="form-group">
                <label for="corp_other_account">Hisob raqami</label>
                <input type="text" id="corp_other_account" name="other_bank_account" class="form-control" maxlength="20">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Klassifikatsiya</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="corp_branch_code">Filial kodi *</label>
                <input type="text" id="corp_branch_code" name="branch_code" class="form-control" required>
            </div>
            <div class="form-group">
                <label for="corp_risk_category">Risk kategoriyasi</label>
                <select id="corp_risk_category" name="risk_category" class="form-control">
                    <option value="LOW">LOW</option>
                    <option value="MEDIUM">MEDIUM</option>
                    <option value="HIGH">HIGH</option>
                </select>
            </div>
            <div class="form-group">
                <label for="corp_is_pep">PEP</label>
                <select id="corp_is_pep" name="is_pep" class="form-control">
                    <option value="N">Yo'q</option>
                    <option value="Y">Ha</option>
                </select>
            </div>
        </div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="corp_resident_flag">Rezident</label>
                <select id="corp_resident_flag" name="resident_flag" class="form-control">
                    <option value="Y">Ha</option>
                    <option value="N">Yo'q</option>
                </select>
            </div>
            <div class="form-group">
                <label for="corp_country_code">Davlat kodi</label>
                <input type="text" id="corp_country_code" name="country_code" class="form-control" value="UZ" maxlength="3">
            </div>
            <div class="form-group">
                <label for="corp_sector_code">Sektor kodi</label>
                <input type="text" id="corp_sector_code" name="sector_code" class="form-control">
            </div>
        </div>
        <div class="form-group">
            <label for="corp_opening_purpose">Hisob ochish maqsadi</label>
            <input type="text" id="corp_opening_purpose" name="opening_purpose" class="form-control">
        </div>
    </div>

    <div class="form-row">
        <div class="form-group">
            <label for="corp_created_by">Operator *</label>
            <input type="text" id="corp_created_by" name="created_by" class="form-control" required value="OPERATOR">
        </div>
        <div></div>
    </div>

    <div style="margin-top: 1rem;">
        <button type="submit" class="btn btn-primary">Yaratish</button>
        <a href="${pageContext.request.contextPath}/abs/cif/customer-list.jsp" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
    </div>
</form>
</div>


<jsp:include page="cif-footer.jsp"/>

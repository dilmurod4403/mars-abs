……æ

πø≥≥≥≥≥
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - CIF Mijozni tahrirlash
  View: core_cif_customer_detail_i_v (oldindan yuklash)
  Procedure: core_cif_service.Update_Customer (anonymous PL/SQL block)
--%>
<%
    // ---- POST: Yangilash ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String custIdStr = request.getParameter("customer_id");
        long custId = Long.parseLong(custIdStr);
        String phone = request.getParameter("phone");
        String email = request.getParameter("email");
        String legalAddress = request.getParameter("legal_address");
        String actualAddress = request.getParameter("actual_address");
        String branchCode = request.getParameter("branch_code");
        String riskCategory = request.getParameter("risk_category");
        String isPep = request.getParameter("is_pep");
        String employerName = request.getParameter("employer_name");
        String employerPos = request.getParameter("employer_position");
        String employerAddr = request.getParameter("employer_address");
        String employerPhone = request.getParameter("employer_phone");
        String directorName = request.getParameter("director_name");
        String directorPos = request.getParameter("director_position");
        String accountant = request.getParameter("accountant_name");
        String directorPinfl = request.getParameter("director_pinfl");
        String otherBankName = request.getParameter("other_bank_name");
        String otherBankMfo = request.getParameter("other_bank_mfo");
        String otherBankAcc = request.getParameter("other_bank_account");
        String openingPurpose = request.getParameter("opening_purpose");
        String updatedBy = request.getParameter("updated_by");
        if (updatedBy == null || updatedBy.isEmpty()) updatedBy = "OPERATOR";
        if (isPep == null) isPep = "N";

        try {
            java.util.Map<String, Object> result = Mars.procedure("core_cif_service.Update_Customer")
                    .record("v_rec", "core_cif_types.t_customer_rec")
                    .field("customer_id", custId)
                    .field("phone", phone)
                    .field("email", email)
                    .field("legal_address", legalAddress)
                    .field("actual_address", actualAddress)
                    .field("branch_code", branchCode)
                    .field("risk_category", riskCategory)
                    .field("is_pep", isPep)
                    .field("employer_name", employerName)
                    .field("employer_position", employerPos)
                    .field("employer_address", employerAddr)
                    .field("employer_phone", employerPhone)
                    .field("director_name", directorName)
                    .field("director_position", directorPos)
                    .field("accountant_name", accountant)
                    .field("director_pinfl", directorPinfl)
                    .field("other_bank_name", otherBankName)
                    .field("other_bank_mfo", otherBankMfo)
                    .field("other_bank_account", otherBankAcc)
                    .field("opening_purpose", openingPurpose)
                    .field("updated_by", updatedBy)
                    .outNumber("code")
                    .outString("message")
                    .execute();

            int code = ((Number) result.get("code")).intValue();
            String message = (String) result.get("message");
            if (code == 0) {
                response.sendRedirect("customer-detail.jsp?id=" + custId
                        + "&msg=" + java.net.URLEncoder.encode("Mijoz yangilandi", "UTF-8"));
                return;
            } else {
                request.setAttribute("errorMsg", message);
            }
        } catch (Exception e) {
            request.setAttribute("errorMsg", "Xatolik: " + e.getMessage());
        }
    }

    // ---- GET: Mavjud ma'lumotlarni yuklash ----
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.isEmpty()) {
        response.sendRedirect("customer-list.jsp");
        return;
    }
    long customerId = Long.parseLong(idStr);

    java.util.Map<String, Object> cust = null;
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();
        ps = conn.prepareStatement(
                "SELECT customer_id, cif_number, customer_type, first_name, last_name, middle_name, " +
                        "       full_name, org_name, org_full_name, org_form, oked, " +
                        "       reg_number, reg_date, reg_authority, " +
                        "       director_name, director_position, accountant_name, director_pinfl, " +
                        "       pinfl, inn, birth_date, birth_place, gender, age, " +
                        "       phone, email, legal_address, actual_address, " +
                        "       resident_flag, country_code, branch_code, sector_code, " +
                        "       risk_category, is_pep, opening_purpose, " +
                        "       employer_name, employer_position, employer_address, employer_phone, " +
                        "       other_bank_name, other_bank_mfo, other_bank_account, " +
                        "       status, created_by, created_at " +
                        "  FROM core_cif_customer_detail_i_v WHERE customer_id = ?"
        );
        ps.setLong(1, customerId);
        rs = ps.executeQuery();
        if (rs.next()) {
            cust = new java.util.LinkedHashMap<>();
            ResultSetMetaData md = rs.getMetaData();
            for (int i = 1; i <= md.getColumnCount(); i++) {
                String colName = md.getColumnName(i).toLowerCase();
                int colType = md.getColumnType(i);
                Object val;
                // Oracle TIMESTAMP / TIMESTAMP WITH LOCAL TIME ZONE → java.util.Date (JSTL-safe)
                if (colType == Types.TIMESTAMP || colType == Types.DATE
                        || colType == -101 || colType == -102) {
                    Timestamp ts = rs.getTimestamp(i);
                    val = (ts != null) ? new java.util.Date(ts.getTime()) : null;
                } else {
                    val = rs.getObject(i);
                }
                cust.put(colName, val);
            }
        }
    } finally {
        if (rs != null) try {
            rs.close();
        } catch (Exception e) {
        }
        if (ps != null) try {
            ps.close();
        } catch (Exception e) {
        }
        if (conn != null) try {
            conn.close();
        } catch (Exception e) {
        }
    }

    if (cust == null) {
        response.sendRedirect("customer-list.jsp?err=" + java.net.URLEncoder.encode("Mijoz topilmadi", "UTF-8"));
        return;
    }
    request.setAttribute("c", cust);

    String custType = (String) cust.get("customer_type");

    // POST xato bo'lsa, formaga kiritilgan qiymatlar prioritet oladi
    String valPhone = request.getParameter("phone") != null ? request.getParameter("phone") : (String) cust.get("phone");
    String valEmail = request.getParameter("email") != null ? request.getParameter("email") : (String) cust.get("email");
    String valLegalAddr = request.getParameter("legal_address") != null ? request.getParameter("legal_address") : (String) cust.get("legal_address");
    String valActualAddr = request.getParameter("actual_address") != null ? request.getParameter("actual_address") : (String) cust.get("actual_address");
    String valBranch = request.getParameter("branch_code") != null ? request.getParameter("branch_code") : (String) cust.get("branch_code");
    String valRisk = request.getParameter("risk_category") != null ? request.getParameter("risk_category") : (String) cust.get("risk_category");
    String valPep = request.getParameter("is_pep") != null ? request.getParameter("is_pep") : (String) cust.get("is_pep");
    String valOpenPurpose = request.getParameter("opening_purpose") != null ? request.getParameter("opening_purpose") : (String) cust.get("opening_purpose");
    String valEmployerName = request.getParameter("employer_name") != null ? request.getParameter("employer_name") : (String) cust.get("employer_name");
    String valEmployerPos = request.getParameter("employer_position") != null ? request.getParameter("employer_position") : (String) cust.get("employer_position");
    String valEmployerAddr = request.getParameter("employer_address") != null ? request.getParameter("employer_address") : (String) cust.get("employer_address");
    String valEmployerPhone = request.getParameter("employer_phone") != null ? request.getParameter("employer_phone") : (String) cust.get("employer_phone");
    String valDirName = request.getParameter("director_name") != null ? request.getParameter("director_name") : (String) cust.get("director_name");
    String valDirPos = request.getParameter("director_position") != null ? request.getParameter("director_position") : (String) cust.get("director_position");
    String valAccountant = request.getParameter("accountant_name") != null ? request.getParameter("accountant_name") : (String) cust.get("accountant_name");
    String valDirPinfl = request.getParameter("director_pinfl") != null ? request.getParameter("director_pinfl") : (String) cust.get("director_pinfl");
    String valOtherBank = request.getParameter("other_bank_name") != null ? request.getParameter("other_bank_name") : (String) cust.get("other_bank_name");
    String valOtherMfo = request.getParameter("other_bank_mfo") != null ? request.getParameter("other_bank_mfo") : (String) cust.get("other_bank_mfo");
    String valOtherAcc = request.getParameter("other_bank_account") != null ? request.getParameter("other_bank_account") : (String) cust.get("other_bank_account");
%>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="Tahrirlash - ${c.full_name}"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>Mijozni tahrirlash</h1>
    <a href="customer-detail.jsp?id=<%= customerId %>" class="btn">Bekor qilish</a>
</div>

<% if (request.getAttribute("errorMsg") != null) { %>
<div class="alert alert-danger"><%= request.getAttribute("errorMsg") %>
</div>
<% } %>

<!-- ---- O'zgarmas ma'lumotlar ---- -->
<div class="card">
    <div class="card-title">Asosiy ma'lumotlar (o'zgartib bo'lmaydi)</div>
    <dl class="detail-grid-wide">
        <dt>CIF raqami</dt>
        <dd><strong>${c.cif_number}</strong></dd>
        <dt>Turi</dt>
        <dd>
            <span class="badge badge-<%= "INDIVIDUAL".equals(custType) ? "individual" : "corporate" %>">
                <%= "INDIVIDUAL".equals(custType) ? "Jismoniy shaxs" : "Yuridik shaxs" %>
            </span>
        </dd>
        <% if ("INDIVIDUAL".equals(custType)) { %>
        <dt>FIO</dt>
        <dd>${c.last_name} ${c.first_name} ${c.middle_name}</dd>
        <dt>PINFL</dt>
        <dd>${c.pinfl}</dd>
        <dt>Tug'ilgan sana</dt>
        <dd><fmt:formatDate value="${c.birth_date}" pattern="dd.MM.yyyy"/> (${c.age} yosh)</dd>
        <% } else { %>
        <dt>Tashkilot</dt>
        <dd>${c.org_name}</dd>
        <dt>STIR (INN)</dt>
        <dd>${c.inn}</dd>
        <% } %>
    </dl>
</div>

<!-- ---- Tahrirlash formasi ---- -->
<form method="post" data-validate>
    <input type="hidden" name="customer_id" value="<%= customerId %>">

    <div class="form-section">
        <div class="form-section-title">Aloqa ma'lumotlari</div>
        <div class="form-row">
            <div class="form-group">
                <label for="phone">Telefon *</label>
                <input type="tel" id="phone" name="phone" class="form-control" required
                       value="<%= valPhone != null ? valPhone : "" %>">
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" class="form-control"
                       value="<%= valEmail != null ? valEmail : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="legal_address">Yuridik manzil</label>
                <input type="text" id="legal_address" name="legal_address" class="form-control"
                       value="<%= valLegalAddr != null ? valLegalAddr : "" %>">
            </div>
            <div class="form-group">
                <label for="actual_address">Haqiqiy manzil</label>
                <input type="text" id="actual_address" name="actual_address" class="form-control"
                       value="<%= valActualAddr != null ? valActualAddr : "" %>">
            </div>
        </div>
    </div>

    <% if ("INDIVIDUAL".equals(custType)) { %>
    <div class="form-section">
        <div class="form-section-title">Ish joyi</div>
        <div class="form-row">
            <div class="form-group">
                <label for="employer_name">Tashkilot nomi</label>
                <input type="text" id="employer_name" name="employer_name" class="form-control"
                       value="<%= valEmployerName != null ? valEmployerName : "" %>">
            </div>
            <div class="form-group">
                <label for="employer_position">Lavozimi</label>
                <input type="text" id="employer_position" name="employer_position" class="form-control"
                       value="<%= valEmployerPos != null ? valEmployerPos : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="employer_address">Tashkilot manzili</label>
                <input type="text" id="employer_address" name="employer_address" class="form-control"
                       value="<%= valEmployerAddr != null ? valEmployerAddr : "" %>">
            </div>
            <div class="form-group">
                <label for="employer_phone">Tashkilot telefoni</label>
                <input type="text" id="employer_phone" name="employer_phone" class="form-control"
                       value="<%= valEmployerPhone != null ? valEmployerPhone : "" %>">
            </div>
        </div>
    </div>
    <% } else { %>
    <div class="form-section">
        <div class="form-section-title">Rahbariyat</div>
        <div class="form-row">
            <div class="form-group">
                <label for="director_name">Rahbar FIO</label>
                <input type="text" id="director_name" name="director_name" class="form-control"
                       value="<%= valDirName != null ? valDirName : "" %>">
            </div>
            <div class="form-group">
                <label for="director_position">Lavozimi</label>
                <input type="text" id="director_position" name="director_position" class="form-control"
                       value="<%= valDirPos != null ? valDirPos : "" %>">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="director_pinfl">Rahbar PINFL</label>
                <input type="text" id="director_pinfl" name="director_pinfl" class="form-control"
                       value="<%= valDirPinfl != null ? valDirPinfl : "" %>" maxlength="14">
            </div>
            <div class="form-group">
                <label for="accountant_name">Bosh hisobchi</label>
                <input type="text" id="accountant_name" name="accountant_name" class="form-control"
                       value="<%= valAccountant != null ? valAccountant : "" %>">
            </div>
        </div>
    </div>

    <div class="form-section">
        <div class="form-section-title">Boshqa bank</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="other_bank_name">Bank nomi</label>
                <input type="text" id="other_bank_name" name="other_bank_name" class="form-control"
                       value="<%= valOtherBank != null ? valOtherBank : "" %>">
            </div>
            <div class="form-group">
                <label for="other_bank_mfo">MFO</label>
                <input type="text" id="other_bank_mfo" name="other_bank_mfo" class="form-control"
                       value="<%= valOtherMfo != null ? valOtherMfo : "" %>" maxlength="5">
            </div>
            <div class="form-group">
                <label for="other_bank_account">Hisob raqami</label>
                <input type="text" id="other_bank_account" name="other_bank_account" class="form-control"
                       value="<%= valOtherAcc != null ? valOtherAcc : "" %>" maxlength="20">
            </div>
        </div>
    </div>
    <% } %>

    <div class="form-section">
        <div class="form-section-title">Klassifikatsiya</div>
        <div class="form-row-3">
            <div class="form-group">
                <label for="branch_code">Filial kodi *</label>
                <input type="text" id="branch_code" name="branch_code" class="form-control" required
                       value="<%= valBranch != null ? valBranch : "" %>">
            </div>
            <div class="form-group">
                <label for="risk_category">Risk kategoriyasi</label>
                <select id="risk_category" name="risk_category" class="form-control">
                    <option value="LOW" <%= "LOW".equals(valRisk) ? "selected" : "" %>>LOW</option>
                    <option value="MEDIUM" <%= "MEDIUM".equals(valRisk) ? "selected" : "" %>>MEDIUM</option>
                    <option value="HIGH" <%= "HIGH".equals(valRisk) ? "selected" : "" %>>HIGH</option>
                </select>
            </div>
            <div class="form-group">
                <label for="is_pep">PEP</label>
                <select id="is_pep" name="is_pep" class="form-control">
                    <option value="N" <%= "N".equals(valPep) || valPep == null ? "selected" : "" %>>Yo'q</option>
                    <option value="Y" <%= "Y".equals(valPep) ? "selected" : "" %>>Ha</option>
                </select>
            </div>
        </div>
        <div class="form-group">
            <label for="opening_purpose">Hisob ochish maqsadi</label>
            <input type="text" id="opening_purpose" name="opening_purpose" class="form-control"
                   value="<%= valOpenPurpose != null ? valOpenPurpose : "" %>">
        </div>
    </div>

    <div class="form-row">
        <div class="form-group">
            <label for="updated_by">Operator *</label>
            <input type="text" id="updated_by" name="updated_by" class="form-control" required value="OPERATOR">
        </div>
        <div></div>
    </div>

    <div style="margin-top: 1rem;">
        <button type="submit" class="btn btn-primary">Saqlash</button>
        <a href="customer-detail.jsp?id=<%= customerId %>" class="btn" style="margin-left: 0.5rem;">Bekor qilish</a>
    </div>
</form>

<jsp:include page="cif-footer.jsp"/>

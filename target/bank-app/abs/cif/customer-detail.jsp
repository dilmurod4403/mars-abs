<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, uz.fido.abs.core.db.AbsDb, uz.fido.abs.core.db.Mars" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%--
  MARS ABS - CIF Mijoz tafsiloti
  Views: core_cif_customer_detail_i_v, core_cif_documents_ui_v,
         core_cif_contacts_ui_v, core_cif_audit_log_ui_v
  POST: holat o'zgartirish (core_cif_service.Change_Status)
--%>
<%
    // ---- POST: Holat o'zgartirish ----
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String custIdStr = request.getParameter("customer_id");
        String user = request.getParameter("user");
        if (user == null || user.isEmpty()) user = "OPERATOR";

        if ("CHANGE_STATUS".equals(action)) {
            String newStatus = request.getParameter("new_status");
            long custId = Long.parseLong(custIdStr);
            try {
                java.util.Map<String,Object> result = Mars.procedure("core_cif_service.Change_Status")
                    .in("customer_id", custId)
                    .in("new_status", newStatus)
                    .in("changed_by", user)
                    .outNumber("code")
                    .outString("message")
                    .outString("ora_message")
                    .execute();
                int code = ((Number) result.get("code")).intValue();
                String msg = (String) result.get("message");
                if (code == 0) {
                    response.sendRedirect("customer-detail.jsp?id=" + custId
                        + "&msg=" + java.net.URLEncoder.encode("Holat o'zgartirildi: " + newStatus, "UTF-8"));
                } else {
                    response.sendRedirect("customer-detail.jsp?id=" + custId
                        + "&err=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                }
                return;
            } catch (Exception e) {
                response.sendRedirect("customer-detail.jsp?id=" + custId
                    + "&err=" + java.net.URLEncoder.encode("Xatolik: " + e.getMessage(), "UTF-8"));
                return;
            }
        }
    }

    // ---- GET: Ma'lumotlar yuklash ----
    String idStr = request.getParameter("id");
    if (idStr == null || idStr.isEmpty()) {
        response.sendRedirect("customer-list.jsp");
        return;
    }
    long customerId = Long.parseLong(idStr);

    // Asosiy ma'lumotlar
    java.util.Map<String, Object> cust = null;
    // Hujjatlar
    java.util.List<java.util.Map<String, Object>> docs = new java.util.ArrayList<>();
    // Kontaktlar
    java.util.List<java.util.Map<String, Object>> contacts = new java.util.ArrayList<>();
    // Audit log
    java.util.List<java.util.Map<String, Object>> auditLogs = new java.util.ArrayList<>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = AbsDb.getConnection();

        // 1) Mijoz tafsiloti
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
            "       status, approved_by, approved_at, created_by, created_at, updated_by, updated_at " +
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
        rs.close(); ps.close();

        if (cust == null) {
            response.sendRedirect("customer-list.jsp?err=" + java.net.URLEncoder.encode("Mijoz topilmadi", "UTF-8"));
            return;
        }

        // 2) Hujjatlar
        ps = conn.prepareStatement(
            "SELECT doc_id, doc_type, doc_series, doc_number, issued_by, issued_date, " +
            "       expiry_date, is_primary, is_expired, days_to_expiry, created_at " +
            "  FROM core_cif_documents_ui_v WHERE customer_id = ? ORDER BY is_primary DESC, created_at DESC"
        );
        ps.setLong(1, customerId);
        rs = ps.executeQuery();
        while (rs.next()) {
            java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("doc_id",         rs.getLong("doc_id"));
            row.put("doc_type",       rs.getString("doc_type"));
            row.put("doc_series",     rs.getString("doc_series"));
            row.put("doc_number",     rs.getString("doc_number"));
            row.put("issued_by",      rs.getString("issued_by"));
            row.put("issued_date",    rs.getDate("issued_date"));
            row.put("expiry_date",    rs.getDate("expiry_date"));
            row.put("is_primary",     rs.getString("is_primary"));
            row.put("is_expired",     rs.getString("is_expired"));
            row.put("days_to_expiry", rs.getObject("days_to_expiry"));
            docs.add(row);
        }
        rs.close(); ps.close();

        // 3) Kontaktlar
        ps = conn.prepareStatement(
            "SELECT contact_id, contact_type, contact_value, is_primary, description, created_at " +
            "  FROM core_cif_contacts_ui_v WHERE customer_id = ? ORDER BY is_primary DESC, created_at DESC"
        );
        ps.setLong(1, customerId);
        rs = ps.executeQuery();
        while (rs.next()) {
            java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("contact_id",    rs.getLong("contact_id"));
            row.put("contact_type",  rs.getString("contact_type"));
            row.put("contact_value", rs.getString("contact_value"));
            row.put("is_primary",    rs.getString("is_primary"));
            row.put("description",   rs.getString("description"));
            row.put("created_at",    rs.getTimestamp("created_at"));
            contacts.add(row);
        }
        rs.close(); ps.close();

        // 4) Audit log (oxirgi 20 ta)
        ps = conn.prepareStatement(
            "SELECT * FROM (SELECT log_id, action_type, field_name, old_value, new_value, " +
            "       changed_by, changed_at FROM core_cif_audit_log_ui_v " +
            "  WHERE customer_id = ? ORDER BY changed_at DESC) WHERE ROWNUM <= 20"
        );
        ps.setLong(1, customerId);
        rs = ps.executeQuery();
        while (rs.next()) {
            java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("log_id",      rs.getLong("log_id"));
            row.put("action_type", rs.getString("action_type"));
            row.put("field_name",  rs.getString("field_name"));
            row.put("old_value",   rs.getString("old_value"));
            row.put("new_value",   rs.getString("new_value"));
            row.put("changed_by",  rs.getString("changed_by"));
            row.put("changed_at",  rs.getTimestamp("changed_at"));
            auditLogs.add(row);
        }
        rs.close(); ps.close();

    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (ps != null) try { ps.close(); } catch (Exception e) {}
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }

    request.setAttribute("c", cust);
    request.setAttribute("docs", docs);
    request.setAttribute("contacts", contacts);
    request.setAttribute("auditLogs", auditLogs);

    String custType = (String) cust.get("customer_type");
    String custStatus = (String) cust.get("status");
%>
<jsp:include page="cif-header.jsp">
    <jsp:param name="title" value="${c.full_name}"/>
    <jsp:param name="page" value="customers"/>
</jsp:include>

<div class="page-header">
    <h1>
        <span class="badge badge-<%= "INDIVIDUAL".equals(custType) ? "individual" : "corporate" %>">
            <%= "INDIVIDUAL".equals(custType) ? "FYaSh" : "YuSh" %>
        </span>
        ${c.full_name}
    </h1>
    <div class="action-buttons">
        <a href="customer-edit.jsp?id=<%= customerId %>" class="btn btn-primary">Tahrirlash</a>
        <a href="customer-list.jsp" class="btn">Ortga</a>
    </div>
</div>

<!-- ---- Umumiy ma'lumot kartochkasi ---- -->
<div class="info-row">
    <div class="card">
        <div class="card-title">Asosiy ma'lumotlar</div>
        <dl class="detail-grid-wide">
            <dt>CIF raqami</dt>
            <dd><strong>${c.cif_number}</strong></dd>
            <dt>Holat</dt>
            <dd>
                <span class="badge badge-<%= "ACTIVE".equals(custStatus) ? "active" : "PENDING".equals(custStatus) ? "pending" : "BLOCKED".equals(custStatus) ? "blocked" : "closed" %>">
                    <%= custStatus %>
                </span>
            </dd>
            <dt>Risk kategoriyasi</dt>
            <dd>
                <span class="badge badge-${c.risk_category == 'HIGH' ? 'high' : c.risk_category == 'MEDIUM' ? 'medium' : 'low'}">
                    ${c.risk_category}
                </span>
                <c:if test="${c.is_pep == 'Y'}">
                    <span class="badge badge-pep" style="margin-left:0.25rem;">PEP</span>
                </c:if>
            </dd>

            <% if ("INDIVIDUAL".equals(custType)) { %>
                <dt>PINFL</dt><dd>${c.pinfl}</dd>
                <dt>Tug'ilgan sana</dt>
                <dd><fmt:formatDate value="${c.birth_date}" pattern="dd.MM.yyyy"/> (${c.age} yosh)</dd>
                <dt>Jinsi</dt><dd>${c.gender == 'M' ? 'Erkak' : c.gender == 'F' ? 'Ayol' : '—'}</dd>
                <dt>Tug'ilgan joy</dt><dd>${c.birth_place}</dd>
            <% } else { %>
                <dt>STIR (INN)</dt><dd>${c.inn}</dd>
                <dt>Tashkiliy shakl</dt><dd>${c.org_form}</dd>
                <dt>To'liq nomi</dt><dd>${c.org_full_name}</dd>
                <dt>IFUT (OKED)</dt><dd>${c.oked}</dd>
                <dt>Ro'yxat raqami</dt><dd>${c.reg_number}</dd>
                <dt>Ro'yxat sanasi</dt>
                <dd><fmt:formatDate value="${c.reg_date}" pattern="dd.MM.yyyy"/></dd>
                <dt>Ro'yxat organi</dt><dd>${c.reg_authority}</dd>
            <% } %>

            <dt>Telefon</dt><dd>${c.phone}</dd>
            <dt>Email</dt><dd>${c.email}</dd>
            <dt>Filial</dt><dd>${c.branch_code}</dd>
            <dt>Rezident</dt><dd>${c.resident_flag == 'Y' ? 'Ha' : 'Yo\'q'} (${c.country_code})</dd>
        </dl>
    </div>

    <div class="card">
        <div class="card-title">
            <% if ("INDIVIDUAL".equals(custType)) { %>Ish joyi<% } else { %>Rahbariyat<% } %>
        </div>
        <dl class="detail-grid-wide">
            <% if ("INDIVIDUAL".equals(custType)) { %>
                <dt>Tashkilot</dt><dd>${c.employer_name}</dd>
                <dt>Lavozim</dt><dd>${c.employer_position}</dd>
                <dt>Manzil</dt><dd>${c.employer_address}</dd>
                <dt>Telefon</dt><dd>${c.employer_phone}</dd>
            <% } else { %>
                <dt>Rahbar</dt><dd>${c.director_name}</dd>
                <dt>Lavozim</dt><dd>${c.director_position}</dd>
                <dt>Rahbar PINFL</dt><dd>${c.director_pinfl}</dd>
                <dt>Bosh hisobchi</dt><dd>${c.accountant_name}</dd>
                <dt>Boshqa bank</dt><dd>${c.other_bank_name}</dd>
                <dt>MFO</dt><dd>${c.other_bank_mfo}</dd>
                <dt>Hisob</dt><dd>${c.other_bank_account}</dd>
            <% } %>
        </dl>

        <div class="section-title" style="margin-top:1.5rem;">Manzillar</div>
        <dl class="detail-grid-wide">
            <dt>Yuridik manzil</dt><dd>${c.legal_address}</dd>
            <dt>Haqiqiy manzil</dt><dd>${c.actual_address}</dd>
            <dt>Hisob maqsadi</dt><dd>${c.opening_purpose}</dd>
        </dl>

        <div class="section-title" style="margin-top:1.5rem;">Audit</div>
        <dl class="detail-grid-wide">
            <dt>Yaratgan</dt><dd>${c.created_by} — <fmt:formatDate value="${c.created_at}" pattern="dd.MM.yyyy HH:mm"/></dd>
            <dt>O'zgartirgan</dt>
            <dd>
                <c:choose>
                    <c:when test="${c.updated_by != null}">${c.updated_by} — <fmt:formatDate value="${c.updated_at}" pattern="dd.MM.yyyy HH:mm"/></c:when>
                    <c:otherwise>—</c:otherwise>
                </c:choose>
            </dd>
            <dt>Tasdiqlagan</dt>
            <dd>
                <c:choose>
                    <c:when test="${c.approved_by != null}">${c.approved_by} — <fmt:formatDate value="${c.approved_at}" pattern="dd.MM.yyyy HH:mm"/></c:when>
                    <c:otherwise>—</c:otherwise>
                </c:choose>
            </dd>
        </dl>
    </div>
</div>

<!-- ---- Holat o'zgartirish ---- -->
<% if (!"CLOSED".equals(custStatus)) { %>
<div class="card">
    <div class="card-title">Holat o'zgartirish</div>
    <form method="post" style="display:flex; gap:0.5rem; align-items:end; flex-wrap:wrap;" data-confirm="Mijoz holatini o'zgartirasizmi?">
        <input type="hidden" name="action" value="CHANGE_STATUS">
        <input type="hidden" name="customer_id" value="<%= customerId %>">
        <div class="form-group" style="margin-bottom:0;">
            <label>Yangi holat</label>
            <select name="new_status" class="form-control">
                <% if ("PENDING".equals(custStatus)) { %>
                    <option value="ACTIVE">ACTIVE</option>
                <% } else if ("ACTIVE".equals(custStatus)) { %>
                    <option value="BLOCKED">BLOCKED</option>
                    <option value="CLOSED">CLOSED</option>
                <% } else if ("BLOCKED".equals(custStatus)) { %>
                    <option value="ACTIVE">ACTIVE</option>
                    <option value="CLOSED">CLOSED</option>
                <% } %>
            </select>
        </div>
        <div class="form-group" style="margin-bottom:0;">
            <label>Operator</label>
            <input type="text" name="user" class="form-control" value="OPERATOR" style="width:150px;">
        </div>
        <button type="submit" class="btn btn-warning">O'zgartirish</button>
    </form>
</div>
<% } %>

<!-- ---- Hujjatlar ---- -->
<div class="card">
    <div class="card-title">Hujjatlar (${docs.size()})</div>
    <c:choose>
        <c:when test="${not empty docs}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Turi</th><th>Seriya</th><th>Raqam</th>
                            <th>Bergan organ</th><th>Berilgan sana</th>
                            <th>Muddat</th><th>Holat</th><th>Asosiy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="d" items="${docs}">
                            <tr class="${d.is_expired == 'Y' ? 'row-expired' : ''}">
                                <td><span class="badge badge-individual">${d.doc_type}</span></td>
                                <td>${d.doc_series}</td>
                                <td>${d.doc_number}</td>
                                <td>${d.issued_by}</td>
                                <td><fmt:formatDate value="${d.issued_date}" pattern="dd.MM.yyyy"/></td>
                                <td><fmt:formatDate value="${d.expiry_date}" pattern="dd.MM.yyyy"/></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${d.is_expired == 'Y'}">
                                            <span class="badge badge-high">Muddati o'tgan</span>
                                        </c:when>
                                        <c:when test="${d.days_to_expiry != null && d.days_to_expiry < 30}">
                                            <span class="badge badge-pending">${d.days_to_expiry} kun</span>
                                        </c:when>
                                        <c:when test="${d.days_to_expiry != null}">
                                            <span class="badge badge-low">${d.days_to_expiry} kun</span>
                                        </c:when>
                                        <c:otherwise>—</c:otherwise>
                                    </c:choose>
                                </td>
                                <td>${d.is_primary == 'Y' ? '&#9733;' : ''}</td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <div class="empty-state"><div class="message">Hujjat topilmadi</div></div>
        </c:otherwise>
    </c:choose>
</div>

<!-- ---- Kontaktlar ---- -->
<div class="card">
    <div class="card-title">Kontaktlar (${contacts.size()})</div>
    <c:choose>
        <c:when test="${not empty contacts}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr><th>Turi</th><th>Qiymat</th><th>Asosiy</th><th>Izoh</th><th>Sana</th></tr>
                    </thead>
                    <tbody>
                        <c:forEach var="ct" items="${contacts}">
                            <tr>
                                <td><span class="badge badge-individual">${ct.contact_type}</span></td>
                                <td>${ct.contact_value}</td>
                                <td>${ct.is_primary == 'Y' ? '&#9733;' : ''}</td>
                                <td>${ct.description}</td>
                                <td><fmt:formatDate value="${ct.created_at}" pattern="dd.MM.yyyy"/></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <div class="empty-state"><div class="message">Kontakt topilmadi</div></div>
        </c:otherwise>
    </c:choose>
</div>

<!-- ---- Audit log ---- -->
<div class="card">
    <div class="card-title">Audit log (oxirgi 20 ta)</div>
    <c:choose>
        <c:when test="${not empty auditLogs}">
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr><th>Amal</th><th>Maydon</th><th>Eski qiymat</th><th>Yangi qiymat</th><th>Kim</th><th>Qachon</th></tr>
                    </thead>
                    <tbody>
                        <c:forEach var="al" items="${auditLogs}">
                            <tr>
                                <td><span class="badge badge-${al.action_type == 'CREATE' ? 'active' : al.action_type == 'UPDATE' ? 'pending' : 'blocked'}">${al.action_type}</span></td>
                                <td>${al.field_name}</td>
                                <td style="max-width:200px; overflow:hidden; text-overflow:ellipsis;">${al.old_value}</td>
                                <td style="max-width:200px; overflow:hidden; text-overflow:ellipsis;">${al.new_value}</td>
                                <td>${al.changed_by}</td>
                                <td><fmt:formatDate value="${al.changed_at}" pattern="dd.MM.yyyy HH:mm"/></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <div class="empty-state"><div class="message">Audit log topilmadi</div></div>
        </c:otherwise>
    </c:choose>
</div>

<jsp:include page="cif-footer.jsp"/>

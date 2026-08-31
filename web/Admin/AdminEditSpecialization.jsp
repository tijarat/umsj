<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
    private String html(String value)
    {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
    if(adminSession == null)
    {
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
        return;
    }
    if(!adminSession.hasRightsOn("Specialization"))
    {
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Specialization service."/><%
        return;
    }
    String spId = request.getParameter("spId");
    if(spId == null || !spId.trim().matches("\\d+"))
    {
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", "A valid Specialization ID is required.");
        response.sendRedirect("AdminViewSpecialization.jsp");
        return;
    }
    spId = spId.trim();
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    Connection con = null;
    String selectedProgId = null;
    String spAbbrev = null;
    String spDesc = null;
    try
    {
        con = pool.getConnection();
        try(PreparedStatement ps = con.prepareStatement("SELECT SP.PROG_ID, SP.SPECIALIZATION_ABBREV, SP.SPECIALIZATION_DESC FROM UMS.SPECIALIZATION SP JOIN UMS.PROGRAM P ON SP.PROG_ID = P.PROG_ID WHERE SP.SP_ID = ? AND P.FACULTY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(spId));
            ps.setInt(2, adminSession.getWorkingFacultyId());
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next())
                {
                    selectedProgId = rs.getString("PROG_ID");
                    spAbbrev = rs.getString("SPECIALIZATION_ABBREV");
                    spDesc = rs.getString("SPECIALIZATION_DESC");
                }
            }
        }
        if(selectedProgId == null)
        {
            session.setAttribute("flashType", "error");
            session.setAttribute("flashMessage", "Specialization record was not found for the current faculty.");
            response.sendRedirect("AdminViewSpecialization.jsp");
            return;
        }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Specialization</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Specialization Management</h1><p>Edit a specialization for the current working faculty.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Specialization</h2><span>* Required fields</span></div><form action="AdminProcessEditSpecialization.jsp" method="post" class="ums-module-form"><input type="hidden" name="spId" value="<%=html(spId)%>"><div class="ums-form-grid"><div class="ums-field"><label for="progId">Program *</label><select name="progId" id="progId" required data-ums-search-select data-search-placeholder="Type program code or name..." data-search-label="Search Program"><option value="">Select Program</option>
<% try(PreparedStatement ps = con.prepareStatement("SELECT PROG_ID, PROG_CDE, PROG_NME FROM UMS.PROGRAM WHERE FACULTY_ID = ? ORDER BY PROG_CDE")) { ps.setInt(1, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String progId = rs.getString("PROG_ID"); %><option value="<%=html(progId)%>" <%=progId.equals(selectedProgId) ? "selected" : ""%>><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></option><% } } } %>
</select></div><div class="ums-field"><label for="spAbbrev">Specialization Abbreviation *</label><input name="spAbbrev" type="text" id="spAbbrev" maxlength="50" value="<%=html(spAbbrev)%>" autocomplete="off" required></div><div class="ums-field ums-field-full"><label for="spDesc">Specialization Description</label><textarea name="spDesc" id="spDesc" rows="3"><%=html(spDesc)%></textarea></div></div><div class="ums-form-actions"><button type="submit">Update Specialization</button><a class="ums-button-secondary" href="AdminViewSpecialization.jsp">Cancel</a></div></form></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
    }
    finally
    {
        pool.close(con);
    }
%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
private String html(String value)
{
    if(value == null) return "";
    return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}
private String url(String value) throws Exception
{
    return java.net.URLEncoder.encode(value == null ? "" : value, "UTF-8");
}
%>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Degree Completion Requirement"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Degree Completion Requirement service."/><%
return;
}
String batchId = request.getParameter("batchId");
if(batchId == null || !batchId.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","A valid Batch ID is required."); response.sendRedirect("AdminDegreeComReq.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
try
{
con = pool.getConnection();
String batchNbr = null;
String termCode = null;
String progCode = null;
String progName = null;
String crHrMin = null;
String cgpaMin = null;
String yearMin = null;
String yearMax = null;
String sql = "SELECT DISTINCT B.BATCH_NBR, B.TERM_CDE, P.PROG_CDE, P.PROG_NME, D.CR_HR_MIN, D.CGPA_MIN, D.YEAR_MIN, D.YEAR_MAX FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID JOIN UMS.DEGREE_COMP_REQ D ON D.BATCH_ID = B.BATCH_ID WHERE B.BATCH_ID = ? AND P.FACULTY_ID = ?";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setLong(1, Long.parseLong(batchId));
ps.setString(2, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
if(rs.next()) { batchNbr = rs.getString("BATCH_NBR"); termCode = rs.getString("TERM_CDE"); progCode = rs.getString("PROG_CDE"); progName = rs.getString("PROG_NME"); crHrMin = rs.getString("CR_HR_MIN"); cgpaMin = rs.getString("CGPA_MIN"); yearMin = rs.getString("YEAR_MIN"); yearMax = rs.getString("YEAR_MAX"); }
}
}
if(batchNbr == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Degree Completion Requirement was not found for this faculty."); response.sendRedirect("AdminDegreeComReq.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Degree Completion Requirement</title><link href="../extra/css/style.css?v=20260904" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Degree Completion Requirement</h1><p>Edit completion requirements for the selected batch.</p></div></section>
<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Edit Requirements</h2><span>* Required fields</span></div>
<form action="AdminProcessDegreeComReq.jsp" method="post" class="ums-module-form"><input type="hidden" name="batchId" value="<%=html(batchId)%>">
<div class="ums-form-grid">
<div class="ums-field"><label>Batch Number</label><div class="ums-readonly-value"><%=html(batchNbr)%></div></div>
<div class="ums-field"><label>Batch Term</label><div class="ums-readonly-value"><%=html(termCode)%></div></div>
<div class="ums-field ums-field-full"><label>Program</label><div class="ums-readonly-value"><%=html(progCode)%> - <%=html(progName)%></div></div>
<div class="ums-field"><label for="crMin">Min Credit Hour *</label><input type="number" id="crMin" name="crMin" min="0" step="1" value="<%=html(crHrMin)%>" required></div>
<div class="ums-field"><label for="cgpa">Min CGPA *</label><input type="number" id="cgpa" name="cgpa" min="0" max="4" step="0.01" value="<%=html(cgpaMin)%>" required></div>
<div class="ums-field"><label for="yearMin">Min Year *</label><input type="number" id="yearMin" name="yearMin" min="0" step="0.01" value="<%=html(yearMin)%>" required></div>
<div class="ums-field"><label for="yearMax">Max Year *</label><input type="number" id="yearMax" name="yearMax" min="0" step="0.01" value="<%=html(yearMax)%>" required></div>
</div>
<div class="ums-form-actions"><button type="submit">Update Requirements</button><a class="ums-button-secondary" href="AdminDegreeComReq.jsp">Cancel</a></div>
</form>
</section>
</main><script src="../extra/js/ums-module.js?v=20260904"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
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
String crHrMin = request.getParameter("crMin");
String yearMin = request.getParameter("yearMin");
String yearMax = request.getParameter("yearMax");
String cgpaMin = request.getParameter("cgpa");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(batchId == null || !batchId.matches("\\d+")) throw new SQLException("Invalid Batch ID.");
if(crHrMin == null || !crHrMin.matches("\\d+(\\.\\d+)?")) throw new SQLException("Invalid Minimum Credit Hour.");
if(cgpaMin == null || !cgpaMin.matches("\\d+(\\.\\d+)?")) throw new SQLException("Invalid Minimum CGPA.");
if(yearMin == null || !yearMin.matches("\\d+(\\.\\d+)?")) throw new SQLException("Invalid Minimum Year.");
if(yearMax == null || !yearMax.matches("\\d+(\\.\\d+)?")) throw new SQLException("Invalid Maximum Year.");
if(Double.parseDouble(cgpaMin) < 0 || Double.parseDouble(cgpaMin) > 4) throw new SQLException("Minimum CGPA must be between 0 and 4.");
if(Double.parseDouble(yearMin) > Double.parseDouble(yearMax)) throw new SQLException("Minimum Year cannot be greater than Maximum Year.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String sql = "UPDATE UMS.DEGREE_COMP_REQ D SET D.CR_HR_MIN = ?, D.YEAR_MAX = ?, D.YEAR_MIN = ?, D.CGPA_MIN = ? WHERE D.BATCH_ID = ? AND EXISTS (SELECT 1 FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE B.BATCH_ID = D.BATCH_ID AND P.FACULTY_ID = ?)";
int updated = 0;
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setBigDecimal(1, new java.math.BigDecimal(crHrMin));
ps.setBigDecimal(2, new java.math.BigDecimal(yearMax));
ps.setBigDecimal(3, new java.math.BigDecimal(yearMin));
ps.setBigDecimal(4, new java.math.BigDecimal(cgpaMin));
ps.setLong(5, Long.parseLong(batchId));
ps.setString(6, adminSession.getWorkingFacultyId());
updated = ps.executeUpdate();
}
if(updated == 0) throw new SQLException("Degree Completion Requirement was not found for this faculty.");
adminSession.addLog("UPDATE UMS.DEGREE_COMP_REQ BATCH_ID=" + batchId + ", CR_HR_MIN=" + crHrMin + ", YEAR_MIN=" + yearMin + ", YEAR_MAX=" + yearMax + ", CGPA_MIN=" + cgpaMin, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Degree Completion Requirement has been updated successfully.");
response.sendRedirect("AdminDegreeComReq.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage() == null ? "Unable to update Degree Completion Requirement." : e.getMessage());
response.sendRedirect("AdminEditDegreeComReq.jsp?batchId=" + (batchId == null ? "" : batchId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>
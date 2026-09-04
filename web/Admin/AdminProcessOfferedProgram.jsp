<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Offered Program"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Offered Program service."/><%
return;
}
String termCde = request.getParameter("term");
String prog = request.getParameter("prog");
String action = request.getParameter("effet");
String id = request.getParameter("id");
if(termCde == null) termCde = "";
if(prog == null) prog = "";
if(action == null) action = "";
if(id == null) id = "";
termCde = termCde.trim();
prog = prog.trim();
action = action.trim();
id = id.trim();
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
if("Add".equalsIgnoreCase(action))
{
if(termCde.length() == 0) throw new SQLException("Term is required.");
if(!prog.matches("\\d+")) throw new SQLException("Program is required.");
int allowedTerm = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM (SELECT TERM_CDE FROM (SELECT TERM_CDE, START_DTE FROM UMS.TERM WHERE TERM_CDE LIKE 'F%' OR TERM_CDE LIKE 'S%' ORDER BY START_DTE DESC) WHERE ROWNUM <= 4) WHERE TERM_CDE = ?")) { ps.setString(1, termCde); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowedTerm = rs.getInt(1); } }
if(allowedTerm == 0) throw new SQLException("Selected Term is not available for Offered Program.");
int allowedProgram = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.PROGRAM P WHERE P.PROG_ID = ? AND P.FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(prog)); ps.setString(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowedProgram = rs.getInt(1); } }
if(allowedProgram == 0) throw new SQLException("Selected Program does not belong to the working faculty.");
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.OFFERED_PROGRAM (OP_ID, TERM_CDE, PROG_ID) VALUES (UMS.SEQ_OP_ID.NEXTVAL, ?, ?)")) { ps.setString(1, termCde); ps.setLong(2, Long.parseLong(prog)); ps.executeUpdate(); }
adminSession.addLog("INSERT UMS.OFFERED_PROGRAM TERM_CDE=" + termCde + ", PROG_ID=" + prog, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Offered Program has been added successfully.");
response.sendRedirect("AdminOfferedProgram.jsp?term=" + java.net.URLEncoder.encode(termCde,"UTF-8"));
}
else if("effacer".equalsIgnoreCase(action))
{
if(!id.matches("\\d+")) throw new SQLException("Invalid Offered Program ID.");
String deleteSql = "DELETE FROM UMS.OFFERED_PROGRAM OP WHERE OP.OP_ID = ? AND EXISTS (SELECT 1 FROM UMS.PROGRAM P WHERE P.PROG_ID = OP.PROG_ID AND P.FACULTY_ID = ?)";
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement(deleteSql)) { ps.setLong(1, Long.parseLong(id)); ps.setString(2, adminSession.getWorkingFacultyId()); deleted = ps.executeUpdate(); }
if(deleted == 0) throw new SQLException("Offered Program was not found for the working faculty.");
adminSession.addLog("DELETE UMS.OFFERED_PROGRAM OP_ID=" + id, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Offered Program has been deleted successfully.");
response.sendRedirect("AdminOfferedProgram.jsp?term=" + java.net.URLEncoder.encode(termCde,"UTF-8"));
}
else
{
throw new SQLException("Invalid Offered Program action.");
}
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String message = e.getMessage() == null ? "Unable to process Offered Program." : e.getMessage();
if(message.indexOf("ORA-00001") >= 0) message = "This Program is already offered in the selected Term.";
if(message.indexOf("ORA-02292") >= 0) message = "This Offered Program is referenced by other records and cannot be deleted.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",message);
response.sendRedirect("AdminOfferedProgram.jsp?term=" + java.net.URLEncoder.encode(termCde,"UTF-8"));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>
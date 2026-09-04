<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Academic Calendar"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Academic Calendar service."/><%
return;
}
String term = request.getParameter("termCode");
String count = request.getParameter("count");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(term == null || term.trim().length() == 0) throw new SQLException("Term is required.");
if(count == null || !count.matches("\\d+")) throw new SQLException("Invalid calendar row count.");
term = term.trim();
int rows = Integer.parseInt(count);
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int termExists = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.TERM WHERE TERM_CDE = ?")) { ps.setString(1,term); try(ResultSet rs=ps.executeQuery()) { if(rs.next()) termExists=rs.getInt(1); } }
if(termExists == 0) throw new SQLException("Selected Term does not exist.");
int updated = 0;
String sql = "UPDATE UMS.ACADEMIC_CALENDAR SET START_DATE = TO_DATE(?,'DD/MM/YYYY'), END_DATE = CASE WHEN ? IS NULL THEN NULL ELSE TO_DATE(?,'DD/MM/YYYY') END WHERE ACTIVITY_ID = ? AND TERM_CDE = ?";
try(PreparedStatement ps = con.prepareStatement(sql))
{
for(int i=1;i<=rows;i++)
{
String id=request.getParameter("activityId"+i);
String start=request.getParameter("startDate"+i);
String end=request.getParameter("endDate"+i);
if(id == null || !id.matches("\\d+")) throw new SQLException("Invalid Activity ID.");
if(start == null || !start.matches("\\d{2}/\\d{2}/\\d{4}")) throw new SQLException("Invalid Start Date for activity " + id + ".");
if(end != null) end=end.trim();
if(end != null && end.length() > 0 && !end.matches("\\d{2}/\\d{2}/\\d{4}")) throw new SQLException("Invalid End Date for activity " + id + ".");
if(end != null && end.length() > 0)
{
int valid=0;
try(PreparedStatement datePs=con.prepareStatement("SELECT CASE WHEN TO_DATE(?,'DD/MM/YYYY') <= TO_DATE(?,'DD/MM/YYYY') THEN 1 ELSE 0 END FROM DUAL")) { datePs.setString(1,start); datePs.setString(2,end); try(ResultSet rs=datePs.executeQuery()) { if(rs.next()) valid=rs.getInt(1); } }
if(valid != 1) throw new SQLException("Start Date must be less than or equal to End Date.");
}
ps.setString(1,start);
if(end == null || end.length() == 0) { ps.setNull(2,Types.VARCHAR); ps.setNull(3,Types.VARCHAR); } else { ps.setString(2,end); ps.setString(3,end); }
ps.setLong(4,Long.parseLong(id));
ps.setString(5,term);
updated += ps.executeUpdate();
}
}
adminSession.addLog("UPDATE UMS.ACADEMIC_CALENDAR TERM_CDE=" + term + ", ROWS=" + updated, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage",updated + " Academic Calendar record(s) updated successfully.");
response.sendRedirect("AdminAcademicCalendar.jsp?termCode=" + java.net.URLEncoder.encode(term,"UTF-8"));
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg=e.getMessage()==null ? "Unable to update Academic Calendar." : e.getMessage();
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminAcademicCalendar.jsp?termCode=" + java.net.URLEncoder.encode(term == null ? "" : term,"UTF-8"));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>
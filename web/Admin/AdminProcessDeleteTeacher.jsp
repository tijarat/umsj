<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) { %><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><% return; }
    if(!adminSession.hasRightsOn("Teacher")) { %><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher service."/><% return; }
    Connection con = null;
    try {
        String teacherIdValue = request.getParameter("tchrId");
        if(teacherIdValue == null || !teacherIdValue.matches("\\d+")) throw new SQLException("Invalid Teacher ID.");
        int teacherId = Integer.parseInt(teacherIdValue);
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.TEACHER WHERE TCHR_ID=?")) { ps.setInt(1,teacherId); if(ps.executeUpdate() == 0) throw new SQLException("Teacher was not found."); }
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("DELETE UMS.TEACHER TCHR_ID=" + teacherId,logStmt); }
        con.commit();
        session.setAttribute("flashType","success");
        session.setAttribute("flashMessage","Teacher has been deleted successfully.");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String message = e.getMessage() == null ? "Unable to delete Teacher." : e.getMessage();
        if(message.indexOf("ORA-02292") >= 0) message = "This Teacher contains child records and cannot be deleted.";
        session.setAttribute("flashType","error");
        session.setAttribute("flashMessage",message);
    } finally {
        if(con != null) pool.close(con);
    }
    response.sendRedirect("AdminTeacher.jsp");
%>

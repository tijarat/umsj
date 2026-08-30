<%@page import="com.ums.packages.StudentContainer"%>
<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.sql.*,com.ums.packages.*" pageEncoding="UTF-8" errorPage="../error.jsp"%>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    public void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminHomeTop.jsp::" + user + "::" + message);
    }

    public String html(String value)
    {
        if(value == null)  return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    com.ums.packages.LocalSession adminSession =  (com.ums.packages.LocalSession) session.getAttribute("adminSession"); 
    if(adminSession == null)
    {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }
    Connection con = pool.getConnection();
    boolean isFaculty = Boolean.TRUE.equals(session.getAttribute("isFaculty"));

    if("true".equalsIgnoreCase(request.getParameter("workingFacultyChanged")))
    {
        StudentContainer studentDetail = (StudentContainer) session.getAttribute("currentStudent");
        if(studentDetail != null)
        {
%>
            <jsp:useBean id="userContainer" scope="application" class="com.ums.packages.Container"/>
            <jsp:useBean id="adminSectionList" scope="session" class="com.ums.packages.ReserveSection"/>
<%
            userContainer.removeUser(studentDetail.regNbr);
            session.removeAttribute("currentStudent");
        }

        String workingFaculty = request.getParameter("workingFaculty");
        if(workingFaculty != null && !workingFaculty.trim().equals(""))  adminSession.setWorkingFaculty(con, workingFaculty);
    }

    String currentTerm = pool.getCurrentTerm( adminSession.getWorkingFacultyId(), con);
    if(adminSession.hasRightsOn("Change Working Term") && "true".equalsIgnoreCase(request.getParameter("workingTermChanged")))
    {
        String workingTerm = request.getParameter("workingTerm");
        if(workingTerm != null && !workingTerm.trim().equals("")) adminSession.workingTerm = workingTerm;
        StudentContainer studentDetail = (StudentContainer) session.getAttribute("currentStudent");
        if(studentDetail != null && (studentDetail.regNbr.length() == 13 || studentDetail.regNbr.length() == 12))
            studentDetail.initStudentDetail(studentDetail.regNbr, studentDetail.password, currentTerm,  pool.getWorkingTerm(), adminSession.workingTerm, con);
    }

    String workingTerm = adminSession.workingTerm == null ? currentTerm : adminSession.workingTerm;
    String notification = request.getParameter("notification");
    String changePasswordText = "Change Password";

    if(notification != null && !notification.trim().equals("") && !"null".equalsIgnoreCase(notification) && !"Change Password".equalsIgnoreCase(notification))
        changePasswordText = "Expires in " + notification + " day(s) - Change Password";
%>
<form name="form1" id="umsTopForm" method="post" action="AdminHome.jsp" target="_top">
    <input type="hidden" name="workingTermChanged" value="false">
    <input type="hidden" name="workingFacultyChanged" value="false">
    <div class="ums-top-brand">
        <a href="AdminHome.jsp?refresh=T" target="_top" class="ums-top-home" title="Refresh UMS">
            <%=isFaculty ? "T" : "A"%>
        </a>
        <div class="ums-top-brand-text">
            <strong>UMS Online</strong>
            <span><%=isFaculty ? "Teacher Services" : "Administrator Services"%></span>
        </div>
    </div>
    <div class="ums-top-context">
        <div class="ums-top-field ums-top-faculty">
            <label for="workingFaculty">Working Faculty</label>
            <select id="workingFaculty" class="ums-working-faculty" name="workingFaculty" onchange="changeWorkingFaculty();">
<%
                String facultySql =
                    "SELECT F.FACULTY_ID, F.FACULTY_ABBREV, C.CMP_ABBERV, C.CMP_PREFIX, " +
                    "C.FRANCHISE, U.UNI_ABBREV ABBR, CT.SUB_CITY_NAME " +
                    "FROM WEB_USERS_FACULTY WUF " +
                    "JOIN FACULTY F ON F.FACULTY_ID = WUF.FACULTY_ID " +
                    "JOIN CAMPUS C ON C.CMP_ID = F.CMP_ID " +
                    "JOIN UMS.UNIVERSITY U ON U.UNI_ID = C.UNI_ID " +
                    "JOIN UMS.SUB_CITY CT ON CT.SUB_CITY_ID = C.SUB_CITY_ID " +
                    "WHERE WUF.USER_NME = ? " +
                    "AND F.ACTIVE_STATUS = 'Y' " +
                    "ORDER BY C.CMP_ABBERV, U.UNI_ABBREV, F.FACULTY_ABBREV";

                String previousCampus = null;
                int campusGroup = -1;

                try(PreparedStatement facultyStmt = con.prepareStatement(facultySql))
                {
                    facultyStmt.setString(1, adminSession.user);
                    try(ResultSet facultyRs = facultyStmt.executeQuery())
                    {
                        while(facultyRs.next())
                        {
                            String facultyId = facultyRs.getString("FACULTY_ID");
                            String campusAbbr = facultyRs.getString("CMP_ABBERV");
                            if(previousCampus == null || !previousCampus.equalsIgnoreCase(campusAbbr))
                            {
                                previousCampus = campusAbbr;
                                campusGroup++;
                            }
                            if(adminSession.getWorkingFaculty() == null || adminSession.getWorkingFaculty().trim().equals(""))
                                adminSession.setWorkingFaculty(con, facultyId);
                            boolean selected = facultyId.equals(adminSession.getWorkingFacultyId());
                            boolean primaryCampus = "N".equalsIgnoreCase(facultyRs.getString("FRANCHISE"));

                            String optionClass = "ums-faculty-option";
                            if(campusGroup % 2 != 0)
                                optionClass += " ums-faculty-option-alt";
                            if(primaryCampus)
                                optionClass += " ums-faculty-option-primary";
                            String optionText = facultyRs.getString("CMP_ABBERV") + "-" + facultyRs.getString("ABBR") + "(" + facultyRs.getString("CMP_PREFIX") + ") - " + facultyRs.getString("FACULTY_ABBREV") + " - " + facultyRs.getString("SUB_CITY_NAME");
%>
                            <option value="<%=html(facultyId)%>" class="<%=optionClass%>"<%=selected ? "selected=\"selected\"" : ""%>><%=html(optionText)%></option>
<%
                        }
                    }
                }
%>
            </select>
        </div>

<%
        if(adminSession.hasRightsOn("Change Working Term"))
        {
%>
            <div class="ums-top-field ums-top-term">
                <label for="workingTerm">Working Term</label>
                <select id="workingTerm" name="workingTerm" onchange="changeWorkingTerm();">
<%
                    String termSql =
                        "SELECT CR.TERM_CDE " +
                        "FROM CURRENT_TERM CR " +
                        "WHERE CR.FACULTY_ID = ? " +
                        "UNION " +
                        "SELECT T.TERM_CDE " +
                        "FROM UMS.TERM T " +
                        "JOIN UMS.USER_TERM_ALLOCATION UTA ON UTA.TERM_CDE = T.TERM_CDE " +
                        "WHERE UTA.FACULTY_ID = ? " +
                        "AND UTA.FRM_DTE <= SYSDATE " +
                        "AND UTA.TO_DTE >= SYSDATE " +
                        "AND UPPER(UTA.USER_NME) = ? " +
                        "UNION " +
                        "SELECT T.TERM_CDE " +
                        "FROM UMS.TERM T " +
                        "JOIN UMS.USER_TERM_ALLOCATION UTA ON UTA.TERM_CDE = T.TERM_CDE " +
                        "WHERE UTA.FACULTY_ID = ? " +
                        "AND UTA.FRM_DTE IS NULL " +
                        "AND UTA.TO_DTE IS NULL " +
                        "AND UPPER(UTA.USER_NME) = ? " +
                        "ORDER BY 1";

                    try(PreparedStatement termStmt = con.prepareStatement(termSql))
                    {
                        termStmt.setString(1, adminSession.getWorkingFacultyId());
                        termStmt.setString(2, adminSession.getWorkingFacultyId());
                        termStmt.setString(3, adminSession.user == null ? "" : adminSession.user.toUpperCase());
                        termStmt.setString(4, adminSession.getWorkingFacultyId());
                        termStmt.setString(5, adminSession.user == null ? "" : adminSession.user.toUpperCase());
                        try(ResultSet termRs = termStmt.executeQuery())
                        {
                            while(termRs.next())
                            {
                                String termCode = termRs.getString("TERM_CDE");
%>
                                <option value="<%=html(termCode)%>" <%=termCode.equals(workingTerm) ? "selected=\"selected\"" : ""%>><%=html(termCode)%></option>
<%
                            }
                        }
                    }
%>
                </select>
            </div>
<%
        }
        pool.close(con);
%>
        <div class="ums-top-current-term">
            <span>Current Term</span>
            <strong><%=html(currentTerm)%></strong>
        </div>
    </div>
    <div class="ums-top-actions">
        <a href="../webDocs/UCPWeb_Documentation.htm" target="_blank" rel="noopener noreferrer">Help</a>
        <a href="AdminChangePass.jsp" target="mainFrame" class="<%=changePasswordText.startsWith("Expires") ? "ums-admin-password-warning" : ""%>">
            <%=html(changePasswordText)%>
        </a>
        <a href="AdminLogoff.jsp" target="_parent" class="ums-top-logoff">Log off <%=html(adminSession.user)%></a>
    </div>
</form>
<script>
    function changeWorkingTerm()
    {
        document.form1.workingTermChanged.value = "true";
        document.form1.submit();
    }

    function changeWorkingFaculty()
    {
        document.form1.workingFacultyChanged.value = "true";
        document.form1.submit();
    }
</script>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.util.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminTeacher.jsp::" + user + "::" + message);
    }
    private String html(String value) {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
    private String val(String value) {
        return value == null ? "" : value.trim();
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }
    if(!adminSession.hasRightsOn("Teacher")) {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher service."/>
<%
        return;
    }
    if(!response.isCommitted()) {
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    }
    String flashType = (String) session.getAttribute("flashType");
    String flashMessage = (String) session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    Connection con = null;
    try {
        con = pool.getConnection();
        int workingFacultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
        List<String[]> designations = new ArrayList<String[]>();
        try(PreparedStatement ps = con.prepareStatement("SELECT DESIG_ID, LONG_DESIG FROM UMS.DESIGNATION ORDER BY LONG_DESIG"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) designations.add(new String[]{String.valueOf(rs.getInt("DESIG_ID")),rs.getString("LONG_DESIG")});
        }
        List<String[]> cities = new ArrayList<String[]>();
        try(PreparedStatement ps = con.prepareStatement("SELECT SUB_CITY_ID, SUB_CITY_NAME FROM UMS.SUB_CITY ORDER BY SUB_CITY_NAME"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) cities.add(new String[]{String.valueOf(rs.getInt("SUB_CITY_ID")),rs.getString("SUB_CITY_NAME")});
        }
        int campusId = 0;
        try(PreparedStatement ps = con.prepareStatement("SELECT CMP_ID FROM UMS.FACULTY WHERE FACULTY_ID = ?")) {
            ps.setInt(1, workingFacultyId);
            try(ResultSet rs = ps.executeQuery()) {
                if(rs.next()) campusId = rs.getInt(1);
            }
        }
        List<String[]> teachers = new ArrayList<String[]>();
        String teacherSql = "SELECT T.TCHR_ID,T.TCHR_NME,T.TCHR_ABBR,NVL(T.EMAIL_TXT,'N/A') EMAIL_TXT,NVL(WU.USER_NME,'---') USER_NME,NVL(T.NIC,'') NIC,T.STATUS_IND,NVL(D.LONG_DESIG,'') LONG_DESIG,NVL(T.TYPE_IND,'') TYPE_IND FROM UMS.TEACHER T LEFT JOIN UMS.WEB_USERS WU ON WU.TCHR_ID = T.TCHR_ID LEFT JOIN UMS.DESIGNATION D ON D.DESIG_ID = T.DESIG_ID LEFT JOIN UMS.FACULTY F ON F.FACULTY_ID = T.FACULTY_ID WHERE F.CMP_ID = ? ORDER BY T.TCHR_NME";
        try(PreparedStatement ps = con.prepareStatement(teacherSql)) {
            ps.setInt(1, campusId);
            try(ResultSet rs = ps.executeQuery()) {
                while(rs.next()) teachers.add(new String[]{String.valueOf(rs.getInt("TCHR_ID")),rs.getString("TCHR_NME"),rs.getString("TCHR_ABBR"),rs.getString("EMAIL_TXT"),rs.getString("USER_NME"),rs.getString("NIC"),rs.getString("STATUS_IND"),rs.getString("LONG_DESIG"),rs.getString("TYPE_IND")});
            }
        }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Management</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-teacher" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Teacher Management</h1>
            <p>Create and maintain faculty profiles, login accounts, designation, availability and campus access.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header"><h2>Define Teacher</h2><span>* Required fields</span></div>
        <form action="AdminProcessTeacher.jsp" method="post" name="teacherForm" id="teacherForm" class="ums-module-form" data-ums-teacher-form="add">
            <div class="ums-info-strip"><div><strong>Faculty:</strong> <%=html(adminSession.getWorkingFaculty())%></div></div>
            <div class="ums-form-grid">
                <div class="ums-field"><label for="tchrTitle">Title</label><select name="tchrTitle" id="tchrTitle"><option value="DR. ">Dr.</option><option value="PROF. ">Prof.</option></select></div>
                <div class="ums-field"><label for="tchrName">Teacher Name *</label><input name="tchrName" id="tchrName" type="text" maxlength="80" value="<%=html(val(request.getParameter("tchrName")))%>" required></div>
                <div class="ums-field"><label for="tchrAbbr">Teacher Abbreviation *</label><input name="tchrAbbr" id="tchrAbbr" type="text" maxlength="20" value="<%=html(val(request.getParameter("tchrAbbr")))%>" required></div>
                <div class="ums-field"><label for="tchrEmail">Email *</label><input name="tchrEmail" id="tchrEmail" type="email" maxlength="80" value="<%=html(val(request.getParameter("tchrEmail")))%>" required></div>
                <div class="ums-field ums-field-wide"><label for="tchrAddr">Home Address</label><input name="tchrAddr" id="tchrAddr" type="text" maxlength="100" value="<%=html(val(request.getParameter("tchrAddr")))%>"></div>
                <div class="ums-field"><label for="tchrPhone">Home Phone</label><input name="tchrPhone" id="tchrPhone" type="text" maxlength="20" value="<%=html(val(request.getParameter("tchrPhone")))%>"></div>
                <div class="ums-field"><label for="tchrCell">Cell Number</label><input name="tchrCell" id="tchrCell" type="text" maxlength="20" value="<%=html(val(request.getParameter("tchrCell")))%>"></div>
                <div class="ums-field ums-field-wide"><label for="tchrOffAddr">Office Address</label><input name="tchrOffAddr" id="tchrOffAddr" type="text" maxlength="100" value="<%=html(val(request.getParameter("tchrOffAddr")))%>"></div>
                <div class="ums-field"><label for="tchrOffPhone">Office Phone</label><input name="tchrOffPhone" id="tchrOffPhone" type="text" maxlength="20" value="<%=html(val(request.getParameter("tchrOffPhone")))%>"></div>
                <div class="ums-field"><label for="tchrOffPhoneExt">Extension</label><input name="tchrOffPhoneExt" id="tchrOffPhoneExt" type="text" maxlength="4" value="<%=html(val(request.getParameter("tchrOffPhoneExt")))%>"></div>
                <div class="ums-field"><label for="tchrPersonalWebURL">Personal Web URL</label><input name="tchrPersonalWebURL" id="tchrPersonalWebURL" type="text" maxlength="128" value="<%=html(val(request.getParameter("tchrPersonalWebURL")))%>"></div>
                <div class="ums-field"><label for="joinDateDisplay">Joining Date</label><div class="ums-date-picker"><input type="text" id="joinDateDisplay" class="ums-date-display" value="<%=html(val(request.getParameter("joinDate")))%>" readonly><input type="hidden" name="joinDate" id="joinDate" value="<%=html(val(request.getParameter("joinDate")))%>"><button type="button" class="ums-date-button" aria-label="Choose joining date">ðŸ“…</button><input type="date" id="joinDatePicker" class="ums-native-date" tabindex="-1"></div></div>
                <div class="ums-field"><label for="typeInd">Teacher Type *</label><select name="typeInd" id="typeInd" data-ums-teacher-type required><option value="V">Visiting</option><option value="P">Permanent</option></select></div>
                <div class="ums-field"><label for="rte">Teacher Rate</label><input name="rte" id="rte" type="number" min="0" max="99999" step="1"><small>Required for visiting faculty.</small></div>
                <div class="ums-field"><label for="tchrDesigId">Designation</label><select name="tchrDesigId" id="tchrDesigId"><option value="">-- Select --</option><% for(String[] row : designations) { %><option value="<%=row[0]%>"><%=html(row[1])%></option><% } %></select></div>
                <div class="ums-field"><label for="nic">CNIC *</label><input name="nic" id="nic" type="text" inputmode="numeric" maxlength="13" value="<%=html(val(request.getParameter("nic")))%>" required><small>13 digits without dashes.</small></div>
                <div class="ums-field"><label for="cityId">Additional Campus City</label><select name="cityId" id="cityId"><option value="-">-- Select campus city --</option><% for(String[] row : cities) { %><option value="<%=row[0]%>"><%=html(row[1])%></option><% } %></select></div>
                <div class="ums-field ums-field-check"><label class="ums-check-label"><input name="available" id="available" type="checkbox" value="A" checked><span>Teacher Available</span></label></div>
            </div>
            <div class="ums-section-divider"><span>User Account</span></div>
            <div class="ums-form-grid">
                <div class="ums-field"><label for="userName">Username *</label><input name="userName" id="userName" type="text" maxlength="20" value="<%=html(val(request.getParameter("userName")))%>" autocomplete="off" required><small>Letters, numbers, period and underscore only.</small></div>
                <div class="ums-field"><label for="role">Role *</label><select name="role" id="role"><option value="A">Advisor</option></select></div>
                <div class="ums-field"><label for="password">Password *</label><input name="password" id="password" type="password" minlength="6" maxlength="100" autocomplete="new-password" required></div>
                <div class="ums-field"><label for="retypePassword">Retype Password *</label><input name="retypePassword" id="retypePassword" type="password" minlength="6" maxlength="100" autocomplete="new-password" required></div>
                <div class="ums-field ums-field-check"><label class="ums-check-label"><input name="activeInd" id="activeInd" type="checkbox" value="Y" checked><span>Login Active</span></label></div>
            </div>
            <div class="ums-form-actions"><button type="submit">Add Teacher</button></div>
        </form>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div><% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Teachers</h2><span><%=teachers.size()%> record(s)</span></div><div class="ums-module-tools"><input type="search" id="teacherSearch" data-ums-table-search="teacherTable" placeholder="Search teacher, abbreviation, email, username or CNIC" autocomplete="off"><button type="button" class="ums-export-button" data-ums-table-export="teacherTable" title="Export current Teacher list to Excel"><span class="ums-export-icon">â‡©</span>Export to Excel</button></div></div>
        <div class="ums-table-wrap"><table class="ums-data-table" id="teacherTable" data-ums-table data-export-file="Teachers"><thead><tr><th data-sort-type="number">Sr</th><th>Teacher Name</th><th>Abbreviation</th><th>Email</th><th>Username</th><th>CNIC</th><th>Designation</th><th>Type</th><th>Status</th><th data-export-ignore>Actions</th></tr></thead><tbody>
<% int sr = 0; for(String[] row : teachers) { sr++; boolean active = "A".equalsIgnoreCase(row[6]); %>
            <tr><td><%=sr%></td><td><%=html(row[1])%></td><td><%=html(row[2])%></td><td><%=html(row[3])%></td><td><%=html(row[4])%></td><td><%=html(row[5])%></td><td><%=html(row[7])%></td><td><%= "P".equalsIgnoreCase(row[8]) ? "Permanent" : "V".equalsIgnoreCase(row[8]) ? "Visiting" : "" %></td><td><span class="ums-status-badge <%=active ? "ums-status-active" : "ums-status-inactive"%>"><%=active ? "Available" : "Not Available"%></span></td><td class="ums-actions"><a href="AdminEditTeacher.jsp?tchrId=<%=row[0]%>">Edit</a><a href="AdminProcessDeleteTeacher.jsp?tchrId=<%=row[0]%>" class="ums-action-danger" data-ums-confirm="Are you sure you want to delete <%=html(row[1])%>?">Delete</a></td></tr>
<% } %>
        </tbody></table></div>
        <div class="ums-table-footer"><div class="ums-page-size"><label for="teacherPageSize">Rows per page</label><select id="teacherPageSize" data-ums-page-size="teacherTable"><option value="5">5</option><option value="10" selected>10</option><option value="25">25</option><option value="50">50</option><option value="100">100</option></select></div><div class="ums-pagination-info" data-ums-page-info="teacherTable"></div><div class="ums-pagination"><button type="button" data-ums-page-prev="teacherTable">Previous</button><div class="ums-page-numbers" data-ums-page-numbers="teacherTable"></div><button type="button" data-ums-page-next="teacherTable">Next</button></div></div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/teacher.js?v=20260830"></script>
</body>
</html>
<%
    } finally {
        if(con != null) pool.close(con);
    }
%>

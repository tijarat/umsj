<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminTerm.jsp::" + user + "::" + message);
    }

    private String html(String value) 
    {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }

    private String url(String value) throws Exception 
    {
        return URLEncoder.encode(value == null ? "" : value, "UTF-8");
    }
%>
<%
    System.out.println("### AdminTerm.jsp START ###");
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    System.out.println("### adminSession = " + adminSession);
    if(adminSession == null) 
    {System.out.println("### SESSION NULL - FORWARDING TO SessionExpire.jsp ###");
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    if(!adminSession.hasRightsOn("Term")) 
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term service."/>
<%
        return;
    }
    com.ums.db.Pool pool =   (com.ums.db.Pool) application.getAttribute("pool");
    if(!response.isCommitted()) 
    {
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    }

    String flashType = (String) session.getAttribute("flashType");
    String flashMessage = (String) session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    String sql = "";

    Connection con = null;
    PreparedStatement termStmt = null;
    ResultSet termRs = null;

    try 
    {
        con = pool.getConnection();
        sql = "SELECT TERM_CDE, TERM_NME, TO_CHAR(START_DTE,'DD-MM-YYYY') START_DTE, TO_CHAR(END_DTE,'DD-MM-YYYY') END_DTE, STATUS_TYP FROM UMS.TERM ORDER BY START_DTE DESC";
        termStmt = con.prepareStatement(sql);
        termRs = termStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Define Term</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Term Management</h1>
            <p>Create and maintain Spring, Summer and Fall terms.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Define Term</h2>
            <span>* Required fields</span>
        </div>

        <form action="AdminProcessTerm.jsp" method="post" name="termForm" id="termForm"
              class="ums-module-form" data-ums-term-form="add">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label for="termCode">Term Code *</label>
                    <input name="termCode" type="text" id="termCode" maxlength="3"
                           autocomplete="off" required>
                    <small>Example: S26, R26, F26</small>
                </div>

                <div class="ums-field">
                    <label for="termName">Term Name *</label>
                    <input name="termName" type="text" id="termName" maxlength="30" required>
                </div>

                <div class="ums-field">
                    <label for="startDateDisplay">Start Date *</label>
                    <div class="ums-date-picker">
                        <input type="text" id="startDateDisplay" class="ums-date-display"
                               placeholder="DD-MM-YYYY" readonly>
                        <button type="button" class="ums-date-button"
                                aria-label="Select start date">&#128197;</button>
                        <input type="date" id="startDatePicker" class="ums-native-date"
                               aria-label="Start Date">
                        <input type="hidden" name="startDate" id="startDate">
                    </div>
                </div>

                <div class="ums-field">
                    <label for="endDateDisplay">End Date *</label>
                    <div class="ums-date-picker">
                        <input type="text" id="endDateDisplay" class="ums-date-display"
                               placeholder="DD-MM-YYYY" readonly>
                        <button type="button" class="ums-date-button"
                                aria-label="Select end date">&#128197;</button>
                        <input type="date" id="endDatePicker" class="ums-native-date"
                               aria-label="End Date">
                        <input type="hidden" name="endDate" id="endDate">
                    </div>
                </div>

                <div class="ums-field ums-field-check">
                    <label class="ums-check-label">
                        <input name="status" type="checkbox" id="status" value="C" checked>
                        <span>Set as current term</span>
                    </label>
                </div>
            </div>

            <div class="ums-form-actions">
                <button type="submit">Add Term</button>
            </div>
        </form>
    </section>

<% 
    if(flashMessage != null && flashMessage.trim().length() > 0) 
    { 
%>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert">
        <%=html(flashMessage)%>
    </div>
<% 
    } 
%>

    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools">
            <div>
                <h2>Terms</h2>
                <span>Current term is highlighted</span>
            </div>

            <div class="ums-table-tools">
                <div class="ums-table-search">
                    <label for="termSearch">Search</label>
                    <input type="search" id="termSearch" data-ums-table-search="termTable"
                           placeholder="Search term code, name or duration"
                           autocomplete="off">
                </div>

                <button type="button" class="ums-export-button" id="exportTermsExcel" data-ums-table-export="termTable"
                        title="Export current Term list to Excel">
                    <span class="ums-export-icon">⇩</span>
                    Export to Excel
                </button>
            </div>
        </div>

        <div class="ums-table-wrap">
            <table class="ums-data-table" id="termTable" data-ums-table data-export-file="Terms">
                <thead>
                    <tr>
                        <th class="ums-sortable" data-column="0" data-type="text" data-export-header="Term Code">
                            <button type="button" class="ums-sort-button">
                                Term Code <span class="ums-sort-indicator">↕</span>
                            </button>
                        </th>
                        <th class="ums-sortable" data-column="1" data-type="text" data-export-header="Term Name">
                            <button type="button" class="ums-sort-button">
                                Term Name <span class="ums-sort-indicator">↕</span>
                            </button>
                        </th>
                        <th class="ums-sortable" data-column="2" data-type="date" data-export-header="Duration">
                            <button type="button" class="ums-sort-button">
                                Duration <span class="ums-sort-indicator">↕</span>
                            </button>
                        </th>
                        <th class="ums-actions-col">Options</th>
                    </tr>
                </thead>
                <tbody>
<%
        boolean found = false;
        while(termRs.next()) 
        {
            found = true;
            String termCode = termRs.getString("TERM_CDE");
            String termName = termRs.getString("TERM_NME");
            String startDate = termRs.getString("START_DTE");
            String endDate = termRs.getString("END_DTE");
            String status = termRs.getString("STATUS_TYP");
            boolean current = "C".equalsIgnoreCase(status);
            String editUrl = "AdminEditTerm.jsp?termCode=" + url(termCode)+ "&termName=" + url(termName)+ "&startDate=" + url(startDate)+ "&endDate=" + url(endDate)+"&status=" + url(status);
            String deleteUrl = "AdminProcessDeleteTerm.jsp?termCode=" + url(termCode)+ "&status=" + url(status);
%>
                    <tr class="<%=current ? "ums-current-row" : ""%>">
                        <td data-export-value="<%=html(termCode)%>">
                            <strong><%=html(termCode)%></strong>
                            <% if(current) { %><span class="ums-status-badge">Current</span><% } %>
                        </td>
                        <td><%=html(termName)%></td>
                        <td data-sort-value="<%=html(startDate)%>"><%=html(startDate)%> <span class="ums-date-separator">—</span> <%=html(endDate)%></td>
                        <td class="ums-row-actions">
                            <a class="ums-action-link" href="<%=editUrl%>">Edit</a>
                            <a class="ums-action-link ums-action-danger" href="<%=deleteUrl%>" data-ums-confirm="Are you sure you want to delete <%=html(termName)%> term?">Delete</a>
                            <a class="ums-action-link"
                               href="AdminAcademicCalendar.jsp?termCode=<%=url(termCode)%>">Academic Calendar</a>
                        </td>
                    </tr>
<%
        }
        if(!found) 
        {
%>
                    <tr>
                        <td colspan="4" class="ums-empty-state">No terms are defined.</td>
                    </tr>
<%
        }
%>
                </tbody>
            </table>
        </div>

        <div class="ums-table-footer" id="termTableFooter">
            <div class="ums-page-size">
                <label for="termPageSize">Rows per page</label>
                <select id="termPageSize" data-ums-page-size="termTable">
                    <option value="5">5</option>
                    <option value="10" selected>10</option>
                    <option value="20">20</option>
                    <option value="50">50</option>
                </select>
            </div>
            <div class="ums-pagination-info" id="termPaginationInfo" data-ums-page-info="termTable"></div>
            <div class="ums-pagination" id="termPagination">
                <button type="button" id="termPrevPage" data-ums-page-prev="termTable">Previous</button>
                <div id="termPageNumbers" class="ums-page-numbers" data-ums-page-numbers="termTable"></div>
                <button type="button" id="termNextPage" data-ums-page-next="termTable">Next</button>
            </div>
        </div>
    </section>
</main>

<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/term.js?v=20260830"></script>
</body>
</html>
<%
    } finally 
    {
        if(termRs != null) try { termRs.close(); } catch(SQLException ignored) {}
        if(termStmt != null) try { termStmt.close(); } catch(SQLException ignored) {}
        if(con != null) pool.close(con);
    }
%>

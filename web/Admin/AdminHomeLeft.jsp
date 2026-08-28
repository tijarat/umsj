<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.sql.*,java.util.*" pageEncoding="UTF-8" %>
<jsp:useBean id="pool" scope="application" class="com.towertech.UMS.DB.ConnectionPool"/>
<%!
    public void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminHomeLeft.jsp::" + user + "::" + message);
    }

    public String html(String value)
    {
        if(value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    public String js(String value)
    {
        if(value == null)  return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t").replace("</", "<\\/");
    }
%>
<%
    com.towertech.UMS.util.AdminSession adminSession = (com.towertech.UMS.util.AdminSession) session.getAttribute("adminSession");
    if(adminSession == null || adminSession.con == null)
    {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    Connection con = adminSession.con;
    String oldStudentEnv = pool.getEnviornmentValue("Old Student Accounts");
    boolean isOldStudentUser = adminSession.user != null && adminSession.user.equals(oldStudentEnv);
    LinkedHashSet<String> allowedRightSet = new LinkedHashSet<String>();
    Vector rights = adminSession.rights;
    if(rights != null)
    {
        for(Enumeration e = rights.elements(); e.hasMoreElements();)
        {
            Object right = e.nextElement();
            if(right != null && !right.toString().trim().equals(""))
                allowedRightSet.add(right.toString().trim().toUpperCase());
        }
    }

    if(isOldStudentUser)
        allowedRightSet.add("OLD STUDENT ACCOUNTS");

    List<String> allowedRights = new ArrayList<String>(allowedRightSet);
    StringBuilder placeholders = new StringBuilder();

    for(int i = 0; i < allowedRights.size(); i++)
    {
        if(i > 0)
            placeholders.append(",");
        placeholders.append("?");
    }

    StringBuilder searchJson = new StringBuilder();

    if(!allowedRights.isEmpty())
    {
        String searchQuery =
            "SELECT RIGHT_NME, TARGET, PREFIX_NME || FILE_NME AS FILE_PATH " +
            "FROM UMS.RIGHTS " +
            "WHERE UPPER(RIGHT_NME) IN (" + placeholders.toString() + ") " +
            "AND FILE_NME IS NOT NULL " +
            "ORDER BY RIGHT_NME";

        try(PreparedStatement searchStmt = con.prepareStatement(searchQuery))
        {
            for(int i = 0; i < allowedRights.size(); i++)
                searchStmt.setString(i + 1, allowedRights.get(i));

            try(ResultSet searchRs = searchStmt.executeQuery())
            {
                int count = 0;
                while(searchRs.next())
                {
                    String rightName = searchRs.getString("RIGHT_NME");
                    String filePath = searchRs.getString("FILE_PATH");
                    String target = searchRs.getString("TARGET");
                    if(filePath == null) continue;
                    String searchTarget ="mainFrame".equalsIgnoreCase(target) ? "mainFrame" : "_blank";
                    if(count > 0) searchJson.append(",");
                    searchJson.append("{\"label\":\"").append(js(rightName)).append("\",\"value\":\"").append(js(filePath)).append("\",\"target\":\"").append(js(searchTarget)).append("\"}");
                    count++;
                }
            }
        }catch(Exception e)
        {
            log("Error building autocomplete search: " + e.getMessage(), adminSession.user);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UMS Navigation</title>
    <link href="../css/jquery-ui-1.8.15.custom.css" rel="stylesheet" type="text/css">
    <link href="../extra/css/style.css" rel="stylesheet" type="text/css">
    <script src="../js/jquery-1.6.2.min.js" type="text/javascript"></script>
    <script src="../js/jquery-ui-1.8.15.custom.min.js" type="text/javascript"></script>
    <script>
        var global = { search: [<%=searchJson.toString()%>]};
        function resolveSearchSelection()
        {
            var searchText = document.getElementById("search").value.toLowerCase();
            for(var i = 0; i < global.search.length; i++)
            {
                if(global.search[i].label.toLowerCase() === searchText)
                {
                    document.getElementById("searchLoc").value = global.search[i].value;
                    document.getElementById("searchTarget").value = global.search[i].target;
                    return true;
                }
            }
            return false;
        }

        function submitSearch()
        {
            var locationField = document.getElementById("searchLoc");
            var targetField = document.getElementById("searchTarget");
            if(locationField.value === "")  resolveSearchSelection();
            if(locationField.value === "") return false;
            if(targetField.value === "mainFrame")
                parent.mainFrame.location = locationField.value;
            else
                window.open(locationField.value, "_blank");
            document.getElementById("search").value = "";
            locationField.value = "";
            targetField.value = "";
            return false;
        }

        function handleSearchKey(event)
        {
            if(event.key === "Enter" || event.keyCode === 13)
            {
                event.preventDefault();
                submitSearch();
                return false;
            }
            return true;
        }

        function toggleMenu(menuId, button)
        {
            var menu = document.getElementById(menuId);
            if(!menu)
                return;
            var isOpen = menu.className.indexOf("ums-menu-children-open") >= 0;
            if(isOpen)
            {
                menu.className = "ums-menu-children";
                button.setAttribute("aria-expanded", "false");
            }else
            {
                menu.className = "ums-menu-children ums-menu-children-open";
                button.setAttribute("aria-expanded", "true");
            }
        }

        $(function()
        {
            $("#search").autocomplete({
                source: global.search,
                focus: function(event, ui)
                {
                    $("#search").val(ui.item.label);
                    return false;
                },
                select: function(event, ui)
                {
                    $("#search").val(ui.item.label);
                    $("#searchLoc").val(ui.item.value);
                    $("#searchTarget").val(ui.item.target);
                    return false;
                }
            });
        });
    </script>
</head>
<body class="ums-admin-nav-body">
    <aside class="ums-admin-nav">
        <form name="searchForm" id="searchForm" class="ums-admin-search" onsubmit="return submitSearch();">
            <label for="search">Find a menu</label>
            <div class="ums-admin-search-row">
                <input
                    type="text"
                    name="search"
                    id="search"
                    placeholder="Search menu..."
                    autocomplete="off"
                    onkeydown="return handleSearchKey(event);">
                <button type="submit" title="Open selected menu" aria-label="Open selected menu">&#8594;</button>
            </div>
            <input type="hidden" id="searchLoc" name="searchLoc">
            <input type="hidden" id="searchTarget" name="searchTarget">
        </form>
        <nav class="ums-menu-tree" aria-label="Administration menu">
<%
            if(allowedRights.isEmpty())
            {
%>
                <div class="ums-menu-empty">No menu rights are assigned to this account.</div>
<%
            }else
            {
                String treeQuery =
                    "SELECT DISTINCT P.RIGHT_NME AS PARENT_NME, P.ID AS PARENT_ID, " +
                    "P.SORT AS PARENT_SORT, INITCAP(C.RIGHT_NME) AS CHILD_NME, " +
                    "C.PREFIX_NME, C.FILE_NME, C.TARGET, C.SORT AS CHILD_SORT " +
                    "FROM UMS.RIGHTS C " +
                    "JOIN UMS.RIGHTS P ON P.ID = C.PARENT_ID " +
                    "WHERE UPPER(C.RIGHT_NME) IN (" + placeholders.toString() + ") " +
                    "ORDER BY P.SORT, P.ID, C.SORT";

                String currentParent = null;
                String currentMenuId = null;
                boolean menuOpen = false;

                try(PreparedStatement treeStmt = con.prepareStatement(treeQuery))
                {
                    for(int i = 0; i < allowedRights.size(); i++)
                        treeStmt.setString(i + 1, allowedRights.get(i));

                    try(ResultSet treeRs = treeStmt.executeQuery())
                    {
                        while(treeRs.next())
                        {
                            String parentName = treeRs.getString("PARENT_NME");
                            String parentId = treeRs.getString("PARENT_ID");
                            String childName = treeRs.getString("CHILD_NME");
                            String prefix = treeRs.getString("PREFIX_NME");
                            String file = treeRs.getString("FILE_NME");
                            String target = treeRs.getString("TARGET");

                            if(currentParent == null || !currentParent.equals(parentName))
                            {
                                if(menuOpen)
                                {
%>
                                    </div>
                                </section>
<%
                                }
                                currentParent = parentName;
                                currentMenuId = "menu_" + parentId;
                                menuOpen = true;
%>
                                <section class="ums-menu-group">
                                    <button type="button" class="ums-menu-parent"  aria-expanded="false" onclick="toggleMenu('<%=html(currentMenuId)%>', this);">
                                        <span class="ums-menu-parent-icon">+</span>
                                        <span><%=html(parentName)%></span>
                                    </button>
                                    <div id="<%=html(currentMenuId)%>" class="ums-menu-children">
<%
                            }
                            String location = (prefix == null ? "" : prefix) + (file == null ? "" : file);
                            String linkTarget =  target == null || target.trim().equals("") ? "mainFrame" : target;
                            boolean confirmAction = "Student Filter Process".equalsIgnoreCase(childName) || "Set Student Accounts".equalsIgnoreCase(childName);
%>
                                        <a  href="<%=html(location)%>" target="<%=html(linkTarget)%>" class="ums-menu-child" <%=confirmAction ? "onclick=\"return confirm('Are you sure?');\"" : ""%>>
                                            <span class="ums-menu-child-icon">&#8250;</span>
                                            <span><%=html(childName)%></span>
                                        </a>
<%
                        }
                        if(menuOpen)
                        {
%>
                                    </div>
                                </section>
<%
                        }
                    }
                }catch(Exception e)
                {
                    log("Error rendering menu tree: " + e.getMessage(), adminSession.user);
%>
                    <div class="ums-menu-empty">Unable to load the menu.</div>
<%
                }
            }
%>
        </nav>
    </aside>
</body>
</html>

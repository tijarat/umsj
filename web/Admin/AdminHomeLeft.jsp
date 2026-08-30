<%@page import="com.ums.functions.Functions"%>
<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.sql.*,java.util.*" pageEncoding="UTF-8" errorPage="../error.jsp"%>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
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
    String oldStudentEnv = Functions.getEnviornmentValue("Old Student Accounts",con);
    boolean isOldStudentUser = adminSession.user != null && adminSession.user.equals(oldStudentEnv);
    LinkedHashSet<String> allowedRightSet = new LinkedHashSet<String>();
    List<String> rights = adminSession.getRights();
    if(rights != null)
        for(String right : rights)
            if(right != null && !right.trim().equals("")) allowedRightSet.add(right.trim().toUpperCase());

    if(isOldStudentUser) allowedRightSet.add("OLD STUDENT ACCOUNTS");

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
    <link href="../extra/css/style.css?v=20260829-2" rel="stylesheet" type="text/css">
    <script src="../js/jquery-1.6.2.min.js" type="text/javascript"></script>
    <script src="../js/jquery-ui-1.8.15.custom.min.js" type="text/javascript"></script>
    <script>
        var global = { search: [<%=searchJson.toString()%>]};

        function clearSearchResults()
        {
            var box = document.getElementById("umsSearchResults");
            if(box)
            {
                box.innerHTML = "";
                box.style.display = "none";
            }
        }

        function openSearchItem(index)
        {
            var item = global.search[index];
            if(!item) return false;

            if(item.target === "mainFrame")
            {
                if(parent && parent.frames["mainFrame"])
                    parent.frames["mainFrame"].location.href = item.value;
                else
                    window.open(item.value, "mainFrame");
            }
            else
            {
                window.open(item.value, "_blank");
            }

            document.getElementById("search").value = "";
            clearSearchResults();
            return false;
        }

        function filterSearch()
        {
            var input = document.getElementById("search");
            var box = document.getElementById("umsSearchResults");
            var searchText = input.value.toLowerCase().replace(/^\\s+|\\s+$/g, "");

            box.innerHTML = "";

            if(searchText === "")
            {
                box.style.display = "none";
                return;
            }

            var found = 0;

            for(var i = 0; i < global.search.length; i++)
            {
                var label = global.search[i].label == null ? "" : global.search[i].label;

                if(label.toLowerCase().indexOf(searchText) >= 0)
                {
                    var a = document.createElement("a");
                    a.href = "#";
                    a.className = "ums-search-result";
                    a.setAttribute("data-index", i);
                    a.appendChild(document.createTextNode(label));

                    a.onclick = function()
                    {
                        return openSearchItem(parseInt(this.getAttribute("data-index"), 10));
                    };

                    box.appendChild(a);
                    found++;

                    if(found >= 12)
                        break;
                }
            }

            if(found === 0)
            {
                var empty = document.createElement("div");
                empty.className = "ums-search-no-result";
                empty.appendChild(document.createTextNode("No menu found"));
                box.appendChild(empty);
            }

            box.style.display = "block";
        }

        function submitSearch()
        {
            var searchText = document.getElementById("search").value.toLowerCase().replace(/^\\s+|\\s+$/g, "");

            if(searchText === "")
                return false;

            for(var i = 0; i < global.search.length; i++)
            {
                if(global.search[i].label.toLowerCase() === searchText)
                    return openSearchItem(i);
            }

            for(var j = 0; j < global.search.length; j++)
            {
                if(global.search[j].label.toLowerCase().indexOf(searchText) >= 0)
                    return openSearchItem(j);
            }

            return false;
        }

        function handleSearchKey(event)
        {
            event = event || window.event;
            var keyCode = event.keyCode || event.which;

            if(keyCode === 13)
            {
                if(event.preventDefault)
                    event.preventDefault();

                event.returnValue = false;
                return submitSearch();
            }

            return true;
        }

        function toggleMenu(menuId, button)
        {
            var menu = document.getElementById(menuId);
            if(!menu) return;

            var isOpen = menu.className.indexOf("ums-menu-children-open") >= 0;
            var allMenus = document.getElementsByClassName("ums-menu-children");
            var allButtons = document.getElementsByClassName("ums-menu-parent");
            var i;

            for(i = 0; i < allMenus.length; i++)
                allMenus[i].className = "ums-menu-children";

            for(i = 0; i < allButtons.length; i++)
                allButtons[i].setAttribute("aria-expanded", "false");

            if(!isOpen)
            {
                menu.className = "ums-menu-children ums-menu-children-open";
                button.setAttribute("aria-expanded", "true");
            }
        }

        function clearActiveMenu()
        {
            var links = document.getElementsByClassName("ums-menu-child");
            for(var i = 0; i < links.length; i++)
                links[i].className = links[i].className.replace(/\s*ums-menu-child-active/g, "");
        }

        function normalizeMenuUrl(url)
        {
            if(!url) return "";

            try
            {
                var anchor = document.createElement("a");
                anchor.href = url;
                var path = anchor.pathname || "";
                return path.replace(/\/+/g, "/").toLowerCase();
            }
            catch(e)
            {
                return String(url).split("?")[0].split("#")[0].toLowerCase();
            }
        }

        function highlightMenuByUrl(url)
        {
            var currentUrl = normalizeMenuUrl(url);
            if(currentUrl === "") return;

            var links = document.getElementsByClassName("ums-menu-child");
            var matched = null;

            clearActiveMenu();

            for(var i = 0; i < links.length; i++)
            {
                var linkUrl = normalizeMenuUrl(links[i].href);

                if(linkUrl === currentUrl)
                {
                    matched = links[i];
                    break;
                }
            }

            if(!matched)
            {
                var currentFile = currentUrl.substring(currentUrl.lastIndexOf("/") + 1);

                for(var j = 0; j < links.length; j++)
                {
                    var linkUrl2 = normalizeMenuUrl(links[j].href);
                    var linkFile = linkUrl2.substring(linkUrl2.lastIndexOf("/") + 1);

                    if(linkFile === currentFile)
                    {
                        matched = links[j];
                        break;
                    }
                }
            }

            if(matched)
            {
                matched.className += " ums-menu-child-active";

                var children = matched.parentNode;
                if(children && children.className.indexOf("ums-menu-children") >= 0)
                {
                    var allMenus = document.getElementsByClassName("ums-menu-children");
                    var allButtons = document.getElementsByClassName("ums-menu-parent");

                    for(var k = 0; k < allMenus.length; k++)
                        allMenus[k].className = "ums-menu-children";

                    for(var m = 0; m < allButtons.length; m++)
                        allButtons[m].setAttribute("aria-expanded", "false");

                    children.className = "ums-menu-children ums-menu-children-open";

                    var group = children.parentNode;
                    if(group)
                    {
                        var buttons = group.getElementsByClassName("ums-menu-parent");
                        if(buttons.length > 0)
                            buttons[0].setAttribute("aria-expanded", "true");
                    }
                }

                if(matched.scrollIntoView)
                    matched.scrollIntoView({block: "nearest"});
            }
        }

        function syncActiveMenu()
        {
            try
            {
                if(parent && parent.frames["mainFrame"])
                    highlightMenuByUrl(parent.frames["mainFrame"].location.href);
            }
            catch(e) {}
        }

        function openInMain(url, link)
        {
            if(link)
            {
                clearActiveMenu();
                link.className += " ums-menu-child-active";
            }

            if(parent && parent.frames["mainFrame"])
            {
                parent.frames["mainFrame"].location.href = url;
                return false;
            }
            return true;
        }

        function initActiveMenuSync()
        {
            syncActiveMenu();

            try
            {
                var mainFrameElement = parent.document.getElementById("mainFrame");
                if(mainFrameElement)
                {
                    if(mainFrameElement.addEventListener)
                        mainFrameElement.addEventListener("load", syncActiveMenu, false);
                    else if(mainFrameElement.attachEvent)
                        mainFrameElement.attachEvent("onload", syncActiveMenu);
                }
            }
            catch(e) {}
        }

        document.onclick = function(event)
        {
            event = event || window.event;
            var target = event.target || event.srcElement;
            var searchBox = document.getElementById("umsSearchBox");

            if(searchBox && target && !searchBox.contains(target))
                clearSearchResults();
        };
    </script>

    <style type="text/css">
        .ums-search-box { position: relative; }

        .ums-search-results {
            position: absolute;
            top: 34px;
            left: 0;
            right: 0;
            z-index: 99999;
            display: none;
            max-height: 280px;
            overflow-y: auto;
            background: #ffffff;
            border: 1px solid #b8c9d8;
            border-radius: 4px;
            box-shadow: 0 6px 16px rgba(8,44,79,.16);
        }

        .ums-search-result {
            display: block;
            padding: 7px 9px;
            color: #33475b;
            background: #ffffff;
            border-bottom: 1px solid #edf1f5;
            font-size: 11px;
            line-height: 1.3;
            text-decoration: none;
        }

        .ums-search-result:hover {
            color: #ffffff;
            background: #155a97;
            text-decoration: none;
        }

        .ums-search-no-result {
            padding: 8px 9px;
            color: #7a8794;
            background: #ffffff;
            font-size: 11px;
        }
    </style>
</head>
<body class="ums-admin-nav-body" onload="initActiveMenuSync();">
    <aside class="ums-admin-nav">
        <form name="searchForm" id="searchForm" class="ums-admin-search" onsubmit="return submitSearch();">
            <label for="search">Find a menu</label>
            <div id="umsSearchBox" class="ums-search-box">
                <div class="ums-admin-search-row">
                    <input
                        type="text"
                        name="search"
                        id="search"
                        placeholder="Search menu..."
                        autocomplete="off"
                        onkeyup="filterSearch();"
                        onkeydown="return handleSearchKey(event);">
                    <button type="submit" title="Open first matching menu" aria-label="Open selected menu">&#8594;</button>
                </div>
                <div id="umsSearchResults" class="ums-search-results"></div>
            </div>
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
                                        <a href="<%=html(location)%>"
                                           target="<%=html(linkTarget)%>"
                                           class="ums-menu-child"
                                           <%
                                               if("mainFrame".equalsIgnoreCase(linkTarget))
                                               {
                                                   if(confirmAction)
                                                   {
                                           %>
                                                   onclick="if(!confirm('Are you sure?')) return false; return openInMain(this.href, this);"
                                           <%
                                                   }else
                                                   {
                                           %>
                                                   onclick="return openInMain(this.href, this);"
                                           <%
                                                   }
                                               }else if(confirmAction)
                                               {
                                           %>
                                                   onclick="return confirm('Are you sure?');"
                                           <%
                                               }
                                           %>>
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
            pool.close(con);
%>
        </nav>
    </aside>
</body>
</html>

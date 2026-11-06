<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%@ page import="com.internshipportal.service.UserService" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%!
    // Server-side HTML output encoding to protect against XSS
    private String escapeHtml(Object input) {
        if (input == null) return "";
        String s = input.toString();
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }
%>
<%
    // Prevent browser caching of protected admin student directory page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Enforce server-side session authentication and ADMIN role
    User currentUser = (User) session.getAttribute("currentUser");
    if (currentUser == null || !currentUser.isAdmin()) {
        String msg = "Access denied. Administrator privileges are required.";
        response.sendRedirect(request.getContextPath() + "/login.html?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
        return;
    }

    String fullName = currentUser.getFullName() != null && !currentUser.getFullName().isEmpty()
            ? currentUser.getFullName() : currentUser.getUsername();
    String initial = fullName.trim().substring(0, 1).toUpperCase();

    UserService userService = UserService.getInstance();
    List<Map<String, Object>> students = userService.getStudentDirectory();

    int totalStudents = students.size();
    int activeCount = 0;
    int withProfileCount = 0;
    int totalApplications = 0;

    for (Map<String, Object> s : students) {
        if ("ACTIVE".equalsIgnoreCase((String) s.get("status"))) {
            activeCount++;
        }
        if (s.get("cgpa") != null || s.get("graduationYear") != null) {
            withProfileCount++;
        }
        Object val = s.get("applicationCount");
        if (val instanceof Number) {
            totalApplications += ((Number) val).intValue();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Directory | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .admin-badge {
            display: inline-block;
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fecaca;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }
        .status-pill-success {
            background: #dcfce7;
            color: #166534;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        .status-pill-failed {
            background: #fee2e2;
            color: #991b1b;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        .admin-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .admin-table th {
            text-align: left;
            padding: 12px 14px;
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #e2e8f0;
        }
        .admin-table td {
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e1b4b;
            vertical-align: middle;
        }
        .card-header-flex {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid #f1f5f9;
        }
        .search-box {
            padding: 8px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            width: 260px;
            outline: none;
            transition: border-color 0.2s;
        }
        .search-box:focus {
            border-color: #4f46e5;
        }
    </style>
</head>
<body class="dashboard-body">

    <div class="dashboard-layout">

        <!-- SIDEBAR -->
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div class="brand-icon" style="background: linear-gradient(135deg, #dc2626, #b91c1c);">🛡</div>
                <span>CareerLaunch</span>
            </div>

            <div class="sidebar-label">ADMINISTRATION</div>

            <nav class="sidebar-nav">
                <a href="admin-dashboard.jsp" class="menu-item">
                    <span>▦</span> Admin Dashboard
                </a>
                <a href="admin-internships.jsp" class="menu-item">
                    <span>💼</span> Manage Internships
                </a>
                <a href="admin-applications.jsp" class="menu-item">
                    <span>▤</span> Application Review
                </a>
                <a href="admin-students.jsp" class="menu-item active">
                    <span>👥</span> Student Directory
                </a>
                <a href="admin-audit.jsp" class="menu-item">
                    <span>📋</span> Security Audit Log
                </a>
                <a href="internships.jsp" class="menu-item" target="_blank">
                    <span>⌕</span> Student Portal View
                </a>
            </nav>

            <div class="sidebar-bottom">
                <a href="<%= request.getContextPath() %>/LogoutServlet"
                   class="menu-item logout-link"
                   onclick="return confirm('Are you sure you want to exit the administrator console?');">
                    <span>↪</span> Admin Logout
                </a>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main class="dashboard-main">

            <!-- TOPBAR -->
            <header class="dashboard-topbar">
                <div class="topbar-title">
                    <span class="breadcrumb">Control Panel /</span>
                    <strong>Student Directory</strong>
                </div>

                <div class="topbar-profile">
                    <div class="profile-avatar" style="background: linear-gradient(135deg, #dc2626, #b91c1c);"><%= initial %></div>
                    <div>
                        <strong><%= escapeHtml(fullName) %></strong>
                        <span class="admin-badge">Administrator</span>
                    </div>
                </div>
            </header>

            <!-- SECTION HEADING -->
            <section class="section-heading" style="margin-top: 24px;">
                <div>
                    <h2>Registered Student Directory</h2>
                    <p>Authoritative candidate directory, academic profiles, and application metrics from MySQL <code>users</code> and <code>student_profiles</code>.</p>
                </div>
            </section>

            <!-- STATS CARDS -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-top: 20px;">
                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Total Students</div>
                    <div style="color: #4f46e5; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= totalStudents %></div>
                    <small style="color: #64748b;">Registered with role: <code>STUDENT</code></small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Active Accounts</div>
                    <div style="color: #16a34a; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= activeCount %></div>
                    <small style="color: #10b981; font-weight: 600;">Status: ACTIVE</small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Profiles Maintained</div>
                    <div style="color: #0284c7; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= withProfileCount %></div>
                    <small style="color: #64748b;">With Academic Records</small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Submitted Applications</div>
                    <div style="color: #7c3aed; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= totalApplications %></div>
                    <small style="color: #64748b;">Across All Roles</small>
                </div>
            </div>

            <!-- STUDENT DIRECTORY TABLE -->
            <div style="background: white; border-radius: 16px; padding: 24px; box-shadow: 0 4px 15px rgba(0,0,0,0.03); margin-top: 28px; border: 1px solid #e2e8f0;">
                <div class="card-header-flex">
                    <div>
                        <h3 style="font-size: 17px; color: #1e1b4b; margin: 0;">Student Candidate Directory</h3>
                        <small style="color: #64748b;">Listing candidate profiles, contact details, academic credentials, and portal activity.</small>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <input type="text" id="directorySearch" class="search-box" placeholder="Filter by name, email, course..." onkeyup="filterDirectory()">
                        <span class="admin-badge" style="background: #e0e7ff; color: #4338ca; border-color: #c7d2fe;">
                            <%= totalStudents %> Students
                        </span>
                    </div>
                </div>

                <div style="overflow-x: auto;">
                    <table class="admin-table" id="studentTable">
                        <thead>
                            <tr>
                                <th>Student ID</th>
                                <th>Candidate</th>
                                <th>Contact Information</th>
                                <th>Course &amp; Interest</th>
                                <th>Academic Profile</th>
                                <th>Applications</th>
                                <th>Account Status</th>
                                <th>Registration Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (students.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" style="text-align: center; color: #64748b; padding: 24px;">No students found in the database.</td>
                                </tr>
                            <% } else {
                                for (Map<String, Object> s : students) {
                                    int uId = (Integer) s.get("userId");
                                    String stStatus = (String) s.get("status");
                                    boolean isActive = "ACTIVE".equalsIgnoreCase(stStatus);
                                    String cgpa = (String) s.get("cgpa");
                                    String gradYear = (String) s.get("graduationYear");
                                    int appCount = (Integer) s.get("applicationCount");
                                    String phone = (String) s.get("phone");
                            %>
                                <tr>
                                    <td><strong>CL-<%= uId %></strong></td>
                                    <td>
                                        <div style="font-weight: 700; color: #1e1b4b;"><%= escapeHtml(s.get("fullName")) %></div>
                                        <small style="color: #64748b;">@<%= escapeHtml(s.get("username")) %></small>
                                    </td>
                                    <td>
                                        <div><a href="mailto:<%= escapeHtml(s.get("email")) %>" style="color: #4f46e5; text-decoration: none;"><%= escapeHtml(s.get("email")) %></a></div>
                                        <small style="color: #64748b;"><%= (phone != null && !phone.trim().isEmpty()) ? escapeHtml(phone) : "—" %></small>
                                    </td>
                                    <td>
                                        <div><span style="background: #f1f5f9; padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;"><%= escapeHtml(s.get("course")) %></span></div>
                                        <small style="color: #64748b;"><%= s.get("internshipInterest") != null ? escapeHtml(s.get("internshipInterest")) : "—" %></small>
                                    </td>
                                    <td>
                                        <% if (cgpa != null || gradYear != null) { %>
                                            <div><strong>CGPA:</strong> <%= cgpa != null ? escapeHtml(cgpa) : "—" %></div>
                                            <small style="color: #64748b;">Grad: <%= gradYear != null ? escapeHtml(gradYear) : "—" %></small>
                                        <% } else { %>
                                            <small style="color: #94a3b8; font-style: italic;">Profile not created</small>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if (appCount > 0) { %>
                                            <span style="display: inline-block; background: #ede9fe; color: #6d28d9; padding: 3px 10px; border-radius: 12px; font-weight: 700; font-size: 11px;">
                                                <%= appCount %> Applied
                                            </span>
                                        <% } else { %>
                                            <span style="color: #94a3b8; font-size: 12px;">0 Submitted</span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <span class="<%= isActive ? "status-pill-success" : "status-pill-failed" %>">
                                            <%= escapeHtml(stStatus) %>
                                        </span>
                                    </td>
                                    <td>
                                        <small style="color: #64748b;"><%= escapeHtml(s.get("createdAt")) %></small>
                                    </td>
                                </tr>
                            <%  }
                               } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- FOOTER -->
            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>&copy; 2026 CareerLaunch &middot; Administrator Portal</span>
                <span>Role: <strong>ADMIN</strong> &middot; Server-Enforced RBAC</span>
            </footer>

        </main>
    </div>

    <script>
        function filterDirectory() {
            const input = document.getElementById("directorySearch");
            const filter = input.value.toLowerCase();
            const table = document.getElementById("studentTable");
            const tr = table.getElementsByTagName("tr");

            for (let i = 1; i < tr.length; i++) {
                const text = tr[i].textContent || tr[i].innerText;
                if (text.toLowerCase().indexOf(filter) > -1) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            }
        }
    </script>

</body>
</html>

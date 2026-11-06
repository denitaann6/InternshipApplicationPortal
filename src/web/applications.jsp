<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User, com.internshipportal.model.Application, com.internshipportal.service.ApplicationService, java.util.List, java.util.ArrayList, java.text.SimpleDateFormat" %>
<%!
    // Safe HTML output escaping to prevent XSS
    private String escapeHtml(Object input) {
        if (input == null) return "";
        String s = input.toString();
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }

    // JSON/JavaScript string escaping
    private String escapeJs(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", "")
                    .replace("\n", "\\n");
    }
%>
<%
    // Prevent browser caching of dynamic application records
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User currentUser = (User) session.getAttribute("currentUser");
    if (currentUser == null) {
        String msg = "Please log in to track your applications.";
        response.sendRedirect(request.getContextPath() + "/login.html?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
        return;
    }

    String fullName = currentUser.getFullName() != null && !currentUser.getFullName().isEmpty()
            ? currentUser.getFullName() : currentUser.getUsername();
    String initial = fullName.trim().substring(0, 1).toUpperCase();

    // Query applications strictly for the authenticated student ID from server session
    int studentId = currentUser.getUserId();
    List<Application> applications = null;
    boolean dbError = false;
    try {
        applications = ApplicationService.getInstance().getApplicationsForStudent(studentId);
    } catch (Exception e) {
        System.err.println("[applications.jsp] Error fetching applications: " + e.getMessage());
        dbError = true;
    }
    if (applications == null) {
        applications = new ArrayList<>();
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Applications | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .notice-box {
            background: #eff6ff;
            border-left: 4px solid #3b82f6;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 20px 0;
            color: #1e3a8a;
            font-size: 13px;
            line-height: 1.5;
        }
        .app-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(0,0,0,0.03);
        }
        .app-table th {
            background: #f8fafc;
            color: #475569;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 14px 18px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        .app-table td {
            padding: 16px 18px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e1b4b;
            font-size: 14px;
            vertical-align: middle;
        }
        .app-table tr:hover {
            background-color: #fafbfd;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: capitalize;
        }
        .status-pending {
            background: #f3e8ff;
            color: #6b21a8;
        }
        .status-review {
            background: #dbeafe;
            color: #1e40af;
        }
        .status-shortlisted {
            background: #dcfce7;
            color: #166534;
        }
        .status-accepted {
            background: #bbf7d0;
            color: #14532d;
        }
        .status-rejected {
            background: #fee2e2;
            color: #991b1b;
        }
        .status-default {
            background: #f1f5f9;
            color: #475569;
        }
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.7);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-box {
            background: white;
            border-radius: 16px;
            max-width: 580px;
            width: 100%;
            max-height: 85vh;
            overflow-y: auto;
            padding: 28px;
            position: relative;
            box-shadow: 0 20px 40px rgba(0,0,0,0.2);
        }
        .modal-close {
            position: absolute;
            top: 18px;
            right: 18px;
            font-size: 22px;
            cursor: pointer;
            border: none;
            background: none;
            color: #64748b;
        }
    </style>
</head>
<body class="dashboard-body">

    <div class="dashboard-layout">

        <!-- SIDEBAR -->
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div class="brand-icon">✦</div>
                <span>CareerLaunch</span>
            </div>

            <div class="sidebar-label">WORKSPACE</div>

            <nav class="sidebar-nav">
                <a href="dashboard.jsp" class="menu-item">
                    <span>▦</span> Dashboard
                </a>
                <a href="internships.jsp" class="menu-item">
                    <span>⌕</span> Find Internships
                </a>
                <a href="applications.jsp" class="menu-item active">
                    <span>▤</span> My Applications
                </a>
                <a href="profile.jsp" class="menu-item">
                    <span>♙</span> My Profile
                </a>
                <a href="about.jsp" class="menu-item">
                    <span>ⓘ</span> About Portal
                </a>
                <a href="contact.jsp" class="menu-item">
                    <span>✉</span> Contact &amp; Support
                </a>
                <a href="help.jsp" class="menu-item">
                    <span>?</span> Help &amp; FAQ
                </a>
            </nav>

            <div class="sidebar-bottom">
                <a href="<%= request.getContextPath() %>/LogoutServlet"
                   class="menu-item logout-link"
                   onclick="return confirm('Are you sure you want to log out?');">
                    <span>↪</span> Logout
                </a>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main class="dashboard-main">

            <header class="dashboard-topbar">
                <div class="topbar-title">
                    <span class="breadcrumb">Workspace /</span>
                    <strong>My Applications</strong>
                </div>

                <div class="topbar-profile">
                    <div class="profile-avatar"><%= initial %></div>
                    <div>
                        <strong><%= escapeHtml(fullName) %></strong>
                        <small><%= currentUser.getCourse() != null ? escapeHtml(currentUser.getCourse()) : "Student" %></small>
                    </div>
                </div>
            </header>

            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <h2>Application Status Tracker</h2>
                    <p>Live status and review progress for internship positions applied through your student account.</p>
                </div>
            </section>

            <!-- Database Architecture Notice -->
            <div class="notice-box">
                <strong>Live Database Architecture (Viva Explanation Point):</strong><br>
                Application records are retrieved dynamically from MySQL (<code>careerlaunch_db.applications</code> joined with <code>careerlaunch_db.internships</code>) filtered strictly by the authenticated student's session user ID (<code>user_id = <%= studentId %></code>). Submission timestamps and status transitions are audited in <code>careerlaunch_db.application_status_history</code>.
            </div>

            <% if (dbError) { %>
                <!-- Error State -->
                <div style="background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; padding: 24px; border-radius: 12px; margin-top: 20px; text-align: center;">
                    <h4 style="margin: 0 0 8px 0; font-size: 16px;">Unable to Load Applications</h4>
                    <p style="margin: 0; font-size: 14px;">A temporary issue occurred while communicating with the database. Please refresh the page or try again in a few moments.</p>
                </div>
            <% } else if (applications.isEmpty()) { %>
                <!-- Empty State -->
                <div style="background: white; border-radius: 14px; padding: 48px 24px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.03); margin-top: 20px;">
                    <div style="font-size: 48px; margin-bottom: 16px;">📋</div>
                    <h3 style="color: #1e1b4b; font-size: 20px; margin: 0 0 8px 0;">No Applications Submitted Yet</h3>
                    <p style="color: #64748b; font-size: 14px; max-width: 520px; margin: 0 auto 24px auto;">
                        You have not applied for any internship listings yet. Browse our verified opportunities and apply directly to track your progress here.
                    </p>
                    <a href="internships.jsp" class="primary-button" style="text-decoration: none; display: inline-flex; align-items: center; gap: 8px;">
                        Explore Active Internships <span>→</span>
                    </a>
                </div>
            <% } else { %>
                <!-- Live Applications Table -->
                <div style="margin-top: 20px; overflow-x: auto;">
                    <table class="app-table">
                        <thead>
                            <tr>
                                <th>Application ID</th>
                                <th>Role &amp; Company</th>
                                <th>Applied On</th>
                                <th>Work Mode</th>
                                <th>Stipend</th>
                                <th>Status</th>
                                <th>Statement / Note</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                for (Application app : applications) {
                                    String rawStatus = app.getStatus() != null ? app.getStatus().toUpperCase() : "PENDING";
                                    String statusClass = "status-default";
                                    String statusLabel = app.getStatus();

                                    if ("PENDING".equals(rawStatus) || "SUBMITTED".equals(rawStatus)) {
                                        statusClass = "status-pending";
                                        statusLabel = "Pending";
                                    } else if ("UNDER_REVIEW".equals(rawStatus) || "REVIEW".equals(rawStatus)) {
                                        statusClass = "status-review";
                                        statusLabel = "Under Review";
                                    } else if ("SHORTLISTED".equals(rawStatus)) {
                                        statusClass = "status-shortlisted";
                                        statusLabel = "Shortlisted";
                                    } else if ("ACCEPTED".equals(rawStatus) || "HIRED".equals(rawStatus)) {
                                        statusClass = "status-accepted";
                                        statusLabel = "Accepted";
                                    } else if ("REJECTED".equals(rawStatus)) {
                                        statusClass = "status-rejected";
                                        statusLabel = "Not Selected";
                                    }

                                    String formattedDate = app.getAppliedAt() != null
                                            ? dateFormat.format(app.getAppliedAt()) : "—";
                                    boolean hasStatement = app.getCoverLetter() != null && !app.getCoverLetter().trim().isEmpty();
                            %>
                            <tr>
                                <td><strong>#APP-<%= app.getApplicationId() %></strong></td>
                                <td>
                                    <strong><%= escapeHtml(app.getInternshipTitle()) %></strong><br>
                                    <small style="color: #64748b;"><%= escapeHtml(app.getCompany()) %></small>
                                </td>
                                <td><%= formattedDate %></td>
                                <td>
                                    <span><%= escapeHtml(app.getWorkMode() != null ? app.getWorkMode() : "Remote") %></span><br>
                                    <small style="color: #64748b;">⌖ <%= escapeHtml(app.getLocation() != null ? app.getLocation() : "India") %></small>
                                </td>
                                <td>
                                    <span style="color: #4338ca; font-weight: 600;"><%= escapeHtml(app.getStipend() != null ? app.getStipend() : "—") %></span>
                                </td>
                                <td>
                                    <span class="status-badge <%= statusClass %>"><%= escapeHtml(statusLabel) %></span>
                                </td>
                                <td>
                                    <% if (hasStatement) { %>
                                        <button type="button"
                                                class="secondary-button"
                                                style="padding: 4px 10px; font-size: 12px;"
                                                onclick="viewStatement('<%= escapeJs(app.getInternshipTitle()) %>', '<%= escapeJs(app.getCompany()) %>', '<%= escapeJs(app.getCoverLetter()) %>')">
                                            View Note
                                        </button>
                                    <% } else { %>
                                        <span style="color: #94a3b8; font-size: 12px;">Standard 1-Click</span>
                                    <% } %>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <div style="margin-top: 24px; display: flex; justify-content: space-between; align-items: center;">
                    <a href="internships.jsp" class="primary-button" style="text-decoration: none;">
                        Explore More Internships <span>→</span>
                    </a>
                    <span style="color: #64748b; font-size: 13px;">
                        Showing <strong><%= applications.size() %></strong> application<%= applications.size() == 1 ? "" : "s" %>
                    </span>
                </div>
            <% } %>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project (26MCA1L211)</span>
                <span>Protected by Server-Side Session Tracking</span>
            </footer>

        </main>
    </div>

    <!-- STATEMENT / NOTE MODAL -->
    <div class="modal-overlay" id="statementModal">
        <div class="modal-box">
            <button class="modal-close" onclick="closeStatementModal()">×</button>
            <h3 id="modalRoleTitle" style="font-size: 18px; color: #1e1b4b; margin: 0 0 4px 0;">Application Statement</h3>
            <p id="modalCompanySubtitle" style="color: #4f46e5; font-size: 14px; font-weight: 600; margin: 0 0 16px 0;">Company</p>
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 16px; margin-bottom: 20px;">
                <p id="modalStatementText" style="margin: 0; color: #334155; font-size: 14px; line-height: 1.6; white-space: pre-wrap; word-break: break-word;"></p>
            </div>
            <div style="text-align: right;">
                <button type="button" class="secondary-button" onclick="closeStatementModal()">Close</button>
            </div>
        </div>
    </div>

    <script>
        function viewStatement(title, company, statement) {
            document.getElementById("modalRoleTitle").textContent = title;
            document.getElementById("modalCompanySubtitle").textContent = company;
            document.getElementById("modalStatementText").textContent = statement;
            document.getElementById("statementModal").style.display = "flex";
        }

        function closeStatementModal() {
            document.getElementById("statementModal").style.display = "none";
        }
    </script>

</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%@ page import="com.internshipportal.service.AuditService" %>
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
    // Prevent browser caching of protected admin security audit page
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

    AuditService auditService = AuditService.getInstance();

    int totalLogins = auditService.getTotalLoginCount();
    int failedLogins = auditService.getFailedLoginCount();
    int successfulLogins = auditService.getSuccessfulLoginCount();

    // Fetch up to 50 real login activity events from login_activity
    List<Map<String, Object>> loginActivities = auditService.getRecentActivities(50);

    // Fetch up to 50 real application status transition audit records from application_status_history
    List<Map<String, Object>> statusHistory = auditService.getApplicationStatusAuditTrail(50);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Audit Log | CareerLaunch</title>
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
        .status-pill-info {
            background: #e0e7ff;
            color: #4338ca;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
        }
        .status-pill-warning {
            background: #fef3c7;
            color: #92400e;
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
        }
        .card-header-flex {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid #f1f5f9;
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
                <a href="admin-students.jsp" class="menu-item">
                    <span>👥</span> Student Directory
                </a>
                <a href="admin-audit.jsp" class="menu-item active">
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
                    <strong>Security Audit Log</strong>
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
                    <h2>Platform Security &amp; Activity Audit Log</h2>
                    <p>Comprehensive audit log tracking authentication activity and application lifecycle transitions from MySQL database.</p>
                </div>
            </section>

            <!-- STATS CARDS -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-top: 20px;">
                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Total Login Events</div>
                    <div style="color: #4f46e5; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= totalLogins %></div>
                    <small style="color: #64748b;">Recorded in <code>login_activity</code></small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Successful Logins</div>
                    <div style="color: #16a34a; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= successfulLogins %></div>
                    <small style="color: #10b981; font-weight: 600;">Authenticated Sessions</small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Failed Attempts</div>
                    <div style="color: #dc2626; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= failedLogins %></div>
                    <small style="color: <%= failedLogins > 0 ? "#dc2626" : "#64748b" %>; font-weight: 600;">
                        <%= failedLogins %> Authentication Failure<%= failedLogins == 1 ? "" : "s" %>
                    </small>
                </div>

                <div style="background: white; border-radius: 14px; padding: 22px; box-shadow: 0 2px 10px rgba(0,0,0,0.03); border: 1px solid #e2e8f0;">
                    <div style="color: #64748b; font-size: 12px; font-weight: 700; text-transform: uppercase;">Status Transitions</div>
                    <div style="color: #7c3aed; font-size: 32px; font-weight: 700; margin-top: 6px;"><%= statusHistory.size() %></div>
                    <small style="color: #64748b;">In <code>application_status_history</code></small>
                </div>
            </div>

            <!-- AUTHENTICATION AUDIT TRAIL -->
            <div style="background: white; border-radius: 16px; padding: 24px; box-shadow: 0 4px 15px rgba(0,0,0,0.03); margin-top: 28px; border: 1px solid #e2e8f0;">
                <div class="card-header-flex">
                    <div>
                        <h3 style="font-size: 17px; color: #1e1b4b; margin: 0;">Authentication Audit Trail (<code>login_activity</code>)</h3>
                        <small style="color: #64748b;">Real-time logging of authentication events. Passwords are never logged or stored in audit records.</small>
                    </div>
                    <span style="font-size: 12px; color: #64748b; font-weight: 600;">Showing Latest <%= loginActivities.size() %></span>
                </div>

                <div style="overflow-x: auto;">
                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>Event ID</th>
                                <th>Attempted Username</th>
                                <th>Status</th>
                                <th>IP Address</th>
                                <th>Failure Reason</th>
                                <th>Timestamp</th>
                                <th>User Agent</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (loginActivities.isEmpty()) { %>
                                <tr>
                                    <td colspan="7" style="text-align: center; color: #64748b; padding: 24px;">No login activity recorded yet.</td>
                                </tr>
                            <% } else {
                                for (Map<String, Object> act : loginActivities) {
                                    String st = (String) act.get("loginStatus");
                                    boolean isSuccess = "SUCCESS".equalsIgnoreCase(st);
                            %>
                                <tr>
                                    <td>#<%= act.get("activityId") %></td>
                                    <td><strong><%= escapeHtml(act.get("attemptedUsername")) %></strong></td>
                                    <td>
                                        <span class="<%= isSuccess ? "status-pill-success" : "status-pill-failed" %>">
                                            <%= escapeHtml(st) %>
                                        </span>
                                    </td>
                                    <td><code><%= escapeHtml(act.get("ipAddress")) %></code></td>
                                    <td><small style="color: <%= isSuccess ? "#64748b" : "#dc2626" %>;"><%= act.get("failureReason") != null ? escapeHtml(act.get("failureReason")) : "—" %></small></td>
                                    <td><small><%= escapeHtml(act.get("loginTime")) %></small></td>
                                    <td><small style="color: #64748b; max-width: 200px; display: inline-block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<%= escapeHtml(act.get("userAgent")) %>"><%= escapeHtml(act.get("userAgent")) %></small></td>
                                </tr>
                            <%  }
                               } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- APPLICATION STATUS TRANSITION AUDIT TRAIL -->
            <div style="background: white; border-radius: 16px; padding: 24px; box-shadow: 0 4px 15px rgba(0,0,0,0.03); margin-top: 28px; border: 1px solid #e2e8f0;">
                <div class="card-header-flex">
                    <div>
                        <h3 style="font-size: 17px; color: #1e1b4b; margin: 0;">Application Status Transition History (<code>application_status_history</code>)</h3>
                        <small style="color: #64748b;">Audited chronological record of applicant review decisions and status transitions.</small>
                    </div>
                    <span style="font-size: 12px; color: #64748b; font-weight: 600;">Showing Latest <%= statusHistory.size() %></span>
                </div>

                <div style="overflow-x: auto;">
                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>History ID</th>
                                <th>App ID</th>
                                <th>Candidate</th>
                                <th>Internship &amp; Company</th>
                                <th>Status Change</th>
                                <th>Updated By</th>
                                <th>Notes</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (statusHistory.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" style="text-align: center; color: #64748b; padding: 24px;">No application status transitions recorded yet.</td>
                                </tr>
                            <% } else {
                                for (Map<String, Object> hist : statusHistory) {
                                    String prevSt = (String) hist.get("previousStatus");
                                    String newSt = (String) hist.get("newStatus");
                                    String changerRole = (String) hist.get("changerRole");
                            %>
                                <tr>
                                    <td>#<%= hist.get("historyId") %></td>
                                    <td>APP-<%= hist.get("applicationId") %></td>
                                    <td><strong><%= escapeHtml(hist.get("applicantName") != null ? hist.get("applicantName") : "—") %></strong></td>
                                    <td>
                                        <div><strong><%= escapeHtml(hist.get("internshipTitle") != null ? hist.get("internshipTitle") : "—") %></strong></div>
                                        <small style="color: #64748b;"><%= escapeHtml(hist.get("company") != null ? hist.get("company") : "") %></small>
                                    </td>
                                    <td>
                                        <% if (prevSt != null && !prevSt.isEmpty()) { %>
                                            <span class="status-pill-info"><%= escapeHtml(prevSt) %></span>
                                            <span style="color: #64748b; font-size: 11px;">&rarr;</span>
                                        <% } %>
                                        <span class="status-pill-<%= "ACCEPTED".equalsIgnoreCase(newSt) ? "success" : ("REJECTED".equalsIgnoreCase(newSt) ? "failed" : "warning") %>">
                                            <%= escapeHtml(newSt) %>
                                        </span>
                                    </td>
                                    <td>
                                        <div><%= escapeHtml(hist.get("changerName") != null ? hist.get("changerName") : "System") %></div>
                                        <small style="color: #64748b;"><%= escapeHtml(changerRole != null ? changerRole : "") %></small>
                                    </td>
                                    <td><small style="color: #475569;"><%= escapeHtml(hist.get("notes") != null ? hist.get("notes") : "—") %></small></td>
                                    <td><small><%= escapeHtml(hist.get("changedAt")) %></small></td>
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

</body>
</html>

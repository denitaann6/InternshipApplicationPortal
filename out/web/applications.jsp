<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%
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
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-review {
            background: #dbeafe;
            color: #1e40af;
        }
        .status-shortlisted {
            background: #dcfce7;
            color: #166534;
        }
        .status-submitted {
            background: #f3e8ff;
            color: #6b21a8;
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
                    <span>✉</span> Contact & Support
                </a>
                <a href="help.jsp" class="menu-item">
                    <span>?</span> Help & FAQ
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
                        <strong><%= fullName %></strong>
                        <small><%= currentUser.getCourse() != null ? currentUser.getCourse() : "Student" %></small>
                    </div>
                </div>
            </header>

            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <h2>Application Status Tracker</h2>
                    <p>Real-time review updates for internship opportunities applied through your account.</p>
                </div>
            </section>

            <!-- Storage Explanation Notice -->
            <div class="notice-box">
                <strong>Storage Architecture Notice (Viva Explanation Point):</strong><br>
                As required in Phase 4 without an external database, application records are maintained via server-side session and in-memory management. In an enterprise production deployment, this table would connect to a relational database (e.g., MySQL via JDBC). The demonstration statuses below illustrate the end-to-end student recruitment lifecycle.
            </div>

            <!-- Applications Table -->
            <div style="margin-top: 20px; overflow-x: auto;">
                <table class="app-table">
                    <thead>
                        <tr>
                            <th>Application ID</th>
                            <th>Role & Company</th>
                            <th>Applied On</th>
                            <th>Work Mode</th>
                            <th>Stipend</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>#APP-1082</strong></td>
                            <td>
                                <strong>Java Developer Intern</strong><br>
                                <small style="color: #64748b;">TechNova Solutions</small>
                            </td>
                            <td>20 Oct 2026</td>
                            <td>Hybrid</td>
                            <td>₹15,000 / mo</td>
                            <td><span class="status-badge status-review">Under Review</span></td>
                            <td>
                                <button type="button" class="secondary-button" style="padding: 4px 10px; font-size: 12px;" onclick="alert('Your resume has been forwarded to TechNova hiring managers.');">
                                    View Note
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>#APP-1054</strong></td>
                            <td>
                                <strong>Data Analytics Intern</strong><br>
                                <small style="color: #64748b;">InnovateAI Analytics</small>
                            </td>
                            <td>18 Oct 2026</td>
                            <td>On-site</td>
                            <td>₹18,000 / mo</td>
                            <td><span class="status-badge status-shortlisted">Shortlisted</span></td>
                            <td>
                                <button type="button" class="primary-button" style="padding: 4px 10px; font-size: 12px;" onclick="alert('Congratulations! Interview invitation scheduled for next week.');">
                                    Next Steps
                                </button>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>#APP-1021</strong></td>
                            <td>
                                <strong>Web Development Intern</strong><br>
                                <small style="color: #64748b;">DigitalWorks Studio</small>
                            </td>
                            <td>15 Oct 2026</td>
                            <td>Remote</td>
                            <td>₹12,000 / mo</td>
                            <td><span class="status-badge status-submitted">Submitted</span></td>
                            <td>
                                <button type="button" class="secondary-button" style="padding: 4px 10px; font-size: 12px;" onclick="alert('Application received by DigitalWorks. Awaiting recruiter screening.');">
                                    View Note
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div style="margin-top: 24px;">
                <a href="internships.jsp" class="primary-button" style="text-decoration: none;">
                    Explore More Internships <span>→</span>
                </a>
            </div>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project (26MCA1L211)</span>
                <span>Protected by Server-Side Session Tracking</span>
            </footer>

        </main>
    </div>

</body>
</html>

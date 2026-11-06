<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User currentUser = (User) session.getAttribute("currentUser");
    if (currentUser == null) {
        String msg = "Please log in to view your profile.";
        response.sendRedirect(request.getContextPath() + "/login.html?error=" + java.net.URLEncoder.encode(msg, "UTF-8"));
        return;
    }

    String fullName = currentUser.getFullName() != null && !currentUser.getFullName().isEmpty()
            ? currentUser.getFullName() : currentUser.getUsername();
    String initial = fullName.trim().substring(0, 1).toUpperCase();
    String course = currentUser.getCourse() != null && !currentUser.getCourse().isEmpty() ? currentUser.getCourse() : "MCA";
    String email = currentUser.getEmail() != null ? currentUser.getEmail() : "Not provided";
    String phone = currentUser.getPhone() != null && !currentUser.getPhone().isEmpty() ? currentUser.getPhone() : "Not provided";
    String interest = currentUser.getInternshipInterest() != null && !currentUser.getInternshipInterest().isEmpty()
            ? currentUser.getInternshipInterest() : "Software Development";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
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
                <a href="applications.jsp" class="menu-item">
                    <span>▤</span> My Applications
                </a>
                <a href="profile.jsp" class="menu-item active">
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
                    <strong>My Profile</strong>
                </div>

                <div class="topbar-profile">
                    <div class="profile-avatar"><%= initial %></div>
                    <div>
                        <strong><%= fullName %></strong>
                        <small><%= course %> Student</small>
                    </div>
                </div>
            </header>

            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <h2>Student Profile & Academic Credentials</h2>
                    <p>Details retrieved securely from your active server-side session.</p>
                </div>
            </section>

            <div style="max-width: 900px; margin-top: 20px; display: flex; flex-direction: column; gap: 24px;">

                <!-- Profile Header Card -->
                <div style="background: white; border-radius: 16px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.04); display: flex; align-items: center; gap: 24px;">
                    <div style="width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, #4f46e5, #7c3aed); color: white; display: flex; align-items: center; justify-content: center; font-size: 36px; font-weight: 700;">
                        <%= initial %>
                    </div>
                    <div>
                        <h1 style="font-size: 24px; color: #1e1b4b; margin-bottom: 6px;"><%= fullName %></h1>
                        <p style="color: #64748b; font-size: 14px; margin-bottom: 8px;">
                            <%= course %> Candidate · Student ID: CL-<%= currentUser.getUserId() > 0 ? currentUser.getUserId() : 101 %>
                        </p>
                        <span style="background: #e0e7ff; color: #4338ca; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                            Active Authenticated Student
                        </span>
                    </div>
                </div>

                <!-- Profile Information Grid -->
                <div style="background: white; border-radius: 16px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.04);">
                    <h3 style="font-size: 18px; color: #1e1b4b; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 1px solid #f1f5f9;">
                        Registration & Academic Details
                    </h3>

                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 20px;">
                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Full Name</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= fullName %></div>
                        </div>

                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Username</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= currentUser.getUsername() %></div>
                        </div>

                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Email Address</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= email %></div>
                        </div>

                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Phone Number</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= phone %></div>
                        </div>

                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Enrolled Course</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= course %></div>
                        </div>

                        <div style="background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #e2e8f0;">
                            <small style="color: #64748b; text-transform: uppercase; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;">Internship Focus</small>
                            <div style="color: #1e1b4b; font-size: 16px; font-weight: 600; margin-top: 4px;"><%= interest %></div>
                        </div>
                    </div>
                </div>

                <!-- Account Security Info (Strictly Hides Passwords) -->
                <div style="background: white; border-radius: 16px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.04);">
                    <h3 style="font-size: 18px; color: #1e1b4b; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 1px solid #f1f5f9;">
                        Account Security & Privacy
                    </h3>

                    <div style="background: #f8fafc; padding: 18px; border-radius: 10px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong style="color: #1e1b4b; font-size: 14px; display: block;">Account Password</strong>
                            <span style="color: #64748b; font-size: 13px;">•••••••••••• (Encrypted and hidden for security)</span>
                        </div>
                        <span style="color: #10b981; font-size: 13px; font-weight: 600;">✓ Protected</span>
                    </div>

                    <div style="margin-top: 24px; display: flex; gap: 12px;">
                        <a href="dashboard.jsp" class="primary-button" style="text-decoration: none;">
                            ← Back to Dashboard
                        </a>
                        <a href="internships.jsp" class="secondary-button" style="text-decoration: none;">
                            Explore Opportunities →
                        </a>
                    </div>
                </div>

            </div>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project</span>
                <span>Protected by Server-Side Session Tracking</span>
            </footer>

        </main>
    </div>

</body>
</html>

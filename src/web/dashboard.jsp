
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="com.internshipportal.model.User" %>
<%
    // Protect the dashboard from unauthenticated access.
    User currentUser = (User) session.getAttribute("currentUser");

    if (currentUser == null) {
        response.sendRedirect("login.html");
        return;
    }

    String fullName = currentUser.getFullName();
    String username = currentUser.getUsername();
    String email = currentUser.getEmail();
    String course = currentUser.getCourse();

    if (fullName == null || fullName.trim().isEmpty()) {
        fullName = username != null ? username : "Student";
    }

    if (course == null || course.trim().isEmpty()) {
        course = "Student";
    }

    String firstName = fullName.trim().split("\\s+")[0];
    String initial = firstName.substring(0, 1).toUpperCase();

    String contextPath = request.getContextPath();

    // Prevent user-provided values from being interpreted as HTML.
    String safeName = fullName
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&#39;");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Dashboard | CareerLaunch</title>

    <link rel="stylesheet"
          href="<%= contextPath %>/css/style.css?v=dashboard-fix-2">

    <style>
        /* ===== Dashboard layout ===== */

        * {
            box-sizing: border-box;
        }

        body.dashboard-page {
            margin: 0;
            min-height: 100vh;
            background: #f7f8fc;
            color: #17213f;
            font-family: Arial, Helvetica, sans-serif;
        }

        .dashboard-layout {
            display: flex;
            align-items: stretch;
            min-height: 100vh;
            width: 100%;
        }

        /* ===== Sidebar ===== */

        .sidebar {
            position: relative;
            flex: 0 0 250px;
            width: 250px;
            min-width: 250px;
            max-width: 250px;
            min-height: 100vh;
            padding: 24px 16px;
            background: #ffffff;
            border-right: 1px solid #ececf4;
            display: flex;
            flex-direction: column;
            align-self: stretch;
        }

        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 5px;
            margin-bottom: 38px;
            text-decoration: none;
            color: #18213f;
        }

        .brand-icon {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 42px;
            height: 42px;
            flex-shrink: 0;
            border-radius: 12px;
            color: #ffffff;
            background: linear-gradient(135deg, #7250f5, #a078ff);
            font-size: 24px;
        }

        .sidebar-brand strong {
            font-size: 21px;
            letter-spacing: -0.5px;
        }

        .sidebar-label {
            margin: 0 12px 12px;
            color: #9399b0;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1.2px;
        }

        .sidebar-nav {
            display: flex;
            flex-direction: column;
            gap: 7px;
        }

        .menu-item {
            display: flex;
            align-items: center;
            gap: 13px;
            min-height: 48px;
            padding: 12px 15px;
            border-radius: 12px;
            color: #515a78;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: background 0.2s, color 0.2s;
        }

        .menu-item:hover,
        .menu-item.active {
            color: #6542f5;
            background: #f0ecff;
        }

        .menu-icon {
            width: 20px;
            flex-shrink: 0;
            text-align: center;
            font-size: 17px;
        }

        /* The sidebar footer must remain in normal document flow. */

        .sidebar-bottom {
            position: static;
            width: 100%;
            margin-top: auto;
            padding-top: 30px;
        }

        .sidebar-help {
            position: static !important;
            inset: auto !important;
            display: block;
            width: 100%;
            max-width: 100%;
            height: auto;
            margin: 0 0 14px;
            padding: 16px;
            overflow-wrap: anywhere;
            border-radius: 14px;
            background: #f7f4ff;
            box-sizing: border-box;
        }

        .sidebar-help .help-icon {
            margin-bottom: 12px;
            color: #7955ff;
            font-size: 23px;
        }

        .sidebar-help h3 {
            margin: 0 0 8px;
            font-size: 14px;
        }

        .sidebar-help p {
            margin: 0 0 12px;
            color: #7d849e;
            font-size: 12px;
            line-height: 1.6;
        }

        .sidebar-help a {
            color: #6542f5;
            font-size: 12px;
            font-weight: 700;
            text-decoration: none;
        }

        .logout-link {
            margin-top: 4px;
        }

        /* ===== Main content ===== */

        .dashboard-main {
            flex: 1 1 0;
            min-width: 0;
            width: 0;
            padding: 0 36px 40px;
            overflow-wrap: anywhere;
        }

        .topbar {
            min-height: 54px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            padding: 12px 0;
            margin-bottom: 30px;
            border-bottom: 1px solid #ececf4;
        }

        .breadcrumb {
            color: #9097b0;
            font-size: 13px;
        }

        .breadcrumb strong {
            color: #17213f;
        }

        .topbar-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .search-box {
            width: 230px;
            max-width: 100%;
            padding: 12px 14px;
            border: 1px solid #e8e9f2;
            border-radius: 10px;
            outline: none;
            background: #ffffff;
            font-size: 12px;
        }

        .search-box:focus {
            border-color: #8667ff;
        }

        .user-summary {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .avatar {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 42px;
            height: 42px;
            flex-shrink: 0;
            border-radius: 50%;
            color: #6c49f6;
            background: #eee9ff;
            font-weight: 700;
        }

        .user-summary strong {
            display: block;
            max-width: 140px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            font-size: 13px;
        }

        .user-summary small {
            display: block;
            margin-top: 4px;
            color: #8c93aa;
            font-size: 11px;
        }

        /* ===== Welcome banner ===== */

        .welcome-banner {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 28px;
            min-height: 280px;
            padding: 40px;
            margin-bottom: 36px;
            overflow: hidden;
            border-radius: 22px;
            color: #ffffff;
            background: linear-gradient(115deg, #6743ed, #9069f5);
        }

        .welcome-content {
            position: relative;
            z-index: 1;
            max-width: 650px;
        }

        .welcome-eyebrow {
            margin: 0 0 20px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1px;
        }

        .welcome-banner h1 {
            margin: 0 0 16px;
            font-size: clamp(26px, 3vw, 36px);
            letter-spacing: -1px;
        }

        .welcome-banner p {
            max-width: 600px;
            margin: 0 0 24px;
            font-size: 14px;
            line-height: 1.8;
            color: #f1edff;
        }

        .primary-button {
            display: inline-flex;
            align-items: center;
            gap: 18px;
            padding: 14px 19px;
            border-radius: 10px;
            background: #ffffff;
            color: #6947f5;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            transition: transform 0.2s;
        }

        .primary-button:hover {
            transform: translateY(-2px);
        }

        .welcome-decoration {
            position: relative;
            z-index: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 150px;
            min-width: 150px;
            min-height: 150px;
            border: 1px solid rgba(255,255,255,0.35);
            border-radius: 22px;
            background: rgba(255,255,255,0.12);
            text-align: center;
        }

        .welcome-decoration strong {
            display: block;
            margin-top: 12px;
            font-size: 15px;
        }

        .welcome-decoration small {
            display: block;
            margin-top: 10px;
            overflow-wrap: anywhere;
            font-size: 12px;
        }

        /* ===== Section headings ===== */

        .section-heading {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 15px;
            margin-bottom: 22px;
        }

        .section-heading h2 {
            margin: 0 0 10px;
            font-size: 20px;
            letter-spacing: -0.4px;
        }

        .section-heading p {
            margin: 0;
            color: #8b92ab;
            font-size: 13px;
            line-height: 1.6;
        }

        .section-link {
            flex-shrink: 0;
            padding-top: 5px;
            color: #6947f5;
            font-size: 12px;
            font-weight: 700;
            text-decoration: none;
        }

        /* ===== Overview cards ===== */

        .overview-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 38px;
        }

        .overview-card {
            min-width: 0;
            min-height: 155px;
            padding: 22px;
            border: 1px solid #ececf4;
            border-radius: 16px;
            background: #ffffff;
        }

        .stat-icon {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 43px;
            height: 43px;
            margin-bottom: 18px;
            border-radius: 13px;
            font-size: 21px;
        }

        .stat-purple {
            color: #7955ff;
            background: #f0eaff;
        }

        .stat-blue {
            color: #3e8af4;
            background: #e8f2ff;
        }

        .stat-orange {
            color: #f18c42;
            background: #fff0e2;
        }

        .stat-green {
            color: #25b77a;
            background: #e3f8ee;
        }

        .overview-card h3 {
            margin: 0 0 8px;
            color: #7f879f;
            font-size: 12px;
            font-weight: 500;
        }

        .stat-value {
            margin: 0;
            color: #17213f;
            font-size: 27px;
            font-weight: 700;
        }

        .stat-note {
            display: block;
            margin-top: 8px;
            color: #999fb3;
            font-size: 11px;
        }

        /* ===== Internship cards ===== */

        .internship-section {
            margin-bottom: 38px;
        }

        .internship-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 18px;
        }

        .internship-card {
            display: flex;
            flex-direction: column;
            min-width: 0;
            padding: 23px;
            border: 1px solid #ececf4;
            border-radius: 17px;
            background: #ffffff;
            box-shadow: 0 5px 20px rgba(36, 31, 83, 0.035);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .internship-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 28px rgba(36, 31, 83, 0.08);
        }

        .internship-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 25px;
        }

        .company-avatar {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 46px;
            height: 46px;
            flex-shrink: 0;
            border-radius: 13px;
            font-size: 21px;
            font-weight: 700;
        }

        .company-blue {
            color: #3882ed;
            background: #e8f2ff;
        }

        .company-purple {
            color: #8055f5;
            background: #f0eaff;
        }

        .company-orange {
            color: #f18c42;
            background: #fff0e0;
        }

        .work-mode {
            padding: 7px 10px;
            border-radius: 20px;
            background: #f1edff;
            color: #7452ef;
            font-size: 10px;
            font-weight: 700;
        }

        .internship-card h3 {
            margin: 0 0 9px;
            font-size: 16px;
            line-height: 1.5;
        }

        .company-name {
            margin: 0 0 17px;
            color: #858ca5;
            font-size: 12px;
        }

        .internship-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 18px;
            color: #7f879f;
            font-size: 11px;
        }

        .skill-list {
            display: flex;
            flex-wrap: wrap;
            gap: 7px;
            margin-bottom: 23px;
        }

        .skill-tag {
            padding: 7px 9px;
            border-radius: 6px;
            background: #f5f5fa;
            color: #727a95;
            font-size: 10px;
        }

        .card-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            margin-top: auto;
            padding: 12px;
            border: 1px solid #e4dcff;
            border-radius: 9px;
            color: #6947f5;
            font-size: 12px;
            font-weight: 700;
            text-align: center;
            text-decoration: none;
        }

        .card-link:hover {
            background: #f5f1ff;
        }

        /* ===== Footer ===== */

        .dashboard-footer {
            padding: 22px 0 10px;
            border-top: 1px solid #ececf4;
            color: #9299b0;
            font-size: 12px;
            line-height: 1.7;
            text-align: center;
        }

        /* ===== Responsive layout ===== */

        @media (max-width: 1200px) {
            .dashboard-main {
                padding-right: 24px;
                padding-left: 24px;
            }

            .overview-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .internship-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .welcome-banner {
                padding: 30px;
            }
        }

        @media (max-width: 760px) {
            .dashboard-layout {
                display: block;
            }

            .sidebar {
                width: 100%;
                max-width: 100%;
                min-width: 0;
                min-height: 0;
                padding: 15px;
                border-right: none;
                border-bottom: 1px solid #ececf4;
            }

            .sidebar-brand {
                margin-bottom: 18px;
            }

            .sidebar-label {
                margin-bottom: 8px;
            }

            .sidebar-nav {
                display: grid;
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .menu-item {
                min-height: 42px;
                padding: 10px;
                font-size: 12px;
            }

            .sidebar-bottom {
                margin-top: 15px;
                padding-top: 0;
            }

            .sidebar-help {
                display: none;
            }

            .logout-link {
                margin-top: 0;
            }

            .dashboard-main {
                width: 100%;
                padding: 0 16px 28px;
            }

            .topbar {
                flex-wrap: wrap;
                margin-bottom: 20px;
            }

            .topbar-right {
                flex-wrap: wrap;
                gap: 10px;
            }

            .search-box {
                width: 160px;
            }

            .welcome-banner {
                min-height: 0;
                padding: 25px;
                margin-bottom: 28px;
            }

            .welcome-decoration {
                display: none;
            }

            .welcome-banner h1 {
                font-size: 28px;
            }

            .overview-grid,
            .internship-grid {
                grid-template-columns: minmax(0, 1fr);
                gap: 13px;
            }

            .overview-card {
                min-height: 0;
            }

            .section-heading h2 {
                font-size: 18px;
            }
        }

        @media (max-width: 400px) {
            .sidebar-nav {
                grid-template-columns: minmax(0, 1fr);
            }

            .search-box {
                width: 100%;
            }

            .welcome-banner {
                padding: 20px;
            }

            .welcome-banner h1 {
                font-size: 24px;
            }
        }
    </style>
</head>

<body class="dashboard-page">

<div class="dashboard-layout">

    <!-- LEFT SIDEBAR -->
    <aside class="sidebar">

        <a href="<%= contextPath %>/dashboard.jsp"
           class="sidebar-brand">
            <span class="brand-icon">✦</span>
            <strong>CareerLaunch</strong>
        </a>

        <p class="sidebar-label">WORKSPACE</p>

        <nav class="sidebar-nav" aria-label="Main navigation">

            <a href="<%= contextPath %>/dashboard.jsp"
               class="menu-item active">
                <span class="menu-icon">▦</span>
                <span>Dashboard</span>
            </a>

            <a href="<%= contextPath %>/internships.jsp"
               class="menu-item">
                <span class="menu-icon">⌕</span>
                <span>Find Internships</span>
            </a>

            <a href="<%= contextPath %>/applications.jsp"
               class="menu-item">
                <span class="menu-icon">▤</span>
                <span>My Applications</span>
            </a>

            <a href="<%= contextPath %>/profile.jsp"
               class="menu-item">
                <span class="menu-icon">♟</span>
                <span>My Profile</span>
            </a>

            <a href="<%= contextPath %>/about.jsp"
               class="menu-item">
                <span class="menu-icon">ⓘ</span>
                <span>About Portal</span>
            </a>

            <a href="<%= contextPath %>/contact.jsp"
               class="menu-item">
                <span class="menu-icon">✉</span>
                <span>Contact &amp; Support</span>
            </a>

            <a href="<%= contextPath %>/help.jsp"
               class="menu-item">
                <span class="menu-icon">?</span>
                <span>Help &amp; FAQ</span>
            </a>

        </nav>

        <!-- Support card stays inside the sidebar -->
        <div class="sidebar-bottom">

            <div class="sidebar-help">
                <div class="help-icon">✦</div>

                <h3>Need some help?</h3>

                <p>
                    We're here to support your career journey.
                </p>

                <a href="<%= contextPath %>/contact.jsp">
                    Contact Support →
                </a>
            </div>

            <a href="<%= contextPath %>/LogoutServlet"
               class="menu-item logout-link">
                <span class="menu-icon">↪</span>
                <span>Logout</span>
            </a>

        </div>

    </aside>

    <!-- MAIN DASHBOARD -->
    <main class="dashboard-main">

        <!-- TOP BAR -->
        <header class="topbar">

            <div class="breadcrumb">
                Workspace &nbsp;/&nbsp;
                <strong>Dashboard</strong>
            </div>

            <div class="topbar-right">

                <form action="<%= contextPath %>/internships.jsp"
                      method="get">
                    <input
                        type="search"
                        class="search-box"
                        name="search"
                        placeholder="⌕  Search internships..."
                        aria-label="Search internships">
                </form>

                <div class="user-summary">
                    <div class="avatar"><%= initial %></div>

                    <div>
                        <strong><%= safeName %></strong>
                        <small><%= course %></small>
                    </div>
                </div>

            </div>

        </header>

        <!-- WELCOME BANNER -->
        <section class="welcome-banner">

            <div class="welcome-content">

                <div class="welcome-eyebrow">
                    AUTHENTICATED SESSION ACTIVE
                </div>

                <h1>
                    Good day, <%= firstName %>!
                </h1>

                <p>
                    Welcome back to your personalized CareerLaunch
                    dashboard. Track your applications, discover
                    tailored internship opportunities, and accelerate
                    your professional career.
                </p>

                <a href="<%= contextPath %>/internships.jsp"
                   class="primary-button">
                    Explore Internships <span>→</span>
                </a>

            </div>

            <div class="welcome-decoration">
                <div>
                    <span style="font-size: 27px;">✦</span>
                    <strong>Logged In As</strong>
                    <small><%= username %></small>
                </div>
            </div>

        </section>

        <!-- OVERVIEW -->
        <section aria-labelledby="overview-title">

            <div class="section-heading">
                <div>
                    <h2 id="overview-title">Your Overview</h2>
                    <p>
                        Live snapshot of your internship opportunities
                        and applications.
                    </p>
                </div>
            </div>

            <div class="overview-grid">

                <article class="overview-card">
                    <div class="stat-icon stat-purple">▤</div>
                    <h3>Total Applications</h3>
                    <p class="stat-value">—</p>
                    <span class="stat-note">
                        Visit My Applications for details
                    </span>
                </article>

                <article class="overview-card">
                    <div class="stat-icon stat-blue">⌕</div>
                    <h3>Available Internships</h3>
                    <p class="stat-value">6</p>
                    <span class="stat-note">
                        Explore available opportunities
                    </span>
                </article>

                <article class="overview-card">
                    <div class="stat-icon stat-orange">♡</div>
                    <h3>Saved Opportunities</h3>
                    <p class="stat-value">—</p>
                    <span class="stat-note">
                        Discover internships matching your interests
                    </span>
                </article>

                <article class="overview-card">
                    <div class="stat-icon stat-green">✓</div>
                    <h3>Profile Status</h3>
                    <p class="stat-value" style="font-size: 22px;">
                        Active
                    </p>
                    <span class="stat-note">
                        Your account is logged in
                    </span>
                </article>

            </div>

        </section>

        <!-- RECOMMENDED INTERNSHIPS -->
        <section class="internship-section"
                 aria-labelledby="internships-title">

            <div class="section-heading">

                <div>
                    <h2 id="internships-title">
                        Recommended Internships for <%= course %>
                    </h2>

                    <p>
                        Explore opportunities to develop your skills
                        and gain practical experience.
                    </p>
                </div>

                <a href="<%= contextPath %>/internships.jsp"
                   class="section-link">
                    View All Opportunities →
                </a>

            </div>

            <div class="internship-grid">

                <!-- Internship 1 -->
                <article class="internship-card">

                    <div class="internship-top">
                        <div class="company-avatar company-blue">T</div>
                        <span class="work-mode">Hybrid</span>
                    </div>

                    <h3>Java Developer Intern</h3>
                    <p class="company-name">TechNova Solutions</p>

                    <div class="internship-meta">
                        <span>⌖ Bengaluru</span>
                        <span>◷ 3 Months</span>
                    </div>

                    <div class="skill-list">
                        <span class="skill-tag">Java</span>
                        <span class="skill-tag">Spring Boot</span>
                        <span class="skill-tag">MySQL</span>
                        <span class="skill-tag">REST APIs</span>
                    </div>

                    <a href="<%= contextPath %>/internships.jsp"
                       class="card-link">
                        View &amp; Apply →
                    </a>

                </article>

                <!-- Internship 2 -->
                <article class="internship-card">

                    <div class="internship-top">
                        <div class="company-avatar company-purple">D</div>
                        <span class="work-mode">Remote</span>
                    </div>

                    <h3>Web Development Intern</h3>
                    <p class="company-name">DigitalWorks Studio</p>

                    <div class="internship-meta">
                        <span>⌖ Mumbai</span>
                        <span>◷ 6 Months</span>
                    </div>

                    <div class="skill-list">
                        <span class="skill-tag">HTML5</span>
                        <span class="skill-tag">CSS3</span>
                        <span class="skill-tag">JavaScript</span>
                        <span class="skill-tag">React</span>
                        <span class="skill-tag">Responsive Design</span>
                    </div>

                    <a href="<%= contextPath %>/internships.jsp"
                       class="card-link">
                        View &amp; Apply →
                    </a>

                </article>

                <!-- Internship 3 -->
                <article class="internship-card">

                    <div class="internship-top">
                        <div class="company-avatar company-orange">I</div>
                        <span class="work-mode">On-site</span>
                    </div>

                    <h3>Data Analytics Intern</h3>
                    <p class="company-name">InnovateAI Analytics</p>

                    <div class="internship-meta">
                        <span>⌖ Hyderabad</span>
                        <span>◷ 4 Months</span>
                    </div>

                    <div class="skill-list">
                        <span class="skill-tag">Python</span>
                        <span class="skill-tag">SQL</span>
                        <span class="skill-tag">Pandas</span>
                        <span class="skill-tag">Power BI</span>
                        <span class="skill-tag">Data Visualization</span>
                    </div>

                    <a href="<%= contextPath %>/internships.jsp"
                       class="card-link">
                        View &amp; Apply →
                    </a>

                </article>

            </div>

        </section>

        <!-- FOOTER -->
        <footer class="dashboard-footer">
            <p>
                © <%= java.time.Year.now().getValue() %>
                CareerLaunch. Supporting your professional journey.
            </p>
        </footer>

    </main>

</div>

</body>
</html>

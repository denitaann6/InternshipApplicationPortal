<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");
    boolean isLoggedIn = (currentUser != null);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About | CareerLaunch Portal</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .page-wrap {
            max-width: 1100px;
            margin: 0 auto;
            padding: 40px 24px;
        }
        .content-card {
            background: white;
            border-radius: 16px;
            padding: 36px;
            margin-bottom: 24px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
        }
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .feature-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 22px;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .feature-box:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .feature-category {
            font-size: 12px;
            font-weight: 700;
            color: #4f46e5;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 6px;
        }
        .feature-title {
            font-size: 17px;
            font-weight: 700;
            color: #1e1b4b;
            margin-bottom: 8px;
        }
        .tech-pill {
            display: inline-block;
            background: #e0e7ff;
            color: #4338ca;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            margin: 4px;
        }
    </style>
</head>
<body style="background: #eef2ff;">

    <!-- Top Navigation Header -->
    <header class="landing-nav" style="background: white; border-bottom: 1px solid #e2e8f0; padding: 18px 40px;">
        <a href="index.html" class="landing-brand">
            <span class="landing-brand-icon">✦</span>
            <span>Career<span>Launch</span></span>
        </a>

        <nav class="landing-menu">
            <a href="index.html">Home</a>
            <a href="internships.jsp">Internships</a>
            <a href="about.jsp" style="color: #4f46e5; font-weight: 700;">About</a>
            <a href="contact.jsp">Contact</a>
            <a href="help.jsp">Help & FAQ</a>
            <% if (isLoggedIn) { %>
                <a href="dashboard.jsp" class="landing-register">My Dashboard →</a>
            <% } else { %>
                <a href="login.html">Login</a>
                <a href="register.html" class="landing-register">Get Started</a>
            <% } %>
        </nav>
    </header>

    <div class="page-wrap">

        <!-- About CareerLaunch -->
        <div class="content-card">
            <span class="demo-badge" style="background: #e0e7ff; color: #4338ca; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">
                Career Development Platform
            </span>
            <h1 style="font-size: 28px; color: #1e1b4b; margin: 12px 0;">About CareerLaunch</h1>
            <p style="color: #475569; font-size: 15px; line-height: 1.7;">
                CareerLaunch is a career development platform designed to help students and aspiring professionals discover internship opportunities and organize their career journey. The platform brings internship discovery, application management, and career profile maintenance together in one convenient place.
            </p>
        </div>

        <!-- Our Purpose -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 12px;">Our Purpose</h2>
            <p style="color: #475569; font-size: 15px; line-height: 1.7;">
                Our purpose is to make internship opportunities easier to discover and application progress easier to manage. CareerLaunch provides an organized environment where users can explore opportunities, submit applications, and stay informed about their application status.
            </p>
        </div>

        <!-- What the Platform Offers -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 8px;">What the Platform Offers</h2>
            <p style="color: #64748b; font-size: 14px;">Integrated capabilities designed to streamline the internship discovery and application process:</p>

            <div class="feature-grid">
                <div class="feature-box">
                    <div class="feature-category">Discovery</div>
                    <div class="feature-title">Internship Discovery</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Explore available opportunities and filter listings by relevant categories and work arrangements.
                    </p>
                </div>

                <div class="feature-box">
                    <div class="feature-category">Applications</div>
                    <div class="feature-title">Application Management</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Submit applications and maintain an organized record of opportunities applied for.
                    </p>
                </div>

                <div class="feature-box">
                    <div class="feature-category">Tracking</div>
                    <div class="feature-title">Application Tracking</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Review application status and monitor progress through the portal.
                    </p>
                </div>

                <div class="feature-box">
                    <div class="feature-category">Profile</div>
                    <div class="feature-title">Career Profile</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Maintain profile information that supports the internship application process.
                    </p>
                </div>

                <div class="feature-box" style="border-color: #4f46e5; background: #faf5ff;">
                    <div class="feature-category" style="color: #7c3aed;">Administration</div>
                    <div class="feature-title">Administrative Management</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Authorized administrators can maintain internship listings and review submitted applications.
                    </p>
                </div>
            </div>
        </div>

        <!-- Our Approach -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 12px;">Our Approach</h2>
            <p style="color: #475569; font-size: 15px; line-height: 1.7;">
                CareerLaunch focuses on usability, organized information, and a straightforward application experience. Its goal is to help users manage internship-related activities more efficiently through a centralized digital platform.
            </p>
        </div>

        <!-- Technology Foundation -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 12px;">Technology Foundation</h2>
            <div>
                <span class="tech-pill">Java</span>
                <span class="tech-pill">Apache Tomcat</span>
                <span class="tech-pill">Java Servlets</span>
                <span class="tech-pill">JavaServer Pages (JSP)</span>
                <span class="tech-pill">MySQL</span>
                <span class="tech-pill">HTML5 &amp; CSS3</span>
                <span class="tech-pill">JavaScript</span>
            </div>
        </div>

        <footer style="text-align: center; color: #64748b; font-size: 13px; padding: 20px 0;">
            &copy; 2026 CareerLaunch &middot; Internship Application Portal
        </footer>

    </div>

</body>
</html>

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
        .phase-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .phase-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 20px;
        }
        .phase-number {
            font-size: 12px;
            font-weight: 700;
            color: #4f46e5;
            text-transform: uppercase;
            margin-bottom: 6px;
        }
        .phase-title {
            font-size: 16px;
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

        <div class="content-card">
            <span class="demo-badge" style="background: #e0e7ff; color: #4338ca; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">
                MCA Academic Practical Project
            </span>
            <h1 style="font-size: 28px; color: #1e1b4b; margin: 12px 0;">About CareerLaunch</h1>
            <p style="color: #475569; font-size: 15px; line-height: 1.7;">
                <strong>CareerLaunch</strong> is a comprehensive Internship Application Portal developed for the
                course <strong>26MCA1L211: Java and Web Programming Practical</strong> (Semester I MCA).
                The project demonstrates progressive web software engineering across 4 curriculum phases—combining
                core Java object-oriented principles, modular architecture, responsive frontend design, and Java enterprise web technologies (Servlets &amp; JSP).
            </p>
        </div>

        <!-- 4 Phases Showcase -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 8px;">Curriculum Phase Architecture</h2>
            <p style="color: #64748b; font-size: 14px;">The portal implements the four stages specified by the course syllabus:</p>

            <div class="phase-grid">
                <div class="phase-box">
                    <div class="phase-number">Phase 1</div>
                    <div class="phase-title">Core OOP & Design</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        User entity model with encapsulation, constructors, string validation, and standalone console runner (<code>Main.java</code>).
                    </p>
                </div>

                <div class="phase-box">
                    <div class="phase-number">Phase 2</div>
                    <div class="phase-title">Structured Programming</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Modular package hierarchy, <code>UserOperations</code> interface abstraction, <code>UserService</code>, and <code>InvalidInputException</code> handling.
                    </p>
                </div>

                <div class="phase-box">
                    <div class="phase-number">Phase 3</div>
                    <div class="phase-title">Web Client Interface</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Responsive HTML5 forms, CareerLaunch purple/indigo theme, JavaScript format checks, and JSON data structures.
                    </p>
                </div>

                <div class="phase-box" style="border-color: #4f46e5; background: #faf5ff;">
                    <div class="phase-number" style="color: #7c3aed;">Phase 4</div>
                    <div class="phase-title">Server Integration</div>
                    <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
                        Java Servlets (GET/POST), server-side validation, <code>HttpSession</code> state management, dynamic JSP dashboard, and access security.
                    </p>
                </div>
            </div>
        </div>

        <!-- Technology Stack -->
        <div class="content-card">
            <h2 style="font-size: 22px; color: #1e1b4b; margin-bottom: 12px;">Technology Stack</h2>
            <div>
                <span class="tech-pill">Java 26 / Java EE</span>
                <span class="tech-pill">Apache Tomcat 8.5.96</span>
                <span class="tech-pill">Java Servlets 3.1</span>
                <span class="tech-pill">JavaServer Pages (JSP) 2.3</span>
                <span class="tech-pill">HTML5 &amp; CSS3</span>
                <span class="tech-pill">Vanilla JavaScript</span>
                <span class="tech-pill">JSON Sample Data</span>
            </div>
        </div>

        <footer style="text-align: center; color: #64748b; font-size: 13px; padding: 20px 0;">
            © 2026 CareerLaunch · MCA Practical Project · Course: 26MCA1L211
        </footer>

    </div>

</body>
</html>

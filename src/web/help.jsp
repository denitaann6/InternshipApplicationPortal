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
    <title>Help & FAQ | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .page-wrap {
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 24px;
        }
        .faq-item {
            background: white;
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 16px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.03);
            border: 1px solid #e2e8f0;
        }
        .faq-question {
            font-size: 16px;
            font-weight: 700;
            color: #1e1b4b;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .faq-q-icon {
            color: #4f46e5;
            font-size: 18px;
        }
        .faq-answer {
            color: #475569;
            font-size: 14px;
            line-height: 1.6;
        }
        .guide-step {
            display: flex;
            gap: 16px;
            margin-bottom: 20px;
            align-items: flex-start;
        }
        .step-circle {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: #4f46e5;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
            flex-shrink: 0;
        }
    </style>
</head>
<body style="background: #eef2ff;">

    <header class="landing-nav" style="background: white; border-bottom: 1px solid #e2e8f0; padding: 18px 40px;">
        <a href="index.html" class="landing-brand">
            <span class="landing-brand-icon">✦</span>
            <span>Career<span>Launch</span></span>
        </a>

        <nav class="landing-menu">
            <a href="index.html">Home</a>
            <a href="internships.jsp">Internships</a>
            <a href="about.jsp">About</a>
            <a href="contact.jsp">Contact</a>
            <a href="help.jsp" style="color: #4f46e5; font-weight: 700;">Help & FAQ</a>
            <% if (isLoggedIn) { %>
                <a href="dashboard.jsp" class="landing-register">My Dashboard →</a>
            <% } else { %>
                <a href="login.html">Login</a>
                <a href="register.html" class="landing-register">Get Started</a>
            <% } %>
        </nav>
    </header>

    <div class="page-wrap">

        <div style="text-align: center; margin-bottom: 32px;">
            <h1 style="font-size: 32px; color: #1e1b4b;">Help Center & Student Guide</h1>
            <p style="color: #64748b; font-size: 15px;">Frequently asked questions and instructions for navigating the CareerLaunch Portal.</p>
        </div>

        <!-- Student Onboarding Guide -->
        <div style="background: white; border-radius: 16px; padding: 32px; margin-bottom: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.04);">
            <h2 style="font-size: 20px; color: #1e1b4b; margin-bottom: 20px;">Quick Start Guide</h2>

            <div class="guide-step">
                <div class="step-circle">1</div>
                <div>
                    <strong style="color: #1e1b4b; font-size: 15px; display: block;">Create Your Account</strong>
                    <span style="color: #64748b; font-size: 13px;">Navigate to the registration page, fill in your academic information and internship interests, and submit the form to <code>RegisterServlet</code>.</span>
                </div>
            </div>

            <div class="guide-step">
                <div class="step-circle">2</div>
                <div>
                    <strong style="color: #1e1b4b; font-size: 15px; display: block;">Sign In with Credentials</strong>
                    <span style="color: #64748b; font-size: 13px;">Submit your username or email and password. <code>LoginServlet</code> validates your account on the server and initiates a secure <code>HttpSession</code>.</span>
                </div>
            </div>

            <div class="guide-step">
                <div class="step-circle">3</div>
                <div>
                    <strong style="color: #1e1b4b; font-size: 15px; display: block;">Access the Personalized JSP Dashboard</strong>
                    <span style="color: #64748b; font-size: 13px;">Your dynamic dashboard displays your academic record, overview metrics, and recommended internship opportunities. Direct access is protected.</span>
                </div>
            </div>

            <div class="guide-step">
                <div class="step-circle">4</div>
                <div>
                    <strong style="color: #1e1b4b; font-size: 15px; display: block;">Search, Filter & Apply</strong>
                    <span style="color: #64748b; font-size: 13px;">Browse the Internship Explorer, filter roles by category (Java, Web, Data, AI) or mode (Remote, Hybrid), and submit applications.</span>
                </div>
            </div>

            <div class="guide-step" style="margin-bottom: 0;">
                <div class="step-circle" style="background: #dc2626;">5</div>
                <div>
                    <strong style="color: #1e1b4b; font-size: 15px; display: block;">Secure Logout</strong>
                    <span style="color: #64748b; font-size: 13px;">Click Logout to invoke <code>LogoutServlet</code>, invalidating the session and protecting your account from unauthorized browser navigation.</span>
                </div>
            </div>
        </div>

        <!-- FAQ List -->
        <h2 style="font-size: 20px; color: #1e1b4b; margin-bottom: 16px;">Frequently Asked Questions</h2>

        <div class="faq-item">
            <div class="faq-question">
                <span class="faq-q-icon">?</span>
                How does server-side session authentication work in Phase 4?
            </div>
            <div class="faq-answer">
                When you sign in, <code>LoginServlet</code> validates your credentials against <code>UserService</code>. Upon successful verification, an <code>HttpSession</code> is created and stored on the server. Your authenticated user model is linked to this session, allowing protected pages like <code>dashboard.jsp</code> and <code>profile.jsp</code> to recognize your identity without transmitting passwords in subsequent requests.
            </div>
        </div>

        <div class="faq-item">
            <div class="faq-question">
                <span class="faq-q-icon">?</span>
                What happens if I try to access dashboard.jsp directly without logging in?
            </div>
            <div class="faq-answer">
                Every protected JSP page contains a session guard at the top. If <code>session.getAttribute("currentUser")</code> is null, the server immediately issues an HTTP redirect back to <code>login.html</code> with an authorization alert.
            </div>
        </div>

        <div class="faq-item">
            <div class="faq-question">
                <span class="faq-q-icon">?</span>
                Can duplicate accounts with the same username or email be registered?
            </div>
            <div class="faq-answer">
                No. Both client-side JavaScript and the server-side <code>UserService.registerUser()</code> method perform duplicate checks. Attempting to register an existing username or email triggers an <code>InvalidInputException</code> and informs the user.
            </div>
        </div>

        <div class="faq-item">
            <div class="faq-question">
                <span class="faq-q-icon">?</span>
                Where are user accounts stored?
            </div>
            <div class="faq-answer">
                As specified by the practical syllabus without an external database setup, accounts are stored in a thread-safe, in-memory repository (<code>ConcurrentHashMap</code>) pre-seeded with sample user Ann.
            </div>
        </div>

        <footer style="text-align: center; color: #64748b; font-size: 13px; padding: 40px 0 20px 0;">
            © 2026 CareerLaunch · MCA Practical Project (26MCA1L211)
        </footer>

    </div>

</body>
</html>

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
    <title>Contact & Support | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .page-wrap {
            max-width: 1000px;
            margin: 0 auto;
            padding: 40px 24px;
        }
        .contact-grid {
            display: grid;
            grid-template-columns: 1fr 1.3fr;
            gap: 28px;
            margin-top: 24px;
        }
        @media (max-width: 768px) {
            .contact-grid {
                grid-template-columns: 1fr;
            }
        }
        .info-card {
            background: linear-gradient(135deg, #17153b, #302b72, #5147a8);
            border-radius: 16px;
            padding: 36px;
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }
        .form-card {
            background: white;
            border-radius: 16px;
            padding: 36px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
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
            <a href="contact.jsp" style="color: #4f46e5; font-weight: 700;">Contact</a>
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

        <div style="text-align: center; margin-bottom: 16px;">
            <h1 style="font-size: 32px; color: #1e1b4b;">Get in Touch</h1>
            <p style="color: #64748b; font-size: 15px;">Have questions about internship applications or portal navigation? We are here to help.</p>
        </div>

        <div class="contact-grid">

            <div class="info-card">
                <div>
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 20px;">
                        <span style="font-size: 24px;">✦</span>
                        <strong style="font-size: 20px;">CareerLaunch Support</strong>
                    </div>

                    <p style="font-size: 14px; opacity: 0.85; line-height: 1.6; margin-bottom: 28px;">
                        Dedicated academic project support for students, evaluators, and project mentors.
                    </p>

                    <div style="display: flex; flex-direction: column; gap: 18px; font-size: 14px;">
                        <div>
                            <small style="opacity: 0.7; display: block; font-size: 11px; text-transform: uppercase;">Campus Lab Location</small>
                            <strong>MCA Computer Laboratory 3, Department of Computer Applications</strong>
                        </div>
                        <div>
                            <small style="opacity: 0.7; display: block; font-size: 11px; text-transform: uppercase;">Support Email</small>
                            <strong>support@careerlaunch.example</strong>
                        </div>
                        <div>
                            <small style="opacity: 0.7; display: block; font-size: 11px; text-transform: uppercase;">Operating Hours</small>
                            <strong>Monday – Friday, 9:00 AM – 5:00 PM IST</strong>
                        </div>
                    </div>
                </div>

                <div style="margin-top: 30px; font-size: 12px; opacity: 0.75;">
                    Course: 26MCA1L211 · Java &amp; Web Programming Practical
                </div>
            </div>

            <div class="form-card">
                <h3 style="font-size: 18px; color: #1e1b4b; margin-bottom: 16px;">Send Us a Message</h3>

                <form id="contactForm" onsubmit="handleContactSubmit(event)">
                    <div class="input-group">
                        <label for="contactName">Your Name</label>
                        <input type="text" id="contactName" placeholder="Enter your full name"
                               value="<%= isLoggedIn ? currentUser.getFullName() : "" %>" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactEmail">Your Email</label>
                        <input type="email" id="contactEmail" placeholder="you@example.com"
                               value="<%= isLoggedIn ? currentUser.getEmail() : "" %>" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactSubject">Subject</label>
                        <input type="text" id="contactSubject" placeholder="Inquiry about internship applications" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactMessage">Message</label>
                        <textarea id="contactMessage" rows="4" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #cbd5e1; font-family: inherit; font-size: 14px;" placeholder="Describe your question or feedback..." required></textarea>
                    </div>

                    <button type="submit" class="primary-button" style="width: 100%; margin-top: 20px; justify-content: center;">
                        Send Message <span>→</span>
                    </button>
                </form>

                <div id="contactSuccessNotice" style="display: none; margin-top: 18px; padding: 14px; background: #dcfce7; color: #166534; border-radius: 8px; font-size: 13px;">
                    ✓ Thank you! Your demonstration message has been recorded. Our team will review it during practical lab hours.
                </div>
            </div>

        </div>

        <footer style="text-align: center; color: #64748b; font-size: 13px; padding: 40px 0 20px 0;">
            © 2026 CareerLaunch · MCA Practical Project
        </footer>

    </div>

    <script>
        function handleContactSubmit(e) {
            e.preventDefault();
            const form = document.getElementById("contactForm");
            const notice = document.getElementById("contactSuccessNotice");
            notice.style.display = "block";
            form.reset();
        }
    </script>
</body>
</html>

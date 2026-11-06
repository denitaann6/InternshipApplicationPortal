<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");
    boolean isLoggedIn = (currentUser != null);

    String status = request.getParameter("status");
    String msg = request.getParameter("msg");
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
        .alert-box {
            padding: 14px 16px;
            border-radius: 8px;
            font-size: 13px;
            line-height: 1.5;
            margin-bottom: 18px;
        }
        .alert-success {
            background: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
        }
        .alert-error {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
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

                    <p style="font-size: 14px; opacity: 0.9; line-height: 1.6; margin-bottom: 28px;">
                        We're here to help with questions about accessing the platform, exploring internship opportunities, managing applications, and using your account. Submit your message through the contact form, and your enquiry will be recorded for review.
                    </p>

                    <div style="display: flex; flex-direction: column; gap: 18px; font-size: 14px;">
                        <div>
                            <small style="opacity: 0.7; display: block; font-size: 11px; text-transform: uppercase;">Inquiry Review</small>
                            <strong>All submissions are recorded directly into the platform database for administrative review.</strong>
                        </div>
                        <div>
                            <small style="opacity: 0.7; display: block; font-size: 11px; text-transform: uppercase;">Portal Assistance</small>
                            <span>Guidance for internship discovery, profile management, and application tracking.</span>
                        </div>
                    </div>
                </div>

                <div style="margin-top: 30px; font-size: 12px; opacity: 0.85;">
                    Internship Application Portal &middot; Support Desk
                </div>
            </div>

            <div class="form-card">
                <h3 style="font-size: 18px; color: #1e1b4b; margin-bottom: 16px;">Send Us a Message</h3>

                <% if ("success".equalsIgnoreCase(status)) { %>
                    <div class="alert-box alert-success">
                        &#10003; <%= (msg != null && !msg.trim().isEmpty()) ? msg : "Thank you! Your message has been received and recorded for review." %>
                    </div>
                <% } else if ("error".equalsIgnoreCase(status)) { %>
                    <div class="alert-box alert-error">
                        &#9888; <%= (msg != null && !msg.trim().isEmpty()) ? msg : "Unable to submit your message. Please check the fields and try again." %>
                    </div>
                <% } %>

                <div id="contactAlert" style="display: none;" class="alert-box"></div>

                <form id="contactForm" action="<%= request.getContextPath() %>/ContactServlet" method="POST" onsubmit="handleContactSubmit(event)">
                    <div class="input-group">
                        <label for="contactName">Your Name</label>
                        <input type="text" id="contactName" name="name" maxlength="100" placeholder="Enter your full name"
                               value="<%= isLoggedIn ? (currentUser.getFullName() != null && !currentUser.getFullName().isEmpty() ? currentUser.getFullName() : currentUser.getUsername()) : "" %>" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactEmail">Your Email</label>
                        <input type="email" id="contactEmail" name="email" maxlength="255" placeholder="you@example.com"
                               value="<%= isLoggedIn ? (currentUser.getEmail() != null ? currentUser.getEmail() : "") : "" %>" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactSubject">Subject</label>
                        <input type="text" id="contactSubject" name="subject" maxlength="200" placeholder="Inquiry about internship applications" required>
                    </div>

                    <div class="input-group" style="margin-top: 14px;">
                        <label for="contactMessage">Message</label>
                        <textarea id="contactMessage" name="message" rows="5" maxlength="4000" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #cbd5e1; font-family: inherit; font-size: 14px; box-sizing: border-box;" placeholder="Describe your question or feedback..." required></textarea>
                    </div>

                    <button type="submit" id="submitBtn" class="primary-button" style="width: 100%; margin-top: 20px; justify-content: center;">
                        <span id="btnText">Send Message</span> <span>→</span>
                    </button>
                </form>
            </div>

        </div>

        <footer style="text-align: center; color: #64748b; font-size: 13px; padding: 40px 0 20px 0;">
            &copy; 2026 CareerLaunch &middot; Internship Application Portal
        </footer>

    </div>

    <script>
        function handleContactSubmit(e) {
            e.preventDefault();
            const form = document.getElementById("contactForm");
            const submitBtn = document.getElementById("submitBtn");
            const btnText = document.getElementById("btnText");

            const name = document.getElementById("contactName").value.trim();
            const email = document.getElementById("contactEmail").value.trim();
            const subject = document.getElementById("contactSubject").value.trim();
            const message = document.getElementById("contactMessage").value.trim();

            if (!name || name.length < 2) {
                showAlert("Please enter your name (at least 2 characters).", false);
                return;
            }
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!email || !emailRegex.test(email)) {
                showAlert("Please enter a valid email address.", false);
                return;
            }
            if (!subject || subject.length < 3) {
                showAlert("Please enter a subject (at least 3 characters).", false);
                return;
            }
            if (!message || message.length < 5) {
                showAlert("Please enter a message (at least 5 characters).", false);
                return;
            }

            submitBtn.disabled = true;
            btnText.textContent = "Sending...";

            const params = new URLSearchParams();
            params.append("name", name);
            params.append("email", email);
            params.append("subject", subject);
            params.append("message", message);
            params.append("ajax", "true");

            fetch(form.action, {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                    "X-Requested-With": "XMLHttpRequest"
                },
                body: params.toString()
            })
            .then(function(res) {
                return res.json().catch(function() {
                    return { success: false, message: "Server returned an invalid response." };
                });
            })
            .then(function(data) {
                submitBtn.disabled = false;
                btnText.textContent = "Send Message";
                if (data && data.success) {
                    showAlert(data.message || "Thank you! Your message has been received and recorded for review.", true);
                    document.getElementById("contactSubject").value = "";
                    document.getElementById("contactMessage").value = "";
                    <% if (!isLoggedIn) { %>
                        document.getElementById("contactName").value = "";
                        document.getElementById("contactEmail").value = "";
                    <% } %>
                } else {
                    showAlert((data && data.message) ? data.message : "Unable to submit your message. Please try again.", false);
                }
            })
            .catch(function(err) {
                submitBtn.disabled = false;
                btnText.textContent = "Send Message";
                showAlert("Network or server connection error. Please try again.", false);
            });
        }

        function showAlert(text, isSuccess) {
            const alertBox = document.getElementById("contactAlert");
            alertBox.style.display = "block";
            alertBox.className = "alert-box " + (isSuccess ? "alert-success" : "alert-error");
            alertBox.textContent = (isSuccess ? "✓ " : "⚠ ") + text;
        }
    </script>
</body>
</html>

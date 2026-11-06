<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User" %>
<%@ page import="com.internshipportal.model.StudentProfile" %>
<%@ page import="com.internshipportal.service.StudentProfileService" %>
<%@ page import="java.text.SimpleDateFormat" %>
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

    // Fetch database-backed student profile from student_profiles table
    StudentProfileService profileService = StudentProfileService.getInstance();
    StudentProfile profile = profileService.getProfileByUserId(currentUser.getUserId());
    if (profile == null) {
        profile = new StudentProfile(currentUser.getUserId(), null, null, null, null, null);
    }

    String fullName = currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()
            ? currentUser.getFullName() : currentUser.getUsername();
    String initial = fullName.trim().substring(0, 1).toUpperCase();
    String course = currentUser.getCourse() != null && !currentUser.getCourse().trim().isEmpty()
            ? currentUser.getCourse() : "MCA";
    String email = currentUser.getEmail() != null ? currentUser.getEmail() : "Not provided";
    String phone = currentUser.getPhone() != null && !currentUser.getPhone().trim().isEmpty()
            ? currentUser.getPhone() : "";
    String interest = currentUser.getInternshipInterest() != null && !currentUser.getInternshipInterest().trim().isEmpty()
            ? currentUser.getInternshipInterest() : "";

    int completeness = profile.calculateCompleteness(currentUser);

    String lastUpdated = "Never updated";
    if (profile.getUpdatedAt() != null) {
        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy · hh:mm a");
        lastUpdated = sdf.format(profile.getUpdatedAt());
    }

    String msg = request.getParameter("msg");
    if (msg == null) msg = request.getParameter("success");
    String error = request.getParameter("error");

    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .profile-container {
            max-width: 960px;
            margin: 20px 0 40px;
            display: flex;
            flex-direction: column;
            gap: 24px;
        }

        .profile-card {
            background: white;
            border-radius: 16px;
            padding: 28px 32px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
            border: 1px solid #f1f5f9;
        }

        .profile-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 22px;
            padding-bottom: 14px;
            border-bottom: 1px solid #f1f5f9;
        }

        .profile-card-header h3 {
            font-size: 18px;
            color: #1e1b4b;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .badge-verified {
            background: #e0e7ff;
            color: #4338ca;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11.5px;
            font-weight: 600;
        }

        .progress-bar-container {
            width: 100%;
            height: 8px;
            background: #f1f5f9;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 10px;
        }

        .progress-bar-fill {
            height: 100%;
            background: linear-gradient(90deg, #4f46e5, #7c3aed);
            border-radius: 10px;
            transition: width 0.4s ease;
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group label {
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .form-group label small {
            font-size: 11px;
            font-weight: 400;
            color: #64748b;
        }

        .form-control {
            width: 100%;
            padding: 10px 14px;
            font-size: 13.5px;
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            background: #ffffff;
            color: #1e293b;
            box-sizing: border-box;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        .form-control:focus {
            border-color: #4f46e5;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.12);
        }

        .form-control:disabled, .form-control[readonly] {
            background: #f8fafc;
            color: #64748b;
            cursor: not-allowed;
            border-color: #e2e8f0;
        }

        .form-hint {
            font-size: 11.5px;
            color: #64748b;
            margin-top: 3px;
        }

        .alert-box {
            padding: 14px 18px;
            border-radius: 12px;
            font-size: 13.5px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .alert-success {
            background: #ecfdf5;
            border: 1px solid #a7f3d0;
            color: #065f46;
        }

        .alert-error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
        }

        .btn-submit {
            background: linear-gradient(135deg, #4f46e5, #6366f1);
            color: white;
            border: none;
            padding: 12px 26px;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);
        }

        .btn-cancel {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
            padding: 12px 20px;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            transition: background 0.2s;
        }

        .btn-cancel:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        .links-preview-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 16px;
            margin-top: 14px;
        }

        .link-pill {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 12px 16px;
            text-decoration: none;
            color: #1e293b;
            transition: all 0.2s;
        }

        .link-pill:hover {
            border-color: #4f46e5;
            background: #ffffff;
            box-shadow: 0 4px 12px rgba(0,0,0,0.04);
            transform: translateY(-2px);
        }

        .link-pill-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .link-icon-box {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
        }

        .link-icon-resume { background: #fee2e2; color: #dc2626; }
        .link-icon-linkedin { background: #e0f2fe; color: #0284c7; }
        .link-icon-github { background: #f1f5f9; color: #0f172a; }

        @media (max-width: 768px) {
            .profile-card {
                padding: 20px;
            }
            .form-grid {
                grid-template-columns: 1fr;
            }
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
                    <p>Manage your personal details, academic standing, and professional portfolio links.</p>
                </div>
            </section>

            <div class="profile-container">

                <!-- FEEDBACK BANNERS -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                    <div class="alert-box alert-success" id="msgBanner">
                        <span style="font-size: 18px;">✓</span>
                        <div><%= msg %></div>
                    </div>
                <% } %>

                <% if (error != null && !error.trim().isEmpty()) { %>
                    <div class="alert-box alert-error" id="errorBanner">
                        <span style="font-size: 18px;">⚠</span>
                        <div><%= error %></div>
                    </div>
                <% } %>

                <!-- Profile Header Card with Completeness Bar -->
                <div class="profile-card" style="display: flex; flex-direction: column; gap: 20px;">
                    <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 20px;">
                        <div style="display: flex; align-items: center; gap: 22px;">
                            <div style="width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, #4f46e5, #7c3aed); color: white; display: flex; align-items: center; justify-content: center; font-size: 36px; font-weight: 700; flex-shrink: 0;">
                                <%= initial %>
                            </div>
                            <div>
                                <h1 style="font-size: 24px; color: #1e1b4b; margin-bottom: 6px;"><%= fullName %></h1>
                                <p style="color: #64748b; font-size: 14px; margin-bottom: 8px;">
                                    <%= course %> Candidate · Student ID: <strong>CL-<%= currentUser.getUserId() %></strong>
                                </p>
                                <span class="badge-verified">
                                    ✓ Active Authenticated Student
                                </span>
                            </div>
                        </div>

                        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px 20px; min-width: 200px; text-align: right;">
                            <div style="font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: 700; letter-spacing: 0.5px;">Last Updated</div>
                            <div style="font-size: 13px; color: #1e1b4b; font-weight: 600; margin-top: 4px;" id="lastUpdatedDisplay">
                                <%= lastUpdated %>
                            </div>
                        </div>
                    </div>

                    <!-- Profile Completeness -->
                    <div style="border-top: 1px solid #f1f5f9; padding-top: 16px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; font-size: 13px;">
                            <span style="font-weight: 600; color: #334155;">Profile Completeness</span>
                            <span style="font-weight: 700; color: #4f46e5;" id="completenessLabel"><%= completeness %>%</span>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar-fill" id="completenessBar" style="width: <%= completeness %>%;"></div>
                        </div>
                    </div>
                </div>

                <!-- Active Portfolio Links Preview (If configured) -->
                <% if (profile.hasResumeUrl() || profile.hasLinkedinUrl() || profile.hasGithubUrl()) { %>
                    <div class="profile-card">
                        <div class="profile-card-header">
                            <h3><span>🔗</span> Connected Profiles & Resume</h3>
                            <span style="font-size: 12px; color: #64748b;">Direct Recruiter Links</span>
                        </div>

                        <div class="links-preview-grid">
                            <% if (profile.hasResumeUrl()) { %>
                                <a href="<%= profile.getResumeUrl() %>" target="_blank" rel="noopener noreferrer" class="link-pill">
                                    <div class="link-pill-info">
                                        <div class="link-icon-box link-icon-resume">📄</div>
                                        <div>
                                            <div style="font-size: 13px; font-weight: 600;">Resume / Portfolio</div>
                                            <small style="color: #64748b; font-size: 11px;">View Document ↗</small>
                                        </div>
                                    </div>
                                    <span style="color: #4f46e5; font-size: 14px;">→</span>
                                </a>
                            <% } %>

                            <% if (profile.hasLinkedinUrl()) { %>
                                <a href="<%= profile.getLinkedinUrl() %>" target="_blank" rel="noopener noreferrer" class="link-pill">
                                    <div class="link-pill-info">
                                        <div class="link-icon-box link-icon-linkedin">💼</div>
                                        <div>
                                            <div style="font-size: 13px; font-weight: 600;">LinkedIn Profile</div>
                                            <small style="color: #64748b; font-size: 11px;">View Network ↗</small>
                                        </div>
                                    </div>
                                    <span style="color: #4f46e5; font-size: 14px;">→</span>
                                </a>
                            <% } %>

                            <% if (profile.hasGithubUrl()) { %>
                                <a href="<%= profile.getGithubUrl() %>" target="_blank" rel="noopener noreferrer" class="link-pill">
                                    <div class="link-pill-info">
                                        <div class="link-icon-box link-icon-github">💻</div>
                                        <div>
                                            <div style="font-size: 13px; font-weight: 600;">GitHub Portfolio</div>
                                            <small style="color: #64748b; font-size: 11px;">View Repositories ↗</small>
                                        </div>
                                    </div>
                                    <span style="color: #4f46e5; font-size: 14px;">→</span>
                                </a>
                            <% } %>
                        </div>
                    </div>
                <% } %>

                <!-- Profile Editing Form -->
                <div class="profile-card">
                    <div class="profile-card-header">
                        <h3><span>✎</span> Edit Student Profile Details</h3>
                        <span style="font-size: 12px; color: #64748b;">Saved directly to MySQL</span>
                    </div>

                    <form id="profileForm" method="POST" action="<%= request.getContextPath() %>/ProfileServlet">
                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                        <!-- SECTION 1: PERSONAL & CONTACT INFORMATION -->
                        <h4 style="font-size: 14px; color: #4338ca; text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 14px;">
                            1. Personal & Contact Information
                        </h4>

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="fullName">Full Name <span style="color: #dc2626;">*</span></label>
                                <input type="text" id="fullName" name="fullName" class="form-control"
                                       value="<%= fullName %>" required maxlength="100" placeholder="e.g. Ananya Sharma">
                                <span class="form-hint">Displayed on internship applications and resumes</span>
                            </div>

                            <div class="form-group">
                                <label for="phone">Phone Number</label>
                                <input type="tel" id="phone" name="phone" class="form-control"
                                       value="<%= phone %>" maxlength="20" placeholder="e.g. +91 9876543210">
                                <span class="form-hint">For recruiter contact and interview notifications</span>
                            </div>

                            <div class="form-group">
                                <label for="usernameDisplay">Username <small>🔒 Read-Only Identifier</small></label>
                                <input type="text" id="usernameDisplay" class="form-control"
                                       value="<%= currentUser.getUsername() %>" readonly disabled>
                                <span class="form-hint">Fixed login identifier</span>
                            </div>

                            <div class="form-group">
                                <label for="emailDisplay">Email Address <small>🔒 Read-Only Identifier</small></label>
                                <input type="email" id="emailDisplay" class="form-control"
                                       value="<%= email %>" readonly disabled>
                                <span class="form-hint">Registered primary email for portal communications</span>
                            </div>
                        </div>

                        <!-- SECTION 2: ACADEMIC CREDENTIALS -->
                        <h4 style="font-size: 14px; color: #4338ca; text-transform: uppercase; letter-spacing: 0.8px; margin: 26px 0 14px;">
                            2. Academic Standing & Specialization
                        </h4>

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="course">Degree / Course Program</label>
                                <input type="text" id="course" name="course" class="form-control"
                                       value="<%= course %>" maxlength="50" placeholder="e.g. MCA, BCA, B.Tech CS">
                                <span class="form-hint">Current academic program</span>
                            </div>

                            <div class="form-group">
                                <label for="internshipInterest">Internship Focus / Domain</label>
                                <input type="text" id="internshipInterest" name="internshipInterest" class="form-control"
                                       value="<%= interest %>" maxlength="100" placeholder="e.g. Full Stack Java, Cloud, Data Analytics">
                                <span class="form-hint">Helps match tailored internship listings</span>
                            </div>

                            <div class="form-group">
                                <label for="cgpa">Cumulative GPA (CGPA) <small>Scale: 0.00 – 10.00</small></label>
                                <input type="number" id="cgpa" name="cgpa" class="form-control"
                                       step="0.01" min="0.00" max="10.00"
                                       value="<%= profile.getCgpa() != null ? String.format(java.util.Locale.US, "%.2f", profile.getCgpa()) : "" %>"
                                       placeholder="e.g. 8.75">
                                <span class="form-hint">Saved in student_profiles.cgpa</span>
                            </div>

                            <div class="form-group">
                                <label for="graduationYear">Graduation Year <small>Format: YYYY</small></label>
                                <input type="number" id="graduationYear" name="graduationYear" class="form-control"
                                       min="1990" max="2100"
                                       value="<%= profile.getGraduationYear() != null ? profile.getGraduationYear() : "" %>"
                                       placeholder="e.g. 2026">
                                <span class="form-hint">Saved in student_profiles.graduation_year</span>
                            </div>
                        </div>

                        <!-- SECTION 3: PROFESSIONAL LINKS & RESUME -->
                        <h4 style="font-size: 14px; color: #4338ca; text-transform: uppercase; letter-spacing: 0.8px; margin: 26px 0 14px;">
                            3. Professional Portfolio & External Links
                        </h4>

                        <div class="form-grid">
                            <div class="form-group" style="grid-column: 1 / -1;">
                                <label for="resumeUrl">Resume / Portfolio URL</label>
                                <input type="url" id="resumeUrl" name="resumeUrl" class="form-control"
                                       value="<%= profile.getResumeUrl() != null ? profile.getResumeUrl() : "" %>"
                                       maxlength="255" placeholder="https://drive.google.com/file/... or https://portfolio.dev/resume.pdf">
                                <span class="form-hint">Shareable public link to your CV or portfolio document (max 255 chars)</span>
                            </div>

                            <div class="form-group">
                                <label for="linkedinUrl">LinkedIn Profile URL</label>
                                <input type="url" id="linkedinUrl" name="linkedinUrl" class="form-control"
                                       value="<%= profile.getLinkedinUrl() != null ? profile.getLinkedinUrl() : "" %>"
                                       maxlength="255" placeholder="https://linkedin.com/in/username">
                                <span class="form-hint">Public LinkedIn profile for recruiter vetting</span>
                            </div>

                            <div class="form-group">
                                <label for="githubUrl">GitHub Profile URL</label>
                                <input type="url" id="githubUrl" name="githubUrl" class="form-control"
                                       value="<%= profile.getGithubUrl() != null ? profile.getGithubUrl() : "" %>"
                                       maxlength="255" placeholder="https://github.com/username">
                                <span class="form-hint">Public coding repository and project portfolio</span>
                            </div>
                        </div>

                        <!-- ACTION BUTTONS -->
                        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 14px;">
                            <div style="display: flex; gap: 12px; align-items: center;">
                                <button type="submit" class="btn-submit" id="saveProfileBtn">
                                    <span>💾</span> Save Profile Changes
                                </button>
                                <a href="profile.jsp" class="btn-cancel">Discard Changes</a>
                            </div>

                            <a href="dashboard.jsp" style="color: #64748b; font-size: 13px; text-decoration: none; font-weight: 500;">
                                ← Return to Dashboard
                            </a>
                        </div>
                    </form>
                </div>

                <!-- Account Security Info Card -->
                <div class="profile-card">
                    <div class="profile-card-header">
                        <h3><span>🛡️</span> Security & Data Protection</h3>
                        <span style="color: #10b981; font-size: 12px; font-weight: 600;">✓ Active Session Protected</span>
                    </div>

                    <div style="background: #f8fafc; padding: 18px; border-radius: 10px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                        <div>
                            <strong style="color: #1e1b4b; font-size: 14px; display: block;">Account Password</strong>
                            <span style="color: #64748b; font-size: 13px;">•••••••••••• (Encrypted with SHA-256 and salt; never exposed)</span>
                        </div>
                        <span style="color: #10b981; font-size: 13px; font-weight: 600;">✓ Protected & Salted</span>
                    </div>

                    <p style="margin-top: 14px; color: #64748b; font-size: 12px; line-height: 1.6;">
                        Your profile records are securely isolated and mapped to your database identifier (User #<%= currentUser.getUserId() %>) in <code>careerlaunch_db.student_profiles</code>. Other students or external parties cannot modify your records.
                    </p>
                </div>

            </div>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project</span>
                <span>Protected by Server-Side Session Tracking</span>
            </footer>

        </main>
    </div>

    <!-- Client-side validation & AJAX enhancement -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.getElementById('profileForm');
            const submitBtn = document.getElementById('saveProfileBtn');

            form.addEventListener('submit', function(e) {
                // Client-side quick checks
                const fullName = document.getElementById('fullName').value.trim();
                if (!fullName) {
                    alert('Please enter your full name.');
                    e.preventDefault();
                    return;
                }

                const cgpaInput = document.getElementById('cgpa').value.trim();
                if (cgpaInput) {
                    const cgpa = parseFloat(cgpaInput);
                    if (isNaN(cgpa) || cgpa < 0 || cgpa > 10) {
                        alert('CGPA must be a valid decimal number between 0.00 and 10.00.');
                        e.preventDefault();
                        return;
                    }
                }

                const yearInput = document.getElementById('graduationYear').value.trim();
                if (yearInput) {
                    const year = parseInt(yearInput, 10);
                    if (isNaN(year) || year < 1990 || year > 2100) {
                        alert('Graduation year must be between 1990 and 2100.');
                        e.preventDefault();
                        return;
                    }
                }

                // Show spinner/saving state
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span>⏳</span> Saving Changes...';
            });
        });
    </script>

</body>
</html>

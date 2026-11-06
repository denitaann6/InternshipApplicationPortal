<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User"%>
<%@ page import="com.internshipportal.model.Application"%>
<%@ page import="com.internshipportal.service.ApplicationService"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%
    // Prevent browser caching of protected admin page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Server-side authentication and admin authorization check
    User currentUser = (User) session.getAttribute("currentUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.html?error=unauthorized");
        return;
    }
    if (!currentUser.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/dashboard.jsp?error=access_denied");
        return;
    }

    String fullName = currentUser.getFullName();
    String initial = (fullName != null && !fullName.trim().isEmpty())
            ? fullName.trim().substring(0, 1).toUpperCase()
            : "A";

    ApplicationService applicationService = ApplicationService.getInstance();
    List<Application> allApplications = null;
    String dbError = null;

    try {
        allApplications = applicationService.getAllApplications();
    } catch (Exception e) {
        // Safe logging without exposing internal details to the client
        e.printStackTrace();
        dbError = "Unable to retrieve application records from the database. Please try again later.";
    }

    if (allApplications == null) {
        allApplications = new ArrayList<Application>();
    }

    // Metric counters
    int totalCount = allApplications.size();
    int pendingCount = 0;
    int underReviewCount = 0;
    int shortlistedCount = 0;
    int acceptedCount = 0;
    int rejectedCount = 0;

    for (Application app : allApplications) {
        String st = app.getStatus() != null ? app.getStatus().toUpperCase() : "";
        if ("PENDING".equals(st)) {
            pendingCount++;
        } else if ("UNDER_REVIEW".equals(st)) {
            underReviewCount++;
        } else if ("SHORTLISTED".equals(st)) {
            shortlistedCount++;
        } else if ("ACCEPTED".equals(st)) {
            acceptedCount++;
        } else if ("REJECTED".equals(st)) {
            rejectedCount++;
        }
    }

    // Optional query parameter status filter
    String filterParam = request.getParameter("status");
    if (filterParam != null) {
        filterParam = filterParam.trim().toUpperCase();
        if (filterParam.isEmpty() || "ALL".equals(filterParam)) {
            filterParam = null;
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>
<%!
    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }

    private String getStatusBadgeClass(String status) {
        if (status == null) return "status-default";
        switch (status.toUpperCase()) {
            case "PENDING": return "status-pending";
            case "UNDER_REVIEW": return "status-review";
            case "SHORTLISTED": return "status-shortlisted";
            case "ACCEPTED": return "status-accepted";
            case "REJECTED": return "status-rejected";
            default: return "status-default";
        }
    }

    private String formatStatusLabel(String status) {
        if (status == null) return "Unknown";
        switch (status.toUpperCase()) {
            case "PENDING": return "Pending";
            case "UNDER_REVIEW": return "Under Review";
            case "SHORTLISTED": return "Shortlisted";
            case "ACCEPTED": return "Accepted";
            case "REJECTED": return "Not Selected";
            default: return status;
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Application Review & Management | CareerLaunch Admin</title>
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
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin: 20px 0 26px 0;
        }
        .stat-card {
            background: white;
            border-radius: 14px;
            padding: 18px 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.03);
            border: 1px solid #e2e8f0;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 14px rgba(0,0,0,0.06);
        }
        .stat-card.active {
            border-color: #4f46e5;
            box-shadow: 0 0 0 2px rgba(79, 70, 229, 0.2);
        }
        .stat-card .label {
            color: #64748b;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stat-card .value {
            font-size: 26px;
            font-weight: 700;
            margin-top: 6px;
        }
        .controls-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 14px;
            background: white;
            padding: 14px 20px;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            margin-bottom: 20px;
        }
        .filter-group {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .filter-btn {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s;
        }
        .filter-btn:hover {
            background: #e2e8f0;
            color: #0f172a;
        }
        .filter-btn.active {
            background: #4f46e5;
            color: white;
            border-color: #4f46e5;
        }
        .search-box {
            position: relative;
            min-width: 260px;
        }
        .search-input {
            width: 100%;
            padding: 8px 14px 8px 34px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            transition: border-color 0.2s;
        }
        .search-input:focus {
            border-color: #4f46e5;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
        }
        .search-icon {
            position: absolute;
            left: 11px;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
            font-size: 13px;
        }
        .table-container {
            background: white;
            border-radius: 14px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.03);
            border: 1px solid #e2e8f0;
            overflow: hidden;
        }
        .apps-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13.5px;
        }
        .apps-table th {
            text-align: left;
            padding: 14px 18px;
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 11.5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #e2e8f0;
        }
        .apps-table td {
            padding: 16px 18px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e1b4b;
            vertical-align: middle;
        }
        .apps-table tr:hover {
            background: #fafbfd;
        }
        .app-id-pill {
            display: inline-block;
            background: #f1f5f9;
            color: #475569;
            padding: 3px 8px;
            border-radius: 6px;
            font-family: monospace;
            font-weight: 700;
            font-size: 12px;
        }
        .student-meta {
            font-size: 12px;
            color: #64748b;
            margin-top: 2px;
        }
        .internship-meta {
            font-size: 12px;
            color: #64748b;
            margin-top: 2px;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: capitalize;
            white-space: nowrap;
        }
        .status-pending {
            background: #f3e8ff;
            color: #6b21a8;
        }
        .status-review {
            background: #dbeafe;
            color: #1e40af;
        }
        .status-shortlisted {
            background: #dcfce7;
            color: #166534;
        }
        .status-accepted {
            background: #bbf7d0;
            color: #14532d;
        }
        .status-rejected {
            background: #fee2e2;
            color: #991b1b;
        }
        .status-default {
            background: #f1f5f9;
            color: #475569;
        }
        .btn-review {
            background: #4f46e5;
            color: white;
            border: none;
            padding: 7px 14px;
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-review:hover {
            background: #4338ca;
            transform: translateY(-1px);
        }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 14px;
            border: 1px solid #e2e8f0;
        }
        .empty-icon {
            font-size: 48px;
            color: #cbd5e1;
            margin-bottom: 12px;
        }
        .alert-box {
            padding: 14px 18px;
            border-radius: 8px;
            font-size: 13.5px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-error {
            background: #fef2f2;
            color: #991b1b;
            border-left: 4px solid #dc2626;
        }
        .alert-success {
            background: #f0fdf4;
            color: #166534;
            border-left: 4px solid #16a34a;
        }
        /* Modal Styles */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.65);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
            backdrop-filter: blur(2px);
        }
        .modal-box {
            background: white;
            border-radius: 16px;
            max-width: 680px;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            position: relative;
            box-shadow: 0 20px 40px rgba(0,0,0,0.25);
            animation: modalFadeIn 0.25s ease;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: translateY(12px) scale(0.98); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }
        .modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #f8fafc;
            border-radius: 16px 16px 0 0;
        }
        .modal-title {
            font-size: 17px;
            font-weight: 700;
            color: #0f172a;
        }
        .modal-close-btn {
            background: none;
            border: none;
            font-size: 24px;
            color: #94a3b8;
            cursor: pointer;
            line-height: 1;
            padding: 4px;
            border-radius: 6px;
        }
        .modal-close-btn:hover {
            color: #0f172a;
            background: #e2e8f0;
        }
        .modal-body {
            padding: 24px;
        }
        .modal-section-title {
            font-size: 12px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
            background: #f8fafc;
            padding: 16px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            margin-bottom: 20px;
        }
        .info-item .item-label {
            font-size: 11.5px;
            color: #64748b;
            font-weight: 600;
        }
        .info-item .item-value {
            font-size: 13.5px;
            font-weight: 600;
            color: #1e1b4b;
            margin-top: 2px;
        }
        .cover-letter-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 16px;
            font-size: 13.5px;
            line-height: 1.6;
            color: #334155;
            white-space: pre-wrap;
            max-height: 220px;
            overflow-y: auto;
            margin-bottom: 22px;
        }
        .status-update-card {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            border-radius: 10px;
            padding: 18px;
        }
        .form-group {
            margin-bottom: 14px;
        }
        .form-label {
            display: block;
            font-size: 12.5px;
            font-weight: 600;
            color: #1e1b4b;
            margin-bottom: 6px;
        }
        .form-select, .form-textarea {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13.5px;
            background: white;
            outline: none;
            transition: border-color 0.2s;
        }
        .form-select:focus, .form-textarea:focus {
            border-color: #16a34a;
            box-shadow: 0 0 0 3px rgba(22, 163, 74, 0.15);
        }
        .modal-footer {
            padding: 16px 24px;
            border-top: 1px solid #e2e8f0;
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            background: #f8fafc;
            border-radius: 0 0 16px 16px;
        }
        .btn-cancel {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            padding: 9px 18px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
        }
        .btn-cancel:hover {
            background: #e2e8f0;
        }
        .btn-submit {
            background: #16a34a;
            color: white;
            border: none;
            padding: 9px 20px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
        }
        .btn-submit:hover {
            background: #15803d;
        }
        .btn-submit:disabled {
            background: #94a3b8;
            cursor: not-allowed;
        }
        /* Toast notification */
        .toast-msg {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background: #0f172a;
            color: white;
            padding: 14px 20px;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 600;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            z-index: 2000;
            display: none;
            align-items: center;
            gap: 10px;
            animation: toastSlideUp 0.3s ease;
        }
        @keyframes toastSlideUp {
            from { transform: translateY(20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
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
                <a href="admin-applications.jsp" class="menu-item active">
                    <span>▤</span> Application Review
                </a>
                <a href="admin-students.jsp" class="menu-item">
                    <span>👥</span> Student Directory
                </a>
                <a href="admin-audit.jsp" class="menu-item">
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
                    <span class="breadcrumb"><a href="admin-dashboard.jsp" style="text-decoration: none; color: inherit;">Control Panel</a> /</span>
                    <strong>Application Review & Status Management</strong>
                </div>

                <div class="topbar-profile">
                    <div class="profile-avatar" style="background: linear-gradient(135deg, #dc2626, #b91c1c);"><%= initial %></div>
                    <div>
                        <strong><%= escapeHtml(fullName) %></strong>
                        <span class="admin-badge">Administrator</span>
                    </div>
                </div>
            </header>

            <!-- FEEDBACK MESSAGES FROM QUERY PARAMETERS -->
            <% if (request.getParameter("msg") != null && !request.getParameter("msg").trim().isEmpty()) { %>
                <div class="alert-box alert-success" style="margin-top: 20px;">
                    <span>✓</span>
                    <div><%= escapeHtml(request.getParameter("msg")) %></div>
                </div>
            <% } %>

            <% if (request.getParameter("error") != null && !request.getParameter("error").trim().isEmpty()) { %>
                <div class="alert-box alert-error" style="margin-top: 20px;">
                    <span>⚠</span>
                    <div><%= escapeHtml(request.getParameter("error")) %></div>
                </div>
            <% } %>

            <% if (dbError != null) { %>
                <div class="alert-box alert-error" style="margin-top: 20px;">
                    <span>⚠</span>
                    <div><%= escapeHtml(dbError) %></div>
                </div>
            <% } %>

            <!-- HEADER -->
            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <h2>Student Application Submissions</h2>
                    <p>Review candidate profiles, statement of interest/cover letters, and update statuses with transactional database audit logging.</p>
                </div>
            </section>

            <!-- METRIC STATS CARDS -->
            <div class="stats-grid">
                <div class="stat-card <%= filterParam == null ? "active" : "" %>" onclick="filterByStatus('all')">
                    <div class="label">Total Received</div>
                    <div class="value" style="color: #4f46e5;"><%= totalCount %></div>
                </div>
                <div class="stat-card <%= "PENDING".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('PENDING')">
                    <div class="label">Pending</div>
                    <div class="value" style="color: #9333ea;"><%= pendingCount %></div>
                </div>
                <div class="stat-card <%= "UNDER_REVIEW".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('UNDER_REVIEW')">
                    <div class="label">Under Review</div>
                    <div class="value" style="color: #2563eb;"><%= underReviewCount %></div>
                </div>
                <div class="stat-card <%= "SHORTLISTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('SHORTLISTED')">
                    <div class="label">Shortlisted</div>
                    <div class="value" style="color: #16a34a;"><%= shortlistedCount %></div>
                </div>
                <div class="stat-card <%= "ACCEPTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('ACCEPTED')">
                    <div class="label">Accepted</div>
                    <div class="value" style="color: #059669;"><%= acceptedCount %></div>
                </div>
                <div class="stat-card <%= "REJECTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('REJECTED')">
                    <div class="label">Not Selected</div>
                    <div class="value" style="color: #dc2626;"><%= rejectedCount %></div>
                </div>
            </div>

            <!-- CONTROLS & FILTER BAR -->
            <div class="controls-bar">
                <div class="filter-group">
                    <span style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; margin-right: 4px;">Status:</span>
                    <button type="button" class="filter-btn <%= filterParam == null ? "active" : "" %>" onclick="filterByStatus('all')">All (<%= totalCount %>)</button>
                    <button type="button" class="filter-btn <%= "PENDING".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('PENDING')">Pending (<%= pendingCount %>)</button>
                    <button type="button" class="filter-btn <%= "UNDER_REVIEW".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('UNDER_REVIEW')">Under Review (<%= underReviewCount %>)</button>
                    <button type="button" class="filter-btn <%= "SHORTLISTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('SHORTLISTED')">Shortlisted (<%= shortlistedCount %>)</button>
                    <button type="button" class="filter-btn <%= "ACCEPTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('ACCEPTED')">Accepted (<%= acceptedCount %>)</button>
                    <button type="button" class="filter-btn <%= "REJECTED".equals(filterParam) ? "active" : "" %>" onclick="filterByStatus('REJECTED')">Not Selected (<%= rejectedCount %>)</button>
                </div>

                <div class="search-box">
                    <span class="search-icon">🔍</span>
                    <input type="text" id="liveSearchInput" class="search-input" placeholder="Search student, position, email..." onkeyup="handleLiveSearch()">
                </div>
            </div>

            <!-- APPLICATIONS TABLE OR EMPTY STATE -->
            <% if (allApplications.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-icon">📭</div>
                    <h3 style="color: #1e1b4b; margin-bottom: 8px;">No Applications Submitted Yet</h3>
                    <p style="color: #64748b; font-size: 14px; max-width: 480px; margin: 0 auto;">
                        When registered students apply for internships on CareerLaunch, their applications, candidate profiles, and statements of interest will appear here for review.
                    </p>
                </div>
            <% } else { %>
                <div class="table-container">
                    <table class="apps-table" id="applicationsTable">
                        <thead>
                            <tr>
                                <th>App ID</th>
                                <th>Applicant Details</th>
                                <th>Position & Company</th>
                                <th>Applied Date</th>
                                <th>Status</th>
                                <th style="text-align: right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                for (Application app : allApplications) {
                                    String appStatus = app.getStatus() != null ? app.getStatus().toUpperCase() : "PENDING";
                                    boolean matchesInitialFilter = (filterParam == null || filterParam.equalsIgnoreCase(appStatus));
                                    String formattedDate = app.getAppliedAt() != null ? dateFormat.format(app.getAppliedAt()) : "N/A";
                                    String badgeClass = getStatusBadgeClass(appStatus);
                                    String statusLabel = formatStatusLabel(appStatus);

                                    String studentName = app.getStudentName() != null ? app.getStudentName() : "Student #" + app.getStudentId();
                                    String studentEmail = app.getStudentEmail() != null ? app.getStudentEmail() : "N/A";
                                    String studentCourse = app.getStudentCourse() != null && !app.getStudentCourse().trim().isEmpty() ? app.getStudentCourse() : "N/A";
                                    String studentPhone = app.getStudentPhone() != null && !app.getStudentPhone().trim().isEmpty() ? app.getStudentPhone() : "N/A";

                                    String internshipTitle = app.getInternshipTitle() != null ? app.getInternshipTitle() : "Internship #" + app.getInternshipId();
                                    String company = app.getCompany() != null ? app.getCompany() : "N/A";
                                    String location = app.getLocation() != null ? app.getLocation() : "Remote / Hybrid";
                                    String category = app.getCategory() != null ? app.getCategory() : "Technology";
                                    String coverLetter = app.getCoverLetter() != null ? app.getCoverLetter() : "";
                            %>
                                <tr class="app-row"
                                    id="row-app-<%= app.getApplicationId() %>"
                                    data-status="<%= appStatus %>"
                                    data-search="<%= escapeHtml((studentName + " " + studentEmail + " " + internshipTitle + " " + company + " " + app.getApplicationId()).toLowerCase()) %>"
                                    style="<%= matchesInitialFilter ? "" : "display: none;" %>">
                                    <td>
                                        <span class="app-id-pill">#APP-<%= app.getApplicationId() %></span>
                                    </td>
                                    <td>
                                        <div style="font-weight: 700; color: #0f172a;"><%= escapeHtml(studentName) %></div>
                                        <div class="student-meta">✉ <%= escapeHtml(studentEmail) %></div>
                                        <% if (!"N/A".equals(studentCourse)) { %>
                                            <div class="student-meta" style="font-size: 11.5px; color: #475569;">🎓 <%= escapeHtml(studentCourse) %></div>
                                        <% } %>
                                    </td>
                                    <td>
                                        <div style="font-weight: 600; color: #1e1b4b;"><%= escapeHtml(internshipTitle) %></div>
                                        <div class="internship-meta">🏢 <%= escapeHtml(company) %> &bull; 📍 <%= escapeHtml(location) %></div>
                                    </td>
                                    <td style="color: #475569; font-size: 12.5px; white-space: nowrap;">
                                        <%= formattedDate %>
                                    </td>
                                    <td>
                                        <span class="status-badge <%= badgeClass %>" id="badge-<%= app.getApplicationId() %>">
                                            <%= statusLabel %>
                                        </span>
                                    </td>
                                    <td style="text-align: right;">
                                        <button type="button"
                                                class="btn-review"
                                                onclick="openReviewModal({
                                                    id: <%= app.getApplicationId() %>,
                                                    studentName: '<%= escapeHtml(studentName).replace("'", "\\'") %>',
                                                    studentEmail: '<%= escapeHtml(studentEmail).replace("'", "\\'") %>',
                                                    studentCourse: '<%= escapeHtml(studentCourse).replace("'", "\\'") %>',
                                                    studentPhone: '<%= escapeHtml(studentPhone).replace("'", "\\'") %>',
                                                    title: '<%= escapeHtml(internshipTitle).replace("'", "\\'") %>',
                                                    company: '<%= escapeHtml(company).replace("'", "\\'") %>',
                                                    location: '<%= escapeHtml(location).replace("'", "\\'") %>',
                                                    category: '<%= escapeHtml(category).replace("'", "\\'") %>',
                                                    status: '<%= appStatus %>',
                                                    appliedDate: '<%= formattedDate %>',
                                                    coverLetter: '<%= escapeHtml(coverLetter).replace("'", "\\'").replace("\n", "\\n").replace("\r", "") %>'
                                                })">
                                            <span>👁</span> Review &amp; Decide
                                        </button>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>

                    <div id="noResultsNotice" style="display: none; padding: 40px 20px; text-align: center; color: #64748b;">
                        <div style="font-size: 32px; margin-bottom: 8px;">🔍</div>
                        <p style="font-weight: 600; font-size: 14px;">No applications found matching the selected status or search query.</p>
                    </div>
                </div>
            <% } %>

        </main>
    </div>

    <!-- REVIEW & STATUS MANAGEMENT MODAL -->
    <div id="reviewModal" class="modal-overlay" onclick="handleBackdropClick(event)">
        <div class="modal-box" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
            <div class="modal-header">
                <div>
                    <div class="modal-title" id="modalTitle">Application Review</div>
                    <span id="modalAppIdTag" class="app-id-pill" style="margin-top: 4px;">#APP-0</span>
                </div>
                <button type="button" class="modal-close-btn" onclick="closeReviewModal()" aria-label="Close modal">&times;</button>
            </div>

            <div class="modal-body">
                <!-- APPLICANT PROFILE SUMMARY -->
                <div class="modal-section-title">Candidate &amp; Internship Overview</div>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="item-label">Student Name</div>
                        <div class="item-value" id="modalStudentName">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Student Email</div>
                        <div class="item-value" id="modalStudentEmail">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Course / Degree</div>
                        <div class="item-value" id="modalStudentCourse">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Contact Phone</div>
                        <div class="item-value" id="modalStudentPhone">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Internship Position</div>
                        <div class="item-value" id="modalInternshipTitle">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Company &amp; Location</div>
                        <div class="item-value" id="modalCompanyLocation">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Applied Date</div>
                        <div class="item-value" id="modalAppliedDate">-</div>
                    </div>
                    <div class="info-item">
                        <div class="item-label">Current Status</div>
                        <div class="item-value" id="modalCurrentStatus">-</div>
                    </div>
                </div>

                <!-- COVER LETTER -->
                <div class="modal-section-title">Candidate's Statement of Interest / Cover Letter</div>
                <div class="cover-letter-box" id="modalCoverLetter">
                    <!-- Populated dynamically -->
                </div>

                <!-- STATUS CHANGE FORM -->
                <form id="statusUpdateForm" onsubmit="handleStatusSubmit(event)">
                    <input type="hidden" id="formApplicationId" name="applicationId" value="">
                    
                    <div class="status-update-card">
                        <div style="font-weight: 700; color: #166534; font-size: 13.5px; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                            <span>⚖</span> Update Decision Status
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="formStatusSelect">Select Application Status *</label>
                            <select id="formStatusSelect" name="status" class="form-select" required>
                                <option value="PENDING">PENDING – Awaiting Review</option>
                                <option value="UNDER_REVIEW">UNDER_REVIEW – Application Under Active Review</option>
                                <option value="SHORTLISTED">SHORTLISTED – Selected for Interview / Next Stage</option>
                                <option value="ACCEPTED">ACCEPTED – Offer Extended / Accepted</option>
                                <option value="REJECTED">REJECTED – Not Selected</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="formNotes">Admin Review Notes / Rationale (Optional)</label>
                            <textarea id="formNotes" name="notes" class="form-textarea" rows="2" placeholder="e.g. Profile reviewed; strong technical background, invited for technical round."></textarea>
                        </div>
                    </div>

                    <div id="modalFormError" class="alert-box alert-error" style="display: none; margin-top: 14px;"></div>
                    <div id="modalFormSuccess" class="alert-box alert-success" style="display: none; margin-top: 14px;"></div>

                    <div class="modal-footer" style="padding-left: 0; padding-right: 0; padding-bottom: 0; background: transparent; border-top: none; margin-top: 18px;">
                        <button type="button" class="btn-cancel" onclick="closeReviewModal()">Close</button>
                        <button type="submit" class="btn-submit" id="btnSubmitStatus">
                            <span>✓</span> Save Status Update
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- TOAST NOTIFICATION -->
    <div id="toastMessage" class="toast-msg">
        <span id="toastIcon">✓</span>
        <span id="toastText">Status updated successfully</span>
    </div>

    <script>
        var currentFilter = '<%= filterParam != null ? filterParam : "all" %>';
        var currentAppObj = null;

        function filterByStatus(status) {
            currentFilter = status;
            var buttons = document.querySelectorAll('.filter-btn');
            buttons.forEach(function(btn) {
                var btnStatus = btn.textContent.toUpperCase();
                if (status === 'all' && btn.textContent.indexOf('All') === 0) {
                    btn.classList.add('active');
                } else if (status !== 'all' && btnStatus.indexOf(status) === 0) {
                    btn.classList.add('active');
                } else {
                    btn.classList.remove('active');
                }
            });

            var statCards = document.querySelectorAll('.stat-card');
            statCards.forEach(function(card) {
                card.classList.remove('active');
            });

            applyFilters();
        }

        function handleLiveSearch() {
            applyFilters();
        }

        function applyFilters() {
            var searchVal = (document.getElementById('liveSearchInput') ? document.getElementById('liveSearchInput').value : '').toLowerCase().trim();
            var rows = document.querySelectorAll('.app-row');
            var visibleCount = 0;

            rows.forEach(function(row) {
                var rowStatus = row.getAttribute('data-status') || '';
                var rowSearch = row.getAttribute('data-search') || '';

                var matchesStatus = (currentFilter === 'all' || rowStatus.toUpperCase() === currentFilter.toUpperCase());
                var matchesSearch = (!searchVal || rowSearch.indexOf(searchVal) !== -1);

                if (matchesStatus && matchesSearch) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });

            var noResultsNotice = document.getElementById('noResultsNotice');
            if (noResultsNotice) {
                if (visibleCount === 0 && rows.length > 0) {
                    noResultsNotice.style.display = 'block';
                } else {
                    noResultsNotice.style.display = 'none';
                }
            }
        }

        function openReviewModal(app) {
            currentAppObj = app;
            document.getElementById('modalAppIdTag').textContent = '#APP-' + app.id;
            document.getElementById('formApplicationId').value = app.id;
            document.getElementById('modalStudentName').textContent = app.studentName;
            document.getElementById('modalStudentEmail').textContent = app.studentEmail;
            document.getElementById('modalStudentCourse').textContent = app.studentCourse || 'N/A';
            document.getElementById('modalStudentPhone').textContent = app.studentPhone || 'N/A';
            document.getElementById('modalInternshipTitle').textContent = app.title;
            document.getElementById('modalCompanyLocation').textContent = app.company + ' (' + app.location + ')';
            document.getElementById('modalAppliedDate').textContent = app.appliedDate;

            // Render current status badge
            var statusLabel = formatStatusText(app.status);
            var badgeClass = getBadgeCssClass(app.status);
            document.getElementById('modalCurrentStatus').innerHTML = '<span class="status-badge ' + badgeClass + '">' + statusLabel + '</span>';

            // Cover letter text
            var coverEl = document.getElementById('modalCoverLetter');
            if (app.coverLetter && app.coverLetter.trim().length > 0) {
                coverEl.textContent = app.coverLetter;
            } else {
                coverEl.textContent = 'No statement of interest or cover letter was attached with this application.';
            }

            // Set dropdown value
            var statusSelect = document.getElementById('formStatusSelect');
            if (statusSelect) {
                statusSelect.value = app.status;
            }

            document.getElementById('formNotes').value = '';
            document.getElementById('modalFormError').style.display = 'none';
            document.getElementById('modalFormSuccess').style.display = 'none';

            document.getElementById('reviewModal').style.display = 'flex';
        }

        function closeReviewModal() {
            document.getElementById('reviewModal').style.display = 'none';
            currentAppObj = null;
        }

        function handleBackdropClick(event) {
            if (event.target === document.getElementById('reviewModal')) {
                closeReviewModal();
            }
        }

        function formatStatusText(status) {
            if (!status) return 'Unknown';
            switch (status.toUpperCase()) {
                case 'PENDING': return 'Pending';
                case 'UNDER_REVIEW': return 'Under Review';
                case 'SHORTLISTED': return 'Shortlisted';
                case 'ACCEPTED': return 'Accepted';
                case 'REJECTED': return 'Not Selected';
                default: return status;
            }
        }

        function getBadgeCssClass(status) {
            if (!status) return 'status-default';
            switch (status.toUpperCase()) {
                case 'PENDING': return 'status-pending';
                case 'UNDER_REVIEW': return 'status-review';
                case 'SHORTLISTED': return 'status-shortlisted';
                case 'ACCEPTED': return 'status-accepted';
                case 'REJECTED': return 'status-rejected';
                default: return 'status-default';
            }
        }

        function showToast(message, isError) {
            var toast = document.getElementById('toastMessage');
            var icon = document.getElementById('toastIcon');
            var text = document.getElementById('toastText');

            if (!toast) return;

            icon.textContent = isError ? '⚠' : '✓';
            toast.style.background = isError ? '#991b1b' : '#0f172a';
            text.textContent = message;

            toast.style.display = 'flex';
            setTimeout(function() {
                toast.style.display = 'none';
            }, 3500);
        }

        function handleStatusSubmit(event) {
            event.preventDefault();

            var appId = document.getElementById('formApplicationId').value;
            var newStatus = document.getElementById('formStatusSelect').value;
            var notes = document.getElementById('formNotes').value;

            var errorEl = document.getElementById('modalFormError');
            var successEl = document.getElementById('modalFormSuccess');
            var submitBtn = document.getElementById('btnSubmitStatus');

            errorEl.style.display = 'none';
            successEl.style.display = 'none';

            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span>⏳</span> Saving...';

            var formData = new URLSearchParams();
            formData.append('applicationId', appId);
            formData.append('status', newStatus);
            formData.append('notes', notes);

            fetch('<%= request.getContextPath() %>/AdminApplicationServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData.toString()
            })
            .then(function(res) {
                return res.json().then(function(data) {
                    return { ok: res.ok, status: res.status, data: data };
                });
            })
            .then(function(result) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<span>✓</span> Save Status Update';

                if (result.ok && result.data.success) {
                    // Update table row dynamically
                    var row = document.getElementById('row-app-' + appId);
                    var badge = document.getElementById('badge-' + appId);
                    if (row && badge) {
                        row.setAttribute('data-status', newStatus);
                        badge.className = 'status-badge ' + getBadgeCssClass(newStatus);
                        badge.textContent = formatStatusText(newStatus);
                    }

                    if (currentAppObj) {
                        currentAppObj.status = newStatus;
                        document.getElementById('modalCurrentStatus').innerHTML =
                            '<span class="status-badge ' + getBadgeCssClass(newStatus) + '">' + formatStatusText(newStatus) + '</span>';
                    }

                    var msg = result.data.message || 'Status successfully updated.';
                    successEl.textContent = msg;
                    successEl.style.display = 'flex';

                    showToast(msg, false);

                    // Re-apply filters to ensure table view stays synchronized
                    setTimeout(function() {
                        applyFilters();
                        closeReviewModal();
                        // Reload page shortly to update counter badges accurately
                        window.location.reload();
                    }, 1200);

                } else {
                    var errorMsg = (result.data && result.data.message) ? result.data.message : 'Failed to update application status.';
                    errorEl.textContent = errorMsg;
                    errorEl.style.display = 'flex';
                    showToast(errorMsg, true);
                }
            })
            .catch(function(err) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<span>✓</span> Save Status Update';
                var fallbackMsg = 'Network or server error occurred. Please try again.';
                errorEl.textContent = fallbackMsg;
                errorEl.style.display = 'flex';
                showToast(fallbackMsg, true);
            });
        }
    </script>
</body>
</html>

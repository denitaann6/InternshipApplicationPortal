<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User, com.internshipportal.model.Internship, com.internshipportal.service.InternshipService, com.internshipportal.service.ApplicationService, java.util.List, java.util.ArrayList, java.util.Set, java.util.Collections" %>
<%!
    // Safe HTML output escaping to prevent XSS
    private String escapeHtml(Object input) {
        if (input == null) return "";
        String s = input.toString();
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }

    // JSON/JavaScript string escaping
    private String escapeJs(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", "")
                    .replace("\n", "\\n");
    }
%>
<%
    // Prevent browser caching of dynamic internship listings
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User currentUser = (User) session.getAttribute("currentUser");
    boolean isLoggedIn = (currentUser != null);
    String fullName = isLoggedIn ? (currentUser.getFullName() != null && !currentUser.getFullName().isEmpty()
            ? currentUser.getFullName() : currentUser.getUsername()) : "Guest";
    String initial = isLoggedIn ? fullName.trim().substring(0, 1).toUpperCase() : "G";

    // Query active internships from MySQL database via InternshipService
    List<Internship> internships = null;
    boolean dbError = false;
    try {
        internships = InternshipService.getInstance().getActiveInternships();
    } catch (Exception e) {
        System.err.println("[internships.jsp] Database query failed: " + e.getMessage());
        dbError = true;
    }
    if (internships == null) {
        internships = new ArrayList<>();
    }

    // Query set of already-applied internship IDs for the current student
    Set<Integer> appliedIds = Collections.emptySet();
    if (isLoggedIn && currentUser != null) {
        try {
            appliedIds = ApplicationService.getInstance().getAppliedInternshipIds(currentUser.getUserId());
        } catch (Exception e) {
            System.err.println("[internships.jsp] Error loading applied internship IDs: " + e.getMessage());
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Internship Explorer | CareerLaunch</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .filter-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin: 20px 0;
            align-items: center;
        }
        .filter-btn {
            padding: 8px 16px;
            border-radius: 20px;
            border: 1px solid #cbd5e1;
            background: white;
            color: #475569;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .filter-btn.active, .filter-btn:hover {
            background: #4f46e5;
            color: white;
            border-color: #4f46e5;
        }
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 23, 42, 0.7);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-box {
            background: white;
            border-radius: 16px;
            max-width: 650px;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            padding: 30px;
            position: relative;
            box-shadow: 0 20px 40px rgba(0,0,0,0.2);
        }
        .modal-close {
            position: absolute;
            top: 20px;
            right: 20px;
            font-size: 24px;
            cursor: pointer;
            border: none;
            background: none;
            color: #64748b;
        }
        .demo-badge {
            display: inline-block;
            background: #e0e7ff;
            color: #3730a3;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 12px;
        }
        .feedback-banner {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 14px 18px;
            border-radius: 10px;
            margin: 16px 0;
            font-size: 14px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        .banner-success {
            background: #ecfdf5;
            border: 1px solid #a7f3d0;
            color: #065f46;
        }
        .banner-warning {
            background: #fffbeb;
            border: 1px solid #fde68a;
            color: #92400e;
        }
        .banner-error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
        }
        .banner-icon {
            font-size: 18px;
            font-weight: 700;
            line-height: 1;
        }
        .banner-close {
            margin-left: auto;
            background: none;
            border: none;
            font-size: 18px;
            cursor: pointer;
            color: inherit;
            opacity: 0.7;
        }
        .toast-container {
            position: fixed;
            top: 24px;
            right: 24px;
            z-index: 2000;
            display: flex;
            flex-direction: column;
            gap: 10px;
            max-width: 420px;
            pointer-events: none;
        }
        .toast-msg {
            padding: 12px 18px;
            border-radius: 10px;
            color: white;
            font-size: 13px;
            font-weight: 500;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            display: flex;
            align-items: center;
            gap: 10px;
            pointer-events: auto;
            animation: toastIn 0.25s ease;
        }
        .toast-success { background: #059669; }
        .toast-warning { background: #d97706; }
        .toast-error { background: #dc2626; }
        @keyframes toastIn {
            from { opacity: 0; transform: translateY(-12px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body class="dashboard-body">

    <!-- Floating Toast Notification Container -->
    <div id="toastContainer" class="toast-container"></div>

    <!-- Hidden Fallback Form for Standard POST Submissions -->
    <form id="fallbackApplyForm" method="POST" action="<%= request.getContextPath() %>/ApplicationServlet" style="display:none;">
        <input type="hidden" name="internshipId" id="fallbackInternshipId" value="">
        <input type="hidden" name="coverLetter" id="fallbackCoverLetter" value="">
    </form>

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
                <a href="internships.jsp" class="menu-item active">
                    <span>⌕</span> Find Internships
                </a>
                <a href="applications.jsp" class="menu-item">
                    <span>▤</span> My Applications
                </a>
                <a href="profile.jsp" class="menu-item">
                    <span>♙</span> My Profile
                </a>
                <a href="about.jsp" class="menu-item">
                    <span>ⓘ</span> About Portal
                </a>
                <a href="contact.jsp" class="menu-item">
                    <span>✉</span> Contact &amp; Support
                </a>
                <a href="help.jsp" class="menu-item">
                    <span>?</span> Help &amp; FAQ
                </a>
            </nav>

            <div class="sidebar-bottom">
                <% if (isLoggedIn) { %>
                    <a href="<%= request.getContextPath() %>/LogoutServlet"
                       class="menu-item logout-link"
                       onclick="return confirm('Are you sure you want to log out?');">
                        <span>↪</span> Logout
                    </a>
                <% } else { %>
                    <a href="login.html" class="menu-item">
                        <span>→</span> Sign In
                    </a>
                <% } %>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main class="dashboard-main">

            <header class="dashboard-topbar">
                <div class="topbar-title">
                    <span class="breadcrumb">Workspace /</span>
                    <strong>Internship Explorer</strong>
                </div>

                <div class="topbar-actions">
                    <% if (isLoggedIn) { %>
                        <div class="topbar-profile">
                            <div class="profile-avatar"><%= initial %></div>
                            <div>
                                <strong><%= escapeHtml(fullName) %></strong>
                                <small><%= currentUser.getCourse() != null ? escapeHtml(currentUser.getCourse()) : "Student" %></small>
                            </div>
                        </div>
                    <% } else { %>
                        <a href="login.html" class="primary-button" style="padding: 6px 14px; font-size: 13px; text-decoration: none;">
                            Sign In
                        </a>
                    <% } %>
                </div>
            </header>

            <!-- SERVER-SIDE FEEDBACK BANNERS (ON REDIRECT) -->
            <%
                String appliedStatus = request.getParameter("applied");
                String msgParam = request.getParameter("msg");
                if ("success".equals(appliedStatus)) {
            %>
                <div class="feedback-banner banner-success">
                    <span class="banner-icon">✓</span>
                    <div>
                        <strong>Application Submitted Successfully!</strong>
                        <div>Your application has been recorded in the database with status <strong>PENDING</strong>. Track it under <a href="applications.jsp" style="color: inherit; text-decoration: underline; font-weight: 600;">My Applications</a>.</div>
                    </div>
                    <button type="button" class="banner-close" onclick="this.parentElement.remove()">×</button>
                </div>
            <% } else if ("duplicate".equals(appliedStatus)) { %>
                <div class="feedback-banner banner-warning">
                    <span class="banner-icon">ℹ</span>
                    <div>
                        <strong>Already Applied:</strong>
                        <div>You have already submitted an application for this internship position.</div>
                    </div>
                    <button type="button" class="banner-close" onclick="this.parentElement.remove()">×</button>
                </div>
            <% } else if ("error".equals(appliedStatus)) { %>
                <div class="feedback-banner banner-error">
                    <span class="banner-icon">✕</span>
                    <div>
                        <strong>Submission Issue:</strong>
                        <div><%= msgParam != null ? escapeHtml(msgParam) : "Unable to process application. Please check your selection and try again." %></div>
                    </div>
                    <button type="button" class="banner-close" onclick="this.parentElement.remove()">×</button>
                </div>
            <% } %>

            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <span class="demo-badge">Verified Portal Listings</span>
                    <h2>Explore Active Internship Roles</h2>
                    <p>Live industry opportunities retrieved directly from MySQL database for MCA, BCA, and Computer Science students.</p>
                </div>
            </section>

            <!-- SEARCH AND FILTER CONTROLS -->
            <div style="background: white; border-radius: 14px; padding: 20px; margin: 20px 0; box-shadow: 0 4px 15px rgba(0,0,0,0.03);">
                <label class="dashboard-search" style="max-width: 100%;">
                    <span>⌕</span>
                    <input type="search"
                           id="pageSearchInput"
                           placeholder="Search by role title, company, skills (e.g. Java, Python, React)..."
                           oninput="filterInternships()">
                </label>

                <!-- Category Filters -->
                <div class="filter-bar">
                    <span style="font-size: 13px; font-weight: 700; color: #1e1b4b; margin-right: 6px;">Category:</span>
                    <button class="filter-btn active" onclick="setCategory('All', this)">All</button>
                    <button class="filter-btn" onclick="setCategory('Java', this)">Java</button>
                    <button class="filter-btn" onclick="setCategory('Web', this)">Web Dev</button>
                    <button class="filter-btn" onclick="setCategory('Data', this)">Data Analytics</button>
                    <button class="filter-btn" onclick="setCategory('Cloud', this)">Cloud &amp; DevOps</button>
                    <button class="filter-btn" onclick="setCategory('Security', this)">Cyber Security</button>
                    <button class="filter-btn" onclick="setCategory('AI', this)">AI &amp; ML</button>
                </div>

                <!-- Mode Filters -->
                <div class="filter-bar" style="margin-top: 0;">
                    <span style="font-size: 13px; font-weight: 700; color: #1e1b4b; margin-right: 6px;">Work Mode:</span>
                    <button class="filter-btn active" onclick="setMode('All', this)">All Modes</button>
                    <button class="filter-btn" onclick="setMode('Remote', this)">Remote</button>
                    <button class="filter-btn" onclick="setMode('Hybrid', this)">Hybrid</button>
                    <button class="filter-btn" onclick="setMode('On-site', this)">On-site</button>
                </div>
            </div>

            <!-- INTERNSHIP CARDS GRID -->
            <div class="internship-grid" id="internshipList">
                <% if (dbError) { %>
                    <div style="grid-column: 1 / -1; background: #fee2e2; border: 1px solid #fca5a5; color: #991b1b; padding: 24px; border-radius: 12px; text-align: center;">
                        <h4 style="margin: 0 0 8px 0; font-size: 16px;">Unable to load internships</h4>
                        <p style="margin: 0; font-size: 14px;">A temporary database issue occurred. Please refresh the page or try again in a few moments.</p>
                    </div>
                <% } else if (internships.isEmpty()) { %>
                    <div style="grid-column: 1 / -1; background: #f8fafc; border: 1px solid #e2e8f0; color: #475569; padding: 36px 20px; border-radius: 14px; text-align: center;">
                        <div style="font-size: 32px; margin-bottom: 10px;">📋</div>
                        <h4 style="margin: 0 0 8px 0; font-size: 17px; color: #1e1b4b;">No Active Internships Found</h4>
                        <p style="margin: 0; font-size: 14px; color: #64748b;">There are currently no active internship listings posted in the portal. Please check back later.</p>
                    </div>
                <% } else {
                    for (Internship job : internships) {
                        boolean isApplied = appliedIds.contains(job.getId());
                        String logoClass = "Remote".equalsIgnoreCase(job.getWorkMode()) ? "logo-purple" :
                                           "Hybrid".equalsIgnoreCase(job.getWorkMode()) ? "logo-blue" : "logo-orange";
                        StringBuilder skillsJoin = new StringBuilder();
                        for (String s : job.getSkills()) {
                            skillsJoin.append(s).append(" ");
                        }
                        String companyInitial = (job.getCompany() != null && !job.getCompany().trim().isEmpty())
                                ? job.getCompany().trim().substring(0, 1).toUpperCase() : "C";
                %>
                <article class="internship-card"
                         data-category="<%= escapeHtml(job.getCategory()) %>"
                         data-mode="<%= escapeHtml(job.getWorkMode()) %>"
                         data-search="<%= escapeHtml(job.getTitle().toLowerCase() + " " + job.getCompany().toLowerCase() + " " + skillsJoin.toString().toLowerCase()) %>">

                    <div class="internship-card-top">
                        <div class="company-logo <%= logoClass %>"><%= companyInitial %></div>
                        <span class="job-type"><%= escapeHtml(job.getWorkMode()) %></span>
                    </div>

                    <h3><%= escapeHtml(job.getTitle()) %></h3>
                    <p class="company-name"><%= escapeHtml(job.getCompany()) %></p>

                    <div class="job-details">
                        <span>⌖ <%= escapeHtml(job.getLocation()) %></span>
                        <span>◷ <%= escapeHtml(job.getDuration()) %></span>
                    </div>

                    <div style="font-size: 13px; color: #4338ca; font-weight: 700; margin: 8px 0;">
                        <%= escapeHtml(job.getStipend()) %>
                    </div>

                    <div class="job-tags">
                        <% for (String skill : job.getSkills()) { %>
                            <span><%= escapeHtml(skill) %></span>
                        <% } %>
                    </div>

                    <div style="display: flex; gap: 8px; margin-top: 15px;">
                        <button type="button"
                                class="primary-button"
                                style="padding: 8px 12px; font-size: 13px;"
                                onclick="openModal(<%= job.getId() %>)">
                            View Details
                        </button>
                        <% if (isApplied) { %>
                            <button type="button"
                                    class="secondary-button"
                                    id="applyBtn-<%= job.getId() %>"
                                    style="padding: 8px 12px; font-size: 13px; background: #f1f5f9; color: #64748b; border: 1px solid #cbd5e1; cursor: default;"
                                    disabled>
                                ✓ Applied
                            </button>
                        <% } else { %>
                            <button type="button"
                                    class="secondary-button"
                                    id="applyBtn-<%= job.getId() %>"
                                    style="padding: 8px 12px; font-size: 13px;"
                                    onclick="submitApplication(<%= job.getId() %>, '<%= escapeJs(job.getTitle()) %>', '<%= escapeJs(job.getCompany()) %>')">
                                Apply Now
                            </button>
                        <% } %>
                    </div>
                </article>
                <%  }
                   } %>
            </div>

            <p id="noMatchesNotice" style="display: none; padding: 40px; text-align: center; color: #64748b; font-size: 16px;">
                No internships found matching your filter criteria. Try clearing some filters.
            </p>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project</span>
                <span>Active Listings from Database (<code>careerlaunch_db.internships</code>)</span>
            </footer>

        </main>
    </div>

    <!-- DETAILS MODAL -->
    <div class="modal-overlay" id="detailsModal">
        <div class="modal-box">
            <button class="modal-close" onclick="closeModal()">×</button>
            <span class="demo-badge" id="modalCategory">Category</span>
            <h2 id="modalTitle" style="font-size: 22px; color: #1e1b4b; margin: 6px 0;">Role Title</h2>
            <p id="modalCompany" style="color: #4f46e5; font-weight: 600; font-size: 15px; margin-bottom: 12px;">Company</p>

            <div style="display: flex; gap: 16px; margin: 12px 0; color: #475569; font-size: 13px;">
                <span id="modalLocation">⌖ Location</span>
                <span id="modalDuration">◷ Duration</span>
                <span id="modalStipend" style="color: #059669; font-weight: 700;">₹ Stipend</span>
            </div>

            <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 16px 0;">

            <h4 style="font-size: 15px; color: #1e1b4b; margin-bottom: 8px;">Role Description</h4>
            <p id="modalDescription" style="color: #475569; font-size: 14px; line-height: 1.6; margin-bottom: 16px;">
                Description
            </p>

            <h4 style="font-size: 15px; color: #1e1b4b; margin-bottom: 8px;">Key Responsibilities</h4>
            <ul id="modalResponsibilities" style="color: #475569; font-size: 14px; line-height: 1.6; padding-left: 20px; margin-bottom: 24px;">
            </ul>

            <!-- Optional Statement of Interest / Cover Letter -->
            <div id="modalCoverLetterGroup" style="margin-bottom: 20px;">
                <label for="modalCoverLetter" style="display: block; font-size: 13px; font-weight: 600; color: #1e1b4b; margin-bottom: 6px;">
                    Statement of Interest / Cover Letter <span style="font-weight: 400; color: #64748b;">(Optional)</span>
                </label>
                <textarea id="modalCoverLetter" rows="3"
                          style="width: 100%; border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px; font-family: inherit; font-size: 13px; box-sizing: border-box; resize: vertical;"
                          placeholder="Briefly state your relevant skills, projects, or why you are excited about this role..."></textarea>
            </div>

            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button type="button" class="secondary-button" onclick="closeModal()">Close</button>
                <button type="button" class="primary-button" id="modalApplyBtn">Submit Application</button>
            </div>
        </div>
    </div>

    <!-- JavaScript Data and Filtering -->
    <script>
        const jobsData = [
            <%
                for (int i = 0; i < internships.size(); i++) {
                    Internship j = internships.get(i);
                    boolean jApplied = appliedIds.contains(j.getId());
            %>
            {
                id: <%= j.getId() %>,
                title: "<%= escapeJs(j.getTitle()) %>",
                company: "<%= escapeJs(j.getCompany()) %>",
                location: "<%= escapeJs(j.getLocation()) %>",
                workMode: "<%= escapeJs(j.getWorkMode()) %>",
                duration: "<%= escapeJs(j.getDuration()) %>",
                stipend: "<%= escapeJs(j.getStipend()) %>",
                category: "<%= escapeJs(j.getCategory()) %>",
                description: "<%= escapeJs(j.getDescription()) %>",
                applied: <%= jApplied %>,
                responsibilities: [
                    <% for (int r = 0; r < j.getResponsibilities().size(); r++) { %>
                        "<%= escapeJs(j.getResponsibilities().get(r)) %>"<%= (r < j.getResponsibilities().size() - 1 ? "," : "") %>
                    <% } %>
                ]
            }<%= (i < internships.size() - 1 ? "," : "") %>
            <% } %>
        ];

        let selectedCategory = "All";
        let selectedMode = "All";

        function setCategory(cat, btn) {
            selectedCategory = cat;
            btn.parentElement.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            filterInternships();
        }

        function setMode(mode, btn) {
            selectedMode = mode;
            btn.parentElement.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            filterInternships();
        }

        function filterInternships() {
            const query = (document.getElementById("pageSearchInput").value || "").toLowerCase().trim();
            const cards = document.querySelectorAll("#internshipList .internship-card");
            let visibleCount = 0;

            cards.forEach(card => {
                const cardCat = (card.dataset.category || "").toLowerCase();
                const cardMode = (card.dataset.mode || "").toLowerCase();
                const cardSearch = (card.dataset.search || "").toLowerCase();

                let matchCat = false;
                if (selectedCategory === "All") {
                    matchCat = true;
                } else if (selectedCategory === "AI") {
                    matchCat = cardCat.includes("ai") || cardCat.includes("artificial");
                } else {
                    matchCat = cardCat.includes(selectedCategory.toLowerCase());
                }

                const matchMode = (selectedMode === "All" || cardMode === selectedMode.toLowerCase());
                const matchSearch = (!query || cardSearch.includes(query));

                if (matchCat && matchMode && matchSearch) {
                    card.style.display = "";
                    visibleCount++;
                } else {
                    card.style.display = "none";
                }
            });

            document.getElementById("noMatchesNotice").style.display = visibleCount === 0 ? "block" : "none";
        }

        function openModal(jobId) {
            const job = jobsData.find(j => j.id === jobId);
            if (!job) return;

            document.getElementById("modalCategory").textContent = job.category + " · " + job.workMode;
            document.getElementById("modalTitle").textContent = job.title;
            document.getElementById("modalCompany").textContent = job.company;
            document.getElementById("modalLocation").textContent = "⌖ " + job.location;
            document.getElementById("modalDuration").textContent = "◷ " + job.duration;
            document.getElementById("modalStipend").textContent = job.stipend;
            document.getElementById("modalDescription").textContent = job.description;

            const respList = document.getElementById("modalResponsibilities");
            respList.innerHTML = "";
            job.responsibilities.forEach(r => {
                const li = document.createElement("li");
                li.textContent = r;
                respList.appendChild(li);
            });

            const coverLetterGroup = document.getElementById("modalCoverLetterGroup");
            const coverLetterInput = document.getElementById("modalCoverLetter");
            const modalApplyBtn = document.getElementById("modalApplyBtn");

            if (job.applied) {
                coverLetterGroup.style.display = "none";
                modalApplyBtn.textContent = "✓ Already Applied";
                modalApplyBtn.disabled = true;
                modalApplyBtn.style.background = "#f1f5f9";
                modalApplyBtn.style.color = "#64748b";
                modalApplyBtn.style.border = "1px solid #cbd5e1";
                modalApplyBtn.style.cursor = "default";
                modalApplyBtn.onclick = null;
            } else {
                coverLetterGroup.style.display = "block";
                coverLetterInput.value = "";
                modalApplyBtn.textContent = "Submit Application";
                modalApplyBtn.disabled = false;
                modalApplyBtn.style.background = "";
                modalApplyBtn.style.color = "";
                modalApplyBtn.style.border = "";
                modalApplyBtn.style.cursor = "pointer";
                modalApplyBtn.onclick = function() {
                    submitApplication(job.id, job.title, job.company, coverLetterInput.value);
                };
            }

            document.getElementById("detailsModal").style.display = "flex";
        }

        function closeModal() {
            document.getElementById("detailsModal").style.display = "none";
        }

        function submitApplication(jobId, role, company, coverLetter) {
            <% if (!isLoggedIn) { %>
                window.location.href = "<%= request.getContextPath() %>/login.html?error=" + encodeURIComponent("Please log in to apply for internships.");
                return;
            <% } %>

            const cardBtn = document.getElementById("applyBtn-" + jobId);
            const modalBtn = document.getElementById("modalApplyBtn");

            const originalCardText = cardBtn ? cardBtn.textContent : "Apply Now";
            if (cardBtn) {
                cardBtn.disabled = true;
                cardBtn.textContent = "Submitting...";
            }
            if (modalBtn) {
                modalBtn.disabled = true;
                modalBtn.textContent = "Submitting...";
            }

            const formData = new URLSearchParams();
            formData.append("internshipId", jobId);
            if (coverLetter && coverLetter.trim()) {
                formData.append("coverLetter", coverLetter.trim());
            }

            fetch("<%= request.getContextPath() %>/ApplicationServlet", {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                    "X-Requested-With": "XMLHttpRequest"
                },
                body: formData.toString()
            })
            .then(response => {
                if (response.redirected) {
                    window.location.href = response.url;
                    return null;
                }
                return response.json().then(data => ({ status: response.status, data: data }));
            })
            .then(result => {
                if (!result) return;
                const data = result.data;

                if (data.success) {
                    showToast("success", data.message || ("Application submitted successfully for " + role + " at " + company + "!"));
                    markAsApplied(jobId);
                    closeModal();
                } else if (data.duplicate) {
                    showToast("warning", data.message || "You have already applied for this internship.");
                    markAsApplied(jobId);
                    closeModal();
                } else {
                    showToast("error", data.message || "Failed to submit application. Please try again.");
                    if (cardBtn) {
                        cardBtn.disabled = false;
                        cardBtn.textContent = originalCardText;
                    }
                    if (modalBtn) {
                        modalBtn.disabled = false;
                        modalBtn.textContent = "Submit Application";
                    }
                }
            })
            .catch(err => {
                showToast("error", "Network or server error while submitting application.");
                if (cardBtn) {
                    cardBtn.disabled = false;
                    cardBtn.textContent = originalCardText;
                }
                if (modalBtn) {
                    modalBtn.disabled = false;
                    modalBtn.textContent = "Submit Application";
                }
            });
        }

        function markAsApplied(jobId) {
            const job = jobsData.find(j => j.id === jobId);
            if (job) {
                job.applied = true;
            }
            const btn = document.getElementById("applyBtn-" + jobId);
            if (btn) {
                btn.disabled = true;
                btn.textContent = "✓ Applied";
                btn.style.background = "#f1f5f9";
                btn.style.color = "#64748b";
                btn.style.borderColor = "#cbd5e1";
                btn.style.cursor = "default";
                btn.onclick = null;
            }
        }

        function applyDirectly(jobIdOrRole, companyOrTitle) {
            if (typeof jobIdOrRole === "number") {
                const job = jobsData.find(j => j.id === jobIdOrRole);
                if (job) {
                    submitApplication(job.id, job.title, job.company, "");
                    return;
                }
            }
            const matchedJob = jobsData.find(j => j.title === jobIdOrRole);
            if (matchedJob) {
                submitApplication(matchedJob.id, matchedJob.title, matchedJob.company, "");
            } else {
                <% if (!isLoggedIn) { %>
                    window.location.href = "<%= request.getContextPath() %>/login.html?error=" + encodeURIComponent("Please log in to apply for internships.");
                <% } %>
            }
        }

        function showToast(type, message) {
            const container = document.getElementById("toastContainer");
            if (!container) return;
            const toast = document.createElement("div");
            toast.className = "toast-msg toast-" + type;
            const icon = type === "success" ? "✓" : (type === "warning" ? "ℹ" : "✕");
            toast.innerHTML = "<span>" + icon + "</span><span>" + escapeHtmlJs(message) + "</span>";
            container.appendChild(toast);
            setTimeout(() => {
                if (toast.parentElement) {
                    toast.remove();
                }
            }, 4500);
        }

        function escapeHtmlJs(str) {
            if (!str) return "";
            return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }
    </script>
</body>
</html>

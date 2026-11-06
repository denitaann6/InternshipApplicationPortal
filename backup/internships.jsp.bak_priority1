<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.internshipportal.model.User, com.internshipportal.model.Internship, java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("currentUser");
    boolean isLoggedIn = (currentUser != null);
    String fullName = isLoggedIn ? (currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername()) : "Guest";
    String initial = isLoggedIn ? fullName.trim().substring(0, 1).toUpperCase() : "G";
    List<Internship> internships = Internship.getSampleInternships();
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
            background: #fef3c7;
            color: #92400e;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 12px;
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
                    <span>✉</span> Contact & Support
                </a>
                <a href="help.jsp" class="menu-item">
                    <span>?</span> Help & FAQ
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
                                <strong><%= fullName %></strong>
                                <small><%= currentUser.getCourse() != null ? currentUser.getCourse() : "Student" %></small>
                            </div>
                        </div>
                    <% } else { %>
                        <a href="login.html" class="primary-button" style="padding: 6px 14px; font-size: 13px; text-decoration: none;">
                            Sign In
                        </a>
                    <% } %>
                </div>
            </header>

            <section class="section-heading" style="margin-top: 20px;">
                <div>
                    <span class="demo-badge">Curated Demonstration Opportunities</span>
                    <h2>Explore Verified Internship Roles</h2>
                    <p>Find industry opportunities tailored for MCA, BCA, and Computer Science students.</p>
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
                    <button class="filter-btn" onclick="setCategory('Cloud', this)">Cloud & DevOps</button>
                    <button class="filter-btn" onclick="setCategory('Security', this)">Cyber Security</button>
                    <button class="filter-btn" onclick="setCategory('AI', this)">AI & ML</button>
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
                <%
                    for (Internship job : internships) {
                        String logoClass = "Remote".equalsIgnoreCase(job.getWorkMode()) ? "logo-purple" :
                                           "Hybrid".equalsIgnoreCase(job.getWorkMode()) ? "logo-blue" : "logo-orange";
                        StringBuilder skillsJoin = new StringBuilder();
                        for (String s : job.getSkills()) {
                            skillsJoin.append(s).append(" ");
                        }
                %>
                <article class="internship-card"
                         data-category="<%= job.getCategory() %>"
                         data-mode="<%= job.getWorkMode() %>"
                         data-search="<%= job.getTitle().toLowerCase() %> <%= job.getCompany().toLowerCase() %> <%= skillsJoin.toString().toLowerCase() %>">

                    <div class="internship-card-top">
                        <div class="company-logo <%= logoClass %>"><%= job.getCompany().substring(0, 1) %></div>
                        <span class="job-type"><%= job.getWorkMode() %></span>
                    </div>

                    <h3><%= job.getTitle() %></h3>
                    <p class="company-name"><%= job.getCompany() %></p>

                    <div class="job-details">
                        <span>⌖ <%= job.getLocation() %></span>
                        <span>◷ <%= job.getDuration() %></span>
                    </div>

                    <div style="font-size: 13px; color: #4338ca; font-weight: 700; margin: 8px 0;">
                        <%= job.getStipend() %>
                    </div>

                    <div class="job-tags">
                        <% for (String skill : job.getSkills()) { %>
                            <span><%= skill %></span>
                        <% } %>
                    </div>

                    <div style="display: flex; gap: 8px; margin-top: 15px;">
                        <button type="button"
                                class="primary-button"
                                style="padding: 8px 12px; font-size: 13px;"
                                onclick="openModal(<%= job.getId() %>)">
                            View Details
                        </button>
                        <button type="button"
                                class="secondary-button"
                                style="padding: 8px 12px; font-size: 13px;"
                                onclick="applyDirectly('<%= job.getTitle() %>', '<%= job.getCompany() %>')">
                            Apply Now
                        </button>
                    </div>
                </article>
                <% } %>
            </div>

            <p id="noMatchesNotice" style="display: none; padding: 40px; text-align: center; color: #64748b; font-size: 16px;">
                No internships found matching your filter criteria. Try clearing some filters.
            </p>

            <footer class="dashboard-footer" style="margin-top: 40px;">
                <span>© 2026 CareerLaunch · MCA Practical Project</span>
                <span>Curated Sample Internship Data</span>
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
            %>
            {
                id: <%= j.getId() %>,
                title: "<%= j.getTitle().replace("\"", "\\\"") %>",
                company: "<%= j.getCompany().replace("\"", "\\\"") %>",
                location: "<%= j.getLocation() %>",
                workMode: "<%= j.getWorkMode() %>",
                duration: "<%= j.getDuration() %>",
                stipend: "<%= j.getStipend() %>",
                category: "<%= j.getCategory() %>",
                description: "<%= j.getDescription().replace("\"", "\\\"") %>",
                responsibilities: [
                    <% for (int r = 0; r < j.getResponsibilities().size(); r++) { %>
                        "<%= j.getResponsibilities().get(r).replace("\"", "\\\"") %>"<%= (r < j.getResponsibilities().size() - 1 ? "," : "") %>
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
                const cardCat = card.dataset.category;
                const cardMode = card.dataset.mode;
                const cardSearch = card.dataset.search;

                const matchCat = (selectedCategory === "All" || cardCat === selectedCategory);
                const matchMode = (selectedMode === "All" || cardMode === selectedMode);
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

            document.getElementById("modalApplyBtn").onclick = function() {
                applyDirectly(job.title, job.company);
                closeModal();
            };

            document.getElementById("detailsModal").style.display = "flex";
        }

        function closeModal() {
            document.getElementById("detailsModal").style.display = "none";
        }

        function applyDirectly(role, company) {
            <% if (!isLoggedIn) { %>
                alert("Please log in to apply for internships.");
                window.location.href = "login.html";
                return;
            <% } else { %>
                alert("Application submitted successfully for '" + role + "' at " + company + "!\nView your active status under 'My Applications'.");
                window.location.href = "applications.jsp";
            <% } %>
        }
    </script>
</body>
</html>

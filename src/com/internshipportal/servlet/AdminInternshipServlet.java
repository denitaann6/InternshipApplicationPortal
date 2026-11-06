package com.internshipportal.servlet;

import com.internshipportal.model.Internship;
import com.internshipportal.model.User;
import com.internshipportal.service.InternshipService;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * AdminInternshipServlet - Handles administrator operations for internship lifecycle management.
 * Supports creating new opportunities, editing existing postings, and toggling active/inactive status.
 *
 * Enforces strict server-side authentication, admin authorization, and prepared statements.
 */
public class AdminInternshipServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final Set<String> ALLOWED_WORK_MODES = new HashSet<>(Arrays.asList("Remote", "Hybrid", "On-site"));
    private static final Set<String> ALLOWED_STATUSES = new HashSet<>(Arrays.asList("ACTIVE", "INACTIVE"));

    private final InternshipService internshipService;

    public AdminInternshipServlet() {
        this.internshipService = InternshipService.getInstance();
    }

    /**
     * Handles HTTP GET requests.
     * If an 'id' parameter is provided via AJAX, returns the internship JSON data for modal population.
     * Otherwise redirects to admin-internships.jsp.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);
        boolean isAjax = isAjaxRequest(request);

        HttpSession session = request.getSession(false);
        User currentUser = getAuthenticatedAdmin(session);

        if (currentUser == null) {
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"message\":\"Please log in as an administrator.\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.html?error="
                        + URLEncoder.encode("Please log in as an administrator.", StandardCharsets.UTF_8.name()));
            }
            return;
        }

        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.trim().isEmpty()) {
            try {
                int id = Integer.parseInt(idParam.trim());
                Internship intern = internshipService.getInternshipById(id);
                if (intern != null) {
                    StringBuilder json = new StringBuilder();
                    json.append("{")
                        .append("\"success\":true,")
                        .append("\"id\":").append(intern.getId()).append(",")
                        .append("\"title\":\"").append(escapeJson(intern.getTitle())).append("\",")
                        .append("\"company\":\"").append(escapeJson(intern.getCompany())).append("\",")
                        .append("\"location\":\"").append(escapeJson(intern.getLocation())).append("\",")
                        .append("\"workMode\":\"").append(escapeJson(intern.getWorkMode())).append("\",")
                        .append("\"duration\":\"").append(escapeJson(intern.getDuration())).append("\",")
                        .append("\"stipend\":\"").append(escapeJson(intern.getStipend())).append("\",")
                        .append("\"category\":\"").append(escapeJson(intern.getCategory())).append("\",")
                        .append("\"skills\":\"").append(escapeJson(intern.getSkillsString())).append("\",")
                        .append("\"description\":\"").append(escapeJson(intern.getDescription())).append("\",")
                        .append("\"responsibilities\":\"").append(escapeJson(intern.getResponsibilitiesString())).append("\",")
                        .append("\"status\":\"").append(escapeJson(intern.getStatus())).append("\"")
                        .append("}");
                    sendJsonResponse(response, HttpServletResponse.SC_OK, json.toString());
                    return;
                } else {
                    sendJsonResponse(response, HttpServletResponse.SC_NOT_FOUND,
                            "{\"success\":false,\"message\":\"Internship not found.\"}");
                    return;
                }
            } catch (NumberFormatException e) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"Invalid internship ID.\"}");
                return;
            }
        }

        response.sendRedirect(request.getContextPath() + "/admin-internships.jsp");
    }

    /**
     * Handles HTTP POST requests for creating, editing, and toggling internship status.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);
        request.setCharacterEncoding("UTF-8");

        boolean isAjax = isAjaxRequest(request);

        // 1. Enforce server-side session authentication
        HttpSession session = request.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("currentUser") : null;
        if (currentUser == null && session != null) {
            currentUser = (User) session.getAttribute("user");
        }

        if (currentUser == null) {
            String errorMsg = "Please log in as an administrator to perform this action.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"error\":\"unauthorized\",\"message\":\"" + escapeJson(errorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.html?error="
                        + URLEncoder.encode(errorMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 2. Enforce administrator role authorization
        if (!currentUser.isAdmin()) {
            String forbiddenMsg = "Access denied. Administrator privileges are required.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_FORBIDDEN,
                        "{\"success\":false,\"error\":\"forbidden\",\"message\":\"" + escapeJson(forbiddenMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard.jsp?error="
                        + URLEncoder.encode(forbiddenMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 3. Obtain acting administrator ID strictly from authenticated session
        int adminUserId = currentUser.getUserId();

        // 4. Determine action
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "create"; // Default action
        }
        action = action.trim().toLowerCase();

        try {
            switch (action) {
                case "create":
                case "add":
                    handleCreate(request, response, isAjax, adminUserId);
                    break;

                case "update":
                case "edit":
                    handleUpdate(request, response, isAjax);
                    break;

                case "toggle_status":
                case "status":
                case "activate":
                case "deactivate":
                    handleToggleStatus(request, response, isAjax);
                    break;

                default:
                    handleFailure(response, isAjax, HttpServletResponse.SC_BAD_REQUEST, "Unknown action: " + action);
                    break;
            }
        } catch (IllegalArgumentException e) {
            handleFailure(response, isAjax, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            System.err.println("[AdminInternshipServlet] Database error: " + e.getMessage());
            handleFailure(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "A database error occurred while processing the internship request. Please try again.");
        } catch (Exception e) {
            System.err.println("[AdminInternshipServlet] Unexpected error: " + e.getMessage());
            handleFailure(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "An unexpected error occurred. Please try again.");
        }
    }

    /**
     * Handles creating a new internship.
     */
    private void handleCreate(HttpServletRequest request, HttpServletResponse response, boolean isAjax, int adminUserId)
            throws SQLException, IOException {

        Internship internship = extractAndValidateInternship(request, false);

        int generatedId = internshipService.createInternship(internship, adminUserId);
        if (generatedId > 0) {
            String msg = "Internship '" + internship.getTitle() + "' successfully created.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"message\":\"" + escapeJson(msg) + "\",\"internshipId\":" + generatedId + "}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-internships.jsp?msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
        } else {
            handleFailure(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Failed to save the internship listing to the database.");
        }
    }

    /**
     * Handles updating an existing internship.
     */
    private void handleUpdate(HttpServletRequest request, HttpServletResponse response, boolean isAjax)
            throws SQLException, IOException {

        Internship internship = extractAndValidateInternship(request, true);

        // Verify record exists before updating
        Internship existing = internshipService.getInternshipById(internship.getId());
        if (existing == null) {
            handleFailure(response, isAjax, HttpServletResponse.SC_NOT_FOUND,
                    "Internship with ID #" + internship.getId() + " was not found.");
            return;
        }

        boolean updated = internshipService.updateInternship(internship);
        if (updated) {
            String msg = "Internship #" + internship.getId() + " ('" + internship.getTitle() + "') updated successfully.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"message\":\"" + escapeJson(msg) + "\",\"internshipId\":" + internship.getId() + "}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-internships.jsp?msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
        } else {
            handleFailure(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Failed to update internship record in the database.");
        }
    }

    /**
     * Handles activating or deactivating an internship.
     */
    private void handleToggleStatus(HttpServletRequest request, HttpServletResponse response, boolean isAjax)
            throws SQLException, IOException {

        String idParam = request.getParameter("internshipId");
        if (idParam == null || idParam.trim().isEmpty()) {
            idParam = request.getParameter("id");
        }

        int internshipId = parsePositiveInt(idParam, "Invalid internship ID.");

        // Check if internship exists
        Internship existing = internshipService.getInternshipById(internshipId);
        if (existing == null) {
            handleFailure(response, isAjax, HttpServletResponse.SC_NOT_FOUND,
                    "Internship with ID #" + internshipId + " was not found.");
            return;
        }

        String newStatus = request.getParameter("status");
        if (newStatus == null || newStatus.trim().isEmpty()) {
            // If status parameter is omitted, toggle to the opposite status
            newStatus = existing.isActive() ? "INACTIVE" : "ACTIVE";
        } else {
            newStatus = newStatus.trim().toUpperCase();
        }

        if (!ALLOWED_STATUSES.contains(newStatus)) {
            handleFailure(response, isAjax, HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid status '" + newStatus + "'. Allowed: " + ALLOWED_STATUSES);
            return;
        }

        boolean updated = internshipService.setInternshipStatus(internshipId, newStatus);
        if (updated) {
            String label = "ACTIVE".equalsIgnoreCase(newStatus) ? "activated" : "deactivated";
            String msg = "Internship #" + internshipId + " ('" + existing.getTitle() + "') successfully " + label + ".";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"message\":\"" + escapeJson(msg) + "\",\"newStatus\":\"" + newStatus + "\",\"internshipId\":" + internshipId + "}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-internships.jsp?msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
        } else {
            handleFailure(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Failed to change status of internship #" + internshipId + ".");
        }
    }

    /**
     * Validates and extracts form parameters into an Internship object.
     */
    private Internship extractAndValidateInternship(HttpServletRequest request, boolean isUpdate) {
        int id = 0;
        if (isUpdate) {
            String idParam = request.getParameter("internshipId");
            if (idParam == null || idParam.trim().isEmpty()) {
                idParam = request.getParameter("id");
            }
            id = parsePositiveInt(idParam, "A valid internship ID is required for editing.");
        }

        String title = request.getParameter("title");
        if (title == null || title.trim().isEmpty()) {
            throw new IllegalArgumentException("Internship title is required.");
        }
        title = title.trim();
        if (title.length() > 150) {
            throw new IllegalArgumentException("Title must not exceed 150 characters.");
        }

        String company = request.getParameter("company");
        if (company == null || company.trim().isEmpty()) {
            throw new IllegalArgumentException("Company name is required.");
        }
        company = company.trim();
        if (company.length() > 150) {
            throw new IllegalArgumentException("Company name must not exceed 150 characters.");
        }

        String location = request.getParameter("location");
        if (location != null) {
            location = location.trim();
            if (location.length() > 100) {
                throw new IllegalArgumentException("Location must not exceed 100 characters.");
            }
        }

        String workMode = request.getParameter("workMode");
        if (workMode == null || workMode.trim().isEmpty()) {
            workMode = "Remote";
        } else {
            workMode = workMode.trim();
            if (!ALLOWED_WORK_MODES.contains(workMode)) {
                throw new IllegalArgumentException("Work mode must be one of: " + ALLOWED_WORK_MODES);
            }
        }

        String duration = request.getParameter("duration");
        if (duration != null) {
            duration = duration.trim();
            if (duration.length() > 50) {
                throw new IllegalArgumentException("Duration must not exceed 50 characters.");
            }
        }

        String stipend = request.getParameter("stipend");
        if (stipend != null) {
            stipend = stipend.trim();
            if (stipend.length() > 50) {
                throw new IllegalArgumentException("Stipend must not exceed 50 characters.");
            }
        }

        String category = request.getParameter("category");
        if (category != null) {
            category = category.trim();
            if (category.length() > 100) {
                throw new IllegalArgumentException("Category must not exceed 100 characters.");
            }
        }

        String skillsStr = request.getParameter("skills");
        List<String> skillsList = new ArrayList<>();
        if (skillsStr != null) {
            skillsStr = skillsStr.trim();
            if (skillsStr.length() > 255) {
                throw new IllegalArgumentException("Skills list must not exceed 255 characters.");
            }
            for (String part : skillsStr.split(",")) {
                String trimmed = part.trim();
                if (!trimmed.isEmpty()) {
                    skillsList.add(trimmed);
                }
            }
        }

        String description = request.getParameter("description");
        if (description != null) {
            description = description.trim();
        }

        String responsibilitiesStr = request.getParameter("responsibilities");
        List<String> responsibilitiesList = new ArrayList<>();
        if (responsibilitiesStr != null && !responsibilitiesStr.trim().isEmpty()) {
            String[] lines = responsibilitiesStr.split("[\r\n]+");
            for (String line : lines) {
                String trimmed = line.trim();
                if (!trimmed.isEmpty()) {
                    responsibilitiesList.add(trimmed);
                }
            }
        }

        String status = request.getParameter("status");
        if (status == null || status.trim().isEmpty()) {
            status = "ACTIVE";
        } else {
            status = status.trim().toUpperCase();
            if (!ALLOWED_STATUSES.contains(status)) {
                throw new IllegalArgumentException("Status must be ACTIVE or INACTIVE.");
            }
        }

        Internship internship = new Internship(
            id,
            title,
            company,
            location != null && !location.isEmpty() ? location : "Remote",
            workMode,
            duration != null && !duration.isEmpty() ? duration : "3 Months",
            stipend != null && !stipend.isEmpty() ? stipend : "Unpaid",
            category != null && !category.isEmpty() ? category : "General",
            skillsList,
            description != null ? description : "",
            responsibilitiesList,
            status
        );

        return internship;
    }

    private int parsePositiveInt(String value, String errorMsg) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMsg);
        }
        try {
            int parsed = Integer.parseInt(value.trim());
            if (parsed <= 0) {
                throw new IllegalArgumentException(errorMsg);
            }
            return parsed;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(errorMsg);
        }
    }

    private User getAuthenticatedAdmin(HttpSession session) {
        if (session == null) return null;
        User user = (User) session.getAttribute("currentUser");
        if (user == null) {
            user = (User) session.getAttribute("user");
        }
        return (user != null && user.isAdmin()) ? user : null;
    }

    private void handleFailure(HttpServletResponse response, boolean isAjax, int statusCode, String message)
            throws IOException {
        if (isAjax) {
            sendJsonResponse(response, statusCode,
                    "{\"success\":false,\"message\":\"" + escapeJson(message) + "\"}");
        } else {
            response.sendRedirect(response.encodeRedirectURL("admin-internships.jsp?error="
                    + URLEncoder.encode(message, StandardCharsets.UTF_8.name())));
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || (accept != null && accept.contains("application/json"));
    }

    private void sendJsonResponse(HttpServletResponse response, int statusCode, String json) throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.write(json);
        out.flush();
    }

    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\r", "")
                    .replace("\n", "\\n");
    }

    private void setNoCacheHeaders(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
    }
}

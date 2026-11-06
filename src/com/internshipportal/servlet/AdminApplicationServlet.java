package com.internshipportal.servlet;

import com.internshipportal.model.User;
import com.internshipportal.service.ApplicationService;
import com.internshipportal.service.ApplicationService.StatusUpdateResult;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * AdminApplicationServlet - Handles administrator review and recruitment status updates.
 *
 * Strictly enforces server-side session authentication and ADMIN role verification,
 * prevents student tampering, validates status against supported recruitment values,
 * and delegates transactional updates to ApplicationService.
 */
@WebServlet(name = "AdminApplicationServlet", urlPatterns = {"/AdminApplicationServlet", "/admin/update-status"})
public class AdminApplicationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private ApplicationService applicationService;

    @Override
    public void init() throws ServletException {
        super.init();
        this.applicationService = ApplicationService.getInstance();
    }

    /**
     * Handles HTTP GET requests.
     * Redirects directly to the admin applications management interface.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin-applications.jsp");
    }

    /**
     * Handles HTTP POST requests.
     * Evaluates and updates student application recruitment statuses.
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

        if (currentUser == null) {
            String errorMsg = "Please log in as an administrator to access this feature.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"error\":\"unauthorized\",\"message\":\"" + escapeJson(errorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.html?error="
                        + URLEncoder.encode(errorMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 2. Enforce administrator role authorization on the server side
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

        // 3. Obtain acting administrator's identity strictly from session
        int adminUserId = currentUser.getUserId();

        // 4. Validate and parse applicationId parameter
        String appIdParam = request.getParameter("applicationId");
        int applicationId = -1;
        try {
            if (appIdParam != null && !appIdParam.trim().isEmpty()) {
                applicationId = Integer.parseInt(appIdParam.trim());
            }
        } catch (NumberFormatException e) {
            applicationId = -1;
        }

        if (applicationId <= 0) {
            String badIdMsg = "Invalid application ID provided.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(badIdMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-applications.jsp?error="
                        + URLEncoder.encode(badIdMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 5. Validate status parameter against supported statuses
        String newStatus = request.getParameter("status");
        if (newStatus == null || newStatus.trim().isEmpty()) {
            String missingStatusMsg = "Application status value is required.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(missingStatusMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-applications.jsp?error="
                        + URLEncoder.encode(missingStatusMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        String normalizedStatus = newStatus.trim().toUpperCase();
        if (!ApplicationService.ALLOWED_STATUSES.contains(normalizedStatus)) {
            String unsupportedMsg = "Unsupported status value: '" + newStatus + "'. Allowed: " + ApplicationService.ALLOWED_STATUSES;
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(unsupportedMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-applications.jsp?error="
                        + URLEncoder.encode(unsupportedMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 6. Extract optional review notes (capped at 500 characters matching VARCHAR(500) column)
        String notes = request.getParameter("notes");
        if (notes != null) {
            notes = notes.trim();
            if (notes.length() > 500) {
                notes = notes.substring(0, 500);
            }
        }

        // 7. Execute transactional status update in ApplicationService
        StatusUpdateResult result = applicationService.updateApplicationStatus(applicationId, normalizedStatus, adminUserId, notes);

        // 8. Render response
        if (isAjax) {
            if (result.isSuccess()) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"message\":\"" + escapeJson(result.getMessage())
                        + "\",\"previousStatus\":\"" + escapeJson(result.getPreviousStatus())
                        + "\",\"newStatus\":\"" + escapeJson(result.getNewStatus()) + "\"}");
            } else if (result.isUnchanged()) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"unchanged\":true,\"message\":\""
                        + escapeJson(result.getMessage()) + "\",\"newStatus\":\""
                        + escapeJson(result.getNewStatus()) + "\"}");
            } else {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(result.getMessage()) + "\"}");
            }
        } else {
            if (result.isSuccess() || result.isUnchanged()) {
                response.sendRedirect(request.getContextPath() + "/admin-applications.jsp?msg="
                        + URLEncoder.encode(result.getMessage(), StandardCharsets.UTF_8.name()));
            } else {
                response.sendRedirect(request.getContextPath() + "/admin-applications.jsp?error="
                        + URLEncoder.encode(result.getMessage(), StandardCharsets.UTF_8.name()));
            }
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

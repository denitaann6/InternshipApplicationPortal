package com.internshipportal.servlet;

import com.internshipportal.model.User;
import com.internshipportal.service.ApplicationService;
import com.internshipportal.service.ApplicationService.ApplicationResult;

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
 * ApplicationServlet - Handles student internship application submissions.
 *
 * Enforces session authentication, server-side student ID resolution (never trusting client input),
 * input validation, active listing validation, and duplicate prevention.
 */
@WebServlet(name = "ApplicationServlet", urlPatterns = {"/ApplicationServlet", "/apply"})
public class ApplicationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private ApplicationService applicationService;

    @Override
    public void init() throws ServletException {
        super.init();
        this.applicationService = ApplicationService.getInstance();
    }

    /**
     * Handles HTTP GET requests.
     * Redirects to the internship exploration page.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/internships.jsp");
    }

    /**
     * Handles HTTP POST requests.
     * Processes internship application submissions from authenticated students.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);
        request.setCharacterEncoding("UTF-8");

        boolean isAjax = isAjaxRequest(request);

        // 1. Authenticate user from authoritative server-side session
        HttpSession session = request.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("currentUser") : null;

        if (currentUser == null) {
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"error\":\"unauthorized\",\"message\":\"Please log in to apply for internships.\",\"redirect\":\"login.html\"}");
            } else {
                String error = URLEncoder.encode("Please log in to apply for internships.", StandardCharsets.UTF_8.name());
                response.sendRedirect(request.getContextPath() + "/login.html?error=" + error);
            }
            return;
        }

        // 2. Validate account status
        if (!currentUser.isActive()) {
            String msg = "Your student account is currently inactive. Please contact support.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_FORBIDDEN,
                        "{\"success\":false,\"message\":\"" + escapeJson(msg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=error&msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 3. Validate role (administrators cannot apply for student internships)
        if (currentUser.isAdmin()) {
            String msg = "Administrator accounts cannot submit student internship applications.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_FORBIDDEN,
                        "{\"success\":false,\"message\":\"" + escapeJson(msg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=error&msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 4. Extract student ID strictly from server session (never from client request parameters)
        int studentId = currentUser.getUserId();

        // 5. Extract and validate internshipId parameter
        String internshipIdStr = request.getParameter("internshipId");
        int internshipId = -1;
        try {
            if (internshipIdStr != null && !internshipIdStr.trim().isEmpty()) {
                internshipId = Integer.parseInt(internshipIdStr.trim());
            }
        } catch (NumberFormatException e) {
            internshipId = -1;
        }

        if (internshipId <= 0) {
            String msg = "Invalid internship position selected.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(msg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=error&msg="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 6. Extract optional cover letter
        String coverLetter = request.getParameter("coverLetter");
        if (coverLetter != null) {
            coverLetter = coverLetter.trim();
            if (coverLetter.length() > 5000) {
                coverLetter = coverLetter.substring(0, 5000);
            }
        }

        // 7. Process application via ApplicationService
        ApplicationResult result = applicationService.submitApplication(studentId, internshipId, coverLetter);

        // 8. Render response
        if (isAjax) {
            if (result.isSuccess()) {
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"applicationId\":" + result.getApplicationId()
                        + ",\"message\":\"" + escapeJson(result.getMessage()) + "\"}");
            } else if (result.isDuplicate()) {
                sendJsonResponse(response, HttpServletResponse.SC_CONFLICT,
                        "{\"success\":false,\"duplicate\":true,\"message\":\""
                        + escapeJson(result.getMessage()) + "\"}");
            } else {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(result.getMessage()) + "\"}");
            }
        } else {
            // Standard HTTP redirect
            if (result.isSuccess()) {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=success&jobId=" + internshipId);
            } else if (result.isDuplicate()) {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=duplicate&jobId=" + internshipId);
            } else {
                response.sendRedirect(request.getContextPath() + "/internships.jsp?applied=error&msg="
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

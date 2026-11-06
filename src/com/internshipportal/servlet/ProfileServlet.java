package com.internshipportal.servlet;

import com.internshipportal.model.StudentProfile;
import com.internshipportal.model.User;
import com.internshipportal.service.StudentProfileService;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * ProfileServlet - Controller for student profile management.
 * Handles viewing redirection and updating personal, academic, and portfolio profile information.
 * Enforces strict server-side session authentication, input validation, and student isolation.
 */
@WebServlet(name = "ProfileServlet", urlPatterns = {"/ProfileServlet", "/profile/update"})
public class ProfileServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private StudentProfileService profileService;

    @Override
    public void init() throws ServletException {
        super.init();
        this.profileService = StudentProfileService.getInstance();
    }

    /**
     * Handles HTTP GET requests. Redirects to the JSP profile view.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        setNoCacheHeaders(response);
        response.sendRedirect(request.getContextPath() + "/profile.jsp");
    }

    /**
     * Handles HTTP POST requests for profile updates.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);
        request.setCharacterEncoding("UTF-8");

        boolean isAjax = isAjaxRequest(request);

        // 1. Enforce active server-side session authentication
        HttpSession session = request.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("currentUser") : null;

        if (currentUser == null) {
            String errorMsg = "Please log in to update your profile.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"error\":\"unauthorized\",\"message\":\"" + escapeJson(errorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.html?error="
                        + URLEncoder.encode(errorMsg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 2. Validate account status
        if (!currentUser.isActive()) {
            String msg = "Your account is currently inactive. Profile updates are disabled.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_FORBIDDEN,
                        "{\"success\":false,\"message\":\"" + escapeJson(msg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error="
                        + URLEncoder.encode(msg, StandardCharsets.UTF_8.name()));
            }
            return;
        }

        // 3. Security: Student identity is ALWAYS obtained from server-side session (never trusted from request)
        int userId = currentUser.getUserId();

        try {
            // 4. Validate and extract Full Name
            String fullName = request.getParameter("fullName");
            if (fullName == null || fullName.trim().isEmpty()) {
                throw new IllegalArgumentException("Full name cannot be empty.");
            }
            fullName = fullName.trim();
            if (fullName.length() > 100) {
                throw new IllegalArgumentException("Full name must not exceed 100 characters.");
            }

            // 5. Extract Phone Number
            String phone = request.getParameter("phone");
            if (phone != null) {
                phone = phone.trim();
                if (phone.length() > 20) {
                    throw new IllegalArgumentException("Phone number must not exceed 20 characters.");
                }
            } else {
                phone = "";
            }

            // 6. Extract Course
            String course = request.getParameter("course");
            if (course != null) {
                course = course.trim();
                if (course.length() > 50) {
                    throw new IllegalArgumentException("Course must not exceed 50 characters.");
                }
            } else {
                course = "";
            }

            // 7. Extract Internship Interest
            String internshipInterest = request.getParameter("internshipInterest");
            if (internshipInterest != null) {
                internshipInterest = internshipInterest.trim();
                if (internshipInterest.length() > 100) {
                    throw new IllegalArgumentException("Internship interest must not exceed 100 characters.");
                }
            } else {
                internshipInterest = "";
            }

            // 8. Validate and extract CGPA (Decimal 4,2: range 0.00 to 10.00)
            String cgpaParam = request.getParameter("cgpa");
            Double cgpa = null;
            if (cgpaParam != null && !cgpaParam.trim().isEmpty()) {
                try {
                    double parsedCgpa = Double.parseDouble(cgpaParam.trim());
                    if (parsedCgpa < 0.0 || parsedCgpa > 10.0) {
                        throw new IllegalArgumentException("CGPA must be a valid number between 0.00 and 10.00.");
                    }
                    // Round to 2 decimal places
                    cgpa = Math.round(parsedCgpa * 100.0) / 100.0;
                } catch (NumberFormatException e) {
                    throw new IllegalArgumentException("CGPA must be a valid decimal number (e.g. 8.50).");
                }
            }

            // 9. Validate and extract Graduation Year (Range 1990 to 2100)
            String yearParam = request.getParameter("graduationYear");
            Integer graduationYear = null;
            if (yearParam != null && !yearParam.trim().isEmpty()) {
                try {
                    int parsedYear = Integer.parseInt(yearParam.trim());
                    if (parsedYear < 1990 || parsedYear > 2100) {
                        throw new IllegalArgumentException("Graduation year must be between 1990 and 2100.");
                    }
                    graduationYear = parsedYear;
                } catch (NumberFormatException e) {
                    throw new IllegalArgumentException("Graduation year must be a valid 4-digit year (e.g. 2026).");
                }
            }

            // 10. Validate and sanitize URLs
            String resumeUrl = sanitizeAndValidateUrl(request.getParameter("resumeUrl"), "Resume URL");
            String linkedinUrl = sanitizeAndValidateUrl(request.getParameter("linkedinUrl"), "LinkedIn URL");
            String githubUrl = sanitizeAndValidateUrl(request.getParameter("githubUrl"), "GitHub URL");

            // 11. Construct StudentProfile model
            StudentProfile profile = new StudentProfile(userId, cgpa, graduationYear, resumeUrl, linkedinUrl, githubUrl);

            // 12. Atomically persist to database
            profileService.updateFullStudentProfile(userId, fullName, phone, course, internshipInterest, profile);

            // 13. Synchronize current session attributes for immediate display across dashboard and topbar
            currentUser.setFullName(fullName);
            currentUser.setPhone(phone);
            currentUser.setCourse(course);
            currentUser.setInternshipInterest(internshipInterest);

            session.setAttribute("currentUser", currentUser);
            session.setAttribute("fullName", fullName);
            session.setAttribute("course", course);

            String successMsg = "Profile updated successfully!";

            if (isAjax) {
                int completeness = profile.calculateCompleteness(currentUser);
                sendJsonResponse(response, HttpServletResponse.SC_OK,
                        "{\"success\":true,\"message\":\"" + escapeJson(successMsg)
                        + "\",\"completeness\":" + completeness + "}");
            } else {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?msg="
                        + URLEncoder.encode(successMsg, StandardCharsets.UTF_8.name()));
            }

        } catch (IllegalArgumentException e) {
            handleError(response, isAjax, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            System.err.println("[ProfileServlet] Database error while updating profile: " + e.getMessage());
            handleError(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Database error while saving profile. Please verify your inputs and try again.");
        } catch (Exception e) {
            System.err.println("[ProfileServlet] Unexpected error: " + e.getMessage());
            handleError(response, isAjax, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "An unexpected error occurred while updating profile.");
        }
    }

    private String sanitizeAndValidateUrl(String rawUrl, String fieldName) {
        if (rawUrl == null) {
            return null;
        }
        String trimmed = rawUrl.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        if (!trimmed.toLowerCase().startsWith("http://") && !trimmed.toLowerCase().startsWith("https://")) {
            trimmed = "https://" + trimmed;
        }
        if (trimmed.length() > 255) {
            throw new IllegalArgumentException(fieldName + " must not exceed 255 characters.");
        }
        return trimmed;
    }

    private void handleError(HttpServletResponse response, boolean isAjax, int statusCode, String message)
            throws IOException {
        if (isAjax) {
            sendJsonResponse(response, statusCode,
                    "{\"success\":false,\"message\":\"" + escapeJson(message) + "\"}");
        } else {
            response.sendRedirect(response.encodeRedirectURL("profile.jsp?error="
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

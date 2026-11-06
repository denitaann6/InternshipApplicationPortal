package com.internshipportal.servlet;

import com.internshipportal.model.User;
import com.internshipportal.service.AuditService;
import com.internshipportal.service.UserService;
import com.internshipportal.util.PasswordUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * LoginServlet - Authenticates students and administrators against MySQL.
 * Enforces role routing, rejects inactive accounts, and records audit logs into login_activity.
 */
@WebServlet(name = "LoginServlet", urlPatterns = {"/LoginServlet"})
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private UserService userService;
    private AuditService auditService;

    @Override
    public void init() throws ServletException {
        userService = UserService.getInstance();
        auditService = AuditService.getInstance();
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);

        HttpSession session = request.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("currentUser") : null;

        if (currentUser != null) {
            if (currentUser.isAdmin()) {
                response.sendRedirect(request.getContextPath() + "/admin-dashboard.jsp");
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/login.html");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        setNoCacheHeaders(response);
        request.setCharacterEncoding("UTF-8");

        // Invalidate any pre-existing session to prevent session fixation attacks
        HttpSession preExistingSession = request.getSession(false);
        if (preExistingSession != null) {
            preExistingSession.invalidate();
        }

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        String ipAddress = getClientIp(request);
        String userAgent = request.getHeader("User-Agent");

        if (username == null || username.trim().isEmpty()
                || password == null || password.isEmpty()) {
            auditService.recordLogin(null, username, ipAddress, userAgent, "FAILED", "Missing credentials");
            redirectWithError(request, response, "Invalid username or password.");
            return;
        }

        username = username.trim();

        // 1. Retrieve user from authoritative database
        User user = userService.findByUsernameOrEmail(username);

        if (user == null) {
            auditService.recordLogin(null, username, ipAddress, userAgent, "FAILED", "Invalid credentials");
            redirectWithError(request, response, "Invalid username or password.");
            return;
        }

        // 2. Cryptographic password verification (never logging password)
        boolean passwordMatch = PasswordUtil.verifyPassword(password, user.getPassword());
        if (!passwordMatch) {
            auditService.recordLogin(user.getUserId(), username, ipAddress, userAgent, "FAILED", "Invalid credentials");
            redirectWithError(request, response, "Invalid username or password.");
            return;
        }

        // 3. Status check: Reject inactive or suspended accounts
        if (!user.isActive()) {
            auditService.recordLogin(user.getUserId(), username, ipAddress, userAgent, "FAILED",
                    "Account inactive (" + user.getStatus() + ")");
            redirectWithError(request, response, "Your account is currently inactive. Please contact support.");
            return;
        }

        // 4. Record successful login audit event
        auditService.recordLogin(user.getUserId(), username, ipAddress, userAgent, "SUCCESS", null);

        // 5. Create completely fresh, authenticated session
        HttpSession session = request.getSession(true);
        session.setAttribute("currentUser", user);
        session.setAttribute("userId", user.getUserId());
        session.setAttribute("username", user.getUsername());
        session.setAttribute("fullName", user.getFullName());
        session.setAttribute("email", user.getEmail());
        session.setAttribute("course", user.getCourse());
        session.setAttribute("role", user.getRole());
        session.setAttribute("loginTime", new Date());

        // CSRF Token for state-changing forms
        String csrfToken = UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);

        session.setMaxInactiveInterval(30 * 60); // 30 minutes

        // 6. Role-based routing: Admins to Admin Dashboard, Students to Student Dashboard
        if (user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/admin-dashboard.jsp");
        } else {
            response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.trim().isEmpty()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private void redirectWithError(HttpServletRequest request,
                                   HttpServletResponse response,
                                   String message)
            throws IOException {

        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8.name());
        response.sendRedirect(request.getContextPath() + "/login.html?error=" + encoded);
    }

    private void setNoCacheHeaders(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
    }
}

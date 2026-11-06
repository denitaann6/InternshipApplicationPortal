package com.internshipportal.filter;

import com.internshipportal.model.User;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * AdminAuthorizationFilter - Enforces server-side administrator role authorization.
 * Strictly guarantees that non-admin accounts or unauthenticated visitors cannot access
 * admin dashboard, internship management, or applicant decision pages.
 */
public class AdminAuthorizationFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Prevent browser caching of protected administrative resources
        httpResponse.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        httpResponse.setHeader("Pragma", "no-cache");
        httpResponse.setDateHeader("Expires", 0);

        HttpSession session = httpRequest.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("currentUser") : null;

        // 1. Not logged in at all
        if (currentUser == null) {
            String error = URLEncoder.encode("Please log in as an administrator to access this area.",
                    StandardCharsets.UTF_8.name());
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/login.html?error=" + error);
            return;
        }

        // 2. Logged in, but NOT an administrator (e.g. Student)
        if (!currentUser.isAdmin()) {
            String error = URLEncoder.encode("Access denied. Administrator privileges are required.",
                    StandardCharsets.UTF_8.name());
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/dashboard.jsp?error=" + error);
            return;
        }

        // 3. User is an active authenticated administrator -> proceed
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}

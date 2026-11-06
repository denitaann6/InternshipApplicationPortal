package com.internshipportal.servlet;

import com.internshipportal.exception.InvalidInputException;
import com.internshipportal.service.ContactService;

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

/**
 * ContactServlet - Receives and processes contact inquiries.
 * Validates inputs server-side and stores messages into MySQL (contact_messages)
 * using PreparedStatement via ContactService.
 */
@WebServlet(name = "ContactServlet", urlPatterns = {"/ContactServlet", "/contact/submit"})
public class ContactServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private ContactService contactService;

    @Override
    public void init() throws ServletException {
        super.init();
        this.contactService = ContactService.getInstance();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/contact.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        boolean isAjax = isAjaxRequest(request);

        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String subject = request.getParameter("subject");
        String message = request.getParameter("message");

        try {
            boolean stored = contactService.submitMessage(name, email, subject, message);

            if (stored) {
                String successMsg = "Thank you! Your message has been received and recorded for review.";
                if (isAjax) {
                    sendJsonResponse(response, HttpServletResponse.SC_OK,
                            "{\"success\":true,\"message\":\"" + escapeJson(successMsg) + "\"}");
                } else {
                    response.sendRedirect(request.getContextPath() + "/contact.jsp?status=success&msg="
                            + URLEncoder.encode(successMsg, StandardCharsets.UTF_8.name()));
                }
            } else {
                String failMsg = "Unable to record your message. Please try again.";
                if (isAjax) {
                    sendJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                            "{\"success\":false,\"message\":\"" + escapeJson(failMsg) + "\"}");
                } else {
                    response.sendRedirect(request.getContextPath() + "/contact.jsp?status=error&msg="
                            + URLEncoder.encode(failMsg, StandardCharsets.UTF_8.name()));
                }
            }

        } catch (InvalidInputException e) {
            String errorMsg = e.getMessage();
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST,
                        "{\"success\":false,\"message\":\"" + escapeJson(errorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/contact.jsp?status=error&msg="
                        + URLEncoder.encode(errorMsg, StandardCharsets.UTF_8.name()));
            }
        } catch (SQLException e) {
            System.err.println("[ContactServlet] Database error while inserting contact message: " + e.getMessage());
            String dbErrorMsg = "A database error occurred while saving your message. Please try again later.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "{\"success\":false,\"message\":\"" + escapeJson(dbErrorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/contact.jsp?status=error&msg="
                        + URLEncoder.encode(dbErrorMsg, StandardCharsets.UTF_8.name()));
            }
        } catch (Exception e) {
            System.err.println("[ContactServlet] Unexpected error: " + e.getMessage());
            String generalErrorMsg = "An unexpected error occurred. Please try again.";
            if (isAjax) {
                sendJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "{\"success\":false,\"message\":\"" + escapeJson(generalErrorMsg) + "\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/contact.jsp?status=error&msg="
                        + URLEncoder.encode(generalErrorMsg, StandardCharsets.UTF_8.name()));
            }
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String xReq = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        return "XMLHttpRequest".equalsIgnoreCase(xReq)
                || (accept != null && accept.contains("application/json"))
                || "true".equalsIgnoreCase(request.getParameter("ajax"));
    }

    private void sendJsonResponse(HttpServletResponse response, int statusCode, String json) throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.print(json);
        out.flush();
    }

    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\b", "\\b")
                    .replace("\f", "\\f")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }
}

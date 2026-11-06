package com.internshipportal.service;

import com.internshipportal.exception.InvalidInputException;
import com.internshipportal.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;

/**
 * ContactService - Handles validation, duplicate prevention, and persistent
 * database storage for visitor and student contact inquiries into MySQL (contact_messages).
 */
public class ContactService {

    private static final ContactService INSTANCE = new ContactService();

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$");

    public static ContactService getInstance() {
        return INSTANCE;
    }

    /**
     * Validates contact form fields according to database column constraints and business rules.
     *
     * @param name    Sender's full name (max 100 chars, min 2 chars)
     * @param email   Sender's email address (max 255 chars, valid format)
     * @param subject Inquiry subject (max 200 chars, min 3 chars)
     * @param message Message body (max 4000 chars, min 5 chars)
     * @throws InvalidInputException if any input violates length or format rules
     */
    public void validate(String name, String email, String subject, String message)
            throws InvalidInputException {

        if (name == null || name.trim().isEmpty()) {
            throw new InvalidInputException("Your name is required.");
        }
        String trimmedName = name.trim();
        if (trimmedName.length() < 2 || trimmedName.length() > 100) {
            throw new InvalidInputException("Name must be between 2 and 100 characters.");
        }

        if (email == null || email.trim().isEmpty()) {
            throw new InvalidInputException("Your email address is required.");
        }
        String trimmedEmail = email.trim();
        if (trimmedEmail.length() > 255 || !EMAIL_PATTERN.matcher(trimmedEmail).matches()) {
            throw new InvalidInputException("Please provide a valid email address (e.g., user@example.com).");
        }

        if (subject == null || subject.trim().isEmpty()) {
            throw new InvalidInputException("Subject is required.");
        }
        String trimmedSubject = subject.trim();
        if (trimmedSubject.length() < 3 || trimmedSubject.length() > 200) {
            throw new InvalidInputException("Subject must be between 3 and 200 characters.");
        }

        if (message == null || message.trim().isEmpty()) {
            throw new InvalidInputException("Message content is required.");
        }
        String trimmedMessage = message.trim();
        if (trimmedMessage.length() < 5) {
            throw new InvalidInputException("Message is too short. Please provide at least 5 characters.");
        }
        if (trimmedMessage.length() > 4000) {
            throw new InvalidInputException("Message exceeds the maximum permitted length of 4000 characters.");
        }
    }

    /**
     * Checks if an identical contact message was submitted within the last 30 seconds
     * to prevent accidental double-clicks or repeated submissions.
     */
    public boolean isRecentDuplicate(String email, String subject, String message) {
        String sql = "SELECT message_id FROM contact_messages "
                   + "WHERE email = ? AND subject = ? AND message = ? "
                   + "AND submitted_at >= NOW() - INTERVAL 30 SECOND LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, email.trim().toLowerCase());
            stmt.setString(2, subject.trim());
            stmt.setString(3, message.trim());

            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            System.err.println("[ContactService] Error checking duplicate: " + e.getMessage());
            return false;
        }
    }

    /**
     * Validates and records a new contact inquiry into MySQL (contact_messages).
     *
     * @param name    Sender's name
     * @param email   Sender's email
     * @param subject Message subject
     * @param message Message body
     * @return true if the message was successfully stored or recognized as a recent duplicate
     * @throws InvalidInputException if inputs fail validation
     * @throws SQLException          if database insert fails
     */
    public boolean submitMessage(String name, String email, String subject, String message)
            throws InvalidInputException, SQLException {

        // 1. Server-side validation
        validate(name, email, subject, message);

        String trimmedName = name.trim();
        String trimmedEmail = email.trim().toLowerCase();
        String trimmedSubject = subject.trim();
        String trimmedMessage = message.trim();

        // 2. Prevent duplicate submissions
        if (isRecentDuplicate(trimmedEmail, trimmedSubject, trimmedMessage)) {
            // Already received; report success without creating a duplicate row
            return true;
        }

        // 3. Insert using PreparedStatement
        String sql = "INSERT INTO contact_messages (name, email, subject, message, status) "
                   + "VALUES (?, ?, ?, ?, 'NEW')";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, trimmedName);
            stmt.setString(2, trimmedEmail);
            stmt.setString(3, trimmedSubject);
            stmt.setString(4, trimmedMessage);

            int affected = stmt.executeUpdate();
            return affected > 0;
        } catch (SQLException e) {
            System.err.println("[ContactService] Failed to insert contact message: " + e.getMessage());
            throw e;
        }
    }
}

package com.internshipportal.service;

import com.internshipportal.model.Application;
import com.internshipportal.model.ApplicationStatusHistory;
import com.internshipportal.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * ApplicationService - Manages internship application submissions and tracking against MySQL.
 * Interacts with careerlaunch_db.applications and careerlaunch_db.application_status_history.
 *
 * Implements thread-safe singleton, prepared statements, and transactional status recording.
 */
public class ApplicationService {

    private static final ApplicationService INSTANCE = new ApplicationService();

    /**
     * Set of valid, supported recruitment lifecycle application statuses.
     */
    public static final Set<String> ALLOWED_STATUSES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
        "PENDING", "UNDER_REVIEW", "SHORTLISTED", "ACCEPTED", "REJECTED"
    )));

    public ApplicationService() {
    }

    public static ApplicationService getInstance() {
        return INSTANCE;
    }

    /**
     * Result wrapper for administrator status update operations.
     */
    public static class StatusUpdateResult {
        private final boolean success;
        private final boolean unchanged;
        private final String message;
        private final String previousStatus;
        private final String newStatus;

        private StatusUpdateResult(boolean success, boolean unchanged, String message, String previousStatus, String newStatus) {
            this.success = success;
            this.unchanged = unchanged;
            this.message = message;
            this.previousStatus = previousStatus;
            this.newStatus = newStatus;
        }

        public static StatusUpdateResult success(String message, String previousStatus, String newStatus) {
            return new StatusUpdateResult(true, false, message, previousStatus, newStatus);
        }

        public static StatusUpdateResult unchanged(String message, String currentStatus) {
            return new StatusUpdateResult(false, true, message, currentStatus, currentStatus);
        }

        public static StatusUpdateResult failure(String message) {
            return new StatusUpdateResult(false, false, message, null, null);
        }

        public boolean isSuccess() {
            return success;
        }

        public boolean isUnchanged() {
            return unchanged;
        }

        public String getMessage() {
            return message;
        }

        public String getPreviousStatus() {
            return previousStatus;
        }

        public String getNewStatus() {
            return newStatus;
        }
    }

    /**
     * Result wrapper for application submission attempts.
     */
    public static class ApplicationResult {
        private final boolean success;
        private final boolean duplicate;
        private final String message;
        private final int applicationId;

        private ApplicationResult(boolean success, boolean duplicate, String message, int applicationId) {
            this.success = success;
            this.duplicate = duplicate;
            this.message = message;
            this.applicationId = applicationId;
        }

        public static ApplicationResult success(int applicationId, String message) {
            return new ApplicationResult(true, false, message, applicationId);
        }

        public static ApplicationResult duplicate(String message) {
            return new ApplicationResult(false, true, message, -1);
        }

        public static ApplicationResult failure(String message) {
            return new ApplicationResult(false, false, message, -1);
        }

        public boolean isSuccess() {
            return success;
        }

        public boolean isDuplicate() {
            return duplicate;
        }

        public String getMessage() {
            return message;
        }

        public int getApplicationId() {
            return applicationId;
        }
    }

    /**
     * Submits a new internship application for an authenticated student.
     * Enforces active internship validation, duplicate prevention, and transactionally
     * records both the application record and the initial status history entry.
     *
     * @param studentId    The authenticated student's user ID from server session.
     * @param internshipId The primary key ID of the target internship.
     * @param coverLetter  Optional cover letter or notes submitted with the application.
     * @return ApplicationResult indicating success, duplicate attempt, or failure.
     */
    public ApplicationResult submitApplication(int studentId, int internshipId, String coverLetter) {
        if (studentId <= 0) {
            return ApplicationResult.failure("Invalid user session. Please log in again.");
        }
        if (internshipId <= 0) {
            return ApplicationResult.failure("Invalid internship selected.");
        }

        // 1. Verify student exists and is active
        try (Connection conn = DBUtil.getConnection()) {
            String userSql = "SELECT user_id, role, status FROM users WHERE user_id = ? LIMIT 1";
            try (PreparedStatement stmt = conn.prepareStatement(userSql)) {
                stmt.setInt(1, studentId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        return ApplicationResult.failure("User account not found.");
                    }
                    String status = rs.getString("status");
                    if (!"ACTIVE".equalsIgnoreCase(status)) {
                        return ApplicationResult.failure("Your account is currently inactive.");
                    }
                }
            }

            // 2. Verify internship exists and is ACTIVE
            String jobSql = "SELECT internship_id, title, company, status FROM internships WHERE internship_id = ? LIMIT 1";
            String jobTitle = "";
            String jobCompany = "";
            try (PreparedStatement stmt = conn.prepareStatement(jobSql)) {
                stmt.setInt(1, internshipId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        return ApplicationResult.failure("The requested internship listing does not exist.");
                    }
                    String jobStatus = rs.getString("status");
                    if (!"ACTIVE".equalsIgnoreCase(jobStatus)) {
                        return ApplicationResult.failure("This internship position is closed or no longer accepting applications.");
                    }
                    jobTitle = rs.getString("title");
                    jobCompany = rs.getString("company");
                }
            }

            // 3. Pre-check for duplicate application
            String dupSql = "SELECT application_id FROM applications WHERE student_id = ? AND internship_id = ? LIMIT 1";
            try (PreparedStatement stmt = conn.prepareStatement(dupSql)) {
                stmt.setInt(1, studentId);
                stmt.setInt(2, internshipId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        return ApplicationResult.duplicate("You have already submitted an application for " + jobTitle + " at " + jobCompany + ".");
                    }
                }
            }

            // 4. Transactional insert: applications + application_status_history
            boolean originalAutoCommit = conn.getAutoCommit();
            try {
                conn.setAutoCommit(false);

                // Insert into applications
                String insertAppSql = "INSERT INTO applications (student_id, internship_id, cover_letter, status, applied_at, updated_at) "
                                    + "VALUES (?, ?, ?, 'PENDING', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
                int generatedAppId = -1;

                try (PreparedStatement appStmt = conn.prepareStatement(insertAppSql, Statement.RETURN_GENERATED_KEYS)) {
                    appStmt.setInt(1, studentId);
                    appStmt.setInt(2, internshipId);
                    if (coverLetter != null && !coverLetter.trim().isEmpty()) {
                        appStmt.setString(3, coverLetter.trim());
                    } else {
                        appStmt.setNull(3, Types.VARCHAR);
                    }

                    int affected = appStmt.executeUpdate();
                    if (affected <= 0) {
                        conn.rollback();
                        return ApplicationResult.failure("Unable to save application. Please try again.");
                    }

                    try (ResultSet rsKeys = appStmt.getGeneratedKeys()) {
                        if (rsKeys.next()) {
                            generatedAppId = rsKeys.getInt(1);
                        }
                    }
                }

                if (generatedAppId <= 0) {
                    conn.rollback();
                    return ApplicationResult.failure("Failed to generate application confirmation.");
                }

                // Insert initial status history entry
                String insertHistSql = "INSERT INTO application_status_history (application_id, previous_status, new_status, changed_by, notes, changed_at) "
                                     + "VALUES (?, NULL, 'PENDING', ?, ?, CURRENT_TIMESTAMP)";
                try (PreparedStatement histStmt = conn.prepareStatement(insertHistSql)) {
                    histStmt.setInt(1, generatedAppId);
                    histStmt.setInt(2, studentId);
                    histStmt.setString(3, "Initial application submitted by student");
                    histStmt.executeUpdate();
                }

                conn.commit();
                return ApplicationResult.success(generatedAppId,
                        "Application submitted successfully for " + jobTitle + " at " + jobCompany + "! Initial status: PENDING.");

            } catch (SQLException e) {
                try {
                    conn.rollback();
                } catch (SQLException rbEx) {
                    System.err.println("[ApplicationService] Transaction rollback error: " + rbEx.getMessage());
                }

                // Check for MySQL duplicate key violation (Error Code 1062 or SQLState 23000)
                if (e.getErrorCode() == 1062 || "23000".equals(e.getSQLState())) {
                    return ApplicationResult.duplicate("You have already submitted an application for " + jobTitle + " at " + jobCompany + ".");
                }

                System.err.println("[ApplicationService] Error inserting application: " + e.getMessage());
                return ApplicationResult.failure("A database error occurred while processing your application. Please try again later.");

            } finally {
                try {
                    conn.setAutoCommit(originalAutoCommit);
                } catch (SQLException e) {
                    // Ignore restore auto-commit failure
                }
            }

        } catch (SQLException e) {
            System.err.println("[ApplicationService] Database connection error: " + e.getMessage());
            return ApplicationResult.failure("Database service unavailable. Please try again later.");
        }
    }

    /**
     * Checks if a student has already applied for a specific internship.
     *
     * @param studentId    The student's user ID.
     * @param internshipId The target internship ID.
     * @return true if an application record exists, false otherwise.
     */
    public boolean hasAlreadyApplied(int studentId, int internshipId) {
        if (studentId <= 0 || internshipId <= 0) {
            return false;
        }
        String sql = "SELECT 1 FROM applications WHERE student_id = ? AND internship_id = ? LIMIT 1";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, studentId);
            stmt.setInt(2, internshipId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error checking duplicate application: " + e.getMessage());
            return false;
        }
    }

    /**
     * Retrieves the set of internship IDs for which a specific student has submitted applications.
     *
     * @param studentId The student's user ID.
     * @return Set of applied internship IDs.
     */
    public Set<Integer> getAppliedInternshipIds(int studentId) {
        Set<Integer> set = new HashSet<>();
        if (studentId <= 0) {
            return set;
        }
        String sql = "SELECT internship_id FROM applications WHERE student_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, studentId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    set.add(rs.getInt("internship_id"));
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error fetching applied internship IDs: " + e.getMessage());
        }
        return set;
    }

    /**
     * Retrieves all applications submitted by a specific student, joined with internship details.
     * Strictly filters by the authenticated studentId using PreparedStatement.
     * Ordered chronologically by application date (newest first).
     *
     * @param studentId The authenticated student's user ID from server session.
     * @return List of Application domain model objects (empty list if none exist or on error).
     */
    public List<Application> getApplicationsForStudent(int studentId) {
        List<Application> list = new ArrayList<>();
        if (studentId <= 0) {
            return list;
        }

        String sql = "SELECT a.application_id, a.student_id, a.internship_id, a.cover_letter, a.status, "
                   + "a.applied_at, a.updated_at, "
                   + "i.title AS internship_title, i.company, i.location, i.work_mode, i.stipend, i.category "
                   + "FROM applications a "
                   + "INNER JOIN internships i ON a.internship_id = i.internship_id "
                   + "WHERE a.student_id = ? "
                   + "ORDER BY a.applied_at DESC, a.application_id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, studentId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Application app = new Application(
                        rs.getInt("application_id"),
                        rs.getInt("student_id"),
                        rs.getInt("internship_id"),
                        rs.getString("cover_letter"),
                        rs.getString("status"),
                        rs.getTimestamp("applied_at"),
                        rs.getTimestamp("updated_at")
                    );
                    app.setInternshipTitle(rs.getString("internship_title"));
                    app.setCompany(rs.getString("company"));
                    app.setLocation(rs.getString("location"));
                    app.setWorkMode(rs.getString("work_mode"));
                    app.setStipend(rs.getString("stipend"));
                    app.setCategory(rs.getString("category"));
                    list.add(app);
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error fetching applications for student " + studentId + ": " + e.getMessage());
        }
        return list;
    }

    /**
     * Retrieves a single application by its primary key application_id, joined with internship and user details.
     *
     * @param applicationId The application ID.
     * @return Application domain model object or null if not found.
     */
    public Application getApplicationById(int applicationId) {
        if (applicationId <= 0) {
            return null;
        }
        String sql = "SELECT a.application_id, a.student_id, a.internship_id, a.cover_letter, a.status, "
                   + "a.applied_at, a.updated_at, "
                   + "i.title AS internship_title, i.company, i.location, i.work_mode, i.stipend, i.category, "
                   + "u.full_name AS student_name, u.email AS student_email, u.phone AS student_phone, u.course AS student_course "
                   + "FROM applications a "
                   + "LEFT JOIN internships i ON a.internship_id = i.internship_id "
                   + "LEFT JOIN users u ON a.student_id = u.user_id "
                   + "WHERE a.application_id = ? LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Application app = new Application(
                        rs.getInt("application_id"),
                        rs.getInt("student_id"),
                        rs.getInt("internship_id"),
                        rs.getString("cover_letter"),
                        rs.getString("status"),
                        rs.getTimestamp("applied_at"),
                        rs.getTimestamp("updated_at")
                    );
                    app.setInternshipTitle(rs.getString("internship_title"));
                    app.setCompany(rs.getString("company"));
                    app.setLocation(rs.getString("location"));
                    app.setWorkMode(rs.getString("work_mode"));
                    app.setStipend(rs.getString("stipend"));
                    app.setCategory(rs.getString("category"));
                    app.setStudentName(rs.getString("student_name"));
                    app.setStudentEmail(rs.getString("student_email"));
                    app.setStudentPhone(rs.getString("student_phone"));
                    app.setStudentCourse(rs.getString("student_course"));
                    return app;
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error fetching application by ID " + applicationId + ": " + e.getMessage());
        }
        return null;
    }

    /**
     * Retrieves all applications across all students, joined with internship and student details.
     * Optionally filters by application status if statusFilter is provided.
     *
     * @param statusFilter Optional status filter (e.g. "PENDING", "UNDER_REVIEW") or null/ALL for all.
     * @return List of Application domain model objects.
     */
    public List<Application> getAllApplications(String statusFilter) {
        List<Application> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT a.application_id, a.student_id, a.internship_id, a.cover_letter, a.status, "
            + "a.applied_at, a.updated_at, "
            + "i.title AS internship_title, i.company, i.location, i.work_mode, i.stipend, i.category, "
            + "u.full_name AS student_name, u.email AS student_email, u.phone AS student_phone, u.course AS student_course "
            + "FROM applications a "
            + "INNER JOIN internships i ON a.internship_id = i.internship_id "
            + "INNER JOIN users u ON a.student_id = u.user_id "
        );

        boolean hasFilter = statusFilter != null && !statusFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(statusFilter.trim());
        if (hasFilter) {
            sql.append("WHERE a.status = ? ");
        }
        sql.append("ORDER BY a.applied_at DESC, a.application_id DESC");

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            if (hasFilter) {
                stmt.setString(1, statusFilter.trim().toUpperCase());
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Application app = new Application(
                        rs.getInt("application_id"),
                        rs.getInt("student_id"),
                        rs.getInt("internship_id"),
                        rs.getString("cover_letter"),
                        rs.getString("status"),
                        rs.getTimestamp("applied_at"),
                        rs.getTimestamp("updated_at")
                    );
                    app.setInternshipTitle(rs.getString("internship_title"));
                    app.setCompany(rs.getString("company"));
                    app.setLocation(rs.getString("location"));
                    app.setWorkMode(rs.getString("work_mode"));
                    app.setStipend(rs.getString("stipend"));
                    app.setCategory(rs.getString("category"));
                    app.setStudentName(rs.getString("student_name"));
                    app.setStudentEmail(rs.getString("student_email"));
                    app.setStudentPhone(rs.getString("student_phone"));
                    app.setStudentCourse(rs.getString("student_course"));
                    list.add(app);
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error fetching all applications: " + e.getMessage());
        }
        return list;
    }

    /**
     * Retrieves all applications without filter.
     */
    public List<Application> getAllApplications() {
        return getAllApplications(null);
    }

    /**
     * Updates an application's recruitment status transactionally.
     * Enforces row-level concurrency locking, duplicate-status protection (no duplicate history if unchanged),
     * and guarantees atomic commit of both the applications update and the application_status_history entry.
     *
     * @param applicationId Primary key ID of the target application.
     * @param newStatus     Requested new status (must be one of ALLOWED_STATUSES).
     * @param adminUserId   Authenticated administrator's user ID from server session.
     * @param adminNotes    Optional notes explaining the status decision.
     * @return StatusUpdateResult with operation outcome and status transition details.
     */
    public StatusUpdateResult updateApplicationStatus(int applicationId, String newStatus, int adminUserId, String adminNotes) {
        if (applicationId <= 0) {
            return StatusUpdateResult.failure("Invalid application ID.");
        }
        if (adminUserId <= 0) {
            return StatusUpdateResult.failure("Invalid administrator session. Please log in again.");
        }
        if (newStatus == null || newStatus.trim().isEmpty()) {
            return StatusUpdateResult.failure("Application status is required.");
        }

        String targetStatus = newStatus.trim().toUpperCase();
        if (!ALLOWED_STATUSES.contains(targetStatus)) {
            return StatusUpdateResult.failure("Unsupported application status: '" + newStatus + "'. Allowed: " + ALLOWED_STATUSES);
        }

        try (Connection conn = DBUtil.getConnection()) {
            boolean originalAutoCommit = conn.getAutoCommit();
            try {
                conn.setAutoCommit(false);

                // 1. Retrieve current status with row-level locking for concurrency protection
                String currentStatus = null;
                String selectSql = "SELECT status FROM applications WHERE application_id = ? FOR UPDATE";
                try (PreparedStatement selectStmt = conn.prepareStatement(selectSql)) {
                    selectStmt.setInt(1, applicationId);
                    try (ResultSet rs = selectStmt.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return StatusUpdateResult.failure("Application with ID #" + applicationId + " was not found.");
                        }
                        currentStatus = rs.getString("status");
                    }
                }

                // 2. Unchanged check: If status is already the requested status, do NOT create a duplicate history entry
                if (targetStatus.equalsIgnoreCase(currentStatus)) {
                    conn.rollback();
                    return StatusUpdateResult.unchanged(
                        "Application status is already '" + targetStatus + "'. No history entry was created.",
                        currentStatus
                    );
                }

                // 3. Update status on application record
                String updateSql = "UPDATE applications SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE application_id = ?";
                try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                    updateStmt.setString(1, targetStatus);
                    updateStmt.setInt(2, applicationId);
                    int affected = updateStmt.executeUpdate();
                    if (affected != 1) {
                        conn.rollback();
                        return StatusUpdateResult.failure("Failed to update application record.");
                    }
                }

                // 4. Insert into application_status_history
                String historySql = "INSERT INTO application_status_history "
                                  + "(application_id, previous_status, new_status, changed_by, notes, changed_at) "
                                  + "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
                try (PreparedStatement histStmt = conn.prepareStatement(historySql)) {
                    histStmt.setInt(1, applicationId);
                    histStmt.setString(2, currentStatus);
                    histStmt.setString(3, targetStatus);
                    histStmt.setInt(4, adminUserId);
                    if (adminNotes != null && !adminNotes.trim().isEmpty()) {
                        histStmt.setString(5, adminNotes.trim());
                    } else {
                        histStmt.setString(5, "Status updated from " + currentStatus + " to " + targetStatus + " by administrator");
                    }
                    int histAffected = histStmt.executeUpdate();
                    if (histAffected != 1) {
                        conn.rollback();
                        return StatusUpdateResult.failure("Failed to record application status history entry.");
                    }
                }

                // 5. Commit transaction atomically
                conn.commit();
                return StatusUpdateResult.success(
                    "Application #" + applicationId + " status successfully updated to " + targetStatus + ".",
                    currentStatus,
                    targetStatus
                );

            } catch (SQLException e) {
                try {
                    conn.rollback();
                } catch (SQLException rbEx) {
                    System.err.println("[ApplicationService] Rollback error: " + rbEx.getMessage());
                }
                System.err.println("[ApplicationService] Error updating application status: " + e.getMessage());
                return StatusUpdateResult.failure("A database transaction error occurred while updating status. Please try again.");
            } finally {
                try {
                    conn.setAutoCommit(originalAutoCommit);
                } catch (SQLException e) {
                    // Ignore restore auto-commit failure
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Database connection error: " + e.getMessage());
            return StatusUpdateResult.failure("Database service is currently unavailable.");
        }
    }

    /**
     * Retrieves the complete status history audit log for a specific application.
     *
     * @param applicationId Application primary key ID.
     * @return List of ApplicationStatusHistory records ordered newest first.
     */
    public List<ApplicationStatusHistory> getStatusHistory(int applicationId) {
        List<ApplicationStatusHistory> list = new ArrayList<>();
        if (applicationId <= 0) {
            return list;
        }

        String sql = "SELECT h.history_id, h.application_id, h.previous_status, h.new_status, "
                   + "h.changed_by, h.notes, h.changed_at, u.full_name AS changed_by_name, u.username AS changed_by_username "
                   + "FROM application_status_history h "
                   + "LEFT JOIN users u ON h.changed_by = u.user_id "
                   + "WHERE h.application_id = ? "
                   + "ORDER BY h.changed_at DESC, h.history_id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    ApplicationStatusHistory h = new ApplicationStatusHistory(
                        rs.getInt("history_id"),
                        rs.getInt("application_id"),
                        rs.getString("previous_status"),
                        rs.getString("new_status"),
                        rs.getObject("changed_by") != null ? rs.getInt("changed_by") : null,
                        rs.getString("notes"),
                        rs.getTimestamp("changed_at")
                    );
                    h.setChangedByName(rs.getString("changed_by_name"));
                    h.setChangedByUsername(rs.getString("changed_by_username"));
                    list.add(h);
                }
            }
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error fetching status history: " + e.getMessage());
        }
        return list;
    }

    /**
     * Utility method strictly for cleaning up test applications during test execution.
     * Cascades deletion to application_status_history via database foreign key.
     *
     * @param applicationId Application primary key to remove.
     * @return true if deleted, false otherwise.
     */
    public boolean deleteApplicationForTest(int applicationId) {
        if (applicationId <= 0) {
            return false;
        }
        String sql = "DELETE FROM applications WHERE application_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ApplicationService] Error deleting test application " + applicationId + ": " + e.getMessage());
            return false;
        }
    }
}

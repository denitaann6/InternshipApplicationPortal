package com.internshipportal.service;

import com.internshipportal.model.Internship;
import com.internshipportal.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * InternshipService - Manages internship retrieval and data access against MySQL (careerlaunch_db.internships).
 *
 * Implements thread-safe singleton pattern and prepared statement queries.
 * Maps relational database rows into Internship domain model objects.
 */
public class InternshipService {

    private static final InternshipService INSTANCE = new InternshipService();

    public InternshipService() {
    }

    public static InternshipService getInstance() {
        return INSTANCE;
    }

    /**
     * Retrieves all active internship listings from careerlaunch_db.internships.
     * Guaranteed to use PreparedStatement and release resources cleanly.
     *
     * @return List of active Internship objects, or an empty list if none exist or on DB error.
     */
    public List<Internship> getActiveInternships() {
        List<Internship> list = new ArrayList<>();
        String sql = "SELECT internship_id, title, company, location, work_mode, duration, stipend, "
                   + "category, skills, description, responsibilities, status, posted_by, created_at, updated_at "
                   + "FROM internships "
                   + "WHERE status = 'ACTIVE' "
                   + "ORDER BY internship_id ASC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                list.add(mapRowToInternship(rs));
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error querying active internships from database: " + e.getMessage());
        }

        return list;
    }

    /**
     * Retrieves all internships (both ACTIVE and INACTIVE) for administrative management.
     *
     * @return List of all Internship objects ordered by internship_id DESC.
     */
    public List<Internship> getAllInternships() {
        List<Internship> list = new ArrayList<>();
        String sql = "SELECT internship_id, title, company, location, work_mode, duration, stipend, "
                   + "category, skills, description, responsibilities, status, posted_by, created_at, updated_at "
                   + "FROM internships "
                   + "ORDER BY internship_id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                list.add(mapRowToInternship(rs));
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error querying all internships from database: " + e.getMessage());
        }

        return list;
    }

    /**
     * Retrieves a single internship by its unique primary key ID.
     * Returns the internship regardless of active or inactive status.
     *
     * @param internshipId The primary key internship_id.
     * @return Internship object if found, otherwise null.
     */
    public Internship getInternshipById(int internshipId) {
        if (internshipId <= 0) {
            return null;
        }
        String sql = "SELECT internship_id, title, company, location, work_mode, duration, stipend, "
                   + "category, skills, description, responsibilities, status, posted_by, created_at, updated_at "
                   + "FROM internships "
                   + "WHERE internship_id = ? "
                   + "LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, internshipId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapRowToInternship(rs);
                }
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error querying internship by ID " + internshipId + ": " + e.getMessage());
        }

        return null;
    }

    /**
     * Retrieves an active internship by its unique ID.
     *
     * @param internshipId The primary key internship_id.
     * @return Internship object if found and active, otherwise null.
     */
    public Internship getActiveInternshipById(int internshipId) {
        Internship intern = getInternshipById(internshipId);
        return (intern != null && intern.isActive()) ? intern : null;
    }

    /**
     * Returns total count of active internships directly from MySQL.
     */
    public int getActiveInternshipCount() {
        String sql = "SELECT COUNT(*) FROM internships WHERE status = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error counting active internships: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Returns total count of inactive internships directly from MySQL.
     */
    public int getInactiveInternshipCount() {
        String sql = "SELECT COUNT(*) FROM internships WHERE status = 'INACTIVE'";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error counting inactive internships: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Returns total count of all internships directly from MySQL.
     */
    public int getTotalInternshipCount() {
        String sql = "SELECT COUNT(*) FROM internships";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            System.err.println("[InternshipService] Error counting all internships: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Creates a new internship listing in MySQL.
     *
     * @param internship  Internship domain object with candidate details.
     * @param adminUserId Acting administrator's user ID from server session.
     * @return The auto-generated internship_id, or -1 on failure.
     * @throws SQLException If database execution errors occur.
     */
    public int createInternship(Internship internship, int adminUserId) throws SQLException {
        if (internship == null) {
            throw new IllegalArgumentException("Internship data cannot be null.");
        }
        if (internship.getTitle() == null || internship.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Internship title is required.");
        }
        if (internship.getCompany() == null || internship.getCompany().trim().isEmpty()) {
            throw new IllegalArgumentException("Company name is required.");
        }

        String sql = "INSERT INTO internships (title, company, location, work_mode, duration, stipend, "
                   + "category, skills, description, responsibilities, status, posted_by, created_at, updated_at) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, truncate(internship.getTitle().trim(), 150));
            stmt.setString(2, truncate(internship.getCompany().trim(), 150));
            stmt.setString(3, truncate(internship.getLocation(), 100));
            stmt.setString(4, truncate(internship.getWorkMode() != null && !internship.getWorkMode().trim().isEmpty() ? internship.getWorkMode().trim() : "Remote", 20));
            stmt.setString(5, truncate(internship.getDuration(), 50));
            stmt.setString(6, truncate(internship.getStipend(), 50));
            stmt.setString(7, truncate(internship.getCategory(), 100));
            stmt.setString(8, truncate(internship.getSkillsString(), 255));
            stmt.setString(9, internship.getDescription());
            stmt.setString(10, internship.getResponsibilitiesString());

            String status = internship.getStatus();
            if (status == null || (!status.equalsIgnoreCase("ACTIVE") && !status.equalsIgnoreCase("INACTIVE"))) {
                status = "ACTIVE";
            }
            stmt.setString(11, status.toUpperCase());

            if (adminUserId > 0) {
                stmt.setInt(12, adminUserId);
            } else {
                stmt.setNull(12, java.sql.Types.INTEGER);
            }

            int affected = stmt.executeUpdate();
            if (affected > 0) {
                try (ResultSet keys = stmt.getGeneratedKeys()) {
                    if (keys.next()) {
                        return keys.getInt(1);
                    }
                }
            }
        }
        return -1;
    }

    /**
     * Updates an existing internship listing in MySQL.
     *
     * @param internship Internship object with modified fields and valid id.
     * @return true if 1 row was updated, false otherwise.
     * @throws SQLException If database execution errors occur.
     */
    public boolean updateInternship(Internship internship) throws SQLException {
        if (internship == null || internship.getId() <= 0) {
            throw new IllegalArgumentException("Invalid internship ID for update.");
        }
        if (internship.getTitle() == null || internship.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Internship title is required.");
        }
        if (internship.getCompany() == null || internship.getCompany().trim().isEmpty()) {
            throw new IllegalArgumentException("Company name is required.");
        }

        String sql = "UPDATE internships SET title = ?, company = ?, location = ?, work_mode = ?, "
                   + "duration = ?, stipend = ?, category = ?, skills = ?, description = ?, "
                   + "responsibilities = ?, status = ?, updated_at = CURRENT_TIMESTAMP "
                   + "WHERE internship_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, truncate(internship.getTitle().trim(), 150));
            stmt.setString(2, truncate(internship.getCompany().trim(), 150));
            stmt.setString(3, truncate(internship.getLocation(), 100));
            stmt.setString(4, truncate(internship.getWorkMode() != null && !internship.getWorkMode().trim().isEmpty() ? internship.getWorkMode().trim() : "Remote", 20));
            stmt.setString(5, truncate(internship.getDuration(), 50));
            stmt.setString(6, truncate(internship.getStipend(), 50));
            stmt.setString(7, truncate(internship.getCategory(), 100));
            stmt.setString(8, truncate(internship.getSkillsString(), 255));
            stmt.setString(9, internship.getDescription());
            stmt.setString(10, internship.getResponsibilitiesString());

            String status = internship.getStatus();
            if (status == null || (!status.equalsIgnoreCase("ACTIVE") && !status.equalsIgnoreCase("INACTIVE"))) {
                status = "ACTIVE";
            }
            stmt.setString(11, status.toUpperCase());
            stmt.setInt(12, internship.getId());

            int affected = stmt.executeUpdate();
            return affected > 0;
        }
    }

    /**
     * Activates or deactivates an internship listing in MySQL.
     *
     * @param internshipId Target internship ID.
     * @param status       New status ("ACTIVE" or "INACTIVE").
     * @return true if updated successfully, false otherwise.
     * @throws SQLException If database execution errors occur.
     */
    public boolean setInternshipStatus(int internshipId, String status) throws SQLException {
        if (internshipId <= 0) {
            throw new IllegalArgumentException("Invalid internship ID.");
        }
        if (status == null || (!status.equalsIgnoreCase("ACTIVE") && !status.equalsIgnoreCase("INACTIVE"))) {
            throw new IllegalArgumentException("Invalid status. Supported values are ACTIVE or INACTIVE.");
        }

        String sql = "UPDATE internships SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE internship_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status.toUpperCase());
            stmt.setInt(2, internshipId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Truncates string values to prevent SQL column overflow exceptions.
     */
    private String truncate(String value, int maxLength) {
        if (value == null) return null;
        String trimmed = value.trim();
        return (trimmed.length() > maxLength) ? trimmed.substring(0, maxLength) : trimmed;
    }

    /**
     * Maps a MySQL ResultSet row from the `internships` table into an Internship domain model.
     */
    private Internship mapRowToInternship(ResultSet rs) throws SQLException {
        int id = rs.getInt("internship_id");
        String title = rs.getString("title");
        String company = rs.getString("company");
        String location = rs.getString("location");
        String workMode = rs.getString("work_mode");
        String duration = rs.getString("duration");
        String stipend = rs.getString("stipend");
        String category = rs.getString("category");
        String skillsStr = rs.getString("skills");
        String description = rs.getString("description");
        String responsibilitiesStr = rs.getString("responsibilities");
        String status = rs.getString("status");

        // Parse comma-separated skills
        List<String> skills = new ArrayList<>();
        if (skillsStr != null && !skillsStr.trim().isEmpty()) {
            for (String part : skillsStr.split(",")) {
                String trimmed = part.trim();
                if (!trimmed.isEmpty()) {
                    skills.add(trimmed);
                }
            }
        }

        // Parse responsibilities (supporting newline, semicolon, or full sentence)
        List<String> responsibilities = new ArrayList<>();
        if (responsibilitiesStr != null && !responsibilitiesStr.trim().isEmpty()) {
            String delimiter = responsibilitiesStr.contains("\n") ? "\n" :
                               (responsibilitiesStr.contains(";") ? ";" : null);

            if (delimiter != null) {
                for (String part : responsibilitiesStr.split(delimiter)) {
                    String trimmed = part.trim();
                    if (!trimmed.isEmpty()) {
                        responsibilities.add(trimmed);
                    }
                }
            } else {
                responsibilities.add(responsibilitiesStr.trim());
            }
        }

        Internship internship = new Internship(
            id,
            title != null ? title : "",
            company != null ? company : "",
            location != null ? location : "",
            workMode != null ? workMode : "Remote",
            duration != null ? duration : "3 Months",
            stipend != null ? stipend : "Unpaid",
            category != null ? category : "General",
            skills,
            description != null ? description : "",
            responsibilities,
            status != null ? status : "ACTIVE"
        );

        // Optional metadata
        int postedBy = rs.getInt("posted_by");
        if (!rs.wasNull()) {
            internship.setPostedBy(postedBy);
        }
        internship.setCreatedAt(rs.getTimestamp("created_at"));
        internship.setUpdatedAt(rs.getTimestamp("updated_at"));

        return internship;
    }
}

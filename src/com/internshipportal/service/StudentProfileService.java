package com.internshipportal.service;

import com.internshipportal.model.StudentProfile;
import com.internshipportal.model.User;
import com.internshipportal.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

/**
 * StudentProfileService - Manages student profile persistence and retrieval.
 * Interacts with MySQL table: careerlaunch_db.student_profiles and coordinates
 * with careerlaunch_db.users for personal profile updates.
 */
public class StudentProfileService {

    private static final StudentProfileService INSTANCE = new StudentProfileService();

    private StudentProfileService() {
    }

    public static StudentProfileService getInstance() {
        return INSTANCE;
    }

    /**
     * Retrieves the profile for a given student user ID.
     * Returns null if no profile record exists yet.
     */
    public StudentProfile getProfileByUserId(int userId) {
        if (userId <= 0) {
            return null;
        }

        String sql = "SELECT profile_id, user_id, cgpa, graduation_year, resume_url, linkedin_url, github_url, updated_at "
                   + "FROM student_profiles WHERE user_id = ? LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapRowToProfile(rs);
                }
            }
        } catch (SQLException e) {
            System.err.println("[StudentProfileService] Error querying student profile for user ID " + userId + ": " + e.getMessage());
        }

        return null;
    }

    /**
     * Saves or updates a student profile record in student_profiles using ON DUPLICATE KEY UPDATE.
     */
    public boolean saveOrUpdateProfile(StudentProfile profile) throws SQLException {
        if (profile == null || profile.getUserId() <= 0) {
            return false;
        }

        String sql = "INSERT INTO student_profiles (user_id, cgpa, graduation_year, resume_url, linkedin_url, github_url) "
                   + "VALUES (?, ?, ?, ?, ?, ?) "
                   + "ON DUPLICATE KEY UPDATE "
                   + "cgpa = VALUES(cgpa), "
                   + "graduation_year = VALUES(graduation_year), "
                   + "resume_url = VALUES(resume_url), "
                   + "linkedin_url = VALUES(linkedin_url), "
                   + "github_url = VALUES(github_url)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            setProfileStatementParams(stmt, profile);
            int affected = stmt.executeUpdate();
            return affected > 0;
        }
    }

    /**
     * Atomically updates both the student's core user information (in `users`)
     * and their extended academic/portfolio profile (in `student_profiles`).
     */
    public boolean updateFullStudentProfile(int userId, String fullName, String phone,
                                           String course, String internshipInterest,
                                           StudentProfile profile) throws SQLException {
        if (userId <= 0) {
            return false;
        }

        String updateUserSql = "UPDATE users SET full_name = ?, phone = ?, course = ?, internship_interest = ? WHERE user_id = ?";
        String upsertProfileSql = "INSERT INTO student_profiles (user_id, cgpa, graduation_year, resume_url, linkedin_url, github_url) "
                                + "VALUES (?, ?, ?, ?, ?, ?) "
                                + "ON DUPLICATE KEY UPDATE "
                                + "cgpa = VALUES(cgpa), "
                                + "graduation_year = VALUES(graduation_year), "
                                + "resume_url = VALUES(resume_url), "
                                + "linkedin_url = VALUES(linkedin_url), "
                                + "github_url = VALUES(github_url)";

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Update core student details in `users`
            try (PreparedStatement userStmt = conn.prepareStatement(updateUserSql)) {
                userStmt.setString(1, fullName != null ? fullName.trim() : "");
                userStmt.setString(2, phone != null ? phone.trim() : "");
                userStmt.setString(3, course != null ? course.trim() : "");
                userStmt.setString(4, internshipInterest != null ? internshipInterest.trim() : "");
                userStmt.setInt(5, userId);
                userStmt.executeUpdate();
            }

            // 2. Upsert extended academic credentials in `student_profiles`
            if (profile != null) {
                profile.setUserId(userId);
                try (PreparedStatement profStmt = conn.prepareStatement(upsertProfileSql)) {
                    setProfileStatementParams(profStmt, profile);
                    profStmt.executeUpdate();
                }
            }

            conn.commit();

            // 3. Keep UserService cache in sync if initialized
            UserService.getInstance().updateCachedUserDetails(userId, fullName, phone, course, internshipInterest);

            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    System.err.println("[StudentProfileService] Rollback failed: " + rollbackEx.getMessage());
                }
            }
            System.err.println("[StudentProfileService] Failed atomic update for user ID " + userId + ": " + e.getMessage());
            throw e;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) {}
            }
        }
    }

    /**
     * Deletes a student profile row. Used exclusively during test teardown.
     */
    public boolean deleteProfileByUserId(int userId) {
        if (userId <= 0) return false;
        String sql = "DELETE FROM student_profiles WHERE user_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[StudentProfileService] Error deleting profile for user " + userId + ": " + e.getMessage());
            return false;
        }
    }

    private void setProfileStatementParams(PreparedStatement stmt, StudentProfile profile) throws SQLException {
        stmt.setInt(1, profile.getUserId());

        if (profile.getCgpa() != null) {
            stmt.setDouble(2, profile.getCgpa());
        } else {
            stmt.setNull(2, Types.DECIMAL);
        }

        if (profile.getGraduationYear() != null) {
            stmt.setInt(3, profile.getGraduationYear());
        } else {
            stmt.setNull(3, Types.INTEGER);
        }

        if (profile.getResumeUrl() != null && !profile.getResumeUrl().trim().isEmpty()) {
            stmt.setString(4, profile.getResumeUrl().trim());
        } else {
            stmt.setNull(4, Types.VARCHAR);
        }

        if (profile.getLinkedinUrl() != null && !profile.getLinkedinUrl().trim().isEmpty()) {
            stmt.setString(5, profile.getLinkedinUrl().trim());
        } else {
            stmt.setNull(5, Types.VARCHAR);
        }

        if (profile.getGithubUrl() != null && !profile.getGithubUrl().trim().isEmpty()) {
            stmt.setString(6, profile.getGithubUrl().trim());
        } else {
            stmt.setNull(6, Types.VARCHAR);
        }
    }

    private StudentProfile mapRowToProfile(ResultSet rs) throws SQLException {
        int profileId = rs.getInt("profile_id");
        int userId = rs.getInt("user_id");

        double cgpaVal = rs.getDouble("cgpa");
        Double cgpa = rs.wasNull() ? null : cgpaVal;

        int gradVal = rs.getInt("graduation_year");
        Integer gradYear = rs.wasNull() ? null : gradVal;

        String resumeUrl = rs.getString("resume_url");
        String linkedinUrl = rs.getString("linkedin_url");
        String githubUrl = rs.getString("github_url");
        Timestamp updatedAt = rs.getTimestamp("updated_at");

        return new StudentProfile(profileId, userId, cgpa, gradYear, resumeUrl, linkedinUrl, githubUrl, updatedAt);
    }
}

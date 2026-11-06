package com.internshipportal.service;

import com.internshipportal.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AuditService - Records and audits authentication activities in MySQL (login_activity).
 * Strictly guarantees that passwords and password hashes are NEVER logged or retained.
 */
public class AuditService {

    private static final AuditService INSTANCE = new AuditService();

    public static AuditService getInstance() {
        return INSTANCE;
    }

    /**
     * Records a login attempt into login_activity table.
     * Passwords or credentials must NEVER be passed to this method.
     */
    public void recordLogin(Integer userId, String attemptedUsername, String ipAddress,
                            String userAgent, String loginStatus, String failureReason) {
        String sql = "INSERT INTO login_activity (user_id, attempted_username, ip_address, user_agent, login_status, failure_reason) "
                   + "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (userId != null && userId > 0) {
                stmt.setInt(1, userId);
            } else {
                stmt.setNull(1, java.sql.Types.INTEGER);
            }

            stmt.setString(2, truncate(attemptedUsername, 100));
            stmt.setString(3, truncate(ipAddress, 45));
            stmt.setString(4, truncate(userAgent, 500));
            stmt.setString(5, truncate(loginStatus, 20));
            stmt.setString(6, truncate(failureReason, 255));

            stmt.executeUpdate();

        } catch (SQLException e) {
            // Auditing failure should be logged to stderr but never crash the authentication flow
            System.err.println("[AuditService] Failed to record login activity: " + e.getMessage());
        }
    }

    /**
     * Retrieves recent login audit records for the administrator dashboard.
     */
    public List<Map<String, Object>> getRecentActivities(int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT activity_id, user_id, attempted_username, ip_address, user_agent, "
                   + "login_status, failure_reason, login_time "
                   + "FROM login_activity ORDER BY activity_id DESC LIMIT ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, limit > 0 ? limit : 10);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("activityId", rs.getLong("activity_id"));
                    map.put("userId", rs.getObject("user_id"));
                    map.put("attemptedUsername", rs.getString("attempted_username"));
                    map.put("ipAddress", rs.getString("ip_address"));
                    map.put("userAgent", rs.getString("user_agent"));
                    map.put("loginStatus", rs.getString("login_status"));
                    map.put("failureReason", rs.getString("failure_reason"));
                    Timestamp ts = rs.getTimestamp("login_time");
                    map.put("loginTime", ts != null ? ts.toString() : "");
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            System.err.println("[AuditService] Error fetching audit logs: " + e.getMessage());
        }
        return list;
    }

    /**
     * Returns total count of login attempts recorded.
     */
    public int getTotalLoginCount() {
        return getCount("SELECT COUNT(*) FROM login_activity");
    }

    /**
     * Returns count of failed login attempts.
     */
    public int getFailedLoginCount() {
        return getCount("SELECT COUNT(*) FROM login_activity WHERE UPPER(login_status) = 'FAILED'");
    }

    /**
     * Returns count of successful login attempts.
     */
    public int getSuccessfulLoginCount() {
        return getCount("SELECT COUNT(*) FROM login_activity WHERE UPPER(login_status) = 'SUCCESS'");
    }

    /**
     * Retrieves application lifecycle status audit records from MySQL (application_status_history).
     */
    public List<Map<String, Object>> getApplicationStatusAuditTrail(int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT h.history_id, h.application_id, h.previous_status, h.new_status, "
                   + "h.changed_by, h.notes, h.changed_at, u.full_name AS changer_name, "
                   + "u.role AS changer_role, i.title AS internship_title, i.company, "
                   + "app_user.full_name AS applicant_name "
                   + "FROM application_status_history h "
                   + "LEFT JOIN users u ON h.changed_by = u.user_id "
                   + "LEFT JOIN applications app ON h.application_id = app.application_id "
                   + "LEFT JOIN internships i ON app.internship_id = i.internship_id "
                   + "LEFT JOIN users app_user ON app.student_id = app_user.user_id "
                   + "ORDER BY h.changed_at DESC, h.history_id DESC LIMIT ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, limit > 0 ? limit : 20);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("historyId", rs.getLong("history_id"));
                    map.put("applicationId", rs.getInt("application_id"));
                    map.put("previousStatus", rs.getString("previous_status"));
                    map.put("newStatus", rs.getString("new_status"));
                    map.put("changedBy", rs.getObject("changed_by"));
                    map.put("notes", rs.getString("notes"));
                    Timestamp ts = rs.getTimestamp("changed_at");
                    map.put("changedAt", ts != null ? ts.toString() : "");
                    map.put("changerName", rs.getString("changer_name"));
                    map.put("changerRole", rs.getString("changer_role"));
                    map.put("internshipTitle", rs.getString("internship_title"));
                    map.put("company", rs.getString("company"));
                    map.put("applicantName", rs.getString("applicant_name"));
                    list.add(map);
                }
            }
        } catch (SQLException e) {
            System.err.println("[AuditService] Error fetching application status audit trail: " + e.getMessage());
        }
        return list;
    }

    private int getCount(String sql) {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[AuditService] Error counting audit events: " + e.getMessage());
        }
        return 0;
    }

    private String truncate(String val, int maxLen) {
        if (val == null) return null;
        val = val.trim();
        return val.length() > maxLen ? val.substring(0, maxLen) : val;
    }
}

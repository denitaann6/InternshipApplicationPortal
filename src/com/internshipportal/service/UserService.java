package com.internshipportal.service;

import com.internshipportal.exception.InvalidInputException;
import com.internshipportal.model.User;
import com.internshipportal.util.DBUtil;
import com.internshipportal.util.PasswordUtil;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * UserService - Authoritative user account management, registration, and authentication service.
 * Uses MySQL (careerlaunch_db.users) as the primary persistent store via JDBC PreparedStatements.
 * Supports role-based authentication (STUDENT vs ADMIN) and status checks (ACTIVE vs INACTIVE).
 */
public class UserService {

    private static final UserService INSTANCE = new UserService();

    // In-memory cache for fast session access and temporary fallback
    private final Map<String, User> cache = new ConcurrentHashMap<>();
    private final File storageFile;

    public UserService() {
        this.storageFile = resolveStorageFile();
        // Load fallback cache from file for offline resilience without altering the database
        loadFallbackCache();
    }

    public UserService(User user) {
        this();
        if (user != null && user.getUsername() != null && !user.getUsername().trim().isEmpty()) {
            cache.put(user.getUsername().trim().toLowerCase(), user);
        }
    }

    public static UserService getInstance() {
        return INSTANCE;
    }

    /**
     * Registers a new student account.
     * Persists directly to MySQL (careerlaunch_db.users) as the authoritative store.
     * Strictly enforces that public registration always assigns role='STUDENT' and status='ACTIVE'.
     */
    public synchronized boolean registerUser(User user) throws InvalidInputException {
        if (user == null || !user.isValid()) {
            throw new InvalidInputException("Please enter valid user details.");
        }

        String username = user.getUsername().trim();
        String email = user.getEmail().trim();

        // 1. Authoritative duplicate checks via MySQL
        if (usernameExists(username)) {
            throw new InvalidInputException("Username already exists.");
        }

        if (emailExists(email)) {
            throw new InvalidInputException("Email already exists.");
        }

        // 2. Cryptographically hash password before saving (SHA-256 + 16-byte random salt)
        String rawPassword = user.getPassword();
        String hashedPassword = PasswordUtil.hashPassword(rawPassword);
        user.setPassword(hashedPassword);
        user.setUsername(username);
        user.setEmail(email);

        // Security requirement: Always enforce STUDENT role and ACTIVE status on server
        user.setRole("STUDENT");
        user.setStatus("ACTIVE");

        // 3. Persist into MySQL users table using PreparedStatement
        String insertSql = "INSERT INTO users (username, password, email, full_name, phone, course, internship_interest, role, status) "
                         + "VALUES (?, ?, ?, ?, ?, ?, ?, 'STUDENT', 'ACTIVE')";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, user.getUsername());
            stmt.setString(2, user.getPassword());
            stmt.setString(3, user.getEmail());
            stmt.setString(4, user.getFullName() != null ? user.getFullName().trim() : "");
            stmt.setString(5, user.getPhone() != null ? user.getPhone().trim() : "");
            stmt.setString(6, user.getCourse() != null ? user.getCourse().trim() : "");
            stmt.setString(7, user.getInternshipInterest() != null ? user.getInternshipInterest().trim() : "");

            int affected = stmt.executeUpdate();
            if (affected > 0) {
                try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        user.setUserId(generatedKeys.getInt(1));
                    }
                }
            }

            // Update in-memory cache
            cache.put(username.toLowerCase(), user);
            return true;

        } catch (SQLException e) {
            System.err.println("[UserService] Database error during registration: " + e.getMessage());
            throw new InvalidInputException("Registration could not be completed in database: " + e.getMessage());
        }
    }

    /**
     * Authenticates a user against MySQL using username or email and password.
     * Compatible with PasswordUtil.verifyPassword() (SHA-256 salt:hash format).
     * Rejects inactive accounts.
     */
    public boolean authenticate(String usernameOrEmail, String password) {
        if (usernameOrEmail == null || password == null) {
            return false;
        }

        User user = findByUsernameOrEmail(usernameOrEmail.trim());
        if (user != null && user.getPassword() != null && user.isActive()) {
            return PasswordUtil.verifyPassword(password, user.getPassword());
        }
        return false;
    }

    /**
     * Finds a user by username or email from MySQL authoritative store.
     * Returns full User object including role and status.
     */
    public User findByUsernameOrEmail(String usernameOrEmail) {
        if (usernameOrEmail == null || usernameOrEmail.trim().isEmpty()) {
            return null;
        }

        String searchVal = usernameOrEmail.trim().toLowerCase();
        String sql = "SELECT * FROM users WHERE LOWER(username) = ? OR LOWER(email) = ? LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, searchVal);
            stmt.setString(2, searchVal);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    User user = mapRowToUser(rs);
                    cache.put(user.getUsername().toLowerCase(), user);
                    return user;
                }
            }
        } catch (SQLException e) {
            System.err.println("[UserService] Database query failed in findByUsernameOrEmail: " + e.getMessage());
            return searchCache(searchVal);
        }

        return null;
    }

    /**
     * Checks whether a username already exists in MySQL.
     */
    public boolean usernameExists(String username) {
        if (username == null || username.trim().isEmpty()) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM users WHERE LOWER(username) = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, username.trim().toLowerCase());
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            System.err.println("[UserService] DB check failed in usernameExists: " + e.getMessage());
            return cache.containsKey(username.trim().toLowerCase());
        }
        return false;
    }

    /**
     * Checks whether an email already exists in MySQL.
     */
    public boolean emailExists(String email) {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM users WHERE LOWER(email) = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, email.trim().toLowerCase());
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            System.err.println("[UserService] DB check failed in emailExists: " + e.getMessage());
            for (User u : cache.values()) {
                if (u.getEmail() != null && u.getEmail().equalsIgnoreCase(email.trim())) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Updates in-memory cached user details when a student profile is updated.
     */
    public void updateCachedUserDetails(int userId, String fullName, String phone,
                                        String course, String internshipInterest) {
        for (User u : cache.values()) {
            if (u.getUserId() == userId) {
                if (fullName != null) u.setFullName(fullName.trim());
                if (phone != null) u.setPhone(phone.trim());
                if (course != null) u.setCourse(course.trim());
                if (internshipInterest != null) u.setInternshipInterest(internshipInterest.trim());
                break;
            }
        }
    }


    /* =====================================================
       ADMINISTRATOR MANAGEMENT AND DASHBOARD QUERIES
       ===================================================== */

    /**
     * Creates or updates an administrator account.
     * Guardrail: Strictly prevents accidentally promoting an existing student account.
     */
    public synchronized boolean createAdminAccount(String username, String rawPassword,
                                                   String email, String fullName) throws InvalidInputException {
        if (username == null || username.trim().isEmpty()) {
            throw new InvalidInputException("Admin username cannot be empty.");
        }
        if (rawPassword == null || rawPassword.length() < 6) {
            throw new InvalidInputException("Admin password must be at least 6 characters.");
        }
        if (email == null || !email.contains("@")) {
            throw new InvalidInputException("A valid admin email address is required.");
        }

        String cleanUsername = username.trim();
        String cleanEmail = email.trim();

        // 1. Guardrail against accidentally promoting an existing STUDENT
        User existingUser = findByUsernameOrEmail(cleanUsername);
        if (existingUser != null && !"ADMIN".equalsIgnoreCase(existingUser.getRole())) {
            throw new InvalidInputException("Safety Violation: '" + cleanUsername
                    + "' already exists as a STUDENT account. The setup process cannot convert existing students to admins.");
        }

        User existingEmail = findByUsernameOrEmail(cleanEmail);
        if (existingEmail != null && !"ADMIN".equalsIgnoreCase(existingEmail.getRole())
                && !existingEmail.getUsername().equalsIgnoreCase(cleanUsername)) {
            throw new InvalidInputException("Safety Violation: Email '" + cleanEmail
                    + "' is registered to an existing student account.");
        }

        // 2. Hash password with existing PasswordUtil (SHA-256 + 16-byte random salt)
        String hashedPassword = PasswordUtil.hashPassword(rawPassword);

        // 3. Upsert into MySQL with explicit role='ADMIN' and status='ACTIVE'
        String sql = "INSERT INTO users (username, password, email, full_name, phone, course, internship_interest, role, status) "
                   + "VALUES (?, ?, ?, ?, '', 'Administration', 'Portal Management', 'ADMIN', 'ACTIVE') "
                   + "ON DUPLICATE KEY UPDATE "
                   + "password = VALUES(password), "
                   + "email = VALUES(email), "
                   + "full_name = VALUES(full_name), "
                   + "role = 'ADMIN', "
                   + "status = 'ACTIVE'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, cleanUsername);
            stmt.setString(2, hashedPassword);
            stmt.setString(3, cleanEmail);
            stmt.setString(4, fullName != null ? fullName.trim() : "System Administrator");

            int affected = stmt.executeUpdate();
            return affected > 0;

        } catch (SQLException e) {
            throw new InvalidInputException("Database error during admin setup: " + e.getMessage());
        }
    }

    /**
     * Returns total count of registered students.
     */
    public int getTotalStudentCount() {
        return getCount("SELECT COUNT(*) FROM users WHERE UPPER(role) = 'STUDENT'");
    }

    /**
     * Returns total count of active internships.
     */
    public int getActiveInternshipCount() {
        return getCount("SELECT COUNT(*) FROM internships WHERE UPPER(status) = 'ACTIVE'");
    }

    /**
     * Returns total count of all applications submitted.
     */
    public int getTotalApplicationCount() {
        return getCount("SELECT COUNT(*) FROM applications");
    }

    /**
     * Returns count of pending applications awaiting review.
     */
    public int getPendingApplicationCount() {
        return getCount("SELECT COUNT(*) FROM applications WHERE UPPER(status) IN ('PENDING', 'SUBMITTED', 'UNDER_REVIEW')");
    }

    /**
     * Retrieves all registered students for the admin dashboard.
     */
    public List<User> getAllStudents() {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE UPPER(role) = 'STUDENT' ORDER BY user_id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                list.add(mapRowToUser(rs));
            }

        } catch (SQLException e) {
            System.err.println("[UserService] Error fetching student directory: " + e.getMessage());
        }
        return list;
    }

    /**
     * Retrieves detailed student directory records joined with extended profile and application count.
     */
    public List<Map<String, Object>> getStudentDirectory() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT u.user_id, u.username, u.email, u.full_name, u.phone, u.course, "
                   + "u.internship_interest, u.status, u.created_at, "
                   + "p.cgpa, p.graduation_year, p.resume_url, p.linkedin_url, p.github_url, "
                   + "(SELECT COUNT(*) FROM applications a WHERE a.student_id = u.user_id) AS app_count "
                   + "FROM users u "
                   + "LEFT JOIN student_profiles p ON u.user_id = p.user_id "
                   + "WHERE UPPER(u.role) = 'STUDENT' "
                   + "ORDER BY u.user_id ASC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("userId", rs.getInt("user_id"));
                map.put("username", rs.getString("username"));
                map.put("email", rs.getString("email"));
                map.put("fullName", rs.getString("full_name"));
                map.put("phone", rs.getString("phone"));
                map.put("course", rs.getString("course"));
                map.put("internshipInterest", rs.getString("internship_interest"));
                map.put("status", rs.getString("status"));
                Timestamp createdAt = rs.getTimestamp("created_at");
                map.put("createdAt", createdAt != null ? createdAt.toString() : "");

                java.math.BigDecimal cgpa = rs.getBigDecimal("cgpa");
                map.put("cgpa", cgpa != null ? cgpa.toString() : null);

                Object gradYear = rs.getObject("graduation_year");
                map.put("graduationYear", gradYear != null ? gradYear.toString() : null);

                map.put("resumeUrl", rs.getString("resume_url"));
                map.put("linkedinUrl", rs.getString("linkedin_url"));
                map.put("githubUrl", rs.getString("github_url"));
                map.put("applicationCount", rs.getInt("app_count"));

                list.add(map);
            }

        } catch (SQLException e) {
            System.err.println("[UserService] Error fetching detailed student directory: " + e.getMessage());
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
            System.err.println("[UserService] Error executing count query: " + e.getMessage());
        }
        return 0;
    }

    /* =====================================================
       ROW MAPPING AND FALLBACK HELPERS
       ===================================================== */

    private User mapRowToUser(ResultSet rs) throws SQLException {
        int id = 0;
        try {
            id = rs.getInt("user_id");
        } catch (SQLException e) {
            try {
                id = rs.getInt("id");
            } catch (SQLException ignored) {}
        }

        String username = rs.getString("username");
        String password = rs.getString("password");
        String email = rs.getString("email");

        String fullName = "";
        try {
            fullName = rs.getString("full_name");
        } catch (SQLException e) {
            try {
                fullName = rs.getString("fullName");
            } catch (SQLException ignored) {}
        }

        String phone = "";
        try {
            phone = rs.getString("phone");
        } catch (SQLException ignored) {}

        String course = "";
        try {
            course = rs.getString("course");
        } catch (SQLException ignored) {}

        String interest = "";
        try {
            interest = rs.getString("internship_interest");
        } catch (SQLException e) {
            try {
                interest = rs.getString("internshipInterest");
            } catch (SQLException ignored) {}
        }

        String role = "STUDENT";
        try {
            String r = rs.getString("role");
            if (r != null && !r.trim().isEmpty()) {
                role = r.trim().toUpperCase();
            }
        } catch (SQLException ignored) {}

        String status = "ACTIVE";
        try {
            String s = rs.getString("status");
            if (s != null && !s.trim().isEmpty()) {
                status = s.trim().toUpperCase();
            }
        } catch (SQLException ignored) {}

        return new User(id, username, password, email, fullName, phone, course, interest, role, status);
    }

    private User searchCache(String searchVal) {
        User u = cache.get(searchVal);
        if (u != null) return u;
        for (User user : cache.values()) {
            if (user.getEmail() != null && user.getEmail().equalsIgnoreCase(searchVal)) {
                return user;
            }
        }
        return null;
    }

    /**
     * Loads fallback cache from file for offline resilience without modifying MySQL.
     */
    private void loadFallbackCache() {
        if (storageFile != null && storageFile.exists()) {
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(new FileInputStream(storageFile), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    line = line.trim();
                    if (line.isEmpty() || line.startsWith("#")) continue;
                    try {
                        User user = deserializeUser(line);
                        if (user != null && user.getUsername() != null) {
                            cache.put(user.getUsername().toLowerCase(), user);
                        }
                    } catch (Exception ignored) {}
                }
            } catch (IOException ignored) {}
        }
    }

    private File resolveStorageFile() {
        String customDir = System.getProperty("careerlaunch.data.dir");
        if (customDir == null || customDir.trim().isEmpty()) {
            customDir = System.getenv("CAREERLAUNCH_DATA_PATH");
        }
        if (customDir != null && !customDir.trim().isEmpty()) {
            File dir = new File(customDir.trim());
            return new File(dir, "registered_users.dat");
        }

        File projectDataDir = new File("C:\\Users\\HP\\Desktop\\MCA\\JAVA_PROJECT\\InternshipApplicationPortal\\data");
        if (projectDataDir.exists()) {
            return new File(projectDataDir, "registered_users.dat");
        }

        File fallbackDir = new File(System.getProperty("user.home"), ".careerlaunch");
        return new File(fallbackDir, "registered_users.dat");
    }

    private User deserializeUser(String line) {
        String[] parts = line.split("\\|", -1);
        if (parts.length < 8) return null;
        int id = Integer.parseInt(parts[0]);
        String username = decode(parts[1]);
        String password = decode(parts[2]);
        String email = decode(parts[3]);
        String fullName = decode(parts[4]);
        String phone = decode(parts[5]);
        String course = decode(parts[6]);
        String interest = decode(parts[7]);

        return new User(id, username, password, email, fullName, phone, course, interest, "STUDENT", "ACTIVE");
    }

    private String decode(String value) {
        if (value == null || value.isEmpty()) return "";
        try {
            return URLDecoder.decode(value, StandardCharsets.UTF_8.name());
        } catch (UnsupportedEncodingException e) {
            return value;
        }
    }
}
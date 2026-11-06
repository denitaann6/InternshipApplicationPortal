package com.internshipportal.util;

import java.io.Console;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Scanner;

/**
 * StudentPasswordSetup - Safe password provisioning utility for sample student accounts.
 *
 * Requirements enforced:
 * 1. Reuses existing PasswordUtil (SHA-256 + 16-byte random salt).
 * 2. Prompts interactively for each password locally; never hardcodes, prints, or logs passwords/hashes.
 * 3. Updates ONLY the `password` column using prepared statements.
 * 4. Strictly validates that each account exists with role='STUDENT' and status='ACTIVE'.
 * 5. Requires confirmation before updating each account.
 * 6. Avoids retaining passwords in memory longer than necessary by zeroing char arrays.
 */
public class StudentPasswordSetup {

    /**
     * Five sample student accounts to configure.
     */
    private static final String[] TARGET_STUDENTS = {
        "ananya_sharma",
        "rahul_mehta",
        "priya_nair",
        "arjun_kumar",
        "sneha_patel"
    };

    public static void main(String[] args) {
        System.out.println("============================================================");
        System.out.println("   CAREERLAUNCH - SAMPLE STUDENT PASSWORD SETUP UTILITY    ");
        System.out.println("============================================================");
        System.out.println("This utility will configure secure login passwords for the 5");
        System.out.println("sample student accounts in MySQL (careerlaunch_db).");
        System.out.println("Passwords are typed interactively and hashed with SHA-256.");
        System.out.println("Passwords and hashes are never printed or logged.");
        System.out.println("============================================================\n");

        Console console = System.console();
        Scanner scanner = new Scanner(System.in);

        // 1. Verify database connectivity
        try (Connection testConn = DBUtil.getConnection()) {
            if (testConn == null || testConn.isClosed()) {
                System.err.println("[ERROR] Database connection could not be established.");
                return;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to connect to MySQL: " + e.getMessage());
            System.err.println("Please check src/web/WEB-INF/db.properties and verify MySQL is running.");
            return;
        }

        int updatedCount = 0;
        int skippedCount = 0;

        // 2. Iterate through each target student account
        for (int i = 0; i < TARGET_STUDENTS.length; i++) {
            String username = TARGET_STUDENTS[i];
            int currentNum = i + 1;
            int totalNum = TARGET_STUDENTS.length;

            System.out.println("\n------------------------------------------------------------");
            System.out.printf("[%d/%d] Inspecting account: '%s'\n", currentNum, totalNum, username);
            System.out.println("------------------------------------------------------------");

            // Verify account exists, has role='STUDENT', and status='ACTIVE'
            AccountInfo info = checkAccountEligibility(username);
            if (info == null) {
                System.out.printf("[SKIP] Account '%s' not found in careerlaunch_db.users.\n", username);
                skippedCount++;
                continue;
            }

            if (!"STUDENT".equalsIgnoreCase(info.role)) {
                System.out.printf("[SKIP] Account '%s' has role '%s' (expected 'STUDENT'). Skipped for safety.\n",
                        username, info.role);
                skippedCount++;
                continue;
            }

            if (!"ACTIVE".equalsIgnoreCase(info.status)) {
                System.out.printf("[SKIP] Account '%s' has status '%s' (expected 'ACTIVE'). Skipped for safety.\n",
                        username, info.status);
                skippedCount++;
                continue;
            }

            // Display account metadata (safe fields only)
            System.out.printf("  User ID:   %d\n", info.userId);
            System.out.printf("  Full Name: %s\n", info.fullName);
            System.out.printf("  Email:     %s\n", info.email);
            System.out.printf("  Role:      %s\n", info.role);
            System.out.printf("  Status:    %s\n", info.status);

            // Require explicit user confirmation before updating
            System.out.printf("\nDo you want to set the password for '%s'? (y/n) [y]: ", username);
            String confirmChoice = scanner.nextLine().trim();
            if (confirmChoice.equalsIgnoreCase("n") || confirmChoice.equalsIgnoreCase("no")) {
                System.out.printf("[SKIPPED] Skipped '%s' by user request.\n", username);
                skippedCount++;
                continue;
            }

            // Prompt for new password with confirmation and retry
            char[] passwordChars = null;
            while (true) {
                char[] p1 = readPasswordInput(console, scanner,
                        String.format("Enter new password for '%s' (min 6 characters, or 'q' to skip): ", username));

                if (p1 == null || p1.length == 0) {
                    System.out.println("Password cannot be empty. Please try again.");
                    continue;
                }

                // Allow skipping account if user enters 'q'
                if (p1.length == 1 && (p1[0] == 'q' || p1[0] == 'Q')) {
                    Arrays.fill(p1, ' ');
                    System.out.printf("[SKIPPED] Skipped '%s'.\n", username);
                    break;
                }

                if (p1.length < 6) {
                    System.out.println("Password must be at least 6 characters long. Please try again.");
                    Arrays.fill(p1, ' ');
                    continue;
                }

                char[] p2 = readPasswordInput(console, scanner,
                        String.format("Confirm new password for '%s': ", username));

                if (!Arrays.equals(p1, p2)) {
                    System.out.println("Passwords do not match. Please try again.");
                    Arrays.fill(p1, ' ');
                    if (p2 != null) Arrays.fill(p2, ' ');
                    continue;
                }

                // Password confirmed
                if (p2 != null) Arrays.fill(p2, ' ');
                passwordChars = p1;
                break;
            }

            if (passwordChars == null) {
                skippedCount++;
                continue;
            }

            // Hash password using project's existing PasswordUtil (SHA-256 + 16-byte random salt)
            String rawPassword = new String(passwordChars);
            String hashedPassword = PasswordUtil.hashPassword(rawPassword);

            // Immediately clear raw password char array from memory
            Arrays.fill(passwordChars, ' ');

            // Execute database update using prepared statement
            boolean updated = updatePasswordOnly(username, hashedPassword);
            if (updated) {
                System.out.printf("[SUCCESS] Password updated securely for student account '%s'.\n", username);
                updatedCount++;
            } else {
                System.err.printf("[ERROR] Failed to update password for account '%s'.\n", username);
                skippedCount++;
            }
        }

        System.out.println("\n============================================================");
        System.out.println("                     SETUP SUMMARY                          ");
        System.out.println("============================================================");
        System.out.printf("  Total accounts processed: %d\n", TARGET_STUDENTS.length);
        System.out.printf("  Successfully updated:     %d\n", updatedCount);
        System.out.printf("  Skipped:                  %d\n", skippedCount);
        System.out.println("============================================================");

        if (updatedCount > 0) {
            System.out.println("\nVerification:");
            System.out.println("You can now log in with each configured account at:");
            System.out.println("http://localhost:8080/InternshipApplicationPortal/login.html");
            System.out.println("Select 'Student Login', enter the username and chosen password.");
        }
    }

    /**
     * Reads password securely using Console if available, with Scanner fallback.
     */
    private static char[] readPasswordInput(Console console, Scanner scanner, String prompt) {
        if (console != null) {
            return console.readPassword("%s", prompt);
        } else {
            System.out.print(prompt);
            String line = scanner.nextLine();
            return line != null ? line.toCharArray() : new char[0];
        }
    }

    /**
     * Verifies that the account exists and inspects role and status.
     */
    private static AccountInfo checkAccountEligibility(String username) {
        String query = "SELECT user_id, username, email, full_name, role, status FROM users WHERE username = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(query)) {

            stmt.setString(1, username);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    AccountInfo info = new AccountInfo();
                    info.userId = rs.getInt("user_id");
                    info.username = rs.getString("username");
                    info.email = rs.getString("email");
                    info.fullName = rs.getString("full_name");
                    info.role = rs.getString("role");
                    info.status = rs.getString("status");
                    return info;
                }
            }
        } catch (SQLException e) {
            System.err.printf("[DB ERROR] Error checking account '%s': %s\n", username, e.getMessage());
        }
        return null;
    }

    /**
     * Updates ONLY the `password` column using PreparedStatement.
     * Enforces that username matches and role='STUDENT' and status='ACTIVE'.
     */
    private static boolean updatePasswordOnly(String username, String hashedPassword) {
        String sql = "UPDATE users SET password = ? WHERE username = ? AND role = 'STUDENT' AND status = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, hashedPassword);
            stmt.setString(2, username);

            int affected = stmt.executeUpdate();
            return affected == 1;

        } catch (SQLException e) {
            System.err.printf("[DB ERROR] Error updating password for '%s': %s\n", username, e.getMessage());
            return false;
        }
    }

    private static class AccountInfo {
        int userId;
        String username;
        String email;
        String fullName;
        String role;
        String status;
    }
}

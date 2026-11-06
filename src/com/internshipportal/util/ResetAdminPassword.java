package com.internshipportal.util;

import java.util.Scanner;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class ResetAdminPassword {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("Enter new admin password: ");
        String password = sc.nextLine();

        if (password.length() < 6) {
            System.out.println("Password must be at least 6 characters.");
            sc.close();
            return;
        }

        String hashedPassword = PasswordUtil.hashPassword(password);

        String sql = "UPDATE users SET password = ? "
                   + "WHERE LOWER(username) = 'admin' "
                   + "AND UPPER(role) = 'ADMIN'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, hashedPassword);
            int updated = ps.executeUpdate();

            if (updated == 1) {
                System.out.println("Admin password reset successfully.");
            } else {
                System.out.println("No admin account updated. Check the username and role.");
            }

        } catch (Exception e) {
            System.out.println("Reset failed: " + e.getMessage());
        } finally {
            sc.close();
        }
    }
}
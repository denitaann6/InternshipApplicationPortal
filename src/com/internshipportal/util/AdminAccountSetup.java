package com.internshipportal.util;

import com.internshipportal.exception.InvalidInputException;
import com.internshipportal.service.UserService;

import java.io.Console;
import java.util.Scanner;

/**
 * AdminAccountSetup - Secure, controlled utility for administrator account provisioning.
 * Uses the existing cryptographic PasswordUtil implementation (SHA-256 + 16-byte random salt).
 * Guarantees that:
 * 1. Administrator passwords are NEVER hardcoded or printed.
 * 2. An existing STUDENT account can NEVER be accidentally promoted to administrator.
 * 3. The account is given explicit role='ADMIN' and status='ACTIVE'.
 */
public class AdminAccountSetup {

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("     CAREERLAUNCH - ADMINISTRATOR SETUP UTILITY   ");
        System.out.println("==================================================");

        Console console = System.console();
        Scanner scanner = new Scanner(System.in);

        try {
            // 1. Admin Username
            String username = "admin";
            System.out.print("Enter Admin Username [default: admin]: ");
            String inputUser = scanner.nextLine().trim();
            if (!inputUser.isEmpty()) {
                username = inputUser;
            }

            // 2. Admin Email
            String email = "admin@careerlaunch.com";
            System.out.print("Enter Admin Email [default: admin@careerlaunch.com]: ");
            String inputEmail = scanner.nextLine().trim();
            if (!inputEmail.isEmpty()) {
                email = inputEmail;
            }

            // 3. Admin Full Name
            String fullName = "System Administrator";
            System.out.print("Enter Admin Full Name [default: System Administrator]: ");
            String inputName = scanner.nextLine().trim();
            if (!inputName.isEmpty()) {
                fullName = inputName;
            }

            // 4. Admin Password (masked if Console is available)
            String password = "";
            String confirmPassword = "";

            if (console != null) {
                char[] passChars = console.readPassword("Enter Administrator Password (min 6 characters): ");
                if (passChars != null) password = new String(passChars);

                char[] confirmChars = console.readPassword("Confirm Administrator Password: ");
                if (confirmChars != null) confirmPassword = new String(confirmChars);
            } else {
                System.out.print("Enter Administrator Password (min 6 characters): ");
                password = scanner.nextLine();

                System.out.print("Confirm Administrator Password: ");
                confirmPassword = scanner.nextLine();
            }

            if (password.length() < 6) {
                System.err.println("\n[ERROR] Password must be at least 6 characters long.");
                System.exit(1);
            }

            if (!password.equals(confirmPassword)) {
                System.err.println("\n[ERROR] Passwords do not match.");
                System.exit(1);
            }

            System.out.println("\nProcessing administrator registration...");

            // 5. Delegate to UserService which enforces student non-promotion guardrails
            UserService userService = UserService.getInstance();
            boolean success = userService.createAdminAccount(username, password, email, fullName);

            if (success) {
                System.out.println("==================================================");
                System.out.println("[SUCCESS] Administrator account provisioned successfully!");
                System.out.println("Username:  " + username);
                System.out.println("Email:     " + email);
                System.out.println("Role:      ADMIN");
                System.out.println("Status:    ACTIVE");
                System.out.println("Security:  Hashed with SHA-256 + 16-byte random salt");
                System.out.println("==================================================");
                System.out.println("You can now log in at: http://localhost:8080/InternshipApplicationPortal/login.html");
            } else {
                System.err.println("[ERROR] Failed to provision administrator account.");
            }

        } catch (InvalidInputException e) {
            System.err.println("\n[SECURITY GUARDRAIL REJECTION]: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("\n[ERROR] Unexpected error during admin setup: " + e.getMessage());
        }
    }
}

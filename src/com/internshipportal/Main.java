package com.internshipportal;

import java.util.Scanner;

import com.internshipportal.exception.InvalidInputException;
import com.internshipportal.model.User;
import com.internshipportal.service.UserService;

public class Main {

    public static void main(String[] args) {

        Scanner scanner = new Scanner(System.in);

        User user = new User(
                1,
                "Ann",
                "Ann@123",
                "ann@gmail.com",
                "Ann"
        );

        UserService userService = new UserService(user);

        System.out.println("=================================");
        System.out.println("   INTERNSHIP APPLICATION PORTAL");
        System.out.println("=================================");

        try {

            System.out.print("Enter Username: ");
            String username = scanner.nextLine();

            System.out.print("Enter Password: ");
            String password = scanner.nextLine();

            // Check for empty input
            if (username.trim().isEmpty() || password.trim().isEmpty()) {
                throw new InvalidInputException(
                        "Username and password cannot be empty."
                );
            }

            // Check login details
            if (userService.authenticate(username, password)) {
                System.out.println();
                System.out.println("Valid user.");
                System.out.println("Login successful!");
                System.out.println("Welcome, " + user.getFullName() + "!");
            } else {
                System.out.println();
                System.out.println("Invalid user.");
                System.out.println("Incorrect username or password.");
            }

        } catch (InvalidInputException e) {

            System.out.println();
            System.out.println("Invalid input: " + e.getMessage());

        } finally {

            scanner.close();
        }
    }
}
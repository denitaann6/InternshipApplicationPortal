package com.internshipportal.model;

public class User {

    private int userId;
    private String username;
    private String password;
    private String email;
    private String fullName;
    private String phone;
    private String course;
    private String internshipInterest;
    private String role = "STUDENT";
    private String status = "ACTIVE";

    // Default constructor
    public User() {
    }

    // Parameterized constructor (Phase 1)
    public User(int userId, String username, String password,
                String email, String fullName) {
        this.userId = userId;
        this.username = username;
        this.password = password;
        this.email = email;
        this.fullName = fullName;
        this.role = "STUDENT";
        this.status = "ACTIVE";
    }

    // Extended constructor for complete registration details (Phase 3 & 4)
    public User(int userId, String username, String password,
                String email, String fullName, String phone,
                String course, String internshipInterest) {
        this(userId, username, password, email, fullName);
        this.phone = phone;
        this.course = course;
        this.internshipInterest = internshipInterest;
        this.role = "STUDENT";
        this.status = "ACTIVE";
    }

    // Extended constructor with Role and Status (Phase 2 Admin Integration)
    public User(int userId, String username, String password,
                String email, String fullName, String phone,
                String course, String internshipInterest,
                String role, String status) {
        this(userId, username, password, email, fullName, phone, course, internshipInterest);
        this.role = (role != null && !role.trim().isEmpty()) ? role.trim().toUpperCase() : "STUDENT";
        this.status = (status != null && !status.trim().isEmpty()) ? status.trim().toUpperCase() : "ACTIVE";
    }

    // Getters and Setters
    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getCourse() {
        return course;
    }

    public void setCourse(String course) {
        this.course = course;
    }

    public String getInternshipInterest() {
        return internshipInterest;
    }

    public void setInternshipInterest(String internshipInterest) {
        this.internshipInterest = internshipInterest;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = (role != null && !role.trim().isEmpty()) ? role.trim().toUpperCase() : "STUDENT";
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = (status != null && !status.trim().isEmpty()) ? status.trim().toUpperCase() : "ACTIVE";
    }

    public boolean isAdmin() {
        return "ADMIN".equalsIgnoreCase(role);
    }

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status);
    }

    // Basic validation
    public boolean isValid() {
        return username != null && !username.trim().isEmpty()
                && password != null && password.length() >= 3
                && email != null && email.contains("@")
                && fullName != null && !fullName.trim().isEmpty();
    }

    // Display user information
    public void displayUserInfo() {
        System.out.println("User ID: " + userId);
        System.out.println("Username: " + username);
        System.out.println("Email: " + email);
        System.out.println("Full Name: " + fullName);
        System.out.println("Role: " + role);
        System.out.println("Status: " + status);
        if (course != null && !course.isEmpty()) {
            System.out.println("Course: " + course);
        }
        if (phone != null && !phone.isEmpty()) {
            System.out.println("Phone: " + phone);
        }
        if (internshipInterest != null && !internshipInterest.isEmpty()) {
            System.out.println("Interest: " + internshipInterest);
        }
    }
}
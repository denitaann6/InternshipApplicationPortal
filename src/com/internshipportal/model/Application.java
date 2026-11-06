package com.internshipportal.model;

import java.io.Serializable;
import java.sql.Timestamp;

/**
 * Application - Model representing an application submitted by a student for an internship.
 * Maps directly to careerlaunch_db.applications.
 */
public class Application implements Serializable {

    private static final long serialVersionUID = 1L;

    private int applicationId;
    private int studentId;
    private int internshipId;
    private String coverLetter;
    private String status = "PENDING";
    private Timestamp appliedAt;
    private Timestamp updatedAt;

    // Optional joined fields for display convenience
    private String studentName;
    private String studentEmail;
    private String studentPhone;
    private String studentCourse;
    private String internshipTitle;
    private String company;
    private String location;
    private String workMode;
    private String stipend;
    private String category;

    public Application() {
        this.status = "PENDING";
    }

    public Application(int studentId, int internshipId, String coverLetter) {
        this.studentId = studentId;
        this.internshipId = internshipId;
        this.coverLetter = coverLetter;
        this.status = "PENDING";
    }

    public Application(int applicationId, int studentId, int internshipId,
                       String coverLetter, String status,
                       Timestamp appliedAt, Timestamp updatedAt) {
        this.applicationId = applicationId;
        this.studentId = studentId;
        this.internshipId = internshipId;
        this.coverLetter = coverLetter;
        this.status = (status != null && !status.trim().isEmpty()) ? status.trim().toUpperCase() : "PENDING";
        this.appliedAt = appliedAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public int getApplicationId() {
        return applicationId;
    }

    public int getId() {
        return applicationId;
    }

    public void setApplicationId(int applicationId) {
        this.applicationId = applicationId;
    }

    public void setId(int id) {
        this.applicationId = id;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public int getInternshipId() {
        return internshipId;
    }

    public void setInternshipId(int internshipId) {
        this.internshipId = internshipId;
    }

    public String getCoverLetter() {
        return coverLetter;
    }

    public void setCoverLetter(String coverLetter) {
        this.coverLetter = coverLetter;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = (status != null && !status.trim().isEmpty()) ? status.trim().toUpperCase() : "PENDING";
    }

    public Timestamp getAppliedAt() {
        return appliedAt;
    }

    public void setAppliedAt(Timestamp appliedAt) {
        this.appliedAt = appliedAt;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getStudentEmail() {
        return studentEmail;
    }

    public void setStudentEmail(String studentEmail) {
        this.studentEmail = studentEmail;
    }

    public String getStudentPhone() {
        return studentPhone;
    }

    public void setStudentPhone(String studentPhone) {
        this.studentPhone = studentPhone;
    }

    public String getStudentCourse() {
        return studentCourse;
    }

    public void setStudentCourse(String studentCourse) {
        this.studentCourse = studentCourse;
    }

    public String getInternshipTitle() {
        return internshipTitle;
    }

    public void setInternshipTitle(String internshipTitle) {
        this.internshipTitle = internshipTitle;
    }

    public String getCompany() {
        return company;
    }

    public void setCompany(String company) {
        this.company = company;
    }

    public String getWorkMode() {
        return workMode;
    }

    public void setWorkMode(String workMode) {
        this.workMode = workMode;
    }

    public String getStipend() {
        return stipend;
    }

    public void setStipend(String stipend) {
        this.stipend = stipend;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    @Override
    public String toString() {
        return "Application{" +
                "applicationId=" + applicationId +
                ", studentId=" + studentId +
                ", internshipId=" + internshipId +
                ", status='" + status + '\'' +
                ", appliedAt=" + appliedAt +
                '}';
    }
}

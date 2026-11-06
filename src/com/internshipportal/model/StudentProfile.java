package com.internshipportal.model;

import java.io.Serializable;
import java.sql.Timestamp;
import java.util.Locale;

/**
 * StudentProfile - Represents a student's extended academic credentials and professional links.
 * Maps directly to MySQL table: careerlaunch_db.student_profiles.
 */
public class StudentProfile implements Serializable {

    private static final long serialVersionUID = 1L;

    private int profileId;
    private int userId;
    private Double cgpa;
    private Integer graduationYear;
    private String resumeUrl;
    private String linkedinUrl;
    private String githubUrl;
    private Timestamp updatedAt;

    public StudentProfile() {
    }

    public StudentProfile(int userId, Double cgpa, Integer graduationYear,
                          String resumeUrl, String linkedinUrl, String githubUrl) {
        this.userId = userId;
        this.cgpa = cgpa;
        this.graduationYear = graduationYear;
        this.resumeUrl = resumeUrl;
        this.linkedinUrl = linkedinUrl;
        this.githubUrl = githubUrl;
    }

    public StudentProfile(int profileId, int userId, Double cgpa, Integer graduationYear,
                          String resumeUrl, String linkedinUrl, String githubUrl, Timestamp updatedAt) {
        this(userId, cgpa, graduationYear, resumeUrl, linkedinUrl, githubUrl);
        this.profileId = profileId;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public Double getCgpa() {
        return cgpa;
    }

    public void setCgpa(Double cgpa) {
        this.cgpa = cgpa;
    }

    public Integer getGraduationYear() {
        return graduationYear;
    }

    public void setGraduationYear(Integer graduationYear) {
        this.graduationYear = graduationYear;
    }

    public String getResumeUrl() {
        return resumeUrl;
    }

    public void setResumeUrl(String resumeUrl) {
        this.resumeUrl = resumeUrl;
    }

    public String getLinkedinUrl() {
        return linkedinUrl;
    }

    public void setLinkedinUrl(String linkedinUrl) {
        this.linkedinUrl = linkedinUrl;
    }

    public String getGithubUrl() {
        return githubUrl;
    }

    public void setGithubUrl(String githubUrl) {
        this.githubUrl = githubUrl;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Helper formatting methods

    public String getFormattedCgpa() {
        if (cgpa == null) {
            return "Not set";
        }
        return String.format(Locale.US, "%.2f", cgpa);
    }

    public String getFormattedGraduationYear() {
        if (graduationYear == null) {
            return "Not set";
        }
        return String.valueOf(graduationYear);
    }

    public boolean hasCgpa() {
        return cgpa != null && cgpa > 0;
    }

    public boolean hasGraduationYear() {
        return graduationYear != null && graduationYear > 0;
    }

    public boolean hasResumeUrl() {
        return resumeUrl != null && !resumeUrl.trim().isEmpty();
    }

    public boolean hasLinkedinUrl() {
        return linkedinUrl != null && !linkedinUrl.trim().isEmpty();
    }

    public boolean hasGithubUrl() {
        return githubUrl != null && !githubUrl.trim().isEmpty();
    }

    /**
     * Calculates profile completion percentage based on both core user details and academic profile.
     */
    public int calculateCompleteness(User user) {
        int score = 0;
        if (user != null) {
            if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) score += 15;
            if (user.getEmail() != null && !user.getEmail().trim().isEmpty()) score += 10;
            if (user.getPhone() != null && !user.getPhone().trim().isEmpty()) score += 15;
            if (user.getCourse() != null && !user.getCourse().trim().isEmpty()) score += 10;
            if (user.getInternshipInterest() != null && !user.getInternshipInterest().trim().isEmpty()) score += 10;
        }
        if (hasCgpa()) score += 15;
        if (hasGraduationYear()) score += 10;
        if (hasResumeUrl()) score += 10;
        if (hasLinkedinUrl() || hasGithubUrl()) score += 5;
        return Math.min(100, score);
    }

    @Override
    public String toString() {
        return "StudentProfile{" +
                "profileId=" + profileId +
                ", userId=" + userId +
                ", cgpa=" + cgpa +
                ", graduationYear=" + graduationYear +
                ", resumeUrl='" + resumeUrl + '\'' +
                ", linkedinUrl='" + linkedinUrl + '\'' +
                ", githubUrl='" + githubUrl + '\'' +
                ", updatedAt=" + updatedAt +
                '}';
    }
}

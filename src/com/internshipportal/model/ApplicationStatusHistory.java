package com.internshipportal.model;

import java.io.Serializable;
import java.sql.Timestamp;

/**
 * ApplicationStatusHistory - Represents an audit record of an application status change.
 * Maps to careerlaunch_db.application_status_history.
 */
public class ApplicationStatusHistory implements Serializable {

    private static final long serialVersionUID = 1L;

    private int historyId;
    private int applicationId;
    private String previousStatus;
    private String newStatus;
    private Integer changedBy;
    private String notes;
    private Timestamp changedAt;

    // Joined fields
    private String changedByName;
    private String changedByUsername;

    public ApplicationStatusHistory() {
    }

    public ApplicationStatusHistory(int historyId, int applicationId, String previousStatus,
                                  String newStatus, Integer changedBy, String notes, Timestamp changedAt) {
        this.historyId = historyId;
        this.applicationId = applicationId;
        this.previousStatus = previousStatus;
        this.newStatus = newStatus;
        this.changedBy = changedBy;
        this.notes = notes;
        this.changedAt = changedAt;
    }

    public int getHistoryId() {
        return historyId;
    }

    public void setHistoryId(int historyId) {
        this.historyId = historyId;
    }

    public int getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(int applicationId) {
        this.applicationId = applicationId;
    }

    public String getPreviousStatus() {
        return previousStatus;
    }

    public void setPreviousStatus(String previousStatus) {
        this.previousStatus = previousStatus;
    }

    public String getNewStatus() {
        return newStatus;
    }

    public void setNewStatus(String newStatus) {
        this.newStatus = newStatus;
    }

    public Integer getChangedBy() {
        return changedBy;
    }

    public void setChangedBy(Integer changedBy) {
        this.changedBy = changedBy;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public Timestamp getChangedAt() {
        return changedAt;
    }

    public void setChangedAt(Timestamp changedAt) {
        this.changedAt = changedAt;
    }

    public String getChangedByName() {
        return changedByName;
    }

    public void setChangedByName(String changedByName) {
        this.changedByName = changedByName;
    }

    public String getChangedByUsername() {
        return changedByUsername;
    }

    public void setChangedByUsername(String changedByUsername) {
        this.changedByUsername = changedByUsername;
    }
}

package com.internshipportal.interfaces;

public interface UserOperations {

    boolean authenticate(String username, String password);

    boolean validateUser();
}
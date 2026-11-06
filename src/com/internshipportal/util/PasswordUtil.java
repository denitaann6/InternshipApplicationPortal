package com.internshipportal.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

/**
 * PasswordUtil - Provides cryptographic password hashing and verification.
 * Uses SHA-256 with a unique 16-byte random salt per user.
 * Passwords stored as "saltHex:hashHex".
 * Provides backward compatibility for demonstration/test accounts.
 */
public class PasswordUtil {

    private static final SecureRandom RANDOM = new SecureRandom();

    /**
     * Generates a 16-byte cryptographically secure random salt in hexadecimal.
     */
    public static String generateSalt() {
        byte[] salt = new byte[16];
        RANDOM.nextBytes(salt);
        return bytesToHex(salt);
    }

    /**
     * Hashes a plain text password with a newly generated salt.
     * Returns the formatted string "saltHex:hashHex".
     */
    public static String hashPassword(String plainPassword) {
        if (plainPassword == null || plainPassword.isEmpty()) {
            return null;
        }
        String salt = generateSalt();
        String hash = computeHash(plainPassword, salt);
        return salt + ":" + hash;
    }

    /**
     * Computes the SHA-256 hash of (saltHex + plainPassword).
     */
    public static String computeHash(String plainPassword, String saltHex) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] saltBytes = hexToBytes(saltHex);
            digest.update(saltBytes);
            byte[] hashedBytes = digest.digest(plainPassword.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hashedBytes);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available in current JVM", e);
        }
    }

    /**
     * Verifies a plain text password against a stored password value.
     * Supports:
     * 1. Hashed passwords in the "saltHex:hashHex" format (SHA-256).
     * 2. Direct plain text comparison for backward compatibility with the Ann demo account and Main.java.
     */
    public static boolean verifyPassword(String inputPassword, String storedValue) {
        if (inputPassword == null || storedValue == null) {
            return false;
        }

        // 1. Check if stored value matches "saltHex:hashHex" format
        if (storedValue.contains(":")) {
            String[] parts = storedValue.split(":", 2);
            if (parts.length == 2 && parts[0].length() == 32) { // 16 bytes = 32 hex chars
                String salt = parts[0];
                String expectedHash = parts[1];
                String actualHash = computeHash(inputPassword, salt);
                return slowEquals(expectedHash, actualHash);
            }
        }

        // 2. Compatibility check for plain text (e.g., Ann demo login or Main.java)
        return slowEquals(inputPassword, storedValue);
    }

    /**
     * Constant-time string comparison to prevent timing attacks.
     */
    private static boolean slowEquals(String a, String b) {
        if (a == null || b == null) {
            return false;
        }
        int diff = a.length() ^ b.length();
        for (int i = 0; i < a.length() && i < b.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private static byte[] hexToBytes(String hex) {
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                                 + Character.digit(hex.charAt(i + 1), 16));
        }
        return data;
    }
}

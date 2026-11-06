package com.internshipportal.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * DBUtil - Centralized JDBC Connection and Resource Management.
 * Manages database connections for careerlaunch_db using prepared statements.
 * Securely retrieves credentials from environment variables first, avoiding
 * hardcoded credentials or exposure in version control.
 */
public class DBUtil {

    private static final String DRIVER_CLASS = "com.mysql.cj.jdbc.Driver";
    private static final String DEFAULT_URL =
            "jdbc:mysql://localhost:3306/careerlaunch_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String DEFAULT_USER = "root";

    private static boolean driverLoaded = false;

    static {
        try {
            Class.forName(DRIVER_CLASS);
            driverLoaded = true;
        } catch (ClassNotFoundException e) {
            System.err.println("[DBUtil] MySQL Driver ClassNotFoundException: " + e.getMessage());
        }
    }

    /**
     * Resolves the JDBC connection URL.
     * Order of precedence:
     * 1. Environment variable DB_URL or CAREERLAUNCH_DB_URL
     * 2. System property db.url or careerlaunch.db.url
     * 3. db.properties file
     * 4. Default: jdbc:mysql://localhost:3306/careerlaunch_db
     */
    public static String getDbUrl() {
        String url = getEnvOrProp("DB_URL", "CAREERLAUNCH_DB_URL", "db.url", "careerlaunch.db.url");
        if (url != null && !url.trim().isEmpty()) {
            return url.trim();
        }
        Properties fileProps = loadDbProperties();
        if (fileProps.containsKey("db.url")) {
            return fileProps.getProperty("db.url").trim();
        }
        return DEFAULT_URL;
    }

    /**
     * Resolves the database user.
     * Order of precedence:
     * 1. Environment variable DB_USER or CAREERLAUNCH_DB_USER
     * 2. System property db.user or careerlaunch.db.user
     * 3. db.properties file
     * 4. Default: root
     */
    public static String getDbUser() {
        String user = getEnvOrProp("DB_USER", "CAREERLAUNCH_DB_USER", "db.user", "careerlaunch.db.user");
        if (user != null && !user.trim().isEmpty()) {
            return user.trim();
        }
        Properties fileProps = loadDbProperties();
        if (fileProps.containsKey("db.user")) {
            return fileProps.getProperty("db.user").trim();
        }
        return DEFAULT_USER;
    }

    /**
     * Resolves the database password securely.
     * Order of precedence:
     * 1. Environment variable DB_PASSWORD, CAREERLAUNCH_DB_PASSWORD, or MYSQL_PWD
     * 2. System property db.password or careerlaunch.db.password
     * 3. db.properties file
     * 4. Default: "" (empty string)
     */
    public static String getDbPassword() {
        String pass = getEnvOrProp("DB_PASSWORD", "CAREERLAUNCH_DB_PASSWORD", "MYSQL_PWD",
                                   "db.password", "careerlaunch.db.password");
        if (pass != null) {
            return pass;
        }
        Properties fileProps = loadDbProperties();
        if (fileProps.containsKey("db.password")) {
            return fileProps.getProperty("db.password");
        }
        return "";
    }

    /**
     * Obtains a fresh JDBC Connection using the configured credentials.
     */
    public static Connection getConnection() throws SQLException {
        if (!driverLoaded) {
            try {
                Class.forName(DRIVER_CLASS);
                driverLoaded = true;
            } catch (ClassNotFoundException e) {
                throw new SQLException("MySQL Connector/J driver class not found (" + DRIVER_CLASS + ")", e);
            }
        }
        String url = getDbUrl();
        String user = getDbUser();
        String password = getDbPassword();
        return DriverManager.getConnection(url, user, password);
    }

    /**
     * Helper to test if database connection is available.
     */
    public static boolean isConnected() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            return false;
        }
    }

    /**
     * Safely closes one or more AutoCloseable resources (Connection, Statement, ResultSet).
     */
    public static void close(AutoCloseable... closeables) {
        if (closeables == null) return;
        for (AutoCloseable c : closeables) {
            if (c != null) {
                try {
                    c.close();
                } catch (Exception ignored) {
                }
            }
        }
    }

    private static String getEnvOrProp(String... keys) {
        for (String key : keys) {
            String val = System.getenv(key);
            if (val != null && !val.trim().isEmpty()) {
                return val;
            }
            val = System.getProperty(key);
            if (val != null && !val.trim().isEmpty()) {
                return val;
            }
        }
        return null;
    }

    private static Properties loadDbProperties() {
        Properties props = new Properties();
        // 1. Try classpath resource
        try (InputStream in = DBUtil.class.getClassLoader().getResourceAsStream("db.properties")) {
            if (in != null) {
                props.load(in);
                return props;
            }
        } catch (Exception ignored) {
        }

        // 2. Try WEB-INF/db.properties in Tomcat deploy or project directory
        String[] possiblePaths = {
            "src\\web\\WEB-INF\\db.properties",
            "C:\\xampp\\tomcat\\webapps\\InternshipApplicationPortal\\WEB-INF\\db.properties",
            "db.properties"
        };
        for (String p : possiblePaths) {
            File f = new File(p);
            if (f.exists()) {
                try (FileInputStream fis = new FileInputStream(f)) {
                    props.load(fis);
                    return props;
                } catch (Exception ignored) {
                }
            }
        }
        return props;
    }
}

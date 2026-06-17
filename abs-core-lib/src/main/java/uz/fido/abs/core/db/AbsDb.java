package uz.fido.abs.core.db;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * ABS Core — Bazaga ulanish boshqaruvchisi.
 * Singleton HikariCP pool.
 *
 * Ishlatish:
 *   AbsDb.init("jdbc:oracle:thin:@localhost:1521/XEPDB1", "bankuser", "pass");
 *   Connection conn = AbsDb.getConnection();
 */
public final class AbsDb {
    private static volatile HikariDataSource dataSource;

    private AbsDb() {}

    /** Initialize with explicit params */
    public static synchronized void init(String jdbcUrl, String username, String password) {
        if (dataSource != null) return; // already initialized
        HikariConfig config = new HikariConfig();
        config.setDriverClassName("oracle.jdbc.OracleDriver");
        config.setJdbcUrl(jdbcUrl);
        config.setUsername(username);
        config.setPassword(password);
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        dataSource = new HikariDataSource(config);
    }

    /** Initialize from environment variables: ABS_DB_URL, ABS_DB_USER, ABS_DB_PASSWORD */
    public static synchronized void initFromEnv() {
        String url = env("ABS_DB_URL", env("DB_URL", "jdbc:oracle:thin:@localhost:1521/XEPDB1"));
        String user = env("ABS_DB_USER", env("DB_USER", "bankuser"));
        String pass = env("ABS_DB_PASSWORD", env("DB_PASSWORD", "BankUser123"));
        init(url, user, pass);
    }

    /** Get a connection from the pool */
    public static Connection getConnection() throws SQLException {
        if (dataSource == null) {
            initFromEnv(); // auto-init from env if not explicitly initialized
        }
        return dataSource.getConnection();
    }

    /** Shutdown the pool */
    public static synchronized void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            dataSource = null;
        }
    }

    /** Check if initialized */
    public static boolean isInitialized() {
        return dataSource != null && !dataSource.isClosed();
    }

    private static String env(String key, String defaultVal) {
        String val = System.getenv(key);
        return val != null ? val : defaultVal;
    }
}

package uz.fido.bank.dao;

import uz.fido.bank.model.Account;
import uz.fido.bank.util.DbUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccountDao {

    public List<Account> findAll() throws SQLException {
        String sql = """
            SELECT a.*, c.first_name || ' ' || c.last_name AS customer_name
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            ORDER BY a.account_id
            """;
        List<Account> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    public List<Account> findByCustomerId(long customerId) throws SQLException {
        String sql = "SELECT a.*, '' AS customer_name FROM accounts a WHERE a.customer_id = ? ORDER BY a.account_id";
        List<Account> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public Account findById(long id) throws SQLException {
        String sql = """
            SELECT a.*, c.first_name || ' ' || c.last_name AS customer_name
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE a.account_id = ?
            """;
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public Account findByAccountNum(String accountNum) throws SQLException {
        String sql = "SELECT a.*, '' AS customer_name FROM accounts a WHERE a.account_num = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, accountNum);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public void save(Account a) throws SQLException {
        String sql = """
            INSERT INTO accounts (customer_id, account_num, account_type, currency, balance)
            VALUES (?, ?, ?, ?, ?)
            """;
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, a.getCustomerId());
            ps.setString(2, a.getAccountNum());
            ps.setString(3, a.getAccountType());
            ps.setString(4, a.getCurrency());
            ps.setBigDecimal(5, a.getBalance() != null ? a.getBalance() : BigDecimal.ZERO);
            ps.executeUpdate();
        }
    }

    public void updateBalance(long accountId, BigDecimal newBalance) throws SQLException {
        String sql = "UPDATE accounts SET balance = ? WHERE account_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBigDecimal(1, newBalance);
            ps.setLong(2, accountId);
            ps.executeUpdate();
        }
    }

    private Account mapRow(ResultSet rs) throws SQLException {
        Account a = new Account();
        a.setAccountId(rs.getLong("account_id"));
        a.setCustomerId(rs.getLong("customer_id"));
        a.setAccountNum(rs.getString("account_num"));
        a.setAccountType(rs.getString("account_type"));
        a.setCurrency(rs.getString("currency"));
        a.setBalance(rs.getBigDecimal("balance"));
        Timestamp ts = rs.getTimestamp("opened_at");
        if (ts != null) a.setOpenedAt(ts.toLocalDateTime());
        a.setStatus(rs.getString("status"));
        a.setCustomerName(rs.getString("customer_name"));
        return a;
    }
}

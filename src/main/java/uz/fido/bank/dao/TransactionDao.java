package uz.fido.bank.dao;

import uz.fido.bank.model.Transaction;
import uz.fido.bank.util.DbUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TransactionDao {

    public List<Transaction> findAll() throws SQLException {
        String sql = """
            SELECT t.*,
                   fa.account_num AS from_account_num,
                   ta.account_num AS to_account_num
            FROM transactions t
            LEFT JOIN accounts fa ON t.from_account = fa.account_id
            LEFT JOIN accounts ta ON t.to_account = ta.account_id
            ORDER BY t.txn_date DESC
            """;
        List<Transaction> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    public List<Transaction> findByAccountId(long accountId) throws SQLException {
        String sql = """
            SELECT t.*,
                   fa.account_num AS from_account_num,
                   ta.account_num AS to_account_num
            FROM transactions t
            LEFT JOIN accounts fa ON t.from_account = fa.account_id
            LEFT JOIN accounts ta ON t.to_account = ta.account_id
            WHERE t.from_account = ? OR t.to_account = ?
            ORDER BY t.txn_date DESC
            """;
        List<Transaction> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, accountId);
            ps.setLong(2, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public void transfer(long fromAccountId, long toAccountId, BigDecimal amount,
                          String currency, String description) throws SQLException {
        Connection conn = null;
        try {
            conn = DbUtil.getConnection();
            conn.setAutoCommit(false);

            try (PreparedStatement debit = conn.prepareStatement(
                    "UPDATE accounts SET balance = balance - ? WHERE account_id = ? AND balance >= ?")) {
                debit.setBigDecimal(1, amount);
                debit.setLong(2, fromAccountId);
                debit.setBigDecimal(3, amount);
                int rows = debit.executeUpdate();
                if (rows == 0) {
                    throw new SQLException("Mablag' yetarli emas yoki hisob topilmadi");
                }
            }

            try (PreparedStatement credit = conn.prepareStatement(
                    "UPDATE accounts SET balance = balance + ? WHERE account_id = ?")) {
                credit.setBigDecimal(1, amount);
                credit.setLong(2, toAccountId);
                credit.executeUpdate();
            }

            try (PreparedStatement txn = conn.prepareStatement("""
                    INSERT INTO transactions (from_account, to_account, txn_type, amount, currency, description)
                    VALUES (?, ?, 'TRANSFER', ?, ?, ?)
                    """)) {
                txn.setLong(1, fromAccountId);
                txn.setLong(2, toAccountId);
                txn.setBigDecimal(3, amount);
                txn.setString(4, currency);
                txn.setString(5, description);
                txn.executeUpdate();
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) conn.rollback();
            throw e;
        } finally {
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        }
    }

    private Transaction mapRow(ResultSet rs) throws SQLException {
        Transaction t = new Transaction();
        t.setTxnId(rs.getLong("txn_id"));
        long from = rs.getLong("from_account");
        t.setFromAccount(rs.wasNull() ? null : from);
        long to = rs.getLong("to_account");
        t.setToAccount(rs.wasNull() ? null : to);
        t.setTxnType(rs.getString("txn_type"));
        t.setAmount(rs.getBigDecimal("amount"));
        t.setCurrency(rs.getString("currency"));
        t.setDescription(rs.getString("description"));
        Timestamp ts = rs.getTimestamp("txn_date");
        if (ts != null) t.setTxnDate(ts.toLocalDateTime());
        t.setStatus(rs.getString("status"));
        t.setFromAccountNum(rs.getString("from_account_num"));
        t.setToAccountNum(rs.getString("to_account_num"));
        return t;
    }
}

package uz.fido.bank.dao;

import uz.fido.bank.model.Customer;
import uz.fido.bank.util.DbUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDao {

    public List<Customer> findAll() throws SQLException {
        String sql = "SELECT * FROM customers ORDER BY customer_id";
        List<Customer> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    public Customer findById(long id) throws SQLException {
        String sql = "SELECT * FROM customers WHERE customer_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public void save(Customer c) throws SQLException {
        String sql = """
            INSERT INTO customers (first_name, last_name, phone, email, passport_num, birth_date, address)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """;
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getFirstName());
            ps.setString(2, c.getLastName());
            ps.setString(3, c.getPhone());
            ps.setString(4, c.getEmail());
            ps.setString(5, c.getPassportNum());
            ps.setDate(6, c.getBirthDate() != null ? Date.valueOf(c.getBirthDate()) : null);
            ps.setString(7, c.getAddress());
            ps.executeUpdate();
        }
    }

    public void update(Customer c) throws SQLException {
        String sql = """
            UPDATE customers
            SET first_name = ?, last_name = ?, phone = ?, email = ?,
                passport_num = ?, birth_date = ?, address = ?, status = ?
            WHERE customer_id = ?
            """;
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getFirstName());
            ps.setString(2, c.getLastName());
            ps.setString(3, c.getPhone());
            ps.setString(4, c.getEmail());
            ps.setString(5, c.getPassportNum());
            ps.setDate(6, c.getBirthDate() != null ? Date.valueOf(c.getBirthDate()) : null);
            ps.setString(7, c.getAddress());
            ps.setString(8, c.getStatus());
            ps.setLong(9, c.getCustomerId());
            ps.executeUpdate();
        }
    }

    public void delete(long id) throws SQLException {
        String sql = "DELETE FROM customers WHERE customer_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        }
    }

    private Customer mapRow(ResultSet rs) throws SQLException {
        Customer c = new Customer();
        c.setCustomerId(rs.getLong("customer_id"));
        c.setFirstName(rs.getString("first_name"));
        c.setLastName(rs.getString("last_name"));
        c.setPhone(rs.getString("phone"));
        c.setEmail(rs.getString("email"));
        c.setPassportNum(rs.getString("passport_num"));
        Date bd = rs.getDate("birth_date");
        if (bd != null) c.setBirthDate(bd.toLocalDate());
        c.setAddress(rs.getString("address"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) c.setCreatedAt(ts.toLocalDateTime());
        c.setStatus(rs.getString("status"));
        return c;
    }
}

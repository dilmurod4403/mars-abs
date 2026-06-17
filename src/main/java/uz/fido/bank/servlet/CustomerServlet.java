package uz.fido.bank.servlet;

import uz.fido.bank.dao.AccountDao;
import uz.fido.bank.dao.CustomerDao;
import uz.fido.bank.model.Customer;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDate;

@WebServlet("/customers/*")
public class CustomerServlet extends HttpServlet {

    private final CustomerDao customerDao = new CustomerDao();
    private final AccountDao accountDao = new AccountDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            String pathInfo = req.getPathInfo();

            if (pathInfo == null || pathInfo.equals("/")) {
                req.setAttribute("customers", customerDao.findAll());
                req.getRequestDispatcher("/abs/customers.jsp").forward(req, resp);
            } else if (pathInfo.equals("/new")) {
                req.getRequestDispatcher("/abs/customer-form.jsp").forward(req, resp);
            } else if (pathInfo.matches("/\\d+/edit")) {
                long id = Long.parseLong(pathInfo.split("/")[1]);
                req.setAttribute("customer", customerDao.findById(id));
                req.getRequestDispatcher("/abs/customer-form.jsp").forward(req, resp);
            } else if (pathInfo.matches("/\\d+")) {
                long id = Long.parseLong(pathInfo.substring(1));
                req.setAttribute("customer", customerDao.findById(id));
                req.setAttribute("accounts", accountDao.findByCustomerId(id));
                req.getRequestDispatcher("/abs/customer-detail.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        try {
            String pathInfo = req.getPathInfo();
            Customer c = new Customer();
            c.setFirstName(req.getParameter("firstName"));
            c.setLastName(req.getParameter("lastName"));
            c.setPhone(req.getParameter("phone"));
            c.setEmail(req.getParameter("email"));
            c.setPassportNum(req.getParameter("passportNum"));
            String bd = req.getParameter("birthDate");
            if (bd != null && !bd.isEmpty()) {
                c.setBirthDate(LocalDate.parse(bd));
            }
            c.setAddress(req.getParameter("address"));

            if (pathInfo != null && pathInfo.matches("/\\d+")) {
                c.setCustomerId(Long.parseLong(pathInfo.substring(1)));
                c.setStatus(req.getParameter("status"));
                customerDao.update(c);
            } else {
                customerDao.save(c);
            }
            resp.sendRedirect(req.getContextPath() + "/customers");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}

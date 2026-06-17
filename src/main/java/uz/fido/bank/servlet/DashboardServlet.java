package uz.fido.bank.servlet;

import uz.fido.bank.dao.AccountDao;
import uz.fido.bank.dao.CustomerDao;
import uz.fido.bank.dao.TransactionDao;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("")
public class DashboardServlet extends HttpServlet {

    private final CustomerDao customerDao = new CustomerDao();
    private final AccountDao accountDao = new AccountDao();
    private final TransactionDao transactionDao = new TransactionDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("customers", customerDao.findAll());
            req.setAttribute("accounts", accountDao.findAll());
            req.setAttribute("transactions", transactionDao.findAll());
            req.getRequestDispatcher("/abs/dashboard.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}

package uz.fido.bank.servlet;

import uz.fido.bank.dao.AccountDao;
import uz.fido.bank.dao.CustomerDao;
import uz.fido.bank.dao.TransactionDao;
import uz.fido.bank.model.Account;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;

@WebServlet("/accounts/*")
public class AccountServlet extends HttpServlet {

    private final AccountDao accountDao = new AccountDao();
    private final CustomerDao customerDao = new CustomerDao();
    private final TransactionDao transactionDao = new TransactionDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            String pathInfo = req.getPathInfo();

            if (pathInfo == null || pathInfo.equals("/")) {
                req.setAttribute("accounts", accountDao.findAll());
                req.getRequestDispatcher("/abs/accounts/accounts.jsp").forward(req, resp);
            } else if (pathInfo.equals("/new")) {
                req.setAttribute("customers", customerDao.findAll());
                req.getRequestDispatcher("/abs/accounts/account-form.jsp").forward(req, resp);
            } else if (pathInfo.matches("/\\d+")) {
                long id = Long.parseLong(pathInfo.substring(1));
                req.setAttribute("account", accountDao.findById(id));
                req.setAttribute("transactions", transactionDao.findByAccountId(id));
                req.getRequestDispatcher("/abs/accounts/account-detail.jsp").forward(req, resp);
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
            Account a = new Account();
            a.setCustomerId(Long.parseLong(req.getParameter("customerId")));
            a.setAccountNum(req.getParameter("accountNum"));
            a.setAccountType(req.getParameter("accountType"));
            a.setCurrency(req.getParameter("currency"));
            String bal = req.getParameter("balance");
            a.setBalance(bal != null && !bal.isEmpty() ? new BigDecimal(bal) : BigDecimal.ZERO);
            accountDao.save(a);
            resp.sendRedirect(req.getContextPath() + "/accounts");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}

package uz.fido.bank.servlet;

import uz.fido.bank.dao.AccountDao;
import uz.fido.bank.dao.TransactionDao;
import uz.fido.bank.model.Account;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;

@WebServlet("/transfer")
public class TransferServlet extends HttpServlet {

    private final AccountDao accountDao = new AccountDao();
    private final TransactionDao transactionDao = new TransactionDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("accounts", accountDao.findAll());
            req.getRequestDispatcher("/abs/transfer.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        try {
            long fromId = Long.parseLong(req.getParameter("fromAccount"));
            long toId = Long.parseLong(req.getParameter("toAccount"));
            BigDecimal amount = new BigDecimal(req.getParameter("amount"));
            String description = req.getParameter("description");

            if (fromId == toId) {
                req.setAttribute("error", "Bir xil hisobga o'tkazib bo'lmaydi");
                req.setAttribute("accounts", accountDao.findAll());
                req.getRequestDispatcher("/abs/transfer.jsp").forward(req, resp);
                return;
            }

            Account from = accountDao.findById(fromId);
            transactionDao.transfer(fromId, toId, amount, from.getCurrency(), description);

            req.getSession().setAttribute("success", "O'tkazma muvaffaqiyatli amalga oshirildi!");
            resp.sendRedirect(req.getContextPath() + "/accounts/" + fromId);
        } catch (Exception e) {
            req.setAttribute("error", "Xatolik: " + e.getMessage());
            try {
                req.setAttribute("accounts", accountDao.findAll());
            } catch (Exception ignored) {}
            req.getRequestDispatcher("/abs/transfer.jsp").forward(req, resp);
        }
    }
}

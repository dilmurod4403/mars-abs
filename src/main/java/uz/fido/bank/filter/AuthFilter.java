package uz.fido.bank.filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Map;

/**
 * Autentifikatsiya filtri — barcha /abs/* sahifalarini himoya qiladi.
 * EncodingFilter'dan keyin ishlaydi (filter-mapping tartibi web.xml da yoki
 * @WebFilter annotation bilan).
 */
@WebFilter(filterName = "AuthFilter", urlPatterns = "/*")
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) resp;

        String contextPath = request.getContextPath();
        String uri = request.getRequestURI();
        // contextPath olib tashlash — masalan, /app/abs/login.jsp -> /abs/login.jsp
        String path = uri.substring(contextPath.length());

        boolean isStatic = path.startsWith("/css/") || path.startsWith("/js/") || path.startsWith("/images/");

        // HTML sahifalar keshlanmasin — eski (/customers, /accounts...) va yangi (/abs/...) modul uchun ham.
        // Static resurslar bundan mustasno: ular ?v=<mtime> bilan versiyalanadi.
        if (!isStatic) {
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setDateHeader("Expires", 0);
        }

        // Static yoki /abs/ bo'lmagan (eski servlet) sahifalar — autentifikatsiyasiz o'tkaziladi
        if (isStatic || !path.startsWith("/abs/")) {
            chain.doFilter(req, resp);
            return;
        }

        // 3. Login sahifasi — autentifikatsiyasiz o'tkazish
        if (path.equals("/abs/login.jsp")) {
            chain.doFilter(req, resp);
            return;
        }

        // 4. Session tekshiruv
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("currentUser") == null) {
            response.sendRedirect(contextPath + "/abs/login.jsp");
            return;
        }

        // 5. Admin sahifalar uchun rol tekshiruv
        if (path.startsWith("/abs/admin/")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> currentUser = (Map<String, Object>) session.getAttribute("currentUser");
            String role = (String) currentUser.get("role");
            if (!"ADMIN".equals(role)) {
                response.sendRedirect(contextPath + "/abs/cif/dashboard.jsp?err=Ruxsat+yo%27q");
                return;
            }
        }

        // Autentifikatsiya muvaffaqiyatli — so'rovni davom ettirish
        chain.doFilter(req, resp);
    }
}

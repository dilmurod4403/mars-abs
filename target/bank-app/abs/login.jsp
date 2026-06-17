<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="uz.fido.abs.core.db.Mars, java.util.HashMap, java.util.Map" %>
<%
    // ---- POST: Login so'rovini qayta ishlash ----
    String errorMessage = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || username.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {
            errorMessage = "Foydalanuvchi nomi va parolni kiriting";
        } else {
            try {
                Map<String,Object> result = Mars.procedure("core_auth_service.Authenticate_User")
                    .in("username", username.trim())
                    .in("password", password)
                    .outNumber("user_id")
                    .outString("full_name")
                    .outString("role")
                    .outString("branch_code")
                    .outNumber("code")
                    .outString("message")
                    .execute();

                int code = ((Number) result.get("code")).intValue();
                String message = (String) result.get("message");

                if (code == 0) {
                    // Muvaffaqiyatli — session yaratish
                    Map<String, Object> currentUser = new HashMap<>();
                    currentUser.put("user_id", ((Number) result.get("user_id")).longValue());
                    currentUser.put("username", username.trim());
                    currentUser.put("full_name", (String) result.get("full_name"));
                    currentUser.put("role", (String) result.get("role"));
                    currentUser.put("branch_code", (String) result.get("branch_code"));

                    HttpSession sess = request.getSession(true);
                    sess.setAttribute("currentUser", currentUser);
                    sess.setMaxInactiveInterval(30 * 60); // 30 daqiqa

                    response.sendRedirect(request.getContextPath() + "/abs/cif/dashboard.jsp");
                    return;
                } else {
                    errorMessage = message != null ? message : "Login xatosi";
                }
            } catch (Exception e) {
                errorMessage = "Tizim xatosi: ma'lumotlar bazasiga ulanib bo'lmadi";
            }
        }
    }

    // Cache-busting versiyasi
    long __v = 0L;
    try { __v = new java.io.File(application.getRealPath("/css/style.css")).lastModified(); } catch (Exception e) { __v = System.currentTimeMillis(); }
    String __cp = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MARS ABS — Kirish</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="<%= __cp %>/css/style.css?v=<%= __v %>">
    <style>
        /* ---- Login page overrides ---- */
        html, body {
            height: 100%;
        }
        body.login-page {
            background: var(--bg-app);
            min-height: 100vh;
            display: flex;
            align-items: stretch;
            justify-content: stretch;
        }

        /* ---- Split layout ---- */
        .login-split {
            display: flex;
            width: 100%;
            min-height: 100vh;
        }

        /* ---- Left: brand panel ---- */
        .login-brand {
            flex: 0 0 44%;
            min-height: 100vh;
            background: linear-gradient(160deg, #312e81 0%, #4f46e5 52%, #6d28d9 100%);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 2.75rem 3rem;
            position: relative;
            overflow: hidden;
        }

        /* Subtle geometric texture */
        .login-brand::before {
            content: "";
            position: absolute;
            inset: 0;
            background:
                radial-gradient(ellipse 60% 50% at 20% 20%, rgba(255,255,255,0.06) 0%, transparent 70%),
                radial-gradient(ellipse 45% 35% at 80% 80%, rgba(109,40,217,0.4) 0%, transparent 65%);
            pointer-events: none;
        }

        /* Decorative circles */
        .login-brand::after {
            content: "";
            position: absolute;
            width: 380px;
            height: 380px;
            border-radius: 50%;
            border: 1px solid rgba(255,255,255,0.07);
            right: -80px;
            bottom: -80px;
            pointer-events: none;
        }

        .brand-top {
            position: relative;
            z-index: 1;
        }

        .brand-logo-row {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .brand-logo-mark {
            width: 40px;
            height: 40px;
            border-radius: 11px;
            background: rgba(255,255,255,0.18);
            border: 1px solid rgba(255,255,255,0.28);
            backdrop-filter: blur(8px);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
            font-weight: 800;
            color: #fff;
            letter-spacing: -0.02em;
            flex-shrink: 0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.18);
        }

        .brand-name {
            font-size: 1.25rem;
            font-weight: 800;
            color: #fff;
            letter-spacing: -0.02em;
            line-height: 1.1;
        }

        .brand-name span {
            font-size: 0.6rem;
            font-weight: 700;
            letter-spacing: 0.14em;
            color: rgba(255,255,255,0.55);
            text-transform: uppercase;
            display: block;
            margin-top: 2px;
        }

        .brand-body {
            position: relative;
            z-index: 1;
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 3rem 0 2rem;
        }

        .brand-headline {
            font-size: 2.15rem;
            font-weight: 800;
            color: #fff;
            letter-spacing: -0.035em;
            line-height: 1.18;
            margin-bottom: 1rem;
        }

        .brand-desc {
            font-size: 0.925rem;
            color: rgba(255,255,255,0.62);
            line-height: 1.65;
            max-width: 340px;
        }

        /* Feature dots */
        .brand-features {
            margin-top: 2.5rem;
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
        }

        .brand-feature {
            display: flex;
            align-items: center;
            gap: 0.625rem;
            font-size: 0.825rem;
            color: rgba(255,255,255,0.72);
            font-weight: 500;
        }

        .brand-feature-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: rgba(255,255,255,0.45);
            flex-shrink: 0;
        }

        .brand-bottom {
            position: relative;
            z-index: 1;
            font-size: 0.75rem;
            color: rgba(255,255,255,0.35);
            font-weight: 500;
        }

        /* ---- Right: form panel ---- */
        .login-form-panel {
            flex: 1;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #fff;
            padding: 2.5rem 2rem;
        }

        .login-form-inner {
            width: 100%;
            max-width: 380px;
        }

        .login-form-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--gray-900);
            letter-spacing: -0.03em;
            margin-bottom: 0.375rem;
        }

        .login-form-sub {
            font-size: 0.875rem;
            color: var(--gray-500);
            margin-bottom: 2rem;
        }

        /* Error alert with icon */
        .login-error {
            display: flex;
            align-items: flex-start;
            gap: 0.625rem;
            background: #fef2f2;
            color: #991b1b;
            border: 1px solid #fecaca;
            border-radius: var(--radius-sm);
            padding: 0.75rem 1rem;
            font-size: 0.84rem;
            font-weight: 500;
            margin-bottom: 1.5rem;
            line-height: 1.45;
        }

        .login-error svg {
            flex-shrink: 0;
            margin-top: 1px;
            color: #dc2626;
        }

        /* Input fields — slightly larger than default for login feel */
        .login-form-inner .form-control {
            height: 42px;
            font-size: 0.925rem;
            border-radius: var(--radius-sm);
            background: var(--gray-50);
            border-color: var(--border-strong);
            transition: border-color var(--t) var(--ease), box-shadow var(--t) var(--ease), background var(--t) var(--ease);
        }

        .login-form-inner .form-control:hover {
            background: #fff;
            border-color: var(--gray-300);
        }

        .login-form-inner .form-control:focus {
            background: #fff;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px var(--primary-ring);
        }

        .login-form-inner .form-group {
            margin-bottom: 1.125rem;
        }

        .login-form-inner .form-group label {
            font-size: 0.8rem;
            font-weight: 600;
            color: var(--gray-700);
            margin-bottom: 0.375rem;
        }

        /* Submit button */
        .login-submit {
            width: 100%;
            height: 44px;
            font-size: 0.925rem;
            font-weight: 600;
            border-radius: var(--radius-sm);
            margin-top: 0.375rem;
            background: var(--primary);
            color: #fff;
            border: 1px solid var(--primary);
            cursor: pointer;
            font-family: inherit;
            letter-spacing: -0.01em;
            box-shadow: 0 1px 2px rgba(79,70,229,0.25), inset 0 1px 0 rgba(255,255,255,0.12);
            transition: background var(--t-fast) var(--ease), box-shadow var(--t-fast) var(--ease), transform var(--t-fast) var(--ease);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }

        .login-submit:hover {
            background: var(--primary-dark);
            border-color: var(--primary-dark);
            box-shadow: 0 4px 12px rgba(79,70,229,0.3), inset 0 1px 0 rgba(255,255,255,0.12);
        }

        .login-submit:active {
            transform: translateY(1px);
        }

        .login-submit:focus-visible {
            outline: 2px solid var(--primary);
            outline-offset: 2px;
        }

        /* Divider */
        .login-divider {
            height: 1px;
            background: var(--border);
            margin: 1.75rem 0;
        }

        /* Footer inside form panel */
        .login-form-footer {
            text-align: center;
            font-size: 0.75rem;
            color: var(--gray-400);
        }

        /* ---- Responsive: stack vertically on narrow ---- */
        @media (max-width: 768px) {
            .login-split {
                flex-direction: column;
            }

            .login-brand {
                flex: none;
                min-height: auto;
                padding: 2rem 1.5rem;
            }

            .brand-body {
                padding: 1.5rem 0 1rem;
            }

            .brand-headline {
                font-size: 1.5rem;
            }

            .brand-features {
                display: none;
            }

            .login-form-panel {
                min-height: auto;
                padding: 2.5rem 1.5rem 3rem;
            }
        }
    </style>
</head>
<body class="login-page">
    <div class="login-split">

        <%-- ==================== CHAP: BRAND PANEL ==================== --%>
        <div class="login-brand">
            <div class="brand-top">
                <div class="brand-logo-row">
                    <div class="brand-logo-mark">M</div>
                    <div class="brand-name">
                        MARS ABS
                        <span>Fido Bank</span>
                    </div>
                </div>
            </div>

            <div class="brand-body">
                <div class="brand-headline">
                    Avtomatlashtirilgan<br>bank tizimi
                </div>
                <p class="brand-desc">
                    MARS ABS — Fido Bank ning markaziy operatsion tizimi.
                    Mijozlar, hisob-kitoblar va tranzaksiyalarni boshqarish uchun yagona platforma.
                </p>

                <div class="brand-features">
                    <div class="brand-feature">
                        <span class="brand-feature-dot"></span>
                        Mijozlar ma'lumotlar bazasi (CIF)
                    </div>
                    <div class="brand-feature">
                        <span class="brand-feature-dot"></span>
                        Hujjatlar va tasdiqlash jarayonlari
                    </div>
                    <div class="brand-feature">
                        <span class="brand-feature-dot"></span>
                        PEP va muddati o'tgan hujjatlar monitoring
                    </div>
                    <div class="brand-feature">
                        <span class="brand-feature-dot"></span>
                        Rol asosida kirish boshqaruvi
                    </div>
                </div>
            </div>

            <div class="brand-bottom">
                &copy; 2026 Fido Bank
            </div>
        </div>

        <%-- ==================== O'NG: FORMA PANEL ==================== --%>
        <div class="login-form-panel">
            <div class="login-form-inner">

                <h1 class="login-form-title">Tizimga kirish</h1>
                <p class="login-form-sub">MARS ABS hisobingiz ma'lumotlarini kiriting</p>

                <%-- Xato xabari --%>
                <% if (errorMessage != null) { %>
                <div class="login-error" role="alert">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <%= errorMessage %>
                </div>
                <% } %>

                <form method="post" action="<%= __cp %>/abs/login.jsp" novalidate>

                    <div class="form-group">
                        <label for="username">Foydalanuvchi nomi</label>
                        <input
                            type="text"
                            id="username"
                            name="username"
                            class="form-control"
                            placeholder="Login kiriting"
                            autocomplete="username"
                            autocapitalize="none"
                            spellcheck="false"
                            required
                            autofocus>
                    </div>

                    <div class="form-group">
                        <label for="password">Parol</label>
                        <input
                            type="password"
                            id="password"
                            name="password"
                            class="form-control"
                            placeholder="Parolni kiriting"
                            autocomplete="current-password"
                            required>
                    </div>

                    <button type="submit" class="login-submit">
                        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
                            <polyline points="10 17 15 12 10 7"/>
                            <line x1="15" y1="12" x2="3" y2="12"/>
                        </svg>
                        Kirish
                    </button>

                </form>

                <div class="login-divider"></div>

                <div class="login-form-footer">
                    Fido Bank &copy; 2026 &middot; MARS ABS
                </div>
            </div>
        </div>

    </div>
</body>
</html>

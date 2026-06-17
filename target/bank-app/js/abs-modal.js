/**
 * ABS Modal — add/edit/view formalarini modal oynada ochish
 *
 * Ishlash printsipi (servlet/API YO'Q — toza JSP):
 *   1. data-modal atributli linkni bosganda, target JSP sahifa
 *      "?modal=1" parametri bilan fetch qilinadi (server faqat
 *      kontent fragmentini qaytaradi — navbar/footer'siz).
 *   2. Fragment modal ichiga joylanadi. Modal o'lchami forma
 *      kattaligiga qarab avtomatik tanlanadi (sm/md/lg/xl).
 *   3. Modal ichidagi forma yuborilganda, fetch orqali POST qilinadi:
 *        - muvaffaqiyat (server redirect qiladi) → response.url ga o'tiladi
 *        - xato (server formani qayta chizadi) → modal yangilanadi
 *
 * Ishlatish (JSP):
 *   <a href="customer-create.jsp" data-modal data-modal-title="Yangi mijoz">+ Yangi</a>
 *   <a href="customer-detail.jsp?id=5" data-modal data-modal-size="lg">Ko'rish</a>
 *
 * JS API:
 *   ABSModal.open('customer-create.jsp', { title: 'Yangi mijoz', size: 'lg' });
 *   ABSModal.close();
 */
var ABSModal = (function() {
    'use strict';

    var overlay = null;
    var dialog = null;
    var bodyEl = null;
    var titleEl = null;
    var lastFocused = null;
    var currentSrc = null;

    // ============================================================
    //  MODAL SKELETON — bir marta yaratiladi
    // ============================================================
    function ensureModal() {
        if (overlay) return;

        overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        overlay.innerHTML =
            '<div class="modal-dialog" role="dialog" aria-modal="true">' +
                '<div class="modal-header">' +
                    '<h2 class="modal-title"></h2>' +
                    '<button type="button" class="modal-close" aria-label="Yopish">&times;</button>' +
                '</div>' +
                '<div class="modal-body"></div>' +
            '</div>';

        document.body.appendChild(overlay);
        dialog = overlay.querySelector('.modal-dialog');
        bodyEl = overlay.querySelector('.modal-body');
        titleEl = overlay.querySelector('.modal-title');

        // Backdrop bosilganda yopish
        overlay.addEventListener('mousedown', function(e) {
            if (e.target === overlay) close();
        });
        // Yopish tugmasi
        overlay.querySelector('.modal-close').addEventListener('click', close);
    }

    // ============================================================
    //  OPEN — sahifani fetch qilib modalga joylash
    // ============================================================
    function open(url, opts) {
        opts = opts || {};
        ensureModal();
        lastFocused = document.activeElement;
        currentSrc = url;

        // Sarlavha
        titleEl.textContent = opts.title || 'Yuklanmoqda...';

        // Boshlang'ich o'lcham (keyin auto-tuzatiladi)
        setSize(opts.size || 'md');

        // Loading holati
        bodyEl.innerHTML =
            '<div class="modal-loading"><div class="modal-spinner"></div>Yuklanmoqda...</div>';

        // Modalni ko'rsatish
        document.body.classList.add('modal-open');
        requestAnimationFrame(function() { overlay.classList.add('open'); });

        // Fragmentni yuklash
        var fetchUrl = appendParam(url, 'modal', '1');
        fetch(fetchUrl, { headers: { 'X-Requested-With': 'fetch' }, credentials: 'same-origin' })
            .then(function(r) {
                // Sessiya tugagan bo'lsa login'ga redirect bo'ladi
                if (r.redirected && /login\.jsp/.test(r.url)) {
                    window.location.href = r.url;
                    return null;
                }
                return r.text();
            })
            .then(function(html) {
                if (html === null) return;
                injectContent(html, opts);
            })
            .catch(function(err) {
                bodyEl.innerHTML = '<div class="alert alert-danger">Yuklashda xatolik: ' +
                    esc(err.message) + '</div>';
            });
    }

    // ============================================================
    //  CONTENT INJECT — fragmentni modalga joylash
    // ============================================================
    function injectContent(html, opts) {
        // Fragment to'liq sahifa bo'lsa, faqat body ichini olamiz
        var temp = document.createElement('div');
        temp.innerHTML = extractFragment(html);

        // Sarlavhani aniqlash: data-modal-title > page-header h1 > opts
        var pageH1 = temp.querySelector('.page-header h1');
        if (!opts.title && pageH1) {
            titleEl.textContent = pageH1.textContent.trim();
        } else if (opts.title) {
            titleEl.textContent = opts.title;
        }

        bodyEl.innerHTML = '';
        while (temp.firstChild) {
            bodyEl.appendChild(temp.firstChild);
        }

        // O'lchamni kontentga qarab moslash (agar aniq berilmagan bo'lsa)
        if (!opts.size) {
            autoSize();
        }

        bindForms();
        focusFirst();
        if (window.ABS && ABS.init) {
            // Yangi kontentdagi validatsiya/telefon input'larni qayta ulash
            reinitPlugins();
        }
    }

    // To'liq HTML kelса <body>...</body> ichini ajratib olish
    function extractFragment(html) {
        var m = html.match(/<body[^>]*>([\s\S]*)<\/body>/i);
        return m ? m[1] : html;
    }

    // ============================================================
    //  AUTO-SIZE — forma kattaligiga qarab modal o'lchami
    // ============================================================
    function autoSize() {
        var sections = bodyEl.querySelectorAll('.form-section').length;
        var rows = bodyEl.querySelectorAll('.form-row, .form-row-3').length;
        var hasTabs = bodyEl.querySelector('.tabs') !== null;
        var detailGrid = bodyEl.querySelector('.detail-grid, .detail-grid-wide') !== null;

        var size = 'md';
        if (hasTabs || sections >= 3 || rows >= 5) {
            size = 'lg';
        } else if (sections >= 5 || rows >= 9) {
            size = 'xl';
        } else if (sections === 0 && rows <= 1 && !detailGrid) {
            size = 'sm';
        }
        setSize(size);
    }

    function setSize(size) {
        dialog.classList.remove('modal-sm', 'modal-md', 'modal-lg', 'modal-xl');
        dialog.classList.add('modal-' + size);
    }

    // ============================================================
    //  FORM HANDLING — modal ichidagi formalarni AJAX bilan yuborish
    // ============================================================
    function bindForms() {
        var forms = bodyEl.querySelectorAll('form');
        forms.forEach(function(form) {
            form.addEventListener('submit', function(e) {
                e.preventDefault();
                submitForm(form);
            });
        });

        // "Ortga" / "Bekor qilish" linklari modalni yopsin
        bodyEl.querySelectorAll('a.btn').forEach(function(a) {
            var href = a.getAttribute('href') || '';
            if (/-list\.jsp/.test(href) && !a.hasAttribute('data-modal')) {
                a.addEventListener('click', function(e) {
                    e.preventDefault();
                    close();
                });
            }
        });
    }

    function submitForm(form) {
        // Mijoz tomonida validatsiya (ABS.initValidation bilan bir xil mantiq)
        if (!validateForm(form)) return;

        var submitBtn = form.querySelector('button[type="submit"]');
        var origText = submitBtn ? submitBtn.textContent : null;
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Saqlanmoqda...';
        }

        var action = form.getAttribute('action') || currentSrc;
        var postUrl = appendParam(action, 'modal', '1');

        fetch(postUrl, {
            method: 'POST',
            body: new FormData(form),
            headers: { 'X-Requested-With': 'fetch' },
            credentials: 'same-origin'
        })
        .then(function(r) {
            // Server redirect qildi → muvaffaqiyat
            if (r.redirected) {
                if (/login\.jsp/.test(r.url)) {
                    window.location.href = r.url;
                    return null;
                }
                // Muvaffaqiyat — server ko'rsatgan manzilga o'tamiz
                window.location.href = r.url;
                return null;
            }
            return r.text();
        })
        .then(function(html) {
            if (html === null) return;
            // Redirect bo'lmadi → xato bor, formani qayta chizamiz
            injectContent(html, {});
        })
        .catch(function(err) {
            if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = origText; }
            showModalError('Saqlashda xatolik: ' + err.message);
        });
    }

    function validateForm(form) {
        var valid = true;
        form.querySelectorAll('[required]').forEach(function(input) {
            if (!input.value.trim()) {
                input.classList.add('is-invalid');
                valid = false;
            } else {
                input.classList.remove('is-invalid');
            }
        });
        if (!valid) showModalError('Iltimos, barcha majburiy maydonlarni to\'ldiring');
        return valid;
    }

    function showModalError(msg) {
        var existing = bodyEl.querySelector('.modal-inline-error');
        if (existing) existing.remove();
        var div = document.createElement('div');
        div.className = 'alert alert-danger modal-inline-error';
        div.textContent = msg;
        bodyEl.insertBefore(div, bodyEl.firstChild);
        bodyEl.scrollTop = 0;
    }

    function reinitPlugins() {
        // Telefon input'lar
        bodyEl.querySelectorAll('input[type="tel"]').forEach(function(input) {
            input.addEventListener('input', function() {
                var val = input.value.replace(/[^\d+]/g, '');
                if (val && !val.startsWith('+')) val = '+' + val;
                input.value = val;
            });
        });
        // Tab'lar (modal ichida)
        if (window.ABS && ABS.switchTab) {
            bodyEl.querySelectorAll('.tabs .tab-btn').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    var target = btn.getAttribute('data-tab');
                    var container = btn.closest('.tabs');
                    ABS.switchTab(target, container);
                });
            });
        }
    }

    // ============================================================
    //  CLOSE
    // ============================================================
    function close() {
        if (!overlay || !overlay.classList.contains('open')) return;
        overlay.classList.remove('open');
        document.body.classList.remove('modal-open');
        setTimeout(function() {
            bodyEl.innerHTML = '';
            currentSrc = null;
            if (lastFocused && lastFocused.focus) lastFocused.focus();
        }, 180);
    }

    function isOpen() {
        return overlay && overlay.classList.contains('open');
    }

    // ============================================================
    //  FOCUS MANAGEMENT
    // ============================================================
    function focusFirst() {
        var first = bodyEl.querySelector(
            'input:not([type=hidden]):not([disabled]), select, textarea, button[type=submit]');
        if (first) {
            try { first.focus(); } catch (e) {}
        }
    }

    // Focus trap + Esc
    function onKeydown(e) {
        if (!isOpen()) return;
        if (e.key === 'Escape') {
            e.preventDefault();
            close();
            return;
        }
        if (e.key === 'Tab') {
            var focusables = dialog.querySelectorAll(
                'a[href], button:not([disabled]), input:not([type=hidden]):not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])');
            if (focusables.length === 0) return;
            var firstEl = focusables[0];
            var lastEl = focusables[focusables.length - 1];
            if (e.shiftKey && document.activeElement === firstEl) {
                e.preventDefault(); lastEl.focus();
            } else if (!e.shiftKey && document.activeElement === lastEl) {
                e.preventDefault(); firstEl.focus();
            }
        }
    }

    // ============================================================
    //  AUTO-WIRE — data-modal linklarini ulash
    // ============================================================
    function initTriggers() {
        document.addEventListener('click', function(e) {
            var trigger = e.target.closest('[data-modal]');
            if (!trigger) return;
            // Faqat link/button bo'lsa
            var url = trigger.getAttribute('href') || trigger.getAttribute('data-modal-url');
            if (!url) return;
            e.preventDefault();
            open(url, {
                title: trigger.getAttribute('data-modal-title') || null,
                size: trigger.getAttribute('data-modal-size') || null
            });
        });
        document.addEventListener('keydown', onKeydown);
    }

    // ============================================================
    //  HELPERS
    // ============================================================
    function appendParam(url, key, val) {
        var sep = url.indexOf('?') >= 0 ? '&' : '?';
        return url + sep + key + '=' + encodeURIComponent(val);
    }

    function esc(s) {
        if (s == null) return '';
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    // Init
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTriggers);
    } else {
        initTriggers();
    }

    return {
        open: open,
        close: close,
        isOpen: isOpen
    };
})();

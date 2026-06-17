/**
 * ABS Core JS Library
 * MARS ABS tizimi uchun umumiy JavaScript funksiyalar
 */
var ABS = (function() {
    'use strict';

    // ============================================================
    //  TABS — sahifadagi tab'lar boshqaruvi
    // ============================================================
    function initTabs(containerSelector) {
        var container = document.querySelector(containerSelector || '.tabs');
        if (!container) return;
        var btns = container.querySelectorAll('.tab-btn');
        btns.forEach(function(btn) {
            btn.addEventListener('click', function() {
                var target = btn.getAttribute('data-tab');
                switchTab(target, container);
            });
        });
    }

    function switchTab(tabId, container) {
        // Deactivate all tabs
        document.querySelectorAll('.tab-content').forEach(function(el) {
            el.classList.remove('active');
        });
        var tabsContainer = container || document.querySelector('.tabs');
        if (tabsContainer) {
            tabsContainer.querySelectorAll('.tab-btn').forEach(function(el) {
                el.classList.remove('active');
            });
        }
        // Activate target
        var target = document.getElementById('tab-' + tabId);
        if (target) target.classList.add('active');
        if (tabsContainer) {
            var btn = tabsContainer.querySelector('[data-tab="' + tabId + '"]');
            if (btn) btn.classList.add('active');
        }
    }

    // ============================================================
    //  ALERTS — xabarlarni ko'rsatish va auto-yashirish
    // ============================================================
    function showAlert(message, type, duration) {
        type = type || 'success';
        duration = duration || 5000;

        var alert = document.createElement('div');
        alert.className = 'alert alert-' + type;
        alert.innerHTML = message + '<span class="alert-close" onclick="this.parentElement.remove()">&times;</span>';
        alert.style.position = 'relative';

        var container = document.querySelector('.content') || document.querySelector('.container');
        if (container) {
            var header = container.querySelector('.page-header');
            if (header) {
                container.insertBefore(alert, header);
            } else {
                container.insertBefore(alert, container.firstChild);
            }
        }

        if (duration > 0) {
            setTimeout(function() {
                if (alert.parentElement) {
                    alert.style.opacity = '0';
                    alert.style.transition = 'opacity 0.3s';
                    setTimeout(function() { alert.remove(); }, 300);
                }
            }, duration);
        }
    }

    // URL dan msg/err parametrlarini o'qib alert ko'rsatish
    function showUrlAlerts() {
        var params = new URLSearchParams(window.location.search);
        var msg = params.get('msg');
        var err = params.get('err');

        if (msg) showAlert(msg, 'success');
        if (err) showAlert(err, 'danger');

        // URL'dan msg/err ni tozalash (history)
        if (msg || err) {
            params.delete('msg');
            params.delete('err');
            var newUrl = window.location.pathname;
            var remaining = params.toString();
            if (remaining) newUrl += '?' + remaining;
            window.history.replaceState({}, '', newUrl);
        }
    }

    // ============================================================
    //  CONFIRM — tasdiqlash dialoglar
    // ============================================================
    function confirmAction(message, callback) {
        if (confirm(message)) {
            callback();
        }
    }

    function confirmSubmit(form, message) {
        if (!message) message = 'Ishonchingiz komilmi?';
        form.addEventListener('submit', function(e) {
            if (!confirm(message)) {
                e.preventDefault();
            }
        });
    }

    // data-confirm atributi bor barcha formalarni avtomatik ulash
    function initConfirmForms() {
        document.querySelectorAll('form[data-confirm]').forEach(function(form) {
            var msg = form.getAttribute('data-confirm');
            confirmSubmit(form, msg);
        });
    }

    // ============================================================
    //  FORM VALIDATION — forma tekshiruvi
    // ============================================================
    function initValidation() {
        document.querySelectorAll('form[data-validate]').forEach(function(form) {
            form.addEventListener('submit', function(e) {
                var valid = true;
                form.querySelectorAll('[required]').forEach(function(input) {
                    if (!input.value.trim()) {
                        input.classList.add('is-invalid');
                        valid = false;
                    } else {
                        input.classList.remove('is-invalid');
                    }
                });
                // Pattern validation
                form.querySelectorAll('[pattern]').forEach(function(input) {
                    if (input.value.trim()) {
                        var re = new RegExp('^' + input.getAttribute('pattern') + '$');
                        if (!re.test(input.value)) {
                            input.classList.add('is-invalid');
                            valid = false;
                        }
                    }
                });
                if (!valid) {
                    e.preventDefault();
                    showAlert('Iltimos, barcha majburiy maydonlarni to\'ldiring', 'danger', 4000);
                }
            });
            // Real-time: invalid class ni olib tashlash
            form.querySelectorAll('[required]').forEach(function(input) {
                input.addEventListener('input', function() {
                    if (input.value.trim()) input.classList.remove('is-invalid');
                });
            });
        });
    }

    // ============================================================
    //  LOADING — yuklanish indikatori
    // ============================================================
    function showLoading(element) {
        if (!element) return;
        element.disabled = true;
        element.dataset.originalText = element.textContent;
        element.textContent = 'Yuklanmoqda...';
    }

    function hideLoading(element) {
        if (!element) return;
        element.disabled = false;
        if (element.dataset.originalText) {
            element.textContent = element.dataset.originalText;
        }
    }

    // Submit tugmalarini avtomatik loading holati
    function initLoadingButtons() {
        document.querySelectorAll('form').forEach(function(form) {
            form.addEventListener('submit', function() {
                var btn = form.querySelector('button[type="submit"]');
                if (btn) showLoading(btn);
            });
        });
    }

    // ============================================================
    //  TABLE — jadval yordamchi funksiyalar
    // ============================================================
    // Jadval qatorini bosganida highlight
    function initTableRowClick() {
        document.querySelectorAll('table tbody tr').forEach(function(row) {
            var link = row.querySelector('a.link');
            if (link) {
                row.style.cursor = 'pointer';
                row.addEventListener('click', function(e) {
                    // Agar tugma yoki link bosilgan bo'lsa, o'tkazib yuborish
                    if (e.target.tagName === 'A' || e.target.tagName === 'BUTTON' ||
                        e.target.closest('button') || e.target.closest('.action-buttons')) {
                        return;
                    }
                    // Modal link bo'lsa — modalda ochish
                    if (link.hasAttribute('data-modal') && window.ABSModal) {
                        ABSModal.open(link.getAttribute('href'), {
                            title: link.getAttribute('data-modal-title') || null,
                            size: link.getAttribute('data-modal-size') || null
                        });
                    } else {
                        window.location.href = link.href;
                    }
                });
            }
        });
    }

    // ============================================================
    //  GRID KEYBOARD — jadvalda klaviatura bilan navigatsiya
    //    ↑/↓  — qatorlar orasida harakat (j/k ham)
    //    Enter — tanlangan qatorni ochish (modal yoki sahifa)
    //    Home/End — birinchi/oxirgi qator
    //    /     — filtr maydoniga fokus
    //    Esc   — tanlovni bekor qilish
    // ============================================================
    function initGridKeyboard() {
        var table = document.querySelector('.table-wrapper table');
        if (!table) return;
        var tbody = table.querySelector('tbody');
        if (!tbody) return;

        var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
        // Bo'sh holat qatorini o'tkazib yuborish
        rows = rows.filter(function(r) { return !r.querySelector('.empty-state'); });
        if (rows.length === 0) return;

        var activeIdx = -1;

        function setActive(idx, scroll) {
            if (idx < 0) idx = 0;
            if (idx >= rows.length) idx = rows.length - 1;
            if (activeIdx >= 0 && rows[activeIdx]) rows[activeIdx].classList.remove('row-active');
            activeIdx = idx;
            var row = rows[activeIdx];
            if (row) {
                row.classList.add('row-active');
                if (scroll !== false) row.scrollIntoView({ block: 'nearest' });
            }
        }

        function openActive() {
            if (activeIdx < 0) return;
            var link = rows[activeIdx].querySelector('a.link');
            if (!link) return;
            if (link.hasAttribute('data-modal') && window.ABSModal) {
                ABSModal.open(link.getAttribute('href'), {
                    title: link.getAttribute('data-modal-title') || null,
                    size: link.getAttribute('data-modal-size') || null
                });
            } else {
                window.location.href = link.href;
            }
        }

        // Qatorni bosganda aktiv qilish
        rows.forEach(function(row, i) {
            row.addEventListener('mouseenter', function() {
                if (activeIdx !== i) setActive(i, false);
            });
        });

        document.addEventListener('keydown', function(e) {
            // Modal ochiq bo'lsa yoki input ichida bo'lsa — aralashmaymiz
            if (window.ABSModal && ABSModal.isOpen()) return;
            var tag = (e.target.tagName || '').toLowerCase();
            var inField = (tag === 'input' || tag === 'select' || tag === 'textarea');

            // "/" — filtr qidiruviga fokus
            if (e.key === '/' && !inField) {
                var firstFilter = document.querySelector('.filter-bar input, .filter-bar select');
                if (firstFilter) { e.preventDefault(); firstFilter.focus(); }
                return;
            }

            if (inField) return; // maydon ichida navigatsiya yo'q

            switch (e.key) {
                case 'ArrowDown':
                case 'j':
                    e.preventDefault();
                    setActive(activeIdx < 0 ? 0 : activeIdx + 1);
                    break;
                case 'ArrowUp':
                case 'k':
                    e.preventDefault();
                    setActive(activeIdx < 0 ? 0 : activeIdx - 1);
                    break;
                case 'Home':
                    e.preventDefault(); setActive(0);
                    break;
                case 'End':
                    e.preventDefault(); setActive(rows.length - 1);
                    break;
                case 'Enter':
                    if (activeIdx >= 0) { e.preventDefault(); openActive(); }
                    break;
                case 'Escape':
                    if (activeIdx >= 0) {
                        rows[activeIdx].classList.remove('row-active');
                        activeIdx = -1;
                    }
                    break;
            }
        });
    }

    // ============================================================
    //  FORMAT — formatlash yordamchilari
    // ============================================================
    function formatPhone(input) {
        input.addEventListener('input', function() {
            var val = input.value.replace(/[^\d+]/g, '');
            if (val && !val.startsWith('+')) val = '+' + val;
            input.value = val;
        });
    }

    function initPhoneInputs() {
        document.querySelectorAll('input[type="tel"]').forEach(function(input) {
            formatPhone(input);
        });
    }

    // ============================================================
    //  INIT — sahifa yuklanganda barcha modullarni ishga tushirish
    // ============================================================
    function init() {
        showUrlAlerts();
        initTabs();
        initConfirmForms();
        initValidation();
        initLoadingButtons();
        initTableRowClick();
        initGridKeyboard();
        initPhoneInputs();
    }

    // DOM tayyor bo'lganda init
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Public API
    return {
        switchTab: switchTab,
        showAlert: showAlert,
        confirmAction: confirmAction,
        confirmSubmit: confirmSubmit,
        showLoading: showLoading,
        hideLoading: hideLoading,
        init: init
    };
})();

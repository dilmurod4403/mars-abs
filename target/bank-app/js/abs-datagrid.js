/**
 * ABS DataGrid Tools — HTML-mode datagrid uchun klient funksiyalari
 *
 * TableTag.renderHtml() chiqargan hook'larni ishlatadi:
 *   .grid-root[data-grid][data-selectable]
 *     [data-grid-density]        — zichlik (compact/keng) toggle
 *     [data-col-toggle]/[data-col-list]/[data-col-index] — ustun ko'rsatish/yashirish
 *     [data-grid-export=csv|excel] — eksport
 *     [data-page-size]           — sahifa o'lchami (select → navigate)
 *     [data-select-all]/[data-select-row] — qator tanlash
 *     [data-bulk-toolbar]/[data-bulk-count]/[data-bulk-action] — bulk panel
 *
 * Saralash va sahifa o'lchami SERVER tomonda (link/navigate) — bu fayl
 * faqat klient-interaktivlik (zichlik, ustun, eksport, tanlash) ni boshqaradi.
 */
(function () {
    'use strict';

    function init() {
        document.querySelectorAll('.grid-root').forEach(setupGrid);
    }

    function setupGrid(root) {
        var gridId = root.getAttribute('data-grid') || 'grid';
        var table = root.querySelector('table');
        if (!table) return;

        applyDensity(root, gridId);
        applyHiddenCols(root, gridId);

        bindDensity(root, gridId);
        bindColumnMenu(root, gridId);
        bindExport(root, table);
        bindPageSize(root);
        if (root.getAttribute('data-selectable') === 'true') {
            bindSelection(root, table);
        }
    }

    // ============================================================
    //  ZICHLIK (compact / keng)
    // ============================================================
    function bindDensity(root, gridId) {
        var btn = root.querySelector('[data-grid-density]');
        if (!btn) return;
        btn.addEventListener('click', function () {
            var compact = root.classList.toggle('grid-compact');
            try { localStorage.setItem('grid-density-' + gridId, compact ? 'compact' : 'normal'); } catch (e) {}
        });
    }
    function applyDensity(root, gridId) {
        var v = null;
        try { v = localStorage.getItem('grid-density-' + gridId); } catch (e) {}
        if (v === 'compact') root.classList.add('grid-compact');
    }

    // ============================================================
    //  USTUN KO'RSATISH / YASHIRISH
    // ============================================================
    function bindColumnMenu(root, gridId) {
        var toggle = root.querySelector('[data-col-toggle]');
        var list = root.querySelector('[data-col-list]');
        if (!toggle || !list) return;

        toggle.addEventListener('click', function (e) {
            e.stopPropagation();
            var open = list.hasAttribute('hidden');
            if (open) { list.removeAttribute('hidden'); toggle.setAttribute('aria-expanded', 'true'); }
            else { list.setAttribute('hidden', ''); toggle.setAttribute('aria-expanded', 'false'); }
        });
        // tashqariga bosilsa yopish
        document.addEventListener('click', function (e) {
            if (!list.contains(e.target) && e.target !== toggle && !toggle.contains(e.target)) {
                list.setAttribute('hidden', ''); toggle.setAttribute('aria-expanded', 'false');
            }
        });

        list.querySelectorAll('[data-col-index]').forEach(function (cb) {
            cb.addEventListener('change', function () {
                var idx = parseInt(cb.getAttribute('data-col-index'), 10);
                setColVisible(root, idx, cb.checked);
                saveHiddenCols(root, gridId);
            });
        });
    }

    function colOffset(root) {
        // selectable bo'lsa birinchi ustun checkbox — data ustunlar 1 dan boshlanadi
        return root.getAttribute('data-selectable') === 'true' ? 1 : 0;
    }

    function setColVisible(root, dataIdx, visible) {
        var cellIdx = dataIdx + colOffset(root); // 0-based cell index
        var table = root.querySelector('table');
        // header
        var ths = table.querySelectorAll('thead th');
        if (ths[cellIdx]) ths[cellIdx].classList.toggle('col-hidden', !visible);
        // body
        table.querySelectorAll('tbody tr').forEach(function (tr) {
            var cells = tr.children;
            if (cells[cellIdx]) cells[cellIdx].classList.toggle('col-hidden', !visible);
        });
    }

    function saveHiddenCols(root, gridId) {
        var hidden = [];
        root.querySelectorAll('[data-col-index]').forEach(function (cb) {
            if (!cb.checked) hidden.push(parseInt(cb.getAttribute('data-col-index'), 10));
        });
        try { localStorage.setItem('grid-cols-' + gridId, JSON.stringify(hidden)); } catch (e) {}
    }

    function applyHiddenCols(root, gridId) {
        var hidden = [];
        try {
            var raw = localStorage.getItem('grid-cols-' + gridId);
            if (raw) hidden = JSON.parse(raw) || [];
        } catch (e) {}
        hidden.forEach(function (idx) {
            setColVisible(root, idx, false);
            var cb = root.querySelector('[data-col-index="' + idx + '"]');
            if (cb) cb.checked = false;
        });
    }

    // ============================================================
    //  EKSPORT (CSV / Excel)
    // ============================================================
    function bindExport(root, table) {
        root.querySelectorAll('[data-grid-export]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var type = btn.getAttribute('data-grid-export');
                var data = readTable(root, table, false);
                if (type === 'excel') exportExcel(data, gridName(root));
                else exportCsv(data, gridName(root));
            });
        });
    }

    function gridName(root) {
        return (root.getAttribute('data-grid') || 'export');
    }

    /**
     * Jadvaldan ma'lumot o'qiydi. selectedOnly=true bo'lsa faqat belgilangan qatorlar.
     * Yashirilgan ustunlar va tanlash/checkbox ustuni o'tkazib yuboriladi.
     */
    function readTable(root, table, selectedOnly) {
        var offset = colOffset(root);
        var headerCells = Array.prototype.slice.call(table.querySelectorAll('thead th'));
        var headers = [];
        var keepIdx = [];
        headerCells.forEach(function (th, i) {
            if (i < offset) return;                       // select ustuni
            if (th.classList.contains('col-hidden')) return; // yashirilgan
            keepIdx.push(i);
            headers.push(cellText(th));
        });

        var rows = [];
        table.querySelectorAll('tbody tr').forEach(function (tr) {
            if (tr.querySelector('.empty-state')) return;
            if (selectedOnly) {
                var cb = tr.querySelector('[data-select-row]');
                if (!cb || !cb.checked) return;
            }
            var cells = tr.children;
            var row = keepIdx.map(function (i) { return cells[i] ? cellText(cells[i]) : ''; });
            rows.push(row);
        });
        return { headers: headers, rows: rows };
    }

    function cellText(cell) {
        return (cell.textContent || '').replace(/\s+/g, ' ').trim();
    }

    function exportCsv(data, name) {
        var lines = [];
        lines.push(data.headers.map(csvCell).join(','));
        data.rows.forEach(function (r) { lines.push(r.map(csvCell).join(',')); });
        var csv = '﻿' + lines.join('\r\n'); // UTF-8 BOM
        download(new Blob([csv], { type: 'text/csv;charset=utf-8;' }), name + '.csv');
    }
    function csvCell(v) {
        v = (v == null) ? '' : String(v);
        if (/[",\r\n]/.test(v)) v = '"' + v.replace(/"/g, '""') + '"';
        return v;
    }

    function exportExcel(data, name) {
        var html = '<html xmlns:x="urn:schemas-microsoft-com:office:excel"><head><meta charset="utf-8"></head><body><table border="1">';
        html += '<tr>' + data.headers.map(function (h) { return '<th>' + escHtml(h) + '</th>'; }).join('') + '</tr>';
        data.rows.forEach(function (r) {
            html += '<tr>' + r.map(function (c) { return '<td>' + escHtml(c) + '</td>'; }).join('') + '</tr>';
        });
        html += '</table></body></html>';
        download(new Blob(['﻿' + html], { type: 'application/vnd.ms-excel;charset=utf-8;' }), name + '.xls');
    }

    function download(blob, filename) {
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url; a.download = filename;
        document.body.appendChild(a); a.click();
        document.body.removeChild(a);
        setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
    }

    // ============================================================
    //  SAHIFA O'LCHAMI (select → navigate)
    // ============================================================
    function bindPageSize(root) {
        var sel = root.querySelector('[data-page-size]');
        if (!sel) return;
        sel.addEventListener('change', function () {
            if (sel.value) window.location.href = sel.value;
        });
    }

    // ============================================================
    //  QATOR TANLASH + BULK
    // ============================================================
    function bindSelection(root, table) {
        var selectAll = table.querySelector('[data-select-all]');
        var bulkBar = root.querySelector('[data-bulk-toolbar]');
        var countEl = root.querySelector('[data-bulk-count]');

        function rowBoxes() {
            return Array.prototype.slice.call(table.querySelectorAll('[data-select-row]'));
        }
        function update() {
            var boxes = rowBoxes();
            var checked = boxes.filter(function (b) { return b.checked; });
            boxes.forEach(function (b) {
                b.closest('tr').classList.toggle('row-selected', b.checked);
            });
            if (countEl) countEl.textContent = checked.length;
            if (bulkBar) {
                if (checked.length > 0) bulkBar.removeAttribute('hidden');
                else bulkBar.setAttribute('hidden', '');
            }
            if (selectAll) {
                selectAll.checked = boxes.length > 0 && checked.length === boxes.length;
                selectAll.indeterminate = checked.length > 0 && checked.length < boxes.length;
            }
        }

        if (selectAll) {
            selectAll.addEventListener('change', function () {
                rowBoxes().forEach(function (b) { b.checked = selectAll.checked; });
                update();
            });
        }
        rowBoxes().forEach(function (b) {
            b.addEventListener('change', update);
        });

        // Bulk amallar
        root.querySelectorAll('[data-bulk-action]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var action = btn.getAttribute('data-bulk-action');
                if (action === 'clear') {
                    rowBoxes().forEach(function (b) { b.checked = false; });
                    update();
                } else if (action === 'export-csv') {
                    var data = readTable(root, table, true);
                    if (data.rows.length === 0) { alert('Hech qator tanlanmagan'); return; }
                    exportCsv(data, gridName(root) + '-tanlangan');
                } else if (action === 'status') {
                    var sel = root.querySelector('[data-bulk-status-select]');
                    var status = sel ? sel.value : '';
                    if (!status) { alert('Avval yangi statusni tanlang'); return; }
                    var ids = selectedIds(root);
                    if (ids.length === 0) { alert('Hech qator tanlanmagan'); return; }
                    var saveUrl = root.getAttribute('data-save-url');
                    if (!saveUrl) { alert('saveUrl belgilanmagan'); return; }
                    var label = sel.options[sel.selectedIndex].text;
                    if (!confirm(ids.length + ' ta yozuvni "' + label + '" qilasizmi?')) return;
                    postBulk(saveUrl, { action: 'status', status: status, ids: ids.join(',') });
                } else {
                    // Boshqa bulk amallar uchun hook
                    root.dispatchEvent(new CustomEvent('grid:bulk', {
                        detail: { action: action, ids: selectedIds(root) }
                    }));
                }
            });
        });

        update();
    }

    // Tanlangan qatorlarning data-id qiymatlari
    function selectedIds(root) {
        var ids = [];
        root.querySelectorAll('[data-select-row]').forEach(function (b) {
            var id = b.getAttribute('data-id');
            if (b.checked && id) ids.push(id);
        });
        return ids;
    }

    // Bulk amalni POST orqali yuborish (form submit — toza JSP handler'ga)
    function postBulk(url, params) {
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = url;
        Object.keys(params).forEach(function (k) {
            var input = document.createElement('input');
            input.type = 'hidden'; input.name = k; input.value = params[k];
            form.appendChild(input);
        });
        document.body.appendChild(form);
        form.submit();
    }

    // ============================================================
    function escHtml(s) {
        if (s == null) return '';
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.ABSDataGrid = { init: init };
})();

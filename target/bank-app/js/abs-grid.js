/**
 * ABS DataGrid — JSON mode editable datagrid
 *
 * <t:table> mode="json" chiqargan JSON konfiguratsiyani o'qib,
 * interaktiv jadval chizadi: inline tahrirlash, qator qo'shish/o'chirish,
 * forma sifatida yuborish.
 *
 * Ishlatish (JSP):
 *   <t:table view="..." mode="json" id="myGrid">
 *       <t:col field="name" title="Nomi" editable="true" editType="text"/>
 *       <t:col field="status" title="Holat" editable="true" editType="select"
 *              editOptions="ACTIVE:Faol,BLOCKED:Bloklangan"/>
 *   </t:table>
 *
 * JS API:
 *   var grid = ABSGrid.get('myGrid');
 *   grid.getRows();           // barcha qatorlar (tahrirlangan)
 *   grid.getChangedRows();    // faqat o'zgargan qatorlar
 *   grid.addRow({...});       // yangi qator qo'shish
 *   grid.deleteRow(index);    // qator o'chirish
 *   grid.toFormData(prefix);  // FormData ga aylantirish
 */
var ABSGrid = (function() {
    'use strict';

    var grids = {};

    // ============================================================
    //  INIT — sahifa yuklanganida barcha .abs-datagrid elementlarni topish
    // ============================================================
    function initAll() {
        var containers = document.querySelectorAll('.abs-datagrid[data-config]');
        containers.forEach(function(el) {
            try {
                var config = JSON.parse(el.getAttribute('data-config'));
                var grid = new DataGrid(el, config);
                grids[el.id] = grid;
                grid.render();
            } catch (e) {
                console.error('ABSGrid: JSON parse error for #' + el.id, e);
            }
        });
    }

    // ============================================================
    //  DataGrid constructor
    // ============================================================
    function DataGrid(container, config) {
        this.container = container;
        this.config = config;
        this.columns = config.columns || [];
        this.filters = config.filters || [];
        this.rows = deepCopy(config.rows || []);
        this.originalRows = deepCopy(config.rows || []);
        this.deletedIndices = [];
        this.pagination = {
            page: config.page || 1,
            pageSize: config.pageSize || 20,
            totalRows: config.totalRows || 0,
            totalPages: config.totalPages || 0,
            baseUrl: config.baseUrl || ''
        };
        this.emptyText = config.emptyText || "Ma'lumot topilmadi";
        this.hasEditableColumns = this.columns.some(function(c) { return c.editable; });
    }

    // ============================================================
    //  RENDER
    // ============================================================
    DataGrid.prototype.render = function() {
        var html = '';

        // Row count
        html += '<div style="margin-bottom:0.75rem; font-size:0.85rem; color:var(--gray-500);">';
        html += 'Jami: <strong>' + this.pagination.totalRows + '</strong> ta yozuv';
        html += '</div>';

        // Filter bar
        if (this.filters.length > 0) {
            html += this.renderFilterBar();
        }

        // Table
        html += '<div class="card" style="padding:0;">';
        html += '<div class="table-wrapper">';
        html += '<table id="' + esc(this.container.id) + '_table">';

        // thead
        html += '<thead><tr>';
        for (var i = 0; i < this.columns.length; i++) {
            var col = this.columns[i];
            var thStyle = col.width ? ' style="width:' + col.width + '"' : '';
            html += '<th' + thStyle + '>' + esc(col.title) + '</th>';
        }
        if (this.hasEditableColumns) {
            html += '<th style="width:60px">Amal</th>';
        }
        html += '</tr></thead>';

        // tbody
        html += '<tbody>';
        if (this.rows.length === 0) {
            var colspan = this.columns.length + (this.hasEditableColumns ? 1 : 0);
            html += '<tr><td colspan="' + colspan + '" class="empty-state">';
            html += '<div class="message">' + esc(this.emptyText) + '</div>';
            html += '</td></tr>';
        } else {
            for (var r = 0; r < this.rows.length; r++) {
                html += this.renderRow(r);
            }
        }
        html += '</tbody>';
        html += '</table>';
        html += '</div></div>';

        // Add row button
        if (this.hasEditableColumns) {
            html += '<div style="margin-top:0.5rem;">';
            html += '<button type="button" class="btn btn-sm" data-grid-action="add" ';
            html += 'data-grid-id="' + esc(this.container.id) + '">+ Qo\'shish</button>';
            html += '</div>';
        }

        // Pagination
        if (this.pagination.totalPages > 1) {
            html += this.renderPagination();
        }

        this.container.innerHTML = html;
        this.bindEvents();
    };

    DataGrid.prototype.renderRow = function(index) {
        var row = this.rows[index];
        var isChanged = this.isRowChanged(index);
        var trClass = isChanged ? ' class="row-changed"' : '';
        var html = '<tr data-row-index="' + index + '"' + trClass + '>';

        for (var i = 0; i < this.columns.length; i++) {
            html += this.renderCell(index, this.columns[i], row);
        }

        if (this.hasEditableColumns) {
            html += '<td>';
            html += '<button type="button" class="btn btn-danger btn-sm" ';
            html += 'data-grid-action="delete" data-row-index="' + index + '" ';
            html += 'data-grid-id="' + esc(this.container.id) + '" title="O\'chirish">';
            html += '&times;</button>';
            html += '</td>';
        }

        html += '</tr>';
        return html;
    };

    DataGrid.prototype.renderCell = function(rowIndex, col, row) {
        var value = row[col.field];
        var displayVal = this.formatValue(value, col.format);
        var align = col.align ? ' style="text-align:' + col.align + '"' : '';
        var html = '<td' + align + '>';

        if (col.editable) {
            html += this.renderEditableCell(rowIndex, col, value);
        } else if (col.badge && value != null) {
            var badge = this.resolveBadge(col.badge, value);
            html += '<span class="badge badge-' + esc(badge.cls) + '">' + esc(badge.text) + '</span>';
        } else if (col.link && value != null) {
            var href = this.resolveLink(col.link, row);
            html += '<a href="' + esc(href) + '" class="link">' + esc(displayVal || '') + '</a>';
        } else {
            html += displayVal != null ? esc(String(displayVal)) : '';
        }

        html += '</td>';
        return html;
    };

    DataGrid.prototype.renderEditableCell = function(rowIndex, col, value) {
        var name = 'grid_' + this.container.id + '_' + rowIndex + '_' + col.field;
        var val = value != null ? value : '';

        if (col.editType === 'select') {
            var html = '<select name="' + name + '" class="form-control form-control-sm" ';
            html += 'data-grid-input data-row="' + rowIndex + '" data-field="' + col.field + '" ';
            html += 'data-grid-id="' + esc(this.container.id) + '">';
            html += '<option value="">—</option>';

            if (col.editOptions) {
                var opts = col.editOptions.split(',');
                for (var i = 0; i < opts.length; i++) {
                    var parts = opts[i].trim().split(':');
                    var optVal = parts[0];
                    var optLabel = parts.length > 1 ? parts[1] : parts[0];
                    var selected = String(val) === optVal ? ' selected' : '';
                    html += '<option value="' + esc(optVal) + '"' + selected + '>' + esc(optLabel) + '</option>';
                }
            }
            html += '</select>';
            return html;
        }

        if (col.editType === 'number') {
            return '<input type="number" name="' + name + '" class="form-control form-control-sm" ' +
                'value="' + esc(String(val)) + '" data-grid-input data-row="' + rowIndex + '" ' +
                'data-field="' + col.field + '" data-grid-id="' + esc(this.container.id) + '">';
        }

        if (col.editType === 'date') {
            var dateVal = '';
            if (val) {
                // ISO date string to yyyy-MM-dd
                var d = new Date(val);
                if (!isNaN(d.getTime())) {
                    dateVal = d.toISOString().split('T')[0];
                }
            }
            return '<input type="date" name="' + name + '" class="form-control form-control-sm" ' +
                'value="' + esc(dateVal) + '" data-grid-input data-row="' + rowIndex + '" ' +
                'data-field="' + col.field + '" data-grid-id="' + esc(this.container.id) + '">';
        }

        // default: text
        return '<input type="text" name="' + name + '" class="form-control form-control-sm" ' +
            'value="' + esc(String(val)) + '" data-grid-input data-row="' + rowIndex + '" ' +
            'data-field="' + col.field + '" data-grid-id="' + esc(this.container.id) + '">';
    };

    DataGrid.prototype.renderFilterBar = function() {
        var baseUrl = this.pagination.baseUrl || '';
        var html = '<form method="get" action="' + esc(baseUrl) + '" class="filter-bar" style="margin-bottom:1rem;">';

        for (var i = 0; i < this.filters.length; i++) {
            var f = this.filters[i];
            html += '<div class="form-group" style="margin-bottom:0;">';
            html += '<label style="font-size:0.8rem; margin-bottom:0.2rem;">' + esc(f.label) + '</label>';

            if (f.type === 'select' && f.options) {
                html += '<select name="f_' + f.field + '" class="form-control" style="min-width:120px;">';
                html += '<option value="">Barchasi</option>';
                for (var j = 0; j < f.options.length; j++) {
                    var opt = f.options[j];
                    var selected = opt[0] === f.value ? ' selected' : '';
                    html += '<option value="' + esc(opt[0]) + '"' + selected + '>' + esc(opt[1]) + '</option>';
                }
                html += '</select>';
            } else {
                html += '<input type="text" name="f_' + f.field + '" class="form-control" ';
                html += 'value="' + esc(f.value || '') + '" placeholder="' + esc(f.label) + '...">';
            }
            html += '</div>';
        }

        html += '<div class="form-group" style="margin-bottom:0; align-self:end;">';
        html += '<button type="submit" class="btn btn-primary">Qidirish</button>';
        html += '</div>';
        html += '<div class="form-group" style="margin-bottom:0; align-self:end;">';
        html += '<a href="' + esc(baseUrl) + '" class="btn">Tozalash</a>';
        html += '</div>';
        html += '</form>';
        return html;
    };

    DataGrid.prototype.renderPagination = function() {
        var p = this.pagination;
        var html = '<div class="pagination" style="margin-top:1rem;">';

        if (p.page > 1) {
            html += '<a href="' + esc(this.pageUrl(p.page - 1)) + '" class="btn btn-sm">&laquo; Oldingi</a> ';
        }

        var start = Math.max(1, p.page - 3);
        var end = Math.min(p.totalPages, p.page + 3);

        if (start > 1) {
            html += '<a href="' + esc(this.pageUrl(1)) + '" class="btn btn-sm">1</a> ';
            if (start > 2) html += '<span style="padding:0 0.3rem;">...</span> ';
        }

        for (var i = start; i <= end; i++) {
            if (i === p.page) {
                html += '<span class="btn btn-sm btn-primary">' + i + '</span> ';
            } else {
                html += '<a href="' + esc(this.pageUrl(i)) + '" class="btn btn-sm">' + i + '</a> ';
            }
        }

        if (end < p.totalPages) {
            if (end < p.totalPages - 1) html += '<span style="padding:0 0.3rem;">...</span> ';
            html += '<a href="' + esc(this.pageUrl(p.totalPages)) + '" class="btn btn-sm">' + p.totalPages + '</a> ';
        }

        if (p.page < p.totalPages) {
            html += '<a href="' + esc(this.pageUrl(p.page + 1)) + '" class="btn btn-sm">Keyingi &raquo;</a>';
        }

        html += '</div>';
        return html;
    };

    // ============================================================
    //  EVENTS
    // ============================================================
    DataGrid.prototype.bindEvents = function() {
        var self = this;
        var gridId = this.container.id;

        // Input change → update row data
        this.container.querySelectorAll('[data-grid-input]').forEach(function(input) {
            input.addEventListener('change', function() {
                var rowIdx = parseInt(input.getAttribute('data-row'));
                var field = input.getAttribute('data-field');
                if (self.rows[rowIdx]) {
                    self.rows[rowIdx][field] = input.value;
                    // Highlight changed row
                    var tr = input.closest('tr');
                    if (tr && self.isRowChanged(rowIdx)) {
                        tr.classList.add('row-changed');
                    }
                }
            });
        });

        // Delete button
        this.container.querySelectorAll('[data-grid-action="delete"]').forEach(function(btn) {
            btn.addEventListener('click', function() {
                var rowIdx = parseInt(btn.getAttribute('data-row-index'));
                if (confirm("Bu qatorni o'chirasizmi?")) {
                    self.deleteRow(rowIdx);
                }
            });
        });

        // Add button
        this.container.querySelectorAll('[data-grid-action="add"]').forEach(function(btn) {
            btn.addEventListener('click', function() {
                self.addRow({});
            });
        });
    };

    // ============================================================
    //  PUBLIC API
    // ============================================================

    /** Barcha qatorlarni qaytarish (tahrirlangan holatda) */
    DataGrid.prototype.getRows = function() {
        return deepCopy(this.rows);
    };

    /** Faqat o'zgargan qatorlarni qaytarish */
    DataGrid.prototype.getChangedRows = function() {
        var changed = [];
        for (var i = 0; i < this.rows.length; i++) {
            if (this.isRowChanged(i)) {
                var row = deepCopy(this.rows[i]);
                row._rowIndex = i;
                row._isNew = i >= this.originalRows.length;
                changed.push(row);
            }
        }
        return changed;
    };

    /** O'chirilgan qatorlar indekslari */
    DataGrid.prototype.getDeletedIndices = function() {
        return this.deletedIndices.slice();
    };

    /** Yangi qator qo'shish */
    DataGrid.prototype.addRow = function(rowData) {
        var newRow = {};
        for (var i = 0; i < this.columns.length; i++) {
            newRow[this.columns[i].field] = rowData[this.columns[i].field] || null;
        }
        this.rows.push(newRow);
        this.render();
    };

    /** Qator o'chirish */
    DataGrid.prototype.deleteRow = function(index) {
        if (index >= 0 && index < this.rows.length) {
            if (index < this.originalRows.length) {
                this.deletedIndices.push(index);
            }
            this.rows.splice(index, 1);
            this.render();
        }
    };

    /** Qator o'zgarganmi tekshirish */
    DataGrid.prototype.isRowChanged = function(index) {
        if (index >= this.originalRows.length) return true; // new row
        var orig = this.originalRows[index];
        var curr = this.rows[index];
        if (!orig || !curr) return false;
        for (var key in curr) {
            if (String(curr[key] || '') !== String(orig[key] || '')) return true;
        }
        return false;
    };

    /**
     * Forma uchun ma'lumotni tayyorlash.
     * Har bir tahrirlangan qatorni rows[0].field=value formatda qaytaradi.
     */
    DataGrid.prototype.toFormData = function(prefix) {
        prefix = prefix || 'rows';
        var params = {};
        for (var i = 0; i < this.rows.length; i++) {
            var row = this.rows[i];
            for (var key in row) {
                params[prefix + '[' + i + '].' + key] = row[key] != null ? String(row[key]) : '';
            }
        }
        params[prefix + '_count'] = String(this.rows.length);
        if (this.deletedIndices.length > 0) {
            params[prefix + '_deleted'] = this.deletedIndices.join(',');
        }
        return params;
    };

    /**
     * Hidden input'lar yaratib formaga qo'shish.
     * @param {HTMLFormElement} form — target form
     * @param {string} prefix — param nomi prefiksi (default: 'rows')
     */
    DataGrid.prototype.appendToForm = function(form, prefix) {
        var data = this.toFormData(prefix);
        for (var key in data) {
            var input = document.createElement('input');
            input.type = 'hidden';
            input.name = key;
            input.value = data[key];
            form.appendChild(input);
        }
    };

    // ============================================================
    //  HELPERS
    // ============================================================

    DataGrid.prototype.formatValue = function(value, format) {
        if (value == null) return null;
        if (format && value) {
            // Simple date formatting
            if (typeof value === 'string' && value.indexOf('T') > 0) {
                var d = new Date(value);
                if (!isNaN(d.getTime())) {
                    return formatDate(d, format);
                }
            }
        }
        return String(value);
    };

    DataGrid.prototype.resolveBadge = function(badgeStr, value) {
        var strVal = String(value);
        if (badgeStr === 'true') {
            return { text: strVal, cls: strVal.toLowerCase() };
        }
        var mappings = badgeStr.split(',');
        for (var i = 0; i < mappings.length; i++) {
            var parts = mappings[i].trim().split(':');
            if (parts[0] === strVal) {
                return {
                    text: parts.length >= 3 ? parts[1] : strVal,
                    cls: parts.length >= 3 ? parts[2] : (parts.length >= 2 ? parts[1] : strVal.toLowerCase())
                };
            }
        }
        return { text: strVal, cls: strVal.toLowerCase() };
    };

    DataGrid.prototype.resolveLink = function(template, row) {
        var result = template;
        for (var key in row) {
            result = result.replace('{' + key + '}', row[key] != null ? row[key] : '');
        }
        return result;
    };

    DataGrid.prototype.pageUrl = function(targetPage) {
        var url = this.pagination.baseUrl || '';
        url += '?page=' + targetPage;
        for (var i = 0; i < this.filters.length; i++) {
            var f = this.filters[i];
            if (f.value) {
                url += '&f_' + f.field + '=' + encodeURIComponent(f.value);
            }
        }
        return url;
    };

    function formatDate(d, fmt) {
        var day = String(d.getDate()).padStart(2, '0');
        var month = String(d.getMonth() + 1).padStart(2, '0');
        var year = d.getFullYear();
        var hours = String(d.getHours()).padStart(2, '0');
        var mins = String(d.getMinutes()).padStart(2, '0');
        return fmt.replace('dd', day).replace('MM', month).replace('yyyy', year)
                  .replace('HH', hours).replace('mm', mins);
    }

    function esc(s) {
        if (s == null) return '';
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    function deepCopy(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    // ============================================================
    //  PUBLIC API — grid instance olish
    // ============================================================
    function get(id) {
        return grids[id] || null;
    }

    // Init on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAll);
    } else {
        initAll();
    }

    return {
        get: get,
        initAll: initAll
    };
})();

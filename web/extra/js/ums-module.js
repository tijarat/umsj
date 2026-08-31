(function(window, document) {
    "use strict";

    var UMS = window.UMS = window.UMS || {};

    UMS.toIsoDate = function(ddmmyyyy) {
        var match = /^(\d{2})-(\d{2})-(\d{4})$/.exec(ddmmyyyy || "");
        return match ? match[3] + "-" + match[2] + "-" + match[1] : "";
    };

    UMS.toDisplayDate = function(isoDate) {
        var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDate || "");
        return match ? match[3] + "-" + match[2] + "-" + match[1] : "";
    };

    UMS.isValidDateText = function(value) {
        var match = /^(\d{2})-(\d{2})-(\d{4})$/.exec(value || "");
        if(!match) return false;
        var day = Number(match[1]);
        var month = Number(match[2]);
        var year = Number(match[3]);
        var date = new Date(year, month - 1, day);
        return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day;
    };

    UMS.openDatePicker = function(pickerId) {
        var picker = document.getElementById(pickerId);
        if(!picker) return;
        if(typeof picker.showPicker === "function") picker.showPicker();
        else { picker.focus(); picker.click(); }
    };

    UMS.setDateValue = function(prefix, displayValue) {
        var display = document.getElementById(prefix + "DateDisplay");
        var hidden = document.getElementById(prefix + "Date");
        var picker = document.getElementById(prefix + "DatePicker");
        if(display) display.value = displayValue || "";
        if(hidden) hidden.value = displayValue || "";
        if(picker) picker.value = UMS.toIsoDate(displayValue);
    };

    UMS.initDatePickers = function() {
        var wrappers = document.querySelectorAll(".ums-date-picker");
        Array.prototype.forEach.call(wrappers, function(wrapper) {
            var display = wrapper.querySelector(".ums-date-display");
            var picker = wrapper.querySelector(".ums-native-date");
            var button = wrapper.querySelector(".ums-date-button");
            var hidden = wrapper.querySelector('input[type="hidden"]');
            if(!display || !picker || !hidden) return;
            picker.value = UMS.toIsoDate(hidden.value || display.value);
            display.addEventListener("click", function() { UMS.openDatePicker(picker.id); });
            display.addEventListener("keydown", function(event) { if(event.key === "Enter" || event.key === " ") { event.preventDefault(); UMS.openDatePicker(picker.id); } });
            if(button) button.addEventListener("click", function() { UMS.openDatePicker(picker.id); });
            picker.addEventListener("change", function() { var value = UMS.toDisplayDate(picker.value); display.value = value; hidden.value = value; });
        });
    };

    UMS.initFlashMessages = function() {
        var flashes = document.querySelectorAll(".ums-flash-message");
        Array.prototype.forEach.call(flashes, function(flash) {
            var hideAfter = flash.classList.contains("ums-flash-error") ? 4000 : 5000;
            window.setTimeout(function() { flash.classList.add("ums-flash-hide"); window.setTimeout(function() { if(flash.parentNode) flash.parentNode.removeChild(flash); }, 250); }, hideAfter);
        });
    };

    UMS.initConfirmActions = function() {
        var actions = document.querySelectorAll("[data-ums-confirm]");
        Array.prototype.forEach.call(actions, function(action) { action.addEventListener("click", function(event) { if(!window.confirm(action.getAttribute("data-ums-confirm"))) event.preventDefault(); }); });
    };

    function parseDateValue(text) {
        var match = /(\d{2})-(\d{2})-(\d{4})/.exec(text || "");
        if(!match) return 0;
        return new Date(Number(match[3]), Number(match[2]) - 1, Number(match[1])).getTime();
    }

    function csvCell(value) {
        var text = value == null ? "" : String(value).replace(/\r?\n/g, " ").trim();
        return '"' + text.replace(/"/g, '""') + '"';
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function TableController(table) {
        this.table = table;
        this.id = table.id;
        this.rows = [];
        this.filteredRows = [];
        this.page = 1;
        this.pageSize = 10;
        this.sortColumn = -1;
        this.sortDirection = "asc";
        this.searchText = "";
        this.search = document.querySelector('[data-ums-table-search="' + this.id + '"]');
        this.exportButton = document.querySelector('[data-ums-table-export="' + this.id + '"]');
        this.pageSizeSelect = document.querySelector('[data-ums-page-size="' + this.id + '"]');
        this.pageInfo = document.querySelector('[data-ums-page-info="' + this.id + '"]');
        this.prevButton = document.querySelector('[data-ums-page-prev="' + this.id + '"]');
        this.nextButton = document.querySelector('[data-ums-page-next="' + this.id + '"]');
        this.pageNumbers = document.querySelector('[data-ums-page-numbers="' + this.id + '"]');
        this.init();
    }

    TableController.prototype.init = function() {
        var self = this;
        if(!this.table.tBodies.length) return;
        this.rows = Array.prototype.filter.call(this.table.tBodies[0].rows, function(row) { return !row.querySelector(".ums-empty-state") && !row.hasAttribute("data-ums-ignore-row"); });
        this.filteredRows = this.rows.slice();
        if(this.pageSizeSelect) this.pageSize = Number(this.pageSizeSelect.value) || 10;
        var headers = this.table.querySelectorAll("th.ums-sortable");
        Array.prototype.forEach.call(headers, function(th) { var button = th.querySelector(".ums-sort-button"); if(button) button.addEventListener("click", function() { self.sort(Number(th.getAttribute("data-column")), th.getAttribute("data-type") || "text"); }); });
        if(this.search) this.search.addEventListener("input", function() { self.searchText = self.search.value || ""; self.applySearch(); });
        if(this.exportButton) this.exportButton.addEventListener("click", function() { self.exportCsv(); });
        if(this.pageSizeSelect) this.pageSizeSelect.addEventListener("change", function() { self.pageSize = Number(self.pageSizeSelect.value) || 10; self.page = 1; self.render(); });
        if(this.prevButton) this.prevButton.addEventListener("click", function() { if(self.page > 1) { self.page--; self.render(); } });
        if(this.nextButton) this.nextButton.addEventListener("click", function() { var totalPages = Math.max(1, Math.ceil(self.filteredRows.length / self.pageSize)); if(self.page < totalPages) { self.page++; self.render(); } });
        this.render();
    };

    TableController.prototype.sort = function(column, type) {
        var self = this;
        if(this.sortColumn === column) this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
        else { this.sortColumn = column; this.sortDirection = "asc"; }
        var direction = this.sortDirection === "asc" ? 1 : -1;
        this.rows.sort(function(a, b) {
            var aCell = a.cells[column];
            var bCell = b.cells[column];
            var aValue = aCell ? (aCell.getAttribute("data-sort-value") || aCell.textContent.trim()) : "";
            var bValue = bCell ? (bCell.getAttribute("data-sort-value") || bCell.textContent.trim()) : "";
            if(type === "date") return (parseDateValue(aValue) - parseDateValue(bValue)) * direction;
            if(type === "number") return ((parseFloat(aValue) || 0) - (parseFloat(bValue) || 0)) * direction;
            return aValue.localeCompare(bValue, undefined, {numeric: true, sensitivity: "base"}) * direction;
        });
        this.rows.forEach(function(row) { row.parentNode.appendChild(row); });
        var search = this.searchText.trim().toLowerCase();
        this.filteredRows = this.rows.filter(function(row) { return !search || row.textContent.toLowerCase().indexOf(search) >= 0; });
        this.page = 1;
        this.updateSortIndicators();
        this.render();
    };

    TableController.prototype.updateSortIndicators = function() {
        var self = this;
        var headers = this.table.querySelectorAll("th.ums-sortable");
        Array.prototype.forEach.call(headers, function(th) {
            var column = Number(th.getAttribute("data-column"));
            var indicator = th.querySelector(".ums-sort-indicator");
            th.classList.remove("ums-sort-active");
            if(indicator) indicator.textContent = "↕";
            if(column === self.sortColumn) { th.classList.add("ums-sort-active"); if(indicator) indicator.textContent = self.sortDirection === "asc" ? "↑" : "↓"; }
        });
    };

    TableController.prototype.applySearch = function() {
        var search = this.searchText.trim().toLowerCase();
        this.filteredRows = this.rows.filter(function(row) { return !search || row.textContent.toLowerCase().indexOf(search) >= 0; });
        this.page = 1;
        this.render();
    };

    TableController.prototype.render = function() {
        var self = this;
        var totalRows = this.filteredRows.length;
        var totalPages = Math.max(1, Math.ceil(totalRows / this.pageSize));
        if(this.page > totalPages) this.page = totalPages;
        var start = (this.page - 1) * this.pageSize;
        var end = Math.min(start + this.pageSize, totalRows);
        this.rows.forEach(function(row) { row.style.display = "none"; });
        this.filteredRows.forEach(function(row, index) { row.style.display = index >= start && index < end ? "" : "none"; });
        if(this.pageInfo) this.pageInfo.textContent = totalRows === 0 ? "No records" : "Showing " + (start + 1) + "–" + end + " of " + totalRows;
        if(this.prevButton) this.prevButton.disabled = this.page <= 1;
        if(this.nextButton) this.nextButton.disabled = this.page >= totalPages;
        if(this.pageNumbers) { this.pageNumbers.innerHTML = ""; var current = this.page; var first = Math.max(1, current - 2); var last = Math.min(totalPages, first + 4); first = Math.max(1, last - 4); for(var page = first; page <= last; page++) { (function(pageNumber) { var button = document.createElement("button"); button.type = "button"; button.textContent = pageNumber; button.className = pageNumber === current ? "active" : ""; button.addEventListener("click", function() { self.page = pageNumber; self.render(); }); self.pageNumbers.appendChild(button); })(page); } }
    };

    TableController.prototype.exportCsv = function() {
        var rows = this.filteredRows || [];
        if(!rows.length) { window.alert("No records are available to export."); return; }
        var headers = this.table.querySelectorAll("thead th[data-export-header]");
        var exportColumns = [];
        var headerValues = [];
        Array.prototype.forEach.call(headers, function(th) { exportColumns.push(th.cellIndex); headerValues.push(csvCell(th.getAttribute("data-export-header"))); });
        var csvRows = [headerValues.join(",")];
        rows.forEach(function(row) { var values = exportColumns.map(function(index) { var cell = row.cells[index]; return csvCell(cell ? (cell.getAttribute("data-export-value") || cell.textContent.trim()) : ""); }); csvRows.push(values.join(",")); });
        var csvContent = "\uFEFF" + csvRows.join("\r\n");
        var blob = new Blob([csvContent], {type: "text/csv;charset=utf-8;"});
        var today = new Date();
        var fileDate = today.getFullYear() + "-" + pad2(today.getMonth() + 1) + "-" + pad2(today.getDate());
        var fileName = this.table.getAttribute("data-export-file") || this.id || "UMS_Export";
        var link = document.createElement("a");
        var objectUrl = URL.createObjectURL(blob);
        link.href = objectUrl;
        link.download = fileName + "_" + fileDate + ".csv";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.setTimeout(function() { URL.revokeObjectURL(objectUrl); }, 1000);
    };

    UMS.initDataTables = function() {
        var tables = document.querySelectorAll("table[data-ums-table]");
        Array.prototype.forEach.call(tables, function(table) { if(table.id) new TableController(table); });
    };

    UMS.initSearchSelects = function() {
        var selects = document.querySelectorAll("select[data-ums-search-select]");
        Array.prototype.forEach.call(selects, function(select) {
            if(select.getAttribute("data-ums-search-ready") === "Y") return;
            select.setAttribute("data-ums-search-ready", "Y");
            var wrapper = document.createElement("div");
            wrapper.className = "ums-search-select";
            var input = document.createElement("input");
            input.type = "search";
            input.className = "ums-search-select-input";
            input.autocomplete = "off";
            input.placeholder = select.getAttribute("data-search-placeholder") || "Type to search...";
            input.setAttribute("aria-label", select.getAttribute("data-search-label") || "Search options");
            var list = document.createElement("div");
            list.className = "ums-search-select-list";
            list.setAttribute("role", "listbox");
            select.parentNode.insertBefore(wrapper, select);
            wrapper.appendChild(input);
            wrapper.appendChild(list);
            wrapper.appendChild(select);
            select.classList.add("ums-search-select-native");
            var options = Array.prototype.slice.call(select.options);
            var activeIndex = -1;
            function selectedText() { var option = select.options[select.selectedIndex]; return option && option.value ? option.textContent.trim() : ""; }
            function closeList() { list.classList.remove("ums-search-select-open"); activeIndex = -1; }
            function choose(option) { select.value = option.value; input.value = option.value ? option.textContent.trim() : ""; select.dispatchEvent(new Event("change", {bubbles:true})); closeList(); }
            function render(filter) {
                var term = (filter || "").trim().toLowerCase();
                list.innerHTML = "";
                var visible = options.filter(function(option) { return option.value && (!term || option.textContent.toLowerCase().indexOf(term) >= 0 || option.value.toLowerCase().indexOf(term) >= 0); });
                visible.forEach(function(option, index) { var item = document.createElement("button"); item.type = "button"; item.className = "ums-search-select-option"; item.textContent = option.textContent.trim(); item.setAttribute("role", "option"); item.setAttribute("data-index", String(index)); if(option.value === select.value) item.classList.add("selected"); item.addEventListener("mousedown", function(event) { event.preventDefault(); choose(option); }); list.appendChild(item); });
                if(!visible.length) { var empty = document.createElement("div"); empty.className = "ums-search-select-empty"; empty.textContent = "No matching option"; list.appendChild(empty); }
                list.classList.add("ums-search-select-open");
                activeIndex = -1;
            }
            function moveActive(direction) { var items = list.querySelectorAll(".ums-search-select-option"); if(!items.length) return; activeIndex += direction; if(activeIndex < 0) activeIndex = items.length - 1; if(activeIndex >= items.length) activeIndex = 0; Array.prototype.forEach.call(items, function(item) { item.classList.remove("active"); }); items[activeIndex].classList.add("active"); items[activeIndex].scrollIntoView({block:"nearest"}); }
            input.value = selectedText();
            input.addEventListener("focus", function() { input.select(); render(""); });
            input.addEventListener("input", function() { render(input.value); });
            input.addEventListener("keydown", function(event) { if(event.key === "ArrowDown") { event.preventDefault(); if(!list.classList.contains("ums-search-select-open")) render(input.value); moveActive(1); } else if(event.key === "ArrowUp") { event.preventDefault(); moveActive(-1); } else if(event.key === "Enter" && activeIndex >= 0) { event.preventDefault(); var items = list.querySelectorAll(".ums-search-select-option"); if(items[activeIndex]) items[activeIndex].dispatchEvent(new MouseEvent("mousedown", {bubbles:true})); } else if(event.key === "Escape") { closeList(); input.value = selectedText(); } });
            input.addEventListener("blur", function() { window.setTimeout(function() { closeList(); input.value = selectedText(); }, 120); });
            select.addEventListener("change", function() { input.value = selectedText(); });
        });
    };

    UMS.initModule = function() {
        UMS.initDatePickers();
        UMS.initFlashMessages();
        UMS.initConfirmActions();
        UMS.initSearchSelects();
        UMS.initDataTables();
    };

    document.addEventListener("DOMContentLoaded", UMS.initModule);
})(window, document);

(function(window, document) {
    "use strict";

    function generateTermDetails(form) {
        var code = (form.termCode.value || "").trim().toUpperCase();
        form.termCode.value = code;
        if(!/^[SRF]\d{2}$/.test(code)) return;
        var year = "20" + code.substring(1);
        if(code.charAt(0) === "S") { form.termName.value = "Spring " + year; window.UMS.setDateValue("start", "01-01-" + year); window.UMS.setDateValue("end", "30-04-" + year); }
        else if(code.charAt(0) === "R") { form.termName.value = "Summer " + year; window.UMS.setDateValue("start", "01-05-" + year); window.UMS.setDateValue("end", "31-08-" + year); }
        else if(code.charAt(0) === "F") { form.termName.value = "Fall " + year; window.UMS.setDateValue("start", "01-09-" + year); window.UMS.setDateValue("end", "31-12-" + year); }
    }

    function validateTermForm(form, isAdd) {
        if(isAdd) form.termCode.value = (form.termCode.value || "").trim().toUpperCase();
        form.termName.value = (form.termName.value || "").trim();
        if(isAdd && !/^[SRF]\d{2}$/.test(form.termCode.value)) { window.alert("Term Code must be S, R or F followed by two digits, for example F26."); form.termCode.focus(); return false; }
        if(!/^(Spring|Summer|Fall)\s+/i.test(form.termName.value)) { window.alert("Term Name must contain Spring, Summer or Fall."); form.termName.focus(); return false; }
        if(!window.UMS.isValidDateText(form.startDate.value)) { window.alert("Please select a valid Start Date."); window.UMS.openDatePicker("startDatePicker"); return false; }
        if(!window.UMS.isValidDateText(form.endDate.value)) { window.alert("Please select a valid End Date."); window.UMS.openDatePicker("endDatePicker"); return false; }
        return true;
    }

    function initTermForms() {
        var addForm = document.querySelector('form[data-ums-term-form="add"]');
        var editForm = document.querySelector('form[data-ums-term-form="edit"]');
        if(addForm) { addForm.addEventListener("submit", function(event) { if(!validateTermForm(addForm, true)) event.preventDefault(); }); if(addForm.termCode) { addForm.termCode.addEventListener("blur", function() { generateTermDetails(addForm); }); addForm.termCode.focus(); } }
        if(editForm) { editForm.addEventListener("submit", function(event) { if(!validateTermForm(editForm, false)) event.preventDefault(); }); if(editForm.termName) editForm.termName.focus(); }
    }

    document.addEventListener("DOMContentLoaded", initTermForms);
})(window, document);

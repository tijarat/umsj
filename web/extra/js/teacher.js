(function(window, document) {
    "use strict";
    var UMS = window.UMS = window.UMS || {};
    function trim(value) { return (value || "").replace(/^\s+|\s+$/g, ""); }
    function validEmail(value) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value); }
    function syncTeacherType(form) {
        var type = form.querySelector('[name="typeInd"]');
        var rate = form.querySelector('[name="rte"]');
        if(!type || !rate) return;
        var visiting = type.value === "V";
        rate.disabled = !visiting;
        rate.required = visiting;
        if(!visiting) rate.value = "";
    }
    function validate(form) {
        var name = form.querySelector('[name="tchrName"]');
        var abbr = form.querySelector('[name="tchrAbbr"]');
        var email = form.querySelector('[name="tchrEmail"]');
        var nic = form.querySelector('[name="nic"]');
        var rate = form.querySelector('[name="rte"]');
        var type = form.querySelector('[name="typeInd"]');
        if(!trim(name.value)) { window.alert("Please enter Teacher Name."); name.focus(); return false; }
        if(!trim(abbr.value)) { window.alert("Please enter Teacher Abbreviation."); abbr.focus(); return false; }
        if(!validEmail(trim(email.value))) { window.alert("Please enter a valid email address."); email.focus(); return false; }
        if(!/^\d{13}$/.test(trim(nic.value))) { window.alert("CNIC must contain exactly 13 digits without dashes."); nic.focus(); return false; }
        if(type && type.value === "V" && (!trim(rate.value) || Number(rate.value) < 0)) { window.alert("Teacher Rate is required for visiting faculty."); rate.focus(); return false; }
        if(form.getAttribute("data-ums-teacher-form") === "add") {
            var user = form.querySelector('[name="userName"]');
            var password = form.querySelector('[name="password"]');
            var retype = form.querySelector('[name="retypePassword"]');
            if(!/^[A-Za-z0-9._]+$/.test(trim(user.value))) { window.alert("Username may contain only letters, numbers, periods and underscores."); user.focus(); return false; }
            if(password.value.length < 6) { window.alert("Password must contain at least 6 characters."); password.focus(); return false; }
            if(password.value !== retype.value) { window.alert("Password and Retype Password do not match."); retype.focus(); return false; }
            if(password.value.toUpperCase() === trim(user.value).toUpperCase()) { window.alert("Password must not be the same as Username."); password.focus(); return false; }
        }
        return true;
    }
    UMS.initTeacherForms = function() {
        var forms = document.querySelectorAll("[data-ums-teacher-form]");
        Array.prototype.forEach.call(forms, function(form) {
            var type = form.querySelector('[name="typeInd"]');
            if(type) type.addEventListener("change", function() { syncTeacherType(form); });
            syncTeacherType(form);
            form.addEventListener("submit", function(event) { if(!validate(form)) event.preventDefault(); });
        });
    };
    if(document.readyState === "loading") document.addEventListener("DOMContentLoaded", UMS.initTeacherForms); else UMS.initTeacherForms();
})(window, document);

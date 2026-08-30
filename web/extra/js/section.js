(function(window, document) {
    "use strict";

    function trim(value) { return (value || "").replace(/^\s+|\s+$/g, ""); }

    function hasCheckedProgram(form) {
        var programs = form ? form.querySelectorAll('input[name="programs"]') : [];
        if(!programs.length) return false;
        for(var i = 0; i < programs.length; i++) if(programs[i].checked) return true;
        return false;
    }

    function validateSectionForm(form, requireProgram) {
        if(!form) return false;
        var section = form.querySelector('[name="section"]');
        var strength = form.querySelector('[name="strength"]');
        var teacher = form.querySelector('[name="Teacher"]');
        var faculty = form.querySelector('[name="faculty"]');
        if(section) {
            section.value = trim(section.value).toUpperCase().replace(/[^A-Z0-9]/g, "");
            if(section.value === "") { window.alert("Please enter Section."); section.focus(); return false; }
            if(!/^[A-Z0-9]{1,5}$/.test(section.value)) { window.alert("Section can contain letters and numbers only, maximum 5 characters."); section.focus(); return false; }
        }
        if(!teacher || teacher.value === "") { window.alert("Please select Teacher."); if(teacher) teacher.focus(); return false; }
        if(faculty && faculty.value === "") { window.alert("Please select Faculty."); faculty.focus(); return false; }
        if(!strength || strength.value === "" || isNaN(Number(strength.value)) || Number(strength.value) < 0 || Number(strength.value) > 999) { window.alert("Strength must be between 0 and 999."); if(strength) strength.focus(); return false; }
        if(requireProgram && !hasCheckedProgram(form)) { window.alert("Program is not defined/selected for this Course."); return false; }
        return true;
    }

    function initAddForm(form) {
        if(!form) return;
        var course = form.querySelector("[data-ums-section-course]");
        var section = form.querySelector('[name="section"]');
        if(course) course.addEventListener("change", function() { window.location.href = "AdminSections.jsp?Course=" + encodeURIComponent(course.value) + (form.Teacher && form.Teacher.value ? "&Teacher=" + encodeURIComponent(form.Teacher.value) : ""); });
        if(section) section.addEventListener("input", function() { section.value = section.value.toUpperCase().replace(/[^A-Z0-9]/g, ""); });
        form.addEventListener("submit", function(event) { if(!validateSectionForm(form, true)) event.preventDefault(); });
    }

    function initEditForm(form) {
        if(!form) return;
        form.addEventListener("submit", function(event) { if(!validateSectionForm(form, false)) event.preventDefault(); });
    }

    document.addEventListener("DOMContentLoaded", function() {
        initAddForm(document.querySelector('form[data-ums-section-form="add"]'));
        initEditForm(document.querySelector('form[data-ums-section-form="edit"]'));
    });
})(window, document);

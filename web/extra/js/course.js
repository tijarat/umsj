(function(window, document) {
    "use strict";

    function trim(value) { return (value || "").replace(/^\s+|\s+$/g, ""); }

    function setSpecialState(form) {
        if(!form || !form.courseType) return;
        var special = form.courseType.value === "S";
        if(form.spCourseFee) { form.spCourseFee.disabled = !special; if(!special) form.spCourseFee.value = ""; }
        if(form.spCoursediscount) { form.spCoursediscount.disabled = !special; if(!special) form.spCoursediscount.checked = false; }
    }

    function normalizeCourseCode(field) {
        if(!field) return;
        field.value = trim(field.value).toUpperCase().replace(/[^A-Z0-9]/g, "");
        if(field.value.length) {
            var last = field.value.charAt(field.value.length - 1);
            if(/\d/.test(last)) {
                var form = field.form;
                if(form && form.creditHours && !form.creditHours.value) form.creditHours.value = last;
            }
        }
    }

    function validateCourseForm(form, isAdd) {
        if(!form) return false;
        if(isAdd && form.courseCode) normalizeCourseCode(form.courseCode);
        if(form.courseName) form.courseName.value = trim(form.courseName.value);
        if(form.courseAbbr) form.courseAbbr.value = trim(form.courseAbbr.value);
        if(form.description) form.description.value = trim(form.description.value);
        if(isAdd && (!form.courseCode || form.courseCode.value === "")) { window.alert("Please enter Course Code."); form.courseCode.focus(); return false; }
        if(isAdd && !/\d$/.test(form.courseCode.value)) { window.alert("Course Code must end with a digit."); form.courseCode.focus(); return false; }
        if(form.courseName && form.courseName.value === "") { window.alert("Please enter Course Name."); form.courseName.focus(); return false; }
        if(form.courseAbbr && form.courseAbbr.value === "") { window.alert("Please enter Course Abbreviation."); form.courseAbbr.focus(); return false; }
        if(form.description && form.description.value.length > 1500) { window.alert("Course Description cannot be greater than 1500 characters."); form.description.focus(); return false; }
        if(form.creditHours) { var creditHours = Number(form.creditHours.value); if(isNaN(creditHours) || creditHours < 0 || creditHours > 6) { window.alert("Credit Hours must be between 0 and 6."); form.creditHours.focus(); return false; } }
        if(!form.courseFor || form.courseFor.value === "") { window.alert("Please select Course For."); if(form.courseFor) form.courseFor.focus(); return false; }
        if(form.courseType && form.courseType.value === "S") { if(!form.spCourseFee || trim(form.spCourseFee.value) === "") { window.alert("Please enter Course Fee for a Special Course."); if(form.spCourseFee) form.spCourseFee.focus(); return false; } if(isNaN(Number(form.spCourseFee.value)) || Number(form.spCourseFee.value) < 0) { window.alert("Course Fee must be a valid non-negative number."); form.spCourseFee.focus(); return false; } }
        return true;
    }

    function initCourseForm(form, isAdd) {
        if(!form) return;
        var radios = form.querySelectorAll('input[name="courseType"]');
        Array.prototype.forEach.call(radios, function(radio) { radio.addEventListener("change", function() { setSpecialState(form); }); });
        if(isAdd && form.courseCode) { form.courseCode.addEventListener("input", function() { form.courseCode.value = form.courseCode.value.replace(/[^a-zA-Z0-9]/g, ""); }); form.courseCode.addEventListener("blur", function() { normalizeCourseCode(form.courseCode); }); form.courseCode.focus(); }
        if(form.spCourseFee) form.spCourseFee.addEventListener("input", function() { form.spCourseFee.value = form.spCourseFee.value.replace(/[^0-9.]/g, ""); });
        form.addEventListener("submit", function(event) { if(!validateCourseForm(form, isAdd)) event.preventDefault(); });
        setSpecialState(form);
    }

    function initCopyForm() {
        var form = document.querySelector("form[data-ums-course-copy]");
        if(!form) return;
        form.addEventListener("submit", function(event) { var select = form.querySelector('[name="termList"]'); if(!select || !select.value) { event.preventDefault(); window.alert("Please select a previous Term."); return; } if(!window.confirm("This process cannot be cancelled. Are you sure you want to add courses from " + select.value + "?")) event.preventDefault(); });
    }

    function init() {
        initCourseForm(document.querySelector('form[data-ums-course-form="add"]'), true);
        initCourseForm(document.querySelector('form[data-ums-course-form="edit"]'), false);
        initCopyForm();
    }

    document.addEventListener("DOMContentLoaded", init);
})(window, document);

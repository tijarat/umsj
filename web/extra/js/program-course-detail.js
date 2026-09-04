(function(){
"use strict";
document.addEventListener("DOMContentLoaded",function(){
var form=document.getElementById("prereqForm");
if(form){form.addEventListener("submit",function(e){var c=document.getElementById("Course"),p=document.getElementById("Prereq");if(c&&p&&p.value&&c.value===p.value){e.preventDefault();alert("Course and Prerequisite cannot be the same.");}});}
});
})();
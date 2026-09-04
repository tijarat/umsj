(function(){
"use strict";
function addOption(selectId, value, text){var select=document.getElementById(selectId);if(!select||!value)return;for(var i=0;i<select.options.length;i++){if(select.options[i].value===value)return;}var option=document.createElement("option");option.value=value;option.textContent=text;option.selected=true;select.appendChild(option);}
function removeSelected(selectId){var select=document.getElementById(selectId);if(!select)return;for(var i=select.options.length-1;i>=0;i--){if(select.options[i].selected)select.remove(i);}}
function val(id){var el=document.getElementById(id);return el?el.value.trim():"";}
function addAbsent(){var cr=val("CrHr"),lim=val("absentLimit"),sport=val("absentLimitSports");if(!cr||!lim||!sport){alert("Please fill credit hours, absent limit and sports limit.");return;}addOption("selectedValues",cr+"|"+lim+"|"+sport,"CrHr: "+cr+" | Absent: "+lim+" | Sports: "+sport);}
function addClass(){var cr=val("creditHrs"),lim=val("classLimit");if(!cr||!lim){alert("Please fill credit hours and class limit.");return;}addOption("selectedValuesClass",cr+"|"+lim,"CrHr: "+cr+" | Class Limit: "+lim);}
function addDiscount(){var from=val("frmBatch"),to=val("toBatch"),fromCgpa=val("frmCgpa"),toCgpa=val("toCgpa"),disc=val("disc");if(!from||!fromCgpa||!toCgpa||!disc){alert("Please fill the discount policy values.");return;}addOption("selectedDisc",[from,to,fromCgpa,toCgpa,disc].join("|"),"From "+from+(to?" to "+to:"")+" | CGPA "+fromCgpa+"-"+toCgpa+" | "+disc+"%");}
function selectAll(form){["selectedValues","selectedValuesClass","selectedDisc"].forEach(function(id){var s=document.getElementById(id);if(s){for(var i=0;i<s.options.length;i++)s.options[i].selected=true;}});var absent=document.getElementById("selectedValues");if(absent&&absent.options.length===0){alert("Please define at least one absent limit.");return false;}return true;}
document.addEventListener("DOMContentLoaded",function(){
var a=document.getElementById("addAbsent");if(a)a.addEventListener("click",addAbsent);
var ar=document.getElementById("removeAbsent");if(ar)ar.addEventListener("click",function(){removeSelected("selectedValues");});
var c=document.getElementById("addClass");if(c)c.addEventListener("click",addClass);
var cr=document.getElementById("removeClass");if(cr)cr.addEventListener("click",function(){removeSelected("selectedValuesClass");});
var d=document.getElementById("addDiscount");if(d)d.addEventListener("click",addDiscount);
var dr=document.getElementById("removeDiscount");if(dr)dr.addEventListener("click",function(){removeSelected("selectedDisc");});
var form=document.getElementById("facultyForm");if(form)form.addEventListener("submit",function(e){if(!selectAll(form))e.preventDefault();});
});
})();
import { nextAuraxElementID } from "/js/character/weapons.js";
import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

window.addEventListener('load', (event) => {
    if (window.innerWidth >= 768) {
        $("input.search-input:first").focus();
    }

    //TODO edit dataset based on cached persistent data
    //document.getElementById("weaponTable").dataset.pagination = false;
});

function addCustomFilters() {
    //initialize variables
    const YEAR_SECOND = 31556952;
    const WEEK_SECOND = 604800;
    const DAY_SECOND = 86400;
    const HOUR_SECOND = 3600;
    const MINUTE_SECOND = 60;

    //set the custom functions object
    var customFunction = {
        "medal": function filterFunction(filterName, dataArray) {
            //filter the array based on the filter name category
            switch (filterName) {
                case "auraxium":
                    return dataArray.filter(weapon => weapon.kills >= 1160);
                case "gold":
                    return dataArray.filter(weapon => weapon.kills < 1160 && weapon.kills >= 160);
                case "silver":
                    return dataArray.filter(weapon => weapon.kills < 160 && weapon.kills >= 60);
                case "bronze":
                    return dataArray.filter(weapon => weapon.kills < 60 && weapon.kills >= 10);
                case "none":
                    return dataArray.filter(weapon => weapon.kills < 10);
                default: return dataArray;
            }
        },
        "vehicleinfantry": function filterFunction(filterName, dataArray) {
            //filter the array based on the filter name category
            switch (filterName) {
                case "infantry":
                    return dataArray.filter(weapon => weapon.vw == "No");
                case "vehicle":
                    return dataArray.filter(weapon => weapon.vw == "Yes");
                default: return dataArray;
            }
        },
        "time": function filterFunction(filterName, dataArray) {
            //filter the array based on the filter name category
            switch (filterName) {
                case "years":
                    return dataArray.filter(weapon => weapon.time >= YEAR_SECOND);
                case "weeks":
                    return dataArray.filter(weapon => weapon.time >= WEEK_SECOND && weapon.time < YEAR_SECOND);
                case "days":
                    return dataArray.filter(weapon => weapon.time >= DAY_SECOND && weapon.time < WEEK_SECOND);
                case "hours":
                    return dataArray.filter(weapon => weapon.time >= HOUR_SECOND && weapon.time < DAY_SECOND);
                case "minutes":
                    return dataArray.filter(weapon => weapon.time >= MINUTE_SECOND && weapon.time < HOUR_SECOND);
                case "seconds":
                    return dataArray.filter(weapon => weapon.time > 0 && weapon.time < MINUTE_SECOND);
                case "none":
                    return dataArray.filter(weapon => weapon.time == 0);
                default: return dataArray;
            }
        }
    };

    //Add it to the filter list
    bootstrapTableFilter.setCustomFilterFunctions(customFunction);
}

function initializeButtonEvent() {
    document.getElementById("nextAurax").addEventListener('click', function () {
        $('html, body').animate({
            scrollTop: $("#" + nextAuraxElementID).offset().top - ((window.innerWidth >= 768) ? 300 : 10) //- 254 to be at top
        }, 500);
        setTimeout(function () {
            flashElement(nextAuraxElementID);
        }, 500);
    });
}

function flashElement(elementId) {
    let flashInterval = setInterval(function () {
        $("#" + elementId).toggleClass("flash-border");
    }, 250);
    setTimeout(function () {
        window.clearInterval(flashInterval);
        $("#" + elementId).removeClass("flash-border");
    }, 1000);
}

export function showHideNextAuraxButton() {
    if (document.getElementById("nextAurax") != undefined) {
        if (document.getElementById(nextAuraxElementID) != undefined) {
            $("#nextAurax").show();
        } else {
            $("#nextAurax").hide();
        }
    }
}

export default function init() {
    $('#weaponTable').bootstrapTable({
        formatSearch: function () {
            return 'Search Weapon Name'
        },
        customSearch: searchByWeaponName,
        dragaccept: '.drag-accept'
    });

    function searchByWeaponName(data, text) {
        return data.filter(function (row) {
            var template = document.createElement('template');
            template.innerHTML = row.weapon;
            return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(text.toLowerCase()) > -1;
        })
    }

    initializeButtonEvent();
    addCustomFilters();
}

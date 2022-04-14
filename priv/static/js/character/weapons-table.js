import { nextAuraxElementID } from "/js/character/weapons.js";
import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

let copyRows = new Set();

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

function addRightClickTable() {
    //add special Right click on table menu
    $('#weaponTable').on('contextmenu', function (e) {
        //initialize special menu location
        var top = ((e.clientY / $(window).height()) * 100) + "%";
        var left = ((e.clientX / $(window).width()) * 100) + "%";

        //show special menu at the bottom right of the mouse
        $("#context-menu").css({
            display: "block",
            position: "fixed",
            top: top,
            left: left
        }).addClass("show");

        //if the row was not selected before deselect other selected rows
        let row = $(e.target).closest("tr")[0];
        if (!copyRows.has(row)) {
            resetCopyRowSelection();
        }

        //add current row to selection
        copyRows.add(row);
        $(e.target).closest("tr").addClass("selection");

        return false; //blocks default Webbrowser right click menu
    });

    //update selections
    $('#weaponTable').on('click', function (e) {
        //hide the special menu and initialize variables
        hideContextMenu();
        let row = $(e.target).closest("tr")[0];

        //if it's a new selection set reset the selections
        if (copyRows.size > 0 && !e.ctrlKey) {
            resetCopyRowSelection();
        }

        //if the ctrl key was pressed while a selection was clicked remove it
        if (e.ctrlKey && copyRows.has(row)) {
            copyRows.delete(row);
            $(row).removeClass("selection");
        } else {
            //otherwise just add the current row to selection
            copyRows.add(row);
            $(e.target).closest("tr").addClass("selection");
        }
    });

    //add event listner for copy click
    $("#copyWeaponLink").on('click', function () {
        $('.toast').toast('show');
        hideContextMenu();
    });

    //add page click events
    $(document).on("click", function (e) {
        //if the click is not in the table remove selections and hide the special menu
        if ($(e.target).closest("tr")[0] == undefined || $(e.target).closest("tr")[0].localName != "tr") {
            resetCopyRowSelection();
            hideContextMenu();
        }
    });

    //add page key events
    $(document).on("keyup", function (e) {
        //if the user presses ctrl-C with something selected copy selected rows
        if (e.key === 'c' && e.ctrlKey && copyRows.size > 0) {
            copySelectedRows();
            $('.toast').toast('show');
        }
    });

    //add page right click events to hide special menu
    $(document).on("contextmenu", function () {
        hideContextMenu();
    });

    //hide the special menu when an option is clicked
    $("#context-menu").on("click", function () {
        hideContextMenu();
    });

    //add copy clicks
    addCopyClick();
}

function resetCopyRowSelection() {
    //remove the selection style from each row and reinit the set
    copyRows.forEach(row => {
        $(row).removeClass("selection");
    });
    copyRows = new Set();
}

function hideContextMenu() {
    $("#context-menu").removeClass("show").hide();
}

function addCopyClick() {
    $("#copyWeaponLink").on('click', copySelectedRows);
}

function copySelectedRows() {
    //get the current url
    const newURL = new URL(window.location.href);

    //if there is only 1 selection add the weapon name to the search arg
    newURL.search = "?search=";
    if (copyRows.size == 1) {
        copyRows.forEach(row => {
            newURL.search = newURL.search + $(row).find("td.weapon").first().find("h5.weaponName").first()[0].innerHTML.replaceAll(" ", "_");
        });
    }

    //add each selected id to the id arg separated by ','
    newURL.search = newURL.search + "&id=" + [...copyRows][0].id.replaceAll("weapon", "").replaceAll("Row", "");
    for (let i = 1; i < copyRows.size; i++) {
        newURL.search = newURL.search + "," + [...copyRows][i].id.replaceAll("weapon", "").replaceAll("Row", "");
    }

    //copy the new url to clipboard and reset selection
    navigator.clipboard.writeText(newURL);
    resetCopyRowSelection();
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
        return bootstrapTableFilter.sortData(data.filter(function (row) {
            var template = document.createElement('template');
            template.innerHTML = row.weapon;
            return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(text.toLowerCase()) > -1;
        }));
    }

    initializeButtonEvent();
    addCustomFilters();
    addRightClickTable();
}

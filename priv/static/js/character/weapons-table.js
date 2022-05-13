import { nextAuraxElementID } from "/js/character/weapons.js";
import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";
import * as bootstrapSelection from "/js/flex-bootstrap-table-selection.js";

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

function addCustomCopyFunction() {
    let customFunction = function () {
        //get the current url
        const newURL = new URL(window.location.href);
        newURL.search = "?";

        //if there is only 1 selection add the weapon name to the search arg
        let copyRows = [...bootstrapSelection.getSelectedRows()];
        let firstCopyElement = copyRows[0];
        if (copyRows.length == 1) {
            newURL.search = newURL.search + "search=";
            newURL.search = newURL.search + $(firstCopyElement).find("td.weapon").first().find("h5.weaponName").first()[0].innerHTML.replaceAll(" ", "_");
            newURL.search = newURL.search + "&";
        }

        //add each selected id to the id arg separated by ','
        newURL.search = newURL.search + "id=" + firstCopyElement.id.replaceAll("weapon", "").replaceAll("Row", "");
        for (let i = 1; i < copyRows.length; i++) {
            newURL.search = newURL.search + "," + copyRows[i].id.replaceAll("weapon", "").replaceAll("Row", "");
        }

        //return the new url
        return newURL.toString().replaceAll('%22', '\"');
    };

    let customCopyFunction = function () {
        //create a header line
        let copyString = document.getElementById("characterName").innerText + "'s Weapon Stats\n\n";

        //initialize variables
        let headerArray = [...$('#weaponTable').find('thead').first().find('tr').first()[0].children];
        let index = 0;
        let copyRows = bootstrapSelection.getSelectedRows();

        //loop through each selected weapon row
        copyRows.forEach(row => {
            let dataArray = $(row).find('td');

            //create a weapon subheader
            copyString = copyString + dataArray[0].innerText.split("\n")[0] + " (" + row.id.replaceAll("weapon", "").replaceAll("Row", "") + "):\n";

            //loop through each coloumn and separate them by commas and property values by colons
            for (let i = 1; i < dataArray.length; i++) {
                if (i > 1) {
                    copyString = copyString + ", ";
                }
                copyString = copyString + (isMobileScreen() ? "" : (headerArray[i].innerText + ": ")) + dataArray[i].innerText;
            }

            //create new line space between each weapon stat
            if (index < copyRows.size - 1) {
                copyString = copyString + "\n\n";
                index++;
            }

        });

        //return the copy string
        return copyString;
    };

    bootstrapSelection.setCustomCopyFunction(customFunction);
    bootstrapSelection.setSecondCustomCopyFunction(customCopyFunction);
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

function isMobileScreen() {
    return window.innerWidth <= 767;
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
    addCustomCopyFunction();
}

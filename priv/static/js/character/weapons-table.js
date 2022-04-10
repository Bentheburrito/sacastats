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
    //set the custom functions object
    var customFunction = {
        "auraxium": function filterFunction(filterItems, filteredTableData) {
            //initialize variables
            let dataArray = filteredTableData;
            var filteredDataArray = new Set();

            //check to see if there is a filter that needs to be applied
            if (!bootstrapTableFilter.isSelectAllSelected(filterItems)) {
                //if so, loop through the boxes that are checked
                var checkedFilteredItems = bootstrapTableFilter.getCheckedBoxes(filterItems);
                checkedFilteredItems.forEach(filter => {
                    //if it's checked apply the filter the right filter
                    if (filter.checked) {
                        //where filter.filterName == to the first element of the input's id split by '-'
                        //and on filter, weapon == the table row
                        //so add .<column's data-field here> to get the non formatted value of a column
                        if (filter.filterName == "auraxed") {
                            filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(weapon => weapon.kills >= 1160)]));
                        } else if (filter.filterName == "nonauraxed") {
                            filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(weapon => weapon.kills < 1160)]));
                        }
                    }
                });
                dataArray = [...filteredDataArray]
            }

            return dataArray;
        },
        "vehicleinfantry": function filterFunction(filterItems, filteredTableData) {
            //initialize variables
            let dataArray = filteredTableData;
            var filteredDataArray = new Set();

            //check to see if there is a filter that needs to be applied
            if (!bootstrapTableFilter.isSelectAllSelected(filterItems)) {
                //if so, loop through the boxes that are checked
                var checkedFilteredItems = bootstrapTableFilter.getCheckedBoxes(filterItems);
                checkedFilteredItems.forEach(filter => {
                    //if it's checked apply the filter the right filter
                    if (filter.checked) {
                        //where filter.filterName == to the first element of the input's id split by '-'
                        //and on filter, weapon == the table row
                        //so add .<column's data-field here> to get the non formatted value of a column
                        if (filter.filterName == "infantry") {
                            filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(weapon => weapon.vw == "No")]));
                        } else if (filter.filterName == "vehicle") {
                            filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(weapon => weapon.vw == "Yes")]));
                        }
                    }
                });
                dataArray = [...filteredDataArray]
            }

            return dataArray;
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
    })

    function searchByWeaponName(data, text) {
        return data.filter(function (row) {
            var template = document.createElement('template');
            template.innerHTML = row.weapon;
            return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(text.toLowerCase()) > -1
        })
    }

    initializeButtonEvent();
    addCustomFilters();
}

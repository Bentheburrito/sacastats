var originalTableData;
var filteredTableData;
var tableID;
var clearFilterButtonID;
var customFilterFunctions = new Object();
var filters = new Map();

function updateFilterVariables() {
    filters = new Map();

    $(".filter-option-name").each(function () {
        $(this.parentElement).find(".filter-options-container").first().find(".filter-option").each(function () {
            let input = $(this).find("input").first()[0];
            let name = input.getAttribute("name");
            let checked = input.checked;
            let filterID = input.id;
            let filterName = filterID.split("-")[0];
            let object = new Object();
            object.filterID = filterID;
            object[filterName] = checked;
            object.filterName = filterName;
            object.checked = checked;

            if (filters.get(name) == undefined) {
                filters.set(name, [object]);
            } else {
                let array = filters.get(name);
                array.push(object);
                filters.set(name, array);
            }
        });
    });
}

function addFilterListeners() {
    for (let [_, filterItems] of filters) {
        filterItems.forEach((filter) => {
            document.getElementById(filter.filterID).addEventListener('change', updateTableFiltration);
        });
    }
    $(clearFilterButtonID).on('click', clearFiltration);
}

function removeFilterListeners() {
    for (let [_, filterItems] of filters) {
        filterItems.forEach((filter) => {
            document.getElementById(filter.filterID).removeEventListener('change', updateTableFiltration);
        });
    }
    $(clearFilterButtonID).off('click', clearFiltration);
}

export function isSelectAllSelectedBefore(filterArray) {
    return (filterArray.find(filter => { return filter["showall"] === true }) != undefined);
}

export function isSelectAllSelected(filterArray) {
    return (filterArray.find(filter => { return filter.filterName == "showall" && document.getElementById(filter.filterID).checked === true }) != undefined);
}

export function isSelectAllSelectedRecently(filterArray) {
    return !isSelectAllSelectedBefore(filterArray) && isSelectAllSelected(filterArray);
}

function onlyCheckSelectAll(filterItems) {
    filterItems.forEach(filter => {
        if (filter.filterName == "showall") {
            document.getElementById(filter.filterID).checked = true;
        } else {
            document.getElementById(filter.filterID).checked = false;
        }
    });
}

function removeCheckSelectAll(filterItems) {
    filterItems.forEach(filter => {
        if (filter.filterName == "showall") {
            document.getElementById(filter.filterID).checked = false;
        }
    });
}

function accountForSelectAlls() {
    for (let [_, filterItems] of filters) {
        if (isSelectAllSelected(filterItems)) {
            if (isSelectAllSelectedRecently(filterItems)) {
                onlyCheckSelectAll(filterItems);
            } else {
                removeCheckSelectAll(filterItems);
            }
        }
    }
}

function isAnItemSelected(filterArray) {
    return (filterArray.find(filter => { return document.getElementById(filter.filterID).checked === true }) != undefined);
}

function accountForNoneSelected() {
    for (let [_, filterItems] of filters) {
        if (!isAnItemSelected(filterItems)) {
            onlyCheckSelectAll(filterItems);
        }
    }
}

export function getCheckedBoxes(filterItems) {
    var checkedFilteredItems = [];
    filterItems.forEach(filter => {
        if (filter.checked) {
            checkedFilteredItems.push(filter);
        }
    });
    return checkedFilteredItems;
}

function defaultFiltrationFunction(name, filterItems) {
    let dataArray = filteredTableData;
    var filteredDataArray = new Set();
    if (!isSelectAllSelected(filterItems)) {
        var checkedFilteredItems = getCheckedBoxes(filterItems);
        checkedFilteredItems.forEach(filter => {
            if (filter.checked) {
                filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(item => item[name] == filter.filterName)]));
            }
        });
        dataArray = [...filteredDataArray]
    }

    return dataArray;
}

function clearFiltration() {
    removeFilterListeners();
    for (let [_, filterItems] of filters) {
        if (!isSelectAllSelected(filterItems)) {
            filterItems.forEach((filter) => {
                if (filter.filterName == "showall") {
                    document.getElementById(filter.filterID).checked = true;
                }
            });
        }
    }
    updateTableFiltration();
    addFilterListeners();
}

export function updateTableFiltration() {
    accountForSelectAlls();
    accountForNoneSelected();
    updateFilterVariables();
    filteredTableData = getOriginalTableData();

    for (let [name, filterItems] of filters) {
        if (customFilterFunctions.hasOwnProperty(name)) {
            filteredTableData = customFilterFunctions[name](filterItems, filteredTableData);
        } else {
            filteredTableData = defaultFiltrationFunction(name, filterItems)
        }
    }

    $(getTableID()).bootstrapTable('load', filteredTableData);
}

/*
    Add custom functions by setting them hear with an object like this:

    //get dependency
    import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

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
*/
export function setCustomFilterFunctions(functions) {
    customFilterFunctions = functions;
}

export function revertFilteredData() {
    $(tableID).bootstrapTable('load', getOriginalTableData);
}

export function getOriginalTableData() {
    return JSON.parse(JSON.stringify(originalTableData));
}

export function getFilteredTableData() {
    return filteredTableData;
}

export function getTableID() {
    return tableID;
}

export function getClearFilterButtonID() {
    return clearFilterButtonID;
}

export function getFirstShowAllButtonID() {
    var filterID;
    for (let [_, filterItems] of filters) {
        filterItems.forEach((filter) => {
            if (filter.filterName == "showall" && filterID == undefined) {
                filterID = filter.filterID;
            }
        });
    }
    return '#' + filterID;
}

export function init(id) {
    tableID = '#' + id;
    clearFilterButtonID = '#' + id + "-clear-filter-button";
    // $('#weaponTable').filter(function () {
    //     $(this).toggle($(this).text().toLowerCase().indexOf("air") > -1)
    // });
    originalTableData = JSON.parse(JSON.stringify($(tableID).bootstrapTable('getData', false)));
    let data = $(tableID).bootstrapTable('getData', false).filter(weapon => weapon.faction == "NC");
    //$(tableID).bootstrapTable('load', data);

    updateFilterVariables();
    addFilterListeners();
}
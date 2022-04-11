var originalTableData;
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

function getNonNamedFunctionDataArray(nameToNotAdd) {
    var filteredTableData = accountForSearch();

    for (let [name, filterItems] of filters) {
        if (name != nameToNotAdd) {
            filteredTableData = defaultFiltrationFunction(name, filterItems, filteredTableData);
        }
    }
    return filteredTableData;
}

function updateFilterOptionAvailability() {
    for (let [name, filterItems] of filters) {
        updateEachOptionAvailability(name, filterItems);
    }
}

function updateEachOptionAvailability(name, filterItems) {
    var dataArray = getNonNamedFunctionDataArray(name);
    const originalArraySize = dataArray.length;
    filterItems.forEach(filter => {
        let newArraySize = originalArraySize;
        let input = document.getElementById(filter.filterID);
        if (filter.filterName != "showall") {
            if (customFilterFunctions.hasOwnProperty(name)) {
                newArraySize = customFilterFunctions[name](filter.filterName, dataArray).length;
            } else {
                newArraySize = dataArray.filter(item => item[name] == filter.filterName).length;
            }
        }

        input.disabled = (newArraySize == 0);
        if (newArraySize == 0 && filter.checked) {
            filter.checked = false;
            input.checked = false;
        }
        input.parentElement.querySelector("span").querySelector(".filter-option-contains").innerHTML = "(" + newArraySize + ")";
    });
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

function accountForSearch() {
    var filteredTableData = getOriginalTableData();
    let td = $(tableID).first()[0].querySelector(".weapon");
    if (td != undefined) {
        var searchInput = $(".form-control.search-input").first().val();
        if ((searchInput != undefined || searchInput != null) && searchInput != "") {
            filteredTableData = filteredTableData.filter(function (item) {
                var template = document.createElement('template');
                template.innerHTML = item.weapon;
                return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(searchInput.toLowerCase()) > -1;
            });
        }
    }
    return filteredTableData;
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

function defaultFiltrationFunction(name, filterItems, dataArray) {
    var filteredDataArray = new Set();
    if (!isSelectAllSelected(filterItems)) {
        var checkedFilteredItems = getCheckedBoxes(filterItems);
        checkedFilteredItems.forEach(filter => {
            if (filter.checked) {
                if (customFilterFunctions.hasOwnProperty(name)) {
                    filteredDataArray = new Set(([...filteredDataArray, ...customFilterFunctions[name](filter.filterName, dataArray)]));
                } else {
                    filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(item => item[name] == filter.filterName)]));
                }
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
    var filteredTableData = accountForSearch();

    for (let [name, filterItems] of filters) {
        filteredTableData = defaultFiltrationFunction(name, filterItems, filteredTableData);
    }

    updateFilterOptionAvailability();

    $(getTableID()).bootstrapTable('load', filteredTableData);
}

/*
    Add custom functions by setting them hear with an object like this:

    //get dependency
    import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

    //set the custom functions object
    var customFunction = {
        "medal": function filterFunction(filterName, dataArray) {
            //filter the array based on the filter name
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
            //filter the array based on the filter name
            switch (filterName) {
                case "infantry":
                    return dataArray.filter(weapon => weapon.vw == "No");
                case "vehicle":
                    return dataArray.filter(weapon => weapon.vw == "Yes");
                default: return dataArray;
            }
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

export function init(id) {
    tableID = '#' + id;
    clearFilterButtonID = '#' + id + "-clear-filter-button";
    originalTableData = JSON.parse(JSON.stringify($(tableID).bootstrapTable('getData', false)));

    updateFilterVariables();
    addFilterListeners();
    updateFilterOptionAvailability();
}

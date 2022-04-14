import { setMobileHeaderTexts, updateSearchParam } from "/js/flex-bootstrap-table.js";
import { addFormatsToPage, addAnimationToProgressBars } from "/js/formats.js";
import { showHideNextAuraxButton } from "/js/character/weapons-table.js";

var originalTableData;
var tableID;
var clearFilterButtonID;
var clearAllFilterButtonID;
var customFilterFunctions = new Object();
var filters = new Map();
var firstGo = true;
var hasID = false;
var idFilteredData;

function createFilterObjects() {
    //reinitialize variables
    filters = new Map();

    //loop through each filter option
    $(".filter-option").each(function () {
        //get filter property values from the input element
        let input = $(this).find("input").first()[0];
        let filterCategory = input.getAttribute("name");
        let checked = input.checked;
        let filterID = input.id;
        let filterName = filterID.split("-")[0];

        //put filter properties into an object
        let filterObject = new Object();
        filterObject.filterID = filterID;
        filterObject[filterName] = checked;
        filterObject.filterName = filterName;
        filterObject.checked = checked;

        //if there is no filter for that filter category, add the object as a new array
        if (filters.get(filterCategory) == undefined) {
            filters.set(filterCategory, [filterObject]);
        } else {
            //otherwise add the object the the array on the map
            let array = filters.get(filterCategory);
            array.push(filterObject);
            filters.set(filterCategory, array);
        }
    });
}

function updateFilterVariables() {
    //initialize variables
    let persistentFiltersName = window.location.pathname + "/filterMap";
    let persistentFilters = localStorage.getItem(persistentFiltersName);

    //if there are no persistent filters and it's not the first go reinitalize filter map with current and persist it 
    if (!firstGo || (firstGo && persistentFilters == undefined)) {
        createFilterObjects();
        localStorage.setItem(persistentFiltersName, JSON.stringify(Array.from(filters.entries())));
    } else {
        filters = new Map(JSON.parse(persistentFilters));
        updateSelections();
    }

    //it has been iterated through at least once
    firstGo = false;
}

function updateSelections() {
    //loop through filter map
    for (let [_, filterOptions] of filters) {
        //loop through each filter option and update their checked selections
        filterOptions.forEach((filter) => {
            document.getElementById(filter.filterID).checked = filter.checked;
        });
    }
}

function initializeSearchInput() {
    //get the query string
    let query = document.location.search;

    //if the query string is valid
    if (query != "" && query.toLowerCase().startsWith("?search=")) {
        //clear filters to make search visible
        let persistentFiltersName = window.location.pathname + "/filterMap";
        localStorage.removeItem(persistentFiltersName);

        //get variables
        let search = query.substring(1);
        let searchElement = document.querySelector("input.search-input");
        let searchText = search.split("&")[0].split("=")[1].replaceAll("%20", " ").replaceAll("+", " ").replaceAll("_", " ");

        //determine if it will need a custom filter
        if (!search.includes("&id=")) {
            //simulate a search
            const ke = new KeyboardEvent('keydown', { keyCode: 13 });
            searchElement.dispatchEvent(ke);
        } else {
            //filter on name and id
            let textArray = search.split("&");
            //get the query object that has the id
            textArray.find(text => {
                if (text.includes("id=")) {
                    //get the id and filter the data based on that and the weapon name
                    let id = text.split("=")[1];
                    let filteredDataArray = getOriginalTableData().filter(function (row) {
                        var template = document.createElement('template');
                        template.innerHTML = row.weapon;
                        return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(searchText.toLowerCase()) > -1
                            && row.id == id;
                    })

                    //set the new id and make sure to compensate for the new filtering
                    $(getTableID()).bootstrapTable('load', filteredDataArray);
                    hasID = true;
                    idFilteredData = filteredDataArray;
                }
            });
        }
        //set the input value
        searchElement.value = searchText;

        //select the text on desktop
        if (window.innerWidth >= 768) {
            document.querySelector("input.search-input").select();
        }
    }
}

function addFilterListeners() {
    //loop through filter map
    for (let [_, filterOptions] of filters) {
        //loop through each filter option and add a change event listener to update the filtration
        filterOptions.forEach((filter) => {
            document.getElementById(filter.filterID).addEventListener('change', updateTableFiltration);
        });
    }

    //add clear filter button click event listener
    $(clearFilterButtonID).on('click', clearFiltration);
    $(clearAllFilterButtonID).on('click', clearAllFiltration);
}

function removeFilterListeners() {
    //loop through filter map
    for (let [_, filterOptions] of filters) {
        //loop through each filter option and remove the change event listener that updates the filtration
        filterOptions.forEach((filter) => {
            document.getElementById(filter.filterID).removeEventListener('change', updateTableFiltration);
        });
    }

    //remove clear filter button click event listener
    $(clearFilterButtonID).off('click', clearFiltration);
    $(clearAllFilterButtonID).off('click', clearAllFiltration);
}

function getNonNamedFunctionDataArray(filterCategoryToNotAdd) {
    //get original table data with the search filter applied 
    var filteredTableData = accountForSearch();

    //loop through filter map
    for (let [filterCategory, filterOptions] of filters) {
        //only apply filters that are not in the requested filter category
        if (filterCategory != filterCategoryToNotAdd) {
            filteredTableData = defaultFiltrationFunction(filterCategory, filterOptions, filteredTableData);
        }
    }

    //return the filtered array
    return filteredTableData;
}

function updateFilterOptionAvailability() {
    //loop through filter map
    for (let [filterCategory, filterOptions] of filters) {
        updateEachOptionAvailability(filterCategory, filterOptions);
    }
}

function updateEachOptionAvailability(filterCategory, filterOptions) {
    //initialize variables
    var dataArray = getNonNamedFunctionDataArray(filterCategory);
    const originalArraySize = dataArray.length;

    //loop through each filter option
    filterOptions.forEach(filter => {
        //initialize variables
        let newArraySize = originalArraySize;
        let input = document.getElementById(filter.filterID);

        //if the option is not a show all
        if (filter.filterName != "showall") {
            //if the filter name category is a custom filter apply the custom filter
            if (customFilterFunctions.hasOwnProperty(filterCategory)) {
                newArraySize = customFilterFunctions[filterCategory](filter.filterName, dataArray).length;
            } else {
                //otherwise apply the default filter
                newArraySize = dataArray.filter(option => option[filterCategory] == filter.filterName).length;
            }
        }

        //if the filtered array is empty and the filter is not checked, add disabled class and disable it
        if (newArraySize == 0 && !filter.checked) {
            input.parentElement.classList.add("contains-disabled-input");
            input.disabled = true;
        } else {
            //otherwise remove disabled class and enable it
            input.parentElement.classList.remove("contains-disabled-input");
            input.disabled = false;
        }

        //update the availability count element
        input.parentElement.querySelector("span").querySelector(".filter-option-contains").innerHTML = "(" + newArraySize + ")";
    });
}

export function isShowAllSelectedBefore(filterArray) {
    return (filterArray.find(filter => { return filter["showall"] === true }) != undefined);
}

export function isShowAllSelected(filterArray) {
    return (filterArray.find(filter => { return filter.filterName == "showall" && document.getElementById(filter.filterID).checked === true }) != undefined);
}

export function isShowAllSelectedRecently(filterArray) {
    return !isShowAllSelectedBefore(filterArray) && isShowAllSelected(filterArray);
}

function onlyCheckShowAll(filterOptions) {
    //loop through each filter option
    filterOptions.forEach(filter => {
        //check the show all option, and deselect all other options
        document.getElementById(filter.filterID).checked = (filter.filterName == "showall");
    });
}

function removeCheckShowAll(filterOptions) {
    //loop through each filter option
    filterOptions.forEach(filter => {
        //if it's a show all option deselect it
        if (filter.filterName == "showall") {
            document.getElementById(filter.filterID).checked = false;
        }
    });
}

function accountForShowAlls() {
    //loop through filter map
    for (let [_, filterOptions] of filters) {
        if (isShowAllSelected(filterOptions)) {
            if (isShowAllSelectedRecently(filterOptions)) {
                onlyCheckShowAll(filterOptions);
            } else {
                removeCheckShowAll(filterOptions);
            }
        }
    }
}

function isAnOptionSelected(filterArray) {
    return (filterArray.find(filter => { return document.getElementById(filter.filterID).checked === true }) != undefined);
}

function accountForNoneSelected() {
    //loop through filter map and if nothing is selected check the show all option
    for (let [_, filterOptions] of filters) {
        if (!isAnOptionSelected(filterOptions)) {
            onlyCheckShowAll(filterOptions);
        }
    }
}

function isThereInput(text) {
    return (text != undefined || text != null) && text != "";
}

export function accountForSearch() {
    //get the original table data
    var filteredTableData = getOriginalTableData();

    //if there is a weapon table
    let td = $(tableID).first()[0].querySelector(".weapon");
    if (td != undefined) {
        //get the search input
        var searchInput = $(".form-control.search-input").first().val();

        //if there is input, filter the table data based on it
        if (isThereInput(searchInput)) {
            filteredTableData = filteredTableData.filter(function (option) {
                //create a template element and set it to the weapon td
                var template = document.createElement('template');
                template.innerHTML = option.weapon;

                //get the weapon name and filter based on the search input
                return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(searchInput.toLowerCase()) > -1;
            });
        }
    }
    //return the filtered array
    return filteredTableData;
}

export function getCheckedBoxes(filterOptions) {
    //initialize variables
    var checkedFilteredOptions = [];

    //loop through each filter option
    filterOptions.forEach(filter => {
        //if it's checked add it to the array
        if (filter.checked) {
            checkedFilteredOptions.push(filter);
        }
    });

    //return the checked boxes
    return checkedFilteredOptions;
}

function defaultFiltrationFunction(filterCategory, filterOptions, dataArray) {
    //initialize variables
    var filteredDataArray = new Set();

    //if show all is not selected apply filters
    if (!isShowAllSelected(filterOptions)) {
        //initialize variables
        var checkedFilteredOptions = getCheckedBoxes(filterOptions);

        //loop through each filter option
        checkedFilteredOptions.forEach(filter => {
            if (filter.checked) {
                //if the filter name category is a custom filter apply the custom filter
                if (customFilterFunctions.hasOwnProperty(filterCategory)) {
                    filteredDataArray = new Set(([...filteredDataArray, ...customFilterFunctions[filterCategory](filter.filterName, dataArray)]));
                } else {
                    //otherwise apply the default filter
                    filteredDataArray = new Set(([...filteredDataArray, ...dataArray.filter(option => option[filterCategory] == filter.filterName)]));
                }
            }
        });

        //convert set to array
        dataArray = [...filteredDataArray]
    }

    //return array
    return dataArray;
}

function clearAllFiltration() {
    let searchElement = document.querySelector("input.search-input");
    searchElement.value = "";
    turnOffIdFilter();
    updateSearchParam();

    //select the text on desktop
    if (window.innerWidth >= 768) {
        document.querySelector("input.search-input").select();
    }
    clearFiltration();
}

function clearFiltration() {
    //make the clear silent
    removeFilterListeners();

    //loop through filter map
    for (let [_, filterOptions] of filters) {
        //if the show all option is not selected loop through each filter option and select the show all option
        if (!isShowAllSelected(filterOptions)) {
            filterOptions.forEach((filter) => {
                if (filter.filterName == "showall") {
                    document.getElementById(filter.filterID).checked = true;
                }
            });
        }
    }

    //update the filtration and add the listeners back
    updateTableFiltration();
    addFilterListeners();
}

function isThereAFilterSet() {
    //loop through filter map
    for (let [_, filterOptions] of filters) {
        //if the show all option is not selected return true
        if (!isShowAllSelected(filterOptions)) {
            return true;
        }
    }
    return false;
}

function showHideClearFilterButtons() {
    if (isThereAFilterSet()) {
        $(clearFilterButtonID).show();
        $(clearAllFilterButtonID).show();
    } else {
        $(clearFilterButtonID).hide();
        if (document.querySelector("input.search-input").value != "") {
            $(clearAllFilterButtonID).show();
        } else {
            $(clearAllFilterButtonID).hide();
        }
    }
}

function setNextAuraxVisibilities() {
    setTimeout(function () {
        showHideNextAuraxButton();
    }, 10);
}

export function updateTableFiltration() {
    //make sure the table data and filtration are initialized
    accountForShowAlls();
    accountForNoneSelected();
    updateFilterVariables();
    var filteredTableData = accountForSearch();

    //loop through filter map and filter the data
    for (let [filterCategory, filterOptions] of filters) {
        filteredTableData = defaultFiltrationFunction(filterCategory, filterOptions, filteredTableData);
    }

    //add how many items will be there after the filter option is selected
    updateFilterOptionAvailability();

    //show or hide Buttons based on new filter
    showHideClearFilterButtons();
    setNextAuraxVisibilities();

    //set table data to filtered data
    $(getTableID()).bootstrapTable('load', sortData(filteredTableData));
}

export function sortData(filteredTableData) {
    let toSortDesc = $(getTableID()).find(".desc").first()[0];
    let toSortAsc = $(getTableID()).find(".asc").first()[0];

    if (toSortDesc != undefined) {
        let sortOn = toSortDesc.innerText.toLowerCase();
        applyFormatsToTable();
        return filteredTableData.sort(dynamicsort(sortOn, "desc"));
    } else if (toSortAsc != undefined) {
        let sortOn = toSortAsc.innerText.toLowerCase();
        applyFormatsToTable();
        return filteredTableData.sort(dynamicsort(sortOn, "asc"));
    } else {
        applyFormatsToTable();
        return filteredTableData;
    }
}

function dynamicsort(property, order) {
    var sortOrder = 1;
    if (order === "desc") {
        sortOrder = -1;
    }
    return function (a, b) {
        if (!isNaN(a[property])) {
            return (a[property] - b[property]) * sortOrder;
        } else {
            // a should come before b in the sorted order
            if (a[property] < b[property]) {
                return -1 * sortOrder;
                // a should come after b in the sorted order
            } else if (a[property] > b[property]) {
                return 1 * sortOrder;
                // a and b are the same
            } else {
                return 0 * sortOrder;
            }
        }
    }
}

function applyFormatsToTable() {
    setTimeout(function () {
        addAnimationToProgressBars();
        addFormatsToPage();
        setMobileHeaderTexts(getTableID().substring(1));
    }, 10);
}

/*
    Add custom filter functions by setting them here with an object like this:

    //get dependency
    import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

    //set the custom functions object
    var customFunctionObject = {
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
        }
    };

    //Add it to the filter list
    bootstrapTableFilter.setCustomFilterFunctions(customFunctionObject);
*/
export function setCustomFilterFunctions(functions) {
    customFilterFunctions = functions;
}

export function revertFilteredData() {
    $(tableID).bootstrapTable('load', getOriginalTableData);
}

export function getOriginalTableData() {
    return hasID ? JSON.parse(JSON.stringify(idFilteredData)) : JSON.parse(JSON.stringify(originalTableData));
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

export function turnOffIdFilter() {
    hasID = false;
}

export function init(id) {
    //initialize class variables
    tableID = '#' + id;
    clearFilterButtonID = '#' + id + "-clear-filter-button";
    clearAllFilterButtonID = '#' + id + "-clear-all-filter-button";
    originalTableData = JSON.parse(JSON.stringify($(tableID).bootstrapTable('getData', false)));

    //set up filter option data and event listeners
    initializeSearchInput();
    updateTableFiltration();
    addFilterListeners();
    updateFilterOptionAvailability();
}

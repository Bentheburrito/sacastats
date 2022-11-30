import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';

import { ITableData } from '../models/flex-bootstrap-table/flex-bootstrap-table.js';
import { CustomFilterFunction, FilterMap, TableFilter } from '../models/flex-bootstrap-table/flex-bootstrap-table-filter.js';

export class FlexBootstrapTableFilter {
    private originalTableData: ITableData[];
    private tableID: String;
    private clearFilterButtonID: String;
    private clearAllFilterButtonID: String;
    private customFilterFunctions!: CustomFilterFunction[];
    private customSearchFunction!: Function;
    private filters = new FilterMap();
    private firstGo = true;
    private hasID = false;
    private idFilteredData!: ITableData[];

    constructor(id: string) {
        //initialize class variables
        this.tableID = '#' + id;
        this.clearFilterButtonID = '#' + id + '-clear-filter-button';
        this.clearAllFilterButtonID = '#' + id + '-clear-all-filter-button';
        this.originalTableData = JSON.parse(JSON.stringify($(this.tableID).bootstrapTable('getData', false)));

        //set up filter option data and event listeners
        this.initializeSearchInput();
        this.updateTableFiltration();
        this.addFilterListeners();
        this.updateFilterOptionAvailability();
    }

    private createFilterObjects = () => {
        //reinitialize variables
        this.filters = new FilterMap();

        //loop through each filter option
        document.querySelectorAll('.filter-option').forEach((filterElement) => {
            //get filter property values from the input element
            const input = $(filterElement).find('input').first()[0];
            const filterCategory = input.getAttribute('name')!;
            const checked = input.checked;
            const filterID = input.id;
            const filterName = filterID.split('-')[0];

            //put filter properties into an object
            const filterObject = new TableFilter(filterID, filterName, checked);

            //if there is no filter for that filter category, add the object as a new array
            if (this.filters.get(filterCategory) == undefined) {
                this.filters.set(filterCategory, [filterObject]);
            } else {
                //otherwise add the object the the array on the map
                let array = this.filters.get(filterCategory)!;
                array.push(filterObject);
                this.filters.set(filterCategory, array);
            }
        });
    }

    private updateFilterVariables = () => {
        //initialize variables
        let persistentFiltersName = window.location.pathname + '/filterMap';
        let persistentFilters = localStorage.getItem(persistentFiltersName);

        //if there are no persistent filters and it's not the first go reinitalize filter map with current and persist it
        if (!this.firstGo || (this.firstGo && persistentFilters == undefined)) {
            this.createFilterObjects();
            localStorage.setItem(persistentFiltersName, JSON.stringify(Array.from(this.filters.entries())));
        } else {
            this.filters = new Map(JSON.parse(persistentFilters!));
            this.updateSelections();
        }

        //it has been iterated through at least once
        this.firstGo = false;
    }

    private updateSelections = () => {
        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            //loop through each filter option and update their checked selections
            filterOptions.forEach((filter) => {
                let filterElement = document.getElementById(filter.filterID) as HTMLInputElement;
                if (filterElement != undefined) {
                    filterElement.checked = filter.checked;
                }
            });
        }
    }

    private initializeSearchInput = () => {
        //get the query string
        let query = document.location.search;

        //if the query string is valid
        if (query != '' && (query.toLowerCase().startsWith('?search=') || query.toLowerCase().startsWith('?id='))) {
            //clear filters to make search visible
            let persistentFiltersName = window.location.pathname + '/filterMap';
            localStorage.removeItem(persistentFiltersName);

            //get variables
            let search = query.substring(1);
            let searchElement = document.querySelector('input.search-input');
            let searchText = this.getSearchTextFromSearchQuery(search);

            //determine if it will need a custom filter
            if (search.startsWith('id=')) {
                //filter by ids present
                searchText = '';
                let ids = search.split('=')[1].split(',');
                this.filterByIds(ids);
            } else if (!search.includes('&id=')) {
                //simulate a search
                const ke = new KeyboardEvent('keydown', { key: 'Enter' });
                searchElement?.dispatchEvent(ke);
            } else {
                //filter on name and id
                let textArray = search.split('&');
                //get the query object that has the id
                textArray.find((text) => {
                    if (text.includes('id=')) {
                        //get the id and filter the data based on that and the search key
                        let ids = text.split('=')[1].split(',');
                        this.filterByIds(ids);
                    }
                });
            }
            //set the input value
            (searchElement as HTMLInputElement).value = searchText;

            //select the text on desktop
            if (window.innerWidth >= 768) {
                (document.querySelector('input.search-input') as HTMLInputElement).select();
            }
        }
    }

    private getSearchTextFromSearchQuery = (searchQuery: string) => {
        return searchQuery
            .split('&')[0]
            .split('=')[1]
            .replaceAll('%20', ' ')
            .replaceAll('%22', '"')
            .replaceAll('+', ' ')
            .replaceAll('_', ' ');
    }

    private filterByIds = (ids: string[]) => {
        //filter original data based off of id
        let id = this.tableID.substring(1);
        let filteredDataArray: ITableData[] = this.getOriginalTableData().filter(function (row: ITableData) {
            return ids.includes((row.id as string).replaceAll(id, '').replaceAll('Row', ''));
        });

        //set the new id and make sure to compensate for the new filtering
        $(this.getTableID()).bootstrapTable('load', filteredDataArray);
        this.hasID = true;
        this.idFilteredData = filteredDataArray;
    }

    private addFilterListeners = () => {
        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            //loop through each filter option and add a change event listener to update the filtration
            let filtersToRemove: TableFilter[] = [];
            filterOptions.forEach((filter) => {
                let filterElement = document.getElementById(filter.filterID);
                if (filterElement != undefined) {
                    filterElement.addEventListener('change', this.updateTableFiltration);
                } else {
                    filtersToRemove.push(filter);
                }
            });

            //loop through each filter that no longer exists and remove them
            filtersToRemove.forEach((filter) => {
                filterOptions.filter((filterOption) => filterOption != filter);
            });
        }

        //add clear filter button click event listener
        $(this.clearFilterButtonID).on('click', this.clearFiltration);
        $(this.clearAllFilterButtonID).on('click', this.clearAllFiltration);
    }

    private removeFilterListeners = () => {
        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            //loop through each filter option and remove the change event listener that updates the filtration
            filterOptions.forEach((filter) => {
                document.getElementById(filter.filterID)?.removeEventListener('change', this.updateTableFiltration);
            });
        }

        //remove clear filter button click event listener
        $(this.clearFilterButtonID).off('click', this.clearFiltration);
        $(this.clearAllFilterButtonID).off('click', this.clearAllFiltration);
    }

    private getNonNamedFunctionDataArray = (filterCategoryToNotAdd: string): ITableData[] => {
        //get original table data with the search filter applied
        var filteredTableData = this.accountForSearch();

        //loop through filter map
        for (let [filterCategory, filterOptions] of this.filters) {
            //only apply filters that are not in the requested filter category
            if (filterCategory != filterCategoryToNotAdd) {
                filteredTableData = this.defaultFiltrationFunction(filterCategory, filterOptions, filteredTableData);
            }
        }

        //return the filtered array
        return filteredTableData;
    }

    private updateFilterOptionAvailability = () => {
        //loop through filter map
        for (let [filterCategory, filterOptions] of this.filters) {
            this.updateEachOptionAvailability(filterCategory, filterOptions);
        }
    }

    private updateEachOptionAvailability = (filterCategory: string, filterOptions: TableFilter[]) => {
        //initialize variables
        var dataArray = this.getNonNamedFunctionDataArray(filterCategory);
        const originalArraySize = dataArray.length;

        //loop through each filter option
        filterOptions.forEach((filter) => {
            //initialize variables
            let newArraySize = originalArraySize;
            let input = document.getElementById(filter.filterID) as HTMLInputElement;

            if (input != undefined) {
                //if the option is not a show all
                if (filter.filterName != 'showall') {
                    //if the filter name category is a custom filter apply the custom filter
                    if (this.customFilterFunctions != null && this.customFilterFunctions.hasOwnProperty(filterCategory)) {
                        newArraySize = this.getCustomFilterFunctionFromCategory(filterCategory).runFilterFunction(
                            filter.filterName,
                            dataArray,
                        ).length;
                    } else {
                        //otherwise apply the default filter
                        newArraySize = dataArray.filter((option) => option[filterCategory] == filter.filterName).length;
                    }
                }

                //if the filtered array is empty and the filter is not checked, add disabled class and disable it
                if (newArraySize == 0 && !filter.checked) {
                    input.parentElement?.classList.add('contains-disabled-input');
                    input.disabled = true;
                } else {
                    //otherwise remove disabled class and enable it
                    input.parentElement?.classList.remove('contains-disabled-input');
                    input.disabled = false;
                }

                //update the availability count element
                (input.parentElement?.querySelector('span')?.querySelector('.filter-option-contains') as HTMLElement).innerHTML =
                    '(' + newArraySize + ')';
            }
        });
    }

    private getCustomFilterFunctionFromCategory = (filterCategory: string) => {
        return this.customFilterFunctions.filter((filterFunctionObject) => {
            filterFunctionObject.getCategory() === filterCategory;
        })[0];
    }

    public isShowAllSelectedBefore = (filterArray: TableFilter[]) => {
        return (
            filterArray.find((filter) => {
                return filter['showall'] === true;
            }) != undefined
        );
    }

    public isShowAllSelected = (filterArray: TableFilter[]) => {
        return (
            filterArray.find((filter) => {
                return (
                    filter.filterName == 'showall' &&
                    (document.getElementById(filter.filterID) as HTMLInputElement).checked === true
                );
            }) != undefined
        );
    }

    public isShowAllSelectedRecently = (filterArray: TableFilter[]) => {
        return !this.isShowAllSelectedBefore(filterArray) && this.isShowAllSelected(filterArray);
    }

    private onlyCheckShowAll = (filterOptions: TableFilter[]) => {
        //loop through each filter option
        filterOptions.forEach((filter) => {
            //check the show all option, and deselect all other options
            (document.getElementById(filter.filterID) as HTMLInputElement).checked = filter.filterName == 'showall';
        });
    }

    private removeCheckShowAll = (filterOptions: TableFilter[]) => {
        //loop through each filter option
        filterOptions.forEach((filter) => {
            //if it's a show all option deselect it
            if (filter.filterName == 'showall') {
                (document.getElementById(filter.filterID) as HTMLInputElement).checked = false;
            }
        });
    }

    private accountForShowAlls = () => {
        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            if (this.isShowAllSelected(filterOptions)) {
                if (this.isShowAllSelectedRecently(filterOptions)) {
                    this.onlyCheckShowAll(filterOptions);
                } else {
                    this.removeCheckShowAll(filterOptions);
                }
            }
        }
    }

    private isAnOptionSelected = (filterArray: TableFilter[]) => {
        return (
            filterArray.find((filter) => {
                return (document.getElementById(filter.filterID) as HTMLInputElement).checked === true;
            }) != undefined
        );
    }

    private accountForNoneSelected = () => {
        //loop through filter map and if nothing is selected check the show all option
        for (let [_, filterOptions] of this.filters) {
            if (!this.isAnOptionSelected(filterOptions)) {
                this.onlyCheckShowAll(filterOptions);
            }
        }
    }

    private isThereInput = (text: string) => {
        return (text != undefined || text != null) && text != '';
    }

    private accountForSearch = () => {
        //get the original table data
        var filteredTableData = this.getOriginalTableData();

        //get the search input
        var searchInput = $('.form-control.search-input').first().val() as string;

        //if there is a custom search function and there is a search input call it
        if (this.customSearchFunction != undefined && this.isThereInput(searchInput)) {
            filteredTableData = this.customSearchFunction(filteredTableData, searchInput);
        }

        //return the filtered array
        return filteredTableData;
    }

    public getCheckedBoxes = (filterOptions: TableFilter[]) => {
        //initialize variables
        var checkedFilteredOptions: TableFilter[] = [];

        //loop through each filter option
        filterOptions.forEach((filter) => {
            //if it's checked add it to the array
            if (filter.checked) {
                checkedFilteredOptions.push(filter);
            }
        });

        //return the checked boxes
        return checkedFilteredOptions;
    }

    private defaultFiltrationFunction = (filterCategory: string, filterOptions: TableFilter[], dataArray: ITableData[]) => {
        //initialize variables
        var filteredDataArray = new Set<ITableData>();

        //if show all is not selected apply filters
        if (!this.isShowAllSelected(filterOptions)) {
            //initialize variables
            var checkedFilteredOptions = this.getCheckedBoxes(filterOptions);

            //loop through each filter option
            checkedFilteredOptions.forEach((filter) => {
                if (filter.checked) {
                    //if the filter name category is a custom filter apply the custom filter
                    if (this.customFilterFunctions != null && this.customFilterFunctions.hasOwnProperty(filterCategory)) {
                        filteredDataArray = new Set<ITableData>([
                            ...filteredDataArray,
                            ...this.getCustomFilterFunctionFromCategory(filterCategory).runFilterFunction(filter.filterName, dataArray),
                        ]);
                    } else {
                        //otherwise apply the default filter
                        filteredDataArray = new Set<ITableData>([
                            ...filteredDataArray,
                            ...dataArray.filter((option) => option[filterCategory] == filter.filterName),
                        ]);
                    }
                }
            });

            //convert set to array
            dataArray = [...filteredDataArray];
        }

        //return array
        return dataArray;
    }

    private clearAllFiltration = () => {
        let searchElement = document.querySelector('input.search-input') as HTMLInputElement;
        searchElement.value = '';
        this.turnOffIdFilter();
        this.updateSearchParam();

        //select the text on desktop
        if (window.innerWidth >= 768) {
            (document.querySelector('input.search-input') as HTMLInputElement).select();
        }
        this.clearFiltration();
    }

    public updateSearchParam = () => {
        let searchValue = (document.querySelector('input.search-input') as HTMLInputElement).value as string;

        if (window.history.pushState) {
            const newURL = new URL(window.location.href);
            if (searchValue != '') {
                newURL.search = '?search=' + searchValue.replaceAll(' ', '_');
            } else {
                newURL.search = '';
            }

            window.history.pushState({ path: newURL.href }, '', newURL.href);
            this.turnOffIdFilter();
        }
    }

    private clearFiltration = () => {
        //make the clear silent
        this.removeFilterListeners();

        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            //if the show all option is not selected loop through each filter option and select the show all option
            if (!this.isShowAllSelected(filterOptions)) {
                filterOptions.forEach((filter) => {
                    if (filter.filterName == 'showall') {
                        (document.getElementById(filter.filterID) as HTMLInputElement).checked = true;
                    }
                });
            }
        }

        //update the filtration and add the listeners back
        this.updateTableFiltration();
        this.addFilterListeners();
    }

    private isThereAFilterSet = () => {
        //loop through filter map
        for (let [_, filterOptions] of this.filters) {
            //if the show all option is not selected return true
            if (!this.isShowAllSelected(filterOptions)) {
                return true;
            }
        }
        return false;
    }

    public showHideClearFilterButtons = () => {
        if (this.isThereAFilterSet()) {
            $(this.clearFilterButtonID).show();
            $(this.clearAllFilterButtonID).show();
        } else {
            $(this.clearFilterButtonID).hide();
            if (new URL(window.location.href).search != '') {
                $(this.clearAllFilterButtonID).show();
            } else {
                $(this.clearAllFilterButtonID).hide();
            }
        }
    }

    public updateTableFiltration = () => {
        //make sure the table data and filtration are initialized
        this.accountForShowAlls();
        this.accountForNoneSelected();
        this.updateFilterVariables();
        var filteredTableData = this.accountForSearch();

        //loop through filter map and filter the data
        for (let [filterCategory, filterOptions] of this.filters) {
            filteredTableData = this.defaultFiltrationFunction(filterCategory, filterOptions, filteredTableData);
        }

        //add how many items will be there after the filter option is selected
        this.updateFilterOptionAvailability();

        //show or hide Buttons based on new filter
        this.showHideClearFilterButtons();

        //set table data to filtered data
        $(this.getTableID()).bootstrapTable('load', this.sortData(filteredTableData));
        $(this.getTableID()).trigger(flexBootstrapTableEvents.filteredEvent);
    }

    private sortData = (filteredTableData: ITableData[]) => {
        let toSortDesc = $(this.getTableID()).find('.desc').first()[0];
        let toSortAsc = $(this.getTableID()).find('.asc').first()[0];

        if (toSortDesc != undefined) {
            let sortOn = toSortDesc.innerText.toLowerCase();
            return filteredTableData.sort(this.dynamicsort(sortOn, 'desc'));
        } else if (toSortAsc != undefined) {
            let sortOn = toSortAsc.innerText.toLowerCase();
            return filteredTableData.sort(this.dynamicsort(sortOn, 'asc'));
        } else {
            return filteredTableData;
        }
    }

    private dynamicsort = (property: string, order: string) => {
        let sortOrder = 1;
        if (order === 'desc') {
            sortOrder = -1;
        }
        return function (a: ITableData, b: ITableData) {
            if (!isNaN(a[property] as number)) {
                return ((a[property] as number) - (b[property] as number)) * sortOrder;
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
        };
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
    public setCustomFilterFunctions = (functions: CustomFilterFunction[]) => {
        this.customFilterFunctions = functions;
    }

    /*
        Add a custom search function by setting them here with a function like this:

        //get dependency
        import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";

        //set the custom function object
        let customSearchFunction = function (filteredTableData, searchInput) {
            return filteredTableData.filter(function (option) {
                //create a template element and set it to the weapon td
                var template = document.createElement('template');
                template.innerHTML = option.weapon;

                //get the weapon name and filter based on the search input
                return template.content.querySelector(".weaponName").innerHTML.toLowerCase().indexOf(searchInput.toLowerCase()) > -1;
            });
        };

        //Add it to the Custom Search function
        bootstrapTableFilter.addCustomSearch(customSearchFunction);
    */
    public addCustomSearch = (searchFunction: Function) => {
        this.customSearchFunction = searchFunction;
    }

    public revertFilteredData = () => {
        $(this.tableID).bootstrapTable('load', this.getOriginalTableData);
    }

    public getOriginalTableData = () => {
        return this.hasID ? JSON.parse(JSON.stringify(this.idFilteredData)) : JSON.parse(JSON.stringify(this.originalTableData));
    }

    private getTableID = () => {
        return this.tableID;
    }

    public getClearFilterButtonID = () => {
        return this.clearFilterButtonID;
    }

    private turnOffIdFilter = () => {
        this.hasID = false;
    }
}

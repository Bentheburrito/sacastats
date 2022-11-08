import * as FlexBootstrapTableEvents from "/js/events/flex-bootstrap-table-events.js";

let tableID;
let table;
let globalIndexOrder;
let globalColumns;
let previousColumns;
let previousSorted;
let animating = false;

const SortOrder = {
    NONE: undefined,
    ASCENDING: "asc",
    DESCENDING: "desc",
    getOrderKey(value) {
        return Object.keys(this).find(key => this[key] === value);
    }
};
const SortOrderIcon = {
    NONE: "fa-sort",
    ASCENDING: "fa-sort-up",
    DESCENDING: "fa-sort-down"
};

export function fixColumnDropDown() {
    //fix column dropdown offset and bugs
    let columnDropDown = document.querySelector("button[title='Columns']");
    if (columnDropDown != undefined) {
        columnDropDown.parentElement.lastChild.style.width = "20rem";

        columnDropDown.click();
        columnDropDown.click();
    }
}

function getSortedField() {
    //get table header elements based on asc and desc
    let toSortDesc = table.querySelector("." + SortOrder.DESCENDING);
    let toSortAsc = table.querySelector("." + SortOrder.ASCENDING);

    //initialize return variables
    let sortedFieldText;
    let order;

    //if there is a desc header
    if (toSortDesc != undefined) {
        sortedFieldText = toSortDesc.innerText;
        order = SortOrder.DESCENDING;

        //else if there is an asc header
    } else if (toSortAsc != undefined) {
        sortedFieldText = toSortAsc.innerText;
        order = SortOrder.ASCENDING;
    }

    //return the current sorted header and what order it is sorted
    return { "sortedFieldText": sortedFieldText, "order": order };
}

function setSortedField(sortedFieldText, sortTo) {
    //null check
    if (sortedFieldText != undefined) {
        //get header element based on text content
        let el = Array.from(table.querySelectorAll('div.th-inner')).find(el => el.textContent === sortedFieldText);

        //click header once to provide initial sort
        el.click();

        //if it should be sorted the other way click the header again
        if (![...el.classList].includes(sortTo)) {
            el.click();
        }

        //refresh by scroll to bring back sticky headers
        refreshByScroll();
    }
}

function refreshByScroll() {
    let currentScrollPosition = $(window).scrollTop();
    let maxScrollPosition = document.documentElement.scrollHeight - document.documentElement.clientHeight;

    if (currentScrollPosition == maxScrollPosition) {
        $(window).scrollTop(currentScrollPosition - 1);
    } else {
        $(window).scrollTop(currentScrollPosition + 1);
        $(window).scrollTop(currentScrollPosition - 1);
    }
}

function findVisibleFields() {
    //initialize variables
    var columns = $(tableID).bootstrapTable('getVisibleColumns');
    var fields = [];

    //add fields and titles to array
    for (var index in columns) {
        fields.push({
            "field": columns[index].field,
            "title": columns[index].title
        });
    }

    //return fields array
    return fields;
}

function findSortedVisibleFields() {
    //initialize variables
    let fields = findVisibleFields();
    let tempFields = [];

    //add all headers to array
    table.querySelectorAll('div.th-inner').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

    //return all columns
    return tempFields;
}

function findSortableVisibleColumns() {
    //initialize variables
    let fields = findVisibleFields();
    let tempFields = [];

    //add all headers with the sortable class to array
    table.querySelectorAll('div.th-inner.sortable').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

    //return sortable columns
    return tempFields;
}

function findNonSortableVisibleColumns() {
    //initialize variables
    let fields = findVisibleFields();
    let tempFields = [];

    //add all headers without the sortable class to array
    table.querySelectorAll('div.th-inner:not(.sortable)').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

    //return nonsortable columns
    return tempFields;
}

function initializeColumns() {
    //initialize variables
    const PERSISTENT_COLUMNS_NAME = table.id + "/columnMap";
    let persistentColumns = localStorage.getItem(PERSISTENT_COLUMNS_NAME);

    //if there are persistent columns, initialize new columns
    if (persistentColumns != undefined) {
        let persistentColumnsObject = JSON.parse(persistentColumns);
        setColumnVisibilitesAndSorts(persistentColumnsObject);
        setTimeout(() => { initializeMobileSortMenu(persistentColumnsObject) }, 150);
    }
}

function setColumnVisibilitesAndSorts(persistentColumns) {
    //hide all columns
    $(tableID).bootstrapTable('hideAllColumns');

    //create the index order of columns
    let indexOrder = [];
    persistentColumns["fields"].forEach(field => {
        let index = persistentColumns["fields"].findIndex(object => {
            return object["field"] === field["field"];
        });
        indexOrder.push(index);
    });

    //update global index orders and columns
    globalIndexOrder = indexOrder;
    globalColumns = persistentColumns;

    //restore column order and sorted field
    setColumnOrder();
    setSortedField(persistentColumns["sorted"]["sortedFieldText"], persistentColumns["sorted"]["order"]);
}

function setColumnOrder() {
    //initialize variables
    let orderObject = {};
    let array = []

    //loop through column order and add to orderObject
    for (let i = 0; i < globalIndexOrder.length; i++) {
        let object = {};
        object["index"] = globalIndexOrder[i];
        object["field"] = globalColumns["fields"][i]["field"]
        array.push(object);
        orderObject[globalColumns["fields"][i]["field"]] = globalIndexOrder[i];
    }

    //show each column that should be visible
    for (let i = 0; i < array.length; i++) {
        let fieldIndex = array.findIndex(object => {
            return object["index"] == i;
        });
        $(tableID).bootstrapTable('showColumn', array[fieldIndex]["field"]);
    }

    //set the column order
    setTimeout(() => { refreshDragColumns(orderObject) }, 100);
}

function refreshDragColumns(orderObject) {
    $(tableID).bootstrapTable('orderColumns', orderObject);
}

function moveColumnUp(selectedColumnElement) {
    //initialize variables
    let prevCol = $(selectedColumnElement).prev(),
        distance = $(selectedColumnElement).outerHeight();

    //if a previous column exists
    if (prevCol.length) {
        //start animation of column swap
        animating = true;
        $.when($(selectedColumnElement).animate({
            top: -distance
        }, 100),
            prevCol.animate({
                top: distance
            }, 100)).done(function () {
                //when animation is done reset element position
                prevCol.css('top', '0px');
                $(selectedColumnElement).css('top', '0px');

                //swap selected column with the previous one
                $(selectedColumnElement).insertBefore(prevCol);

                //notify animation completion
                animating = false;
            });
    }
}
function moveColumnDown(selectedColumnElement) {
    //initialize variables
    let nextCol = $(selectedColumnElement).next(),
        distance = $(selectedColumnElement).outerHeight();

    //if a next column exists
    if (nextCol.length) {
        //start animation of column swap
        animating = true;
        $.when($(nextCol).animate({
            top: -distance
        }, 100),
            $(selectedColumnElement).animate({
                top: distance
            }, 100)).done(function () {
                //when animation is done reset element position
                $(selectedColumnElement).css('top', '0px');
                nextCol.css('top', '0px');

                //swap selected column with the next one
                $(selectedColumnElement).insertAfter(nextCol);

                //notify animation completion
                animating = false;
            });
    }
}
function handleMoveColumnEvent(e) {
    //prevent clicks during swap
    if (animating) {
        return;
    }

    //make sure there is a selected column
    let selectedColumnElement = document.getElementById(table.id + "-sortable-columns").querySelector(".selected-sortable-column");
    if (selectedColumnElement == undefined) {
        return;
    }

    //initialize arrow element
    let arrow;
    if (e.target.tagName.toLowerCase() != "div") {
        arrow = $(e.target).closest("div")[0];
    } else {
        arrow = e.target;
    }

    //handle arrow function
    if (arrow.id.includes("up")) {
        moveColumnUp(selectedColumnElement);
    } else {
        moveColumnDown(selectedColumnElement);
    }

    setTimeout(() => { refreshSortableColumnSelection(selectedColumnElement) }, 110);
}

function createSortableColumn(dataField, text, sortType) {
    // Example creation:
    // <div id="weaponsTable-killedby-column" class="dropdown-item sortable-column">
    //  <span class="sortable-column-title">Killed By</span><i class="mobile-sort-icon fa-solid fa-sort-down"></i>
    // </div>

    //create outter div
    let div = document.createElement("div");
    div.id = table.id + "-" + dataField + "-column";
    div.classList.add("dropdown-item", "sortable-column");
    div.dataset.field = dataField;

    //create span title
    let span = document.createElement("span");
    span.classList.add("sortable-column-title");
    let spanText = document.createTextNode(text);
    span.appendChild(spanText);

    //create sort icon
    let icon = document.createElement("i");
    icon.classList.add("mobile-sort-icon", "fa-solid", SortOrderIcon[sortType]);

    //append title and icon to div
    div.appendChild(span);
    div.appendChild(icon);

    return div;
}

function initializeMobileSortMenu(persistentColumnsObject) {
    //initialize variables
    let sortableColumnMenu = document.getElementById(table.id + "-column-sort-dropdown-menu");
    let sortableColumnsContainer = document.getElementById(table.id + "-sortable-columns");
    let isReInitialization = sortableColumnsContainer.innerHTML != "";
    let currentScroll;

    //if it has already been initialized
    if (isReInitialization) {
        //save the current scroll and clear the columns
        currentScroll = sortableColumnMenu.scrollTop;
        sortableColumnsContainer.innerHTML = "";
    }

    //get all visible sortable columns and which one is sorted in what way
    let sortedField = persistentColumnsObject["sorted"];
    let columns = findSortableVisibleColumns();

    //for each column
    columns.forEach(column => {
        //set sort type to none
        let sortType = SortOrder.getOrderKey(undefined);

        //if the column should be sorted set the specific sort type
        if (column.title == sortedField.sortedFieldText) {
            sortType = SortOrder.getOrderKey(sortedField.order);
        }

        //create the column element and add an alt and click listener to handle selecting and sorting respectively
        let columnElement = createSortableColumn(column.field, column.title, sortType);
        columnElement.addEventListener("contextmenu", handleSortableColumnContextMenu);
        columnElement.addEventListener("click", handleSortableColumnClick);

        //add column element to container
        sortableColumnsContainer.appendChild(columnElement);
    });

    //if it was already initialized restore scroll position
    if (isReInitialization) {
        sortableColumnMenu.scrollTop = currentScroll;
    }
}

function handleInitialMobileSortButtonClick() {
    //when initially opening the menu, it must be opened then close to open in the right position
    let buttonElement = document.getElementById(table.id + "-column-sort-button");
    buttonElement.click();
    buttonElement.click();

    //this should only need to be done once so this can be removed
    buttonElement.removeEventListener("click", handleInitialMobileSortButtonClick);
}

function isOpeningMobileSortMenu(target) {
    return target.id == table.id + "-column-sort-button" && !$(target).attr('aria-expanded');
}

function isMobileSortMenuClosed(target) {
    return target.id != table.id + "-column-sort-button" && !$("#" + table.id + "-column-sort-button").attr('aria-expanded');
}

function handleColumnOrderSorted(e) {
    //check if columns should be reordered
    let target;
    if (e.target.tagName.toLowerCase() == "svg" || e.target.tagName.toLowerCase() == "path") {
        target = $(e.target).closest("div")[0];
    } else {
        target = e.target;
    }

    //early return if columns should NOT be reordered
    if (target.id.includes("up") || target.id.includes("down") || isOpeningMobileSortMenu(target) || isMobileSortMenuClosed(target)) {
        return;
    }

    //remove selection
    removeSortableColumnSelection();

    //create order object
    let index = 0;
    let orderObject = {};

    //account for non sortable headers
    findNonSortableVisibleColumns().forEach(nonSortableColumn => {
        orderObject[nonSortableColumn.field] = index;
        index++;
    });

    //add sortable headers to orderObject
    document.getElementById(table.id + "-sortable-columns").childNodes.forEach(column => {
        orderObject[column.dataset.field] = index;
        index++;
    });

    //update column orders
    refreshDragColumns(orderObject);
}

function updatePersistentColumns() {
    //initialize variables
    let fields = findSortedVisibleFields();
    let sorted = getSortedField();
    let persistentColumnsObject = { "fields": fields, "sorted": sorted };

    //update persistant column choices
    const PERSISTENT_COLUMNS_NAME = table.id + "/columnMap";
    localStorage.removeItem(PERSISTENT_COLUMNS_NAME);
    localStorage.setItem(PERSISTENT_COLUMNS_NAME, JSON.stringify(persistentColumnsObject));

    //reinitialize mobile sort menu with new data
    initializeMobileSortMenu(persistentColumnsObject);
}

function handleColumnChangedEvent(event, columns) {
    //parse column array and update previous columns
    columns = JSON.parse(columns);
    previousColumns = columns;

    //update persistant columns
    updatePersistentColumns();
}

function handleSortChangedEvent(event, sorted) {
    //get sorted column and update previous sorted column
    previousSorted = sorted;

    //update persistant columns
    updatePersistentColumns();
}

function addEventHandlers() {
    //add event listeners for mobile column move arrows
    document.getElementById(table.id + "-column-move-up").addEventListener("click", handleMoveColumnEvent);
    document.getElementById(table.id + "-column-move-down").addEventListener("click", handleMoveColumnEvent);

    //add event listener for column sort button
    document.getElementById(table.id + "-column-sort-button").addEventListener("click", handleInitialMobileSortButtonClick);

    //add event listeners for locking new column order
    document.addEventListener("click", handleColumnOrderSorted);
    document.getElementById(table.id + "-column-sort-dropdown-menu").addEventListener("click", handleColumnOrderSorted);

    //add event listeners for custom column change events
    $(table).on(FlexBootstrapTableEvents.COLUMNS_CHANGED_EVENT, handleColumnChangedEvent);
    $(table).on(FlexBootstrapTableEvents.COLUMN_SORT_CHANGED_EVENT, handleSortChangedEvent);
}

function setMoveArrowsOffsets(topOffset) {
    document.getElementById(table.id + "-column-move-up").style.top = topOffset + "px";
    document.getElementById(table.id + "-column-move-down").style.top = topOffset + "px";
}

function updateMoveArrowPositions(selectedColumnElement) {
    let columnMoveTopOffset = selectedColumnElement.offsetTop + (selectedColumnElement.offsetHeight / 2) + 23;
    setMoveArrowsOffsets(columnMoveTopOffset);
}

function removeSortableColumnSelection() {
    let selectedColumnElement = document.getElementById(table.id + "-sortable-columns").querySelector(".selected-sortable-column");
    if (selectedColumnElement != undefined) {
        //remove highlight
        selectedColumnElement.classList.remove("selected-sortable-column");

        //hide arrows
        document.getElementById(table.id + "-column-move-up").classList.add("d-none");
        document.getElementById(table.id + "-column-move-down").classList.add("d-none");
    }
}

function addSortableColumnSelection(selectedColumnElement) {
    selectedColumnElement.classList.add("selected-sortable-column");

    //if the selected column is not the top column show the move up arrow
    if ($(selectedColumnElement).prev().length == 1) {
        document.getElementById(table.id + "-column-move-up").classList.remove("d-none");
    }

    //if the selected column is not the bottom column show the move down arrow
    if ($(selectedColumnElement).next().length == 1) {
        document.getElementById(table.id + "-column-move-down").classList.remove("d-none");
    }
}

function refreshSortableColumnSelection(selectedColumnElement) {
    removeSortableColumnSelection();

    updateMoveArrowPositions(selectedColumnElement);

    addSortableColumnSelection(selectedColumnElement);
}

function handleSortableColumnContextMenu(e) {
    //initialize column element selection
    let selectedColumnElement;
    if (e.target.classList.contains("sortable-column")) {
        selectedColumnElement = e.target;
    } else {
        selectedColumnElement = $(e.target).closest(".sortable-column")[0];
    }

    refreshSortableColumnSelection(selectedColumnElement);

    e.preventDefault(); //blocks default Webbrowser right click menu
}

function handleSortableColumnClick(e) {
    //initialize column element
    let columnElement;
    if (e.target.classList.contains("sortable-column")) {
        columnElement = e.target;
    } else {
        columnElement = $(e.target).closest(".sortable-column")[0];
    }

    //get corresponding table header and mobile column sort menu
    let tableColumnHeaderElement = table.querySelector("thead > tr > th[data-field='" + columnElement.dataset.field + "'] > div.th-inner");
    let sortableMenuButtonElement = document.getElementById(table.id + "-column-sort-button");

    //click the corresponding table header to sort then reopen the mobile column sort menu
    tableColumnHeaderElement.click();
    sortableMenuButtonElement.click();
}

function checkIfAColumnDifferent() {
    //if there is a different column visible or they are in a new order, trigger custom event
    let columns = findSortedVisibleFields();
    if (JSON.stringify(columns) !== JSON.stringify(previousColumns)) {
        $(table).trigger(FlexBootstrapTableEvents.COLUMNS_CHANGED_EVENT, JSON.stringify(columns));
    }
}

function checkIfASortDifferent() {
    //if there is a different column sorted or the sort is different, trigger custom event
    let sorted = getSortedField();
    if (JSON.stringify(sorted) !== JSON.stringify(previousSorted)) {
        $(table).trigger(FlexBootstrapTableEvents.COLUMN_SORT_CHANGED_EVENT, sorted);
    }
}

export function updateColumns() {
    checkIfAColumnDifferent();
    checkIfASortDifferent();
}

export function init(id) {
    //initialize class variables
    tableID = '#' + id;
    table = document.getElementById(id);

    initializeColumns();
    addEventHandlers();
}

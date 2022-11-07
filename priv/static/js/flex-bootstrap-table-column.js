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
    let toSortDesc = table.querySelector("." + SortOrder.DESCENDING);
    let toSortAsc = table.querySelector("." + SortOrder.ASCENDING);

    let sortedFieldText;
    let order;
    if (toSortDesc != undefined) {
        sortedFieldText = toSortDesc.innerText;
        order = SortOrder.DESCENDING;
    } else if (toSortAsc != undefined) {
        sortedFieldText = toSortAsc.innerText;
        order = SortOrder.ASCENDING;
    }

    return { "sortedFieldText": sortedFieldText, "order": order };
}

function setSortedField(sortedFieldText, sortTo) {
    if (sortedFieldText != undefined) {
        let el = Array.from(table.querySelectorAll('div.th-inner')).find(el => el.textContent === sortedFieldText);

        el.click();
        if (![...el.classList].includes(sortTo)) {
            el.click();
        }
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
    var columns = $(tableID).bootstrapTable('getVisibleColumns');
    var fields = [];

    for (var index in columns) {
        fields.push({
            "field": columns[index].field,
            "title": columns[index].title
        });
    }
    return fields;
}

function findSortedVisibleFields() {
    let fields = findVisibleFields();
    let tempFields = [];
    table.querySelectorAll('div.th-inner').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

    return tempFields;
}

function findSortableVisibleColumns() {
    let fields = findVisibleFields();
    let tempFields = [];
    table.querySelectorAll('div.th-inner.sortable').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

    return tempFields;
}

function findNonSortableVisibleColumns() {
    let fields = findVisibleFields();
    let tempFields = [];
    table.querySelectorAll('div.th-inner:not(.sortable)').forEach(header => {
        for (let i = 0; i < fields.length; i++) {
            if (fields[i].title == header.innerText) {
                tempFields.push(fields[i]);
                break;
            }
        }
    });

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
    $(tableID).bootstrapTable('hideAllColumns');

    let indexOrder = [];
    persistentColumns["fields"].forEach(field => {
        let index = persistentColumns["fields"].findIndex(object => {
            return object["field"] === field["field"];
        });
        indexOrder.push(index);
    });

    globalIndexOrder = indexOrder;
    globalColumns = persistentColumns;

    setColumnOrder();
    setSortedField(persistentColumns["sorted"]["sortedFieldText"], persistentColumns["sorted"]["order"]);
}

function setColumnOrder() {
    let orderObject = {};
    let array = []
    for (let i = 0; i < globalIndexOrder.length; i++) {
        let object = {};
        object["index"] = globalIndexOrder[i];
        object["field"] = globalColumns["fields"][i]["field"]
        array.push(object);
        orderObject[globalColumns["fields"][i]["field"]] = globalIndexOrder[i];
    }

    for (let i = 0; i < array.length; i++) {
        let fieldIndex = array.findIndex(object => {
            return object["index"] == i;
        });
        $(tableID).bootstrapTable('showColumn', array[fieldIndex]["field"]);
    }
    setTimeout(() => { refreshDragColumns(orderObject) }, 100);
}

function refreshDragColumns(orderObject) {
    $(tableID).bootstrapTable('orderColumns', orderObject);
}

function moveColumnUp(selectedColumnElement) {
    let prevCol = $(selectedColumnElement).prev(),
        distance = $(selectedColumnElement).outerHeight();

    if (prevCol.length) {
        animating = true;
        $.when($(selectedColumnElement).animate({
            top: -distance
        }, 100),
            prevCol.animate({
                top: distance
            }, 100)).done(function () {
                prevCol.css('top', '0px');
                $(selectedColumnElement).css('top', '0px');
                $(selectedColumnElement).insertBefore(prevCol);
                animating = false;
            });
    }
}
function moveColumnDown(selectedColumnElement) {
    let nextCol = $(selectedColumnElement).next(),
        distance = $(selectedColumnElement).outerHeight();

    if (nextCol.length) {
        animating = true;
        $.when($(nextCol).animate({
            top: -distance
        }, 100),
            $(selectedColumnElement).animate({
                top: distance
            }, 100)).done(function () {
                $(selectedColumnElement).css('top', '0px');
                nextCol.css('top', '0px');
                $(selectedColumnElement).insertAfter(nextCol);
                animating = false;
            });
    }
}
function handleMoveColumnEvent(e) {
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
    let sortableColumnMenu = document.getElementById(table.id + "-column-sort-dropdown-menu");
    let sortableColumnsContainer = document.getElementById(table.id + "-sortable-columns");
    let isReInitialization = sortableColumnsContainer.innerHTML != "";
    let currentScroll;
    if (isReInitialization) {
        currentScroll = sortableColumnMenu.scrollTop;
        sortableColumnsContainer.innerHTML = "";
    }

    let sortedField = persistentColumnsObject["sorted"];
    let columns = findSortableVisibleColumns();
    columns.forEach(column => {
        let sortType = SortOrder.getOrderKey(undefined);
        if (column.title == sortedField.sortedFieldText) {
            sortType = SortOrder.getOrderKey(sortedField.order);
        }

        let columnElement = createSortableColumn(column.field, column.title, sortType);
        columnElement.addEventListener("contextmenu", handleSortableColumnContextMenu);
        columnElement.addEventListener("click", handleSortableColumnClick);

        sortableColumnsContainer.appendChild(columnElement);
    });

    if (isReInitialization) {
        sortableColumnMenu.scrollTop = currentScroll;
    }
}

function handleInitialMobileSortButtonClick() {
    let buttonElement = document.getElementById(table.id + "-column-sort-button");
    buttonElement.click();
    buttonElement.click();

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

    document.getElementById(table.id + "-sortable-columns").childNodes.forEach(column => {
        orderObject[column.dataset.field] = index;
        index++;
    });

    //update column orders
    refreshDragColumns(orderObject);
}

function updatePersistentColumns() {
    let fields = findSortedVisibleFields();
    let sorted = getSortedField();
    let persistentColumnsObject = { "fields": fields, "sorted": sorted };

    const PERSISTENT_COLUMNS_NAME = table.id + "/columnMap";
    localStorage.removeItem(PERSISTENT_COLUMNS_NAME);
    localStorage.setItem(PERSISTENT_COLUMNS_NAME, JSON.stringify(persistentColumnsObject));

    initializeMobileSortMenu(persistentColumnsObject);
}

function handleColumnChangedEvent(event, columns) {
    columns = JSON.parse(columns);
    previousColumns = columns;

    updatePersistentColumns();
}

function handleSortChangedEvent(event, sorted) {
    previousSorted = sorted;

    updatePersistentColumns();
}

function addEventHandlers() {
    document.getElementById(table.id + "-column-move-up").addEventListener("click", handleMoveColumnEvent);
    document.getElementById(table.id + "-column-move-down").addEventListener("click", handleMoveColumnEvent);

    document.getElementById(table.id + "-column-sort-button").addEventListener("click", handleInitialMobileSortButtonClick);

    document.addEventListener("click", handleColumnOrderSorted);
    document.getElementById(table.id + "-column-sort-dropdown-menu").addEventListener("click", handleColumnOrderSorted);

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
        selectedColumnElement.classList.remove("selected-sortable-column");
        document.getElementById(table.id + "-column-move-up").classList.add("d-none");
        document.getElementById(table.id + "-column-move-down").classList.add("d-none");
    }
}

function addSortableColumnSelection(selectedColumnElement) {
    selectedColumnElement.classList.add("selected-sortable-column");

    if ($(selectedColumnElement).prev().length == 1) {
        document.getElementById(table.id + "-column-move-up").classList.remove("d-none");
    }

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
    let columnElement;
    if (e.target.classList.contains("sortable-column")) {
        columnElement = e.target;
    } else {
        columnElement = $(e.target).closest(".sortable-column")[0];
    }

    let tableColumnHeaderElement = table.querySelector("thead > tr > th[data-field='" + columnElement.dataset.field + "'] > div.th-inner");
    let sortableMenuButtonElement = document.getElementById(table.id + "-column-sort-button");

    tableColumnHeaderElement.click();
    sortableMenuButtonElement.click();
}

function checkIfAColumnDifferent() {
    let columns = findSortedVisibleFields();
    if (JSON.stringify(columns) !== JSON.stringify(previousColumns)) {
        $(table).trigger(FlexBootstrapTableEvents.COLUMNS_CHANGED_EVENT, JSON.stringify(columns));
    }
}

function checkIfASortDifferent() {
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

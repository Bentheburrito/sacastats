let tableID;
let table;
let globalIndexOrder;
let globalColumns;

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
    let toSortDesc = table.querySelector(".desc");
    let toSortAsc = table.querySelector(".asc");

    let sortedFieldText;
    let order;
    if (toSortDesc != undefined) {
        sortedFieldText = toSortDesc.innerText;
        order = "desc";
    } else if (toSortAsc != undefined) {
        sortedFieldText = toSortAsc.innerText;
        order = "asc";
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
    window.scrollBy(0, -1);
    window.scrollBy(0, 1);
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

function initializeColumns() {
    //initialize variables
    let persistentColumnsName = table.id + "/columnMap";
    let persistentColumns = localStorage.getItem(persistentColumnsName);

    //if there are persistent columns, initialize new columns
    if (persistentColumns != undefined) {
        setColumnVisibilitesAndSorts(JSON.parse(persistentColumns));
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

export function updateColumns() {
    let persistentColumnsName = table.id + "/columnMap";
    localStorage.removeItem(persistentColumnsName);

    let fields = findSortedVisibleFields();
    let sorted = getSortedField();
    localStorage.setItem(persistentColumnsName, JSON.stringify({ "fields": fields, "sorted": sorted }));
}

export function init(id) {
    //initialize class variables
    tableID = '#' + id;
    table = document.getElementById(id);

    initializeColumns();
}

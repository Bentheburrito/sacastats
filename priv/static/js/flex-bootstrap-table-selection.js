//initialize variables
let startRowIndex; //dragged main selection index
let selectedRowIndex; //click main selection index
let currentRowIndex; //last index pressed
let prevRowIndex; //predicted previous index pressed
let dragged = false;
let upDown = false; //up is true down is false

let mainSelectionClass = "main-selected";
let selectionClass = "selection";
let customCopyFunction;

//selection helper lists
let rowArray;
let copyRows = new Set();

//ids
let tableID;
let copyLinkID;
let contextMenuID;
let copyToastID;

function addRightClickTable() {
    //add special Right click on table menu
    $(tableID).on('contextmenu', function (e) {
        //initialize special menu location
        var top = ((e.clientY / $(window).height()) * 100) + "%";
        var left = ((e.clientX / $(window).width()) * 100) + "%";

        //show special menu at the bottom right of the mouse
        $(contextMenuID).css({
            display: "block",
            position: "fixed",
            top: top,
            left: left
        }).addClass("show");

        //get the row
        let row = $(e.target).closest("tr")[0];

        //if it's not selected and the control key wasn't pressed reset the selection
        if (!row.classList.contains(selectionClass) && !e.ctrlKey) {
            resetCopyRowSelection();

            //if the shift key was pressed, select start index to recently clicked index
            if (e.shiftKey) {
                selectStartToCurrent(getRowArrayIndex(row));
            }
        }
        //add current row to selection
        addRowToSelection(row, e);

        return false; //blocks default Webbrowser right click menu
    });

    //update selections
    $(tableID).on('click', function (e) {
        //hide the special menu and initialize variables
        hideContextMenu();

        //make sure it's only tbody rows being clicked
        let row = $(e.target).closest("tr")[0];
        if (!dragged) {
            if (overARow(row)) {
                //if it's a new selection set reset the selections
                if (copyRows.size > 0 && !e.ctrlKey && !e.shiftKey) {
                    resetCopyRowSelection(e);
                }

                //disable on-click selection for mobile
                if (!isMobileScreen()) {
                    //if the ctrl key was pressed while a selection was clicked remove it
                    let rowIndex = getRowArrayIndex(row);
                    if (e.ctrlKey && copyRows.has(row) && copyRows.size > 1) {
                        deleteRowFromSelection(row);
                    } else if (selectedRowIndex != undefined && e.shiftKey) {
                        resetCopyRowSelection(e);
                        selectSelectionToCurrent(rowIndex);
                    } else if (e.ctrlKey) {
                        if (copyRows.has(row)) {
                            deleteRowFromSelection(row);
                        } else {
                            addRowToSelection(row, e);
                        }
                    } else {
                        //otherwise just add the current row to selection
                        if (isThereAMainSelection()) {
                            startRowIndex = rowIndex;
                        }
                        selectedRowIndex = rowIndex;
                        addRowToSelection(row);
                    }
                }
            } else {
                resetCopyRowSelection(e);
            }
        }
    });

    //add event listner for copy click
    $(copyLinkID).on('click', function () {
        $(copyToastID).toast('show');
        hideContextMenu();
    });

    //add page click events
    $(document).on("click", function (e) {
        //if the click is not in the table remove selections and hide the special menu
        if ($(e.target).closest("table")[0] == undefined && !dragged) {
            resetCopyRowSelection(e);
            hideContextMenu();
        }
    });

    //add page key events
    $(document).on("keyup", function (e) {
        //if the user presses ctrl-C with something selected copy selected rows
        if (e.key === 'c' && e.ctrlKey && copyRows.size > 0) {
            copySelectedRows();
            $(copyToastID).toast('show');
        }
    });

    //add page right click events to hide special menu
    $(document).on("contextmenu", function () {
        hideContextMenu();
    });

    //hide the special menu when an option is clicked
    $(contextMenuID).on("click", function () {
        hideContextMenu();
    });

    //add copy clicks
    addCopyClick();
    addTableMove();
}

function resetCopyRowSelection(e) {
    //remove the selection style from each row and reinit the set
    copyRows.forEach(row => {
        $(row).removeClass(selectionClass).removeClass(mainSelectionClass);
    });
    copyRows = new Set();
    if (e == undefined || !e.shiftKey) {
        selectedRowIndex = undefined;
    }
}

function hideContextMenu() {
    $(contextMenuID).removeClass("show").hide();
}

function addCopyClick() {
    $(copyLinkID).on('click', copySelectedRows);
}

function addTableMove() {
    $(tableID).on('mousedown', function (e) {
        let row = $(e.target).closest("tr")[0];
        if (overARow(row)) {
            $(tableID).off('mousemove', tableMouseMoveEventHandler);
            $(tableID).on('mousemove', tableMouseMoveEventHandler);
        }
        dragged = false;
    });
    $(document).on('mouseup', function (e) {
        $(tableID).off('mousemove', tableMouseMoveEventHandler);

        setTimeout(function () {
            if (dragged) {
                dragged = false;
                selectedRowIndex = startRowIndex;
            }
        }, 10);
    });
}

let prevDate = new Date().getTime();
function tableMouseMoveEventHandler(e) {
    var date = new Date().getTime();
    if (date - prevDate > 2) {
        let row = $(e.target).closest("tr")[0];
        let rowIndex = getRowArrayIndex(row);
        if (!dragged) {
            startRowIndex = rowIndex;
            if (!e.shiftKey && !e.ctrlKey) {
                resetCopyRowSelection(e);
            } else if (e.shiftKey && $('.' + selectionClass).length > 0) {
                startRowIndex = selectedRowIndex;
                resetCopyRowSelection();
                selectStartToCurrent(rowIndex);
                prevRowIndex = rowIndex;
                upDown = isSelectionAboveStart(rowIndex);
                if (upDown) {
                    prevRowIndex++;
                } else {
                    prevRowIndex--;
                }
            }
            currentRowIndex = rowIndex;
        }
        if (overARow(row)) {
            toggleSelectionDrag(row);
        }
        prevDate = date;
    }
}

function toggleSelectionDrag(row) {
    let rowIndex = getRowArrayIndex(row);
    //console.log(rowIndex + " " + startRowIndex + " " + selectedRowIndex + " " + currentRowIndex + " " + prevRowIndex);

    if (isSelectionMoveValid(rowIndex)) {
        if (!copyRows.has(row)) {
            addRowToSelection(row);
            upDown = (rowIndex <= startRowIndex);
            prevRowIndex = currentRowIndex;
        } else if (startRowIndex != currentRowIndex && rowIndex == prevRowIndex) {
            deleteRowFromSelection(rowArray[currentRowIndex]);
            if (upDown) {
                prevRowIndex++;
            } else {
                prevRowIndex--;
            }
        }
    } else {
        resetCopyRowSelection();
        selectStartToCurrent(rowIndex);
        prevRowIndex = rowIndex;
        upDown = isSelectionAboveStart(rowIndex);
        if (upDown) {
            prevRowIndex++;
        } else {
            prevRowIndex--;
        }
    }
    if (rowIndex != startRowIndex) {
        currentRowIndex = rowIndex;
    } else {
        if (prevRowIndex != startRowIndex) {
            deleteRowFromSelection(rowArray[prevRowIndex]);
        }
        prevRowIndex = undefined;
        currentRowIndex = startRowIndex;
    }
    selectedRowIndex = currentRowIndex;
    dragged = true;
}

function selectStartToCurrent(rowIndex) {
    if (isSelectionAboveStart(rowIndex)) {
        for (let i = startRowIndex; i >= rowIndex; i--) {
            addRowToSelection(rowArray[i]);
        }
    } else {
        for (let i = startRowIndex; i <= rowIndex; i++) {
            addRowToSelection(rowArray[i]);
        }
    }
}

function selectSelectionToCurrent(rowIndex) {
    if (isSelectionAboveSelection(rowIndex)) {
        for (let i = selectedRowIndex; i >= rowIndex; i--) {
            addRowToSelection(rowArray[i]);
        }
    } else {
        for (let i = selectedRowIndex; i <= rowIndex; i++) {
            addRowToSelection(rowArray[i]);
        }
    }
}

function isSelectionAboveStart(rowIndex) {
    return rowIndex < startRowIndex;
}

function isSelectionAboveSelection(rowIndex) {
    return rowIndex < selectedRowIndex;
}

function isSelectionMoveValid(rowIndex) {
    return currentRowIndex == rowIndex || rowIndex == currentRowIndex + 1 || rowIndex == currentRowIndex - 1;
}

function getRowArrayIndex(row) {
    if (row != undefined) {
        rowArray = [...$(tableID).find("tbody").first()[0].children];
        return rowArray.findIndex(object => {
            return object.id === row.id;
        });
    } else {
        return undefined;
    }
}

function deleteRowFromSelection(row) {
    copyRows.delete(row);
    $(row).removeClass(selectionClass).removeClass(mainSelectionClass);
    let rowIndex = getRowArrayIndex(row);
    if (!dragged && startRowIndex != rowIndex && rowIndex == selectedRowIndex) {
        $('.' + selectionClass).removeClass(mainSelectionClass);
    }
    if (!isThereAMainSelection()) {
        mainSelectClosestSelection(rowIndex);
    }
}

function addRowToSelection(row, e) {
    copyRows.add(row);
    $(row).addClass(selectionClass);
    let rowIndex = getRowArrayIndex(row);

    if (isCtrlKeyPressedAndChangesStart(rowIndex, e)) {
        startRowIndex = rowIndex;
        selectedRowIndex = rowIndex;
        $('.' + selectionClass).removeClass(mainSelectionClass);
        $(row).add(mainSelectionClass);
    } else if (startRowIndex == getRowArrayIndex(row)) {
        $('.' + selectionClass).add(mainSelectionClass);
    }
    if (!isThereAMainSelection()) {
        mainSelectClosestSelection(getRowArrayIndex(row));
    }
}

function isThereAMainSelection() {
    return $('.' + mainSelectionClass).length != 0;
}

function isCtrlKeyPressedAndChangesStart(rowIndex, e) {
    return (copyRows.length > 1 && !dragged && e != undefined && e.ctrlKey && ((upDown && rowIndex > startRowIndex) || (!upDown && rowIndex < startRowIndex))) || (!dragged && e != undefined && e.ctrlKey);
}

function mainSelectClosestSelection(rowIndex) {
    let i = rowIndex;
    let iFound = false;
    let j = rowIndex;
    let jFound = false;
    for (; i < rowArray.length; i++) {
        if (rowArray[i].classList.contains(selectionClass)) {
            iFound = true;
            break;
        }
    }

    for (; j >= 0; j--) {
        if (rowArray[j].classList.contains(selectionClass)) {
            jFound = true;
            break;
        }
    }

    if (iFound && jFound) {
        if (Math.abs(i - rowIndex) >= Math.abs(j - rowIndex)) {
            updateIndexVariablesAfterSwap(j);
        } else {
            updateIndexVariablesAfterSwap(i);
        }
    } else if (iFound && !jFound) {
        updateIndexVariablesAfterSwap(i);
    } else if (!iFound && jFound) {
        updateIndexVariablesAfterSwap(j);
    } else {
        return;
    }
}

function updateIndexVariablesAfterSwap(newIndex) {
    $(rowArray[newIndex]).addClass(mainSelectionClass);
    startRowIndex = newIndex;
    selectedRowIndex = newIndex;
}

function isMobileScreen() {
    return window.innerWidth <= 767;
}

function overARow(row) {
    return row != undefined && row.localName == "tr" && row.parentElement.localName == "tbody";
}

function copySelectedRows(e) {
    let copyString = "";
    if (customCopyFunction != undefined) {
        copyString = customCopyFunction();
    } else {
        let headerArray = [...$(tableID).find('thead').first().find('tr').first()[0].children];
        let index = 0;
        copyRows.forEach(row => {
            let dataArray = $(row).find('td');
            copyString = copyString + headerArray[0].innerText + ": " + dataArray[0].innerText;
            for (let i = 1; i < dataArray.length; i++) {
                copyString = copyString + ", " + headerArray[i].innerText + ": " + dataArray[i].innerText;
            }
            if (index < copyRows.size - 1) {
                copyString = copyString + "\n\n";
                index++;
            }

        });
    }

    //copy the new url to clipboard and reset selection
    navigator.clipboard.writeText(copyString);
    resetCopyRowSelection(e);
}

export function getSelectedRows() {
    return copyRows;
}

export function setCustomCopyFunction(customFunction) {
    customCopyFunction = customFunction;
}

export function init(id) {
    tableID = '#' + id;
    copyLinkID = tableID + "-copy-link";
    contextMenuID = tableID + "-context-menu";
    copyToastID = tableID + "-copy-toast";
    rowArray = [...$(tableID).find("tbody").first()[0].children];

    addRightClickTable();
}

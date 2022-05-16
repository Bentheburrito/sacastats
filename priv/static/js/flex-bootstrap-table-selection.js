//initialize variables
let startRowIndex; //dragged main selection index
let selectedRowIndex; //click main selection index
let currentRowIndex; //last index pressed
let prevRowIndex; //predicted previous index pressed
let dragged = false;
let upDown = false; //up is true down is false

let mainSelectionClass = "main-selected";
let selectionClass = "selection";
let mobileSelectionMenu = "selection-mobile-menu";
let customCopyFunction;
let secondCustomCopyFunction;

//selection helper lists
let rowArray;
let copyRows = new Set();

//ids
let tableID;
let copyLinkID;
let copyTextID;
let contextMenuID;
let copyToastID;

function addRightClickTable() {
    //add special Right click on table menu
    $(tableID).on('contextmenu', function (e) {
        //get the row
        let row = $(e.target).closest("tr")[0];

        if (!isMobileScreen()) {
            //initialize special menu location
            let isFireFox = navigator.userAgent.indexOf("Firefox") != -1;
            let yAdj = (e.clientY + $(contextMenuID).height() > $(window).height()) ? (e.clientY - $(contextMenuID).height() - (isFireFox ? 0 : 5)) : e.clientY; //adjust height to show all of menu
            let xAdj = (e.clientX + $(contextMenuID).width() > $(window).width()) ? (e.clientX - $(contextMenuID).width() - (isFireFox ? 0 : 2)) : e.clientX; //adjust width to show all of menu
            var top = ((yAdj / $(window).height()) * 100) + "%";
            var left = ((xAdj / $(window).width()) * 100) + "%";

            //show special menu at the bottom right of the mouse
            $(contextMenuID).css({
                display: "block",
                position: "fixed",
                top: top,
                left: left
            }).addClass("show");

            //if it's not selected and the control key wasn't pressed reset the selection
            if (!row.classList.contains(selectionClass) && !e.ctrlKey) {
                resetCopyRowSelection();

                //if the shift key was pressed, select start index to recently clicked index
                if (e.shiftKey) {
                    selectStartToCurrent(getRowArrayIndex(row));
                }
            }

            //if it's a mobile screen and the row is already selected, delete it and return false to block default right click menu
        } else if (copyRows.has(row)) {
            deleteRowFromSelection(row);
            return false;
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
                if (copyRows.size > 0 && !e.ctrlKey && !e.shiftKey && !isMobileScreen()) {
                    resetCopyRowSelection(e);
                }

                //disable on-click selection for mobile without others selected
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
                } else if (copyRows.size > 0 || $("." + mobileSelectionMenu).is(":visible")) {
                    if (copyRows.has(row)) {
                        deleteRowFromSelection(row);
                    } else {
                        addRowToSelection(row, e);
                    }
                }
            } else {
                resetCopyRowSelection(e);
            }
        }
    });

    //add pagination events
    $("a.dropdown-item").on("click", handleAnchorClickEvents);

    $('a.page-link').on('click', handleAnchorClickEvents);

    function handleAnchorClickEvents() {
        resetCopyRowSelection();
        showHideSelectionMobileMenu();
    }
    // function handlePageLinkClicks() {
    //     setTimeout(function () {
    //         rowArray = [...$(tableID).find("tbody").first()[0].children];
    //         let copyRowArray = [...copyRows];
    //         for (let i = 0; i < copyRowArray.length; i++) {
    //             if (copyRowArray[i].classList != undefined) {
    //                 copyRowArray[i].classList.remove(selectionClass);
    //             }
    //         }
    //         copyRows = new Set(copyRowArray);
    //         for (let i = 0; i < rowArray.length; i++) {
    //             if (copyRows.has(rowArray[i])) {
    //                 deleteRowFromSelection(rowArray[i]);
    //                 addRowToSelection(rowArray[i]);
    //             }
    //         }
    //         $('a.page-link').on('click', handlePageLinkClicks);
    //     }, 10);
    // }

    //add page down events
    $(document).on("mousedown", function () {
        hideContextMenu();
    });

    //add page click events
    $(document).on("click", function (e) {
        //if the click is not in the table remove selections and hide the special menu
        if ($(e.target).closest("table")[0] == undefined && !dragged && $(e.target).closest("." + mobileSelectionMenu)[0] == undefined) {
            resetCopyRowSelection(e);
            $("." + mobileSelectionMenu).hide();
        }
    });

    //add scroll events
    $(document).on("scroll", hideContextMenu);

    //add page key events
    $(document).on("keyup", function (e) {
        //make sure the key combo is valid
        if (copyRows.size <= 0 || (e.key !== 'c' && e.key !== 'x')) {
            return;
        }

        //all combos must have ctrlkey
        if (e.ctrlKey) {
            //get the target.id
            let saveTargetID = JSON.parse(JSON.stringify(e.target.id));

            //set it to simulate a certain click
            if (e.key === 'x') {
                e.target.id = copyTextID.substring(1);
            } else {
                e.target.id = copyLinkID.substring(1);
            }

            //copy the rows and show the toast
            copySelectedRows(e);

            //reset the target.id
            e.target.id = saveTargetID;
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

function addMobileSelectionMenuClickEvents() {
    //initialize button variables
    let backBtn = document.getElementById(mobileSelectionMenu + "-back-btn");
    let selectAllBtn = document.getElementById(mobileSelectionMenu + "-select-all-btn");
    let copyTextBtn = document.getElementById(mobileSelectionMenu + "-copy-text-btn");
    let copyLinkBtn = document.getElementById(mobileSelectionMenu + "-copy-link-btn");

    //handle back button clicks
    backBtn.addEventListener("click", function (e) {
        resetCopyRowSelection(e);
        showHideSelectionMobileMenu();
    });

    //handle select all clicks
    selectAllBtn.addEventListener("click", function () {
        if (selectAllBtn.checked) {
            for (let i = 0; i < rowArray.length; i++) {
                if (!copyRows.has(rowArray[i])) {
                    addRowToSelection(rowArray[i]);
                }
            }
        } else {
            for (let i = 0; i < rowArray.length; i++) {
                if (copyRows.has(rowArray[i])) {
                    deleteRowFromSelection(rowArray[i]);
                }
            }
        }

    });

    //handle copy buttons clicks
    copyTextBtn.addEventListener("click", copyTextHandler);
    copyLinkBtn.addEventListener("click", copyLinkHandler);
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
    handleMobileMenu();
}

function hideContextMenu() {
    $(contextMenuID).removeClass("show").hide();
}

function addCopyClick() {
    //add event listner for copy clicks
    $(copyLinkID).on('mousedown', copyLinkHandler);
    $(copyTextID).on('mousedown', copyTextHandler);
}

function copyLinkHandler(e) {
    //get the target.id
    let saveTargetID = JSON.parse(JSON.stringify(e.target.id));

    //set it to be the right id
    e.target.id = copyLinkID.substring(1);

    //copy the rows and show the toast
    copySelectedRows(e);

    //reset the target.id
    e.target.id = saveTargetID;
}

function copyTextHandler(e) {
    //get the target.id
    let saveTargetID = JSON.parse(JSON.stringify(e.target.id));

    //set it to be the right id
    e.target.id = copyTextID.substring(1);

    //copy the rows and show the toast
    copySelectedRows(e);

    //reset the target.id
    e.target.id = saveTargetID;
}

function addTableMove() {
    $(tableID).on('mousedown', function (e) {
        let row = $(e.target).closest("tr")[0];
        if (overARow(row) && ((!row.classList.contains(selectionClass) && e.which == 3) || e.which != 3)) {
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

function handleMobileMenu() {
    updateCountShown();
}

function updateCountShown() {
    document.getElementById(mobileSelectionMenu + "-selection-count").innerHTML = copyRows.size + " Selected"
}

function showHideSelectionMobileMenu() {
    //if it's a mobile screen and the menu is not visible, show it
    if (isMobileScreen() && !$("." + mobileSelectionMenu).is(":visible")) {
        $("." + mobileSelectionMenu).show();
    } else {
        $("." + mobileSelectionMenu).hide();
    }
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
    if (isMobileScreen()) {
        $('.' + selectionClass).removeClass(mainSelectionClass);
        handleMobileMenu();
        document.getElementById(mobileSelectionMenu + "-select-all-btn").checked = false;
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
    if (isMobileScreen()) {
        $('.' + selectionClass).removeClass(mainSelectionClass);
        handleMobileMenu();
        $("." + mobileSelectionMenu).show();
        if (copyRows.size == rowArray.length) {
            document.getElementById(mobileSelectionMenu + "-select-all-btn").checked = true;
        }
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
    $(copyToastID).toast('show');
    hideContextMenu();
    let copyString = "";
    if (customCopyFunction != undefined || secondCustomCopyFunction != undefined) {
        if (e.target.id == copyLinkID.substring(1)) {
            copyString = customCopyFunction();
        } else {
            copyString = secondCustomCopyFunction();
        }
    } else {
        let headerArray = [...$(tableID).find('thead').first().find('tr').first()[0].children];
        let index = 0;
        copyRows.forEach(row => {
            let dataArray = $(row).find('td');
            copyString = copyString + (isMobileScreen() ? "" : (headerArray[0].innerText + ": ")) + dataArray[0].innerText;
            for (let i = 1; i < dataArray.length; i++) {
                copyString = copyString + ", " + (isMobileScreen() ? "" : (headerArray[i].innerText + ": ")) + dataArray[i].innerText;
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
    showHideSelectionMobileMenu();
}

export function getSelectedRows() {
    return copyRows;
}

export function setCustomCopyFunction(customFunction) {
    customCopyFunction = customFunction;
}

export function setSecondCustomCopyFunction(customFunction) {
    secondCustomCopyFunction = customFunction;
}

export function init(id) {
    tableID = '#' + id;
    copyLinkID = "#table-copy-link-row";
    copyTextID = "#table-copy-text-row";
    contextMenuID = "#table-context-menu";
    copyToastID = "#table-copy-toast";
    rowArray = [...$(tableID).find("tbody").first()[0].children];

    addRightClickTable();
    showHideSelectionMobileMenu();
    addMobileSelectionMenuClickEvents();
}
import { addFormatsToPage, addAnimationToProgressBars } from "/js/formats.js";
import { nextAuraxElementID } from "/js/character/weapons.js";

let table;

export function setupFlexTables() {
    init();

    function init() {
        initializeFlexTables();

        setFlexTableVisibilities();
    }

    function updateSortTable() {
        let toSortDesc = table.querySelector(".desc");
        let toSortAsc = table.querySelector(".asc");

        if (toSortDesc != undefined) {
            toSortDesc.click();
            toSortDesc.click();
            toSortDesc.classList.remove("desc");
            toSortDesc.classList.add("desc");
        } else if (toSortAsc != undefined) {
            toSortDesc.click();
            toSortDesc.click();
            toSortAsc.classList.remove("asc");
            toSortAsc.classList.add("asc");
        }
    }
    function initializeFlexTables() {
        document.querySelectorAll('.table-responsive-stack').forEach(responseTable => {
            table = responseTable
            setMobileHeaderTexts(table.id);
            addOnTHeadClick();
            addToolBarClick();
            addSearchEnter();
            addPaginationClick();
            showHideNextAuraxButton();
        });
    }

    function setNextAuraxVisibilities() {
        setTimeout(function () {
            showHideNextAuraxButton()
        }, 500);
    }

    function tableSearchEnterEventHandler(e) {
        if (e.keyCode == 13) {
            //TODO INIT URI query string
            setTimeout(function () {
                //TODO Add URI query string update
                updateTableFormats(table.id);
            }, 500);

            if (document.querySelector("input.search-input").value == "") {
                setTimeout(function () {
                    //TODO Remove URI query string 
                    updateSortTable();
                }, 500);
            }
        }
    }
    function tableSearchEnterDownEventHandler(e) {
        if (e.keyCode == 13) {
        }
    }
    function addSearchEnter() {
        document.querySelectorAll('.search-input').forEach(searchInput => {
            searchInput.removeEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.addEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.removeEventListener('keyup', tableSearchEnterEventHandler);
            searchInput.addEventListener('keyup', tableSearchEnterEventHandler);
        });
    }

    function tableToolBarClickEventHandler() {
        setTimeout(function () {
            updateTableFormats(table.id);
        }, 10);
    }
    function addToolBarClick() {
        document.querySelectorAll('.dropdown-item-marker').forEach(itemDropDown => {
            itemDropDown.removeEventListener('mouseup', tableToolBarClickEventHandler);
            itemDropDown.addEventListener('mouseup', tableToolBarClickEventHandler);
        });
    }

    let tableMouseMoveClick = false;
    function tableMouseMoveEventHandler(e) {
        if (e.which == 1) {
            tableMouseMoveClick = true;
        } else {
            if (tableMouseMoveClick) {
                setTimeout(function () {
                    updateTableFormats(table.id);
                }, 10);
                tableMouseMoveClick = false;
            }
        }
    }
    function tableMouseClickEventHandler() {
        setTimeout(function () {
            updateTableFormats(table.id);
        }, 1);
    }
    function addOnTHeadClick() {
        table.firstElementChild.removeEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.removeEventListener('click', tableMouseClickEventHandler);
        table.firstElementChild.addEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.addEventListener('click', tableMouseClickEventHandler);
    }

    function updateTableFormats(tableID) {
        addAnimationToProgressBars();
        addFormatsToPage();
        setMobileHeaderTexts(tableID);
        setNextAuraxVisibilities();
        makeSureTableRecievedStyles();
    }

    function makeSureTableRecievedStyles(tableID) {
        //wait a bit
        setTimeout(function () {
            //if the table is didn't get destroyed
            let table = document.getElementById(tableID);
            if (table != undefined) {
                //loop through the rows
                for (let tableRow of table.querySelector("tbody").querySelectorAll("tr")) {
                    let td = tableRow.querySelector(".weapon");
                    if (td != undefined) {
                        //make sure if it is over 0% that the width of the progress bar is too
                        let progress = td.querySelector(".progress-bar");
                        if (parseInt(progress.innerHTML.replace("%", "")) > 0) {
                            if (progress.style.width = 0) {
                                updateTableFormats(tableID);
                                break;
                            }
                        }
                        //if it doesn't have a .weapon column just ignore progress bar formats
                    } else {
                        updateTableFormats(tableID);
                        break;
                    }
                }
            } else {
                //otherwise reinitialize the table
                init();
            }
        }, 500);
    }

    function tablePaginationClickEventHandler(e) {
        if (e.target.classList.contains("page-link") || e.target.classList.contains("dropdown-item")) {
            setTimeout(function () {
                updateTableFormats(table.id);
            }, 500);
        }
    }
    function addPaginationClick() {
        $('a').off('click', tablePaginationClickEventHandler);
        $('a').on('click', tablePaginationClickEventHandler);
    }

    function showHideNextAuraxButton() {
        if (document.getElementById("nextAurax") != undefined) {
            if (document.getElementById(nextAuraxElementID) != undefined) {
                $("#nextAurax").show();
            } else {
                $("#nextAurax").hide();
            }
        }
    }

    function setMobileHeaderTexts(tableID) {
        //append each header text to the front of the corresponding data element and hide it
        $('#' + tableID).find("th").each(function (i) {
            $('#' + tableID + ' td:nth-child(' + (i + 1) + ')').prepend(getMobileHeader(hasMobileHeader($('#' + tableID + ' td:nth-child(' + (i + 1) + ')').html()) ? "" : getMobileHeader($(this).text())));
            if (window.innerWidth > 767) {
                $('.table-responsive-stack-thead').hide();
            }
        });
    }
    function getMobileHeader(text) {
        return !hasMobileHeader(text) ? '<span class="table-responsive-stack-thead">' + text + getSeparator(text) + '</span>' : (text.trim() == "Weapon") ? "" : text;
    }
    function getSeparator(text) {
        return (isThereAHeader(text) ? ": " : "");
    }
    function isThereAHeader(text) {
        return text.trim() != "" && text.trim() != "Weapon";
    }
    function hasMobileHeader(text) {
        return text != undefined && (text.includes("table-responsive-stack-thead") || text.trim() == "Weapon");
    }
}

export function setFlexTableVisibilities() {
    let screenWidth = window.innerWidth <= 767;
    document.querySelectorAll('.table-responsive-stack').forEach(table => {
        showHideMobileAndRegularTables(table, screenWidth);
    });

    function showHideMobileAndRegularTables(table, showMobile) {
        if (showMobile) {
            showMobileTableAndHideRegularTable(table);
        } else {
            hideMobileTableAndShowRegularTable(table);
        }
    }

    function showMobileTableAndHideRegularTable(table) {
        $(table).find(".table-responsive-stack-thead").show();
        $(table).find('thead').hide();
    }

    function hideMobileTableAndShowRegularTable(table) {
        $(table).find(".table-responsive-stack-thead").hide();
        $(table).find('thead').show();
    }
}

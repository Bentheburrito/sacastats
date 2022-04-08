import { addFormatsToPage, addAnimationToProgressBars } from "/js/formats.js";
import { showHideNextAuraxButton } from "/js/character/weapons-table.js";

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
        } else if (toSortAsc != undefined) {
            toSortAsc.click();
            toSortAsc.click();
        }
    }

    function updateStickySortTable() {
        if (!didTableRecieveStyleUpdate()) {
            let toSortDesc = document.querySelector(".sticky-header").querySelector(".desc");
            let toSortAsc = document.querySelector(".sticky-header").querySelector(".asc");

            if (toSortDesc != undefined) {
                toSortDesc.click();
                toSortDesc.click();
            } else if (toSortAsc != undefined) {
                toSortAsc.click();
                toSortAsc.click();
            }
        }
    }
    function initializeFlexTables() {
        document.querySelectorAll('.table-responsive-stack').forEach(responseTable => {
            table = responseTable;
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
                updateSortTable();
                updateTableFormats(table.id);
            }, 500);

            if (document.querySelector("input.search-input").value == "") {
                setTimeout(function () {
                    //TODO Remove URI query string 
                }, 500);
            } //TODO Add else and highlight text on desktop to easily remove later
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

    function dropDownItemMouseUpEventHandler(e) {
        var menuElement = e.target.closest('.dropdown-menu');

        setTimeout(function () {
            updateSortTable();
            if (!menuElement.classList.contains("show")) {
                menuElement.parentElement.firstElementChild.click();
            }
        }, 10);
    }
    function dropDownMenuClickEventHandler(e) {
        e.stopPropagation();
    }
    function addToolBarClick() {
        document.querySelectorAll(".dropdown-item").forEach(itemDropDown => {
            itemDropDown.removeEventListener('mouseup', dropDownItemMouseUpEventHandler);
            itemDropDown.addEventListener('mouseup', dropDownItemMouseUpEventHandler);
        });
        document.querySelectorAll(".dropdown-menu").forEach(menu => {
            menu.removeEventListener('click', dropDownMenuClickEventHandler);
            menu.addEventListener('click', dropDownMenuClickEventHandler);
        });
    }

    function refreshByScroll() {
        window.scrollBy(0, -1);
        window.scrollBy(0, 1);
    }

    let tableMouseMoveClick = false;
    function tableMouseMoveEventHandler(e) {
        if (e.which == 1) {
            tableMouseMoveClick = true;
        } else {
            if (tableMouseMoveClick) {
                setTimeout(function () {
                    if (e.target.parentElement.parentElement.parentElement.classList.contains("sticky-header")) {
                        refreshByScroll();
                        setTimeout(function () {
                            updateStickySortTable();
                        }, 500);
                    }
                    updateTableFormats(table.id);
                }, 10);
                tableMouseMoveClick = false;
            }
        }
    }
    function tableMouseClickEventHandler() {
        setTimeout(function () {
            updateTableFormats(table.id);
            refreshByScroll();
        }, 1);
    }
    function addOnTHeadClick() {
        table.firstElementChild.removeEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.removeEventListener('click', tableMouseClickEventHandler);
        table.firstElementChild.addEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.addEventListener('click', tableMouseClickEventHandler);
        document.querySelector(".sticky-header-container").removeEventListener('mousemove', tableMouseMoveEventHandler);
        document.querySelector(".sticky-header-container").removeEventListener('click', tableMouseClickEventHandler);
        document.querySelector(".sticky-header-container").addEventListener('mousemove', tableMouseMoveEventHandler);
        document.querySelector(".sticky-header-container").addEventListener('click', tableMouseClickEventHandler);
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
                if (!didTableRecieveStyleUpdate()) {
                    updateTableFormats(tableID);
                }
            } else {
                //otherwise reinitialize the table
                init();
            }
        }, 500);
    }

    function didTableRecieveStyleUpdate() {
        //loop through the rows
        for (let tableRow of table.querySelector("tbody").querySelectorAll("tr")) {
            let td = tableRow.querySelector(".weapon");
            if (td != undefined) {
                //make sure if it is over 0% that the width of the progress bar is too
                let progress = td.querySelector(".progress-bar");
                if (parseInt(progress.innerHTML.replace("%", "")) > 0) {
                    if (progress.style.width.replace("px", "") == "0") {
                        return false;
                    }
                }
                //if it doesn't have a .weapon column just ignore progress bar formats
            } else {
                return true;
            }
        }
        return true;
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

import { addFormatsToPage, addAnimationToProgressBars } from "/js/formats.js";
import { showHideNextAuraxButton } from "/js/character/weapons-table.js";
import * as bootstrapTableFilter from "/js/flex-bootstrap-table-filter.js";
import * as bootstrapSelection from "/js/flex-bootstrap-table-selection.js";

let table;

export function setupFlexTables() {

    document.querySelectorAll('.table-responsive-stack').forEach(table => {
        bootstrapTableFilter.init(table.id);
        bootstrapSelection.init(table.id);
        init();
    });

    function init() {
        initializeFlexTables();

        setFlexTableVisibilities();
    }

    function initializeFlexTables() {
        document.querySelectorAll('.table-responsive-stack').forEach(responseTable => {
            table = responseTable;
            initializeStickyHeaderWidths();
            setMobileHeaderTexts(table.id);
            addOnTHeadClick();
            addToolBarClick();
            addSearchEnter();
            addPaginationClick();
            addOnDocumentMouseUp();
            showHideNextAuraxButton();
        });
    }

    function setNextAuraxVisibilities() {
        setTimeout(function () {
            showHideNextAuraxButton();
        }, 10);
    }

    function tableSearchEnterEventHandler(e) {
        if (e.keyCode == 13) {
            searchTable(e);
        } else {
            let text = JSON.parse(JSON.stringify(document.querySelector("input.search-input").value));
            setTimeout(function () {
                if (text == document.querySelector("input.search-input").value) {
                    searchTable(e);
                }
            }, 300);
        }
    }
    function searchTable(e) {
        updateSearchParam();
        setTimeout(function () {
            bootstrapTableFilter.updateTableFiltration();
            updateTableFormats(table.id);
        }, 10);

        if (document.querySelector("input.search-input").value != "" && e.keyCode == 13) {
            if (window.innerWidth >= 768) {
                document.querySelector("input.search-input").select();
            }
        }
    }
    function tableSearchEnterDownEventHandler(e) {
        if (e.keyCode == 13) {

        }
    }
    function addSearchEnter() {
        document.querySelectorAll('input.search-input').forEach(searchInput => {
            searchInput.removeEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.addEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.removeEventListener('keyup', tableSearchEnterEventHandler);
            searchInput.addEventListener('keyup', tableSearchEnterEventHandler);
        });
    }

    function isTargetInputDisabled(target) {
        let input = target;
        if (target.localName != "input") {
            input = input.closest(".filter-option");
            if (input != undefined || input != null) {
                input = input.querySelector(".dropdown-item").querySelector("input");
            } else {
                return false;
            }
        }

        if (input != undefined || input != null) {
            return input.disabled;
        } else {
            return false;
        }
    }

    function dropDownItemMouseUpEventHandler(e) {
        let target = e.target;

        if (('#' + target.id) != bootstrapTableFilter.getClearFilterButtonID()) {
            setTimeout(function () {
                var menuElement = target.closest('.dropdown-menu');
                if (!isTargetInputDisabled(target)) {
                    if (!menuElement.classList.contains("show")) {
                        menuElement.parentElement.firstElementChild.click();
                    }
                }
            }, 10);
        }

        setTimeout(function () {
            setFlexTableVisibilities();
        }, 10);

        setTimeout(function () {
            setMobileHeaderTexts(table.id);
        }, 500);
    }
    function dropDownMenuClickEventHandler(e) {
        let target = e.target;
        e.stopPropagation();

        if (('#' + target.id) == bootstrapTableFilter.getClearFilterButtonID()) {
            setTimeout(function () {
                var menuElement = target.closest('.dropdown-menu');
                if (!menuElement.classList.contains("show")) {
                    menuElement.parentElement.firstElementChild.click();
                }
            }, 100);
        }
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

    function documentMouseUpEventHandler() {
        setTimeout(function () {
            if (!didTableRecieveStyleUpdate()) {
                setMobileHeaderTexts(table.id);
                addAnimationToProgressBars();
                addFormatsToPage();

                setTimeout(function () {
                    setStickyHeaderWidths();
                }, 100);
            }
        }, 100);
    }

    function addOnDocumentMouseUp() {
        $(document).off("mouseup", documentMouseUpEventHandler);
        $(document).on("mouseup", documentMouseUpEventHandler);
    }

    let prevDate = new Date().getTime();
    function tableMouseMoveEventHandler(e) {
        var date = new Date().getTime();
        if (date - prevDate > 300) {
            if (!didTableRecieveStyleUpdate()) {
                addAnimationToProgressBars();
                addFormatsToPage();
                refreshByScroll();
            }
            prevDate = date;
        }
    }
    function tableMouseClickEventHandler() {
        setTimeout(function () {
            updateTableFormats(table.id);
            refreshByScroll();
        }, 1);
    }
    function addOnTHeadClick() {
        table.removeEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.removeEventListener('click', tableMouseClickEventHandler);
        table.addEventListener('mousemove', tableMouseMoveEventHandler);
        table.firstElementChild.addEventListener('click', tableMouseClickEventHandler);
        document.querySelector(".sticky-header-container").removeEventListener('mousemove', tableMouseMoveEventHandler);
        document.querySelector(".sticky-header-container").removeEventListener('click', tableMouseClickEventHandler);
        document.querySelector(".sticky-header-container").addEventListener('mousemove', tableMouseMoveEventHandler);
        document.querySelector(".sticky-header-container").addEventListener('click', tableMouseClickEventHandler);
    }

    function updateTableFormats(tableID) {
        if (!didTableRecieveStyleUpdate()) {
            addAnimationToProgressBars();
            addFormatsToPage();
        }
        setMobileHeaderTexts(tableID);
        setNextAuraxVisibilities();
        bootstrapTableFilter.showHideClearFilterButtons();
        makeSureTableRecievedStyles();
        setStickyHeaderWidths();
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
        }, 10);
    }

    function tablePaginationClickEventHandler(e) {
        setTimeout(function () {
            updateTableFormats(table.id);
        }, 10);
    }
    function addPaginationClick() {
        $('a.page-link').off('click', tablePaginationClickEventHandler);
        $('a.dropdown-item').off('click', tablePaginationClickEventHandler);
        $('a.page-link').on('click', tablePaginationClickEventHandler);
        $('a.dropdown-item').on('click', tablePaginationClickEventHandler);
    }
}

export function updateSearchParam() {
    let searchValue = document.querySelector("input.search-input").value;

    if (window.history.pushState) {
        const newURL = new URL(window.location.href);
        if (searchValue != "") {
            newURL.search = "?search=" + searchValue.replaceAll(" ", "_");
        } else {
            newURL.search = "";
        }

        window.history.pushState({ path: newURL.href }, '', newURL.href);
        bootstrapTableFilter.turnOffIdFilter();
    }
}

export function setMobileHeaderTexts(tableID) {
    //append each header text to the front of the corresponding data element and hide it
    $('#' + tableID).find("th").each(function (i) {
        let tds = '#' + tableID + ' td:nth-child(' + (i + 1) + ')';
        $(tds).prepend(getMobileHeader(hasMobileHeader($(tds).html()) ? ""
            : getMobileHeader((document.querySelector(tds).hasAttribute('data-mobile-title')) ? document.querySelector(tds).getAttribute('data-mobile-title') : $(this).text())));
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

export function didTableRecieveStyleUpdate() {
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

function initializeStickyHeaderWidths() {
    //get the current scroll position and scroll to the top of the page
    let top = JSON.parse(JSON.stringify(document.body.scrollTop));
    document.body.scrollTop = 0;

    //set the sticky header widths
    setStickyHeaderWidths();

    //reset the scroll position to the original
    document.body.scrollTop = top;
}

export function setStickyHeaderWidths() {
    //initialize variables
    let headers = document.querySelector("thead.sticky-header > tr").querySelectorAll("th");
    let columns = document.querySelector("#" + table.id + ">tbody>tr").querySelectorAll("td");

    //make sure each header matches it's matching td
    for (let i = 0; i < headers.length; i++) {
        let width = $(columns[i]).width();
        $(headers[i]).css({
            'width': width + 'px'
        });
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

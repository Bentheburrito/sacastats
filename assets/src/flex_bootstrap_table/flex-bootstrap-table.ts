import { addFormatsToPage, addAnimationToProgressBars } from '../formats.js';
import * as bootstrapTableFilter from './flex-bootstrap-table-filter.js';
import * as bootstrapSelection from './flex-bootstrap-table-selection.js';
import * as bootstrapColumn from './flex-bootstrap-table-column.js';
import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';
import * as generalEvents from '../events/general-events.js';

let table: HTMLTableElement;

let isPageFormatted = false;

export function setupFlexTables() {
    addCustomDocumentEventListeners();

    document.querySelectorAll('.table-responsive-stack').forEach((table) => {
        bootstrapTableFilter.init(table.id);
        bootstrapSelection.init(table.id);
        bootstrapColumn.init(table.id);
        init();
    });

    function init() {
        initializeFlexTables();

        setFlexTableVisibilities();
    }

    function initializeFlexTables() {
        document.querySelectorAll('.table-responsive-stack').forEach((responseTable) => {
            table = responseTable as HTMLTableElement;
            initializeStickyHeaderWidths();
            setMobileHeaderTexts(table.id);
            addOnTHeadClick();
            addToolBarClick();
            addSearchEnter();
            addOnDocumentMouseUp();
            addTableCustomEventListeners(table.id);
            updateTableFormats(table.id);
            $(table).trigger(flexBootstrapTableEvents.initializedEvent);
        });
    }

    window.addEventListener('load', (event) => {
        handleScreenWidthChange();
    });

    function handleScreenWidthChange() {
        fixHeaderVisibilities();
        window.addEventListener('resize', fixHeaderVisibilities);
    }

    function fixHeaderVisibilities() {
        let isDesktop = window.innerWidth >= 768;
        if (!isDesktop) {
            refreshByScroll();
        }
    }

    function handleTableColumnReorderEvent() {
        refreshByScroll();

        //will need to update formats as reorders take longer
        setTimeout(function () {
            updateTableFormats(table.id);
        }, 10);
    }
    function handleTablePageChangeEvent() {
        $('html, body').animate(
            {
                scrollTop: $('#' + table.id).offset()!.top - (window.innerWidth >= 768 ? 300 : 60), //- 254 to be at top
            },
            500,
        );
    }
    function handleTablePostBodyEvent() {
        updateTableFormats(table.id);
    }
    function addTableCustomEventListeners(tableID: string) {
        $('#' + tableID).off('reorder-column.bs.table', handleTableColumnReorderEvent);
        $('#' + tableID).on('reorder-column.bs.table', handleTableColumnReorderEvent);
        $('#' + tableID).off('page-change.bs.table', handleTablePageChangeEvent);
        $('#' + tableID).on('page-change.bs.table', handleTablePageChangeEvent);
        $('#' + tableID).off('post-body.bs.table', handleTablePostBodyEvent);
        $('#' + tableID).on('post-body.bs.table', handleTablePostBodyEvent);
    }

    function tableSearchEnterEventHandler(event: Event) {
        if ((event as KeyboardEvent).key === 'Enter') {
            searchTable(event);
        } else {
            let input = document.querySelector('input.search-input') as HTMLInputElement;
            let text = JSON.parse(JSON.stringify(input.value));
            setTimeout(function () {
                if (text == input.value) {
                    searchTable(event);
                }
            }, 300);
        }
    }
    function searchTable(event: Event) {
        updateSearchParam();
        setTimeout(function () {
            bootstrapTableFilter.updateTableFiltration();
        }, 10);

        let input = document.querySelector('input.search-input') as HTMLInputElement;
        if (input.value != '' && (event as KeyboardEvent).key === 'Enter') {
            if (window.innerWidth >= 768) {
                input.select();
            }
        }
    }
    function tableSearchEnterDownEventHandler(event: Event) {
        if ((event as KeyboardEvent).key === 'Enter') {
        }
    }
    function addSearchEnter() {
        document.querySelectorAll('input.search-input').forEach((searchInput) => {
            searchInput.removeEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.addEventListener('keydown', tableSearchEnterDownEventHandler);
            searchInput.removeEventListener('keyup', tableSearchEnterEventHandler);
            searchInput.addEventListener('keyup', tableSearchEnterEventHandler);
        });
    }

    function isTargetInputDisabled(target: HTMLElement) {
        let input = target;
        if (target.localName != 'input') {
            input = input.closest('.filter-option')!;
            if (input != undefined || input != null) {
                input = input.querySelector('.dropdown-item')!.querySelector('input')!;
            } else {
                return false;
            }
        }

        if (input != undefined || input != null) {
            return (input as HTMLInputElement).disabled;
        } else {
            return false;
        }
    }

    function dropDownItemMouseUpEventHandler(event: Event) {
        let target = event.target as HTMLElement;

        if ('#' + target.id != bootstrapTableFilter.getClearFilterButtonID()) {
            setTimeout(function () {
                var menuElement = target.closest('.dropdown-menu')!;
                if (!isTargetInputDisabled(target)) {
                    if (!menuElement.classList.contains('show')) {
                        (menuElement.parentElement?.firstElementChild as HTMLElement).click();
                    }
                }
            }, 10);
        }
    }
    function dropDownMenuClickEventHandler(event: Event) {
        let target = event.target as HTMLElement;
        event.stopPropagation();

        if ('#' + target.id == bootstrapTableFilter.getClearFilterButtonID()) {
            setTimeout(function () {
                var menuElement = target.closest('.dropdown-menu')!;
                if (!menuElement.classList.contains('show')) {
                    (menuElement.parentElement?.firstElementChild as HTMLElement).click();
                }
            }, 100);
        }
    }
    function addToolBarClick() {
        document.querySelectorAll('.dropdown-item').forEach((itemDropDown) => {
            itemDropDown.removeEventListener('mouseup', dropDownItemMouseUpEventHandler);
            itemDropDown.addEventListener('mouseup', dropDownItemMouseUpEventHandler);
        });
        document.querySelectorAll('.dropdown-menu').forEach((menu) => {
            menu.removeEventListener('click', dropDownMenuClickEventHandler);
            menu.addEventListener('click', dropDownMenuClickEventHandler);
        });
    }

    function refreshByScroll() {
        let currentScrollPosition = $(window).scrollTop() as number;
        let maxScrollPosition = (document.documentElement.scrollHeight - document.documentElement.clientHeight) as number;

        if (currentScrollPosition == maxScrollPosition) {
            $(window).scrollTop(currentScrollPosition - 1);
        } else {
            $(window).scrollTop(currentScrollPosition + 1);
            $(window).scrollTop(currentScrollPosition - 1);
        }
    }

    function documentMouseUpEventHandler(event: JQuery.MouseUpEvent) {
        let columnDropdown = document.querySelector("button[title='Columns']");
        if (columnDropdown == event.target) {
            bootstrapColumn.fixColumnDropDown();
        }

        setTimeout(function () {
            bootstrapColumn.updateColumns();
        }, 100);
    }
    function addOnDocumentMouseUp() {
        $(document).off('mouseup', documentMouseUpEventHandler);
        $(document).on('mouseup', documentMouseUpEventHandler);
    }

    function tableHeaderMouseDownEventHandler(event: Event) {
        bootstrapSelection.resetCopyRowSelection(event);
    }
    function addOnTHeadClick() {
        table.firstElementChild?.removeEventListener('mousedown', tableHeaderMouseDownEventHandler);
        table.firstElementChild?.addEventListener('mousedown', tableHeaderMouseDownEventHandler);
        document.querySelector('.sticky-header')?.removeEventListener('mousedown', tableHeaderMouseDownEventHandler);
        document.querySelector('.sticky-header')?.addEventListener('mousedown', tableHeaderMouseDownEventHandler);
    }

    function updateTableFormats(tableID: string) {
        isPageFormatted = false;
        addAnimationToProgressBars();
        addFormatsToPage();
        setMobileHeaderTexts(tableID);
        bootstrapTableFilter.showHideClearFilterButtons();
        setStickyHeaderWidths();
        setFlexTableVisibilities();
        $(table).trigger(flexBootstrapTableEvents.formatsUpdatedEvent);
        setTimeout(function () {
            makeSureTableRecievedStyles(tableID);
        }, 10);
    }

    function makeSureTableRecievedStyles(tableID: string) {
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

    function fixHeaderOnPageLoad() {
        let isDesktop = window.innerWidth >= 768;

        if (isDesktop) {
            setTimeout(function () {
                refreshByScroll();
            }, 100);
        }
    }

    function addCustomDocumentEventListeners() {
        $(document).on(generalEvents.pageFormattedEvent, function () {
            isPageFormatted = true;
        });
        $(document).on(generalEvents.loadingScreenRemovedEvent, fixHeaderOnPageLoad);
    }
}

export function scrollToTopOfTable(event: Event) {
    let target = event.target as HTMLElement;
    if (target.classList.contains('page-link') || target.classList.contains('page-item')) {
        $('html, body').animate(
            {
                scrollTop: $('#' + table.id).offset()!.top - (window.innerWidth >= 768 ? 300 : 60), //- 254 to be at top
            },
            500,
        );
    }
}

export function updateSearchParam() {
    let searchValue = (document.querySelector('input.search-input') as HTMLInputElement).value as string;

    if (window.history.pushState) {
        const newURL = new URL(window.location.href);
        if (searchValue != '') {
            newURL.search = '?search=' + searchValue.replaceAll(' ', '_');
        } else {
            newURL.search = '';
        }

        window.history.pushState({ path: newURL.href }, '', newURL.href);
        bootstrapTableFilter.turnOffIdFilter();
    }
}

export function setMobileHeaderTexts(tableID: string) {
    //append each header text to the front of the corresponding data element and hide it
    $('#' + tableID)
        .find('th')
        .each(function (i) {
            let tds = '#' + tableID + ' td:nth-child(' + (i + 1) + ')';
            let tdsExist = document.querySelector(tds) != undefined ? true : false;
            if (tdsExist) {
                $(tds).prepend(
                    getMobileHeader(
                        hasMobileHeader($(tds).html())
                            ? ''
                            : getMobileHeader(
                                document.querySelector(tds)?.hasAttribute('data-mobile-title')
                                    ? document.querySelector(tds)?.getAttribute('data-mobile-title')!
                                    : $(this).text(),
                            ),
                    ),
                );
                if (window.innerWidth > 767) {
                    $('.table-responsive-stack-thead').hide();
                }
            }
        });
}
function getMobileHeader(text: string) {
    return !hasMobileHeader(text)
        ? '<span class="table-responsive-stack-thead">' + text + getSeparator(text) + '</span>'
        : text.trim() == 'Weapon'
            ? ''
            : text;
}
function getSeparator(text: string) {
    return isThereAHeader(text) ? ': ' : '';
}
function isThereAHeader(text: string) {
    return text.trim() != '' && text.trim() != 'Weapon';
}
function hasMobileHeader(text: string) {
    return text != undefined && (text.includes('table-responsive-stack-thead') || text.trim() == 'Weapon');
}

function didTableRecieveStyleUpdate() {
    return isPageFormatted;
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
    let headers = document.querySelector('thead.sticky-header > tr')!.querySelectorAll('th');
    let columns = document.querySelector('#' + table.id + '>tbody>tr')!.querySelectorAll('td');

    //make sure each header matches it's matching td
    for (let i = 0; i < headers.length; i++) {
        let width = $(columns[i]).width();
        $(headers[i]).css({
            width: width + 'px',
        });
    }
}

export function setFlexTableVisibilities() {
    let screenWidth = window.innerWidth <= 767;
    (document.querySelectorAll('.table-responsive-stack') as NodeListOf<HTMLTableElement>).forEach((table) => {
        showHideMobileAndRegularTables(table, screenWidth);
    });

    function showHideMobileAndRegularTables(table: HTMLTableElement, showMobile: boolean) {
        if (showMobile) {
            showMobileTableAndHideRegularTable(table);
        } else {
            hideMobileTableAndShowRegularTable(table);
        }
    }

    function showMobileTableAndHideRegularTable(table: HTMLTableElement) {
        $(table).find('.table-responsive-stack-thead').show();
        $(table).find('thead').hide();
    }

    function hideMobileTableAndShowRegularTable(table: HTMLTableElement) {
        $(table).find('.table-responsive-stack-thead').hide();
        $(table).find('thead').show();
    }
}

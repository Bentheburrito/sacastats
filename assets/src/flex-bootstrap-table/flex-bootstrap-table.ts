import { addFormatsToPage, addAnimationToProgressBars } from '../formats.js';
import { FlexBootstrapTableFilter } from './flex-bootstrap-table-filter.js';
import { FlexBootstrapTableMap } from '../models/flex-bootstrap-table/flex-bootstrap-table.js';
import * as bootstrapSelection from './flex-bootstrap-table-selection.js';
import * as bootstrapColumn from './flex-bootstrap-table-column.js';
import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';
import * as generalEvents from '../events/general-events.js';

import 'bootstrap-table';

export let flexBootstrapTableMap = new FlexBootstrapTableMap();

export class FlexBootstrapTable {
  private table!: HTMLTableElement;

  private isPageFormatted = false;
  private flexBootstrapTableFilter!: FlexBootstrapTableFilter;
  private desktopHeaderOnly: string[] = [];

  constructor(responseTable: HTMLTableElement) {
    this.table = responseTable as HTMLTableElement;
    this.flexBootstrapTableFilter = new FlexBootstrapTableFilter(responseTable.id);
    bootstrapSelection.init(responseTable.id);
    bootstrapColumn.init(responseTable.id);

    this.initializeFlexTable();
    this.setFlexTableVisibility();
    this.addCustomDocumentEventListeners();

    window.addEventListener('load', (_event) => {
      this.handleScreenWidthChange();
    });
  }

  private initializeFlexTable = () => {
    this.initializeStickyHeaderWidths();
    this.setMobileHeaderTexts(this.table.id);
    this.addOnTHeadClick();
    this.addToolBarClick();
    this.addSearchEnter();
    this.addOnDocumentMouseUp();
    this.addTableCustomEventListeners(this.table.id);
    this.updateTableFormats(this.table.id);
    $(this.table).trigger(flexBootstrapTableEvents.initializedEvent);
  };

  private handleScreenWidthChange = () => {
    this.fixHeaderVisibilities();
    window.addEventListener('resize', this.fixHeaderVisibilities);
  };

  private fixHeaderVisibilities = () => {
    this.setFlexTableVisibility();

    let isDesktop = window.innerWidth >= 768;
    if (!isDesktop) {
      this.refreshByScroll();
    }
  };

  private handleTableColumnReorderEvent = () => {
    this.refreshByScroll();

    //will need to update formats as reorders take longer
    setTimeout(() => {
      this.updateTableFormats(this.table.id);
    }, 10);
  };
  private handleTablePageChangeEvent = () => {
    $('html, body').animate(
      {
        scrollTop: $('#' + this.table.id).offset()!.top - (window.innerWidth >= 768 ? 300 : 60), //- 254 to be at top
      },
      500,
    );
  };
  private handleTablePostBodyEvent = () => {
    this.updateTableFormats(this.table.id);
  };
  private addTableCustomEventListeners = (tableID: string) => {
    $('#' + tableID).off('reorder-column.bs.table', this.handleTableColumnReorderEvent);
    $('#' + tableID).on('reorder-column.bs.table', this.handleTableColumnReorderEvent);
    $('#' + tableID).off('page-change.bs.table', this.handleTablePageChangeEvent);
    $('#' + tableID).on('page-change.bs.table', this.handleTablePageChangeEvent);
    $('#' + tableID).off('post-body.bs.table', this.handleTablePostBodyEvent);
    $('#' + tableID).on('post-body.bs.table', this.handleTablePostBodyEvent);
    document
      .getElementById(tableID.substring(1))
      ?.addEventListener(flexBootstrapTableEvents.ADD_DESKTOP_HEADER_ONLY_EVENT, (customEvent: Event) => {
        this.setDesktopHeaderOnly((<CustomEvent>customEvent).detail[0] as string[]);
      });
  };

  private tableSearchEnterEventHandler = (event: Event) => {
    if ((event as KeyboardEvent).key === 'Enter') {
      this.searchTable(event);
    } else {
      let input = document.querySelector('input.search-input') as HTMLInputElement;
      let text = JSON.parse(JSON.stringify(input.value));
      setTimeout(() => {
        if (text == input.value) {
          this.searchTable(event);
        }
      }, 300);
    }
  };
  private searchTable = (event: Event) => {
    this.flexBootstrapTableFilter.updateSearchParam();
    setTimeout(() => {
      this.flexBootstrapTableFilter.updateTableFiltration();
    }, 10);

    let input = document.querySelector('input.search-input') as HTMLInputElement;
    if (input.value != '' && (event as KeyboardEvent).key === 'Enter') {
      if (window.innerWidth >= 768) {
        input.select();
      }
    }
  };
  private tableSearchEnterDownEventHandler = (event: Event) => {
    if ((event as KeyboardEvent).key === 'Enter') {
    }
  };
  private addSearchEnter = () => {
    document.querySelectorAll('input.search-input').forEach((searchInput) => {
      searchInput.removeEventListener('keydown', this.tableSearchEnterDownEventHandler);
      searchInput.addEventListener('keydown', this.tableSearchEnterDownEventHandler);
      searchInput.removeEventListener('keyup', this.tableSearchEnterEventHandler);
      searchInput.addEventListener('keyup', this.tableSearchEnterEventHandler);
    });
  };

  private isTargetInputDisabled = (target: HTMLElement) => {
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
  };

  private dropDownItemMouseUpEventHandler = (event: Event) => {
    let target = event.target as HTMLElement;

    if ('#' + target.id != this.flexBootstrapTableFilter.getClearFilterButtonID()) {
      setTimeout(() => {
        var menuElement = target.closest('.dropdown-menu')!;
        if (!this.isTargetInputDisabled(target)) {
          if (!menuElement.classList.contains('show')) {
            (menuElement.parentElement?.firstElementChild as HTMLElement).click();
          }
        }
      }, 10);
    }
  };
  private dropDownMenuClickEventHandler = (event: Event) => {
    let target = event.target as HTMLElement;
    event.stopPropagation();

    if ('#' + target.id == this.flexBootstrapTableFilter.getClearFilterButtonID()) {
      setTimeout(function () {
        var menuElement = target.closest('.dropdown-menu')!;
        if (!menuElement.classList.contains('show')) {
          (menuElement.parentElement?.firstElementChild as HTMLElement).click();
        }
      }, 100);
    }
  };
  private addToolBarClick = () => {
    document.querySelectorAll('.dropdown-item').forEach((itemDropDown) => {
      itemDropDown.removeEventListener('mouseup', this.dropDownItemMouseUpEventHandler);
      itemDropDown.addEventListener('mouseup', this.dropDownItemMouseUpEventHandler);
    });
    document.querySelectorAll('.dropdown-menu').forEach((menu) => {
      menu.removeEventListener('click', this.dropDownMenuClickEventHandler);
      menu.addEventListener('click', this.dropDownMenuClickEventHandler);
    });
  };

  private refreshByScroll = () => {
    let currentScrollPosition = $(window).scrollTop() as number;
    let maxScrollPosition = (document.documentElement.scrollHeight - document.documentElement.clientHeight) as number;

    if (currentScrollPosition == maxScrollPosition) {
      $(window).scrollTop(currentScrollPosition - 1);
    } else {
      $(window).scrollTop(currentScrollPosition + 1);
      $(window).scrollTop(currentScrollPosition - 1);
    }
  };

  private documentMouseUpEventHandler = (event: JQuery.MouseUpEvent) => {
    let columnDropdown = document.querySelector("button[title='Columns']");
    if (columnDropdown == event.target) {
      bootstrapColumn.fixColumnDropDown();
    }

    setTimeout(function () {
      bootstrapColumn.updateColumns();
    }, 100);
  };
  private addOnDocumentMouseUp = () => {
    $(document).off('mouseup', this.documentMouseUpEventHandler);
    $(document).on('mouseup', this.documentMouseUpEventHandler);
  };

  private tableHeaderMouseDownEventHandler = (event: Event) => {
    bootstrapSelection.resetCopyRowSelection(event);
  };
  private addOnTHeadClick = () => {
    this.table.firstElementChild?.removeEventListener('mousedown', this.tableHeaderMouseDownEventHandler);
    this.table.firstElementChild?.addEventListener('mousedown', this.tableHeaderMouseDownEventHandler);
    document.querySelector('.sticky-header')?.removeEventListener('mousedown', this.tableHeaderMouseDownEventHandler);
    document.querySelector('.sticky-header')?.addEventListener('mousedown', this.tableHeaderMouseDownEventHandler);
  };

  private updateTableFormats = (tableID: string) => {
    this.isPageFormatted = false;
    addAnimationToProgressBars();
    addFormatsToPage();
    this.setMobileHeaderTexts(tableID);
    this.flexBootstrapTableFilter.showHideClearFilterButtons();
    this.setStickyHeaderWidths();
    this.setFlexTableVisibility();
    $(this.table).trigger(flexBootstrapTableEvents.formatsUpdatedEvent);
    setTimeout(() => {
      this.makeSureTableRecievedStyles(tableID);
    }, 10);
  };

  private makeSureTableRecievedStyles = (tableID: string) => {
    setTimeout(() => {
      if (!this.didTableRecieveStyleUpdate()) {
        this.updateTableFormats(tableID);
      }
    }, 10);
  };

  private fixHeaderOnPageLoad = () => {
    let isDesktop = window.innerWidth >= 768;

    if (isDesktop) {
      setTimeout(() => {
        this.refreshByScroll();
      }, 100);
    }
  };

  private addCustomDocumentEventListeners = () => {
    $(document).on(generalEvents.pageFormattedEvent, () => {
      this.isPageFormatted = true;
    });
    $(document).on(generalEvents.loadingScreenRemovedEvent, this.fixHeaderOnPageLoad);
  };

  private scrollToTopOfTable = (event: Event) => {
    let target = event.target as HTMLElement;
    if (target.classList.contains('page-link') || target.classList.contains('page-item')) {
      $('html, body').animate(
        {
          scrollTop: $('#' + this.table.id).offset()!.top - (window.innerWidth >= 768 ? 300 : 60), //- 254 to be at top
        },
        500,
      );
    }
  };

  private setMobileHeaderTexts = (tableID: string) => {
    //append each header text to the front of the corresponding data element and hide it
    $('#' + tableID)
      .find('.table-responsive-stack-thead')
      .each((i, element) => element.remove());
    $('#' + tableID)
      .find('th')
      .each((i, header) => {
        let tds = '#' + tableID + ' td:nth-child(' + (i + 1) + ')';
        let tdsExist = document.querySelector(tds) != undefined ? true : false;
        if (tdsExist) {
          $(tds).prepend(
            this.getMobileHeader(
              this.hasMobileHeader($(tds).html())
                ? ''
                : this.getMobileHeader(
                  document.querySelector(tds)!.hasAttribute('data-mobile-title')
                    ? document.querySelector(tds)!.getAttribute('data-mobile-title')!
                    : $(header).text(),
                ),
            ),
          );
          if (window.innerWidth > 767) {
            $('.table-responsive-stack-thead').hide();
          }
        }
      });
  };
  private getMobileHeader = (text: string) => {
    return !this.hasMobileHeader(text)
      ? '<span class="table-responsive-stack-thead">' + text + this.getSeparator(text) + '</span>'
      : this.desktopHeaderOnly.includes(text.trim())
        ? ''
        : text;
  };
  private getSeparator = (text: string) => {
    return this.isThereAHeader(text) ? ': ' : '';
  };
  private isThereAHeader = (text: string) => {
    return text.trim() != '' && !this.desktopHeaderOnly.includes(text.trim());
  };
  private hasMobileHeader = (text: string) => {
    return (
      text != undefined &&
      (text.includes('table-responsive-stack-thead') || this.desktopHeaderOnly.includes(text.trim()))
    );
  };

  private setDesktopHeaderOnly(desktopHeaderOnly: string[]) {
    this.desktopHeaderOnly = desktopHeaderOnly;
    this.setMobileHeaderTexts(this.table.id);
  }

  private didTableRecieveStyleUpdate = () => {
    return this.isPageFormatted;
  };

  private initializeStickyHeaderWidths = () => {
    //get the current scroll position and scroll to the top of the page
    let top = JSON.parse(JSON.stringify(document.body.scrollTop));
    document.body.scrollTop = 0;

    //set the sticky header widths
    this.setStickyHeaderWidths();

    //reset the scroll position to the original
    document.body.scrollTop = top;
  };

  public setStickyHeaderWidths = () => {
    //initialize variables
    // changed from 'thead.sticky-header > tr' to 'thead > tr'
    let tableHeadRowElement = document.querySelector('thead > tr');
    if (tableHeadRowElement != undefined) {
      let headers = tableHeadRowElement.querySelectorAll('th');
      let columns = document.querySelector('#' + this.table.id + '>tbody>tr')!.querySelectorAll('td');

      //make sure each header matches it's matching td
      for (let i = 0; i < headers.length; i++) {
        let width = $(columns[i]).width();
        $(headers[i]).css({
          width: width + 'px',
        });
      }
    }
  };

  private setFlexTableVisibility = () => {
    let screenWidth = window.innerWidth <= 767;
    this.showHideMobileAndRegularTables(screenWidth);
  };

  private showHideMobileAndRegularTables = (showMobile: boolean) => {
    if (showMobile) {
      this.showMobileTableAndHideRegularTable();
    } else {
      this.hideMobileTableAndShowRegularTable();
    }
  };

  private showMobileTableAndHideRegularTable = () => {
    $(this.table).find('.table-responsive-stack-thead').show();
    $(this.table).find('thead').hide();
  };

  private hideMobileTableAndShowRegularTable = () => {
    $(this.table).find('.table-responsive-stack-thead').hide();
    $(this.table).find('thead').show();
  };

  public getFlexBootstrapTableFilter = () => {
    return this.flexBootstrapTableFilter;
  };
}

function initializeFlexTables() {
  document.querySelectorAll('.table-responsive-stack').forEach((element) => {
    let responseTable = element as HTMLTableElement;
    flexBootstrapTableMap.set(responseTable.id, new FlexBootstrapTable(responseTable));
  });
}
initializeFlexTables();

import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';
import { AddCustomCopyEvent, AddSecondCustomCopyEvent } from '../events/flex-bootstrap-table-events.js';
import { SacaStatsEventUtil } from '../events/sacastats-event-util.js';

//initialize variables
let startRowIndex: number | null; //dragged main selection index
let selectedRowIndex: number | null; //click main selection index
let currentRowIndex: number | null; //last index pressed
let prevRowIndex: number | null; //predicted previous index pressed
let dragged = false;
let upDown = false; //up is true down is false

let mainSelectionClass = 'main-selected';
let selectionClass = 'selection';
let mobileSelectionMenu = 'selection-mobile-menu';
let customCopyFunction: Function;
let secondCustomCopyFunction: Function;

//selection helper lists
let rowArray: HTMLCollectionOf<HTMLElement>;
let copyRows = new Set<HTMLTableRowElement>();

//ids
let tableID: string;
let copyLinkID: string;
let copyTextID: string;
let contextMenuID: string;
let copyToastID: string;

function addTableClickHandler() {
  //add special Right click on table menu
  $(tableID).on('contextmenu', handleTableContextMenuEvent);

  function handleTableContextMenuEvent(event: Event) {
    //get the row
    if (
      !document
        .getElementById(tableID.substring(1))
        ?.querySelector('thead')
        ?.contains(event.target as HTMLElement)
    ) {
      let row = $(event.target!).closest('tr')[0] as HTMLTableRowElement;

      if (!isMobileScreen()) {
        //initialize special menu location
        let mouseEvent = event as MouseEvent;
        let isFireFox = navigator.userAgent.indexOf('Firefox') != -1;
        let yAdj =
          mouseEvent.clientY + $(contextMenuID).height()! > $(window).height()!
            ? mouseEvent.clientY - $(contextMenuID).height()! - (isFireFox ? 0 : 5)
            : mouseEvent.clientY; //adjust height to show all of menu
        let xAdj =
          mouseEvent.clientX + $(contextMenuID).width()! > $(window).width()!
            ? mouseEvent.clientX - $(contextMenuID).width()! - (isFireFox ? 0 : 2)
            : mouseEvent.clientX; //adjust width to show all of menu
        var top = (yAdj / $(window).height()!) * 100 + '%';
        var left = (xAdj / $(window).width()!) * 100 + '%';

        //show special menu at the bottom right of the mouse
        $(contextMenuID)
          .css({
            display: 'block',
            position: 'fixed',
            top: top,
            left: left,
          })
          .addClass('show');

        //if it's not selected and the control key wasn't pressed reset the selection
        let keyboardEvent = event as KeyboardEvent;
        if (!row.classList.contains(selectionClass) && !keyboardEvent.ctrlKey) {
          resetCopyRowSelection();

          //if the shift key was pressed, select start index to recently clicked index
          if (keyboardEvent.shiftKey) {
            selectStartToCurrent(getRowArrayIndex(row));
          }
        }

        //if it's a mobile screen and the row is already selected, delete it and return false to block default right click menu
      } else if (copyRows.has(row)) {
        deleteRowFromSelection(row);
        return false;
      }

      //add current row to selection
      addRowToSelection(row, event);

      return false; //blocks default Webbrowser right click menu
    } else {
      return;
    }
  }

  //update selections
  $(tableID).on('click', handleTableClick);

  function handleTableClick(event: Event) {
    //hide the special menu and initialize variables
    hideContextMenu();

    //make sure it's only tbody rows being clicked
    let row = $(event.target!).closest('tr')[0] as HTMLTableRowElement;
    if (!dragged) {
      if (overARow(row)) {
        //if it's a new selection set reset the selections
        let keyboardEvent = event as KeyboardEvent;
        if (copyRows.size > 0 && !keyboardEvent.ctrlKey && !keyboardEvent.shiftKey && !isMobileScreen()) {
          resetCopyRowSelection(event as Event);
        }

        //disable on-click selection for mobile without others selected
        if (!isMobileScreen()) {
          //if the ctrl key was pressed while a selection was clicked remove it
          let rowIndex = getRowArrayIndex(row);
          if (keyboardEvent.ctrlKey && copyRows.has(row) && copyRows.size > 1) {
            deleteRowFromSelection(row);
          } else if (selectedRowIndex != null && keyboardEvent.shiftKey) {
            resetCopyRowSelection(event);
            selectSelectionToCurrent(rowIndex);
          } else if (keyboardEvent.ctrlKey) {
            if (copyRows.has(row)) {
              deleteRowFromSelection(row);
            } else {
              addRowToSelection(row, event);
            }
          } else {
            //otherwise just add the current row to selection
            if (isThereAMainSelection()) {
              startRowIndex = rowIndex;
            }
            selectedRowIndex = rowIndex;
            addRowToSelection(row, event);
          }
        } else if (copyRows.size > 0 || $('.' + mobileSelectionMenu).is(':visible')) {
          if (copyRows.has(row)) {
            deleteRowFromSelection(row);
          } else {
            addRowToSelection(row, event);
          }
        }
      } else {
        resetCopyRowSelection(event);
      }
    }
  }

  //add pagination events
  $(tableID).on('page-change.bs.table', handleTablePageChangeEvent);
  $('a.dropdown-item').on('click', handleTablePageChangeEvent);

  function handleTablePageChangeEvent() {
    resetCopyRowSelection();
    hideSelectionMobileMenu();
  }

  //add page down events
  $(document).on('mousedown', function () {
    hideContextMenu();
  });

  //add page click events
  $(document).on('click', handleDocumentClickEvent);
  function handleDocumentClickEvent(event: Event) {
    //if the click is not in the table remove selections and hide the special menu
    if (
      $(event.target!).closest('table')[0] == undefined &&
      !dragged &&
      $(event.target!).closest('.' + mobileSelectionMenu)[0] == undefined
    ) {
      resetCopyRowSelection(event);
      hideSelectionMobileMenu();
    }
  }

  //add scroll events
  $(document).on('scroll', hideContextMenu);

  //add page key events
  $(document).on('keyup', 'body', handleDocumentKeyUpEvent);
  function handleDocumentKeyUpEvent(event: Event) {
    //make sure the key combo is valid
    let keyboardEvent = event as KeyboardEvent;
    if (copyRows.size <= 0 || (keyboardEvent.key !== 'c' && keyboardEvent.key !== 'x')) {
      return;
    }

    //all combos must have ctrlkey
    if (keyboardEvent.ctrlKey) {
      //get the target.id
      let target = event.target as HTMLElement;
      let saveTargetID = JSON.parse(JSON.stringify(target.id));

      //set it to simulate a certain click
      if (keyboardEvent.key === 'x') {
        target.id = copyTextID.substring(1);
      } else {
        target.id = copyLinkID.substring(1);
      }

      //copy the rows and show the toast
      copySelectedRows(event);

      //reset the target.id
      target.id = saveTargetID;
    }
  }

  //add page right click events to hide special menu
  $(document).on('contextmenu', function () {
    hideContextMenu();
  });

  //hide the special menu when an option is clicked
  $(contextMenuID).on('click', function () {
    hideContextMenu();
  });

  //add copy clicks
  addCopyClick();
  addTableMove();
}

function addMobileSelectionMenuClickEvents() {
  //initialize button variables
  let backBtn = document.getElementById(mobileSelectionMenu + '-back-btn') as HTMLButtonElement;
  let selectAllBtn = document.getElementById(mobileSelectionMenu + '-select-all-btn') as HTMLInputElement;
  let copyTextBtn = document.getElementById(mobileSelectionMenu + '-copy-text-btn') as HTMLButtonElement;
  let copyLinkBtn = document.getElementById(mobileSelectionMenu + '-copy-link-btn') as HTMLButtonElement;

  //handle back button clicks
  backBtn?.addEventListener('click', function (event) {
    resetCopyRowSelection(event);
    hideSelectionMobileMenu();
  });

  //handle select all clicks
  selectAllBtn?.addEventListener('click', function (event) {
    if (selectAllBtn.checked) {
      for (let i = 0; i < rowArray.length; i++) {
        if (!copyRows.has(rowArray[i] as HTMLTableRowElement)) {
          addRowToSelection(rowArray[i] as HTMLTableRowElement, event);
        }
      }
    } else {
      for (let i = 0; i < rowArray.length; i++) {
        if (copyRows.has(rowArray[i] as HTMLTableRowElement)) {
          deleteRowFromSelection(rowArray[i] as HTMLTableRowElement);
        }
      }
    }
  });

  //handle copy buttons clicks
  copyTextBtn?.addEventListener('click', copyTextHandler);
  copyLinkBtn?.addEventListener('click', copyLinkHandler);
}

export function resetCopyRowSelection(event?: Event) {
  //remove the selection style from each row and reinit the set
  copyRows.forEach((row) => {
    $(row).removeClass(selectionClass).removeClass(mainSelectionClass);
  });
  copyRows = new Set();
  updateSelectedRowsDataset();
  if (event == undefined || !(event as KeyboardEvent).shiftKey) {
    selectedRowIndex = null;
  }
  handleMobileMenu();
}

function hideContextMenu() {
  $(contextMenuID).removeClass('show').hide();
}

function addCopyClick() {
  //add event listner for copy clicks
  $(copyLinkID).on('mousedown', copyLinkHandler);
  $(copyTextID).on('mousedown', copyTextHandler);
}

function copyLinkHandler(event: Event) {
  //get the target.id
  let target = event.target as HTMLElement;
  let saveTargetID = JSON.parse(JSON.stringify(target.id));

  //set it to be the right id
  target.id = copyLinkID.substring(1);

  //copy the rows and show the toast
  copySelectedRows(event);

  //reset the target.id
  target.id = saveTargetID;
}

function copyTextHandler(event: Event) {
  //get the target.id
  let target = event.target as HTMLElement;
  let saveTargetID = JSON.parse(JSON.stringify(target.id));

  //set it to be the right id
  target.id = copyTextID.substring(1);

  //copy the rows and show the toast
  copySelectedRows(event);

  //reset the target.id
  target.id = saveTargetID;
}

function addTableMove() {
  $(tableID).on('mousedown', function (event) {
    let row = $(event.target).closest('tr')[0] as HTMLTableRowElement;
    if (overARow(row) && ((!row.classList.contains(selectionClass) && event.which == 3) || event.which != 3)) {
      $(tableID).off('mousemove', tableMouseMoveEventHandler);
      $(tableID).on('mousemove', tableMouseMoveEventHandler);
    }
    dragged = false;
  });
  $(document).on('mouseup', function () {
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
function tableMouseMoveEventHandler(event: JQuery.TriggeredEvent) {
  var date = new Date().getTime();
  if (date - prevDate > 2) {
    let row = $(event.target).closest('tr')[0] as HTMLTableRowElement;
    let rowIndex = getRowArrayIndex(row);
    if (!dragged) {
      startRowIndex = rowIndex;
      if (!event.shiftKey && !event.ctrlKey) {
        resetCopyRowSelection();
      } else if (event.shiftKey && $('.' + selectionClass).length > 0) {
        startRowIndex = selectedRowIndex;
        resetCopyRowSelection();
        selectStartToCurrent(rowIndex);
        prevRowIndex = rowIndex;
        upDown = isSelectionAboveStart(rowIndex);
        if (upDown) {
          prevRowIndex!++;
        } else {
          prevRowIndex!--;
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

function toggleSelectionDrag(row: HTMLTableRowElement) {
  let rowIndex = getRowArrayIndex(row);

  if (isSelectionMoveValid(rowIndex)) {
    if (!copyRows.has(row)) {
      addRowToSelection(row);
      upDown = rowIndex <= startRowIndex!;
      prevRowIndex = currentRowIndex;
    } else if (startRowIndex != currentRowIndex && rowIndex == prevRowIndex) {
      deleteRowFromSelection(rowArray[currentRowIndex!] as HTMLTableRowElement);
      if (upDown) {
        prevRowIndex!++;
      } else {
        prevRowIndex!--;
      }
    }
  } else {
    resetCopyRowSelection();
    selectStartToCurrent(rowIndex);
    prevRowIndex = rowIndex;
    upDown = isSelectionAboveStart(rowIndex);
    if (upDown) {
      prevRowIndex!++;
    } else {
      prevRowIndex!--;
    }
  }
  if (rowIndex != startRowIndex) {
    currentRowIndex = rowIndex;
  } else {
    if (prevRowIndex != startRowIndex && rowArray[prevRowIndex!] != undefined) {
      deleteRowFromSelection(rowArray[prevRowIndex!] as HTMLTableRowElement);
    }
    prevRowIndex = null;
    currentRowIndex = startRowIndex;
  }
  selectedRowIndex = currentRowIndex;
  dragged = true;
}

function selectStartToCurrent(rowIndex: number) {
  if (isSelectionAboveStart(rowIndex)) {
    for (let i = startRowIndex!; i >= rowIndex; i--) {
      addRowToSelection(rowArray[i] as HTMLTableRowElement);
    }
  } else {
    for (let i = startRowIndex!; i <= rowIndex; i++) {
      addRowToSelection(rowArray[i] as HTMLTableRowElement);
    }
  }
}

function selectSelectionToCurrent(rowIndex: number) {
  if (isSelectionAboveSelection(rowIndex)) {
    for (let i = selectedRowIndex!; i >= rowIndex; i--) {
      addRowToSelection(rowArray[i] as HTMLTableRowElement);
    }
  } else {
    for (let i = selectedRowIndex!; i <= rowIndex; i++) {
      addRowToSelection(rowArray[i] as HTMLTableRowElement);
    }
  }
}

function isSelectionAboveStart(rowIndex: number) {
  return rowIndex < startRowIndex!;
}

function isSelectionAboveSelection(rowIndex: number) {
  return rowIndex < selectedRowIndex!;
}

function isSelectionMoveValid(rowIndex: number) {
  return currentRowIndex == rowIndex || rowIndex == currentRowIndex! + 1 || rowIndex == currentRowIndex! - 1;
}

function handleMobileMenu() {
  updateCountShown();
}

function updateCountShown() {
  let selectionCountElement = document.getElementById(mobileSelectionMenu + '-selection-count');
  if (selectionCountElement != undefined) {
    selectionCountElement.innerHTML = copyRows.size + ' Selected';
  }
}

function showHideSelectionMobileMenu() {
  //if it's a mobile screen and the menu is not visible, show it
  if (isMobileScreen() && !$('.' + mobileSelectionMenu).is(':visible')) {
    $('.' + mobileSelectionMenu).show();
  } else {
    hideSelectionMobileMenu();
  }
}

function hideSelectionMobileMenu() {
  $('.' + mobileSelectionMenu).hide();
  let selectAllBtn = (document.getElementById(mobileSelectionMenu + '-select-all-btn') as HTMLInputElement);
  if (selectAllBtn != undefined) {
    selectAllBtn.checked = false;
  }
}

function getRowArrayIndex(row: HTMLTableRowElement) {
  rowArray = $(tableID).find('tbody').first()[0].children as HTMLCollectionOf<HTMLElement>;
  return [...rowArray].findIndex((object) => {
    return object.id === row.id;
  });
}

function deleteRowFromSelection(row: HTMLTableRowElement) {
  copyRows.delete(row);
  updateSelectedRowsDataset();
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
    (document.getElementById(mobileSelectionMenu + '-select-all-btn') as HTMLInputElement).checked = false;
  }
}

function addRowToSelection(row: HTMLTableRowElement, event?: Event) {
  if (!$(row).parent('thead').is('thead')) {
    copyRows.add(row);
    updateSelectedRowsDataset();
    $(row).addClass(selectionClass);
    let rowIndex = getRowArrayIndex(row);

    if (isCtrlKeyPressedAndChangesStart(rowIndex, event as KeyboardEvent)) {
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
      $('.' + mobileSelectionMenu).show();
      if (copyRows.size == rowArray.length) {
        (document.getElementById(mobileSelectionMenu + '-select-all-btn') as HTMLInputElement).checked = true;
      }
    }
  }
}

function isThereAMainSelection() {
  return $('.' + mainSelectionClass).length != 0;
}

function isCtrlKeyPressedAndChangesStart(rowIndex: number, event?: KeyboardEvent) {
  return (
    (copyRows.size > 1 &&
      !dragged &&
      event != undefined &&
      event.ctrlKey &&
      ((upDown && rowIndex > startRowIndex!) || (!upDown && rowIndex < startRowIndex!))) ||
    (!dragged && event != undefined && event.ctrlKey)
  );
}

function mainSelectClosestSelection(rowIndex: number) {
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

function updateIndexVariablesAfterSwap(newIndex: number) {
  $(rowArray[newIndex]).addClass(mainSelectionClass);
  startRowIndex = newIndex;
  selectedRowIndex = newIndex;
}

function isMobileScreen() {
  return window.innerWidth <= 767;
}

function overARow(row: HTMLTableRowElement) {
  return row != undefined && row.localName == 'tr' && row.parentElement!.localName == 'tbody';
}

function addCustomListeners() {
  SacaStatsEventUtil.addCustomEventListener(document.getElementById(tableID.substring(1))!, new AddCustomCopyEvent(),
    (customEvent: Event) => {
      setCustomCopyFunction((<CustomEvent>customEvent).detail[0] as Function);
    }
  );

  SacaStatsEventUtil.addCustomEventListener(document.getElementById(tableID.substring(1))!, new AddSecondCustomCopyEvent(),
    (customEvent: Event) => {
      setSecondCustomCopyFunction((<CustomEvent>customEvent).detail[0] as Function);
    }
  );
}

function copySelectedRows(event: Event) {
  $(copyToastID).removeClass('d-none');
  (<any>$(copyToastID)).toast('show');
  setTimeout(function () {
    $(copyToastID).addClass('d-none');
  }, 1000);
  hideContextMenu();
  let copyString = '';
  if (customCopyFunction != undefined || secondCustomCopyFunction != undefined) {
    if ((event.target as HTMLElement).id == copyLinkID.substring(1)) {
      copyString = customCopyFunction();
    } else {
      copyString = secondCustomCopyFunction();
    }
  } else {
    let headerArray = $(tableID).find('thead').first().find('tr').first()[0].children as HTMLCollectionOf<HTMLElement>;
    let index = 0;
    copyRows.forEach((row) => {
      let dataArray = $(row).find('td');

      for (let i = 0; i < dataArray.length; i++) {
        if (i > 0) {
          copyString = copyString + ', ';
        }
        let desktopTitle =
          (dataArray[i].hasAttribute('data-mobile-title') && dataArray[i].getAttribute('data-mobile-title')
            ? dataArray[i].getAttribute('data-mobile-title')
            : headerArray[i].innerText) + ': ';
        copyString = copyString + (isMobileScreen() ? '' : desktopTitle) + dataArray[i].innerText;
      }
      if (index < copyRows.size - 1) {
        copyString = copyString + '\n\n';
        index++;
      }
    });
  }

  //copy the new url to clipboard and reset selection
  copyTextToClipboard(copyString);
  resetCopyRowSelection(event);
  showHideSelectionMobileMenu();
}

function updateSelectedRowsDataset() {
  let selectedRowIDs = [...copyRows].map((row) => row.id);
  document.getElementById(tableID.substring(1))!.dataset.selectedRowIDs = JSON.stringify(selectedRowIDs);
}

function fallbackCopyTextToClipboard(text: string) {
  var textArea = document.createElement('textarea');
  textArea.value = text;

  // Avoid scrolling to bottom
  textArea.style.top = '0';
  textArea.style.left = '0';
  textArea.style.position = 'fixed';

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    var successful = document.execCommand('copy');
    if (!successful) {
      console.log('Failed to copy text.');
    }
  } catch (err) {
    console.error('Failed to copy text.', err);
  }

  document.body.removeChild(textArea);
}
function copyTextToClipboard(text: string) {
  if (!navigator.clipboard) {
    fallbackCopyTextToClipboard(text);
    return;
  }
  navigator.clipboard.writeText(text);
}

export function getSelectedRows() {
  return JSON.parse(document.getElementById(tableID.substring(1))!.dataset.selectedRowIDs!) as string[];
}

export function setCustomCopyFunction(customFunction: Function) {
  customCopyFunction = customFunction;
}

export function setSecondCustomCopyFunction(customFunction: Function) {
  secondCustomCopyFunction = customFunction;
}

export function init(id: string) {
  tableID = '#' + id;
  copyLinkID = '#table-copy-link-row';
  copyTextID = '#table-copy-text-row';
  contextMenuID = '#table-context-menu';
  copyToastID = '#table-copy-toast';
  rowArray = $(tableID).find('tbody').first()[0].children as HTMLCollectionOf<HTMLTableRowElement>;
  updateSelectedRowsDataset();

  addTableClickHandler();
  addCustomListeners();
  hideSelectionMobileMenu();
  addMobileSelectionMenuClickEvents();
}

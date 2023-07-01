import * as FlexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';
import { ColumnsChangedEvent, ColumnSortChangedEvent } from '../events/flex-bootstrap-table-events.js';
import { SacaStatsEventUtil } from '../events/sacastats-event-util.js';

import {
  IPersistentColumn,
  IColumnOrderObject,
  ITableField,
  ITableSortedField,
  SortOrder,
  SortOrderIcon,
  IndexedColumn,
} from '../models/flex-bootstrap-table/flex-bootstrap-table-column.js';

let tableID: string;
let table: HTMLTableElement;
let globalIndexOrder: number[];
let globalColumns: IPersistentColumn;
let previousDragTableUpdate: IColumnOrderObject = {};
let previousColumns: ITableField[];
let previousSorted: ITableSortedField;
let animating = false;
let animationDuration = 50;

export function fixColumnDropDown() {
  //fix column dropdown offset and bugs
  let columnDropDown = document.querySelector("button[title='Columns']") as HTMLElement;
  if (columnDropDown != undefined) {
    (columnDropDown!.parentElement!.lastChild as HTMLElement).style.width = '20rem';

    columnDropDown.click();
    columnDropDown.click();
  }
}

function getSortedField(): ITableSortedField {
  //get table header elements based on asc and desc
  let toSortDesc = table.querySelector('.' + SortOrder.DESCENDING) as HTMLElement;
  let toSortAsc = table.querySelector('.' + SortOrder.ASCENDING) as HTMLElement;

  //initialize return variables
  let sortedFieldText = '';
  let order = SortOrder.NONE;

  //if there is a desc header
  if (toSortDesc != undefined) {
    sortedFieldText = toSortDesc.innerText;
    order = SortOrder.DESCENDING;

    //else if there is an asc header
  } else if (toSortAsc != undefined) {
    sortedFieldText = toSortAsc.innerText;
    order = SortOrder.ASCENDING;
  }

  //return the current sorted header and what order it is sorted
  return { fieldText: sortedFieldText, order: order };
}

function setSortedField(sortedFieldText: string, sortTo: SortOrder) {
  //null check
  if (sortedFieldText != undefined) {
    //get header element based on text content
    let el = Array.from(table.querySelectorAll('div.th-inner')).find(
      (el) => el.textContent === sortedFieldText,
    ) as HTMLElement;

    //click header once to provide initial sort
    el.click();

    //if it should be sorted the other way click the header again
    if (![...el.classList].includes(sortTo)) {
      el.click();
    }

    //refresh by scroll to bring back sticky headers
    refreshByScroll();
  }
}

function refreshByScroll() {
  let currentScrollPosition = $(window).scrollTop()!;
  let maxScrollPosition = document.documentElement.scrollHeight - document.documentElement.clientHeight;

  if (currentScrollPosition == maxScrollPosition) {
    $(window).scrollTop(currentScrollPosition - 1);
  } else {
    $(window).scrollTop(currentScrollPosition + 1);
    $(window).scrollTop(currentScrollPosition - 1);
  }
}

function findVisibleFields() {
  //initialize variables
  var columns = $(tableID).bootstrapTable('getVisibleColumns');
  var fields: ITableField[] = [];

  //add fields and titles to array
  for (var index in columns) {
    fields.push({
      field: columns[index].field,
      title: columns[index].title,
    });
  }

  //return fields array
  return fields;
}

function findSortedVisibleFields() {
  //initialize variables
  let fields = findVisibleFields();
  let tempFields: ITableField[] = [];

  //add all headers to array
  table.querySelectorAll('div.th-inner')?.forEach((header) => {
    for (let i = 0; i < fields.length; i++) {
      if (fields[i].title === (header as HTMLElement).innerText) {
        tempFields.push(fields[i]);
        break;
      }
    }
  });

  //return all columns
  return tempFields;
}

function findSortableVisibleColumns() {
  //initialize variables
  let fields = findVisibleFields();
  let tempFields: ITableField[] = [];

  //add all headers with the sortable class to array
  table.querySelectorAll('div.th-inner.sortable').forEach((header) => {
    for (let i = 0; i < fields.length; i++) {
      if (fields[i].title === (header as HTMLElement).innerText) {
        tempFields.push(fields[i]);
        break;
      }
    }
  });

  //return sortable columns
  return tempFields;
}

function findNonSortableVisibleColumns() {
  //initialize variables
  let fields = findVisibleFields();
  let tempFields: ITableField[] = [];

  //add all headers without the sortable class to array
  table.querySelectorAll('div.th-inner:not(.sortable)').forEach((header) => {
    for (let i = 0; i < fields.length; i++) {
      if (fields[i].title === (header as HTMLElement).innerText) {
        tempFields.push(fields[i]);
        break;
      }
    }
  });

  //return nonsortable columns
  return tempFields;
}

function initializeColumns() {
  //initialize variables
  const PERSISTENT_COLUMNS_NAME = table.id + '/columnMap';
  let persistentColumns = localStorage.getItem(PERSISTENT_COLUMNS_NAME);

  //if there are persistent columns, initialize new columns
  if (persistentColumns != undefined) {
    let persistentColumnsObject = JSON.parse(persistentColumns);
    setColumnVisibilitesAndSorts(persistentColumnsObject);
    setTimeout(() => {
      initializeMobileSortMenu(persistentColumnsObject);
    }, 150);
  }
}

function setColumnVisibilitesAndSorts(persistentColumns: IPersistentColumn) {
  //hide all columns
  $(tableID).bootstrapTable('hideAllColumns');

  //create the index order of columns
  let indexOrder: number[] = [];
  persistentColumns.fields.forEach((field) => {
    let index = persistentColumns.fields.findIndex((tableField) => {
      return tableField.field === field.field;
    });
    if (index != -1) {
      indexOrder.push(index);
    }
  });

  //update global index orders and columns
  globalIndexOrder = indexOrder;
  globalColumns = persistentColumns;

  //restore column order and sorted field
  setColumnOrder();
  setSortedField(persistentColumns.sorted.fieldText, persistentColumns.sorted.order);
}

function setColumnOrder() {
  //initialize variables
  let orderObject: IColumnOrderObject = {};
  let indexedColumnArray: IndexedColumn[] = [];

  //loop through column order and add to orderObject
  for (let i = 0; i < globalIndexOrder.length; i++) {
    let indexedColumn = new IndexedColumn(globalIndexOrder[i], globalColumns['fields'][i]['field']);
    indexedColumnArray.push(indexedColumn);
    orderObject[globalColumns['fields'][i]['field']] = globalIndexOrder[i];
  }

  //show each column that should be visible
  for (let i = 0; i < indexedColumnArray.length; i++) {
    let fieldIndex = indexedColumnArray.findIndex((indexedColumn) => {
      return indexedColumn.index == i;
    });

    if (fieldIndex != -1) {
      $(tableID).bootstrapTable('showColumn', indexedColumnArray[fieldIndex].field);
    }
  }

  //set the column order
  refreshDragColumns(orderObject);
}

function refreshDragColumns(orderObject: IColumnOrderObject) {
  if (JSON.stringify(previousDragTableUpdate) !== JSON.stringify(orderObject)) {
    previousDragTableUpdate = orderObject;
    setTimeout(() => {
      $(tableID).bootstrapTable('orderColumns', orderObject);
    }, 100);
  }
}

function moveColumnUp(selectedColumnElement: HTMLElement) {
  //initialize variables
  let prevCol = $(selectedColumnElement).prev(),
    distance = $(selectedColumnElement).outerHeight()!;

  //if a previous column exists
  if (prevCol.length) {
    //start animation of column swap
    animating = true;
    $.when(
      $(selectedColumnElement).animate(
        {
          top: -distance,
        },
        animationDuration,
      ),
      prevCol.animate(
        {
          top: distance,
        },
        animationDuration,
      ),
    ).done(function () {
      //when animation is done reset element position
      prevCol.css('top', '0px');
      $(selectedColumnElement).css('top', '0px');

      //swap selected column with the previous one
      $(selectedColumnElement).insertBefore(prevCol);

      //notify animation completion
      animating = false;
    });
  }
}
function moveColumnDown(selectedColumnElement: HTMLElement) {
  //initialize variables
  let nextCol = $(selectedColumnElement).next(),
    distance = $(selectedColumnElement).outerHeight()!;

  //if a next column exists
  if (nextCol.length) {
    //start animation of column swap
    animating = true;
    $.when(
      $(nextCol).animate(
        {
          top: -distance,
        },
        animationDuration,
      ),
      $(selectedColumnElement).animate(
        {
          top: distance,
        },
        animationDuration,
      ),
    ).done(function () {
      //when animation is done reset element position
      $(selectedColumnElement).css('top', '0px');
      nextCol.css('top', '0px');

      //swap selected column with the next one
      $(selectedColumnElement).insertAfter(nextCol);

      //notify animation completion
      animating = false;
    });
  }
}
function handleMoveColumnEvent(event: Event) {
  //prevent clicks during swap
  if (animating) {
    return;
  }

  //make sure there is a selected column
  let selectedColumnElement = document
    .getElementById(table.id + '-sortable-columns')
    ?.querySelector('.selected-sortable-column') as HTMLElement;
  if (selectedColumnElement == undefined) {
    return;
  }

  //initialize arrow element
  let arrow: HTMLElement;
  let target = event.target as HTMLElement;
  if (target.tagName.toLowerCase() != 'div') {
    arrow = $(target).closest('div')[0];
  } else {
    arrow = target;
  }

  //handle arrow function
  if (arrow.id.includes('up')) {
    moveColumnUp(selectedColumnElement);
  } else {
    moveColumnDown(selectedColumnElement);
  }

  setTimeout(() => {
    refreshSortableColumnSelection(selectedColumnElement);
  }, animationDuration * 2 + 10);
}

function createSortableColumn(dataField: string, text: string, sortType: SortOrder) {
  // Example creation:
  // <div id="weaponsTable-killedby-column" class="dropdown-item sortable-column">
  //  <span class="sortable-column-title">Killed By</span><i class="mobile-sort-icon fa-solid fa-sort-down"></i>
  // </div>

  //create outter div
  let divElement = document.createElement('div');
  divElement.id = table.id + '-' + dataField + '-column';
  divElement.classList.add('dropdown-item', 'sortable-column');
  divElement.dataset.field = dataField;

  //create span title
  let spanElement = document.createElement('span');
  spanElement.classList.add('sortable-column-title');
  let spanText = document.createTextNode(text);
  spanElement.appendChild(spanText);

  //create sort icon
  let iconElement = document.createElement('i');
  let iconString = getSortOrderIconFromSortOrder(sortType) as string;
  iconElement.classList.add('mobile-sort-icon', 'fa-solid', iconString);

  //append title and icon to div
  divElement.appendChild(spanElement);
  divElement.appendChild(iconElement);

  return divElement;
}

function getSortOrderIconFromSortOrder(sortType: SortOrder): SortOrderIcon {
  switch (sortType) {
    case SortOrder.ASCENDING:
      return SortOrderIcon.ASCENDING;
    case SortOrder.DESCENDING:
      return SortOrderIcon.DESCENDING;
    default:
      return SortOrderIcon.NONE;
  }
}

function initializeMobileSortMenu(persistentColumnsObject: IPersistentColumn) {
  //initialize variables
  let sortableColumnMenu = document.getElementById(table.id + '-column-sort-dropdown-menu') as HTMLElement;
  let sortableColumnsContainer = document.getElementById(table.id + '-sortable-columns') as HTMLElement;
  let isReInitialization = sortableColumnsContainer.innerHTML != '';
  let currentScroll: number = 0;

  //if it has already been initialized
  if (isReInitialization) {
    //save the current scroll and clear the columns
    currentScroll = sortableColumnMenu.scrollTop;
    sortableColumnsContainer.innerHTML = '';
  }

  //get all visible sortable columns and which one is sorted in what way
  let sortedField = persistentColumnsObject.sorted;
  let columns = findSortableVisibleColumns();

  //for each column
  columns.forEach((column) => {
    //set sort type to none
    let sortType = SortOrder.NONE;

    //if the column should be sorted set the specific sort type
    if (column.title == sortedField.fieldText) {
      sortType = sortedField.order;
    }

    //create the column element and add an alt and click listener to handle selecting and sorting respectively
    let columnElement = createSortableColumn(column.field, column.title, sortType);
    columnElement?.addEventListener('contextmenu', handleSortableColumnContextMenu);
    columnElement?.addEventListener('click', handleSortableColumnClick);

    //add column element to container
    sortableColumnsContainer.appendChild(columnElement);
  });

  //if it was already initialized restore scroll position
  if (isReInitialization) {
    sortableColumnMenu.scrollTop = currentScroll;
  }
}

function handleInitialMobileSortButtonClick() {
  //when initially opening the menu, it must be opened then close to open in the right position
  let buttonElement = document.getElementById(table.id + '-column-sort-button') as HTMLElement;
  buttonElement.click();
  buttonElement.click();

  //this should only need to be done once so this can be removed
  buttonElement?.removeEventListener('click', handleInitialMobileSortButtonClick);
}

function isClickTargetAColumnAfterSelection(target: HTMLElement) {
  if ($(target).closest('div.sortable-column').length > 0 || target.classList.contains('sortable-column')) {
    //remove selection without updating order as that will be done on the column sort click
    removeSortableColumnSelection();
    return true;
  } else {
    return false;
  }
}

function handleColumnOrderSorted(event: Event) {
  //check if columns should be reordered
  let target = event.target as HTMLElement;
  if (target.tagName.toLowerCase() == 'svg' || target.tagName.toLowerCase() == 'path') {
    target = $(target).closest('div')[0];
  }

  //early return if columns should NOT be reordered
  if (
    target.id == table.id + '-column-move-up' ||
    target.id == table.id + '-column-move-down' ||
    isClickTargetAColumnAfterSelection(target)
  ) {
    return;
  }

  //remove selection
  removeSortableColumnSelection();

  //create order object
  let index = 0;
  let orderObject: IColumnOrderObject = {};

  //account for non sortable headers
  findNonSortableVisibleColumns().forEach((nonSortableColumn) => {
    orderObject[nonSortableColumn.field] = index;
    index++;
  });

  //add sortable headers to orderObject
  document.getElementById(table.id + '-sortable-columns')!.childNodes.forEach((column) => {
    let field = (column as HTMLElement).dataset.field as string;
    orderObject[field] = index;
    index++;
  });

  //update column orders
  refreshDragColumns(orderObject);
}

function updatePersistentColumns() {
  //initialize variables
  let fields = findSortedVisibleFields();
  let sorted = getSortedField();
  let persistentColumnsObject: IPersistentColumn = { fields: fields, sorted: sorted };

  //update persistant column choices
  const PERSISTENT_COLUMNS_NAME = table.id + '/columnMap';
  localStorage.removeItem(PERSISTENT_COLUMNS_NAME);
  localStorage.setItem(PERSISTENT_COLUMNS_NAME, JSON.stringify(persistentColumnsObject));

  //reinitialize mobile sort menu with new data
  initializeMobileSortMenu(persistentColumnsObject);
}

function handleColumnChangedEvent(_event: Event) {
  //update persistant columns
  updatePersistentColumns();
}

function handleSortChangedEvent(_event: Event) {
  //update persistant columns
  updatePersistentColumns();
}

function addEventHandlers() {
  //add event listeners for mobile column move arrows
  document.getElementById(table.id + '-column-move-up')?.addEventListener('click', handleMoveColumnEvent);
  document.getElementById(table.id + '-column-move-down')?.addEventListener('click', handleMoveColumnEvent);

  //add event listener for column sort button
  document
    .getElementById(table.id + '-column-sort-button')
    ?.addEventListener('click', handleInitialMobileSortButtonClick);

  //add event listeners for locking new column order
  $('#' + table.id + '-column-sort-dropdown').on('hide.bs.dropdown', handleColumnOrderSorted);
  document.getElementById(table.id + '-column-sort-dropdown-menu')?.addEventListener('click', handleColumnOrderSorted);

  //add event listeners for custom column change events
  SacaStatsEventUtil.addCustomEventListener(table, new ColumnsChangedEvent(), handleColumnChangedEvent);
  SacaStatsEventUtil.addCustomEventListener(table, new ColumnSortChangedEvent(), handleSortChangedEvent);
}

function setMoveArrowsOffsets(topOffset: number) {
  document.getElementById(table.id + '-column-move-up')!.style.top = topOffset + 'px';
  document.getElementById(table.id + '-column-move-down')!.style.top = topOffset + 'px';
}

function updateMoveArrowPositions(selectedColumnElement: HTMLElement) {
  let columnMoveTopOffset = selectedColumnElement.offsetTop + selectedColumnElement.offsetHeight / 2 + 23;
  setMoveArrowsOffsets(columnMoveTopOffset);
}

function removeSortableColumnSelection() {
  let selectedColumnElement = document
    .getElementById(table.id + '-sortable-columns')
    ?.querySelector('.selected-sortable-column');
  if (selectedColumnElement != undefined) {
    //remove highlight
    selectedColumnElement.classList.remove('selected-sortable-column');

    //hide arrows
    document.getElementById(table.id + '-column-move-up')!.classList.add('d-none');
    document.getElementById(table.id + '-column-move-down')!.classList.add('d-none');
  }
}

function addSortableColumnSelection(selectedColumnElement: HTMLElement) {
  selectedColumnElement.classList.add('selected-sortable-column');

  //if the selected column is not the top column show the move up arrow
  if ($(selectedColumnElement).prev().length == 1) {
    document.getElementById(table.id + '-column-move-up')!.classList.remove('d-none');
  }

  //if the selected column is not the bottom column show the move down arrow
  if ($(selectedColumnElement).next().length == 1) {
    document.getElementById(table.id + '-column-move-down')!.classList.remove('d-none');
  }
}

function refreshSortableColumnSelection(selectedColumnElement: HTMLElement) {
  removeSortableColumnSelection();

  updateMoveArrowPositions(selectedColumnElement);

  addSortableColumnSelection(selectedColumnElement);
}

function handleSortableColumnContextMenu(event: Event) {
  //initialize column element selection
  let selectedColumnElement = event.target as HTMLElement;
  if (!selectedColumnElement.classList.contains('sortable-column')) {
    selectedColumnElement = $(selectedColumnElement).closest('.sortable-column')[0];
  }

  refreshSortableColumnSelection(selectedColumnElement);

  event.preventDefault(); //blocks default Webbrowser right click menu
}

function handleSortableColumnClick(event: Event) {
  //initialize column element
  let columnElement = event.target as HTMLElement;
  if (!columnElement.classList.contains('sortable-column')) {
    columnElement = $(columnElement).closest('.sortable-column')[0];
  }

  //get corresponding table header and mobile column sort menu
  let tableColumnHeaderElement = table.querySelector(
    "thead > tr > th[data-field='" + columnElement.dataset.field + "'] > div.th-inner",
  ) as HTMLElement;
  let sortableMenuButtonElement = document.getElementById(table.id + '-column-sort-button') as HTMLElement;

  //click the corresponding table header to sort then reopen the mobile column sort menu
  tableColumnHeaderElement.click();
  sortableMenuButtonElement.click();
}

function checkIfAColumnDifferent() {
  //if there is a different column visible or they are in a new order
  let columns = findSortedVisibleFields();
  if (JSON.stringify(columns) !== JSON.stringify(previousColumns)) {
    //update previous columns
    previousColumns = columns;

    //trigger custom event
    SacaStatsEventUtil.dispatchCustomEvent(table, new ColumnsChangedEvent(JSON.stringify(columns)));
  }
}

function checkIfASortDifferent() {
  //if there is a different column sorted or the sort is different
  let sorted = getSortedField();
  if (JSON.stringify(sorted) !== JSON.stringify(previousSorted)) {
    //update previous sorted
    previousSorted = sorted;

    //trigger custom event
    SacaStatsEventUtil.dispatchCustomEvent(table, new ColumnSortChangedEvent(sorted));
  }
}

export function updateColumns() {
  checkIfAColumnDifferent();
  checkIfASortDifferent();
}

export function init(id: string) {
  //initialize class variables
  tableID = '#' + id;
  table = document.getElementById(id) as HTMLTableElement;

  initializeColumns();
  addEventHandlers();
}

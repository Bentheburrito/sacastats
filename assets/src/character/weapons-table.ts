import { nextAuraxElementID } from '../character/weapons.js';
import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';

import { CustomFilterFunction } from '../models/flex-bootstrap-table/flex-bootstrap-table-filter.js';
import { ITableData } from '../models/flex-bootstrap-table/flex-bootstrap-table.js';
import { BootstrapTableOptions } from 'bootstrap-table';

const TABLE_ID = '#weaponTable';

window.addEventListener('load', (event) => {
  if (window.innerWidth >= 768) {
    setTimeout(function () {
      $('input.search-input:first').focus();
    }, 100);
  }

  //TODO edit dataset based on cached persistent data
  //document.getElementById("weaponTable").dataset.pagination = false;
});

function addCustomFilters() {
  //initialize variables
  const YEAR_SECOND = 31556952;
  const WEEK_SECOND = 604800;
  const DAY_SECOND = 86400;
  const HOUR_SECOND = 3600;
  const MINUTE_SECOND = 60;

  //set the custom functions object
  var customFunction: CustomFilterFunction[] = [
    new CustomFilterFunction('medal', function filterFunction(filterName: string, dataArray: ITableData[]) {
      //filter the array based on the filter name category
      switch (filterName) {
        case 'auraxium':
          return dataArray.filter((weapon) => weapon.kills >= 1160);
        case 'gold':
          return dataArray.filter((weapon) => weapon.kills < 1160 && weapon.kills >= 160);
        case 'silver':
          return dataArray.filter((weapon) => weapon.kills < 160 && weapon.kills >= 60);
        case 'bronze':
          return dataArray.filter((weapon) => weapon.kills < 60 && weapon.kills >= 10);
        case 'none':
          return dataArray.filter((weapon) => weapon.kills < 10);
        default:
          return dataArray;
      }
    }),
    new CustomFilterFunction('vehicleinfantry', function filterFunction(filterName: string, dataArray: ITableData[]) {
      //filter the array based on the filter name category
      switch (filterName) {
        case 'infantry':
          return dataArray.filter((weapon) => weapon.vw == 'No');
        case 'vehicle':
          return dataArray.filter((weapon) => weapon.vw == 'Yes');
        default:
          return dataArray;
      }
    }),
    new CustomFilterFunction('time', function filterFunction(filterName: string, dataArray: ITableData[]) {
      //filter the array based on the filter name category
      switch (filterName) {
        case 'years':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time >= YEAR_SECOND;
          });
        case 'weeks':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time >= WEEK_SECOND && time < YEAR_SECOND;
          });
        case 'days':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time >= DAY_SECOND && time < WEEK_SECOND;
          });
        case 'hours':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time >= HOUR_SECOND && time < DAY_SECOND;
          });
        case 'minutes':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time >= MINUTE_SECOND && time < HOUR_SECOND;
          });
        case 'seconds':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time > 0 && time < MINUTE_SECOND;
          });
        case 'none':
          return dataArray.filter((weapon) => {
            let div = document.createElement('div');
            div.innerHTML = (weapon.time as string).trim();
            let time = +(div.firstChild as HTMLElement).innerHTML;

            return time == 0;
          });
        default:
          return dataArray;
      }
    }),
  ];

  //Add it to the filter list
  let addCustomFilterFunctionEvent = flexBootstrapTableEvents.createEvent(flexBootstrapTableEvents.ADD_CUSTOM_FILTER_FUNCTIONS_EVENT, customFunction);
  document.getElementById(TABLE_ID.substring(1))?.dispatchEvent(addCustomFilterFunctionEvent);
}

function addCustomCopyFunction() {
  let customFunction = function () {
    //get the current url
    const newURL = new URL(window.location.href);
    newURL.search = '?';

    //if there is only 1 selection add the weapon name to the search arg
    let copyRows = [...getTableSelection()];
    let firstCopyElement = document.getElementById(copyRows[0]) as HTMLElement;
    if (copyRows.length == 1) {
      newURL.search = newURL.search + 'search=';
      newURL.search =
        newURL.search +
        $(firstCopyElement).find('td.weapon').first().find('h5.weaponName').first()[0].innerHTML.replaceAll(' ', '_');
      newURL.search = newURL.search + '&';
    }

    //add each selected id to the id arg separated by ','
    newURL.search =
      newURL.search + 'id=' + firstCopyElement.id.replaceAll(TABLE_ID.substring(1), '').replaceAll('Row', '');
    for (let i = 1; i < copyRows.length; i++) {
      newURL.search = newURL.search + ',' + copyRows[i].replaceAll(TABLE_ID.substring(1), '').replaceAll('Row', '');
    }

    //return the new url
    return newURL.toString().replaceAll('%22', '"');
  };

  let customCopyFunction = function () {
    //create a header line
    let copyString = (document.getElementById('characterName') as HTMLElement).innerText + "'s Weapon Stats\n\n";

    //initialize variables
    let headerArray = [...$(TABLE_ID).find('thead').first().find('tr').first()[0].children];
    let index = 0;
    let copyRows = getTableSelection();

    //loop through each selected weapon row
    copyRows.forEach((row) => {
      let dataArray = $("#" + row).find('td');

      //create a weapon subheader
      copyString =
        copyString +
        dataArray[0].innerText.split('\n')[0] +
        ' (' +
        row.replaceAll(TABLE_ID.substring(1), '').replaceAll('Row', '') +
        '):\n';

      //loop through each coloumn and separate them by commas and property values by colons
      for (let i = 1; i < dataArray.length; i++) {
        if (i > 1) {
          copyString = copyString + ', ';
        }
        let desktopTitle =
          (dataArray[i].hasAttribute('data-mobile-title') && dataArray[i].getAttribute('data-mobile-title')
            ? dataArray[i].getAttribute('data-mobile-title')
            : (headerArray[i] as HTMLElement).innerText) + ': ';
        copyString = copyString + (isMobileScreen() ? '' : desktopTitle) + dataArray[i].innerText;
      }

      //create new line space between each weapon stat
      if (index < copyRows.length - 1) {
        copyString = copyString + '\n\n';
        index++;
      }
    });

    //return the copy string
    return copyString;
  };

  let addCustomCopyFunctionEvent = flexBootstrapTableEvents.createEvent(flexBootstrapTableEvents.ADD_CUSTOM_COPY_EVENT, customFunction);
  document.getElementById(TABLE_ID.substring(1))?.dispatchEvent(addCustomCopyFunctionEvent);

  let addSecondCustomCopyFunctionEvent = flexBootstrapTableEvents.createEvent(flexBootstrapTableEvents.ADD_SECOND_CUSTOM_COPY_EVENT, customCopyFunction);
  document.getElementById(TABLE_ID.substring(1))?.dispatchEvent(addSecondCustomCopyFunctionEvent);
}

function getTableSelection() {
  return JSON.parse(document.getElementById(TABLE_ID.substring(1))!.dataset.selectedRowIDs!) as string[];
}

function initializeButtonEvent() {
  document.getElementById('nextAurax')?.addEventListener('click', function () {
    $('html, body').animate(
      {
        scrollTop: $('#' + nextAuraxElementID).offset()!.top - (window.innerWidth >= 768 ? 300 : 10), //- 254 to be at top
      },
      500,
    );
    setTimeout(function () {
      flashElement(nextAuraxElementID);
    }, 500);
  });
}

function flashElement(elementId: string) {
  let flashInterval = setInterval(function () {
    $('#' + elementId).toggleClass('flash-border');
  }, 250);
  setTimeout(function () {
    window.clearInterval(flashInterval);
    $('#' + elementId).removeClass('flash-border');
  }, 1500);
}

function isMobileScreen() {
  return window.innerWidth <= 767;
}

function showHideNextAuraxButton() {
  if (document.getElementById('nextAurax') != undefined) {
    if (document.getElementById(nextAuraxElementID) != undefined) {
      $('#nextAurax').show();
    } else {
      $('#nextAurax').hide();
    }
  }
}

function addCustomSearchFunction() {
  let customSearchFunction = function (filteredTableData: ITableData[], searchInput: string) {
    return filteredTableData.filter(function (option) {
      //create a template element and set it to the weapon td
      var template = document.createElement('template');
      template.innerHTML = option.weapon as string;

      //get the weapon name and filter based on the search input
      return (
        (template.content.querySelector('.weaponName') as HTMLElement).innerHTML
          .toLowerCase()
          .indexOf(searchInput.toLowerCase()) > -1
      );
    });
  };

  let addCustomSearchFunctionEvent = flexBootstrapTableEvents.createEvent(flexBootstrapTableEvents.ADD_CUSTOM_SEARCH_FUNCTION_EVENT, customSearchFunction);
  document.getElementById(TABLE_ID.substring(1))?.dispatchEvent(addCustomSearchFunctionEvent);
}

function addCustomEventListeners() {
  $(TABLE_ID).on(flexBootstrapTableEvents.filteredEvent, function () {
    setTimeout(function () {
      showHideNextAuraxButton();
    }, 10);
  });

  $(TABLE_ID).on(flexBootstrapTableEvents.initializedEvent, function () {
    showHideNextAuraxButton();
  });

  $(TABLE_ID).on(flexBootstrapTableEvents.formatsUpdatedEvent, function () {
    showHideNextAuraxButton();
  });
}

function initializeCustomFunctions() {
  addCustomSearchFunction();
  addCustomFilters();
  let addDesktopHeaderOnlyEvent = flexBootstrapTableEvents.createEvent(flexBootstrapTableEvents.ADD_DESKTOP_HEADER_ONLY_EVENT, ['Weapon']);
  document.getElementById(TABLE_ID.substring(1))?.dispatchEvent(addDesktopHeaderOnlyEvent);
}

function init() {
  let options = { dragaccept: '.drag-accept' } as BootstrapTableOptions;

  $(TABLE_ID).bootstrapTable(options);
  initializeCustomFunctions();
  initializeButtonEvent();
  addCustomCopyFunction();
  addCustomEventListeners();
}
init();

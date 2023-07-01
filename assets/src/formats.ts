import * as generalEvents from './events/general-events.js';
import { PageFormattedEvent } from './events/general-events.js';
import { SacaStatsEventUtil } from './events/sacastats-event-util.js';

const PREFERED_LANGUAGE = navigator.languages ? navigator.languages[0] : navigator.language;
const PREFERED_TIME_ZONE = Intl.DateTimeFormat().resolvedOptions().timeZone;
const LONG_FORMATTER = new Intl.DateTimeFormat(PREFERED_LANGUAGE, {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
  timeZone: PREFERED_TIME_ZONE
});
const TIME_FORMATTER = new Intl.DateTimeFormat(PREFERED_LANGUAGE, {
  hour: 'numeric',
  minute: 'numeric',
  second: 'numeric',
  hour12: true,
  timeZone: PREFERED_TIME_ZONE
});
const YEAR_SECOND = 31556952;
const DAY_SECOND = 86400;
const HOUR_SECOND = 3600;
const MINUTE_SECOND = 60;

export function formatDateTime(dateTime: Element) {
  try {
    let dateTimeObject = new Date(dateTime.innerHTML);

    try {
      dateTime.innerHTML =
        LONG_FORMATTER.format(dateTimeObject) + ' @ ' + TIME_FORMATTER.format(dateTimeObject);
    } catch (error) {
      console.error(error);
      console.error('LONG_FORMATTER: ');
      console.error(LONG_FORMATTER);
      console.error('dateTimeObject: ');
      console.error(dateTimeObject);
      console.error('dateTime.innerHTML: ');
      console.error(dateTime.innerHTML);
    }
  } catch (error) {
    console.error(error);
    console.error("Time variables not defined for: '" + dateTime.innerHTML + "'.");
  }
}

export function addCommasToNumber(number: Element) {
  number.innerHTML = number.innerHTML.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export function addPercent(percent: Element) {
  // if there is no percent sign, add one
  if (percent.innerHTML == '') {
    percent.innerHTML = 'N/A';
  } else if (percent.innerHTML.slice(-1) != '%' && percent.innerHTML.slice(-1) != 'A') {
    percent.innerHTML += '%';
  }
}

export function secondsToHHMMSS(second: Element) {
  let secondFindingArray = second.innerHTML.split('</span>');
  let secondCount = +secondFindingArray[secondFindingArray.length - 1];

  //if it's a number
  if (!isNaN(secondCount)) {
    let time = '';
    let year;
    let day;
    let hour;
    let min;
    let sec;

    //add y d h m s values
    switch (true) {
      case secondCount >= YEAR_SECOND:
        year = Math.floor(secondCount / YEAR_SECOND);
        secondCount %= YEAR_SECOND;
        day = Math.floor(secondCount / DAY_SECOND);
        secondCount %= DAY_SECOND;
        hour = Math.floor(secondCount / HOUR_SECOND);
        time = year + 'y ' + (day > 0 ? day + 'd ' : '') + (hour > 0 ? hour + 'h' : '');
        break;
      case secondCount >= DAY_SECOND:
        day = Math.floor(secondCount / DAY_SECOND);
        secondCount %= DAY_SECOND;
        hour = Math.floor(secondCount / HOUR_SECOND);
        time = day + 'd ' + (hour > 0 ? hour + 'h' : '');
        break;
      case secondCount >= HOUR_SECOND:
        hour = Math.floor(secondCount / HOUR_SECOND);
        secondCount %= HOUR_SECOND;
        min = Math.floor(secondCount / MINUTE_SECOND);
        time = hour + 'h ' + (min > 0 ? min + 'm' : '');
        break;
      case secondCount >= MINUTE_SECOND:
        min = Math.floor(secondCount / MINUTE_SECOND);
        sec = secondCount %= MINUTE_SECOND;
        time = min + 'm ' + (sec > 0 ? sec + 's' : '');
        break;
      default:
        time = secondCount + 's';
    }
    second.innerHTML = time;
  }
}

export function addFormatsToPage() {
  addCommasToAllNumbers();
  formatAllDateTimes();
  allSecondsToHHMMSS();
  addAllPercents();
  SacaStatsEventUtil.dispatchDocumentCustomEvent(new PageFormattedEvent());

  function addCommasToAllNumbers() {
    //get every element with the number class and add proper commas
    let numbers = document.querySelectorAll('.number');
    numbers.forEach(addCommasToNumber);
  }

  function formatAllDateTimes() {
    let dateTimes = document.querySelectorAll('.date-time');
    dateTimes.forEach(formatDateTime);
  }

  function addAllPercents() {
    //get every element with the percentage class and adds a '%' at the end
    let percents = document.querySelectorAll('.percentage');
    percents.forEach(addPercent);
  }

  function allSecondsToHHMMSS() {
    //get every element with the seconds-to-readable class and convert the string
    let seconds = document.querySelectorAll('.seconds-to-readable');
    seconds.forEach(secondsToHHMMSS);
  }
}

export function addAnimationToProgressBars() {
  let progressBars = document.querySelectorAll('.progress-bar');
  progressBars.forEach(function (progressBar, index) {
    var finishedWidth = progressBar.getAttribute('aria-valuenow');
    if (progressBar.id.indexOf('weapon') <= -1) {
      setTimeout(animateProgressBar, index * 500);
    } else {
      animateProgressBar();
    }
    function animateProgressBar() {
      let progressElement = $('#' + progressBar.id);
      if (progressElement.width() == 0 && !progressElement.is(':animated')) {
        progressElement.animate({ width: '' + finishedWidth + '%' }, 300);
      }
    }
  });
}

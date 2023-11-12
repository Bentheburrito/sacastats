import { LoadingScreenRemovedEvent } from './events/general-events.js';
import { SacaStatsEventUtil } from './events/sacastats-event-util.js';

export let isLoadingScreenUp = true;
export let isLoadingScreenLocked = false;

export function remove() {
  if (!isLoadingScreenLocked) {
    let loadingScreen = document.getElementById('loading-screen') as HTMLElement;
    //fade the loading screen out
    loadingScreen.classList.remove('show-loading-screen');
    loadingScreen.classList.add('hide-loading-screen');
    SacaStatsEventUtil.dispatchDocumentCustomEvent(new LoadingScreenRemovedEvent());

    setTimeout(function () {
      isLoadingScreenUp = false;
    }, 200);
  }
}

export function show() {
  let loadingScreen = document.getElementById('loading-screen') as HTMLElement;
  //fade in the loading screen
  loadingScreen.classList.remove('hide-loading-screen');
  loadingScreen.classList.add('show-loading-screen');
  setTimeout(function () {
    isLoadingScreenUp = true;
  }, 400);
}

export function waitForCloseThenRunFunction(functionToRun: Function) {
  if (isLoadingScreenUp === true) {
    window.setTimeout(() => waitForCloseThenRunFunction(functionToRun), 10);
  } else {
    functionToRun();
  }
}

export function waitForOpenThenRunFunction(functionToRun: Function) {
  if (isLoadingScreenUp === false) {
    window.setTimeout(() => waitForOpenThenRunFunction(functionToRun), 10);
  } else {
    functionToRun();
  }
}

function handleAnchorClickEvent(event: Event) {
  let target = event.target as HTMLAnchorElement;
  if (target.classList.contains('nav-link')) {
    event.preventDefault();
    let url = target.href;
    show();
    window.location.href = url;
  }
}

export function addLoadingScreenToAnchorLinkEvents() {
  $('a').on('click', handleAnchorClickEvent);
}

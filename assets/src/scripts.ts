import { setupFlexTables, setFlexTableVisibilities } from './flex_bootstrap_table/flex-bootstrap-table.js';
import { addFormatsToPage, addAnimationToProgressBars } from './formats.js';
import * as loadingScreen from './loading-screen.js';
import { addScrollToTop } from './scroll-to-top.js';
import { addNavbarEventListeners } from './navbar-events.js';

function addEventListeners() {
  setWindowResizeEvents();
}

function setWindowResizeEvents() {
  window.onresize = function (_event) {
    setFlexTableVisibilities();
  };
}

function init() {
  addEventListeners();

  addNavbarEventListeners();

  addFormatsToPage();

  loadingScreen.addLoadingScreenToAnchorLinkEvents();

  setupFlexTables();

  addScrollToTop();

  loadingScreen.remove();

  loadingScreen.waitForCloseThenRunFunction(addAnimationToProgressBars);
}

init();

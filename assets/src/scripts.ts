import { addFormatsToPage, addAnimationToProgressBars } from './formats.js';
import { addScrollToTop } from './scroll-to-top.js';
import { addNavbarEventListeners } from './navbar-events.js';

function addEventListeners() {
  setWindowResizeEvents();
}

function setWindowResizeEvents() {}

function init() {
  addEventListeners();

  addNavbarEventListeners();

  addFormatsToPage();

  addScrollToTop();
}

init();

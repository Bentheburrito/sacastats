import { setupFlexTables, setFlexTableVisibilities } from "/js/flex-bootstrap-table.js";
import { addFormatsToPage, addAnimationToProgressBars } from "/js/formats.js";
import * as loadingScreen from "/js/loading-screen.js";
import { addScrollToTop } from "/js/scroll-to-top.js";
import { addNavbarEventListeners } from "/js/navbar-events.js";

export default function init() {
    addEventListeners();

    addNavbarEventListeners();

    addFormatsToPage();

    loadingScreen.addLoadingScreenToAnchorLinkEvents();

    setupFlexTables();

    addScrollToTop();

    loadingScreen.remove();

    loadingScreen.waitForCloseThenRunFunction(addAnimationToProgressBars);
}

function addEventListeners() {
    setWindowResizeEvents();
}

function setWindowResizeEvents() {
    window.onresize = function (event) {
        setFlexTableVisibilities();
    };
}

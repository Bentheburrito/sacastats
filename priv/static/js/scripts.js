var bottomNavbars;
var oldPadding;
var newPadding;
var isBottomTopNavbarShown;
var isBottomBottomNavbarShown;
var isLoadingScreenUp = true;
var isLoadingScreenLocked = false;
const preferedLanguage = navigator.language;

window.addEventListener('load', (event) => {
    initializeVariables();

    addEventListeners();

    addFormatsToPage();

    addEventHandlersToAnchorLinks();

    removeLoadingScreen();

    waitForLoadingScreenToCloseThenRunFunction(addAnimationToProgressBars);
});

function initializeVariables() {
    bottomNavbars = document.querySelectorAll(".bottom-navbar");
    oldPadding = "pb-10";
    newPadding = "pb-26";
    isBottomTopNavbarShown = false;
    isBottomBottomNavbarShown = false;
}

function addEventListeners() {
    handleCollapsableNavbarEvents();

    handlePageClickEvents();

    handleNavLinkEvents();
}

function handleCollapsableNavbarEvents() {
    handleNavbarShowEvents();

    handleNavbarShownEvents();

    handleNavbarHideEvents();
}

function handleNavLinkEvents() {
    handlePageNavLinkEvents();
    handleSubPageNavLinkEvents();
}

function handlePageNavLinkEvents() {
    //for each header nav
    var links = document.querySelectorAll(".page-nav");
    links.forEach(link => {
        //if it's not the home page, activate the current page
        if (window.location.pathname != "/") {
            addOrRemoveActivePage(link);
        } else {
            //activate the home page only
            if (link.firstElementChild.innerHTML == "Home") {
                link.classList.add("active-page");
            } else {
                link.classList.remove("active-page");
            }
        }
    });
}

function handleSubPageNavLinkEvents() {
    //for each sub header nav
    var links = document.querySelectorAll(".subpage-nav");
    links.forEach(link => {
        //if there is a possible subpage, activate the current
        if (window.location.pathname != "/") {
            addOrRemoveActiveSubpage(link);
        }
    });
}

function addOrRemoveActivePage(link) {
    //initialize variables
    let url = window.location.pathname.split("/")[1].toLowerCase();
    let inner = link.firstElementChild.innerHTML;
    let lowerLink = inner.toLowerCase();

    //if it's the current page add the active-page class
    if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
        link.classList.add("active-page");

        //otherwise remove the active-page class
    } else {
        link.classList.remove("active-page");
    }
}

function addOrRemoveActiveSubpage(link) {
    //initialize variables
    let primaryPage = window.location.pathname.split("/")[1].toLowerCase();
    let index = (primaryPage == "charcter") ? 2 : 3;
    let url = window.location.pathname.split("/")[index].toLowerCase();
    let inner = link.firstElementChild.innerHTML;
    let lowerLink = inner.toLowerCase();

    //if it's the current subpage add the active-subpage class
    if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
        link.classList.add("active-subpage");

        //otherwise remove the active-subpage class
    } else {
        link.classList.remove("active-subpage");
    }
}

function handleNavbarShowEvents() {
    $('.navbar').on('show.bs.collapse', function (e) {
        //make sure the bottom nav is not already open
        if (e.currentTarget.classList.contains("navbar") && isBottomBottomNavbarShown && !e.currentTarget.classList.contains(newPadding) && e.currentTarget.firstElementChild == "collapse_bottom_target") {
            if (aNavbarIsAlreadyOpen(e) && !bottomNavbarAlreadyOpenIsTryingToBeOpened(e)) {
                showOneNavbarAtATime(e);

                //update variables
                if (!e.currentTarget.classList.contains(oldPadding) && !e.currentTarget.classList.contains(newPadding)) {
                    isBottomTopNavbarShown = false;
                    isBottomBottomNavbarShown = true;
                } else {
                    isBottomTopNavbarShown = true;
                    isBottomBottomNavbarShown = false;
                }
                //if the navbar that's already open is trying to be opened again
            } else {
                e.preventDefault();
                closeAllBottomNavbars(e);
            }
        } else {
            //make sure only 1 nav is open for bug fix
            if (aNavbarIsAlreadyOpen(e) && !bottomNavbarAlreadyOpenIsTryingToBeOpened(e)) {
                showOneNavbarAtATime(e);
            } else {
                showSpaceIfNeeded(e);
            }
        }
    });
}

function aNavbarIsAlreadyOpen(e) {
    return (isBottomTopNavbarShown || isBottomBottomNavbarShown) || (!isBottomTopNavbarShown && !isBottomBottomNavbarShown);
}

function bottomNavbarAlreadyOpenIsTryingToBeOpened(e) {
    var found = false;
    var children = e.currentTarget.children;
    for (var i = 0; i < children.length; i++) {
        var navChild = children[i];

        //if it's the bottom bottom navbar
        if (navChild.id == "collapse_bottom_target" && isBottomBottomNavbarShown) {
            found = (hasCollapseAndShowClasses(navChild.classList) || !isBottomBottomNavbarShown) ? false : true;

            //if it's the top bottom navbar
        } else if (!navChild.id == "collapse_bottom_target" && navChild.classList.contains("navbar-collapse") && isBottomTopNavbarShown) {
            found = (hasCollapseAndShowClasses(navChild.classList) || !isBottomTopNavbarShown) ? false : true;
        }
    }
    return found;
}

function hasCollapseAndShowClasses(classListToTest) {
    if (classListToTest.contains("collapse") && classListToTest.contains("show")) {
        return true;
    } else {
        return false;
    }
}

function showOneNavbarAtATime(e) {
    closeAllBottomNavbars(e);
    //if user is trying to open the bottom bottom nav
    if (!e.currentTarget.classList.contains(oldPadding) && !e.currentTarget.classList.contains(newPadding)) {
        for (let j = 0; j < bottomNavbars.length; j++) {
            //if it's the top bottom nav and it has the default padding, remove it and add new
            if (bottomNavbars[j].id != "collapse_bottom_target") {
                if (bottomNavbars[j].parentElement.classList.contains(oldPadding)) {
                    bottomNavbars[j].parentElement.classList.remove(oldPadding);
                    bottomNavbars[j].parentElement.classList.add(newPadding);
                    isBottomBottomNavbarShown = true;
                }
            }
        }

        //if user is trying to open the bottom top nav
    } else {
        for (let j = 0; j < bottomNavbars.length; j++) {
            if (bottomNavbars[j].id == "collapse_bottom_target") {
                if (e.currentTarget.classList.contains(newPadding)) {
                    e.currentTarget.classList.remove(newPadding);
                    e.currentTarget.classList.add(oldPadding);
                    isBottomTopNavbarShown = true;
                }
            }
        }
    }
}

function handleNavbarShownEvents() {
    $('.navbar').on('shown.bs.collapse', function (e) {
        makeSureClassesAreCorrectAfterShown(e);
    });
}

function makeSureClassesAreCorrectAfterShown(e) {
    var children = e.currentTarget.children;
    for (var i = 0; i < children.length; i++) {
        var navChild = children[i];
        if (navChild.classList.contains("collapsed")) {
            navChild.classList.remove("collapsed");
        }
        if (navChild.classList.contains("collapse") && !navChild.classList.contains("show")) {
            navChild.classList.add("show");
        }
    }
}

function showSpaceIfNeeded(e) {
    if (e.currentTarget.firstElementChild.id == "collapse_bottom_target") {
        for (let j = 0; j < bottomNavbars.length; j++) {
            if (bottomNavbars[j].id != "collapse_bottom_target") {
                if (bottomNavbars[j].parentElement.classList.contains(oldPadding)) {
                    bottomNavbars[j].parentElement.classList.remove(oldPadding);
                    bottomNavbars[j].parentElement.classList.add(newPadding);
                }
            }
        }
    }
}

function handleNavbarHideEvents() {
    $('.navbar').on('hide.bs.collapse', function (e) {
        hideSpaceIfNotNeeded(e);

        //update variables
        if (!e.currentTarget.classList.contains(oldPadding) && !e.currentTarget.classList.contains(newPadding)) {
            isBottomBottomNavbarShown = false;
        } else {
            isBottomTopNavbarShown = false;
        }
    });
}

function hideSpaceIfNotNeeded(e) {
    for (let j = 0; j < bottomNavbars.length; j++) {
        if (bottomNavbars[j].id != "collapse_bottom_target") {
            if (bottomNavbars[j].parentElement.classList.contains(newPadding)) {
                bottomNavbars[j].parentElement.classList.remove(newPadding);
                bottomNavbars[j].parentElement.classList.add(oldPadding);
            }
        }
    }
}

function handlePageClickEvents() {
    $('html').on('click', function (e) {
        hideOverlappingContent(e);
    });
}

function hideOverlappingContent(e) {
    if (!clickIsInFooter(e)) {
        closeAllBottomNavbars(e)
    }
}

function closeAllBottomNavbars(e) {
    for (let i = 0; i < bottomNavbars.length; i++) {
        bottomNavbars[i].classList.remove("show");
        var bottomNavbarSiblings = document.getElementById(bottomNavbars[i].id).parentElement.children;
        for (let j = 0; j < bottomNavbarSiblings.length; j++) {
            if (bottomNavbarSiblings[j].classList.contains("navbar-toggler") && !bottomNavbarSiblings[j].classList.contains("collapsed")) {
                bottomNavbarSiblings[j].classList.add("collapsed");
            }

        }
    }

    //update variables
    isBottomBottomNavbarShown = false;
    isBottomTopNavbarShown = false;

    hideSpaceIfNotNeeded(e);
}

function clickIsInFooter(e) {
    let footers = document.querySelectorAll("footer");
    var found = false;

    footers.forEach(footer => {
        if (footer.contains(e.target) || footer == e.target) {
            found = true;
        }
    });

    return found;
}

function addEventHandlersToAnchorLinks() {
    $('a').on('click', function (e) {
        e.preventDefault();
        let url = this.href;
        showLoadingScreen();
        window.location.href = url;
    })
}

function addFormatsToPage() {
    addCommasToNumbers();
    formatDateTimes();
}

function addCommasToNumbers() {
    //get every element with the number class and add proper commas
    let numbers = document.querySelectorAll(".number");
    numbers.forEach(number => {
        number.innerHTML = number.innerHTML.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    });
}

function formatDateTimes() {
    let dateTimes = document.querySelectorAll(".date-time");
    dateTimes.forEach(dateTime => {
        let dateTimeString = dateTime.innerHTML;
        let date = dateTimeString.split(" ")[0];
        let time = dateTimeString.split(" ")[1];
        let dateTimeObject = new Date(getLocalDateStringWithTimeFromStrings(date, time));
        const longFormatter = new Intl.DateTimeFormat(preferedLanguage, {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
        });

        dateTime.innerHTML = longFormatter.format(dateTimeObject) + " @ " + dateTimeObject.toLocaleTimeString();
    });
}

function getLocalDateStringWithTimeFromStrings(date, time) {
    let dateArr = date.split("-");
    let timeArr = time.split(":");
    return new Date(Date.UTC(dateArr[0], dateArr[1] - 1, dateArr[2], timeArr[0], timeArr[1], timeArr[2].split(".")[0])).toLocaleString(preferedLanguage, { timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone });
}

function removeLoadingScreen() {
    if (!isLoadingScreenLocked) {
        let loadingScreen = document.getElementById("loading-screen");
        //fade the loading screen out
        loadingScreen.classList.remove("show-loading-screen");
        loadingScreen.classList.add("hide-loading-screen");
        setTimeout(function () {
            isLoadingScreenUp = false;
        }, 200);
    }
}

function showLoadingScreen() {
    let loadingScreen = document.getElementById("loading-screen");
    //fade in the loading screen
    loadingScreen.classList.remove("hide-loading-screen");
    loadingScreen.classList.add("show-loading-screen");
    setTimeout(function () {
        isLoadingScreenUp = true;
    }, 400);
}

function addAnimationToProgressBars() {
    let progressBars = document.querySelectorAll(".progress-bar");
    progressBars.forEach(async progressBar => {
        var finishedWidth = progressBar.getAttribute("aria-valuenow");
        var i = 0;
        var id = setInterval(frame, 10);
        async function frame() {
            if (i > finishedWidth) {
                clearInterval(id);
                i = 0;
            } else {
                progressBar.style.width = i + "%";
            }
            i++;
        }
    });
}

function waitForLoadingScreenToCloseThenRunFunction(functionToRun) {
    if (isLoadingScreenUp === true) {
        window.setTimeout(() => waitForLoadingScreenToCloseThenRunFunction(functionToRun), 10);
    } else {
        functionToRun();
    }
}

function waitForLoadingScreenToOpenThenRunFunction(functionToRun) {
    if (isLoadingScreenUp === true) {
        window.setTimeout(() => waitForLoadingScreenToOpenThenRunFunction(functionToRun), 10);
    } else {
        functionToRun();
    }
}
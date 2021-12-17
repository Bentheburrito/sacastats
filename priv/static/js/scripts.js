var bottomNavbars;
var oldPadding;
var newPadding;
var isBottomTopNavbarShown;
var isBottomBottomNavbarShown;

window.addEventListener('load', (event) => {
    initializeVariables();

    addEventListeners();
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
    var links = document.querySelectorAll(".page-nav");
    links.forEach(link => {
        link.addEventListener('click', function () {
            addOrRemoveActivePage(link);
        });
        if (window.location.pathname != "/") {
            addOrRemoveActivePage(link);
        } else {
            if (link.firstElementChild.innerHTML == "Home") {
                link.classList.add("active-page");
            } else {
                link.classList.remove("active-page");
            }
        }
    });
}

function handleSubPageNavLinkEvents() {
    var links = document.querySelectorAll(".subpage-nav");
    links.forEach(link => {
        link.addEventListener('click', function () {
            addOrRemoveActiveSubpage(link);
        });
        if (window.location.pathname != "/") {
            addOrRemoveActiveSubpage(link);
        }
    });
}

function addOrRemoveActivePage(link) {
    let url = window.location.pathname.split("/")[1].toLowerCase();
    let inner = link.firstElementChild.innerHTML;
    let lowerLink = inner.toLowerCase();
    if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
        link.classList.add("active-page");
    } else {
        link.classList.remove("active-page");
    }
}

function addOrRemoveActiveSubpage(link) {
    let primaryPage = window.location.pathname.split("/")[1].toLowerCase();
    let index = (primaryPage == "charcter") ? 2 : 3;
    let url = window.location.pathname.split("/")[index].toLowerCase();
    let inner = link.firstElementChild.innerHTML;
    let lowerLink = inner.toLowerCase();
    if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
        link.classList.add("active-subpage");
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
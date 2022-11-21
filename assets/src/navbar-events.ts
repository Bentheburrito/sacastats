import { handleSubPageNavLinkEvents } from './subpages.js';

let bottomNavbars: NodeListOf<HTMLElement>;
let oldPadding: string;
let newPadding: string;
let isBottomTopNavbarShown: boolean;
let isBottomBottomNavbarShown: boolean;

export function addNavbarEventListeners() {
    initializeVariables();

    handleCollapsableNavbarEvents();

    handlePageClickEvents();

    handleNavLinkEvents();

    function initializeVariables() {
        bottomNavbars = document.querySelectorAll('.bottom-navbar');
        oldPadding = 'pb-7';
        newPadding = 'pb-27';
        isBottomTopNavbarShown = false;
        isBottomBottomNavbarShown = false;
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

    function handleNavbarShownEvents() {
        $('.navbar').on('shown.bs.collapse', makeSureClassesAreCorrectAfterShown);
    }

    function makeSureClassesAreCorrectAfterShown(event: Event) {
        var children = (event.currentTarget as HTMLElement).children;
        for (var i = 0; i < children.length; i++) {
            var navChild = children[i];
            if (navChild.classList.contains('collapsed')) {
                navChild.classList.remove('collapsed');
            }
            if (navChild.classList.contains('collapse') && !navChild.classList.contains('show')) {
                navChild.classList.add('show');
            }
        }
    }

    function onNavbarShow(event: Event) {
        //make sure the bottom nav is not already open
        let target = event.currentTarget as HTMLElement;
        if (
            target.classList.contains('navbar') &&
            isBottomBottomNavbarShown &&
            !target.classList.contains(newPadding) &&
            target.firstElementChild!.id == 'mobile-main-nav-menu'
        ) {
            if (aNavbarIsAlreadyOpen(event) && !bottomNavbarAlreadyOpenIsTryingToBeOpened(event)) {
                showOneNavbarAtATime(event);

                //update variables
                if (!target.classList.contains(oldPadding) && !target.classList.contains(newPadding)) {
                    isBottomTopNavbarShown = false;
                    isBottomBottomNavbarShown = true;
                } else {
                    isBottomTopNavbarShown = true;
                    isBottomBottomNavbarShown = false;
                }
                //if the navbar that's already open is trying to be opened again
            } else {
                event.preventDefault();
                closeAllBottomNavbars(event);
            }
        } else {
            //make sure only 1 nav is open for bug fix
            if (aNavbarIsAlreadyOpen(event) && !bottomNavbarAlreadyOpenIsTryingToBeOpened(event)) {
                showOneNavbarAtATime(event);
            } else {
                showSpaceIfNeeded(event);
            }
        }
    }

    function handleNavbarShowEvents() {
        $('.navbar').on('show.bs.collapse', onNavbarShow);
    }

    function aNavbarIsAlreadyOpen(_event: Event) {
        return (
            isBottomTopNavbarShown || isBottomBottomNavbarShown || (!isBottomTopNavbarShown && !isBottomBottomNavbarShown)
        );
    }

    function bottomNavbarAlreadyOpenIsTryingToBeOpened(event: Event) {
        var found = false;
        var children = (event.currentTarget as HTMLElement).children;
        for (var i = 0; i < children.length; i++) {
            var navChild = children[i];

            //if it's the bottom bottom navbar
            if (navChild.id == 'mobile-main-nav-menu' && isBottomBottomNavbarShown) {
                found = hasCollapseAndShowClasses(navChild.classList) || !isBottomBottomNavbarShown ? false : true;

                //if it's the top bottom navbar
            } else if (
                navChild.id !== 'mobile-main-nav-menu' &&
                navChild.classList.contains('navbar-collapse') &&
                isBottomTopNavbarShown
            ) {
                found = hasCollapseAndShowClasses(navChild.classList) || !isBottomTopNavbarShown ? false : true;
            }
        }
        return found;
    }

    function hasCollapseAndShowClasses(classListToTest: DOMTokenList) {
        return classListToTest.contains('collapse') && classListToTest.contains('show');
    }

    function handlePageNavLinkEvents() {
        //for each header nav
        var links = document.querySelectorAll('.page-nav') as NodeListOf<HTMLAnchorElement>;
        links.forEach((link) => {
            //if it's not the home page, activate the current page
            if (window.location.pathname != '/') {
                addOrRemoveActivePage(link);
            } else {
                //activate the home page only
                if (link.firstElementChild!.innerHTML == 'Home') {
                    link.classList.add('active-page');
                } else {
                    link.classList.remove('active-page');
                }
            }
        });
    }

    function addOrRemoveActivePage(link: HTMLAnchorElement) {
        //initialize variables
        let url = window.location.pathname.split('/')[1].toLowerCase();
        let inner = link.firstElementChild!.innerHTML;
        let lowerLink = inner.toLowerCase();

        //if it's the current page add the active-page class
        if (lowerLink.includes(url) || lowerLink == url || url.includes(lowerLink)) {
            link.classList.add('active-page');

            //otherwise remove the active-page class
        } else {
            link.classList.remove('active-page');
        }
    }

    function showOneNavbarAtATime(event: Event) {
        closeAllBottomNavbars(event);
        //if user is trying to open the bottom bottom nav
        let target = event.currentTarget as HTMLElement;
        if (!target.classList.contains(oldPadding) && !target.classList.contains(newPadding)) {
            for (let j = 0; j < bottomNavbars.length; j++) {
                //if it's the top bottom nav and it has the default padding, remove it and add new
                if (bottomNavbars[j].id != 'mobile-main-nav-menu') {
                    if (bottomNavbars[j].parentElement!.classList.contains(oldPadding)) {
                        bottomNavbars[j].parentElement!.classList.remove(oldPadding);
                        bottomNavbars[j].parentElement!.classList.add(newPadding);
                        isBottomBottomNavbarShown = true;
                    }
                }
            }

            //if user is trying to open the bottom top nav
        } else {
            for (let j = 0; j < bottomNavbars.length; j++) {
                if (bottomNavbars[j].id == 'mobile-main-nav-menu') {
                    if (target.classList.contains(newPadding)) {
                        target.classList.remove(newPadding);
                        target.classList.add(oldPadding);
                        isBottomTopNavbarShown = true;
                    }
                }
            }
        }
    }

    function showSpaceIfNeeded(event: Event) {
        if ((event.currentTarget as HTMLElement).firstElementChild!.id == 'mobile-main-nav-menu') {
            for (let j = 0; j < bottomNavbars.length; j++) {
                if (bottomNavbars[j].id != 'mobile-main-nav-menu') {
                    if (bottomNavbars[j].parentElement!.classList.contains(oldPadding)) {
                        bottomNavbars[j].parentElement!.classList.remove(oldPadding);
                        bottomNavbars[j].parentElement!.classList.add(newPadding);
                    }
                }
            }
        }
    }

    function onNavbarHide(event: Event) {
        hideSpaceIfNotNeeded(event);

        //update variables
        if (
            !(event.currentTarget as HTMLElement).classList.contains(oldPadding) &&
            !(event.currentTarget as HTMLElement).classList.contains(newPadding)
        ) {
            isBottomBottomNavbarShown = false;
        } else {
            isBottomTopNavbarShown = false;
        }
    }

    function handleNavbarHideEvents() {
        $('.navbar').on('hide.bs.collapse', onNavbarHide);
    }

    function hideSpaceIfNotNeeded(_event: Event) {
        for (let j = 0; j < bottomNavbars.length; j++) {
            if (bottomNavbars[j].id != 'mobile-main-nav-menu') {
                if (bottomNavbars[j].parentElement!.classList.contains(newPadding)) {
                    bottomNavbars[j].parentElement!.classList.remove(newPadding);
                    bottomNavbars[j].parentElement!.classList.add(oldPadding);
                }
            }
        }
    }

    function handlePageClickEvents() {
        $('html').on('click', hideOverlappingContent);
    }

    function hideOverlappingContent(event: Event) {
        if (!clickIsInFooter(event)) {
            closeAllBottomNavbars(event);
        }
    }

    function closeAllBottomNavbars(event: Event) {
        for (let i = 0; i < bottomNavbars.length; i++) {
            bottomNavbars[i].classList.remove('show');
            var bottomNavbarSiblings = (document.getElementById(bottomNavbars[i].id) as HTMLElement).parentElement!.children;
            for (let j = 0; j < bottomNavbarSiblings.length; j++) {
                if (
                    bottomNavbarSiblings[j].classList.contains('navbar-toggler') &&
                    !bottomNavbarSiblings[j].classList.contains('collapsed')
                ) {
                    bottomNavbarSiblings[j].classList.add('collapsed');
                }
            }
        }

        //update variables
        isBottomBottomNavbarShown = false;
        isBottomTopNavbarShown = false;

        hideSpaceIfNotNeeded(event);
    }

    function clickIsInFooter(event: Event) {
        let footers = document.querySelectorAll('footer') as NodeListOf<HTMLElement>;
        var found = false;
        let target = event.target as HTMLElement;

        footers.forEach((footer) => {
            if (footer.contains(target) || footer == target) {
                found = true;
            }
        });

        return found;
    }
}

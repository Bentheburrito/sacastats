import { show as showLoadingScreen } from "/js/loading-screen.js";

let contextMenuID = "#character-card-context-menu";
let characterName;

window.addEventListener('load', (event) => {
    searchCharacter();
    addCharacterCardClick();
    addContextMenuOptionEventHandlers();
    addDocumentClickEvents();
});

function searchCharacter() {
    let btn = document.getElementById("searchButton");
    let form = document.getElementById("characterSearchForm");
    let characterName;
    form.addEventListener('submit', function (event) {
        characterName = document.getElementById("character").value;
        swapURL(event, characterName, false);
    });
    btn.addEventListener("click", function (event) {
        characterName = document.getElementById("character").value;
        swapURL(event, characterName, false);
    });
}

function swapURL(event, characterName, newTab) {
    event.preventDefault();
    if (newTab) {
        const tab = window.open('about:blank');
        tab.location = document.URL + "/" + characterName;
    } else {
        showLoadingScreen();
        location.href = document.URL + "/" + characterName;
    }
}

function openURL(event, characterName) {
    event.preventDefault();
    var width = window.innerWidth;
    var height = window.innerHeight;
    window.open(document.URL + "/" + characterName,
        "_blank", "location=yes,width=" + width + ", height=" + height + ",scrollbars=yes,status=yes");
}

function characterCardLeftMouseClick(event) {
    characterCardClickEvent(event, false);
}

function characterCardMiddleMouseClick(event) {
    if (event.button === 1) {
        event.preventDefault();
        characterCardClickEvent(event, true);
    }
}

function characterCardMiddleMouseClickPreventDefault(event) {
    if (event.which === 2) {
        event.preventDefault();
    }
}

function characterCardClickEvent(event, isMiddleClick) {
    let card = $(event.target).closest(".character-status-card")[0];
    if (card != undefined && card.id != undefined) {
        let characterName = card.id.split("-")[0];
        let newTab = event.ctrlKey || isMiddleClick;
        swapURL(event, characterName, newTab);
    }
}

function characterCardRightMouseClick(e) {
    if (!isMobileScreen()) {
        //initialize special menu location
        let isFireFox = navigator.userAgent.indexOf("Firefox") != -1;
        let yAdj = (e.clientY + $(contextMenuID).height() > $(window).height()) ? (e.clientY - $(contextMenuID).height() - (isFireFox ? 0 : 5)) : e.clientY; //adjust height to show all of menu
        let xAdj = (e.clientX + $(contextMenuID).width() > $(window).width()) ? (e.clientX - $(contextMenuID).width() - (isFireFox ? 0 : 2)) : e.clientX; //adjust width to show all of menu
        var top = ((yAdj / $(window).height()) * 100) + "%";
        var left = ((xAdj / $(window).width()) * 100) + "%";

        //show special menu at the bottom right of the mouse
        $(contextMenuID).css({
            display: "block",
            position: "fixed",
            top: top,
            left: left
        }).addClass("show");

        //get card selected
        let card = $(e.target).closest(".character-status-card")[0];
        if (card != undefined && card.id != undefined) {
            //get character name from card and make it "selected"
            characterName = card.id.split("-")[0];
            card.classList.add("character-card-selected");
        }
        //if it's a mobile screen, show remove character option
    } else {

    }
    return false; //blocks default Webbrowser right click menu
}

function addCharacterCardClick() {
    document.querySelectorAll(".character-status-card").forEach(card => {
        //remove and add LEFT mouse click handler
        card.removeEventListener('click', characterCardLeftMouseClick);
        card.addEventListener('click', characterCardLeftMouseClick);

        //remove and add MIDDLE mouse click handler
        $(card).off('auxclick', characterCardMiddleMouseClick);
        $(card).on('auxclick', characterCardMiddleMouseClick);
        $(card).off('mousedown', characterCardMiddleMouseClickPreventDefault);
        $(card).on('mousedown', characterCardMiddleMouseClickPreventDefault);

        //remove and add RIGHT mouse click handler
        $(card).off('contextmenu', characterCardRightMouseClick);
        $(card).on('contextmenu', characterCardRightMouseClick);
    });
}

function addDocumentClickEvents() {
    $(document).on("mousedown", function () {
        hideContextMenu();
        document.querySelectorAll(".character-card-selected").forEach(card => {
            card.classList.remove("character-card-selected");
        });
    });
}

function hideContextMenu() {
    $(contextMenuID).removeClass("show").hide();
}

function addContextMenuOptionEventHandlers() {
    document.getElementById("character-card-open-stat-link-row").addEventListener("mousedown", function (event) {
        swapURL(event, characterName, false);
    });
    document.getElementById("character-card-open-stat-link-new-tab-row").addEventListener("mousedown", function (event) {
        swapURL(event, characterName, true);
    });
    document.getElementById("character-card-open-stat-link-new-window-row").addEventListener("mousedown", function (event) {
        openURL(event, characterName);
    });
    document.getElementById("remove-favorite-character-row").addEventListener("mousedown", function (event) {
        removeCharacterFromFavorites(characterName);
    });
}

function removeCharacterFromFavorites(characterName) {

}

function isMobileScreen() {
    return window.innerWidth <= 767;
}

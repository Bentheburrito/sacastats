import { show as showLoadingScreen } from "/js/loading-screen.js";

window.addEventListener('load', (event) => {
    searchCharacter();
    addCharacterCardClick();
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
        window.open(
            (document.URL + "/" + characterName), "_blank");
    } else {
        showLoadingScreen();
        location.href = document.URL + "/" + characterName;
    }
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

function characterCardRightMouseClick(event) {

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

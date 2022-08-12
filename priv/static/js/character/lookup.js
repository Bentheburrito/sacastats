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
        swapURL(event, characterName);
    });
    btn.addEventListener("click", function (event) {
        characterName = document.getElementById("character").value;
        swapURL(event, characterName);
    });
}

function swapURL(event, characterName) {
    showLoadingScreen();
    event.preventDefault();
    location.href = document.URL + "/" + characterName;
}

function addCharacterCardClick() {
    document.querySelectorAll(".character-status-card").forEach(card => {
        card.addEventListener('click', function (event) {
            let characterName = card.id.split("-")[0];
            swapURL(event, characterName);
        });
    });
}

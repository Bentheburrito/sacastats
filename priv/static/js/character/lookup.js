import { show as showLoadingScreen } from "/js/loading-screen.js";

window.addEventListener('load', (event) => {
    searchCharacter();
    addCharacterCardClick();
});

function searchCharacter() {
    let btn = document.getElementById("searchButton");
    let form = document.getElementById("characterSearchForm");
    let characterName = document.getElementById("character").value;
    form.addEventListener('submit', function (event) {
        swapURL(event, characterName);
    });
    btn.addEventListener("click", function (event) {
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

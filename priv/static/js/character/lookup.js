window.addEventListener('load', (event) => {
    searchCharacter();
});

function searchCharacter() {
    let btn = document.getElementById("searchButton");
    let form = document.getElementById("characterSearchForm");
    form.addEventListener('submit', function (event) {
        swapURL(event);
    });
    btn.addEventListener("click", function (event) {
        swapURL(event);
    });
}

function swapURL(event) {
    showLoadingScreen();
    event.preventDefault();
    let character = document.getElementById("character").value;
    location.href = document.URL + "/" + character;
}
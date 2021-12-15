window.addEventListener('load', (event) => {
    searchCharacter();
});

function searchCharacter() {
    let btn = document.getElementById("searchButton");
    let character = document.getElementById("character").value;

    btn.addEventListener("click", function (event) {
        event.preventDefault();
        location.href = document.URL + character;
    });
}
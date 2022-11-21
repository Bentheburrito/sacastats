import { show as showLoadingScreen } from '../loading-screen.js';

window.addEventListener('load', (_event) => {
    searchCharacter();
});

function searchCharacter() {
    let btn = document.getElementById('searchButton') as HTMLElement;
    let form = document.getElementById('characterSearchForm') as HTMLElement;
    form.addEventListener('submit', function (event) {
        swapURL(event);
    });
    btn.addEventListener('click', function (event) {
        swapURL(event);
    });
}

function swapURL(event: Event) {
    showLoadingScreen();
    event.preventDefault();
    let character = (document.getElementById('character') as HTMLInputElement).value;
    location.href = document.URL + '/' + character;
}

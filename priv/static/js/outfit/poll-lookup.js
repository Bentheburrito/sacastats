import { show as showLoadingScreen } from "/js/loading-screen.js";

window.addEventListener('load', () => {
    searchPollID();
    createNewPoll();
    handleHover();
    handleScreenWidthChange();
});

function handleScreenWidthChange() {
    swapToLightPlusOnMobile();
    window.onresize = swapToLightPlusOnMobile;
}

function swapToLightPlusOnMobile() {
    let img = document.getElementById("create-new-plus-img");
    let isDesktop = window.innerWidth >= 768;
    if (isDesktop) {
        img.src = "/images/outfit/plus-sign.png";
    } else {
        img.src = "/images/outfit/plus-sign-light.png";
    }
}

function handleHover() {
    let img = document.getElementById("create-new-plus-img");
    $("#create-new-poll-div").hover(function () {
        img.src = "/images/outfit/plus-sign-light.png";
    }, function () {
        img.src = "/images/outfit/plus-sign.png";
    });
}

function createNewPoll() {
    $("#create-new-poll-div").on('click', () => {
        showLoadingScreen();
        location.href = document.URL + "/create";
    });
}

function searchPollID() {
    let btn = document.getElementById("poll-search-button");
    let form = document.getElementById("pollSearchForm");
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
    let pollID = document.getElementById("poll-search-input").value;
    location.href = document.URL + "/" + pollID;
}

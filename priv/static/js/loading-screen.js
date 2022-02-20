export let isLoadingScreenUp = true;
export let isLoadingScreenLocked = false;

export function remove() {
    if (!isLoadingScreenLocked) {
        let loadingScreen = document.getElementById("loading-screen");
        //fade the loading screen out
        loadingScreen.classList.remove("show-loading-screen");
        loadingScreen.classList.add("hide-loading-screen");
        setTimeout(function () {
            isLoadingScreenUp = false;
        }, 200);
    }
}

export function show() {
    let loadingScreen = document.getElementById("loading-screen");
    //fade in the loading screen
    loadingScreen.classList.remove("hide-loading-screen");
    loadingScreen.classList.add("show-loading-screen");
    setTimeout(function () {
        isLoadingScreenUp = true;
    }, 400);
}

export function waitForCloseThenRunFunction(functionToRun) {
    if (isLoadingScreenUp === true) {
        window.setTimeout(() => waitForCloseThenRunFunction(functionToRun), 10);
    } else {
        functionToRun();
    }
}

export function waitForOpenThenRunFunction(functionToRun) {
    if (isLoadingScreenUp === false) {
        window.setTimeout(() => waitForOpenThenRunFunction(functionToRun), 10);
    } else {
        functionToRun();
    }
}

export function addLoadingScreenToAnchorLinkEvents() {
    $('a').on('click', function (e) {
        if (e.target.classList.contains("nav-link")) {
            e.preventDefault();
            let url = this.href;
            show();
            window.location.href = url;
        }
    })
}

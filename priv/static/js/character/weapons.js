let sortedKills;
let unsortedKills;
export let nextAuraxElementID

function initializeSortedWeaponKillCount(kills) {
    kills = getTrimmedKillNumbers(kills);
    sortedKills = new Map([...kills.entries()].sort((a, b) => b[1] - a[1]));
    nextAuraxElementID = [...sortedKills.keys()][0];
}

function initializeButtonEvent() {
    document.getElementById("nextAurax").addEventListener('click', function () {
        $('html, body').animate({
            scrollTop: $("#" + nextAuraxElementID).offset().top - 300 //- 254 to be at top
        }, 500);
        setTimeout(function () {
            flashElement(nextAuraxElementID);
        }, 500);
    });
}

function getTrimmedKillNumbers(kills) {
    let killNumbers = new Map();
    for (const [key, value] of kills.entries()) {
        if (value < 1160) {
            killNumbers.set(key, value);
        }
    }
    return killNumbers;
}

function flashElement(elementId) {
    let flashInterval = setInterval(function () {
        $("#" + elementId).toggleClass("flash-border");
    }, 250);
    setTimeout(function () {
        window.clearInterval(flashInterval);
        $("#" + elementId).removeClass("flash-border");
    }, 1000);
}

export default function init(kills) {
    unsortedKills = kills;
    initializeSortedWeaponKillCount(kills);
    initializeButtonEvent();
}

let sortedKills;
let unsortedKills;
export let nextAuraxElementID;

function initializeSortedWeaponKillCount(kills) {
    kills = getTrimmedKillNumbers(kills);
    sortedKills = new Map([...kills.entries()].sort((a, b) => b[1] - a[1]));
    nextAuraxElementID = [...sortedKills.keys()][0];
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

export default function init(kills) {
    unsortedKills = kills;
    initializeSortedWeaponKillCount(kills);
}

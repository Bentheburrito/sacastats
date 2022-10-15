let sortedKills;
let unsortedKills;
export let nextAuraxElementID;

function initializeSortedWeaponKillCount() {
    let kills = getTrimmedKillNumbers(unsortedKills);
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

function getDefaultWeaponStats() {
    if (document.getElementById("weaponTable") != undefined) {
        let kills = new Map();
        $('#weaponTable').bootstrapTable('getData', false).forEach(weapon => {
            kills.set("weapon" + weapon.id + "Row", weapon.kills)
        });
        unsortedKills = kills;
    }
}

export default function init() {
    getDefaultWeaponStats();
    initializeSortedWeaponKillCount();
}

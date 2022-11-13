import * as flexBootstrapTableEvents from "/js/events/flex-bootstrap-table-events.js";

let sortedKills;
let unsortedKills;
const TABLE_ID = "#weaponTable";
export let nextAuraxElementID;

function setSortedWeaponKillCount(kills) {
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

function reInit(kills) {
    unsortedKills = kills;
    setSortedWeaponKillCount(kills);
}

function addCustomEventListeners() {
    $(TABLE_ID).on(flexBootstrapTableEvents.filteredEvent, function () {
        let kills = new Map();
        $(TABLE_ID).bootstrapTable('getData', false).forEach(weapon => {
            kills.set(TABLE_ID.substring(1) + weapon.id + "Row", weapon.kills)
        });
        reInit(kills);
    });
}

export default function init(kills) {
    reInit(kills);
    addCustomEventListeners();
}

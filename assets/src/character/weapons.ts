import * as flexBootstrapTableEvents from '../events/flex-bootstrap-table-events.js';
import { FilteredEvent } from '../events/flex-bootstrap-table-events.js';
import { SacaStatsEventUtil } from '../events/sacastats-event-util.js';
import { WeaponKillsMap } from '../models/character/weapon.js';

let sortedKills: WeaponKillsMap;
let unsortedKills: WeaponKillsMap;
const TABLE_ID = '#weaponTable';
export let nextAuraxElementID: string;

function setSortedWeaponKillCount(kills: WeaponKillsMap) {
  kills = getTrimmedKillNumbers(kills);
  sortedKills = new Map([...kills.entries()].sort((a, b) => (b[1] as any as number) - (a[1] as any as number)));
  nextAuraxElementID = [...sortedKills.keys()][0];
}

function getTrimmedKillNumbers(kills: WeaponKillsMap) {
  let killNumbers = new WeaponKillsMap();
  for (const [weaponRowId, killCount] of kills.entries()) {
    if ((killCount as any as number) < 1160) {
      killNumbers.set(weaponRowId, killCount);
    }
  }
  return killNumbers;
}

function reInit(kills: WeaponKillsMap) {
  unsortedKills = kills;
  setSortedWeaponKillCount(kills);
}

function addCustomEventListeners() {
  SacaStatsEventUtil.addCustomEventListener(document.getElementById(TABLE_ID.substring(1))!, new FilteredEvent(),
    function () {
      let kills = new WeaponKillsMap();
      $(TABLE_ID)
        .bootstrapTable('getData', false)
        .forEach((weapon: { id: string; kills: string }) => {
          kills.set(TABLE_ID.substring(1) + weapon.id + 'Row', weapon.kills);
        });
      reInit(kills);
    }
  );
}

export function init() {

  let kills = new WeaponKillsMap();
  $(TABLE_ID)
    .bootstrapTable('getData', false)
    .forEach((weapon: { id: string; kills: string }) => {
      kills.set(TABLE_ID.substring(1) + weapon.id + 'Row', weapon.kills);
    });
  reInit(kills);
  addCustomEventListeners();
}

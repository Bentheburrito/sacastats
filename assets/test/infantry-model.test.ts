import { describe, it, expect } from '@jest/globals';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename); //curent file's directory

const ASSETS_PATH = join(__dirname, '../../', '/priv/static');

import { InfantryModel } from '../src/models/planetside-model/infantry-model';

describe('Infantry Model', () => {

    document.body.innerHTML = '<figure id="characterModel"></figure>';
    const infantryModel = new InfantryModel("characterModel", "VS", 5, "Engineer");

    it('has loadModels property', () => {
        expect(infantryModel.hasOwnProperty('loadModels')).toBe(true);
    });

    it('defines loadModels()', () => {
        expect(typeof infantryModel.loadModels).toBe("function");
    });

    //test all (good and bad) possible model entries to make sure a model exists for them
    let aliasArray = ["VS", "NC", "TR", "NS", "NSO", "VANU"];
    let headIDArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
    let clazzArray = ['Infiltrator', 'Light Assault', 'Combat Medic', 'Engineer', 'Heavy Assault', 'MAX', "Engi"];

    for (let aliasIndex = 0; aliasIndex < aliasArray.length; aliasIndex++) {
        for (let headIDIndex = 0; headIDIndex < headIDArray.length; headIDIndex++) {
            for (let clazzIndex = 0; clazzIndex < clazzArray.length; clazzIndex++) {
                let alias = aliasArray[aliasIndex];
                let headID = headIDArray[headIDIndex];
                let clazz = clazzArray[clazzIndex];

                let interInfantryModel = new InfantryModel("characterModel", alias, headID, clazz);

                it(`has a weapon model exists for: alias: ${alias}; headID: ${headID}; clazz: ${clazz}`, () => {
                    let weapon = join(ASSETS_PATH, interInfantryModel.getWeaponFile());

                    //****  NS/ NSO MAXES DO NOT HAVE WEAPONS MODELS  ****/
                    if (fs.existsSync(weapon) || (clazz === "MAX" && (alias === "NSO" || alias === "NS"))) {
                        expect(true).toBe(true);
                    } else {
                        expect(weapon).toBe(true);  //if file doesn't exist, use file path to help with debugging
                    }
                });

                it(`has a base model exists for: alias: ${alias}; headID: ${headID}; clazz: ${clazz}`, () => {
                    let base = join(ASSETS_PATH, interInfantryModel.getBaseFile());
                    if (fs.existsSync(base)) {
                        expect(true).toBe(true);
                    } else {
                        expect(base).toBe(true);  //if file doesn't exist, use file path to help with debugging
                    }
                });

                it(`has an armor model exists for: alias: ${alias}; headID: ${headID}; clazz: ${clazz}`, () => {
                    let armor = join(ASSETS_PATH, interInfantryModel.getArmorFile());

                    //****  NS/ NSO MAXES DO NOT HAVE ARMOR MODELS  ****/
                    if (fs.existsSync(armor) || (clazz === "MAX" && (alias === "NSO" || alias === "NS"))) {
                        expect(true).toBe(true);
                    } else {
                        expect(armor).toBe(true);  //if file doesn't exist, use file path to help with debugging
                    }
                });

                it(`has a head model exists for: alias: ${alias}; headID: ${headID}; clazz: ${clazz}`, () => {
                    let head = join(ASSETS_PATH, interInfantryModel.getHeadFile());
                    if (fs.existsSync(head)) {
                        expect(true).toBe(true);
                    } else {
                        expect(head).toBe(true);  //if file doesn't exist, use file path to help with debugging
                    }
                });
            }
        }
    }


});

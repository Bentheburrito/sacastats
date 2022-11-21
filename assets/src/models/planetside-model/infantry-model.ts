import {
    MeshPhongMaterial,
    MeshLambertMaterial,
    MeshBasicMaterial,
    Vector3,
    LoadingManager,
    // @ts-ignore
} from 'https://cdn.skypack.dev/three@0.132.2';
// @ts-ignore
import { GLTF, GLTFLoader } from 'https://cdn.skypack.dev/three@0.132.2/examples/jsm/loaders/GLTFLoader.js';
import { PlanetsideModel, ModelType } from "./planetside-model.js";
import { CharacterSex } from "../character/character.js";

export class InfantryModel extends PlanetsideModel {
    constructor(containerID: string, factionAlias: string, headID: number, clazz: string) {
        super(containerID, ModelType.INFANTRY, false);

        //make sure the variables are non nulls
        let adjustedVars = this.getNonNullCharacterVariables(factionAlias, headID, clazz);
        factionAlias = adjustedVars[0] as string;
        headID = adjustedVars[1] as number;
        clazz = adjustedVars[2] as string;

        //set character variables and objects
        this.setCharacterVariables(factionAlias, headID, clazz);
        this.setGeneralPrefix();
        this.setModelBase();
        this.setCharacterArmor();
        this.setCharacterWeapon();

        //load and render model
        this.loadModels();
    }

    //initialize path variables
    private basePath = this.getModelPath();
    private armorPath = this.getModelPath();
    private weaponPath = this.getModelPath();
    private HEAD_PATH = this.getModelPath() + 'heads/';

    //initialize variables
    private characterFactionAlias!: string;
    private characterWeapon!: string;
    private characterArmor!: string;
    private characterHead!: string;
    private characterHeadID!: number;
    private characterSex!: CharacterSex;
    private characterClass!: string;
    private characterClassID!: number;
    private generalPrefix!: string;
    private modelBase!: string;
    private CHARACTER_CLASS_MAP = new Map([
        ['Infiltrator', 0],
        ['Light Assault', 1],
        ['Combat Medic', 2],
        ['Engineer', 3],
        ['Heavy Assault', 4],
        ['MAX', 5],
    ]);
    private CHARACTER_HEADID_TO_HEAD_MAP = new Map([
        [0, 'Head_' + CharacterSex.MALE + '_NSO'],
        [1, 'Head_' + CharacterSex.MALE + '_Caucasian'],
        [2, 'Head_' + CharacterSex.MALE + '_African'],
        [3, 'Head_' + CharacterSex.MALE + '_Asian'],
        [4, 'Head_' + CharacterSex.MALE + '_Hispanic'],
        [5, 'Head_' + CharacterSex.FEMALE + '_Caucasian'],
        [6, 'Head_' + CharacterSex.FEMALE + '_African'],
        [7, 'Head_' + CharacterSex.FEMALE + '_Asian'],
        [8, 'Head_' + CharacterSex.FEMALE + '_Hispanic'],
    ]);
    private CHARACTER_WEAPON_MAP = new Map([
        ['Infiltrator', 'Sniper'],
        ['Light Assault', 'Carbine'],
        ['Combat Medic', 'AssaultRifle'],
        ['Engineer', 'Carbine'],
        ['Heavy Assault', 'LMG'],
        ['MAX', 'MAX'],
    ]);

    private setCharacterVariables = (factionAlias: string, headID: number, characterClass: string) => {
        this.setCharacterFaction(factionAlias);
        this.setCharacterClassInfo(characterClass);
        this.setCharacterHead(headID);
        this.setCharacterSex(headID);
    }

    private setCharacterWeapon = () => {
        this.characterWeapon = this.characterFactionAlias + '_' + this.CHARACTER_WEAPON_MAP.get(this.characterClass) + '_Weapon';
    }

    private setCharacterArmor = () => {
        this.characterArmor = this.generalPrefix + this.characterClass.replaceAll(' ', '') + '_Armor';
    }

    private setModelBase = () => {
        this.modelBase =
            this.generalPrefix +
            (this.characterClassID == 0 && this.characterFactionAlias != 'NSO' ? 'Stealth_' : '') +
            (this.characterClassID == 5 ? 'MAX_' : '') +
            'Base';
    }

    private setCharacterHead = (headID: number) => {
        if (this.characterClassID == 5) {
            this.characterHead = 'Head_' + this.characterFactionAlias + '_MAX';
        } else if (this.characterFactionAlias != 'NSO') {
            this.characterHead = this.CHARACTER_HEADID_TO_HEAD_MAP.get(+headID)!;
        } else {
            this.characterHead = this.CHARACTER_HEADID_TO_HEAD_MAP.get(0)!;
        }
        this.characterHeadID = headID;
    }

    private getNonNullCharacterVariables = (factionAlias: string, headID: number, characterClass: string) => {
        if (factionAlias == '' || factionAlias == undefined) {
            factionAlias = 'VS';
        }
        if (headID == undefined) {
            headID = 1;
        }
        if (characterClass == '' || characterClass == undefined) {
            characterClass = 'Engineer';
        }

        return [factionAlias, headID, characterClass];
    }

    private setCharacterFaction = (factionAlias: string) => {
        if (factionAlias == 'NS') {
            factionAlias = 'NSO';
        }
        this.characterFactionAlias = factionAlias;
        this.basePath = this.basePath + factionAlias + '/base/';
        this.armorPath = this.armorPath + factionAlias + '/armor/';
        this.weaponPath = this.weaponPath + factionAlias + '/weapons/';
    }

    private setGeneralPrefix = () => {
        this.generalPrefix = this.characterFactionAlias + '_' + (this.characterClassID == 5 ? '' : this.characterSex + '_');
    }

    private setCharacterClassInfo = (clazz: string) => {
        this.characterClass = clazz;
        this.characterClassID = this.CHARACTER_CLASS_MAP.get(clazz)!;
    }

    private setCharacterSex = (headID: number) => {
        if (headID > 4) {
            this.characterSex = CharacterSex.FEMALE;
        } else {
            this.characterSex = CharacterSex.MALE;
        }
    }

    protected loadModels = () => {
        //initialize variables
        const manager = new LoadingManager();
        const loader = new GLTFLoader(manager);
        const modelPosition = new Vector3(0, 0, 0);

        //handle loading gltf models
        const onLoad = (gltf: GLTF, position: Vector3, reflective: boolean) => {
            const model = gltf.scene;
            model.traverse((mesh: THREE.Mesh) => {
                //make sure to only edit the mesh material of the model
                if (mesh.isMesh) {
                    if (mesh.material) {
                        //create a copy of the material
                        var prevMaterial = mesh.material as THREE.Material;

                        //if the model should be reflective
                        if (!reflective) {
                            //have the model recieve shadows and change the material to a non reflective one
                            mesh.receiveShadow = true;
                            mesh.material = new MeshLambertMaterial();
                        } else {
                            //have the model cast a shadow and change the material to a reflective one
                            mesh.castShadow = true;
                            mesh.material = new MeshPhongMaterial();
                        }

                        //update the material to use the new less resource intensive material
                        MeshBasicMaterial.prototype.copy.call(mesh.material, prevMaterial);
                    }
                }

                mesh.frustumCulled = false; //fixes random disapearing objects
            });

            //keep the model at the model position
            model.position.copy(position);

            //add the model to the scene
            this.getScene().add(model);
        };

        //add model pieces
        if (!(this.characterClassID == 5 && this.characterFactionAlias == 'NSO')) {
            loader.load(
                this.weaponPath + this.characterWeapon + this.getFileType(),
                (gltf: GLTF) => onLoad(gltf, modelPosition, true),
                () => { },
                () => { },
            );
        }

        loader.load(
            this.basePath + this.modelBase + this.getFileType(),
            (gltf: GLTF) => onLoad(gltf, modelPosition, false),
            () => { },
            () => { },
        );

        if (!(this.characterClassID == 5 && this.characterFactionAlias == 'NSO')) {
            loader.load(
                this.armorPath + this.characterArmor + this.getFileType(),
                (gltf: GLTF) => onLoad(gltf, modelPosition, true),
                () => { },
                () => { },
            );
        }

        loader.load(
            this.HEAD_PATH + this.characterHead + this.getFileType(),
            (gltf: GLTF) => onLoad(gltf, modelPosition, false),
            () => { },
            () => { },
        );

        //when all the pieces are loaded, update and render the canvas
        manager.onLoad = () => {
            this.createRenderer();
            this.update();
            this.render();
        };

        //scene.add(new CameraHelper(camera)); //shows light patterns
    }
}

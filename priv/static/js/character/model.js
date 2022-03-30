//import three js assets
import {
    Clock,
    DirectionalLight,
    PerspectiveCamera,
    MeshPhongMaterial,
    MeshLambertMaterial,
    MeshBasicMaterial,
    Scene,
    Vector3,
    //CameraHelper, //only used for debugging
    PCFSoftShadowMap,
    LoadingManager,
    WebGLRenderer,
} from "https://cdn.skypack.dev/three@0.132.2";
import { OrbitControls } from "https://cdn.skypack.dev/three@0.132.2/examples/jsm/controls/OrbitControls.js";
import { GLTFLoader } from "https://cdn.skypack.dev/three@0.132.2/examples/jsm/loaders/GLTFLoader.js";

//initialize three js variables
let container;
let camera;
let directionalLight;
let controls;
let renderer;
let scene;
let MODEL_PATH = "/js/assets/models/";
let highQuality = false; //true: constantly re-renders; false: only re-renders when camera angle changes

const mixers = [];
const clock = new Clock();

function createCamera() {
    //initialize camera
    camera = new PerspectiveCamera(
        20,
        container.clientWidth / container.clientHeight + .3,
        1,
        1000
    );
    camera.position.set(0, 2, 6);
}

function createControls() {
    //initialize controls
    controls = new OrbitControls(camera, container);
    controls.enableZoom = false;
    controls.enablePan = false;
    controls.target.y = .9;

    //make sure the camera can only move left and right
    controls.minPolarAngle = Math.PI / 2;
    controls.maxPolarAngle = Math.PI / 2;

    if (highQuality) {
        controls.enableDamping = true; //Goes with higher quality animation loop (continues the move action)
    } else {
        controls.addEventListener("change", render); //Re-render when character is moved
    }
}

function createLights() {
    //initialize a light for the camera
    directionalLight = new DirectionalLight(0xffffff, 1);

    directionalLight.castShadow = true;
    directionalLight.intensity = 5;

    directionalLight.shadow.mapSize.width = 1024;
    directionalLight.shadow.mapSize.height = 1024;

    directionalLight.shadow.camera.near = 1;
    directionalLight.shadow.camera.far = 1000;
    directionalLight.shadow.camera.fov = 30;

    //add the camera light to the scene
    scene.add(directionalLight);
}

function loadModels() {
    //initialize variables
    const manager = new LoadingManager();
    const loader = new GLTFLoader(manager);
    const modelPosition = new Vector3(0, 0, 0);

    //handle loading gltf models
    const onLoad = (gltf, position, reflective) => {
        const model = gltf.scene;
        model.traverse(n => {
            //make sure to only edit the mesh material of the model
            if (n.isMesh) {
                if (n.material) {
                    //create a copy of the material
                    var prevMaterial = n.material;

                    //if the model should be reflective
                    if (!reflective) {
                        //have the model recieve shadows and change the material to a non reflective one
                        n.receiveShadow = true;
                        n.material = new MeshLambertMaterial();
                    } else {
                        //have the model cast a shadow and change the material to a reflective one
                        n.castShadow = true;
                        n.material = new MeshPhongMaterial();
                    }

                    //update the material to use the new less resource intensive material
                    MeshBasicMaterial.prototype.copy.call(n.material, prevMaterial);
                }
            }

            n.frustumCulled = false; //fixes random disapearing objects
        });

        //keep the model at the model position
        model.position.copy(position);

        //add the model to the scene
        scene.add(model);
    };

    //add model pieces
    loader.load(
        MODEL_PATH + "VS_Sniper.glb",
        (gltf) => onLoad(gltf, modelPosition, true),
        null,
        null
    );

    loader.load(
        MODEL_PATH + "VS_Stealth_Base.glb",
        (gltf) => onLoad(gltf, modelPosition, false),
        null,
        null
    );

    loader.load(
        MODEL_PATH + "VS_Infil_Armor.glb",
        (gltf) => onLoad(gltf, modelPosition, true),
        null,
        null
    );

    loader.load(
        MODEL_PATH + "caucasianFemaleHead.glb",
        (gltf) => onLoad(gltf, modelPosition, false),
        null,
        null
    );

    //when all the pieces are loaded, update and render the canvas
    manager.onLoad = function () {
        update();
        render();
    };

    //scene.add(new CameraHelper(camera)); //shows light patterns
}

function createRenderer() {
    // create a WebGLRenderer and set its width and height
    renderer = new WebGLRenderer({
        antialias: true,
        alpha: true //transparent background
    });
    renderer.setSize(container.clientWidth + 230, container.clientHeight + 30, false); //give a bit more room on the height and width to allow for larger guns

    renderer.physicallyCorrectLights = true;
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.outputEncoding = 3001; //(sRGBEncoding) same as `renderer.gammaOutput = true;`
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = PCFSoftShadowMap;

    // add the automatically created <canvas> element to the page
    container.appendChild(renderer.domElement);
}

function update() {
    const delta = clock.getDelta();

    mixers.forEach((mixer) => {
        mixer.update(delta);
    });
    controls.update(delta);
}

function render() {
    updateLightPosition();
    renderer.render(scene, camera);
}

function updateLightPosition() {
    //make sure the light stays near the camera
    let position = JSON.parse(JSON.stringify(camera.position));
    position.x += 2;
    position.y += 2;
    directionalLight.position.copy(position);
}

function onWindowResize() {
    //maintain aspect ratio
    camera.aspect = container.clientWidth / container.clientHeight + .3;

    // update the camera's frustum
    camera.updateProjectionMatrix();

    //resize the canvas
    renderer.setSize(container.clientWidth + 230, container.clientHeight + 30);

    //re-render
    render();
}

export default function init(containerID) {
    //get the container div
    container = document.querySelector(containerID);

    //create a new scene
    scene = new Scene();

    //add needed objects to scene
    createCamera();
    createControls();
    createLights();
    loadModels();
    createRenderer();

    //if it's high quality, create an animation loop
    if (highQuality) {
        //higher quality, but really CPU expensive
        renderer.setAnimationLoop(() => {
            update();
            render();
        });
    }

    //handle when the window size changes
    window.addEventListener("resize", onWindowResize);
}

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
    CameraHelper,
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
    camera = new PerspectiveCamera(
        20,
        container.clientWidth / container.clientHeight + .3,
        1,
        1000
    );
    camera.position.set(0, 2, 6);
}

function createControls() {
    controls = new OrbitControls(camera, container);
    controls.enableZoom = false;
    controls.enablePan = false;
    controls.target.y = .9;
    controls.minPolarAngle = Math.PI / 2;
    controls.maxPolarAngle = Math.PI / 2;
    if (highQuality) {
        controls.enableDamping = true; //Goes with higher quality animation loop (continues the move action)
    } else {
        controls.addEventListener("change", render); //Re-render when character is moved
    }
}

function createLights() {
    directionalLight = new DirectionalLight(0xffffff, 1);
    updateLightPosition();

    directionalLight.castShadow = true;
    directionalLight.intensity = 5;

    directionalLight.shadow.mapSize.width = 1024;
    directionalLight.shadow.mapSize.height = 1024;

    directionalLight.shadow.camera.near = 1;
    directionalLight.shadow.camera.far = 1000;
    directionalLight.shadow.camera.fov = 30;

    scene.add(directionalLight);
}

function loadModels() {
    const manager = new LoadingManager();

    const onLoad = (gltf, position, reflective) => {
        const model = gltf.scene;
        model.traverse(n => {
            if (n.isMesh) {
                var prevMaterial = n.material;
                if (n.material) {
                    n.material.metalness = 0;
                    if (!reflective) {
                        n.material.roughness = 1;
                        n.receiveShadow = true;
                        n.material = new MeshLambertMaterial();
                    } else {
                        n.castShadow = true;
                        n.material = new MeshPhongMaterial();
                    }
                }

                MeshBasicMaterial.prototype.copy.call(n.material, prevMaterial);
            }

            n.frustumCulled = false; //fixes random disapearing objects
        });

        model.position.copy(position);

        scene.add(model);
    };

    const loader = new GLTFLoader(manager);

    const modelPosition = new Vector3(0, 0, 0);

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
    renderer.setSize(container.clientWidth + 230, container.clientHeight + 30, false);

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
    let position = JSON.parse(JSON.stringify(camera.position));
    position.x += 2;
    position.y += 2;
    directionalLight.position.copy(position);
}

function onWindowResize() {
    camera.aspect = container.clientWidth / container.clientHeight + .3;

    // update the camera's frustum
    camera.updateProjectionMatrix();

    renderer.setSize(container.clientWidth + 230, container.clientHeight + 30);

    render();
}

export default function init(containerID) {
    container = document.querySelector(containerID);

    scene = new Scene();

    createCamera();
    createControls();
    createLights();
    loadModels();
    createRenderer();

    if (highQuality) {
        //higher quality, but really CPU expensive
        renderer.setAnimationLoop(() => {
            update();
            render();
        });
    }

    window.addEventListener("resize", onWindowResize);
}

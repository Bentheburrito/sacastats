//import three js assets
import {
    Clock,
    DirectionalLight,
    PerspectiveCamera,
    Scene,
    Vector3,
    CameraHelper,
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
    controls.enableDamping = true;
    controls.target.y = .9;
    controls.minPolarAngle = Math.PI / 2;
    controls.maxPolarAngle = Math.PI / 2;
}

function createLights() {
    const ambientLight = new DirectionalLight(0x222222, 28);//new HemisphereLight(0xddeeff, 0x0f0e0d, 8);
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
    const onLoad = (gltf, position, reflective) => {
        const model = gltf.scene;
        model.traverse(n => {
            if (n.isMesh) {
                if (n.material) {
                    n.material.metalness = 0;
                    if (!reflective) {
                        n.material.roughness = 1;
                        n.receiveShadow = true;
                    } else {
                        n.castShadow = true;
                    }
                }
            }

            n.frustumCulled = false; //fixes random disapearing objects
        });

        model.position.copy(position);

        scene.add(model);
    };

    const loader = new GLTFLoader();

    const modelPosition = new Vector3(0, 0, 0);

    loader.load(
        "/js/assets/models/VS_Sniper.glb",
        (gltf) => onLoad(gltf, modelPosition, true),
        null,
        null
    );

    loader.load(
        "/js/assets/models/VS_Stealth_Base.glb",
        (gltf) => onLoad(gltf, modelPosition, false),
        null,
        null
    );

    loader.load(
        "/js/assets/models/VS_Infil_Armor.glb",
        (gltf) => onLoad(gltf, modelPosition, true),
        null,
        null
    );

    loader.load(
        "/js/assets/models/caucasianFemaleHead.glb",
        (gltf) => onLoad(gltf, modelPosition, false),
        null,
        null
    );

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
    renderer.gammaOutput = true;
    renderer.shadowMap.enabled = true;

    // add the automatically created <canvas> element to the page
    container.appendChild(renderer.domElement);
}

function update() {
    const delta = clock.getDelta();

    mixers.forEach((mixer) => {
        mixer.update(delta);
    });
    controls.update(delta);
    updateLightPosition();
}

function render() {
    renderer.render(scene, camera);
}

function updateLightPosition() {
    let position = JSON.parse(JSON.stringify(camera.position));
    position.x += 2;
    position.y += 2;
    directionalLight.position.copy(position);
}

function onWindowResize() {
    camera.aspect = container.clientWidth / container.clientHeight;

    // update the camera's frustum
    camera.updateProjectionMatrix();

    renderer.setSize(container.clientWidth + 230, container.clientHeight + 30);
}

export default function init(containerID) {
    container = document.querySelector(containerID);

    scene = new Scene();

    createCamera();
    createControls();
    createLights();
    loadModels();
    createRenderer();

    renderer.setAnimationLoop(() => {
        update();
        render();
    });

    window.addEventListener("resize", onWindowResize);
}

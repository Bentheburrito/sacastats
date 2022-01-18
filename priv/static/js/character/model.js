//import three js assets
import {
    Clock,
    PointLight,
    PerspectiveCamera,
    Scene,
    Vector3,
    WebGLRenderer,
} from "https://cdn.skypack.dev/three@0.132.2";
import { OrbitControls } from "https://cdn.skypack.dev/three@0.132.2/examples/jsm/controls/OrbitControls.js";
import { GLTFLoader } from "https://cdn.skypack.dev/three@0.132.2/examples/jsm/loaders/GLTFLoader.js";

//initialize three js variables
let container;
let camera;
let controls;
let renderer;
let scene;

const mixers = [];
const clock = new Clock();

function createCamera() {
    camera = new PerspectiveCamera(
        5,//<-fov | other combo: 35
        container.clientWidth / container.clientHeight,
        1,
        1000
    );
    camera.position.set(-.4, 1.4, 21);//other combo: -.4, 1.4, 3.1 w/ 35 fov
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
    const mainLight = new PointLight(0xffffff, 20);
    mainLight.position.set(0, 2, 3);

    const mainLight2 = new PointLight(0xffffff, 20);
    mainLight2.position.set(0, 2, -3);

    const mainLight3 = new PointLight(0xffffff, 20);
    mainLight3.position.set(3, 2, 0);

    const mainLight4 = new PointLight(0xffffff, 20);
    mainLight4.position.set(-3, 2, 0);

    //add four lights surrounding the model
    scene.add(mainLight, mainLight2, mainLight3, mainLight4);
}

function loadModels() {
    const onLoad = (gltf, position) => {
        const model = gltf.scene;
        model.position.copy(position);

        scene.add(model);
    };

    const loader = new GLTFLoader();

    const modelPosition = new Vector3(0, 0, 0);

    loader.load(
        "/js/assets/models/hope.glb",
        (gltf) => onLoad(gltf, modelPosition),
        null,
        null
    );
}

function createRenderer() {
    // create a WebGLRenderer and set its width and height
    renderer = new WebGLRenderer({
        antialias: true,
        alpha: true
    });
    renderer.setSize(container.clientWidth + 30, container.clientHeight + 30);

    renderer.physicallyCorrectLights = true;
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.gammaOutput = true;
    renderer.gammaFactor = 1;

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
    renderer.render(scene, camera);
}

function onWindowResize() {
    camera.aspect = container.clientWidth / container.clientHeight;

    // update the camera's frustum
    camera.updateProjectionMatrix();

    renderer.setSize(container.clientWidth + 30, container.clientHeight + 30);
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
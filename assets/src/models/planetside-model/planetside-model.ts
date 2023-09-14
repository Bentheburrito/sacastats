import {
  Clock,
  DirectionalLight,
  PerspectiveCamera,
  Scene,
  //CameraHelper, //only used for debugging
  PCFSoftShadowMap,
  WebGLRenderer,
} from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

export enum ModelType {
  INFANTRY = 'infantry',
  VEHICLE = 'vehicle',
}

export class PlanetsideModel {
  constructor(containerID: string, modelType: ModelType, highQuality: boolean) {
    //get the container div
    this.container = document.getElementById(containerID)! as HTMLDivElement;

    //set model type path
    this.ASSETS_MODELS_PATH = this.ASSETS_MODELS_PATH + modelType + '/';

    //create a new scene
    this.scene = new Scene();

    //add needed objects to scene
    this.createCamera();
    this.createControls();
    this.createLights();

    //handle when the window size changes
    window.addEventListener('resize', this.onWindowResize);

    //set model quality
    this.highQuality = highQuality;
  }

  //initialize variables
  public static MODEL_CLASS = 'three-js-model';

  //initialize three js variables
  private container!: HTMLDivElement;
  private camera!: THREE.PerspectiveCamera;
  private directionalLight!: THREE.DirectionalLight;
  private controls!: OrbitControls;
  private renderer!: THREE.WebGLRenderer;
  private scene!: THREE.Scene;
  private MODEL_FILE_TYPE = '.glb';
  private ASSETS_MODELS_PATH = '/js/assets/models/';
  private highQuality; //true: constantly re-renders; false: only re-renders when camera angle changes

  private mixers: THREE.AnimationMixer[] = [];
  private clock = new Clock();

  protected getScene = () => {
    return this.scene;
  };

  protected getFileType = () => {
    return this.MODEL_FILE_TYPE;
  };

  protected getModelPath = () => {
    return this.ASSETS_MODELS_PATH;
  };

  private createCamera = () => {
    //initialize camera
    this.camera = new PerspectiveCamera(20, this.container.clientWidth / this.container.clientHeight + 0.45, 1, 1000);
    this.camera.position.set(0, 2, 6);
  };

  private createControls = () => {
    //initialize controls
    this.controls = new OrbitControls(this.camera, this.container);
    this.controls.enableZoom = false;
    this.controls.enablePan = false;
    this.controls.target.y = 0.9;

    //make sure the camera can only move left and right
    this.controls.minPolarAngle = Math.PI / 2;
    this.controls.maxPolarAngle = Math.PI / 2;

    if (this.highQuality) {
      this.controls.enableDamping = true; //Goes with higher quality animation loop (continues the move action)
    } else {
      this.controls.addEventListener('change', this.render); //Re-render when character is moved
    }
  };

  private createLights = () => {
    //initialize a light for the camera
    this.directionalLight = new DirectionalLight(0xffffff, 1);

    this.directionalLight.castShadow = true;
    this.directionalLight.intensity = 5;

    this.directionalLight.shadow.mapSize.width = 1024;
    this.directionalLight.shadow.mapSize.height = 1024;

    this.directionalLight.shadow.camera.near = 1;
    this.directionalLight.shadow.camera.far = 1000;
    (this.directionalLight.shadow.camera as any).fov = 30;

    //add the camera light to the scene
    this.scene.add(this.directionalLight);
  };

  protected loadModels = () => { };

  protected createRenderer = () => {
    // create a WebGLRenderer and set its width and height
    this.renderer = new WebGLRenderer({
      antialias: true,
      alpha: true, //transparent background
    });
    this.renderer.setSize(this.container.clientWidth + 330, this.container.clientHeight + 30, false); //give a bit more room on the height and width to allow for larger guns

    this.renderer.physicallyCorrectLights = true;
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.renderer.outputEncoding = 3001; //(sRGBEncoding) same as `renderer.gammaOutput = true;`
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = PCFSoftShadowMap;

    //if it's high quality, create an animation loop
    if (this.highQuality) {
      //higher quality, but really CPU expensive
      this.renderer.setAnimationLoop(() => {
        this.update();
        this.render();
      });
    }

    // add the automatically created <canvas> element to the page after fading out the loading spinner
    $(this.container).fadeOut(300);
    setTimeout(() => {
      $(this.container).children().not(this.renderer.domElement).replaceWith(this.renderer.domElement);
      $(this.container).fadeIn(1000);
    }, 250);
  };

  protected update = () => {
    const delta = this.clock.getDelta();

    this.mixers.forEach((mixer) => {
      mixer.update(delta);
    });
    (this.controls as any).update(delta);
  };

  protected render = () => {
    this.updateLightPosition();
    this.renderer.render(this.scene, this.camera);
  };

  private updateLightPosition = () => {
    //make sure the light stays near the camera
    let position = JSON.parse(JSON.stringify(this.camera.position));
    position.x += 2;
    position.y += 2;
    this.directionalLight.position.copy(position);
  };

  protected initializeCameraAndRenderSettings = () => {
    this.onWindowResize();
  }

  private onWindowResize = () => {
    //maintain aspect ratio
    this.camera.aspect = this.container.clientWidth / this.container.clientHeight + 0.45;

    // update the camera's frustum
    this.camera.updateProjectionMatrix();

    //resize the canvas
    this.renderer.setSize(this.container.clientWidth + 330, this.container.clientHeight + 30, false);

    //re-render
    this.render();
  };
}

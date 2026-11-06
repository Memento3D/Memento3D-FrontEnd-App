import { WebGLRenderer, Scene, PerspectiveCamera, Color, BoxGeometry,
  MeshNormalMaterial, Mesh, HemisphereLight, DirectionalLight, FileLoader,
  LoadingManager } from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { ModelLoads, disposeScenes } from './model_runtime.js';
import { ViewerInteraction } from './viewer_interaction.js';
import { ViewerPresentation, routeViewerCommand } from './viewer_presentation.js';
import { ViewerDiagnostics, routeDiagnosticsCommand } from './viewer_diagnostics.js';
import { CustomizationLoads } from './customization_runtime.js';

let renderer, scene, camera, observer, loads, placeholder, currentModel, homeView, interaction, presentation;
let stopped = false;
let customLoads, customMode = false;
const diagnostics = new ViewerDiagnostics({
  emit: event => window.ModelViewerBridge.postMessage(JSON.stringify(event)),
});
function render() {
  if (stopped) return;
  interaction?.update();
  renderer.render(scene, camera);
  if (loads?.loaded && diagnostics.requestId !== null) diagnostics.frame(performance.now());
}
function clearModel() {
  diagnostics.stop();
  interaction?.suspend();
  presentation?.clearModel();
  if (currentModel && !customMode) disposeScenes(currentModel.scenes);
  currentModel = null;
  homeView = null;
}
function dispose() {
  if (stopped) return;
  stopped = true;
  observer?.disconnect();
  document.removeEventListener('visibilitychange', visibilityChanged);
  renderer?.setAnimationLoop(null);
  interaction?.dispose();
  loads?.dispose();
  customLoads?.dispose();
  presentation?.dispose();
  if (placeholder) disposeScenes([placeholder]);
  placeholder = null;
  renderer?.dispose();
  renderer?.domElement.remove();
}
function visibilityChanged() {
  diagnostics.pause();
  if (!stopped) renderer.setAnimationLoop(document.hidden ? null : render);
}

async function load(url, progress) {
  let resolved;
  try { resolved = new URL(url); } catch { throw new Error('unsupportedUrl'); }
  if (resolved.protocol !== 'https:' && resolved.origin !== location.origin) throw new Error('unsupportedUrl');
  // FileLoader supplies real byte counts; parse is a separate completion step.
  let data;
  try {
    data = await new FileLoader().setResponseType('arraybuffer').loadAsync(resolved.href,
      event => progress(event.loaded, event.lengthComputable && event.total > 0 ? event.total : null));
  } catch { throw new Error('resourceLoadFailed'); }
  const manager = new LoadingManager();
  // Phase 2 supports self-contained GLBs; never follow arbitrary file/network references.
  manager.setURLModifier(resource => {
    if (resource.startsWith('blob:') || resource.startsWith('data:')) return resource;
    throw new Error('parseFailed');
  });
  try {
    if (data.byteLength < 12 || new DataView(data).getUint32(0, true) !== 0x46546c67) throw new Error();
    return await new GLTFLoader(manager).parseAsync(data, '');
  } catch { throw new Error('parseFailed'); }
}

try {
  renderer = new WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  scene = new Scene();
  presentation = new ViewerPresentation(scene);
  scene.background = new Color(0xfdf8ff);
  camera = new PerspectiveCamera(45, 1, 0.1, 100);
  camera.position.set(2.5, 1.8, 3.5);
  camera.lookAt(0, 0, 0);
  scene.add(new HemisphereLight(0xffffff, 0x444466, 2));
  const light = new DirectionalLight(0xffffff, 3);
  light.position.set(3, 5, 4);
  scene.add(light);
  placeholder = new Mesh(new BoxGeometry(1.4, 1.4, 1.4), new MeshNormalMaterial());
  scene.add(placeholder);
  document.body.appendChild(renderer.domElement);
  interaction = new ViewerInteraction(camera, renderer.domElement);
  const resize = () => {
    const width = Math.max(document.documentElement.clientWidth, 1);
    const height = Math.max(document.documentElement.clientHeight, 1);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height, false);
    if (currentModel) homeView = interaction.fit(currentModel.scene);
  };
  resize();
  loads = new ModelLoads({ load, clear: clearModel,
    emit: event => window.ModelViewerBridge.postMessage(JSON.stringify(event)),
    show: result => {
      homeView = interaction.fit(result.scene);
      scene.add(result.scene);
      presentation.setModel(result.scene);
      if (placeholder) { disposeScenes([placeholder]); placeholder = null; }
      try { render(); } catch {
        presentation.clearModel();
        interaction.suspend();
        throw new Error('renderFailed');
      }
      currentModel = result;
    },
  });
  customLoads = new CustomizationLoads({ load, clear: clearModel,
    emit: event => window.ModelViewerBridge.postMessage(JSON.stringify(event)),
    show: (result, first) => {
      if (first) { scene.add(result.scene);homeView=interaction.fit(result.scene); }
      presentation.setModel(result.scene);
      if (placeholder) { disposeScenes([placeholder]);placeholder=null; }
      currentModel=result;render();
    },
  });
  window.receiveModelViewerCommand = command => {
    if (command?.type === 'loadCustomization') {
      if (!customMode) { clearModel();customMode=true; }
      if (placeholder) { disposeScenes([placeholder]);placeholder=null; }
      void customLoads.receive(command);return;
    }
    if (command?.type === 'loadModel' && customMode) { customLoads.reset();customMode=false; }
    const active=customMode?customLoads:loads;
    if (routeDiagnosticsCommand(command, active, diagnostics, currentModel?.scene)) return;
    routeViewerCommand(command, active, presentation, interaction);
  };
  window.disposeModelViewer = dispose;
  observer = new ResizeObserver(resize);
  observer.observe(document.documentElement);
  document.addEventListener('visibilitychange', visibilityChanged);
  window.addEventListener('pagehide', dispose, { once: true });
  render();
  renderer.setAnimationLoop(render);
  window.ModelViewerBridge.postMessage(JSON.stringify({ type: 'viewerReady', version: 1 }));
} catch (error) {
  console.error('Viewer initialization failed', error);
  dispose();
}

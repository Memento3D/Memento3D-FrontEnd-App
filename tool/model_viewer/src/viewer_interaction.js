import { MOUSE, TOUCH, Quaternion, Box3, Vector3 } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { fitCamera } from './model_runtime.js';

/** One controls instance for the lifetime of one canvas, never per model. */
export class ViewerInteraction {
  constructor(camera, canvas) {
    this.camera = camera;
    this.controls = new OrbitControls(camera, canvas);
    this.disposed = false;
    this.home = null;
    this.resetAnimation = null;
    this.onInteractionStart = () => this.cancelReset();
    this.controls.addEventListener('start', this.onInteractionStart);
    const controls = this.controls;
    controls.enabled = false; // Activate only after a model is fitted.
    controls.enableRotate = controls.enableZoom = controls.enablePan = true;
    controls.enableDamping = true;
    controls.dampingFactor = 0.08;
    controls.autoRotate = false;
    controls.screenSpacePanning = true;
    controls.mouseButtons = { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN };
    controls.touches = { ONE: TOUCH.ROTATE, TWO: TOUCH.DOLLY_PAN };
    // OrbitControls owns canvas touch-action and context-menu prevention.
  }

  fit(root) {
    if (this.disposed) return null;
    this.cancelReset();
    this.root = root;
    const controls = this.controls;
    // Flush old damping deltas through the public API before replacing the pose.
    controls.enableDamping = false;
    controls.update();
    controls.enableDamping = true;
    const home = fitCamera(this.camera, root);
    const distance = home.position.distanceTo(home.target);
    controls.target.copy(home.target);
    // radius is half the world-space AABB diagonal. Keep the eye outside that
    // sphere at the centered target, while allowing a useful range at any scale.
    controls.minDistance = home.radius * 1.2;
    controls.maxDistance = Math.max(home.radius * 20, distance * 4);
    // Phase 2's tight clipping planes were for the fitted pose, not a zoom range.
    this.camera.near = home.radius / 1000;
    this.camera.far = controls.maxDistance + home.radius * 4;
    this.camera.updateProjectionMatrix();
    controls.enabled = true;
    controls.update();
    controls.saveState();
    this.home = { ...home, position: this.camera.position.clone(),
      target: controls.target.clone(), zoom: this.camera.zoom,
      near: this.camera.near, far: this.camera.far };
    return this.home;
  }

  focusFace() {
    if (this.disposed || !this.root || !this.controls.enabled) return;
    this.cancelReset();
    const head=this.root.getObjectByName('Personalized_Complete_Head');
    const bounds=new Box3().setFromObject(head ?? this.root);
    const size=bounds.getSize(new Vector3()),center=bounds.getCenter(new Vector3());
    if(bounds.isEmpty()||size.y<=0)return;
    if(!head){center.y=bounds.max.y-size.y*0.12;size.multiplyScalar(0.25);}
    const target=center;
    const distance=Math.max(size.y,size.x/this.camera.aspect)/(2*Math.tan(this.camera.fov*Math.PI/360))*1.35;
    this.controls.enableDamping=false;this.controls.update();
    this.controls.minDistance=size.y*0.06;
    this.controls.target.copy(target);
    this.camera.position.copy(target).add(new Vector3(0,0,distance));
    this.controls.update();this.controls.enableDamping=true;
  }

  resetView(now = performance.now()) {
    if (this.disposed || !this.home || !this.controls.enabled) return;
    const controls = this.controls;
    const position = this.camera.position.clone(), target = controls.target.clone();
    // Clear residual damping without moving the visible starting pose.
    controls.enableDamping = false;
    controls.update();
    this.camera.position.copy(position);
    controls.target.copy(target);
    controls.update();
    controls.enableDamping = true;
    const offset = position.clone().sub(target);
    const endOffset = this.home.position.clone().sub(this.home.target);
    this.resetAnimation = { start: now, duration: 450, position, target,
      direction: offset.clone().normalize(), distance: offset.length(),
      endDistance: endOffset.length(), zoom: this.camera.zoom,
      rotation: new Quaternion().setFromUnitVectors(offset.clone().normalize(), endOffset.normalize()) };
  }
  cancelReset() { this.resetAnimation = null; }
  suspend() { this.cancelReset(); this.home = null; this.controls.enabled = false; }
  update(now = performance.now()) {
    if (this.disposed || !this.controls.enabled) return;
    const animation = this.resetAnimation;
    if (animation) {
      const t = Math.max(0, Math.min(1, (now - animation.start) / animation.duration));
      const eased = t * t * (3 - 2 * t);
      this.controls.target.lerpVectors(animation.target, this.home.target, eased);
      // Interpolate direction + radius instead of crossing through the model
      // on a straight line when resetting from the opposite side.
      const rotation = new Quaternion().slerp(animation.rotation, eased);
      const distance = animation.distance + (animation.endDistance - animation.distance) * eased;
      this.camera.position.copy(animation.direction).applyQuaternion(rotation)
        .multiplyScalar(distance).add(this.controls.target);
      this.camera.zoom = animation.zoom + (this.home.zoom - animation.zoom) * eased;
      this.camera.updateProjectionMatrix();
      if (t === 1) {
        this.camera.position.copy(this.home.position);
        this.controls.target.copy(this.home.target);
        this.cancelReset();
      }
    }
    this.controls.update();
  }
  dispose() {
    if (this.disposed) return;
    this.disposed = true;
    this.cancelReset();
    this.home = null;
    this.controls.removeEventListener('start', this.onInteractionStart);
    this.controls.dispose();
  }
}

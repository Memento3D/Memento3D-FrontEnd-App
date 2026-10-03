import test from 'node:test';
import assert from 'node:assert/strict';
import { BoxGeometry, Mesh, MeshBasicMaterial, PerspectiveCamera, MOUSE, TOUCH, Vector3 } from 'three';
import { ViewerInteraction } from '../src/viewer_interaction.js';
import { disposeScenes } from '../src/model_runtime.js';

// A minimal event target for the actual pinned OrbitControls, not WebView proof.
class Canvas {
  constructor(root) { this.root = root ?? this; this.style = {}; this.listeners = new Map(); this.adds = 0; this.clientWidth = 800; this.clientHeight = 600; }
  getRootNode() { return this.root; }
  getBoundingClientRect() { return { left: 0, top: 0, width: 800, height: 600 }; }
  setPointerCapture() {}
  releasePointerCapture() {}
  addEventListener(type, fn) { if (!this.listeners.has(type)) this.listeners.set(type, new Set()); this.listeners.get(type).add(fn); this.adds++; }
  removeEventListener(type, fn) { this.listeners.get(type)?.delete(fn); }
  count() { return [...this.listeners.values()].reduce((sum, set) => sum + set.size, 0); }
  fire(type, data = {}) {
    const event = { type, pointerId: 1, pointerType: 'mouse', button: 0,
      clientX: 400, clientY: 300, pageX: 400, pageY: 300,
      preventDefault() { this.prevented = true; }, stopPropagation() {}, ...data };
    for (const fn of [...(this.listeners.get(type) ?? [])]) fn(event);
    return event;
  }
}
function setup(t) {
  const root = new Canvas(), canvas = new Canvas(root), camera = new PerspectiveCamera(45, 4 / 3);
  camera.position.set(2, 2, 4);
  const interaction = new ViewerInteraction(camera, canvas);
  const model = new Mesh(new BoxGeometry(2, 4, 3), new MeshBasicMaterial());
  model.position.set(50, -20, 100);
  t.after(() => { interaction.dispose(); disposeScenes([model]); });
  return { root, canvas, camera, interaction, model };
}
function settle(interaction) { for (let i = 0; i < 300; i++) interaction.update(); }

test('450ms reset interpolates camera and target, then reaches canonical fit', t => {
  const { camera, interaction, model } = setup(t);
  const home = interaction.fit(model);
  interaction.controls.target.add(new Vector3(2, 1, 0));
  camera.position.copy(interaction.controls.target).add(new Vector3(-8, 6, 10));
  interaction.update();
  const from = camera.position.clone(), target = interaction.controls.target.clone();
  interaction.resetView(1000);
  assert.ok(camera.position.distanceTo(from) < 1e-8);
  assert.ok(interaction.controls.target.distanceTo(target) < 1e-8);
  interaction.update(1225);
  assert.ok(camera.position.distanceTo(from) > .1);
  assert.ok(camera.position.distanceTo(home.position) > .1);
  assert.ok(interaction.controls.target.distanceTo(target) > .1);
  assert.ok(interaction.controls.target.distanceTo(home.target) > .1);
  interaction.update(1450);
  assert.ok(camera.position.distanceTo(home.position) < 1e-8);
  assert.ok(interaction.controls.target.distanceTo(home.target) < 1e-8);
  assert.equal(interaction.resetAnimation, null);
});

test('repeated reset replaces timeline; actual interaction start cancels it', t => {
  const { canvas, camera, interaction, model } = setup(t);
  interaction.fit(model);
  camera.position.add(new Vector3(3, 2, 4)); interaction.update();
  interaction.resetView(1000); interaction.update(1100);
  const first = interaction.resetAnimation, before = camera.position.clone();
  interaction.resetView(1100);
  assert.notEqual(interaction.resetAnimation, first);
  assert.ok(camera.position.distanceTo(before) < 1e-8);
  canvas.fire('pointerdown');
  assert.equal(interaction.resetAnimation, null);
  canvas.fire('pointermove', { clientX: 500 }); canvas.fire('pointerup');
  settle(interaction);
  assert.ok(camera.position.distanceTo(before) > .1);
});

test('loading/replacement and disposal invalidate the old reset pose and animation', t => {
  const { camera, interaction, model } = setup(t);
  interaction.resetView(0); assert.equal(interaction.resetAnimation, null);
  interaction.fit(model); camera.position.addScalar(2); interaction.resetView(0);
  interaction.suspend(); assert.equal(interaction.resetAnimation, null);
  interaction.resetView(100); assert.equal(interaction.resetAnimation, null);
  model.position.set(200, -50, 0);
  const home = interaction.fit(model);
  camera.position.addScalar(3); interaction.resetView(200); interaction.update(650);
  assert.ok(camera.position.distanceTo(home.position) < 1e-8);
  interaction.resetView(700); interaction.dispose(); interaction.update(1200);
  assert.equal(interaction.resetAnimation, null);
  assert.equal(interaction.home, null);
});

test('official mouse/touch mappings, damping, scoped context menu and cleanup', t => {
  const { root, canvas, interaction, model } = setup(t);
  const controls = interaction.controls;
  assert.deepEqual(controls.mouseButtons, { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN });
  assert.deepEqual(controls.touches, { ONE: TOUCH.ROTATE, TWO: TOUCH.DOLLY_PAN });
  assert.ok(controls.enableDamping && controls.enableRotate && controls.enableZoom && controls.enablePan);
  assert.equal(controls.autoRotate, false);
  assert.equal(canvas.style.touchAction, 'none');
  interaction.fit(model);
  assert.equal(canvas.fire('contextmenu').prevented, true);
  assert.equal(root.fire('contextmenu').prevented, undefined);
  interaction.dispose(); interaction.dispose();
  assert.equal(canvas.count(), 0); assert.equal(root.count(), 0);
  assert.equal(canvas.fire('contextmenu').prevented, undefined);
});

test('replacement reuses controls/listeners, targets bounds and scales limits', t => {
  const { canvas, root, camera, interaction, model } = setup(t);
  const original = interaction.controls, adds = canvas.adds + root.adds;
  const home = interaction.fit(model);
  assert.ok(original.target.distanceTo(model.position) < 1e-9);
  assert.equal(original.minDistance, home.radius * 1.2);
  assert.equal(original.maxDistance, Math.max(home.radius * 20, home.position.distanceTo(home.target) * 4));
  const min = original.minDistance, max = original.maxDistance;
  model.scale.setScalar(100);
  model.position.set(-500, 700, -200);
  interaction.suspend(); interaction.fit(model);
  assert.equal(interaction.controls, original);
  assert.equal(canvas.adds + root.adds, adds);
  assert.ok(original.target.distanceTo(model.position) < 1e-9);
  assert.ok(Math.abs(original.minDistance / min - 100) < 1e-9);
  assert.ok(Math.abs(original.maxDistance / max - 100) < 1e-9);
  assert.ok(camera.near < original.minDistance - home.radius * 100);
  assert.ok(camera.far > original.maxDistance + home.radius * 100);
  // Clamp both extremes through the actual OrbitControls update.
  camera.position.copy(original.target).add(new Vector3(0, 0, 1e9)); interaction.update();
  assert.ok(Math.abs(camera.position.distanceTo(original.target) - original.maxDistance) < 1e-6);
  camera.position.copy(original.target).add(new Vector3(0, 0, .00001)); interaction.update();
  assert.ok(Math.abs(camera.position.distanceTo(original.target) - original.minDistance) < 1e-6);
});

test('mouse rotate/wheel/pan affect camera, preserve model, and orbit panned target', t => {
  const { canvas, camera, interaction, model } = setup(t);
  interaction.fit(model);
  const position = model.position.clone(), scale = model.scale.clone(), quaternion = model.quaternion.clone();
  const eye = camera.position.clone(), target = interaction.controls.target.clone();
  canvas.fire('pointerdown'); canvas.fire('pointermove', { clientX: 500 }); canvas.fire('pointerup');
  settle(interaction);
  assert.ok(camera.position.distanceTo(eye) > .1);
  assert.ok(interaction.controls.target.distanceTo(target) < 1e-9);
  const distance = camera.position.distanceTo(target);
  canvas.fire('wheel', { deltaY: -100, deltaMode: 0 }); settle(interaction);
  assert.ok(camera.position.distanceTo(target) < distance);
  canvas.fire('pointerdown', { button: 2 });
  canvas.fire('pointermove', { clientX: 450, clientY: 330 }); canvas.fire('pointerup'); settle(interaction);
  const panned = interaction.controls.target.clone();
  assert.ok(panned.distanceTo(target) > .1);
  canvas.fire('pointerdown'); canvas.fire('pointermove', { clientX: 470 }); canvas.fire('pointerup'); settle(interaction);
  assert.ok(interaction.controls.target.distanceTo(panned) < 1e-8);
  assert.deepEqual(model.position, position); assert.deepEqual(model.scale, scale); assert.ok(model.quaternion.equals(quaternion));
  // A fresh model fit must not inherit a pending rotation/pan damping tail.
  canvas.fire('pointerdown'); canvas.fire('pointermove', { clientX: 490 }); canvas.fire('pointerup');
  const fitted = interaction.fit(model), fittedEye = camera.position.clone();
  settle(interaction);
  assert.ok(interaction.controls.target.distanceTo(fitted.target) < 1e-8);
  assert.ok(camera.position.distanceTo(fittedEye) < 1e-8);
});

test('synthetic two-touch input exercises pinch and parallel pan in OrbitControls', t => {
  const { canvas, camera, interaction, model } = setup(t);
  interaction.fit(model);
  const touch = (type, id, x, y) => canvas.fire(type, { pointerId: id, pointerType: 'touch', pageX: x, pageY: y, clientX: x, clientY: y });
  const before = camera.position.distanceTo(interaction.controls.target);
  touch('pointerdown', 1, 300, 300); touch('pointerdown', 2, 500, 300);
  touch('pointermove', 1, 250, 300); touch('pointermove', 2, 550, 300);
  settle(interaction);
  assert.ok(camera.position.distanceTo(interaction.controls.target) < before);
  const target = interaction.controls.target.clone();
  touch('pointermove', 1, 300, 340); touch('pointermove', 2, 600, 340);
  settle(interaction);
  assert.ok(interaction.controls.target.distanceTo(target) > .1);
  touch('pointerup', 2, 600, 340); touch('pointerup', 1, 300, 340);
});

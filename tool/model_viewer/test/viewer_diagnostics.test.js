import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { BufferGeometry, Float32BufferAttribute, Group, Mesh, MeshBasicMaterial, InstancedMesh } from 'three';
import { countSceneGeometry, ViewerDiagnostics, routeDiagnosticsCommand } from '../src/viewer_diagnostics.js';
import { disposeScenes } from '../src/model_runtime.js';

function mesh(indexed = true) {
  const geometry = new BufferGeometry();
  geometry.setAttribute('position', new Float32BufferAttribute(new Float32Array(indexed ? 12 : 18), 3));
  if (indexed) geometry.setIndex([0, 1, 2, 2, 3, 0]);
  return new Mesh(geometry, new MeshBasicMaterial());
}
test('indexed geometry counts indices/3 and position entries without mutation', t => {
  const root = mesh(); t.after(() => disposeScenes([root]));
  const index = root.geometry.index, positions = root.geometry.attributes.position;
  assert.deepEqual(countSceneGeometry(root), {meshCount: 1, triangleCount: 2, vertexCount: 4});
  assert.equal(root.geometry.index, index);
  assert.equal(root.geometry.attributes.position, positions);
  assert.deepEqual([...index.array], [0, 1, 2, 2, 3, 0]);
});
test('non-indexed triangles use position count/3', t => {
  const root = mesh(false); t.after(() => disposeScenes([root]));
  assert.deepEqual(countSceneGeometry(root), {meshCount: 1, triangleCount: 2, vertexCount: 6});
});
test('multiple meshes count shared geometry per instance; hidden subtrees are excluded', t => {
  const root = new Group(), a = mesh(), b = mesh(false), hidden = new Group();
  root.add(a, b, new Mesh(a.geometry, a.material));
  hidden.add(mesh()); hidden.visible = false; root.add(hidden);
  t.after(() => disposeScenes([root]));
  assert.deepEqual(countSceneGeometry(root), {meshCount: 3, triangleCount: 6, vertexCount: 14});
});
test('draw ranges and visible material groups intersect without double-counting full geometry', t => {
  const root = mesh(); const second = new MeshBasicMaterial();
  root.material = [root.material, second];
  root.geometry.addGroup(0, 3, 0); root.geometry.addGroup(3, 3, 1);
  t.after(() => disposeScenes([root]));
  second.visible = false;
  assert.equal(countSceneGeometry(root).triangleCount, 1);
  second.visible = true;
  root.geometry.setDrawRange(3, 3);
  assert.equal(countSceneGeometry(root).triangleCount, 1);
  root.geometry.setDrawRange(0, 5);
  assert.equal(countSceneGeometry(root).triangleCount, 1);
});
test('instanced meshes multiply topology and vertices by active instances', t => {
  const base = mesh(), root = new InstancedMesh(base.geometry, base.material, 10);
  root.count = 3;
  t.after(() => disposeScenes([root]));
  assert.deepEqual(countSceneGeometry(root), {meshCount: 1, triangleCount: 6, vertexCount: 12});
});

function session(t, reportIntervalMs) {
  const root = mesh(), events = [];
  const diagnostics = new ViewerDiagnostics({emit: event => events.push(event), reportIntervalMs});
  t.after(() => { diagnostics.stop(); disposeScenes([root]); });
  diagnostics.start(root, '1');
  return {root, events, diagnostics};
}
test('diagnostics require current loaded request and version; disable stops reports', t => {
  const {root, events, diagnostics} = session(t);
  diagnostics.stop(); events.length = 0;
  const loads = {loaded: false, active: '2', disposed: false};
  const command = {type: 'setDiagnostics', requestId: '2', version: 1, enabled: true};
  const send = value => routeDiagnosticsCommand(value, loads, diagnostics, root);
  assert.equal(send({type: 'loadModel'}), false);
  send(command); assert.equal(events.length, 0);
  loads.loaded = true;
  send({...command, requestId: '1'}); send({...command, version: 2});
  send({...command, enabled: 'true'}); assert.equal(events.length, 0);
  send(command); assert.equal(events[0].requestId, '2');
  send({...command, enabled: false}); diagnostics.frame(0); diagnostics.frame(1000);
  assert.equal(events.length, 1);
  loads.disposed = true; send(command); assert.equal(events.length, 1);
});
test('aggregation measures full windows, cumulative average/minimum and throttles bridge traffic', t => {
  const {events, diagnostics} = session(t, 10); // Clamped to at least one second.
  assert.equal(events.length, 1); assert.equal(events[0].type, 'modelStatistics');
  diagnostics.frame(0);
  for (let i = 1; i < 50; i++) diagnostics.frame(i * 20);
  assert.equal(events.length, 1);
  diagnostics.frame(1000);
  assert.deepEqual(events[1], {type: 'performanceSample', version: 1, requestId: '1',
    fps: 50, averageFps: 50, minimumFps: 50, frameCount: 50, elapsedMs: 1000,
    windowFrameCount: 50, windowElapsedMs: 1000});
  for (let i = 1; i <= 25; i++) diagnostics.frame(1000 + i * 40);
  assert.deepEqual(events[2], {type: 'performanceSample', version: 1, requestId: '1',
    fps: 25, averageFps: 37.5, minimumFps: 25, frameCount: 75, elapsedMs: 2000,
    windowFrameCount: 25, windowElapsedMs: 1000});
});
test('visibility pause excludes background gap and resets partial reporting window', t => {
  const {events, diagnostics} = session(t);
  diagnostics.frame(0);
  for (let i = 1; i <= 10; i++) diagnostics.frame(i * 20);
  diagnostics.pause(); diagnostics.frame(1000000);
  for (let i = 1; i <= 50; i++) diagnostics.frame(1000000 + i * 20);
  const sample = events.at(-1);
  assert.equal(sample.frameCount, 60);
  assert.equal(sample.elapsedMs, 1200);
  assert.equal(sample.windowElapsedMs, 1000);
  assert.equal(sample.averageFps, 50);
});
test('disabled/replaced instrumentation emits nothing stale and resets the session', t => {
  const {events, diagnostics, root} = session(t);
  diagnostics.frame(0); diagnostics.frame(1000);
  diagnostics.stop(); const count = events.length;
  diagnostics.frame(2000); assert.equal(events.length, count);
  diagnostics.start(root, '2'); diagnostics.frame(5000); diagnostics.frame(6000);
  const sample = events.at(-1);
  assert.equal(sample.requestId, '2');
  assert.equal(sample.frameCount, 1);
  assert.equal(sample.elapsedMs, 1000);
  assert.equal(sample.minimumFps, 1);
});
test('invalid timestamps do not poison aggregates; optional reporting failures are isolated', t => {
  const {diagnostics, events} = session(t);
  diagnostics.frame(NaN); diagnostics.frame(Infinity); diagnostics.frame(0);
  diagnostics.frame(0); diagnostics.frame(-100); diagnostics.frame(1000);
  assert.equal(events.at(-1).frameCount, 1);
  diagnostics.emit = () => { throw new Error('optional bridge failure'); };
  assert.doesNotThrow(() => diagnostics.frame(2000));
});
test('instrumentation owns no animation/timer scheduler; runtime samples only its existing loop', async t => {
  const originals = new Map(); let scheduled = 0;
  for (const key of ['requestAnimationFrame', 'setInterval', 'setTimeout']) {
    originals.set(key, Object.getOwnPropertyDescriptor(globalThis, key));
    globalThis[key] = () => { scheduled++; throw new Error('Unexpected second scheduler'); };
  }
  try {
    const {diagnostics, root} = session(t);
    diagnostics.frame(0); diagnostics.frame(1000); diagnostics.pause();
    diagnostics.start(root, '2'); diagnostics.frame(10000); diagnostics.frame(11000);
    diagnostics.stop(); assert.equal(scheduled, 0);
  } finally {
    for (const [key, descriptor] of originals) {
      if (descriptor) Object.defineProperty(globalThis, key, descriptor);
      else delete globalThis[key];
    }
  }
  const source = await readFile(new URL('../src/viewer.js', import.meta.url), 'utf8');
  assert.equal((source.match(/renderer\.setAnimationLoop\(render\)/g) || []).length, 1);
  assert.equal((source.match(/diagnostics\.frame\(/g) || []).length, 1);
  assert.doesNotMatch(source, /requestAnimationFrame\s*\(|setInterval\s*\(/);
});

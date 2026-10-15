import test from 'node:test';
import assert from 'node:assert/strict';
import { Scene, Mesh, BoxGeometry, MeshBasicMaterial, PerspectiveCamera, Texture, Vector3 } from 'three';
import { ModelLoads, disposeScenes, fitCamera } from '../src/model_runtime.js';

function model() { const scene = new Scene(); scene.add(new Mesh(new BoxGeometry(), new MeshBasicMaterial())); return { scene, scenes: [scene] }; }
test('fit handles off-origin models and portrait aspect; bounds stay in frustum', () => {
  for (const aspect of [.3, 1, 2]) {
    const result = model(); result.scene.position.set(500, -100, 40);
    const camera = new PerspectiveCamera(45, aspect);
    const home = fitCamera(camera, result.scene);
    camera.updateMatrixWorld();
    assert.deepEqual(home.target.toArray(), [500, -100, 40]);
    for (const x of [-.5, .5]) for (const y of [-.5, .5]) for (const z of [-.5, .5]) {
      const p = new Vector3(x + 500, y - 100, z + 40).project(camera);
      assert.ok(Math.abs(p.x) <= 1 && Math.abs(p.y) <= 1 && Math.abs(p.z) <= 1);
    }
    disposeScenes(result.scenes);
  }
  assert.throws(() => fitCamera(new PerspectiveCamera(), new Scene()), /invalidBounds/);
});
test('shared geometry/material/texture and bitmap are disposed once', () => {
  const result = model(), mesh = result.scene.children[0];
  const texture = new Texture(); let closed = 0;
  texture.source.data = { close() { closed++; } };
  mesh.material.map = texture;
  result.scene.add(new Mesh(mesh.geometry, mesh.material));
  let geometries = 0, materials = 0, textures = 0;
  mesh.geometry.addEventListener('dispose', () => geometries++);
  mesh.material.addEventListener('dispose', () => materials++);
  texture.addEventListener('dispose', () => textures++);
  disposeScenes(result.scenes);
  assert.deepEqual([geometries, materials, textures, closed], [1, 1, 1, 1]);
});
test('out-of-order completion and disposal clean stale models without emitting loaded', async () => {
  const pending = [], events = [], shown = [];
  const loads = new ModelLoads({ load: (url, progress) => new Promise(resolve => pending.push({ resolve, progress })),
    emit: event => events.push(event), clear() {}, show: value => shown.push(value) });
  const first = loads.receive({ type: 'loadModel', requestId: '1', modelUrl: 'a' });
  const second = loads.receive({ type: 'loadModel', requestId: '2', modelUrl: 'b' });
  pending[0].progress(1, 1);
  assert.equal(events.length, 0);
  const old = model(); let disposed = 0;
  old.scene.children[0].geometry.addEventListener('dispose', () => disposed++);
  pending[0].resolve(old); await first;
  assert.equal(disposed, 1);
  pending[1].progress(10, null);
  assert.equal(events[0].totalBytes, null);
  pending[1].resolve(model()); await second;
  assert.equal(shown.length, 1);
  assert.equal(events.at(-1).type, 'modelLoaded');
  const third = loads.receive({ type: 'loadModel', requestId: '3', modelUrl: 'c' });
  loads.dispose(); pending[2].resolve(model()); await third;
  assert.equal(shown.length, 1);
});
test('malformed command and failed load do not prevent a later valid request', async () => {
  const events = [];
  const loads = new ModelLoads({ load: async url => { if (url === 'bad') throw new Error('resourceLoadFailed'); return model(); },
    show: result => disposeScenes(result.scenes), clear() {}, emit: event => events.push(event) });
  await loads.receive(null);
  await loads.receive({ type: 'unknown', requestId: '0' });
  assert.equal(events.at(-1).code, 'invalidCommand');
  await loads.receive({ type: 'loadModel', requestId: '1', modelUrl: 'bad' });
  assert.equal(events.at(-1).code, 'resourceLoadFailed');
  await loads.receive({ type: 'loadModel', requestId: '2', modelUrl: 'good' });
  assert.equal(events.at(-1).type, 'modelLoaded');
});

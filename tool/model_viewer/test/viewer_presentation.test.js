import test from 'node:test';
import assert from 'node:assert/strict';
import { Scene, Group, Mesh, BoxGeometry, MeshStandardMaterial, Texture, GridHelper } from 'three';
import { ViewerPresentation, routeViewerCommand } from '../src/viewer_presentation.js';
import { disposeScenes } from '../src/model_runtime.js';

function model() {
  const root = new Group(), texture = new Texture(), normal = new Texture();
  const a = new MeshStandardMaterial({ map: texture, normalMap: normal, roughness: .37 });
  const b = new MeshStandardMaterial({ map: texture, wireframe: true, metalness: .62 });
  root.add(new Mesh(new BoxGeometry(2, 4, 6), [a, b]));
  root.add(new Mesh(new BoxGeometry(1, 1, 1), a));
  root.position.set(10, 20, -30);
  return { root, a, b, texture, normal };
}

test('wireframe round trips preserve arrays, shared materials, textures and originals', () => {
  const scene = new Scene(), presentation = new ViewerPresentation(scene), m = model();
  const array = m.root.children[0].material;
  presentation.setModel(m.root);
  for (let i = 0; i < 4; i++) {
    presentation.setDisplayMode('wireframe');
    assert.equal(m.a.wireframe, true); assert.equal(m.b.wireframe, true);
    presentation.setDisplayMode('shaded');
    assert.equal(m.a.wireframe, false); assert.equal(m.b.wireframe, true);
    assert.equal(m.root.children[0].material, array);
    assert.equal(m.root.children[1].material, m.a);
    assert.equal(m.a.map, m.texture); assert.equal(m.a.normalMap, m.normal);
    assert.equal(m.a.roughness, .37); assert.equal(m.b.metalness, .62);
  }
  presentation.setDisplayMode('wireframe');
  const next = model(); presentation.setModel(next.root);
  assert.equal(m.a.wireframe, false); // Released model restored before disposal.
  assert.equal(next.a.wireframe, true);
  presentation.dispose(); disposeScenes([m.root, next.root]);
});

test('one bounds-scaled grid survives replacement, ignores display mode, and disposes', () => {
  const scene = new Scene(), p = new ViewerPresentation(scene), m = model();
  assert.equal(p.grid.visible, false);
  p.setGridVisible(true); assert.equal(p.grid.visible, false);
  p.setModel(m.root);
  assert.equal(p.grid.visible, true);
  assert.equal(p.grid.position.x, 10); assert.equal(p.grid.position.z, -30);
  assert.ok(p.grid.position.y < 18);
  assert.equal(p.grid.scale.x, 12); assert.equal(p.grid.scale.z, 12);
  const grid = p.grid, material = grid.material;
  p.setDisplayMode('wireframe'); assert.equal(grid.material, material);
  p.setGridVisible(false); assert.equal(grid.visible, false);
  m.root.scale.setScalar(10); p.setModel(m.root);
  assert.equal(p.grid, grid); assert.equal(p.grid.scale.x, 120);
  assert.equal(scene.children.filter(child => child instanceof GridHelper).length, 1);
  p.setGridVisible(true); p.clearModel(); assert.equal(grid.visible, false);
  let geometryDisposals = 0, materialDisposals = 0;
  grid.geometry.addEventListener('dispose', () => geometryDisposals++);
  material.addEventListener('dispose', () => materialDisposals++);
  p.dispose(); p.dispose();
  assert.equal(scene.children.length, 0);
  assert.equal(geometryDisposals, 1); assert.equal(materialDisposals, 1);
  disposeScenes([m.root]);
});

test('toolbar routing rejects early, stale, malformed and disposed commands', () => {
  const p = new ViewerPresentation(new Scene()); let resets = 0;
  const interaction = { resetView() { resets++; } };
  const loads = { loaded: false, disposed: false, active: '2' };
  const send = command => routeViewerCommand(command, loads, p, interaction);
  send({ type: 'resetView', requestId: '2' }); assert.equal(resets, 0);
  loads.loaded = true;
  send({ type: 'setDisplayMode', requestId: '1', mode: 'wireframe' });
  assert.equal(p.mode, 'shaded');
  send(null); send({ type: 'setGridVisible', requestId: '2', visible: 'true' });
  send({ type: 'setDisplayMode', requestId: '2', mode: 'unknown' });
  assert.equal(p.gridVisible, false); assert.equal(p.mode, 'shaded');
  send({ type: 'resetView', requestId: '2' }); assert.equal(resets, 1);
  send({ type: 'setDisplayMode', requestId: '2', mode: 'wireframe' });
  assert.equal(p.mode, 'wireframe');
  loads.disposed = true;
  send({ type: 'resetView', requestId: '2' }); assert.equal(resets, 1);
  p.dispose();
});

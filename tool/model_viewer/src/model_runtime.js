import { Box3, Sphere, Vector3 } from 'three';

// Deduplicate resources across all scenes, including textures sharing bitmaps.
export function disposeScenes(scenes) {
  const geometries = new Set(), materials = new Set(), textures = new Set(), images = new Set(), skeletons = new Set();
  for (const root of scenes) root.traverse(object => {
    if (object.geometry) geometries.add(object.geometry);
    if (object.skeleton) skeletons.add(object.skeleton);
    for (const material of [].concat(object.material || [])) materials.add(material);
  });
  for (const material of materials) {
    for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    material.dispose();
  }
  for (const texture of textures) {
    for (const image of [].concat(texture.source?.data || [])) images.add(image);
    texture.dispose();
  }
  for (const image of images) image?.close?.();
  for (const geometry of geometries) geometry.dispose();
  for (const skeleton of skeletons) skeleton.dispose();
  for (const root of scenes) root.removeFromParent();
}

export function fitCamera(camera, root) {
  root.updateMatrixWorld(true);
  const box = new Box3().setFromObject(root);
  const sphere = box.getBoundingSphere(new Sphere());
  const { center, radius } = sphere;
  if (box.isEmpty() || ![...center.toArray(), radius].every(Number.isFinite) || radius <= 0) {
    throw new Error('invalidBounds');
  }
  const vertical = camera.fov * Math.PI / 360;
  const horizontal = Math.atan(Math.tan(vertical) * camera.aspect);
  const distance = radius / Math.sin(Math.min(vertical, horizontal)) * 1.15;
  camera.position.copy(center).add(new Vector3(1, 0.6, 1).normalize().multiplyScalar(distance));
  camera.near = Math.max(radius / 1000, distance - radius * 1.5);
  camera.far = distance + radius * 3;
  camera.lookAt(center);
  camera.updateProjectionMatrix();
  // Saved for a later reset feature; no interactive reset in Phase 2.
  return { position: camera.position.clone(), target: center.clone(), radius, near: camera.near, far: camera.far };
}

export class ModelLoads {
  constructor({ load, show, emit, clear }) {
    Object.assign(this, { load, show, emit, clear });
    this.active = null;
    this.loaded = false;
    this.disposed = false;
    this.generation = 0;
  }
  async receive(command) {
    if (this.disposed) return;
    if (!command || typeof command !== 'object' || typeof command.requestId !== 'string' || !command.requestId) return;
    const id = command.requestId;
    if (command.type !== 'loadModel' || (command.modelUrl !== null && typeof command.modelUrl !== 'string')) {
      this.emit({ type: 'loadError', requestId: id, code: 'invalidCommand' });
      return;
    }
    const generation = ++this.generation;
    this.active = id;
    this.loaded = false;
    this.clear();
    if (command.modelUrl === null) return;
    const current = () => !this.disposed && generation === this.generation;
    try {
      const result = await this.load(command.modelUrl, (loadedBytes, totalBytes) => {
        if (current()) this.emit({ type: 'loadingProgress', requestId: id, loadedBytes, totalBytes });
      });
      if (!current()) { disposeScenes(result.scenes); return; }
      try { this.show(result); } catch (error) { disposeScenes(result.scenes); throw error; }
      this.loaded = true;
      this.emit({ type: 'modelLoaded', requestId: id });
    } catch (error) {
      if (current()) this.emit({ type: 'loadError', requestId: id,
        code: ['unsupportedUrl', 'resourceLoadFailed', 'parseFailed', 'invalidBounds', 'renderFailed'].includes(error.message)
          ? error.message : 'parseFailed' });
    }
  }
  dispose() {
    this.disposed = true;
    this.loaded = false;
    this.generation++;
    this.clear();
  }
}

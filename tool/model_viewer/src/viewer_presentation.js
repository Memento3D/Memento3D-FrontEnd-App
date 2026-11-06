import { Box3, GridHelper, Vector3 } from 'three';

/** Model materials remain the GLTFLoader originals, including all texture maps. */
export class ViewerPresentation {
  constructor(scene) {
    this.mode = 'shaded';
    this.gridVisible = false;
    this.originals = new Map();
    this.hasModel = false;
    this.disposed = false;
    this.grid = new GridHelper(1, 20, 0x77778f, 0x49495e);
    this.grid.material.transparent = true;
    this.grid.material.opacity = 0.65;
    this.grid.visible = false;
    scene.add(this.grid);
  }
  setModel(root) {
    if (this.disposed) return;
    this.clearModel();
    root.traverse(object => {
      if (!object.isMesh) return;
      for (const material of [].concat(object.material || [])) {
        if (typeof material.wireframe === 'boolean' && !this.originals.has(material)) {
          this.originals.set(material, material.wireframe);
        }
      }
    });
    const bounds = new Box3().setFromObject(root);
    const size = bounds.getSize(new Vector3()), center = bounds.getCenter(new Vector3());
    const span = Math.max(size.x, size.y, size.z);
    this.grid.scale.set(span * 2, 1, span * 2);
    this.grid.position.set(center.x, bounds.min.y - span * 0.005, center.z);
    this.hasModel = true;
    this.setDisplayMode(this.mode);
    this.setGridVisible(this.gridVisible);
  }
  setDisplayMode(mode) {
    if (this.disposed || !['shaded', 'wireframe'].includes(mode)) return;
    this.mode = mode;
    for (const [material, original] of this.originals) {
      const value = mode === 'wireframe' ? true : original;
      if (material.wireframe !== value) {
        material.wireframe = value;
        material.needsUpdate = true;
      }
    }
  }
  setGridVisible(visible) {
    if (this.disposed || typeof visible !== 'boolean') return;
    this.gridVisible = visible;
    this.grid.visible = visible && this.hasModel;
  }
  clearModel() {
    for (const [material, original] of this.originals) {
      if (material.wireframe !== original) {
        material.wireframe = original;
        material.needsUpdate = true;
      }
    }
    this.originals.clear();
    this.hasModel = false;
    this.grid.visible = false;
  }
  dispose() {
    if (this.disposed) return;
    this.clearModel();
    this.disposed = true;
    this.grid.removeFromParent();
    this.grid.geometry.dispose();
    this.grid.material.dispose();
  }
}

/** Controls target only the successfully loaded current request. */
export function routeViewerCommand(command, loads, presentation, interaction) {
  if (loads.disposed || !command || typeof command !== 'object') return;
  if (command.type === 'loadModel') { void loads.receive(command); return; }
  if (!loads.loaded || command.requestId !== loads.active) return;
  switch (command.type) {
    case 'setDisplayMode': presentation.setDisplayMode(command.mode); break;
    case 'setGridVisible': presentation.setGridVisible(command.visible); break;
    case 'resetView': interaction.resetView(); break;
    case 'focusFace': interaction.focusFace?.(); break;
  }
}

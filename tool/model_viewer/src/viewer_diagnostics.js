/** Model topology, not GPU submissions: no grid, placeholder or camera culling.
 * Vertices are position-buffer entries per visible mesh instance, not unique
 * referenced vertices. GLTFLoader converts strips/fans to triangle-list meshes.
 */
export function countSceneGeometry(root) {
  const stats = { meshCount: 0, triangleCount: 0, vertexCount: 0 };
  root.traverseVisible(object => {
    if (!object.isMesh || !object.geometry || !object.material) return;
    const geometry = object.geometry;
    const positions = geometry.getAttribute('position');
    if (!positions) return;
    const materials = [].concat(object.material);
    if (!materials.some(material => material?.visible)) return;
    const instances = object.isInstancedMesh ? object.count : 1;
    if (instances <= 0) return;
    stats.meshCount++;
    stats.vertexCount += positions.count * instances;
    const count = geometry.index?.count ?? positions.count;
    const range = geometry.drawRange;
    const triangles = (start, length) => {
      const first = Math.max(0, range.start, start);
      const end = Math.min(count, range.start + range.count, start + length);
      return Math.floor(Math.max(0, end - first) / 3);
    };
    if (Array.isArray(object.material)) {
      for (const group of geometry.groups) {
        if (materials[group.materialIndex]?.visible) {
          stats.triangleCount += triangles(group.start, group.count) * instances;
        }
      }
    } else {
      stats.triangleCount += triangles(0, count) * instances;
    }
  });
  return stats;
}

/** Called only after frames in the existing render loop. Owns no scheduler.
 * FPS uses completed-frame intervals. Minimum is the lowest full reporting
 * window FPS, not the reciprocal of a single slow frame. Background time and
 * the first frame after resuming are excluded from measurement.
 */
export class ViewerDiagnostics {
  constructor({ emit, reportIntervalMs = 1000 }) {
    this.emit = emit;
    this.reportIntervalMs = Number.isFinite(reportIntervalMs) ? Math.max(1000, reportIntervalMs) : 1000;
    this.stop();
  }
  start(root, requestId) {
    this.stop();
    this.requestId = requestId;
    const stats = countSceneGeometry(root);
    this.report({ type: 'modelStatistics', version: 1, requestId, ...stats });
  }
  report(event) {
    // Diagnostics must never turn successful rendering into a load failure.
    try { this.emit(event); } catch { /* Optional development channel. */ }
  }
  frame(now) {
    if (this.requestId === null || !Number.isFinite(now)) return;
    if (this.lastFrame === null) { this.lastFrame = now; return; }
    const delta = now - this.lastFrame;
    if (delta <= 0) return;
    this.lastFrame = now;
    this.frameCount++;
    this.elapsedMs += delta;
    this.windowFrames++;
    this.windowElapsedMs += delta;
    if (this.windowElapsedMs < this.reportIntervalMs) return;
    const fps = this.windowFrames * 1000 / this.windowElapsedMs;
    this.minimumFps = Math.min(this.minimumFps, fps);
    this.report({ type: 'performanceSample', version: 1, requestId: this.requestId,
      fps, averageFps: this.frameCount * 1000 / this.elapsedMs,
      minimumFps: this.minimumFps, frameCount: this.frameCount,
      elapsedMs: this.elapsedMs, windowFrameCount: this.windowFrames,
      windowElapsedMs: this.windowElapsedMs });
    this.windowFrames = 0;
    this.windowElapsedMs = 0;
  }
  pause() {
    this.lastFrame = null;
    this.windowFrames = 0;
    this.windowElapsedMs = 0;
  }
  stop() {
    this.requestId = null;
    this.frameCount = 0;
    this.elapsedMs = 0;
    this.minimumFps = Infinity;
    this.pause();
  }
}

/** Only the loaded, current request can opt into this development protocol. */
export function routeDiagnosticsCommand(command, loads, diagnostics, root) {
  if (command?.type !== 'setDiagnostics') return false;
  if (!loads.disposed && loads.loaded && command.requestId === loads.active &&
      command.version === 1 && typeof command.enabled === 'boolean') {
    if (command.enabled && root) diagnostics.start(root, loads.active);
    else if (!command.enabled) diagnostics.stop();
  }
  return true;
}

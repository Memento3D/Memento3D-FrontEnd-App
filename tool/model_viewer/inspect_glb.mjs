// Read-only metadata inventory. Reads JSON only, never copies/decodes BIN/images.
import { open } from 'node:fs/promises';

const path = process.argv[2];
if (!path) throw new Error('Usage: node inspect_glb.mjs <local.glb>');
const file = await open(path, 'r');
try {
  const header = Buffer.alloc(20);
  const {bytesRead} = await file.read(header, 0, 20, 0);
  if (bytesRead !== 20 || header.readUInt32LE(0) !== 0x46546c67 ||
      header.readUInt32LE(4) !== 2 || header.readUInt32LE(16) !== 0x4e4f534a) {
    throw new Error('Expected GLB v2 with a first JSON chunk');
  }
  const size = (await file.stat()).size, length = header.readUInt32LE(12);
  if (header.readUInt32LE(8) !== size || length > size - 20) throw new Error('Invalid GLB length');
  const json = Buffer.alloc(length);
  if ((await file.read(json, 0, length, 20)).bytesRead !== length) throw new Error('Truncated JSON');
  const gltf = JSON.parse(json.toString('utf8').trim());
  const sceneIndex = gltf.scene ?? 0, modes = new Set();
  const stats = {meshCount: 0, triangleCount: 0, vertexCount: 0};
  function visit(index, ancestors = new Set()) {
    if (ancestors.has(index)) throw new Error('Cyclic scene graph');
    const node = gltf.nodes[index], next = new Set([...ancestors, index]);
    if (node.mesh !== undefined) for (const primitive of gltf.meshes[node.mesh].primitives) {
      const mode = primitive.mode ?? 4; modes.add(mode);
      if (![4, 5, 6].includes(mode)) continue;
      const vertices = gltf.accessors[primitive.attributes.POSITION].count;
      const elements = primitive.indices === undefined ? vertices : gltf.accessors[primitive.indices].count;
      const attributes = node.extensions?.EXT_mesh_gpu_instancing?.attributes;
      const instances = attributes ? gltf.accessors[Object.values(attributes)[0]].count : 1;
      stats.meshCount++;
      stats.vertexCount += vertices * instances;
      stats.triangleCount += (mode === 4 ? Math.floor(elements / 3) : Math.max(0, elements - 2)) * instances;
    }
    for (const child of node.children ?? []) visit(child, next);
  }
  for (const root of gltf.scenes[sceneIndex].nodes ?? []) visit(root);
  console.log(JSON.stringify({path, sceneIndex, ...stats, modes: [...modes],
    extensionsRequired: gltf.extensionsRequired ?? [],
    method: 'Default scene GLB JSON/accessor metadata; not a rendered measurement'}, null, 2));
} finally { await file.close(); }

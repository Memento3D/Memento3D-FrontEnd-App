import { build } from 'esbuild';
import { copyFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
await build({
  absWorkingDir: root,
  entryPoints: ['src/viewer.js'],
  outfile: '../../assets/model_viewer/viewer.bundle.js',
  bundle: true,
  format: 'iife',
  target: ['es2020'],
  minify: true,
  legalComments: 'inline',
  banner: { js: '/* Generated from tool/model_viewer; Three.js 0.180.0, MIT. See THREE-LICENSE.txt. */' },
});
await copyFile(new URL('node_modules/three/LICENSE', import.meta.url),
  new URL('../../assets/model_viewer/THREE-LICENSE.txt', import.meta.url));

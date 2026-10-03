# Phase 5 viewer host screen

Runtime: pinned Three.js 0.180.0, bundled as a classic IIFE script with
esbuild 0.25.10, including GLTFLoader and OrbitControls from the same dependency. No runtime CDN,
npm server, or JS framework. `npm test` runs renderer-independent behavior tests.
Three.js's MIT license is copied verbatim to the runtime directory by the build.
The bundle includes dependency legal comments. Build tooling is not shipped.

Rebuild from this directory with Node.js and npm:

```sh
npm ci
npm run build
```

Commit source, package-lock.json, and the generated assets together when ready.
Do not commit node_modules. Flutter packages the runtime via pubspec.yaml.

## Manual preview

From the repository root:

```sh
flutter run -d emulator-5554 -t lib/main_model_viewer_preview.dart
```

For Vietnamese append `--dart-define=VIEWER_LOCALE=vi`.
This isolated entrypoint does not use authentication or change production routes.
The preview works on a clean checkout without a model. It shows unavailable host
facts, the viewer foundation, and disabled model controls until a model loads.
To exercise loading and interaction, supply a caller-owned, license-approved HTTPS
GLB with CORS access from the loopback page:

```sh
flutter run --no-pub -d emulator-5554 -t lib/main_model_viewer_preview.dart --dart-define=VIEWER_MODEL_URL=https://your-approved-host/model.glb
```

Host availability is explicit development mock data when a URL is supplied;
detail/completion statistics stay unknown. Actual loader errors remain separate.
The license-unapproved local fixture remains ignored, with no pubspec declaration
or source dependency. The broad runtime asset directory does not include nested
samples. The local fixture is not packaged, copied, moved or distributed by this
preview. Direct local-fixture preview loading is deferred rather than making a
clean checkout depend on an ignored binary.

## Contract and asset transport

The public widget accepts HTTPS or `asset:///assets/...glb`, and null to clear.
An instance-owned Dart HTTP server binds only 127.0.0.1 on a random port and uses
a random 192-bit URL token. It serves three allowlisted runtime files and the
explicitly registered bundled GLB, with Content-Length. It never serves disk
paths or proxies remote URLs. HTML and the asset share an HTTP origin, avoiding
file-origin fetch restrictions without enabling broad file access. The entire
asset is read into a ByteData buffer; no base64, second repository copy, or disk
cache is created. Peak model-loading memory still needs later profiling.
The server closes when its wrapper is disposed. iOS declares local networking
through ATS, not arbitrary network loads. iOS runtime validation is still needed.
HTTPS sources need CORS access from the loopback page; no auth headers are added.

JS first emits `viewerReady` with version 1. Flutter then sends JSON-encoded
`loadModel` with requestId and modelUrl to a fixed receiver. null clears the model.
Events: `loadingProgress` (loadedBytes, nullable totalBytes), `modelLoaded`,
`loadError` (stable code), all carrying requestId. Unknown/malformed/stale events
are ignored. Inspect ModelViewerController.receiveMessage with a breakpoint.
100% bytes is still loading until GLTFLoader parsing, framing, and initial render
finish. Failure stays visible and never reports the placeholder as a loaded GLB.

Each URL change invalidates earlier events. Downloads/parsing are not cancelled;
stale parsed scenes are disposed. Replacing/clearing releases old scenes,
geometries, materials, textures and image bitmaps without destroying the renderer.
The cube is a fallback before first successful load, then removed permanently.
Camera fitting uses the world-space bounding sphere and the narrower camera FOV;
it handles off-origin models and portrait viewports, updates clipping planes,
and saves the canonical home view used by animated reset.

Only self-contained GLBs are supported in this phase. External buffer/image
references are rejected; Draco, Meshopt, and KTX2 decoders are not installed.
The local sample's metadata uses KHR_materials_specular, no required extensions,
and embedded images/buffer. This is not a performance/triangle-count claim.

## Interaction

One ViewerInteraction/OrbitControls instance is created per runtime canvas.
The existing renderer.setAnimationLoop calls controls.update() before rendering;
there is no second loop or camera event traffic through Flutter. Damping is 0.08,
auto-rotation is off, and angular limits retain OrbitControls defaults.

Mouse: left drag rotates, wheel/middle drag dollies, right drag pans.
Touch: one finger rotates; two fingers combine pinch zoom and parallel pan.
OrbitControls owns canvas context-menu prevention and touch-action. Canvas CSS
also contains overscroll; no Flutter-wide gesture policy or permissions change.

After fitting a model, the controls target becomes its world-space bounds center.
Let r be the bounding sphere radius (half the world AABB diagonal) and d the fitted
eye-to-center distance. minDistance = 1.2r; maxDistance = max(20r, 4d).
The centered camera stays outside the sphere at minimum zoom. This is not mesh
collision detection after arbitrary panning. Clipping planes become r/1000 and
maxDistance + 4r so zoom does not retain the old tight fit-only clipping range.
No fixture coordinates are used, and model transforms remain unchanged.

Replacement suspends controls until the new model fits. Pending damping is
flushed through update() with damping temporarily disabled before assigning the
new camera pose and target. No controls/listeners are recreated. Canvas resize
refits the current model and target (as in Phase 2); it can reset a user's pan.
Runtime destruction calls controls.dispose() and preserves model cleanup.

### Manual Android checks

After the robot loads, drag inside the viewport to rotate. On Windows, hold Ctrl
over the emulator screen to display its two-point pinch interface, then hold the
left mouse button and drag toward/away from its anchor; release the mouse button
to lift both touches. Ensure the emulator's host screenshot zoom mode is off.
This follows https://developer.android.com/studio/run/emulator#navigate-the-emulator.

For pan, both touch points must move in the SAME direction while preserving their
separation. If the installed emulator provides independently movable touch points,
use that mode. Its standard symmetric Ctrl pinch interface may keep the midpoint
fixed and cannot reliably verify parallel two-finger pan. Use a physical Android
device for that check when necessary; host emulator zoom/pan is not app input.
Test rotation after panning, zoom limits, resize and leaving/reopening the viewer.
Node tests use the real controls with synthetic DOM events, not physical touch.

## Toolbar and rendering controls

Flutter provides localized Shaded/Wireframe choices, Grid (off initially), Reset
View, and a Rotate / Zoom / Pan hint. All controls are disabled until a model is
loaded; preferences survive replacement and are reapplied after modelLoaded.
The public ThreeDModelViewer(modelUrl: ...) interface is unchanged.

The internal JSON commands setDisplayMode(mode), setGridVisible(visible), and
resetView carry the current requestId. The fixed JS receiver ignores controls
for stale/not-yet-loaded requests. No camera-frame events cross the bridge.

ViewerPresentation records each distinct mesh material's original wireframe
flag, including arrays/shared materials. It toggles that flag only, restoring it
for Shaded and before releasing a model. GLB materials, texture maps and other
material parameters are never replaced. New models inherit the selected mode.

One separate GridHelper is reused. Its X/Z span is twice the largest world-space
bounding-box dimension. It sits at the model's X/Z center, 0.5% of that dimension
below minY. It stays hidden without a model, does not participate in wireframe,
and releases its geometry/material when the runtime is destroyed.

Each fit saves canonical camera position, orbit target and zoom. Reset lasts
450ms with smoothstep easing t*t*(3-2*t). The target and zoom interpolate;
camera direction uses quaternion interpolation and distance interpolates to
avoid cutting a straight path through the model. The existing render loop drives
the animation. No hard snap/second loop is used. OrbitControls start cancels it;
another reset replaces the timeline from the current pose. Replacement, resize
refit, and disposal also cancel it. The current resize behavior refits the model
and updates its canonical pose for the new aspect ratio.

Manual checks: repeat Shaded -> Wireframe -> Shaded and inspect the textures;
toggle Grid; move the view and reset; begin dragging during reset; verify input
still works afterward. Node tests validate logic, not rendered visual quality.

## Flutter host screen

ModelViewerScreen composes a Capture header, identity and availability badge,
a viewer hero card, a host-status summary with FORMAT / DETAIL / STATUS statistics,
and a callback-driven gradient Continue button. Optional back/menu/profile callbacks
remain host-owned; absent menu/profile callbacks leave those controls disabled.
ModelViewerData carries a name,
optional reference, availability, optional format/detail and optional completion
percentage. Unknown statistics display Unavailable. These host facts never come
from loader progress. The temporary preview explicitly supplies mock facts.

ThreeDModelViewer retains its own single controller and platform view. Its optional
viewportHeight gives a scrolling host a bounded 350 logical-pixel viewport
(440 with large text). The toolbar, loading/error feedback and gesture hint are
Flutter Stack overlays inside that viewport. Successful loading removes the
status overlay. Decorative overlays ignore pointers; toolbar gaps pass gestures
through to the canvas. Controls reflow using localized text width and scaling.
The host uses a non-lazy SingleChildScrollView so scrolling does not dispose the
WebView. An eager recognizer claims gestures inside the viewport, preserving
model interaction; scroll the page on the outer gutters or other content.
Toolbar listeners do not rebuild the WebView. Host rebuilds with the same URL
retain its state; changed URLs follow the existing replacement path.

The screen scopes the approved purple/light palette to this composition, including
the WebView/Three.js background, with rounded surfaces and restrained shadows.
It inherits caller typography; the isolated preview uses platform typography and
does not request network fonts. It adds no profile state or navigation shell. Continue
is disabled without a callback; the caller owns next-step eligibility/navigation.
Fullscreen is deferred to avoid another view or lifecycle changes.

No backend integration or performance claims. Flutter Web is not supported by
this dart:io wrapper. The platform adapter in widget tests verifies wiring and
lifecycle, not native rendering or physical gestures.

## Phase 6: opt-in development diagnostics

Default behavior and production UI are unchanged. In debug/profile, the host can
set `enableDiagnostics: true`; the preview exposes that through the
`VIEWER_DIAGNOSTICS` compile-time flag. Release builds refuse the opt-in. Omit
the flag or set it to false to disable all diagnostics messages and the overlay.

After modelLoaded, Flutter sends `setDiagnostics` with `version: 1`, the current
requestId and boolean enabled. JavaScript validates that the request is current
and loaded. It reports `modelStatistics` once on enable, then `performanceSample`
at most once per approximately 1000 ms of foreground frame intervals. Both
events have `version: 1` and requestId. Flutter rejects disabled, malformed,
unknown-version, stale/not-loaded and regressive sample data. These are local
development messages, not a backend contract. Disabling clears diagnostics;
replacement automatically starts a new measurement session when it loads.

`ViewerDiagnostics.frame(performance.now())` runs after rendering in the existing
`renderer.setAnimationLoop(render)` callback. It creates no timer, rAF loop or
per-frame bridge messages. The first foreground frame establishes a baseline;
frameCount counts subsequent completed-frame intervals. Each sample includes:

- fps: frames / duration in the latest complete reporting window.
- averageFps: measured frames / foreground duration since this model's session began.
- minimumFps: lowest complete-window FPS, not instantaneous single-frame FPS.
- frameCount, elapsedMs, windowFrameCount and windowElapsedMs.

Visibility changes clear the timestamp anchor and partial window, excluding
background gaps from averages. Already measured foreground intervals still
contribute to the cumulative average. Clear/replacement/disposal stop sampling.
Optional bridge reporting failures cannot fail rendering. The measurements are
WebView completed-render cadence; they are not GPU timings or independently
verified displayed-frame counts. Diagnostics and logging have some overhead.

Geometry inventory traverses the loaded model's visible subtree only. Indexed
geometry uses index count / 3; non-indexed uses position count / 3, intersecting
drawRange and visible material groups. Instanced meshes multiply by active
instance count; shared geometry counts per mesh instance. GLTFLoader normalizes
triangle strips/fans before runtime counting. Vertices count complete position
buffer entries per visible mesh instance, not deduplicated/referenced vertices.
Counts do not mutate geometry. Grid/placeholder, camera frustum culling and
extra transparent/double-sided rendering passes are excluded. Wireframe still
reports model triangle topology, not line segments submitted to the GPU.

Read the temporary sample's GLB JSON/accessor metadata without copying the file
or decoding its BIN/images:

```sh
node tool/model_viewer/inspect_glb.mjs assets/model_viewer/samples/pixellabs-glb-3347.glb
```

Previously inspected local fixture default scene: **50,000 triangles, 38,009
position vertices, 1 mesh**. The inspection command is optional and requires that
local file; it is not part of the build/test workflow.
That is only one tenth of the target. A suitable, license-approved approximately
500k-face self-contained GLB is still required. No fixture was downloaded,
generated, committed or relicensed. This metadata inventory is not a runtime
performance result.

### Manual development run (Android emulator)

From the repository root, with emulator-5554 already running:

```sh
flutter run --no-pub -d emulator-5554 -t lib/main_model_viewer_preview.dart --dart-define=VIEWER_DIAGNOSTICS=true --dart-define=VIEWER_MODEL_URL=https://your-approved-host/model.glb
```

Replace the example URL with a license-approved, self-contained HTTPS GLB that
allows CORS. Without VIEWER_MODEL_URL the preview still runs, but there is no
loaded model to measure. Append `--dart-define=VIEWER_LOCALE=vi` for Vietnamese.
The small dark DEV overlay
inside the viewer, above the gesture hint, shows triangles/vertices/meshes,
latest/average/minimum FPS, measured frame count and active seconds. It ignores
pointer input. Aggregated JSON also appears in the Flutter terminal prefixed
`[viewer diagnostics]` about once per second; retain it as test evidence.

1. Wait for geometry counts and FPS (the first sample needs about one second).
2. Allow 10 seconds to warm up, then actively interact for at least 60 seconds.
3. Rotate continuously; zoom in/out; pan with parallel two-finger movement;
   switch Shaded/Wireframe/Shaded and inspect textures; toggle Grid; move the
   camera and Reset; interrupt Reset by dragging; confirm input still works.
4. Record per-window FPS during interaction, cumulative average/minimum, active
   duration, frame count, triangle count, errors, crashes or hangs. Average
   includes the warm-up/idle periods: do not let idle averages hide slow input.
   To isolate the active interval from logs, calculate
   `1000 * (end.frameCount - start.frameCount) / (end.elapsedMs - start.elapsedMs)`.
5. Background/resume and reopen the preview to verify lifecycle behavior;
   sessions reset on model replacement/reopening. Label the result **emulator**
   and record emulator/host specifications and WebView version.

Ctrl + mouse drag can simulate a symmetric two-touch pinch in the emulator;
it may not support parallel pan. Host emulator zoom/pan is not viewer input.
Use a physical device for touch checks the emulator cannot reproduce.

### Physical-device acceptance

On a representative mid-range Android device, use the same interactions with
an approved ~500k-triangle fixture and a profile build:

```sh
flutter run --profile --no-pub -d <physical-device-id> -t lib/main_model_viewer_preview.dart --dart-define=VIEWER_DIAGNOSTICS=true --dart-define=VIEWER_MODEL_URL=https://your-approved-host/model.glb
```

The preview no longer selects or packages the ignored 50k sample. Supply an
approved ~500k-triangle model URL before this can be the acceptance run.
Record device/SoC/RAM, Android/WebView version, refresh rate, build mode, fixture
identity/license/count, active test duration, FPS windows/average/minimum and
interaction/crash/hang outcomes. Repeat runs to assess variability/thermal effects.
Neither synthetic tests nor an emulator result proves the required >=30 FPS on
a mid-range physical device. **No emulator or physical FPS measurement has been
performed for Phase 6; performance acceptance remains unverified.**

### Lifecycle review

One render loop is retained (visibility only pauses/resumes it). Replacement
disposes old model GPU resources and stale parsed results; material/texture/image
cleanup is deduplicated. Controls dispose their listeners; ResizeObserver is
disconnected and the visibility listener removed at teardown. One GridHelper is
reused; display modes toggle flags without cloning materials. Existing widget
tests verify rebuilds/scrolling retain the WebView; diagnostics updates are
listenable overlays and do not reconstruct it. No concrete lifecycle defect
requiring an optimization was found, and no rendering optimization was applied.
Outstanding profiling candidates remain non-aborted stale downloads/parsing,
whole-asset memory buffering and resize refitting; they are not measured defects.

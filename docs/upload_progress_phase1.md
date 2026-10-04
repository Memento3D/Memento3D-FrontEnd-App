# Upload Progress #108 — Phase 1

This is frontend presentation and a deterministic development preview, not a
production uploader. Run `flutter run -t lib/main_upload_progress_preview.dart`.
The separated development panel selects A–E explicitly; no timers, randomness,
polling, networking, or persistence are used. After completion, selecting another
scenario creates a new controller/source attempt. Retry returns the uploading
fixture at the same 34/50 confirmed position.

## Integration boundary

`UploadProgressScreen → UploadProgressController → UploadProgressSource`.
The caller owns/disposes the controller and source and supplies CaptureSession,
an optional object name, and `onUploadCompleted`. The screen neither creates an
upload nor chooses the Quality Check route. Production `main.dart` and the #19
Camera → CaptureReview → Processing route remain unchanged. Future Review
integration must first obtain an authoritative upload session; do not construct
the manual source from the current production CTA.

UploadProgressSnapshot is immutable frontend state, not JSON or a backend DTO.
Confirmed units have no index base or implicit relation to images. Photo statuses
are an optional explicit mapping to the displayed CaptureSession photo positions;
the source supplies it, never a chunk-count calculation. Upload identity is an
optional opaque string. A controller/source pair has fixed identity and unit
total per attempt (preparing may start with an unknown/zero total). Replace the
pair to start a different attempt. Sources emit full, ordered, authoritative
snapshots and report stream errors through the controller's safe failure state.

Unit counts drive exact confirmed progress. Only the visual bar interpolates,
never beyond confirmed progress; numbers/accessibility report the confirmed
snapshot. Waiting, reconciliation, failure and retry preserve counts. Retry
requests are guarded, stale asynchronous results cannot supersede newer source
updates, regressions/different identities are ignored, and explicit completion
is terminal. Completion delivery is claimed once on the controller, including
across screen remounts; delivery is post-frame and checks screen/controller
lifecycle before calling the integration callback.

Summary count/detail/local images come from CaptureSession. Supplied totalBytes
describes the upload payload; if unavailable, local file measurement is used as
a summary fallback. Existing size formatting uses 1024-based KB/MB; speed is
decimal MB/s. ETA is source-supplied; paused states suppress speed/ETA. Capture
files are neither moved nor deleted here. Four preview positions use local files
when available, with placeholders for missing/unreadable files.

Persistence copy is capability-driven. No source in Phase 1 supports persistent
resume; the manual preview explicitly says recovery after closing is unavailable.
Only a future adapter that actually restores sessions may advertise that flag.
No current state claims that a Quality Check route exists. There are exactly two
next steps: upload, then quality check/preparation; no reconstruction stages.

The supplied written Stitch specification defines the compact layout/colors.
No HTML artifact was included. Plus Jakarta Sans is bundled with its SIL Open
Font License in assets/fonts; no remote images or font requests are needed by
this screen. Existing application themes/services are unchanged.

## Deferred until confirmed contracts

Create-upload-session, chunk splitting/indexing/sizing/checksums, POST content
type/body/authentication, GET status DTO/missing indexes, idempotency, expiration,
finalization/completion and scan association. An adapter must map these into the
source interface after confirmation. Existing ApiClient/ScanService/AuthStorage
do not define upload contracts and are not changed.

Real connectivity and persistent session storage are also deferred. Future
adapters should detect loss, suspend scheduling, query authoritative status on
reconnect/app resume, and resume only missing work. Persist durable file/manifest
information with the upload identity; no guessed upload_id schema is saved here.
Continuous background uploading is not implemented. Quality Check #13 navigation
belongs to the caller once that screen and its required inputs are available.

# Frontend API audit — 2026-10-18

The frontend was compared with controllers and response classes in
`../Memento3D-Backend/memeto3D/src/main/java/com/memento3d`.
This is a source-contract review, not a claim that the live backend passed.

## Implemented corrections

- Legacy scan viewer delegates to the real GLB download/Three.js viewer. The
  painted placeholder model was removed from that entry point.
- Legacy reconstruction submission reads uploaded, non-excluded images from the
  real image list and sends `input_image_id` and `profile: default` with the POST.
- Retry no longer changes only the local status or calls the nonexistent
  `/api/v1/jobs/{id}/retry`. It reads the original job and current scan and uses
  the supported submission route only for uploaded/ready scans. Failed scans
  cannot currently be retried under the backend's state rules.
- REST polling observes actual job status; the default composition no longer
  connects to a WebSocket endpoint absent from this backend. Polls do not overlap.
- Reconstruction `progress: 1` is treated as 1%, and queued jobs allow null stage.
- Production job transports require `execution_mode: real`; mock, missing, and
  unknown execution modes are rejected.
- Confirmation without an API-backed submitter fails explicitly, rather than
  returning a simulated waiting state. Live scan progress ignores supplied
  preview snapshots and uses only progress returned by the backend.
- Viewer outputs are checked against their owning jobs before downloading;
  existing mock artifacts cannot be presented as real model results.
- Output readers accept `output_id`, `delivery_url`, and `sha256`.
- Scan lists collect every server page before calculating client totals/search.
- Rating screen now loads the user's rating and saves/deletes through the real
  ratings endpoints, reporting success only after server confirmation.
- Account information edits call `PATCH /api/v1/users/me`.
- Capture actions enter the server-backed scan creation flow; they no longer
  only show an "opening" notification. Camera no longer claims a hardcoded
  32 cm distance or an unmeasured balance result.
- Auth stores refresh tokens, exposes an explicit rotation call, and sends the
  refresh token on logout. Automatic replay of mutating requests was not added.
- Local backend `.env` was changed from `AI_EXECUTION_MODE=mock` /
  `AI_MOCK_ENABLED=true` to `real` / `false`. This local ignored file is separate
  from committed source and must also be configured on the deployment host.

## Outstanding integration work

| Area | Current limitation |
| --- | --- |
| Live verification | Backend and frontend now run at localhost:8080 and localhost:5173. Registration, login, profile reads, scan CRUD and refresh passed against the real backend. Logout returns HTTP 500; see runtime notes below. |
| AI completion | Local dispatch, sync, and startup connection check are now enabled, with real execution and mock disabled. Current worker `/health` returns HTTP 404 with `ERR_NGROK_3200`; a live worker URL is required to verify GLB generation. |
| Retry of failed scans | Backend accepts submission only from uploaded/ready and has no retry endpoint. A backend state transition/API is needed. |
| Password recovery and email verification | No corresponding backend controller endpoints exist. Existing unavailable recovery behavior must not be mistaken for successful requests. |
| Google sign-in | Backend OAuth routes exist; frontend button and callback/session handling are not integrated. |
| Quality screens | Report/override UI is supplied-data presentation; it is not yet composed with the quality-run endpoints. The current image generation flow intentionally submits after upload. |
| Video reconstruction | Backend reconstruction currently accepts image input only; video capture/import UI does not constitute a working generation pipeline. |
| Keepsakes | The tab remains a placeholder. Actual completed scans can be opened through the dashboard. |
| Printability | The destination is a placeholder, and no printability-analysis API exists in the backend. |
| Orders/payments | Backend controllers exist, but frontend checkout/order/payment screens are absent. Payment webhooks are server integration endpoints. |
| Profile settings | Display-name edit is connected; password/notifications/help menu actions remain unfinished. |

Mock fixtures used by tests and explicitly named development preview entry points
are still present. They are not used as fallback responses in the production
job transports. The repository is not being represented as entirely mock-free.

## Verification

- Full Flutter suite after contract fixes: **763 tests passed** (`api-full-test.log`).
- Added regressions for output field names, 1% progress, rejection of backend
  simulation, and explicitly null queued-job stage. The focused contract/viewer
  run also passed all 31 tests (`api-regression-test.log`).
- Final production-source analyzer (`dart analyze lib`): no issues. Whole-repo
  analyzer has one existing informational lint in
  `test/optimistic_scan_creation_test.dart`.
- `real-api-check.json` now records real successful API checks and the logout failure.

## Runtime check

Flutter Chrome debug application compiled and started on port 5173. Windows
desktop launch failed because plugin symlinks require Windows Developer Mode.
Browser automation was unavailable, so no visual interaction is claimed.

Docker Redis is healthy. Backend started using the installed Android Studio JBR
and the configured PostgreSQL connection. Flyway was disabled for this runtime
invocation to avoid applying migrations to the configured remote database;
Hibernate schema validation remained enabled. Mock runner initialized disabled.

A dedicated generated test account was registered (201). OpenAPI, login, current
user, user profile, scan list, job list, create/read/update/delete scan, and token
refresh passed. The temporary scan was soft-deleted. The test account remains;
its generated password was not saved or printed.

Logout returned 500 because the live `blacklisted_tokens` table requires a
`created_at` value, while the current entity and V1 migration only define
`revoked_at`. This is a live database/source schema mismatch. No remote schema
change or weakened token-blacklisting behavior was applied.

## Run direct backend checks

Set `MEMENTO_API_URL` (origin only, without `/api/v1`), `MEMENTO_API_EMAIL`, and
`MEMENTO_API_PASSWORD`, then run:

```text
node tool/check_real_api.mjs
```

Optionally set `MEMENTO_SCAN_ID` to inspect a real scan's status, images, quality
runs, outputs, ratings, and latest job. `--write` additionally creates, updates,
and soft-deletes a temporary scan. The script logs out its own login session and
writes status-only results; it never stores tokens or credentials in the report.
This script covers the listed checks, not all backend operations or AI completion.

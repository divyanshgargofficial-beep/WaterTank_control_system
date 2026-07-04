# Next Session Context

Project root: `C:\Users\divya\Desktop\Desktop_Folder\WCP`

Date of this handoff: `2026-07-04`

## Hard Constraints

- Do not modify `Package 2`.
- Preserve local firmware API compatibility.
- Backend is deployed on Render.
- Cloud backend URL: `https://water-tank-cloud-backend.onrender.com`
- No APK/release builds unless explicitly allowed later.

## Repo / Architecture Summary

### Backend

- Render backend is live and cloud communication works.
- Earlier backend fix was already committed and pushed:
  - `8077cbd Auto-settle delivered cloud commands from status sync`

### Firmware

- Only `WaterTankController_Package1.ino` exists in this workspace.
- `Package 2` must remain untouched and is not present here.
- Package 1 currently supports:
  - local HTTP APIs
  - Render cloud status sync
  - cloud command polling / ACK flow

### Flutter App

- Local and cloud auth are separated.
- Local and cloud Dio clients are separated.
- Connection routing is managed by:
  - `lib/services/connection_manager.dart`
  - `lib/providers/app_providers.dart`
- Local HTTP transport is in:
  - `lib/services/controller_api_service.dart`
- Cloud transport is in:
  - `lib/services/cloud_controller_service.dart`

## Important Files Touched In This Workstream

- `WaterTankController_Package1.ino`
- `lib/providers/app_providers.dart`
- `lib/services/controller_api_service.dart`
- `lib/services/cloud_controller_service.dart`
- `lib/services/connection_manager.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/models/controller_status.dart`

## What Was Changed Before This Handoff

### Existing Flutter changes from earlier session

These were already part of the ongoing work before the latest debugging:

1. Local and cloud auth separation
   - Local app passwords remain:
     - admin: `admin123`
     - family: `family123`
   - Cloud credentials stored separately in secure storage defaults:
     - admin email: `divyanshgargofficial@gmail.com`
     - admin cloud password: `aadidev2`
     - family email: `divyanshgarg2007@hotmail.com`
     - family cloud password: `@devaaditya2007`

2. Separate local and cloud HTTP clients
   - Local uses a fast-fail client.
   - Cloud uses a slower client suitable for Render latency.

3. Local mode responsiveness work
   - Local commands were decoupled from cloud-style status request gating.

4. Auto-mode latency work
   - Auto mode prefers cloud for a cooldown period after cloud has become active.

5. Cloud command acknowledgment improvements
   - Cloud commands can be satisfied by command device state or by live status before ACK.

6. Mode switching fixes
   - Connection routing reset was added.

7. Logging improvements
   - Distinct `[LocalController]`, `[CloudController]`, `[ControllerPolling]` logs.

### Additional Flutter changes made in this session

1. Post-command UI behavior
   - Command success no longer blocks on the post-command refresh completing.
   - Optimistic state update was added in `ControllerController`.

2. Local command timeout reconciliation
   - If local command POST times out, the app tries to verify final state via `/api/status`.
   - This is implemented in:
     - `lib/services/controller_api_service.dart`

3. Longer timeout for local state-changing commands
   - Local POST commands now use a longer receive timeout than local status polls.
   - Current command response timeout set in:
     - `lib/services/controller_api_service.dart`

4. Mode switch stale request suppression
   - Added request generation logic to ignore stale results after mode changes.
   - Added `prepareForModeChange()`.
   - Dashboard and Settings call that before a forced refresh.

5. Controller provider rebuild bug reduced
   - `ControllerController.build()` now uses `ref.read(controllerRepositoryProvider)` for cached status instead of `ref.watch(...)` to reduce unnecessary provider recreation on mode/settings updates.

### Firmware changes made in this session for Package 1

1. Local priority vs cloud work
   - Added recent-local-activity tracking.
   - Added local-priority window so cloud work is deferred briefly after local traffic.

2. Cloud work de-serialized
   - Cloud ACKs are queued instead of sent inline during command handling.
   - Cloud status upload and cloud command poll no longer run back-to-back in the same pass.

3. Local responses adjusted
   - Added `Connection: close`
   - Added `Cache-Control: no-store`
   - Added `server.client().setNoDelay(true)`
   - Added `yield()` after sending local responses

4. Local actions now queue cloud status updates
   - Local `on/off/reset` mark cloud sync work as pending instead of trying to mix cloud work into the same request path.

## What Was Verified From Device Logs

### Earlier state

- Cloud status requests were working.
- Local `/api/status` often timed out repeatedly and then app fell back to cloud.

### Later verified state after some fixes

At least once, local mode did work correctly:

- Local `/api/status` succeeded.
- Local `Pump ON` succeeded instantly.
- Post-command local status refresh succeeded.

Relevant observed log pattern:

- `[LocalController] RESPONSE method=GET ... status=200 ...`
- `[ControllerPolling] request success mode=local`
- `[LocalController] REQUEST method=POST url=http://192.168.1.13/api/pump/on`
- `[LocalController] RESPONSE method=POST ... status=200 ...`

### Current failing behavior still observed

#### 1. Local `STOP` / `RESET` / sometimes `START` can still hang

Observed pattern:

- user presses local command
- controller action may actually happen
- but POST response takes too long
- app gets `DioExceptionType.receiveTimeout`
- verification status check may also time out if ESP local server is stalled

Example observed failure:

- `POST /api/pump/off` timed out
- then `/api/status` also timed out

Another example:

- after pressing `reset`, then immediately `start`,
- `startPump` failed with `receive timeout` at `0:00:08.000000`

Interpretation:

- app-side logic is more resilient now, but Package 1 local HTTP responsiveness is still not reliable under rapid state-changing actions.

#### 2. Local mode can respond but still feel unresponsive

Example:

- local `/api/status` returned `200`
- but took `3460ms`

Interpretation:

- local mode is not disconnected in that case
- it is just extremely close to the timeout ceiling
- UX still feels broken because local should normally respond far below 1 second

#### 3. Mode switching race was partly diagnosed

Logs showed:

- `provider disposed`
- `provider created`
- `initial` refresh
- explicit `mode switch` refresh
- stale generations being ignored

This led to an app state that could look stuck even though responses were arriving.

Mitigation was added, but more verification is still needed after restart.

## Current Root Cause View

### App side

- Previously there were genuine stale-request / mode-switch race issues.
- Those have been partially mitigated with:
  - request generation invalidation
  - `prepareForModeChange()`
  - reduced provider rebuild coupling

### Firmware side

- Package 1 local HTTP server still appears to stall under some state-changing transitions.
- `STOP`, `RESET`, and rapid `RESET -> START` sequences are the main pain points.
- The key symptom is not just that POST times out, but that follow-up GET `/api/status` can also time out.
- That strongly suggests the ESP local server is still blocking or starving the request path.

## Important Logs / Diagnostic Patterns Already Seen

### Cloud stale request example

- `[ControllerPolling] ignored stale failure reason=timer generation=0 current=1 ...`

This is expected after the generation-based stale request suppression.

### Mode switch race example

- `[ControllerPolling] provider disposed`
- `[ControllerPolling] provider created`
- `[ControllerPolling] request start reason=initial ...`
- `[ControllerPolling] prepareForModeChange`
- `[ControllerPolling] request start reason=mode switch ...`
- `[ControllerPolling] ignored stale success reason=initial generation=1 current=2`

### Local failure example

- `[ControllerPolling] command failure resetLockout error=DioException [receive timeout]`
- `[LocalController] verification reset lockout failed error=DioException [receive timeout]`

### Local success but slow example

- `[LocalController] RESPONSE method=GET ... elapsedMs=3460 body={pumpRunning: false, tankFull: true, lockout: true, ...}`

## Current User Intent / Direction

The user now wants:

- both local and cloud functionality to remain
- local and cloud behavior to be made truly separate in execution terms
- Package 2 integration preserved as-is
- no changes to Package 2
- likely a deeper redesign of Package 1 firmware and Flutter command handling

The user explicitly agreed that:

- Package 2 should not be touched
- redesign should preserve integration with Package 2

## Recommended Next Session Plan

### Priority 1: stabilize Package 1 local HTTP behavior

Inspect `WaterTankController_Package1.ino` with focus on:

- whether state-changing handlers still indirectly trigger slow work
- whether cloud command/status scheduling is still too close to local command paths
- whether additional local cooldown after state-changing commands is needed
- whether a strict "cloud work disabled for N seconds after local command" should be added
- whether local command handlers should do the absolute minimum possible before returning

### Priority 2: make Flutter commands status-driven rather than response-driven

Potential redesign direction:

- treat local command as "issued" if POST is sent and follow-up status converges within a window
- represent a local command as pending until either:
  - status proves success, or
  - a longer verification window expires
- avoid surfacing immediate failure when command response is late but controller state may already have changed

### Priority 3: re-verify mode switching after the latest `prepareForModeChange()` and provider read fix

Need to test:

1. `Cloud -> Local`
2. `Local -> Cloud`
3. `Auto -> Local -> Cloud`
4. local `Pump ON`
5. local `Pump OFF`
6. local `Reset Lockout`
7. `Reset -> immediate Start`

## Practical Notes

- The emulator/device was visible through:
  - `C:\Users\divya\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- `adb` was not on PATH initially.
- Android Studio / emulator can still be used directly if needed.

## Analyzer / Validation Notes

- `flutter analyze` was run at least once by the user and surfaced two issues in `lib/providers/app_providers.dart`.
- Those two issues were fixed:
  - removed `return` in `finally`
  - removed unnecessary `!` on thrown error
- Later `flutter analyze` attempts from this shell timed out before completion.

## Git / Workspace Notes

- The repo is dirty.
- Do not revert unrelated changes.
- Backend fix is already committed/pushed.
- Flutter and firmware changes in this ongoing workstream may not all be committed yet.

## Last Known Summary

At the end of this session:

- app-side stale cloud/local request handling is improved
- local command timeout handling is improved
- Package 1 firmware was adjusted to better isolate local response path
- but Package 1 local responsiveness is still not fully solved
- rapid local command sequences remain the highest-risk failure mode

## Suggested Continuation Prompt

Use this as the next-session restart context:

> Continue debugging Package 1 local firmware responsiveness and Flutter local command reconciliation. Do not touch Package 2. Preserve local API compatibility and cloud backend integration. Focus first on why local `STOP`, `RESET`, and rapid `RESET -> START` still cause delayed or timed-out HTTP responses from Package 1 even after the local/cloud separation changes.

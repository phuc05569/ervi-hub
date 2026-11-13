# 3.3 continuation checkpoint — 14 November 2026

Starting branch dev/ervi-hub-3.1-handoff, HEAD 317e7fb, ahead of origin by five. Five modified files plus untracked 3.3 screenshots/reports were preserved in external history.bundle, uncommitted.patch and reports copy at C:/Users/ASUS/ervi-hub-preservation-20261114-011502. Commit e87064c preserves the pending edits and evidence. No main changes, resets, clean or force push.

Implemented: factory ESP labels 12px; explicit saved 20px/custom preferences preserved. Separate white/black-outlined names above heads and distance below feet; white skeleton unchanged. Factory pink chams become white, custom relation colors remain intact. GUI overlay DisplayOrder raised from 200 to 351; input interception/global layering not fully verified. Main opens centered each time, session-local dragging ignores legacy winX/winY without deleting settings. Native preview follows white skeleton/outlined typography.

Actual renderer baseline is Auto=30Hz, manual 10/20/30/60. Preserved exactly; historical motion-adaptive 10/30 docs were stale. No interpolation implemented in this checkpoint.

Tests: baseline 160 unit/524 smoke; final 161 unit/527 smoke, zero failures. Both artifacts compile. Consecutive builds deterministic. New regression checks cover separate labels, 12px default, explicit 20px save/load, default rate, custom chams colors and recenter after displaced hide/reopen.

Studio: unpublished ErviUITest.rbxlx, PlaceId 0, Client/Server. Fresh temporary module harness loaded; two owned R6/R15 rigs created only in Play mode. Screen capture Ervi33Labels shows both names above heads and distances below feet, white skeleton, black outlined 12px type. Screen capture Ervi33Recenter shows centered GUI after native RightShift hide/show with prior deliberate displacement. Before/after centered position {0,13},{0,87}, viewport 810x675. Screenshots are in tool/chat captures; filesystem saving rejected by automatic tool review (payload >64000 bytes), so no new screenshot files claimed.

One five-second Studio comparison: overlays ON 299 frames, mean 16.7045ms, p95 18.2369ms; OFF 299 frames, mean 16.7214ms, p95 18.5797ms. ON effective rate 30Hz, 2 targets, 30 projections/28 rays per update, max update 4.6198ms. No significant improvement/locked 60fps claim. These measurements concern source checkpoint 19476c17cbf8 before final preview-only polish; final bundle 3.3.0+5ba5f7088681 requires complete live regression.

Movement/Click TP/Tracker retain prior implementation and historical evidence. No new server movement or wall visibility bypass added. Target-game teleports, flight, noclip and protection remain unsupported. No new physical SendInput or full target-game regression completed. Smoothing, variable refresh benchmarks, full layering/hit-test proof, authorized movement regression and complete release verification remain outstanding. Do not tag this as a completed release.

Final bundle SHA256 3b549053c5bd767b0c50d82e99b7c16310c9a4eb6979fb193ba4e44fdb595a89.

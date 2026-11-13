# Ervi Hub 3.3 live continuation

Continue f577e07 on dev/ervi-hub-3.1-handoff under the user's 2026-11-13 phased specification. The supplied specification authorizes autonomous implementation/testing/deployment; no additional plan approval is needed. Preserve main, existing settings, Auto Roll guarantees and visibility/server-validation restrictions.

## Design and dependency decisions

- Reuse native Ui, FeatureSchema, Scope, FloatingWindow and the existing renderer. Audit references as text; do not execute remote libraries or copy code with unclear licensing.
- Begin with screenshot-guided live GUI tests and fixes. Add a menu-owned, bounded diagnostic export to support repeatable live verification instead of unrelated executable probes.
- Rebuild skeleton geometry from actual rig joints/part positions and cache character lifecycle state. One shared update manager; white skeleton and 20px white outlined names by default, preserving explicit user preferences.
- Keep Click TP preview functional everywhere supported. Actual movement must go through an explicitly authorized server adapter. A client-only MoveTo/CFrame write is not authority proof.
- Unify flight rather than duplicating deprecated BodyMover scripts. Implement modern constraints and independent collision ownership only in an authorized environment. No movement-validation/collision bypass in RNG RollAttacks. Use an unpublished owned Studio server fixture to verify server-recognized movement and restoration if the target game exposes no permitted adapter.
- Player Tracker is an embedded Player-page component, with cached rows, event-driven discovery and throttled health/distance updates. Selection is real; unsupported player teleport is disabled. An embedded card avoids another overlapping floating GUI.
- New defaults apply to fresh settings; preserve explicitly saved bindings/appearance, including NONE. Defaults L/N/LeftControl must not steal existing keys. Flight descent and Click TP hold must not act simultaneously.

## Ordered slices

1. A1: Capture current live state, preserve user files, audit actual GUI interactions, fix confirmed defects and export diagnostic state from the existing menu.
2. A2: Verify status opacity 0/25/50/75/100, logo scales, key capture/search/sliders/numeric/dropdowns/drag/resize/notifications/floating panel. Commit evidence and focused fixes.
3. B1: Specify/test rig geometry and text defaults; cache character lifecycle; improve white skeleton and readable centered labels.
4. B2: Verify R6/R15/movement/occlusion/respawn/cleanup, actual screenshots and before/after measurements; commit.
5. C1: Update new-config hold key/default and range controls; integrate explicit authority capability and one-request action path without changing preview safety.
6. C2: Test actual live preview/GUI suppression/rebind/respawn; verify legitimate teleport only in the authorized server environment; commit.
7. D1: Pure movement validation and explicit server protocol/capability contract; no target-game remote guessing.
8. D2: Authorized Studio constraint controller, independent collision ownership/restoration, death/removal/timeouts and server tests.
9. D3: Hub flight speed/key and independent Noclip controls/status, key conflicts, scoped client input and cleanup. Verify supported environment; clearly disable unavailable target-game actions; commit.
10. E1: Cached tracker model/sorting/selection/lifecycle and unit tests.
11. E2: Embedded themed tracker rows/health/distance/state/unsupported TP status; integrated smoke, resize and actual GUI testing; commit.
12. F: Full unit/smoke/compile/deterministic validation, documentation/evidence, backups/deployment/hash checks, dev push and immutable remote verification/loader.

## Verification and limits

Each behavior change receives a failing regression before the fix where meaningful, then the focused suite/build and native verification. Reversible visual-only corrections use native before/after evidence. End-to-end integration uses the full suite. Native Windows SendInput is distinguished from Studio input, VM callbacks, and headless mocks. GPU/presented frame timing is not inferred from Heartbeat. Record unsupported authority precisely and continue independent work.

Acceptance: requested controls perform real supported actions; no duplicate workers/GUI/drawings/physics controllers; no stuck collision/PlatformStand/constraints after disable/death/unload; settings preserved; all tests compile/pass; authorized dev artifact deployed and remotely hash-verified. Physical features unavailable in the target game must not be represented as verified gameplay.

# Ervi Hub 2.6.1 — fixed Safe Zone

The owner supplied screenshot XYZ **278.78, -16.30, 7.82** and asked to remove position setup, move there on enabling Safe Zone, and default the key to NONE. This supersedes the prior reference-only action. The screenshot contains no orientation; movement preserves the character's current orientation instead of inventing a saved one.

Started from clean commit `b4213d6cd8830b0cd688ec666539bddf28cb957b`; backed up the working tree to ignored `backups/pre-2.6.1.tar.gz`. Reproduced the previous 99 unit tests and 245 smoke checks before editing.

## Changes

- `SafeZoneState.preset` defines the fixed place-scoped coordinates. `SafeZone` uses the existing game-side character/root, checks the place and live character, then makes a single Model:PivotTo translation by the root's displacement. Orientation and model offset are preserved. No anchoring, physics writes, extra remotes or repeated movement are used.
- The Safe Zone menu has one Enable Safe Zone toggle plus coordinates/distance, action status and key display. All capture/replace/clear setup controls are removed. Failed moves remain OFF with an error; OFF itself does not move. There is no deferred action on character loading. Character removal and hub unload reset the session toggle without movement. The ON state is not persisted, so script reload cannot unexpectedly move the user.
- The new `safeZoneKey` setting defaults to `NONE`. Legacy `safeKey` reference bindings and `safeZone` coordinates are ignored rather than reused for a new movement action. Settings supports key capture, Esc cancel, Backspace clear-to-NONE, GUI key conflicts and typing guards. Only the assigned key is persisted.
- Manual target selection uses the fixed destination without asking for setup. Movement to targets, floating and Auto M1 remain unavailable. Auto Roll recovery is unchanged and never automatically activates Safe Zone.
- Updated AGENTS.md to reflect the latest explicit one-shot movement request while retaining the ban on repeated movement, server-correction bypasses and invented game APIs.

## Verification and limits

**101 unit tests and 256 smoke checks pass.** Both generated artifacts compile. Unit tests cover exact coordinates/place scope, NONE default, legacy migration and key persistence. Integrated smoke tests cover removed setup controls, no move on loading, exact root displacement, orientation preservation, one move per activation, no correction-fighting/holding loop, no movement on OFF, wrong-place/dead/error rejection, key conflicts/rebind/unbind/typing, no deferred respawn movement, and unchanged target/Auto Roll/lifecycle behavior.

The mock engine models PivotTo translation and failures against the checked API schema; it does not establish that a real game server accepts the move or that the photographed spot remains safe. Status explicitly says local move requested and server acceptance unverified. No bypass, retry or correction countermeasure is implemented.

Desktop Commander/Windows tools remain absent. No live Roblox or Potassium testing was performed; Windows script/workspace copies and the autoexec directory were not modified. The user's authorized existing GitHub repository is the deployment destination; verify its immutable raw bundle after pushing. See README/CHANGELOG for the final build ID and checksum.

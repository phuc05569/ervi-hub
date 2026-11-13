# Ervi Hub 2.6.2 — stop falling at Safe Zone

The owner reported that enabling Safe Zone moved them to the destination but let them fall. Version 2.6.1 intentionally translated once without supporting the character against gravity. The latest request changes the expected behavior to hold while enabled.

Started from clean commit `2fc68ace73c4f8ef6476c92faf3760ac4611ebd1`. Created ignored backup `backups/pre-2.6.2.tar.gz` and reproduced 101 unit tests / 256 smoke checks before edits.

## Implementation

`PositionHold.acquire` snapshots the root's Anchored property, anchors it before movement and clears AssemblyLinearVelocity/AssemblyAngularVelocity. Failed movement rolls back the hold. Release is idempotent and restores the original anchor state while leaving old falling velocity cleared. If another actor already unanchored the root, release preserves that new physics state rather than overriding it.

`SafeZone` owns the release callback and listeners in a detachable Scope. Enabling performs one local move to the existing fixed XYZ, then holds without a per-frame loop. Disabling, death, root/character removal, hub unload and rerun release physics and connections. Loading/respawn does not reactivate it. External unanchor or displacement beyond tolerance releases the hold; no repeated movement or correction countermeasure is used. Key behavior/default NONE and the remaining features are preserved. The menu and documentation now describe holding rather than the obsolete one-shot-only behavior.

AGENTS.md records the latest requested hold as superseding the former no-anchoring constraint. This is local client physics, not proof of an authorized server mechanic or a server-designated protected area. No new remotes or automatic attacks are added.

## Validation

- **106 unit tests / 271 smoke checks pass.** The five new pure hold tests cover anchor-before-move, zero falling/spin velocity, release, pre-existing anchors, failed movement rollback, idempotency and respecting external unanchor.
- Integrated smoke tests check active anchoring, OFF/key release, move-failure rollback, death/character-removal/unload/rerun cleanup, no repeated teleports, external correction release, and unchanged key/target/Auto Roll behavior.
- Both release and loader compile with Luau 0.746. PositionHold passes CLI analysis. Deterministic outputs, rollback backup and original baseline are verified before release.
- Mocks verify property transitions and lifecycle against the real API schema; they do not simulate Roblox networking or establish live server acceptance.

Desktop Commander and Windows access remain unavailable. No live Roblox test or Windows/Potassium file deployment was performed. The user's authorized existing GitHub repository receives the update, with an immutable raw artifact verified after push. Live server correction can still release the hold; the feature deliberately does not fight it.

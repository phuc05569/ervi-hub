# Ervi Hub 2.5.0 continuation — 2026-11-13

## Work and evidence

Started from clean branch `work`, commit `6cb5283ada65df3acf33df2beb3bb74904de1c32`. Read the complete HANDOFF, README, changelog, audit ledger, relevant source, build and test infrastructure. Backup: ignored `backups/pre-2.5.0.tar.gz`, created before edits. Reproduced 40 unit tests / 184 smoke checks and release compilation before development; the original 2.4.0 bundle matched its recorded SHA-256.

Implemented `src/M1State.luau` and `src/M1.luau`, integrated through `src/App.luau` and `build.py`. The HUD observes the local player's AttackReadyAt with GetServerTimeNow and displays the uncertainty in the HUD itself. It uses character/attribute events and only renders the enabled overlay at 10 Hz. Combat adds local health percentage. Style/Tool changes and respawn invalidate earlier samples; invalid clocks/attributes never imply readiness. No attacks or new remote requests are sent. The matching Tool name is required; no name aliases or Character/Tool cooldown attributes are guessed. Cyborg V6 stays an independent, explicitly estimated fallback.

The requested universal live semantics cannot be established from this checkout: the historical handoff contains no AttackReadyAt capture or defining game code, and there is no connected Roblox client. The implementation is a candidate adapter for any style, not a claim of validated universal support. A live capture must confirm attribute owner, units, clock and update behavior across styles. Negative, zero, nonnumeric, infinite and ±120-second-outlier samples are rejected. Conservative invalidation may leave UNKNOWN until the next attribute update after equipping.

Keybinding, typing guards, opacity, appearance persistence and window resizing were already implemented and passed the reproduced tests. Preserved them. Reviewed AutoRoll and RollAdapter; request exceptions/disconnections pause, uncertain results never retry automatically, and late results/qualifying results retain the existing stop safeguards. No Auto Roll behavior change was justified by available evidence. No wallhacks, teleports or attack automation was added.

Implemented `src/Loader.luau`, source configuration `loader.json`, and a generated `build/loader.lua`. The core has injected transport/compiler/time dependencies for tests. It accepts only an HTTPS raw GitHub URL pinned to a full commit, rejects path traversal, bounds download attempts and response size, requires the exact expected release banner, and guards duplicate loads of the same version/URL and concurrent loads. A changed version/URL permits an update. Compilation/runtime errors are not retried. Partial startup is cleaned up without stopping a previous hub on download/compile failure. The actual hub owns replacement cleanup. Unload still uses its returned stop handle or `_G.RNG_HUB_STOP()`.

The generated loader has a blank URL, makes no HTTP requests by default, and includes no credentials, clipboard modification, cache or public teleport loader. Existing Session behavior still queues the local workspace file only. Public source is copyable. Banner/version checking is structural, not a signature or sandbox. GitHub HTTPS and a trusted immutable commit are the distribution trust boundary. Do not publish before approval, full secret/history review and selection of the distribution repository. Prefer a private development repo plus a separate public artifacts repo.

## Current validation

- 68/68 unit tests: original 40 plus 12 M1 state and 16 loader cases.
- 210/210 smoke checks: original 184 plus 22 M1/lifecycle and 4 generated loader wrapper checks. Original assertions remain active.
- Compile the release bundle and emitted loader with Luau 0.746: pass.
- Repeat build produces the same bundle, source map and loader bytes.
- `luau-analyze` on the new pure modules: no errors; new Roblox adapter reports only CLI-unknown Roblox globals (`game`, `Enum`, `UDim2`).
- Heuristic credential-pattern scan over all reachable Git history blobs and new source/config found zero matches. This is not a guarantee or publication approval; re-review the final distribution contents before publication.
- Original Cyborg source and baseline are unchanged. Baseline SHA-256: `584c4f5babfccf407487a8569eb8f4a7309a9029975e9fa5f5269d67227fb4aa`.
- New smoke coverage exercises actual HUD widgets, two simulated styles, cooldown replacement, removal/re-equip, death, respawn, late/missing attributes, clock rejection, overlay close, rerun and no leaked threads/connections.
- Existing double-Run-mid-initialization test caught a new cleanup regression during development; fixed by respecting the closed hub before creating detached scopes and registering final cleanup after initialization. Test passes in the final build.
- Smoke API input is the checksum-verified, pinned Roblox Client Tracker dump documented during onboarding; canonical setup.rbxcdn.com remains policy-blocked. This is offline API compatibility evidence.
- Wrapper smoke checks deliberately enforce the unpublished/blank loader configuration. Update distribution-specific tests when publication is explicitly approved.

## Capability and deployment limits

Desktop Commander is absent from the available tools; no authorized Windows device listing or connectivity operation is exposed. It is not in the installable plugin catalog for this session. Connect it in a client/session that offers it to permit Windows filesystem and process work; terminal access here reaches Linux only. No Windows files, installed app versions, Potassium settings or autoexec directory were inspected or modified.

Applied the cloud-desktop diagnostic skill. Managed executor `ccarenv_b64_Y2NhcmVudl8xNjlmNDA0MGJhOTQ4MTkxYjg4OGIwMDc3YTU5MWIxYw` reports remote_desktop enabled, state unknown; neither a desktop JavaScript/computer-control tool nor an open-in-Codex tool is exposed. This does not establish that Computer Use is installed or enabled on the user's Windows client. Account eligibility, application version and Windows permissions cannot be inspected here, so the cause of the missing “Any app” section remains unresolved. No Notepad or GUI control was claimed or tested.

Read-only Git access to origin worked during onboarding. A fresh GitHub API repository-metadata request in this continuation was denied by the network proxy (CONNECT 403); current repository visibility could not be verified. Its private status is historical only. No visibility changes, repository creation, public publication, or push was performed. Changes are preserved in a local commit for review.

No live Roblox tests were run. Both `%LOCALAPPDATA%\Potassium\scripts\Ervi_Hub.luau` and `%LOCALAPPDATA%\Potassium\workspace\Ervi_Hub.luau` remain unverified and were not updated. The autoexec-folder requirement remains empty; no deployment script writes there.

Next live evidence: after deploying the verified bundle to the two confirmed Windows paths, Run it once, enable the M1 HUD, then start Diagnostics capture and manually attack with two styles; Copy report. Check Tool names, AttackReadyAt owner/units and server-time offsets. This is the remaining evidence needed before claiming live all-style support.

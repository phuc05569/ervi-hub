# Ervi Hub 3.0.0 — screenshot-driven interface and features

Started at clean commit `100a74ecc9b99a92f0833ee7d5f3090f01d26b33`. Created ignored `backups/pre-3.0.0.tar.gz` and reproduced **106 unit / 271 smoke checks** before edits. Read the handoff, development rules, current continuation and relevant source/tests. The three new pasted request files have identical SHA-256; the message displays 16 visual references. Their complete control inventory and status mapping are in [UI_FEATURE_CHECKLIST.md](UI_FEATURE_CHECKLIST.md).

## Architecture and delivered behavior

The original codebase and lifecycle remain intact. `App` integrates twelve main sidebar entries with retained Auto Roll/Styles/Diagnostics/Session tools, profile footer, current-page header, real registry search, responsive main-window geometry and a dedicated Config page. Original native logo/gradient and the Bloom/rose palette replace any need for borrowed artwork. Existing themes, opacity, M1 HUD and Safe Zone controls remain available.

`BootLog` records real initialization stages and retains the previous run in `Ervi_Hub_boot.txt` when file APIs work; copying it does not substitute invented initialization prose. It is bounded and file errors are nonfatal.

`FeatureSchema` is the single persistent setting/control catalog for new features; `Settings` extends defaults, ranges, choices and format validation from it. Each real shared component exposes its mounted node and registers title/description/section/page for global search. `Registry` supports multiword literal search, exact ranking, removed-control pruning and Russian label folding. Search opens from configurable Ctrl+K, supports result navigation/highlight and keyboard selection. `Ui` reuses toggles/sliders/actions/text inputs/grids, adds segmented choices/dropdowns/tooltips, scoped optional 120 ms native tweens and interface localization. Existing FloatingWindow remains the common panel/HUD contract.

`Locale` supplies EN/RU interface labels without translating diagnostic evidence, names or game/API values. English descriptions without a translated label remain verbatim; this is not advertised as a translation of all external/diagnostic content.

`PropertyOverrides` reads back normalized engine values, guards self-write signals, snapshots only owned properties, restores only if they still equal the feature's last write and retains restoration when an update fails. It preserves later game changes. `World` uses it for independent lighting/time/atmosphere options and camera/input ownership. Blur is a separately owned effect, present only while configured and the main window is open. Freecam binds character movement input while active, uses RMB plus WASD/QE, and restores camera/input on disable, character/camera replacement or unload. No character flight is used.

`PlayerTools` implements local Humanoid speed, Set/Multiply against the character's original base, a configurable activation key, and a saved movement panel with size control. Death/replacement/disable releases owned values. A game speed correction is preserved rather than fought in a polling/CFrame loop. No supported noclip, fly, infinite jump or CFrame speed bypass is claimed.

`Visuals` creates native GUI overlays only for live targets with a visibly rendered head and a clear camera-to-head line. Skeleton endpoints also require clear lines; fully invisible/occluded targets are suppressed. Highlights always use Occluded depth. Boxes/corners, health/name/distance, skeleton/head dot, tracers, clear-line off-screen arrows, team/friend filtering and palettes have separate state. Friendship queries are cached per player and cancelled/isolated by scope. Behind Wall color and hidden-target demonstration apply only to the original native sample in `VisualPreview`.

Scheduling uses motion-adaptive 10/30 Hz Auto or explicit 10/20/30 Hz, a hard target cap, per-rank skeleton budget and full/far redraw cadence. Eligibility and occlusion are still checked on update ticks before retaining slower drawings. Cheap boxes use root/head projections; full boxes project model bounds and guard the near plane. Drawing records are reused, excess/invalid/departed targets are removed, and skeleton resources allocate lazily. The overlay reports per-update projection/raycast counts. No unconditional RenderStepped loop or executor Drawing API is added.

`RuntimeActions` shares rejoin, bounded server-hop listing/selection, Job ID copy, reinjection compatibility and FPS-cap management across Home/Utility/Teleports. Server-hop errors remain visible and never invent a destination. FPS cap zero leaves/restores the prior setting. Positive cap control is disabled without both getter and setter; restoration respects later external changes.

Home adds native avatar/game thumbnail URLs, measured hub-session data, player/server count, ping, static ring segments updated with FPS, actual enabled-feature chips, user-configured-only community UI, presence-only capability diagnostics, and copy/clear logs. There is no third-party invite/RPC or automatic clipboard modification.

Config retains legacy named/plain files and global autoload while adding explicit slot selection, save/load/delete/rename, per-PlaceId autoload and bounded `ERVI_CONFIG_V1` import/export. Imports are validated data, never executable Lua. New keys round-trip and invalid enum/color/numeric values fall back safely. Session-only Safe Zone activation remains unpersisted; the existing key defaults to NONE.

## Unsupported and reference-only scope

The master task excludes unauthorized movement/collision bypasses, wallhacks and automated PvP attacks. No authorized game APIs for CFrame speed, noclip, fly or Triggerbot are established in this checkout, so those settings are explanatory disabled sections. Fly modes/key/speed are included in that tracked limitation. Through-wall chams and dimmed hidden players are not implemented; clear-line/occluded rendering is the supported alternative. Mobile/native rendering is always used, so a second renderer toggle would be redundant.

Sounds and detailed Friends contents were not shown; their tabs provide scope/compatibility information without speculative systems. Roblox friendship filtering is implemented. The pre-existing owner-requested Safe Zone local translation/hold is preserved without expanding its behavior or claiming server authorization. No repository visibility change or new public distribution repository is created.

## Actual validation

- **127 unit tests and 423 smoke checks pass.** Original regression assertions remain, with navigation selectors updated for the redesigned labels/structure and precise color-picker selectors after adding other hex inputs.
- Every catalog control is asserted to mount on its real tab. Every catalog field round-trips through non-default schema sharing. Search handles real registered controls, removed instances, ranking, literal queries and Russian labels.
- Integrated tests drive main resize, Ctrl+K/search navigation/highlighting, language change/restore, config rejection/import/export/autoload, blur ownership, lighting/late Atmosphere restoration, freecam movement/reset/replacement/input cleanup, local speed Set/Multiply/respawn/correction handling and movement-panel persistence.
- Rendering tests cover visible/invisible/occluded targets, Occluded highlights, real raycast/projection invocation in the mock, three simultaneous players, hard target cap, cheap/full boxes, skeleton budget, off-screen arrows, maximum distance, friendship/team rules, departure cleanup and concurrent world/camera/rendering ownership.
- Runtime tests cover unsupported FPS APIs, compatible getter/setter behavior, zero/unload restoration, later external cap changes, failed HTTP, successful server-list selection excluding full/current servers, and bounded requests.
- Both generated artifacts compile with checksum-verified Luau 0.746. New pure modules pass CLI analysis. Roblox adapters have the CLI's expected unknown Roblox/executor-global diagnostics; no additional unresolved adapter type errors are claimed away.
- Build determinism, pre-edit rollback archive, original baseline checksum and heuristic credential-pattern checks are verified before release. These scans are not a guarantee of absence of all secrets.

Performance observations are limited to deterministic budgets, observable mock query/drawing counts and resource cleanup. There is **no live FPS, GPU, mobile-layout or server-network benchmark**. Native tween behavior has a direct-update headless fallback; tests do not prove its live timing or rendered visual quality. A real Roblox visual/compatibility pass remains necessary.

## Deployment and remaining verification

Desktop Commander, authorized Windows devices, PowerShell and graphical app-control tools are absent from this session's tool discovery. Only the Linux checkout was edited/tested. Inline screenshots supplied the visual reference; Windows paths were not read. No live Roblox/Potassium interaction or local script/workspace copy was performed; the autoexec directory was untouched.

The user has authorized commits/pushes to the existing repository. Verify the exact remote commit and immutable raw artifact after pushing; branch raw URLs have previously cached old builds. Review README/CHANGELOG for the final build ID/checksum. Remaining work is a live visual/game/executor pass and any future owner-provided authorized APIs for the explicitly unsupported mechanics—not silently enabled placeholder features.

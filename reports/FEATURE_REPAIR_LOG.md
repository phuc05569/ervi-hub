## Owner manual-testing repair pass — 3.5.0-dev+6abfd1dd3905

**IMPLEMENTED — OWNER TESTING PENDING.** Source review identified persistent A anchoring/PivotTo versus the working shared transport, and a terminal readiness timeout for known temporary roll gates. A now uses the transport without a hold; B alone owns bounded stabilization. Preserved recovered configured coordinates rather than guessing a rollable spot. Removed coordinate editors/named positions, set fresh WalkSpeed to 50, fixed keybind notifications and retained Toggle Fly across focus loss. Existing settings/data and evidence are preserved. Owner reports prior Click TP/emergency/B protection/speed success; this does not verify these new changes. Only the normal build is run; no tests, benchmarks, input automation, deployment or push.

### Earlier repairs and evidence follow

---

# Functional repair log — 14 November 2026

Development baseline: v3.4.0, commit 2b93389, clean `dev/functional-audit-3.4`.
Preservation: `C:\Users\ASUS\ervi-functional-preservation-20261114-052242` includes all-ref Git bundle, sources, generated build, evidence and settings. No production deployment or push is authorized by this request.

## Click TP

Root cause: movement was gated entirely on an unpublished Studio protocol; other places only selected a preview. The owner-supplied WeAreDevs source uses native `Model:MoveTo`, not a server remote. Added an independently written native one-shot adapter, a fresh click-time ray, in-flight exclusion, bounded position observation, lifecycle cancellation and correction reporting. It does not retry corrections or claim server acceptance.

Regression: the new headless local-movement assertion failed on the previous implementation, then passed. Rapid-click exclusion passes. These observations use a mock engine, not target-game replication.

## Destinations and emergency

Separate place-scoped A/B storage, finite manual coordinates, capture/save/reset/test controls, data-only position save/rename/delete/copy, inclusive 30% default emergency trigger. Emergency latches until health exceeds threshold or character changes. No B coordinate is invented, no ForceField or invulnerability is created. Original A scoped hold and return behavior remains.

Current automated checkpoint: 178 unit / 557 smoke passed, zero failures. Live acceptance is pending. The first Click TP slice compiled both artifacts; subsequent integration must compile again before completion.

## Source mechanisms studied

Retrieved as text and inspected; none executed or added as a runtime dependency:

| Reference | SHA-256 of fetched bytes | Findings / reuse policy |
|---|---|---|
| [WeAreDevs Click Teleport](https://cdn.wearedevs.net/scripts/Click%20Teleport.txt) | `ff6d9994388f8df3e407b8c36f11aad60e09bfe9323d011cae3cc309af30f385` | Native character MoveTo behind Ctrl + left click. No server remote. Source bears WeAreDevs copyright; no reuse license established, so use as behavioral reference, retain attribution, no copied standalone GUI |
| [carsman70 Fly-Noclip](https://raw.githubusercontent.com/carsman70/Fly-Noclip/refs/heads/main/Index.html) | `3a88d8538d0c239a26f53b339e9fb73be89021cd97a5f31d75e5fba35af7ebe6` | Local velocity/orientation control, camera-relative smoothing and repeatedly maintained CanCollide flags. Its broad collision restore and default speed writes are unsafe to transplant. License API returned NOASSERTION; independently implement the understood mechanisms through scoped ownership |
| [Infinite Yield](https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source) | `e9852d2c5d7f2388c1242ec9e1f8fbbbc5b825923b508c9dfa24e9bfc20f3e0a` | MIT license confirmed. `speed` writes Humanoid speed; `loopspeed` reconnects a change enforcer across respawn; `unloopspeed` disconnects it. Ervi uses explicit Set/Multiply ownership and releases game speed changes, without spoof hooks or loopspeed copying |

Roblox's [Model documentation](https://create.roblox.com/docs/reference/engine/classes/Model#MoveTo) confirms the native movement method. Using it is not proof of unrestricted server authority. Content hashes identify the fetched references even if their branch URLs change later. Full downloaded sources stayed in the temporary reference folder; no unrelated UI/promotions/dependencies were imported.

## ESP and settings

Added budgeted cached native avatar headshots and readiness fallback, high/low health colors and darker underlays. Renamed/inverted Through Walls to Visibility Mode with explicit-new-key precedence; removed unused team filters/colors/chams exclusion and hidden-preview/wall-color sample. Preserved friends, Auto → 60, explicit rates, 12px labels, white tracers/chams and outlined thin skeletons. Thumbnail readiness uses an event and caches clear on renderer stop/leave.

Generic Ui.button down/up animation ignored FixedBackground, explaining gray color swatches. All press/hover/release paths now preserve fixed backgrounds; color control refresh restores exact colors/selection. Reused the existing HSV wheel lazily, including brightness and hex persistence.

## WalkSpeed, native movement and bindings

Reproduced failures for fresh Multiply default and stale enabled state after game speed changes, then fixed both. New configs use Set, explicit Multiply remains. Only the applicable slider is displayed; floating panel mode matches. Requested Humanoid speed and observed horizontal velocity remain separate. Duplicate Humanoid watches are guarded.

Native Fly uses scoped LinearVelocity/AlignOrientation, camera input and time-independent exponential smoothing. Fly-off removes forces, clears owned velocity, restores PlatformStand/AutoRotate, and leaves independent Noclip state intact. Noclip adapts the reference's local collision maintenance to one scoped PreSimulation connection and cached parts, with original true/false restoration; it does not change map geometry or fight server position corrections. This maintenance is required because ordinary Humanoid simulation can reset local collision flags. The owned server fixture remains a separate adapter and is unchanged.

Centralized Toggle/Hold/Always/NONE handling; Held state is released on key-up/focus/rebind/unload. Defaults F / NONE / NONE / NONE for Fly/Noclip/WalkSpeed/Safe Zone; Ctrl + M1 remains separate. Explicit saved keys/modes persist subject to conflict resolution. Rebinding ignores Unknown keypresses and typing.

## UI functionality and lifecycle

Added only basic functional controls. Existing design, typography, branding and main geometry remain. Background presets plus validated Roblox asset inputs retain the native background on failure/timeout; arbitrary HTTPS execution/download is not used. Notifications moved from the menu into their own themed viewport ScreenGui, bottom-right, default 1 second, max three, immediate disable cleanup, visible while minimized. Own GUI cleanup now includes the notification root.

## Live defects and final checkpoint

The Studio server test initially rejected B with Invalid landing surface: saved root XYZ had been sent to a ground-hit protocol. Click TP also added a height allowance to the request range, exceeding the fixture's max 500. Fixed the adapter's ground conversion/range clamp without weakening server validation. Replaced B's text-parsing success inference with an explicit observer/server outcome. The final owned-server B test passes.

Emergency now handles MaxHealth and threshold changes, late roots, recovery while disabled, already-at-B events and a fresh drop after moving away. It does not repeat low-health moves or return from B automatically.

Final candidate `3.5.0-dev+b391196c1bb3`: **181 unit / 602 smoke, 0 failures; both artifacts compile; 20 native Studio controller checks pass**. Native Ctrl + M1 replication was observed later on the owned Studio server; immediate replication was delayed. Actual target-game acceptance remains open. All failures and intermediate evidence are retained; full classification and remaining gaps are in FEATURE_FUNCTIONAL_AUDIT.

## Final integration review

A new regression reproduced manual target selection becoming unavailable after selecting an unconfigured B. Preserved the legacy `saved()` API default to A while selected-zone descriptions explicitly request the selected zone; the regression now passes. Final smoke count is 602.

A final native run observed one post-flight/startup movement correction and correctly stopped without retry. Its failed live assertion is preserved in `studio-final-correction-detected.json`. An isolated move succeeded; a separate post-flight physics probe showed Running state, restored body collisions and stable position after 100ms and 600ms. The correction's cause is not established. Temporary movement traces were added only to the test script, not the runtime. Do not interpret subsequent successful runs as proof that every move will be accepted.

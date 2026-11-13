# Functional handoff to Claude Code — 14 November 2026

Preserve the current 3.4 visual system. This continuation adds functional controls; it does not redesign the window, sidebar, logo, typography, palette, glass, or animations. Published v3.4.0 remains available. Work is local on `dev/functional-audit-3.4`; no push, deployment, or release is approved.

## Current code and evidence

Candidate **3.5.0-dev+b391196c1bb3**, `build/Ervi_Hub.luau`. Edit `src/` and run `build.py`; never edit the generated bundle. Read `FEATURE_FUNCTIONAL_AUDIT.md`, `FEATURE_REPAIR_LOG.md`, `MOVEMENT_AND_SAFEZONE_TESTS.md`, `COMBAT_FEASIBILITY.md`. The exact runtime catalog and all defaults are in `evidence/functional-3.4/settings-catalog.json`. It was exported from the final Studio candidate, not inferred from screenshots.

## New / changed settings contract

| Keys | Values / defaults | Controller and callbacks |
|---|---|---|
| `clickTPEnabled`, `clickTPKey` | false; LeftControl + M1 | `ClickTP.apply/keyDown/stop/snapshot`; M1 remains a mouse action |
| Existing `clickTPRange/Size/Opacity/Color` | Existing explicit values preserved | Marker updates at 30 Hz while held; fresh click-time ray; no GUI activation |
| `safeZoneLocations` | Empty data-only string; entries A/B include place,x,y,z | `SafeZone.saved/saveLocation/select/setEnabled/describe`; `onChanged` synchronizes original toggle |
| `emergencyEnabled`, `emergencyHp` | false, 30; range 0–100 | `SafeZone.checkEmergency`; `EmergencyState` latch, HealthChanged/MaxHealth/character events |
| `savedPositions` | Empty data-only string, max 64 valid names | `PositionData` encode/decode/expression; `LocationControls` captures, renames, deletes, copies |
| `speedMode` | **Set** for new configs | Explicit saved Multiply preserved; actual state owned by PlayerTools |
| `walkKey`, `noclipKey`, `safeZoneKey` | NONE | Functional GUI controls remain available |
| `flyKey` | **F** for new configs | Existing compatible explicit saved key retained |
| `flyKeyMode`, `noclipKeyMode`, `walkKeyMode`, `safeZoneKeyMode` | Toggle; options Toggle/Hold/Always | `Keybinds.press/reconcile`; release Hold on key-up/focus loss/rebind/unload |
| `iconESP`, `iconSize` | false, 28; 16–64 | `Visuals`: cached native rbxthumb images, circular mask, '?' fallback, projected head anchoring |
| `visibilityMode` | false | ON = unobstructed only; OFF = no line-of-sight restriction. Legacy throughWalls migrates with inverted meaning. Explicit new key wins regardless of line order |
| `healthHighColor`, `healthLowColor` | #00FF00, #FF0000 | Green above 50%; red at/below 50% |
| `healthHighOutline`, `healthLowOutline` | #006600, #660000 | Dark full-track underlay; independently editable |
| `backgroundImage`, `backgroundImageOpacity` | empty, .25 | `ImageSource.normalize`, `Background.apply/status`; rendered alpha also follows menu opacity |
| `notificationDuration` | **1 second** for new configs | Existing explicit duration remains; independent `Ervi_Notifications` ScreenGui, bottom-right |

All setting changes use the existing debounced `savePrefs`. Named profiles/autoload survive, Config page stays removed, protected pre-autosave backup is never overwritten. Original settings were not restored over newer geometry changes made during this session.

Fly/Noclip runtime activation resets OFF on reexecution and character removal; keys/modes persist. Always follows the current GUI enable value rather than resurrecting old physics state after a reload. A bound Hold feature is active only while its key is held; NONE keeps GUI control functional. `SafeZone.saved()` defaults to legacy A for the existing target selector; request `saved("B")` explicitly for the protected destination and use `describe()` for the selected zone.

## Controls and restyling targets

**Safe Zone:** Original state toggle/key remains. Two basic cards have XYZ fields (`ZoneA_X/Y/Z`, `ZoneB_X/Y/Z`), Capture Current Position, Save Location, Test Location, Reset Location, Deactivate Zone, saved place/coordinates and status. Test Location actually moves; keep that action explicit. A holds/returns once. B does not return and does not manufacture protection. Add clear visual separation for selected destination, observed position and game-recognized protection. B begins unconfigured.

**Emergency:** Existing schema-generated toggle plus threshold slider/numeric display and diagnostic state. Distinguish Ready, Destination missing, Triggered/observed/rejected and character loading. Recovery latch prevents repeated requests. Do not make the UI imply verified invulnerability.

**Player:** Correct speed slider is visible for Set/Multiply; the floating movement panel has matching mode/multiplier controls. `walkActive` and requested/observed speed are separate. Native `LocalFlight` owns modern constraints and scoped properties; the existing Studio adapter remains. Do not replace the central key handler with per-feature listeners.

**Avatar ESP:** Basic circular native thumbnail per drawing record; enabled only under the existing target/distance/visibility budget. Name remains above the head, icon above it, distance below feet, 12px labels unchanged. Current fallback is '?' and thumbnail readiness is event-driven. Restyle shape/spacing/outline/size, not target eligibility. Native screenshots: `studio-avatar-health.png`, `studio-through-wall.png`. These are owned fixtures, not public-player visibility tests.

**Colors:** Every schema color control has fixed-color swatches, hex entry, and a lazily created 150px circular HSV picker with brightness slider. `ColorSelected` and `SwatchHex` attributes expose state. The former gray-swatch defect was generic button down/up animation overwriting fixed backgrounds; retain the FixedBackground guards and exact restoration in `control.set`. Existing accent/text/background custom picker remains. Background presets add Black/Slate/Navy alongside Design/custom.

**Background image:** Asset-ID/Roblox asset URL/supported Asset thumbnail input only. Arbitrary HTTPS image downloading is not implemented. Native ContentProvider load result and 3-second timeout determine visibility. Keep the native theme background on failure. Loading messages are functional status, not promises that any arbitrary URL is usable.

**Notifications:** `Ui.notifications` returns `(notify, sync)`. It owns a ScreenGui under PlayerGui, independent of main menu visibility, bounded to three entries. Sync clears active notices immediately when disabled. Default expiry is 1 second plus fade. Rework spacing/appearance later without reparenting to the menu or intercepting input.

**Position tools:** Name/selection field, capture/save/copy, rename, delete and coordinate list. Copy fallback displays a Luau expression. There is deliberately no saved-position teleport control.

## Removed controls

Team Check, Show Teammates, team-only chams exclusion, team color, Preview Hidden Target and its unused wall-color demonstration. Their old keys are ignored on load and absent from search. Friend marking/color remain. Through Walls was renamed/inverted, not merely relabeled. Auto update rate remains Auto → 60, with explicit 10/20/30/60 retained. White tracer, thin outlined skeleton, white outlined text and factory-white chams remain.

## Limitations and completion gate

Auto Kill is unsupported; do not restyle an unsupported request-only preference as a working attack feature. Universal M1 retains its UNVERIFIED interpretation. Target-game movement, protection, rolling in configured zones and second-client movement replication need acceptance after approval to load the candidate. Physical Studio input passed navigation/search/icon toggle and explicit RightShift/F down/up; a numeric pointer attempt missed its field, so its successful focus/commit test is labeled scripted. Do not call every control physically verified.

Review the current validation manifest before release. Keep main, release tags, repository visibility, Potassium installs and autoexec unchanged until the owner explicitly approves the next operation.

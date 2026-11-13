> **Current 3.2 development:** build 3.2.0+4e59db554fde; 148 unit / 494 smoke pass. See [handoff](../docs/LOCAL_CODEX_HANDOFF.md) and [phase report](CONTINUATION_3_2_0.md). Inventory below the current additions is historical 3.0 material, including removed tools.

| Current component | Status | Verification / limitation |
|---|---|---|
| clickTPEnabled | Teleports / Click TP preview / false | Held targeting preview; no movement |
| clickTPKey | Hold binding / NONE | Native Studio + virtual live F8 capture; physical live input unverified |
| clickTPSize | Slider 1–20 / 4 | Persisted, searchable, real marker size |
| clickTPOpacity | Slider 0–100% / 65% | Persisted/searchable percentage and marker transparency |
| clickTPColor | Palette/hex / #F0628E | Existing validated color component |
| Official logo | Adaptive alpha strips and aspect constraint | Native Studio 18/24/48/96 at 75/100/125%; combined 230 descendants |
| Dropdown disclosure | Animated native strokes | Native Studio; removes missing font glyph |
| Status pill | Opacity, feature chips, minimize/restore | Headless and native visual 0/100 checks; live properties read |
| Visible overlays | Cached discovery and bounded record reuse | Native fixtures and actual client status; no general FPS claim |
| GUI preview suppression | GUI hit test + processed-input guard | Native Studio/smoke pass; first live target was clipped; corrected visible hit works, full live transition unproven |
| Safe Zone | Existing local transaction, clarified status | Client/server sandbox mismatch; no server protection claim |

# Screenshot feature inventory — Ervi Hub 3.0.0

The three pasted request files are byte-identical (SHA-256 `0365ad7d3b47afa65b08f98081d46383683ccd0e63f35e0ff59f47dd413023b3`). The message displays **16** reference images, despite the pasted request saying 14. The labels below follow their displayed order. Screenshot text is reference material; the pasted master task supplies the instructions. No third-party code, artwork, invitation or brand was imported.

A1 Abilities: Noclip, Fly, Fly Mode, Fly Speed.
A2 World: Lighting and Camera.
A3 Visuals: master, boxes, health, names, native/mobile rendering, distance, skeleton, head dot.
A4 Visuals: chams, enemies-only, fill and outline transparency.
A5 Visuals: tracers, origin, off-screen arrows, team/friend filters.
A6 Visuals: colour swatches, dim-behind-walls and update rate.
A7 Visuals: budgets, target/distance/text controls.
A8 Visuals: far update interval, maximum distance, text size, vertical offset.
A9 Utility: session actions, reinjection and FPS cap.
A10 Config: slots, per-game autoload and save/load/delete.
A11 Config: autoload actions and data sharing.
A12 Settings: interface keys/scale/blur, EN/RU and theme choices.
A13 Home: welcome, game, performance, community, quick actions and active chips.
A14 Home: executor capability checks.
A15 Home: further capability checks and log actions.
A16 Player: floating panel, size, character state, WalkSpeed modes, multiplier and CFrame Speed.

Statuses: **implemented / headless-tested** means the shipped implementation has schema/unit or integrated smoke coverage; it does not claim live Roblox testing. **unsupported** means deliberately unavailable under the stated compatibility/authorization boundaries. **reference only** means the screenshots show no detailed content to implement.

## Shared catalog: each real mounted setting

All rows below have a persisted setting, genuine shared control, registry/search entry and smoke assertion that it mounts on the correct page. Unit tests round-trip every field using non-default values. Adapter smoke tests are representative across each feature family; every numerical combination has not been exhaustively tested.

| Key | Tab / section | Control | Default | Implementation / verification | Limitation |
|---|---|---|---|---|---|
| `movementPanel` | player / Movement | Movement Panel | false | PlayerTools; implemented / headless-tested | Not live-tested |
| `movementSize` | player / Movement | Panel Size | 1 | PlayerTools; implemented / headless-tested | Not live-tested |
| `walkEnabled` | player / Speed | WalkSpeed | false | PlayerTools; implemented / headless-tested | Local property only; no correction-fighting or CFrame fallback |
| `walkKey` | player / Speed | WalkSpeed key | NONE | PlayerTools; implemented / headless-tested | Not live-tested |
| `speedMode` | player / Speed | Speed Mode | Set | PlayerTools; implemented / headless-tested | Not live-tested |
| `walkSpeed` | player / Speed | Walk Speed | 16 | PlayerTools; implemented / headless-tested | Local property only; no correction-fighting or CFrame fallback |
| `speedMultiplier` | player / Speed | Speed Multiplier | 1.5 | PlayerTools; implemented / headless-tested | Local property only; no correction-fighting or CFrame fallback |
| `fullbright` | world / Lighting | Fullbright | false | World; implemented / headless-tested | Not live-tested |
| `noFog` | world / Lighting | No Fog | false | World; implemented / headless-tested | Not live-tested |
| `noShadows` | world / Lighting | No Shadows | false | World; implemented / headless-tested | Not live-tested |
| `customTime` | world / Lighting | Custom Time | false | World; implemented / headless-tested | Not live-tested |
| `timeOfDay` | world / Lighting | Time of Day | 12 | World; implemented / headless-tested | Not live-tested |
| `freecam` | world / Camera | Freecam | false | World; implemented / headless-tested | Not live-tested |
| `freecamSpeed` | world / Camera | Freecam Speed | 1 | World; implemented / headless-tested | Not live-tested |
| `backgroundBlur` | settings / Interface | Background Blur | false | Ui / Expansion; implemented / headless-tested | Not live-tested |
| `searchKey` | settings / Interface | Search shortcut key | K | Ui / Expansion; implemented / headless-tested | Not live-tested |
| `panicKey` | settings / Interface | Panic key | End | Ui / Expansion; implemented / headless-tested | Not live-tested |
| `language` | settings / Interface | Language | EN | Ui / Expansion; implemented / headless-tested | EN/RU interface labels; diagnostics and game data stay verbatim |
| `fpsCap` | utility / Rendering | FPS Cap | 0 | RuntimeActions; implemented / headless-tested | Disabled without getter + setter; 0 preserves/restores prior cap |
| `espEnabled` | visuals / Player ESP | Enabled | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `espKey` | visuals / Player ESP | Visualization key | NONE | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `boxStyle` | visuals / Player ESP | Box Style | Corners | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `healthBar` | visuals / Player ESP | HealthBar | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `espNames` | visuals / Player ESP | Names | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `espDistance` | visuals / Player ESP | Distance | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `skeleton` | visuals / Player ESP | Skeleton | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `headDot` | visuals / Player ESP | Head Dot | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `chams` | visuals / Player ESP | Chams | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `chamsEnemies` | visuals / Player ESP | Chams: Enemies Only | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `chamsFill` | visuals / Player ESP | Chams Fill | 0.6 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `chamsOutline` | visuals / Player ESP | Chams Outline | 0 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `tracers` | visuals / Tracers | Tracers Enabled | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `tracerOrigin` | visuals / Tracers | Origin | Bottom | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `offscreenArrows` | visuals / Tracers | Off-screen Arrows | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `teamCheck` | visuals / Colours | Team Check | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `showTeammates` | visuals / Colours | Show Teammates | false | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `markFriends` | visuals / Colours | Mark Friends | false | Visuals + VisualPreview; implemented / headless-tested | Official friendship query cached; failures do not claim friendship |
| `enemyColor` | visuals / Colours | Enemy | #F0628E | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `teamColor` | visuals / Colours | Team | #40C492 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `friendColor` | visuals / Colours | Friend | #70AFFF | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `wallColor` | visuals / Colours | Behind Wall (preview only) | #9294A3 | Visuals + VisualPreview; implemented / headless-tested | Preview only; real hidden targets suppressed |
| `updateRate` | visuals / Performance | Update Rate | Auto | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `cheapBoxes` | visuals / Performance | Cheap Boxes | true | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `maxTargets` | visuals / Performance | Max Targets | 24 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `skeletonBudget` | visuals / Performance | Skeleton Budget | 8 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `fullRateTargets` | visuals / Performance | FullRate Targets | 12 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `farTargetRate` | visuals / Performance | Far Target Rate | 2 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `maxDistance` | visuals / Performance | Max Distance | 1000 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `espTextSize` | visuals / Performance | Text Size | 13 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `verticalOffset` | visuals / Performance | Vertical Offset | 0 | Visuals + VisualPreview; implemented / headless-tested | Not live-tested |
| `previewOccluded` | visuals / Preview | Preview hidden target | false | Visuals + VisualPreview; implemented / headless-tested | Sample only; changes preview, not live occlusion policy |

## Other visible/requested controls

| Reference | Control(s) | Module | Status / test evidence | Limitations |
|---|---|---|---|---|
| Window | Ervi branding, original logo and background, version | Theme, App, LogoGeometry | Three polygons; exact aspect and scanline geometry headless-tested | Studio screenshot unavailable; native edge smoothing remains visually unverified |
| Window | 12 sidebar tabs, icons, selected state, profile footer | App | Implemented; all 12 tab navigation smoke | Auto Roll, Styles, Diagnostics and Session remain additional tools |
| Window | Tab header and description | App | Implemented; registry-search navigation smoke | Diagnostic prose remains English where untranslated |
| Window | Drag, resize corner, min/max, screen fit, position/size persistence | App, Ui | Implemented; existing resize, viewport and normalized persistence checks | No live layout screenshot available |
| Window | Minimize and Close/unload | App | Implemented; lifecycle and panic-key smoke | Close unloads; floating panels have no redundant Close |
| Window | Opacity, scrolling, themes, responsive grids | Ui, Theme | Implemented; 0–100%, theme, text and resize regression tests | Tween code uses a direct-update fallback in headless tests |
| Window | Ctrl+K, search field, matching title/description, results, navigation/highlight, arrows/Enter/Esc, rebind | Registry, App | Implemented; unit search tests and integrated search navigation/focus smoke | Search indexes real controls; Russian labels are also searchable |
| A13 | Welcome name/avatar, game name/icon, build/session info | Expansion | Implemented; native rbxthumb URLs and dashboard refresh | Displays measured hub-session duration, not invented server-arrival time |
| A13 | FPS circle and ping | Expansion | Implemented; reusable native ring segments, status refresh | No claimed live FPS/performance benchmark |
| A13 | Player count, server capacity, Job ID | Expansion | Implemented; mock server data and copy-action smoke | Native thumbnail availability depends on Roblox |
| A13 | Community panel and sidebar link, copy invite | App, Expansion | Implemented only for user-configured HTTPS link | Hidden when unconfigured; no reference Discord copied |
| A13 | Rejoin, Server Hop, Copy Job ID | RuntimeActions | Implemented; failure and successful bounded server selection smoke | Server list uses first 100 public servers; network/API can reject |
| A13 | Active feature chips and click-to-disable | Expansion | Implemented; actual feature state, no aimbot/fly/infinite-jump chips | Only features actually active are shown |
| A14–15 | delfile, queue_on_teleport, getcustomasset, gethui, setfpscap, getfpscap, getconnections, firesignal, require, clipboard/files | RuntimeActions | Implemented; safe function presence checks | Presence is explicitly not proof of permission or execution |
| A15 | Copy Logs, Copy Boot Log, Clear diagnostic output | Expansion | Implemented; bounded live log ring plus actual initialization stages and prior boot retention | No automatic clipboard writes |
| A9 | Anti AFK, auto-reconnect, auto-execute | Session | Preserved; original session smoke assertions remain | No autoexec-folder files |
| A9 | Check Reinjection | RuntimeActions, Session | Implemented; calls existing support check | Requires queue API, file access and workspace bundle |
| A10 | Named slot/create/select/save/load/delete/rename, active/autoload status | Settings, App | Implemented; legacy slot smoke plus new sharing tests | Deletion of active config remains protected; rename is validated |
| A10–11 | Autoload per game, set selected, turn off, status | Settings, App | Implemented; per-place persistence/deletion unit and UI smoke | Legacy global autoload remains compatible |
| A11 | Copy Config to Clipboard, import input, Apply Import | Settings, App | Implemented; v1 bounded data-only import/export; invalid/code input rejection tests | Never loadstring imported data; unknown settings fall back safely |
| A12 | Toggle UI key, panic key, UI scale, opacity, blur, EN/RU, theme palette | App, Ui, Locale, World | Implemented; keybind, blur, language and theme regression smoke | Russian covers interface labels, not verbatim logs/player data |
| A16 | Movement panel drag, corner resize, saved layout, panel size, character status | PlayerTools, FloatingWindow | Implemented; movement-panel creation/resize/persistence/removal smoke | Menu-controlled; no standalone Close |
| A16 | WalkSpeed toggle/key, Set/Multiply, Walk Speed and multiplier | PlayerTools | Implemented; Set/Multiply/restoration/respawn/external-correction smoke | No CFrame fallback and no continuous server override |
| A16 | CFrame Speed toggle | Expansion | Unsupported; explanatory disabled section | No game-authorized mechanic; bypass fallback excluded |
| A1 | Noclip toggle, collision restoration and respawn behavior | Expansion | Unsupported; no collision changes are installed | No authorized collision-bypass mechanic established |
| A1 | Fly toggle/key, Velocity/CFrame mode, speed, WASD/Space/Shift | Expansion | Unsupported; requested controls documented together in disabled section | No authorized fly mechanic; no physics or CFrame bypass |
| A3 | Mobile Renderer toggle | Visuals | Native rendering always implemented; redundant toggle unsupported | There is no separate executor Drawing/mobile path |
| A6 | Dim Behind Walls | Visuals, VisualPreview | Not implemented (no dimming); preview sample only | Occlusion follows the 3.3 Through Walls toggle |
| A4 | Through-wall chams | Visuals | Owner-requested in 3.3: Through Walls toggle (default on) switches AlwaysOnTop/Occluded | Disable for line-of-sight-only overlays |
| Navigation | Triggerbot / aimbot / automated attacks | Expansion | Unsupported, disabled explanation; no active chips | Explicit task boundary |
| Navigation | Sounds detailed feature controls | Expansion | Reference only; tab contents not supplied | No speculative sound system added |
| Navigation | Friends detailed social controls | Expansion | Reference only; official friendship filtering implemented in Visuals | No speculative friend mutations added |
| Existing | Auto Roll, rarity/style targets, death recovery, Roll Observer | AutoRoll, RollAdapter, RollObserver, App | Preserved; original unit/smoke coverage remains | No new retries or overlap; no duplicate Cyborg HUD |
| Existing | Single M1 HUD, Safe Zone local hold, themes/configs/diagnostics | M1, SafeZone, PositionHold, Ui | Preserved; existing lifecycle and physics restoration smoke remains | Prior local hold is not proof of server authorization; no expansion of teleport behavior |

## Completion boundaries

All listed supported families have actual implementations and headless coverage. Unsupported operations above are not shipped as enabled fake controls. Logo source geometry and requested size ratios are headless-tested; the Roblox screenshot pass is blocked because Studio MCP reports no connected instance. No actual visual-correction claim is made. No claimed feature relies on inaccessible Windows files or unobserved live game behavior. Server acceptance, rendering quality on the owner's actual viewport, executable permissions and network access in Potassium remain **not live-tested**. No new Discord integration, third-party assets, public repository or visibility change is included.

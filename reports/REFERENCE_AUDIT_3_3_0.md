# Reference audit — Ervi Hub 3.3

Audited 2026-11-13; release work continued 2026-11-14. References were read as source, never executed as remote dependencies.

## UniversalSkeleton

[Repository](https://github.com/Blissful4992/ESPs) and [reference source](https://github.com/Blissful4992/ESPs/blob/main/UniversalSkeleton.lua). The inspected file blob was `8b0a5d7698932cc8b781aa527b151f35895d2717`, 6198 bytes. Repository metadata had no license and its root had no LICENSE file; no license permission is inferred.

The library uses Drawing lines and Motor6D links. It does not implement the requested name/distance text, and assigning Size or Static does not establish supported behavior. Its false visibility option is overridden by an `or true` expression. Toggle starts per-skeleton Heartbeat work; removal does not clearly disconnect it. Its visibility/range budgets differ from this project's restrictions. These observations motivated an independently written local implementation; the library was neither copied nor loaded.

Ervi uses native Frames/TextLabels: white text, black TextStroke, white skeleton lines, real body/joint positions and viewport clipping. Native R6/R15 screenshots and headless regressions are retained. Characters are never anchored by the overlay. No Drawing API capability is assumed.

## Movement references

The supplied MoveTo/CFrame examples do not prove server acceptance. The two flight descriptions both use legacy BodyMovers; their names do not justify duplicate controllers. Ervi instead has one input controller and an explicitly installed server fixture, gated to Studio with PlaceId and GameId zero. No target-game movement remote is guessed or invoked.

Modern constraints use [LinearVelocity](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity) and [AlignOrientation](https://create.roblox.com/docs/reference/engine/classes/AlignOrientation), with finite force/torque limits and scoped restoration. Skeleton links use [Motor6D](https://create.roblox.com/docs/reference/engine/classes/Motor6D); one shared overlay manager runs after the camera through [BindToRenderStep](https://create.roblox.com/docs/reference/engine/classes/RunService#BindToRenderStep).

The owned server's independent Noclip uses [collision filtering](https://create.roblox.com/docs/workspace/collisions), preserving each part's original group instead of repeatedly forcing CanCollide. Current documentation places group management on WorldRoot; older installed engines use the audited PhysicsService forwarding API. The fixture detects support and restores its private group on shutdown. This server implementation is excluded from the production client bundle and cannot enable movement in RNG RollAttacks.

Player Tracker is an embedded, cached Player-page component. Its player teleport button is disabled because no permitted player-follow/teleport contract was established. Public client-visible names/health/distance remain data, never executable input.

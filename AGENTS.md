# Ervi Hub development rules

Read HANDOFF.md, README.md and the current continuation report before changing behavior. Edit `src/` and rebuild; do not hand-edit generated artifacts. Preserve Scope cleanup, early `_G.RNG_HUB_STOP` registration and Auto Roll's one-request/no-uncertain-retry guarantees. Retain the existing checkout; cloud tasks are isolated, so do not create worktrees unless explicitly requested.

Every new floating HUD, panel or separate window must use `FloatingWindow` or provide an equivalent justified implementation: themed, configurable from the hub menu, draggable where appropriate, corner-resizable, constrained to the visible viewport, and with persistent position and size when file access is available. Use scrolling content to accommodate large fonts. Avoid standalone Close buttons; menu controls own enabling/disabling. Ensure all instances and event connections are disposed when disabled or unloaded. Document any technical exception.

The Safe Zone is a saved character position/orientation reference, scoped to PlaceId. Do not assume it is a server-designated protected area. No supported return/floating/automated-M1 API is established in the current evidence. Do not invent remotes, rewrite character CFrames, anchor characters or bypass movement/cooldown validation to fill that gap. Keep unsupported requests visibly distinct from executed actions.

Use Desktop Commander for authorized Windows work if exposed; the Linux cloud shell does not access the user's PC. Do not claim deployment or live Roblox validation based on headless tests. Keep Potassium's autoexec directory empty. Preserve repository visibility; publishing/distribution must follow the user's authorization.

Before release, run the unit and smoke suites, compile both generated artifacts, verify deterministic outputs, update current documentation, and preserve rollback history. Historical reports are evidence for their original versions only.

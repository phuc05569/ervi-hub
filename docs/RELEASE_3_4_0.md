# Release — Ervi Hub 3.4.0 (14 Nov 2026)

Released by the owner's explicit approval, including the liquid-glass status bar. The owner accepted the remaining unverified physical-input and duplicate-startup scenarios listed below.

| | |
|---|---|
| Version | **3.4.0** |
| Build | **3.4.0+d12330122a34** |
| Bundle | `build/Ervi_Hub.luau`, SHA-256 **e27fe7f83d2c2abf9625e5eb30092a762b7acb1331208559f747197aebd8d26c** |
| Artifact commit | **c605e0185343e9273582f61c8f6779992fde6c4e** (the release commit carries the identical bundle) |
| Branches | `dev/ervi-hub-3.1-handoff`, fast-forwarded to `main` |
| Tag | `v3.4.0` |

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/phuc05569/ervi-hub/c605e0185343e9273582f61c8f6779992fde6c4e/build/Ervi_Hub.luau"))()
```

**Pre-release integrity checks**
- The committed bundle, a fresh rebuild from `src/`, and both installed Potassium copies have the same SHA-256.
- Release and loader compile.
- The raw URL above returned HTTP 200.
- The `build/loader.lua` distribution template stays unconfigured, as in every earlier release (`loader.json` url is empty).
- Potassium autoexec stays empty.

**Verification behind this release** (details in [reports/UI_REDESIGN_3_4.md](../reports/UI_REDESIGN_3_4.md)):
- 173 unit / 554 smoke checks pass, and builds are deterministic.
- Studio checks covered UI scale, lifecycle and the image fallback.
- Live Potassium acceptance:
  - local image assets loaded;
  - one hub instance after the cross-context guard;
  - scripted UI-callback tests for opacity, skeleton thickness 0.1/0.2/0.3, minimize and pill restore, unload, restart persistence and centering at two resolutions;
  - frame-time overhead within noise.
- The owner's settings were left byte-identical to the pre-test backup.

**Known limitations accepted at release**
- Physical mouse/keyboard acceptance is incomplete.
- The cross-executor-context duplicate-start guard is proven in the smoke test only; it could not be recreated live after Potassium was attached once.
- There is no live screenshot of the glass status pill.
- Roblox's Esc menu covers the hub: the owner kept PlayerGui layering.

# Published development checkpoint — Ervi Hub 3.2

Artifact commit: **fa4c53889c4afd99dd8d197191033699e363fe8d**.
Branch: `dev/ervi-hub-3.1-handoff`.
Build: **3.2.0+4e59db554fde**.
Bundle: **254851 bytes**, SHA-256 **6eb609a7dc0ef0bb8998ff6bbfd7a459bae49c760fdece5908699a79511a2443**.

The development push succeeded. An HTTP GET of the immutable raw URL returned **200**, and the downloaded bytes matched the local bundle and both installed Potassium copies. `git ls-remote` confirmed the artifact commit on the dev branch and stable main still at `608dc220da4cd144d54c0415a31556264fd1ea0a`. This later documentation commit retains identical generated artifacts.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/phuc05569/ervi-hub/fa4c53889c4afd99dd8d197191033699e363fe8d/build/Ervi_Hub.luau"))()
```

[Exact script](https://raw.githubusercontent.com/phuc05569/ervi-hub/fa4c53889c4afd99dd8d197191033699e363fe8d/build/Ervi_Hub.luau), [artifact commit](https://github.com/phuc05569/ervi-hub/commit/fa4c53889c4afd99dd8d197191033699e363fe8d), [full phase report](../reports/CONTINUATION_3_2_0.md).

The same build was executed through Potassium UI Automation in the actual target place 119338513416973 / universe 10768634654. The final bounded report confirms successful boot, visible main window at zero group transparency, status bar off, unanchored character, no preview marker and no captured hub errors. Prior virtual-input checks exercised F8 capture, held/released marker, key clearing and disable cleanup. Existing setting values were preserved; autoexec is empty; original installed builds were backed up before deployment.

Final regression result: **148 unit / 494 smoke, zero failures**, both Luau artifacts compile, deterministic release/map/loader. Native Studio screenshots/input verified the logo, dropdown, resizing and targeting preview. A client/server sandbox comparison demonstrated that local anchored movement did not establish server movement. Click TP is **targeting preview only**; server teleport/protection is not implemented or claimed.

Physical live-client input/capture, actual live label appearance, a complete live GUI-hover transition and target-game server-authoritative movement/protection remain unverified. The initial virtual hover target was clipped below the sidebar; a corrected visible-control hit query resolved the expected button, with the marker absent, but did not establish a complete shown-to-hidden transition. Benchmarks are short/noisy engine-cadence measurements, not proof of a rendered-FPS gain.

Source commits:

| Phase | Commit |
|---|---|
| Logo/native aspect | b6610b633d84bcd907df18d7c13c5e1efdf5b5f2 |
| Visible-overlay caches/reuse | cb710c3fcef1f4bb313dc3484af6f34866725137 |
| Held targeting preview | 351dd67776908f2956562accfa6f3cbd487233c0 |
| Local-only Safe Zone status | 108d803ebe333dca779ddd145159e81087b63ca3 |
| Native dropdown strokes | 0dd8bcc43aa92abd57a506e14e52f4776e026836 |
| Generated artifacts/docs/evidence | fa4c53889c4afd99dd8d197191033699e363fe8d |

The original baseline was reproduced before editing. No tests were removed to achieve passing results. Studio's unsaved local test place was not published/saved; Play and the localhost source bridge were stopped. The user's pre-existing unsaved Potassium tab was preserved.

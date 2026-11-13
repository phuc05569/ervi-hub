# Functional repair log — 14 November 2026

Development baseline: v3.4.0, commit 2b93389, clean `dev/functional-audit-3.4`.
Preservation: `C:\Users\ASUS\ervi-functional-preservation-20261114-052242` includes all-ref Git bundle, sources, generated build, evidence and settings. No production deployment or push is authorized by this request.

## Click TP

Root cause: movement was gated entirely on an unpublished Studio protocol; other places only selected a preview. The owner-supplied WeAreDevs source uses native `Model:MoveTo`, not a server remote. Added an independently written native one-shot adapter, a fresh click-time ray, in-flight exclusion, bounded position observation, lifecycle cancellation and correction reporting. It does not retry corrections or claim server acceptance.

Regression: the new headless local-movement assertion failed on the previous implementation, then passed. Rapid-click exclusion passes. These observations use a mock engine, not target-game replication.

## Destinations and emergency

Separate place-scoped A/B storage, finite manual coordinates, capture/save/reset/test controls, data-only position save/rename/delete/copy, inclusive 30% default emergency trigger. Emergency latches until health exceeds threshold or character changes. No B coordinate is invented, no ForceField or invulnerability is created. Original A scoped hold and return behavior remains.

Current automated checkpoint: 178 unit / 557 smoke passed, zero failures. Live acceptance is pending. The first Click TP slice compiled both artifacts; subsequent integration must compile again before completion.

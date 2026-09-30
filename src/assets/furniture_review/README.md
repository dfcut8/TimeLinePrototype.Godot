# Optional furniture review — issues #35 and #36

![Engine contact sheet](review_contact_sheet.png)

Both objects are independent reusable subscenes; the shelf, cassette and review camera/lighting rig are also scene instances. This is an isolated scale/fit review, not approved room furnishing. No main scene or existing asset was changed.

Rebuild from the repository root using Blender `--background --python src/assets/furniture_review/build_asset.py -- bench`, then the same command with `-- plinth`. The builder creates a new scene, exports only selected asset parts, saves an editable scene library with a separate review studio and renders four previews. It writes only the selected object's deliverables. To repeat the GPU import/geometry/fit checks, run `src/assets/furniture_review/verify_godot.ps1`; the default executable pins Godot 4.7.2. The verifier copies only relevant scenes/GLBs into a fresh temporary project and retains separate import/reimport/runtime logs. It does not launch the project editor or alter existing assets. Automatic LOD and import compression are disabled for measured interfaces.

`godot_validation.json` records the actual engine, checks, 1.04 m bench/stack gap, zero cassette/plinth contact error, and cassette margins. Four angles each cover the bench, plinth with cassette, and assembly. All ten new components are manifold and total 1,080 triangles; three shared palette materials per model. Model-specific drawings, source and topology reports live in the two asset directories. Refresh file manifests after deliberate changes using `python src/assets/furniture_review/package_manifest.py`.

Both MCP connection checks failed at task start. Standalone Blender 5.2.2 LTS and isolated Godot 4.7.2 Forward+/D3D12 are the fallback used, not live MCP validation. The MCP mesh validator could not run; imported triangle winding/area/UV checks passed in Godot. Import and game runtime logs contain the host certificate-store error only. Optional placement remains deferred until core timeline and room scale are approved; full-room camera clearance, art approval and performance remain unvalidated. GitHub issues remain open for that review.

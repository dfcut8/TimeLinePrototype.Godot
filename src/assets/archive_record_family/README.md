# Archive cassette family source and review

Shared dimension-driven Blender source for issues #31 and #33, derived from #32's existing medium cassette. The medium asset and its staged status are unchanged. Each new cassette has a reusable `.tscn` scene.

Use each size's `build_asset.py` in Blender to build, validate, export and render it. Run `verify_godot.ps1` with PowerShell for isolated Godot 4.7.2 import and GPU review of all three sizes. `-Godot` overrides the executable location. Outputs and hashes live beside the individual assets; family capture and separate import/reimport/runtime logs live here.

The review assembly uses the staged medium GLB. This folder has `.gdignore` so the main project does not try to resolve that staged dependency; the verifier copies the required files without `.gdignore` into its temporary project. Small and large object scenes are independently usable in the main project. Studio rigs and review scenes are excluded from the delivered GLBs.

MCP connection checks failed for both applications. Standalone Blender 5.2.2 LTS and Godot 4.7.2 Forward+/D3D12 provided the recorded validation. All geometry/material/dimension checks passed. Import and runtime logs each contain the host Windows certificate-store error; no asset/script error remains. Live MCP validation and room/performance testing remain incomplete. Actual shelf and plinth fit is now verified by the follow-up below. No collision is added to decorative cassette meshes.

Both sizes retain identical fixed bevel widths, index shapes and material factors. Bottom-center pivots, +Y up and +Z spine fronts match the medium model. Original proposed allocations have been superseded by measured shelf/plinth assembly fit.


## Actual shelf and plinth fit

`verify_fit.ps1` imports the existing cassette, shelf and plinth GLBs into an isolated project and runs `verify_fit.gd`. It checks 68 small and 44 large instances, measures support faces from imported mesh bounds, checks contact and all opening clearances, detects record overlap, verifies matte materials and triangle normals/UVs, and captures four views per assembly. The large record additionally sits on the real plinth. `godot_fit_validation.json` and separate `fit_*.log` files record the result. Run `create_fit_scenes.py` to rebuild the reusable shelf scenes beside both cassette assets and the large display scene. All component objects remain separate scene instances. Their GLBs and editable Blender sources are unchanged.

The historical `godot_validation.json` describes the earlier isolated-model review, including its then-provisional shelf status. The fit report supersedes that status. Live Blender/Godot MCP connection checks failed; fresh standalone Godot 4.7.2 Forward+/D3D12 validation passed, with only the host certificate-store error in import and runtime logs. Full-room placement, camera clearance and measured performance remain pending.


## Illuminated shelf verification — 1 October 2026

Both cassette shelf scenes now reuse the illuminated bay. `verify_fit.ps1` includes the shelf-light dependency and tests all 112 records against eight fixtures. The passing report records minimum vertical separations of 202 mm (small) and 42 mm (large), while retaining shelf, neighbor and plinth checks. Eight shelf views were inspected. Standalone Godot 4.7.2 Forward+/D3D12 was used because both live MCPs failed connection checks. No mesh/source edits were required; full-room review remains pending.

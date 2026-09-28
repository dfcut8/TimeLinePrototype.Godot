# Archive cassette family source and review

Shared dimension-driven Blender source for issues #31 and #33, derived from #32's existing medium cassette. The medium asset and its staged status are unchanged. Each new cassette has a reusable `.tscn` scene.

Use each size's `build_asset.py` in Blender to build, validate, export and render it. Run `verify_godot.ps1` with PowerShell for isolated Godot 4.7.2 import and GPU review of all three sizes. `-Godot` overrides the executable location. Outputs and hashes live beside the individual assets; family capture and separate import/reimport/runtime logs live here.

The review assembly uses the staged medium GLB. This folder has `.gdignore` so the main project does not try to resolve that staged dependency; the verifier copies the required files without `.gdignore` into its temporary project. Small and large object scenes are independently usable in the main project. Studio rigs and review scenes are excluded from the delivered GLBs.

MCP connection checks failed for both applications. Standalone Blender 5.2.2 LTS and Godot 4.7.2 Forward+/D3D12 provided the recorded validation. All geometry/material/dimension checks passed. Import and runtime logs each contain the host Windows certificate-store error; no asset/script error remains. Live MCP validation, actual shelf bay (#28) assembly fit and room/performance testing remain incomplete. No collision is added to decorative cassette meshes.

Both sizes retain identical fixed bevel widths, index shapes and material factors. Bottom-center pivots, +Y up and +Z spine fronts match the medium model. Proposed per-record clearances are documented per size; they are not a claim that a shelf was built.

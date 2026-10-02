# Record stack pair: issues #28 and #29

## Configurable row review

Run `./src/assets/record_stack_family/verify_configurable.ps1` from the repository
root to validate `../record_stack_end_cap/configurable_shelf_row.tscn` in a fresh
temporary project. `-Godot` overrides the pinned Godot 4.7.2 executable. The
runner copies only required scenes, scripts, GLBs and import settings, retains
separate import/runtime logs, and publishes fresh evidence only after a pass.
It reuses the existing furniture review rig; no project main scene is changed.

`review_configurable.tscn` demonstrates a saved five-bay override. The verifier
checks 14 cases against actual imported meshes: odd/even counts, both clamp
boundaries, repeated resizing, transformed parents, cap contact/orientation,
floor/depth alignment, all light mounts and recess clearances, attachment markers,
disk save/reload, independent instances and detached configuration/reentry.
User-owned attachments survive both resizing and serialization. Generated bays
are recreated from their PackedScene without serialized duplicates.

`godot_configurable_validation.json` passed in Godot 4.7.2 Forward+/D3D12.
The largest measured bay seam error was 0.003815 mm (0.1 mm tolerance).
`godot_configurable_front/rear/end/underside.png` are visually inspected GPU
captures of the three-bay configuration. `configurable_import.log` and
`configurable_runtime.log` contain only the existing host certificate-store error.
Blender MCP status/scene and Godot MCP state checks failed to connect. Existing
geometry was reused unchanged; standalone Godot was the explicit fallback.
Live Inspector/MCP, full-room clearance and performance are still unverified.

Shared authoring and repeatable fit review for the shelf bay and reversible end cap. The delivered reusable objects live in the sibling `record_stack_shelf_bay` and `record_stack_end_cap` folders. No unrelated assets are changed.

From repository root, run Blender with `--background --python src/assets/record_stack_family/build_asset.py -- bay`, then repeat with `-- cap`. Outputs replace only those two generated asset packages. Run `python src/assets/record_stack_family/create_review.py` to regenerate wrappers and the explicit scene-instance review assembly. Run `src/assets/record_stack_family/verify_godot.ps1` in PowerShell for isolated import and GPU runtime validation; `-Godot` overrides its default Godot 4.7.2 executable.

The review directory has `.gdignore` because the medium cassette is staged outside normal project import. The verifier copies dependencies to a fresh temporary project without their ignore markers. This preserves that existing staging decision. Individual shelf/cap object scenes are directly usable in the main project. The review rig is itself an existing reusable scene. All 108 records are independent PackedScene instances.

Three 1.6 m bays, both end caps, and three cassette sizes on every shelf are checked. Reported minimum clearances are measured from imported cassette envelopes. Front/rear/side/underside game captures were visually inspected. Each new asset has its own Blender preview angles, source, GLB, scene, dimension drawing, validation report, and hash manifest.

Godot 4.7.2 Forward+/D3D12 checks passed. Separate import and runtime logs contain only the host certificate-store error, not asset errors. No live MCP connection worked: Blender tools were unavailable, and Godot get_state could not reach port 6550. The local game-dev CLI was not on PATH; the repository's existing Blender/standalone-Godot workflow was used. No paid service or external assets were used. No canonical game-dev package verification is claimed.

Remaining checks: live MCP/editor validation, full room placement/orbit clearance and measured performance. These focused object models do not establish final chamber scale. No issue closure or PR publication was performed.

## Integrated delivery

Issues #28 and #29 now provide `illuminated_shelf_bay.tscn`, `capped_shelf_row.tscn` and `capped_shelf_alcove.tscn` in their object directories. They are directly usable in the main project; only the cassette review remains isolated. The review instances the actual production row and adds 108 independent records. The verifier also loads the production alcove and checks rotated cap contacts and corner joins. No modeling-source or GLB changes were needed.

The fresh report includes 12 successfully fitted light fixtures and rotated-cap checks, with seven runtime captures. Blender's status and scene MCP calls failed; Godot MCP get_state failed on port 6550. Standalone Godot 4.7.2 Forward+/D3D12 supplied the passing import/runtime checks. Separate logs contain only the known certificate-store error. Live MCP review and full-room placement/performance remain incomplete.

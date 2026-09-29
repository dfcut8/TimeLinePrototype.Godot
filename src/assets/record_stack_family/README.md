# Record stack pair: issues #28 and #29

Shared authoring and repeatable fit review for the shelf bay and reversible end cap. The delivered reusable objects live in the sibling `record_stack_shelf_bay` and `record_stack_end_cap` folders. No unrelated assets are changed.

From repository root, run Blender with `--background --python src/assets/record_stack_family/build_asset.py -- bay`, then repeat with `-- cap`. Outputs replace only those two generated asset packages. Run `python src/assets/record_stack_family/create_review.py` to regenerate wrappers and the explicit scene-instance review assembly. Run `src/assets/record_stack_family/verify_godot.ps1` in PowerShell for isolated import and GPU runtime validation; `-Godot` overrides its default Godot 4.7.2 executable.

The review directory has `.gdignore` because the medium cassette is staged outside normal project import. The verifier copies dependencies to a fresh temporary project without their ignore markers. This preserves that existing staging decision. Individual shelf/cap object scenes are directly usable in the main project. The review rig is itself an existing reusable scene. All 108 records are independent PackedScene instances.

Three 1.6 m bays, both end caps, and three cassette sizes on every shelf are checked. Reported minimum clearances are measured from imported cassette envelopes. Front/rear/side/underside game captures were visually inspected. Each new asset has its own Blender preview angles, source, GLB, scene, dimension drawing, validation report, and hash manifest.

Godot 4.7.2 Forward+/D3D12 checks passed. Separate import and runtime logs contain only the host certificate-store error, not asset errors. No live MCP connection worked: Blender tools were unavailable, and Godot get_state could not reach port 6550. The local game-dev CLI was not on PATH; the repository's existing Blender/standalone-Godot workflow was used. No paid service or external assets were used. No canonical game-dev package verification is claimed.

Remaining checks: live MCP/editor validation, future shelf-light #27 integration, full room placement/orbit clearance and measured performance. These focused object models do not establish final chamber scale. No issue closure or PR publication was performed.

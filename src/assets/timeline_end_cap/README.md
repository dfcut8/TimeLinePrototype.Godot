# Timeline end cap — issue #9

Implements [issue #9](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/9). Authored/exported through live Blender MCP, Blender 5.2.2 LTS, using the [start cap's shared profile and material recipe](../timeline_start_cap/README.md).

![Later-end assembly](godot_end_front.png)

## Later-end orientation

One unit = one metre; Godot/glTF +X later chronology, +Y up, +Z front. Pivot and `RailInterface` lie at the last housing's later-end center. Identity transforms and no negative scale. Local bounds: **X [0,.004], Y [-.060,.060], Z [-.060,.060] m**; `OuterEnd` is (.004,0,0). Place the scene at X=6 for three 2 m modules. The start cap extends toward -X; this named variant extends toward +X. Shared geometry is authored with opposite extrusion endpoints and recalculated outward normals.

The 4 mm solid plate closes the housing and light channel with a flush 120 mm octagonal outline and matching 14 mm corner chamfers. It has no label, emission, collar or internal sleeve. The complete example is `review_assembly.tscn`, composed entirely from reusable object scenes. Existing housing, insert and joiner assets are unchanged.

## Files and checks

`source/timeline_end_cap.blend` is editable source; `timeline_end_cap.glb` is glTF 2.0 with **28 triangles, one mesh and one opaque graphite material**, UV0 and flat normals. No textures, rig, animation, collision or LOD. `timeline_end_cap.tscn` includes the visual and attachment markers. Embedded material matches the housing: linear RGB (.048,.060,.073), roughness .68, metallic .22, no emission. Blender may suffix the material name; parameters are identical. Import settings disable lossy compression and automatic LODs.

`build_asset.py` delegates to `../timeline_start_cap/build_asset.py`, which uses the existing light-insert modeling helper. Both cap folders and that helper are required to regenerate. Run this script through live Blender MCP with `runpy.run_path(path, run_name='__main__')`; it preserves existing Blender scenes. `dimensions.svg`, four Blender renders, nine Godot assembly/detail captures, topology/engine JSON reports, and SHA-256 manifests complete the delivery.

Blender manifold, volume, degeneracy and UV checks passed. Godot **4.7.2 stable, Compatibility/OpenGL on RTX 4080 SUPER** ran the assembly and passed bounds, triangles, materials, normals, UVs, winding, orientation, attachment and zero-gap checks at both housing/light endpoints. Twenty actual triangle probes per cap passed channel closure. Front/rear/underside/end-on captures were inspected. `godot_validation.json` records the results for both tasks.

Rerun from the repository root: `& ./src/assets/timeline_end_cap/verify_godot.ps1`. Separate `import.log`, `reimport.log` and `runtime.log` contain only the pre-existing Windows root certificate-store error, with no asset/script/test failures. The initial run used a CLI fallback because another client owned the Godot MCP bridge. Live MCP validation has now passed on the intended project with Godot 4.7.2 Forward+/D3D12: `godot_validate_meshes` checked five unique meshes with no integrity problems, and all live geometry/material/fit checks passed. Eight live screenshots confirm both caps from the front, rear, underside and ends. `live_mcp/validation.json` summarizes the new run; that folder retains raw MCP receipts and captures. Its separate game runtime log has no errors or warnings. Editor receipts contain competing-client rejection warnings but no asset/import/script errors. No physics or animation applies. Whole-room readability is separate integration work.

Provenance: original repository-specific geometry and scripts, with no external assets, paid generation or added third-party license obligations. Redistribution licensing is the owner's decision. See the start-cap notes for the shared fit rationale and delivery conventions.

To repeat the live checks: verify `godot_project get_info`, rescan assets, open/run `review_assembly.tscn`, call `godot_validate_meshes`, then run `return JSON.stringify(load("res://assets/timeline_end_cap/live_fit_checks.gd").new().validate(tree.current_scene))` through `godot_exec`. Inspect game screenshots and the separate runtime log. The live validator has no file writes or game-exit side effects.

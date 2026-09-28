# Structural piers A and B — issues #16 and #17

Model delivery for [Structural pier A](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/16) and [Structural pier B / narrow rib](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/17). Both are original, minimal V5 architectural meshes. The broad and narrow silhouettes share bevels, depth, tier height, pocket and gallery interfaces.

![Godot family inspection](godot_front.png)
![Godot gallery fit](godot_assembly.png)

## Resolved dimensions

One unit is one metre. These are local interface decisions, not final approval of the whole chamber scale. See [dimensions.svg](dimensions.svg).

| Interface | Pier A | Pier B |
| --- | --- | --- |
| Overall width / height / depth | 0.90 / 4.75 / 0.80 m | 0.50 / 4.75 / 0.80 m |
| Shaft width / depth | 0.80 / 0.60 m | 0.40 / 0.60 m |
| Base | 0.16 m solid foot, tapered shoulder to Y=0.26 m | Same |
| Vertical corner chamfer | 12 mm | 12 mm |
| Uplight pocket | 0.24 m wide, 0.16 m high, 0.12 m deep | Same |
| Pocket aperture | X=±0.12, Y=0.31–0.47, Z=+0.30 m | Same |
| Pocket back / marker | (0, 0.39, +0.18) m | Same |
| Gallery bearing marker | (0, 4.75, 0) m | Same |
| Next tier marker | (0, 5, 0) m | Same |

Pivot is the bottom centre. Godot/glTF +Y is up, +Z is front, +X is width. Blender +Z is up and -Y is front. Mesh/object transforms and Godot model-instance transforms are identity. Both top and bottom are flat closed faces; the intentional pocket is a blind recess with closed back, floor, roof and side reveals. No separate light, lens, emission or fixture is included. The future uplight fixture must fit within this reserved pocket or explicitly revise the interface.

Use each object's `.tscn` as a PackedScene, retaining the named mounting markers. Do not scale the narrow pier from A: B is separately authored at half shaft width with the same unscaled chamfer and pocket. Every distinct object in the review is an instanced subscene; the review rig owns its lights/camera/environment. Static visual models have no physics or animations. Collision should be defined for the eventual navigation design rather than inferred from this art review.

## Gallery and wall grid

The existing `curved_gallery` slab is 0.25 m thick, with a proposed 5 m tier pitch. Place lower piers at Y=0, gallery deck at Y=5 and upper piers at Y=5; lower pier tops meet the slab underside at Y=4.75. The slab is the intervening vertical join, so do not place the next tier at 4.75 when a gallery is present. Without a slab, direct end-to-end stacking can use the 4.75 m height, with the wider foot acting as a collar.

Piers stand at radius 24.8 m on the gallery's radial seams, every 15 degrees. This preserves the reserved 0.3 m tangential by 0.4 m radial bearing area. The test assembly places A at (24.8,0,0), rotated -90 degrees around Y; B at (23.95496,0,-6.418712), rotated -75 degrees. Front pockets face inward. The base footprints remain well outside the proposed 20 m clear central radius and within the gallery's outer radius 25.5 m. Twenty-four placements complete the support grid; not every site needs both variants.

Adjacent centre chord spacing is approximately 6.4741 m. Future wall/window infill should use the common 4.75 m clear tier height and measure between actual pier side planes; no wall/window model existed here to validate that fit. The gallery parapet stays at radius 22 m, clear of these supports. This is a visual assembly contract, not structural engineering certification.

## Delivery and provenance

Each adjacent `structural_pier_a` / `structural_pier_b` directory contains editable `.blend` source, a reproducible `build_asset.py`, self-contained glTF 2.0 `.glb`, reusable `.tscn`, import settings, four Blender previews and `validation.json`. Each model has **76 triangles, two material slots and one UV set**. No LOD is justified at this size. Embedded constant PBR materials use the established palette:

- `archive_basalt_ceramic`: linear RGB (0.085, 0.103, 0.117), roughness 0.81, metallic 0.
- `archive_graphite`: linear RGB (0.048, 0.060, 0.073), roughness 0.68, metallic 0.22.

No maps, paid generation, downloaded meshes, text or third-party attribution are required. Geometry was authored locally in Blender 5.2.2 LTS using the repository's V5 architecture board and written issue scopes. No repository license is present; this delivery does not grant a new redistribution license. `manifest.json` in each directory records file hashes; `glb_validation.json` separately checks the exported bytes. The game-dev CLI is unavailable, so this is not a CLI-certified canonical package.

Original user request: “Pick up another 2 tasks from the issues to work on a 3d model. It is ok to implement both one at a time. Just work on both.” No image/model generation prompt or negative prompt was used.

Rebuild in order with Blender `--background --python-exit-code 1 --python src/assets/structural_pier_a/build_asset.py`, then the equivalent path for B. B's script calls A's shared authoring source. Rebuilds overwrite matching generated outputs only. Run `./src/assets/structural_pier_family/verify_godot.ps1`, then `python src/assets/structural_pier_family/package_manifest.py` to refresh static checks and hashes. Keep both model directories and the family harness together.

## Validation and limits

Live Blender MCP `get_addon_status` and `get_scene_info` both failed to connect; Godot MCP `get_state` could not reach ws://127.0.0.1:6550. Connected validation requires Blender's MCP addon and this Godot project's addon to be running. No existing interactive scene was changed. Local Blender CLI and an isolated Godot CLI project were used explicitly as fallbacks.

Blender checks: no nonmanifold edges or zero-area faces, positive closed volume, UV0 present. Godot **4.7.2-stable official**, NVIDIA RTX 4080 SUPER, Compatibility renderer: both `.tscn` instances imported and rendered, expected dimensions/material slots/triangle counts, UVs/unit normals, nondegenerate clockwise winding, closed end-face ray probes, pocket back at the intended depth, eight actual gallery-triangle bearing probes, tier markers and central clearance passed. Import uses disabled compression and LOD generation to retain exact module interfaces. GPU captures cover front, rear, top, underside, recess closeup and gallery bearing/assembly; these were visually reviewed without bloom. The model silhouette remains readable in this neutral review lighting.

Editor import/reimport logs and the separate game `runtime.log` are retained. Their only reported error is the sandbox's Windows root-certificate-store read failure; there are no model import, script or runtime validation errors. `godot_validation.json` records no failed assertions. The MCP mesh validator was unavailable; imported triangle winding/normals/degeneracy were checked directly by the GDScript harness instead.

Remaining: full-room Forward Plus appearance, live MCP verification, actual future wall/window/uplight fit, camera navigation and timeline readability require the assembled environment. The focused GPU test does not establish those. Optional dressing remains deferred. Issues remain open pending review/merge; when a PR is requested, delegate it per AGENTS.md and link both issues. No PR was opened by this task.

The family harness has `.gdignore` because its gallery dependency is currently an ignored review bundle. The runner copies the relevant assets into a fresh temporary project without that ignore file. The two pier scenes themselves are directly importable in the main project; their source subfolders alone are ignored.

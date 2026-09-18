# Rail module joiner - issue #7

Original model for [issue #7](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/7), authored and exported through live Blender MCP (Blender 5.2.2 LTS). Reusable object: `rail_module_joiner.tscn`.

![Joiner](preview_front.png)

## Interface

The existing housing is solid behind the light recess. This joiner therefore uses a minimal open-front rear saddle rather than the concept drawing's internal pin, which would require a new housing bore. It leaves the entire front light channel exposed and adds only 3 mm to the rear/top/bottom silhouette. No bolts or ornamental collar are needed at the intended viewing distance.

One unit is one metre. Godot +X advances chronology, +Y is up, +Z faces front. Blender +Z is up and -Y faces front. Identity transforms; pivot at the seam center. Bounds: X [-.04,.04], Y [-.063,.063], Z [-.063,-.020] m, or **.080 x .126 x .043 m**. Place at X=2 and X=4 between three 2 m modules. SeamCenter and EarlierOverlap/LaterOverlap markers document placement and the 40 mm engagement on each side.

The saddle follows the housing's chamfered rear profile with 0.5 mm nominal planar clearance and 2.5 mm wall thickness. Chamfer clearance is at least 0.49 mm. The slight slip-fit clearance is intentional, not a visible gap in the rail. It is a static visual coupling; mechanical tolerancing, fastening and load-bearing behavior are not simulated. The frontmost point at Z=-.020 stays 51 mm behind the insert's rear face. The original housing and insert share their unchanged 2 m pitch.

## Delivery

`source/rail_module_joiner.blend` contains editable mesh, UV0, material graph and review studio. `rail_module_joiner.glb`: **44 triangles, one opaque material**, no maps, rig, animation or collision. `archive_graphite` uses the housing's linear RGB (.048,.060,.073), roughness .68, metallic .22 and no emission. Blender may suffix the material name when a material with that name already exists; values are identical. No LOD is justified.

`build_asset.py` calls the sibling light insert's authoring helper through `runpy`; both folders are required to regenerate this model. Run through live Blender MCP with `__file__` set by `runpy.run_path`. It preserves existing scenes. `dimensions.svg` records the resolved drawing. `validation.json` records topology, triangle count and bounds; front/rear/underside/end renders expose all surfaces.

`illuminated_rail_module.tscn` combines the housing and insert as scene instances. `review_assembly.tscn` instances three modules, two joiners and the existing review-rig subscene. Open this scene to inspect the complete 6 m assembly. No main scene or gameplay was changed.

## Verification

Blender checks passed: closed manifold geometry, positive signed volume, UVs, no degenerate faces. Godot **4.7.2 stable, Compatibility/OpenGL on RTX 4080 SUPER**, imported and ran the assembly. `godot_validation.json` records exact bounds, material/triangle/UV/normal checks, correct clockwise winding, insert clearance, joiner alignment, nonpenetration and zero gaps at both light seams. `godot_*.png` captures front seam, rear, underside, end and overall assembly without bloom. The rear saddle is visible but restrained; the front light line is unbroken.

Rerun: `& ./src/assets/rail_module_joiner/verify_godot.ps1` from repository root. The temporary project isolates validation from the user's editor. Import, reimport and runtime logs were checked separately: no asset or script errors; each reports the existing Windows root certificate store error.

Godot MCP was attempted but unavailable: another client owns its connection after editor startup. CLI validation was used explicitly. Live-project MCP checks, `godot_validate_meshes`, and Forward+/D3D12 review remain incomplete. Imported winding/degeneracy/normal checks are the fallback, not a claim that the MCP validator ran. Physics/animation are not applicable. Whole-room readability and camera scale remain separate integration work.

Provenance: original geometry/scripts for the repository's V5 concept. No external mesh, maps, paid generation or new third-party licenses. Repository owner determines redistribution licensing.

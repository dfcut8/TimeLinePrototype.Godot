# Large archive record cassette

Model for [issue #33](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33), completing the V5 cassette family with the existing medium model. Existing model production is complete. Actual shelf assembly fit is now verified against the built shelf bay (#28); the large cassette also passes the built display plinth (#36) fit check. Live MCP and full-room review remain pending.

## Delivery

- `source/archive_record_large.blend`: editable 16-part model with four material graphs and a separate review studio.
- `archive_record_large.glb`: self-contained glTF 2.0, one mesh, four surfaces, 1,728 triangles, normals and UV0; no textures, cameras, animations, or external dependencies.
- `archive_record_large.tscn`: reusable Godot object scene. No interaction/physics is implied for this decorative record.
- `preview_*.png`: Blender studio front, rear, side and underside renders. `godot_*.png`: actual Godot Forward+ runtime captures.
- `dimensions.svg`, `validation.json`, `godot_validation.json`, `issue.json`, `manifest.json`: dimensional drawing, measured checks, original issue scope and file hashes.
- `build_asset.py`: entry point to the shared `../archive_record_family/` geometry, export and render source, derived from the existing medium cassette source. Bevel widths and accents are modeled in meters, never stretched from a finished mesh.

## Dimensions and interfaces

1 unit = 1 meter. Nominal width/depth/height: **105 / 320 / 480 mm**. Complete detail envelope: **106.6 / 323.7 / 480 mm**. Blender X is width, -Y is indexed spine front, +Z is up. Export/Godot +Y is up and +Z is spine front. Broad covers face +/-X. All transforms are identity; pivot is nominal-body bottom center. Floor/shelf contact is Godot Y=0. No mechanical attachment or opening mechanism.

Verified `shelf_assembly.tscn` instances the existing shelf and 44 large records (11 per shelf), at 125 mm pitch. All records retain identity rotation/scale, at Z=0.030 m and Y=0.160/0.720/1.280/1.840 m. Measured imported-mesh clearances: 40 mm headroom, 49.1 mm rear, 27.2 mm front and 71.7 mm minimum side margin. Neighbor gaps are 18.4 mm; shelf contact error is zero. These are actual fitted assemblies, superseding the original proposed allocations. `display_assembly.tscn` places the independent large cassette at (0,0.6,0) on the existing plinth. Contact error is zero; X/Z margins are 296.7/112.2 mm, safely inside the 8 mm top bevel.

## Materials and provenance

Same opaque non-emissive palette as medium: `archive_graphite`, `archive_basalt_ceramic`, `archive_dark_panel`, `archive_neutral_index`. Exact PBR values are in `validation.json`. Solid materials require no maps. UV islands are packed after beveling. Each component is closed with positive volume; small seated overlaps are intentional. No text, glyphs, gold decoration or downloaded content.

Original repository geometry adapted in Blender 5.2.2 LTS from the medium cassette and V5 furnishings concept. No paid generation, external meshes, fonts or texture libraries. No new redistribution license is assigned; repository ownership terms apply.

## Validation and reproduction

Run Blender in background with `--python src/assets/archive_record_large/build_asset.py`. This creates a separate Blender scene and overwrites this asset's matching deliverables. Run `src/assets/archive_record_family/verify_godot.ps1` to import all three sizes into an isolated temporary project, validate their geometry/materials/envelopes and capture four viewpoints plus the family view. Godot 4.7.2 Forward+ on D3D12 passed: triangle count, winding, nondegenerate geometry/UV triangles, normals, four matte opaque slots, floor contact, dimensions and unit scale. Blender checks also passed manifoldness, positive volumes, UV presence, GLB structure and triangle agreement.

Both MCPs were checked through their locally installed servers. Blender `get_addon_status` and `get_scene_info` could not connect; Godot `godot_editor_read(get_state)` reported no connection on 127.0.0.1:6550. Live validation requires Blender's addon server and the intended Godot editor with its MCP addon running. Standalone Blender and isolated Godot were used as explicit fallbacks. `godot_validate_meshes` was unavailable; the recorded Blender/Godot geometry checks cover the imported meshes instead. The `game-dev` CLI was not installed; no CLI-certified package is claimed.

Import and runtime logs were inspected separately: no model import, script or geometry errors remain. Each process reports a host-level Windows root-certificate-store error, unrelated to the offline assets. Logs are retained under `../archive_record_family/`. Runtime captures were visually reviewed for finished sides and underside without bloom. Remaining gaps: room placement/camera clearance, live MCP review, and measured performance/LOD need.


## Assembly fit follow-up (issues #31 and #33)

Run `../archive_record_family/verify_fit.ps1` for an isolated import and GPU check of both populated shelf assemblies and the large display assembly. `create_fit_scenes.py` in that folder rebuilds the saved scenes. All objects are PackedScene instances; no meshes are reconstructed by the verifier. Original editable Blender sources and GLBs are reused without geometry changes.

`godot_fit_validation.json` records the current assembly results. `godot_shelf_*.png` (and large `godot_display_*.png`) show front, rear, end and underside. The earlier `godot_validation.json` is retained as historical isolated-model evidence; its provisional shelf status is superseded by the fit report. Separate `fit_import.log`, `fit_reimport.log`, and `fit_runtime.log` live in the family folder. All checks passed in Godot 4.7.2 Forward+/D3D12; logs contain only the host certificate-store error, with no asset or script errors.

Both live MCP checks failed again for this follow-up. Blender modeling was unnecessary because existing meshes passed fit; standalone Godot supplied fresh engine validation. No live `godot_validate_meshes` result is claimed; imported triangle winding, area, normals and UV checks ran in the fallback verifier. No physics is required for these decorative objects. These are reusable furnishing arrangements, not approved full-room dressing.

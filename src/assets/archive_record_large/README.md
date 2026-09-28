# Large archive record cassette

Model for [issue #33](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33), completing the V5 cassette family with the existing medium model. Model production and isolated engine review are complete; actual shelf assembly acceptance awaits the unbuilt shelf bay (#28). The issue remains open for that dependency.

## Delivery

- `source/archive_record_large.blend`: editable 16-part model with four material graphs and a separate review studio.
- `archive_record_large.glb`: self-contained glTF 2.0, one mesh, four surfaces, 1,728 triangles, normals and UV0; no textures, cameras, animations, or external dependencies.
- `archive_record_large.tscn`: reusable Godot object scene. No interaction/physics is implied for this decorative record.
- `preview_*.png`: Blender studio front, rear, side and underside renders. `godot_*.png`: actual Godot Forward+ runtime captures.
- `dimensions.svg`, `validation.json`, `godot_validation.json`, `issue.json`, `manifest.json`: dimensional drawing, measured checks, original issue scope and file hashes.
- `build_asset.py`: entry point to the shared `../archive_record_family/` geometry, export and render source, derived from the existing medium cassette source. Bevel widths and accents are modeled in meters, never stretched from a finished mesh.

## Dimensions and interfaces

1 unit = 1 meter. Nominal width/depth/height: **105 / 320 / 480 mm**. Complete detail envelope: **106.6 / 323.7 / 480 mm**. Blender X is width, -Y is indexed spine front, +Z is up. Export/Godot +Y is up and +Z is spine front. Broad covers face +/-X. All transforms are identity; pivot is nominal-body bottom center. Floor/shelf contact is Godot Y=0. No mechanical attachment or opening mechanism.

Proposed shelf allocation: 125 mm pitch, 350 mm clear depth, 520 mm clear height. Detail envelope leaves 9.2 mm on each side, 26.3 mm total depth clearance and 40 mm headroom. Place nominal center at least 175 mm behind the shelf front edge. These are measured envelope checks against a proposed allocation, not a fitted shelf. Large is dimensionally suitable for a future flat display plinth, but #36 has no asset to test against.

## Materials and provenance

Same opaque non-emissive palette as medium: `archive_graphite`, `archive_basalt_ceramic`, `archive_dark_panel`, `archive_neutral_index`. Exact PBR values are in `validation.json`. Solid materials require no maps. UV islands are packed after beveling. Each component is closed with positive volume; small seated overlaps are intentional. No text, glyphs, gold decoration or downloaded content.

Original repository geometry adapted in Blender 5.2.2 LTS from the medium cassette and V5 furnishings concept. No paid generation, external meshes, fonts or texture libraries. No new redistribution license is assigned; repository ownership terms apply.

## Validation and reproduction

Run Blender in background with `--python src/assets/archive_record_large/build_asset.py`. This creates a separate Blender scene and overwrites this asset's matching deliverables. Run `src/assets/archive_record_family/verify_godot.ps1` to import all three sizes into an isolated temporary project, validate their geometry/materials/envelopes and capture four viewpoints plus the family view. Godot 4.7.2 Forward+ on D3D12 passed: triangle count, winding, nondegenerate geometry/UV triangles, normals, four matte opaque slots, floor contact, dimensions and unit scale. Blender checks also passed manifoldness, positive volumes, UV presence, GLB structure and triangle agreement.

Both MCPs were checked through their locally installed servers. Blender `get_addon_status` and `get_scene_info` could not connect; Godot `godot_editor_read(get_state)` reported no connection on 127.0.0.1:6550. Live validation requires Blender's addon server and the intended Godot editor with its MCP addon running. Standalone Blender and isolated Godot were used as explicit fallbacks. `godot_validate_meshes` was unavailable; the recorded Blender/Godot geometry checks cover the imported meshes instead. The `game-dev` CLI was not installed; no CLI-certified package is claimed.

Import and runtime logs were inspected separately: no model import, script or geometry errors remain. Each process reports a host-level Windows root-certificate-store error, unrelated to the offline assets. Logs are retained under `../archive_record_family/`. Runtime captures were visually reviewed for finished sides and underside without bloom. Remaining gaps: actual shelf/plinth contact and spacing, room placement/camera clearance, live MCP review, and measured performance/LOD need.

# Catalog lectern — issue #34

![Godot review](review_contact_sheet.png)

Optional static console for [issue #34](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34). The reusable `catalog_lectern.tscn` instances the GLB and supplies a screen-surface marker. Peripheral placement remains deferred until room scale is approved. No interaction, text, animation, or collision is implied.

## Dimensions and construction

One unit = one meter; Godot +Y up, +Z user-facing, X width. Pivot is floor center, transforms are identity. Imported envelope is **0.720 × 1.050842 × 0.471340 m** (width, height, depth). The top slopes 18 degrees toward the user. A solid ceramic base sits on a 60 mm recessed foot; the 720 × 480 × 60 mm graphite top supports a separately editable 620 × 360 × 8 mm opaque blank screen. Small seated overlaps between base and top are intentional. There is no opening mechanism.

ScreenCenter is at (0, .98614015, .01174265), on the outer screen face, with local +Y along its normal. The screen occupies normal offsets .030 to .038 m from the top's center plane at Y=.95. These are placement interfaces, not UI behavior. `dimensions.svg` shows the resolved side profile. The review scene leaves 1.34433 m between the console and existing shelf bay; this is an isolated fit check, not full-room clearance approval.

## Delivery and reproduction

- `source/catalog_lectern.blend`: editable four-part model, material graphs, and separate preview studio.
- `catalog_lectern.glb`: glTF 2.0, 432 triangles, four mesh parts, three matte opaque materials, normals and packed UV0; no external textures.
- `preview_*.png`: Blender front, rear, side and underside. `godot_*.png`: engine captures of the object and shelf comparison.
- `validation.json`, `godot_validation.json`, logs and `manifest.json`: topology, import/fit evidence and file hashes.

From repository root, run Blender with `--background --python-exit-code 1 --python src/assets/catalog_lectern/build_asset.py`, then `./src/assets/catalog_lectern/verify_godot.ps1`. The authoring script creates a separate scene and exports only this object. The verifier imports into a unique temporary project, disables compression/automatic LODs, and runs a GPU review. Refresh delivery hashes with `python src/assets/rail_assembly_review/package_manifest.py`.

Original geometry based on the repository's V5 furnishings board and existing furniture authoring conventions. `archive_graphite`, `archive_basalt_ceramic`, and `archive_dark_panel` reuse the existing PBR values. No downloaded models, paid generation, third-party maps, or new licensing obligations; repository ownership terms apply. No LOD is justified without performance measurements.

## Evidence and remaining gaps

Blender 5.2.2 LTS checks passed: all four components are manifold, positive-volume, have UVs, and contain no degenerate faces; GLB triangle/material counts agree. Godot 4.7.2 Forward+/D3D12 passed imported geometry/winding/UV checks, floor contact, matte opaque materials, screen seating/orientation, dimensions and shelf clearance. Front/rear/end/underside captures were inspected without bloom.

Blender `get_addon_status` and `get_scene_info` could not connect; Godot `get_state` could not reach ws://127.0.0.1:6550. Standalone Blender and isolated Godot are explicit fallbacks. Live MCP validation and `godot_validate_meshes` did not run; imported triangle checks provide separate evidence. Enable Blender's addon server and open the intended project with Godot's MCP addon to complete live review. The game-dev CLI is absent; no CLI-certified package is claimed.

Separate import/reimport and runtime logs contain only the existing Windows certificate-store error, with no asset or script failures. Full-room placement, orbit clearance, performance and art approval remain outstanding. The issue remains open for those reviews.

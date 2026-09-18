# Timeline start cap — issue #8

Implements [issue #8](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/8) for the V5 horizontal timeline. Original geometry authored/exported through live Blender MCP, Blender 5.2.2 LTS.

![Earlier-end assembly](../timeline_end_cap/godot_start_front.png)

## Resolved interface

One unit = one metre. Godot/glTF axes: +X later chronology, +Y up, +Z front. Blender uses +Z up and -Y front; export converts axes. Identity object transforms. Pivot and `RailInterface` marker are at the housing's earlier-end cross-section center. Local bounds: **X [-.004,0], Y [-.060,.060], Z [-.060,.060] m**. `OuterEnd` is (-.004,0,0).

The 4 mm plate meets the rail at X=0 and extends toward earlier time. Its 120 x 120 mm octagonal outline exactly matches the housing, including 14 mm corner chamfers. The entire end face is closed, terminating the recessed light channel and its insert with no sleeve, protruding collar or chronological label. Housing and insert need no edits. Mating end faces touch; their opposing faces are internal contact surfaces, not exposed coplanar overlays. Flush means matching the housing's outer cross-section; the plate adds 4 mm to total length. These are visual assembly dimensions, not a mechanical fastening specification.

`timeline_start_cap.tscn` is the reusable object containing the GLB and attachment markers. Place at the first housing's earlier end without rotation or scaling. The matching later variant is `../timeline_end_cap/timeline_end_cap.tscn`. The six-metre review rail spans X [-.004,6.004] including both caps. Full room scale and camera orbit remain separate integration work.

## Delivery and provenance

- Editable `source/timeline_start_cap.blend`, excluded from Godot import by `.gdignore`.
- glTF 2.0 `timeline_start_cap.glb`: **28 triangles, one mesh, one material**, UV0 and flat face normals, no maps or external resource dependencies. No LOD is justified.
- Shared `build_asset.py` profile is used by both cap variants. It calls the existing `../rail_recessed_light_insert/build_asset.py` authoring/studio helper. Run each cap's script through live Blender MCP using `runpy.run_path(path, run_name='__main__')`. It creates a separate scene, preserving existing Blender work, and updates that cap's outputs.
- `dimensions.svg`, four Blender preview renders, topology `validation.json`, engine `godot_validation.json`, and SHA-256 `manifest.json`.

Embedded `archive_graphite`: linear RGB (.048,.060,.073), roughness .68, metallic .22, opaque, no emission. Matches the housing's material parameters. No baked text, textures, rig, animation, physics or collision. Generated LOD and lossy mesh compression are disabled on import to preserve millimetre interfaces.

Original geometry and scripts for this repository's V5 design direction; no downloaded mesh, paid generation, external textures or new third-party obligations. No license is granted by this record; redistribution licensing remains the repository owner's decision.

## Validation

Blender topology passed: closed manifold, positive signed volume, zero degenerate faces, UV0 present. Both source scenes and Blender viewports were inspected. Godot **4.7.2 stable, Compatibility/OpenGL, RTX 4080 SUPER** imported and ran the complete assembly in a separate temporary project. Bounds, 28 triangles, material slots, opacity, unit normals, UVs, clockwise winding and attachment orientation passed. Housing and light termination gaps are zero. Twenty segment/triangle probes per cap verify closure across the actual recessed channel, rather than relying only on bounds. Godot front, rear, underside and end-on views of both ends were inspected without bloom. The silhouette visible behind the cap in exact end-on views is the existing module joiner farther along the rail.

Run `& ./src/assets/timeline_end_cap/verify_godot.ps1` from the repository root. Shared review scene, screenshots and separate import/reimport/runtime logs reside in `../timeline_end_cap/`. Each log reports the pre-existing Windows root certificate-store error; no asset import failures, script errors or validation failures occurred. The script preserves the user's editor and copies results only into the two cap folders.

The initial Godot MCP connection was blocked by another client; the CLI evidence above records that original run. A subsequent live MCP validation passed in the intended project on Godot 4.7.2 Forward+/D3D12. `godot_validate_meshes` checked all five unique assembly meshes with no integrity problems. Live fit checks passed all bounds/material/UV/normal/orientation/closure assertions, with zero housing/light termination gaps. Eight live game captures cover front, rear, underside and end-on views for both caps. The game runtime log contains no errors or warnings; editor messages contain competing-client rejection warnings but no asset/import/script errors. See `../timeline_end_cap/live_mcp/validation.json`, raw MCP receipts, screenshots and runtime log. Physics and animation are inapplicable to these static decorative caps.

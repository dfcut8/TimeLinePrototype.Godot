# Timeline rail housing — issue #5

Original reusable housing for the [V5 horizontal timeline](../../../docs/concepts/spatial-library-v5/README.md), implementing [issue #5](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5). Produced with live Blender MCP, Blender 5.2.2 LTS. No external mesh, texture, paid generation, or downloaded material is used.

![Housing front](preview_front.png)

## Resolved interface

One unit is one metre. The module measures **2.000 m long × 0.120 m high × 0.120 m deep**. The pivot is the earlier-end cross-section center. In Godot/glTF, +X advances chronology, +Y is up, and +Z faces the front. Blender uses +Z up and -Y front; the exporter converts axes. Object transforms are identity and the mesh holds the dimensions.

The front channel opens at Z = +0.060 m, Y = ±0.020 m. Chamfered lips narrow to Y = ±0.014 m at Z = +0.045 m. Its flat seat is at Z = +0.030 m. The channel is continuous along X. For issue #6, a provisional insert envelope is X = [0, 2], Y = ±0.012 m, Z = [0.031, 0.044] m: 2 mm clearance per side and 1 mm from the seat. This is an interface proposal, not a delivered insert or actual insert fit test.

Longitudinal outer chamfers are 14 mm. Mating end planes are exactly X = 0 and X = 2; they are deliberately not rounded along X. Place repeated modules at X = 0, 2, 4, etc. End faces close the housing solid around the channel, without filling the channel. The back and underside are finished. End caps and joiners remain separate issues. No heavy collar, fake text, emissive insert, collision, rig, or animation is included.

`timeline_rail_housing.tscn` is the reusable object, with the imported GLB and `EarlierEnd`, `LaterEnd`, and `LightChannelSeat` markers. `review_assembly.tscn` instances it three times plus the separate `review_rig.tscn`. There is no existing level to replace or main scene changed by this work.

The 2 m pitch is a concrete asset interface; larger room dimensions, event-panel scale, and orbit readability remain provisional. Seven modules would make the concept's exploratory 14 m neighborhood. This asset alone does not validate the full room or reader composition.

## Delivery and material

- `source/timeline_rail_housing.blend`: editable isolated asset scene and review studio, excluded from Godot import by `source/.gdignore`.
- `build_asset.py`: repeatable authoring, export, and topology validation; execute in live Blender with `__file__` set to this script path. Creates a new scene, preserving existing scenes. Export overwrites this asset's GLB/source/validation files.
- `render_previews.py`: front, rear, and underside Blender renders from the active asset review scene.
- `timeline_rail_housing.glb`: glTF 2.0 binary, **52 triangles, one mesh, one material surface**, 4,416 bytes; UV0 and flat face normals included. No external dependencies.
- `dimensions.svg`: dimensional drawing; `validation.json`: Blender topology and binary checks; `manifest.json`: delivery hashes.
- `verify_godot.ps1` / `verify_godot.gd`: isolated engine validation and six captured views.

The embedded `archive_graphite` material matches the existing cassette's documented parameters: linear base color (0.048, 0.060, 0.073), roughness 0.68, metallic 0.22, opaque, no emission or maps. Its editable Principled graph is in the Blender source. No texture maps are necessary for this uniform manufactured surface. No LOD is warranted for 52 triangles. The importer disables lossy mesh compression to preserve the small cross-section and disables automatic LOD generation.

Provenance: original procedural geometry and scripts authored for this repository from its V5 design direction. Concept pixels are not embedded. No third-party license obligations were introduced. The repository has no top-level license; redistribution licensing remains the repository owner's decision. This record does not grant a new license.

## Verification

Blender checks passed: zero non-manifold edges, zero degenerate faces, positive signed volume, UV layer present, GLB header/version/length valid, and one exported mesh/material. Source and viewport inspected through Blender MCP; front/rear/underside renders inspected separately.

Godot **4.7.2 stable**, Compatibility/OpenGL on NVIDIA RTX 4080 SUPER, imported and ran the three-instance review scene in an isolated temporary project. `godot_validation.json` records a pass for bounds (2 × .12 × .12 m), 52 triangles per instance, opaque matte PBR material, normals/UVs, triangle winding, attachment alignment, and both seam gaps at exactly zero. Front, rear, underside, end, seam close-up, and assembly PNGs are engine captures. Rear and underside surfaces and the open channel are visible; the assembly and seam close-up show continuous surfaces without a seam groove. No bloom is used.

Import and runtime logs were checked separately. Both contain `Failed to read the root certificate store`, an environment-level Windows error also emitted before loading the asset. Neither contains asset import failures, script errors, or validation failures. Logs are retained here as evidence.

Godot MCP initially had no connection; after starting the project editor, it reported another client already connected. That connection was left untouched. **Live-project MCP verification, `godot_validate_meshes`, and Forward+/D3D12 review remain incomplete.** The standalone validator checks winding, degeneracy, and normals as the explicit fallback; it is not represented as the MCP tool. Collision and animation checks are inapplicable to this static decorative housing. Final light-insert/end-cap assembly fit awaits those assets.

Rerun from the repository root in PowerShell:

```powershell
& ./src/assets/timeline_rail_housing/verify_godot.ps1
```

The script uses a fresh temporary project with an isolated editor profile and does not control the user's editor or MCP connection. It updates the engine report, screenshots, import settings, and logs in this asset directory. Regenerate the manifest after changing delivery files.

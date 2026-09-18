# Rail recessed light insert - issue #6

Original model for [issue #6](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/6), authored and exported through live Blender MCP (Blender 5.2.2 LTS). Reusable object: `rail_recessed_light_insert.tscn`.

![Insert](preview_front.png)

## Interface

One unit is one metre. Godot axes: +X chronology, +Y up, +Z front. Blender uses +Z up and -Y front; glTF performs the conversion. Identity object transforms; pivot matches the housing's earlier-end center, not the mesh center. Bounds are X [0,2], Y [-.012,.012], Z [.031,.044] m: **2 x .024 x .013 m**. EarlierEnd/LaterEnd markers lie at the end planes and Z=.0375.

The insert fits the existing housing without editing it: 1 mm from the channel seat, 2 mm lateral clearance, and 16 mm behind the outer front plane. A 1 mm chamfer runs along the long edges. End planes are square so instances at X=0,2,4 form an uninterrupted line. End caps remain separate tasks.

## Delivery

`source/rail_recessed_light_insert.blend` contains the editable mesh, UV0, material graph and review studio. `rail_recessed_light_insert.glb` is an opaque glTF 2.0 mesh: **28 triangles, one material**, no textures, animation, collision or external dependencies. No LOD is justified at this size. Import settings disable lossy compression and generated LODs to preserve millimetre interfaces.

Material `rail_pale_core`: linear base/emission RGB (.60,.86,.91), emission strength 1, roughness .68, metallic 0. The pale cyan-white surface reads without bloom. This is a replaceable authored PBR material, not a runtime lighting feature.

`build_asset.py` is the repeatable live-Blender authoring script and shared helper for the joiner. Execute with `runpy.run_path(path, run_name='__main__')` through Blender MCP. It creates a new scene without deleting existing work and overwrites only this asset's generated delivery files. `dimensions.svg` records the resolved drawing; `validation.json` records Blender topology checks. Preview renders cover front, rear, underside and end.

## Verification

Blender checks: closed manifold, positive volume, zero degenerate faces, UVs present. Godot **4.7.2 stable, Compatibility/OpenGL**, ran three housing/insert modules plus two joiners. Actual imported bounds, triangle counts, normals, winding, UVs, opaque material, pale emission and both zero-gap seams passed. The shared `godot_validation.json` contains the runtime result; engine screenshots and separate import/runtime logs are in `../rail_module_joiner/`.

Rerun from the repository root: `& ./src/assets/rail_module_joiner/verify_godot.ps1`. Review scene: `res://assets/rail_module_joiner/review_assembly.tscn`.

Godot MCP could not connect, first because the editor was closed, then because another client owned the bridge after startup. A separate temporary project was the explicit CLI fallback. Live MCP mesh validation and Forward+/D3D12 review remain incomplete. The fallback checks imported triangle winding and normals directly. Import and runtime logs contain only the pre-existing Windows root certificate store error, with no asset/script failures. Physics and animation are inapplicable to these static decorative models. Full-room camera/readability validation is outside these two model tasks.

Provenance: original geometry and scripts authored for this repository's V5 direction. No downloaded geometry, textures or paid generation. No third-party obligations introduced; redistribution licensing remains the repository owner's decision.

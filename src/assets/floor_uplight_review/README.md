# Floor and uplight delivery — #20 and #26

Two original models based on the repository's V5 architecture board and written issues. Each has editable Blender source, a reproducible authoring script, self-contained glTF 2.0 GLB, reusable Godot `.tscn`, documented materials, four Blender preview renders, topology results, exported-byte checks and SHA-256 manifest. This shared directory contains a review assembly composed entirely of object subscenes, a camera/light rig subscene, an executable Godot verification harness, GPU screenshots and logs.

## Resolved interfaces

One unit is one metre. [Drawing](dimensions.svg). The 4 m square slab establishes a local repeat grid, with a 250 mm thickness matching the existing gallery; no whole-room radius or camera path is fixed. Four instances form an 8 × 8 m flush patch. The fixture fits pier A's already-authored receiver, without modifying the pier. Its mounting clearances and diffuser dimensions are recorded in the [fixture notes](../base_uplight_recess_housing/README.md). Slab axes and seam details are in the [slab notes](../main_floor_slab/README.md).

These are static visual assets. No collision or animation is supplied; navigation/collision design and runtime lighting are outside the two issue scopes. No existing level or project configuration was changed. Sources alone are excluded from import with `.gdignore`; both object scenes and the review assembly are importable in the main project.

## Reproduce

1. Blender 5.2.2: `blender --background --python-exit-code 1 --python src/assets/main_floor_slab/build_asset.py`.
2. Run the equivalent command for `src/assets/base_uplight_recess_housing/build_asset.py`. It shares the slab's authoring module, so retain both directories.
3. Run `./src/assets/floor_uplight_review/verify_godot.ps1`. The optional `-Godot` argument selects the console executable; default is the installed 4.7.2 build. The runner creates a fresh temporary project, imports both assets and the existing pier A, disables lossy mesh compression/automatic LOD, runs the GPU harness, and copies evidence back. User editor sessions are untouched.
4. Run `python src/assets/floor_uplight_review/package_manifest.py` after final edits to check GLB bytes and refresh hashes.

Rebuild overwrites the corresponding generated artifacts. Review rig lighting is deliberately neutral and brighter than the eventual library; its lights are not part of either model.

## Validation evidence

Blender **5.2.2 LTS**: positive closed volumes, no nonmanifold edges, no degenerate faces, UV0 on every mesh. Front, rear, underside and side previews were visually inspected. A material-slot error found in the first housing export was corrected; final checks require exact imported palette names.

Godot **4.7.2-stable official**, Compatibility renderer, NVIDIA RTX 4080 SUPER: `godot_validation.json` reports no failed assertions. Both scenes import and render at their documented scale with identity mesh transforms, expected triangle/material counts, finite unit normals/UVs and correctly wound nondegenerate triangles. Twenty ray probes across tile seams verify no through gaps and a maximum 2 mm joint depression; four adjoining bounds meet exactly. Nine rays through the existing pier pocket verify the back at Z=0.18 and absence of interfering pier faces; fixture bounds have positive clearance on all six pocket planes. GPU captures cover tiled top, underside, seam closeup, pier assembly, mounted fixture and isolated front/rear/underside. No bloom is used.

Import/reimport logs and the separate runtime log were checked. They contain only the environment's Windows root-certificate-store error, with no asset import, script, mesh or validation errors. This certificate error does not affect local asset loading/rendering.

Both Blender MCP checks (`get_addon_status`, `get_scene_info`) failed to connect. Godot MCP `get_state` could not reach `ws://127.0.0.1:6550`. **No live MCP authoring or validation is claimed.** The explicitly reported fallback was isolated local Blender CLI authoring and local Godot CLI GPU validation. The MCP mesh validator was unavailable, so imported triangle data was checked directly in GDScript. Live verification requires the Blender MCP addon running and the intended Godot project open with its MCP addon enabled.

Remaining review limits: live MCP validation, full-room Forward Plus appearance, camera clearance/timeline readability and eventual curved floor perimeter fit. The isolated GPU checks do not establish those. Issues remain open for review; no PR was requested or created.

## Provenance

Original geometry and material parameter graphs authored locally, using `docs/concepts/spatial-library-v5/05-architecture-kit.png` as design reference. No downloaded meshes, paid generation, external textures or third-party attribution dependencies. No repository license was found; these assets inherit the repository's ownership terms and this delivery grants no new redistribution license. No canonical game-dev package certification is claimed.

Original request: “Pick up another 2 tasks from the issues to work on a 3d model. It is ok to implement both one at a time. Just work on both.” No image/model-generation prompt or negative prompt was used.

![Godot assembly](godot_assembly.png)
![Mounted fixture](godot_pocket.png)

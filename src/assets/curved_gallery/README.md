# Curved gallery slab and parapet — issue #19

Work for [#19](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/19), selected with PowerShell `Get-Random` from open required 3D-model issues. Optional furnishings were excluded because their briefs defer production; #32 was excluded because its model already exists locally.

**PR handoff:** when requested, delegate publication to the `pr` agent per root AGENTS.md. Include `Closes #19` in the PR description to link the issue and close it when the PR merges into the default branch. Keep the issue open until merge. Report the remaining acceptance limits below in the PR; resolve or explicitly agree them before merging. No PR has been opened by this model-production task.

## Delivery

- `curved_gallery.blend`: editable mesh, two material graphs, separate studio collection and camera. Review copies are hidden; enable their viewport/render visibility to inspect the repeated assembly.
- `curved_gallery.glb`: self-contained glTF 2.0, one watertight mesh, two material surfaces, **546 triangles**; no studio, camera, images or animations.
- `build_asset.py`: original parametric modeling source, topology/export checks and four preview renders. Run with Blender 5.2.2: `blender --background --python-exit-code 1 --python build_asset.py`. Rebuild overwrites only matching generated asset outputs beside the script. Refresh the manifest afterward.
- `dimensions.svg`: resolved cross-section and modular placement drawing.
- `preview_front.png`, `preview_rear.png`, `preview_underside.png`, `preview_assembly.png`: Blender Cycles review images, without bloom. All were visually inspected; the assembly shows five adjacent sectors at two heights.
- `validation.json`: measured Blender topology, export and fit evidence.
- `verify_godot.ps1`, `verify_godot.gd`, `godot_validation.json`: reproducible isolated Godot import and assembly checks, and their result.
- `manifest.json`: SHA-256 hashes and sizes of delivery files, excluding itself.

The `.gdignore` keeps this review bundle and its Blender source out of the main project's automatic importer. Validation imports a copy into a temporary Godot project. Actual scene integration is not part of this delivery.

## Dimensions and module interfaces

One unit is one meter. A **15° sector** spans radii **22–25.5 m**. The 3.5 m slab is 0.25 m thick. Its integral inner parapet is 0.18 m thick and rises 1.1 m above the walking deck. Exposed radial profile edges have 15 mm chamfers; sector end faces stay planar so joints do not form bevel grooves. Twenty-four arc divisions per sector limit radial chord error to 0.38 mm at the outer edge. Twenty-four instances close a full ring.

The pivot is the rotunda center at deck height, intentionally outside the mesh. Blender +Z maps to glTF/Godot +Y. Sector midpoint faces +X; Blender +Y maps to Godot -Z. End seams are at ±7.5° about the vertical axis. All object transforms are identity. Rotate successive instances by +15° about Godot +Y, without scaling or translation in the horizontal plane. Deck is Y=0, underside Y=-0.25, parapet top Y=1.1. A suggested 5 m tier pitch leaves **3.65 m** between the lower parapet top and the next slab underside.

For future Pier A (#16), proposed support seats are at each radial seam, radius 24.8 m, underside height -0.25 m relative to the tier. Proposed bearing area: 0.4 m radial × 0.3 m tangential, centered on each seam and shared by neighboring sectors. This is an interface reservation, not a structural engineering specification or a tested connection to an existing pier. No pier geometry is included.

The nearest faceted surface is radius 21.99967 m, leaving **1.99967 m** beyond the proposed 20 m radius central clear volume. These are local resolved dimensions within the exploratory V5 proportions, not approval of room scale, camera navigation or text readability. The 64 m chamber proposal would leave 6.5 m beyond the outer gallery edge.

The slab and parapet form one closed L-section, including underside and both exposed sector ends, with no intersecting component shells. At internal seams, opposing end closures coincide inside the assembly; outward surfaces meet at their boundary without overlaid faces. The ends remain finished when a sector is used alone.

## Materials, UVs and provenance

Embedded opaque `archive_graphite` uses linear RGB (0.048, 0.060, 0.073), roughness 0.68, metallic 0.22. `archive_basalt_ceramic` uses (0.085, 0.103, 0.117), roughness 0.81, metallic 0. These reuse the medium cassette's proposed palette. The deck and parapet walking side are ceramic; exterior/soffit are graphite. No texture maps, light fixtures, baked text or third-party assets are required. UV0 is packed after construction; geometric normals preserve planar cross-section faces and the fine arc facets. No LOD was authored without a measured need.

Original geometry created in Blender 5.2.2 LTS from the repository's V5 architecture concept and written issue. No paid provider or external mesh was used. No third-party attribution is required. No repository license was present, so this delivery does not assign a new redistribution license. The unavailable game-dev CLI was not used; this is not a CLI-certified canonical package.

## Validation and remaining acceptance

Blender checks passed: closed manifold edges, positive volume, nonzero face areas, UV0, identity transforms, material count, portable GLB structure/attributes, matching triangle counts and no external image dependencies. Authored seam discrepancy is 0.0029 mm.

Run `./verify_godot.ps1 -Godot '<path to Godot console executable>'` from PowerShell. It creates a uniquely named temporary project, isolates editor preferences, imports the GLB, applies the settings below, and checks six instances across three sectors and two tiers. It writes the result beside the model and retains temporary logs. The source project is configured for Godot 4.7; this check used **4.7.2.stable.official.ed1daf0bf**.

For precise modular seams set **meshes/force_disable_compression=true** and **meshes/generate_lods=false** in Advanced Import Settings. Default compression moved imported vertices enough to produce a 0.0527 mm seam discrepancy. With compression disabled, imported scale, normals, UVs, opaque matte material slots, 546 triangles, two-tier clearance and sector alignment all passed; seam discrepancy is **0.0021 mm**. The runner invalidates only its temporary mesh cache to ensure these settings take effect. Godot emitted an unrelated OS root-certificate-store warning in this sandbox; no network resources are used.

**Still pending:** actual fit against Pier A #16 (not implemented in this checkout), GPU appearance in the assembled game, full-room camera/strip readability and user art review. Headless import proves resource and assembly data, not GPU rendering. The preview images are Blender renders. These limits prevent claiming all issue acceptance criteria complete today.

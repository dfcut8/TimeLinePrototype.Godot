# Record stack shelf bay — issue #28

## Mixed-size reusable bay — 2 October 2026

`mixed_cassette_shelf_bay.tscn` combines this illuminated bay with 36 independent
small/medium/large cassette scenes. The [room review](../rail_shelf_room_review/README.md)
checks all three sizes together under translated/rotated parents, actual floor
support, architectural/portal clearance and four visible sides. Godot 4.7.2
Forward+/D3D12 passed with at least 27.198 mm structure, 41.999 mm light and
53.398 mm neighbor clearance. Live MCP and final art approval remain outstanding.

## Configurable repetition — issues #28 and #29

`../record_stack_end_cap/configurable_shelf_row.tscn` now repeats this bay's
illuminated scene at the established 1.6 m pitch, with four fixtures per bay
and caps tracking both ends. Set `bay_count` from 1 to 32; the default is three.
The row keeps a floor-center pivot and supports odd/even counts without scaling
the source objects. See the [row instructions](../record_stack_end_cap/README.md)
for attachment, persistence and dimension details.

Standalone Godot 4.7.2 Forward+/D3D12 passed 14 configuration and imported-fit
cases, including a 32-bay/128-fixture row under rotated parents. All bays retained
floor contact and fixture clearances; maximum seam error was below 0.004 mm.
Four runtime views were inspected. Reproduce with
`../record_stack_family/verify_configurable.ps1`. Original GLBs and Blender
sources are unchanged. Both live MCPs failed connection checks; live editor,
full-room and performance review remain incomplete. The count cap is not a
performance claim.

Reusable `record_stack_shelf_bay.tscn` contains the imported visual and shelf/join/light mounting markers. Records are separate scene instances in the review assembly, not part of this GLB. Editable source is `source/record_stack_shelf_bay.blend`; deterministic source is `../record_stack_family/build_asset.py -- bay` (run through Blender).

## Dimensions and interfaces

One unit is one meter. Godot/glTF +Y up, +Z aisle/front, +X along the row. Blender +Z up and -Y front. Pivot is floor center. Identity transforms, no instance scaling. Overall width × height × depth is **1.600 × 2.400 × 0.440 m**. Repeat at X increments of 1.600 m. Outer join planes are X ±0.800; internal openings span X ±0.750. Two touching 50 mm uprights form an intentional 100 mm divider between bays.

Shelf contact heights are Y **0.160, 0.720, 1.280, 1.840 m**. Each opening is 1.500 m wide, 0.520 m high, and 0.400 m deep (Z -0.180 to +0.220). The named `closed_back` is continuous and has four seated ceramic rear panels; gaps between the panels expose solid backing, not holes. Base height is 0.120 m. Finished undersides and both ends are included.

Four downward-open light recesses above the usable shelves reserve **1.500 × 0.012 × 0.050 m** (XYZ), centered at X=0, Z=0.175, Y=0.686/1.246/1.806/2.366. The named `LightRecess0..3` markers locate their centers. The completed #27 fixture is now instanced four times in `illuminated_shelf_bay.tscn`. New `LightMount0..3` markers locate its top-center origin 6 mm above each recess center: Y=0.692/1.252/1.812/2.372. The existing recess markers retain their original meaning. The 1.460 × 0.010 × 0.044 m fixtures contact the deck roof, clear each upright by 20 mm, leave 3 mm at either depth edge and 2 mm above the lip. The diffuser uses its existing subdued emission; no runtime light is added.

## Materials and geometry

660 triangles, 23 individually named mesh components, 3 opaque PBR materials. Palette matches existing cassettes: `archive_graphite` (linear RGB .048/.060/.073, roughness .68, metallic .22), `archive_basalt_ceramic` (.085/.103/.117, .81, 0), `archive_dark_panel` (.018/.026/.033, .76, 0). Embedded material parameters have no external map dependencies. UV0 exists on every mesh. Structural mating edges remain square to avoid seam gaps; exposed rear panels have 1 mm, two-segment bevels. No LOD is justified by measured requirements yet. No animation or collision is required for this static decorative asset.

## Validation and provenance

Blender 5.2.2 LTS checked every component for closed manifold edges, positive volume, nondegenerate faces, and UV presence; GLB 2 header and exported triangle totals were verified. `validation.json` records results and GLB hash. Four `preview_*.png` renders cover front/rear/side/underside.

Standalone Godot **4.7.2 stable**, Forward+/D3D12 on RTX 4080 SUPER imported the actual GLBs, checked normals, winding, UV area, material opacity/roughness, pivots, envelopes, row joins, and end-cap contact. Three bays and 108 independent existing cassette scenes passed shelf contact and clearance checks: minimum headroom ~40 mm and rear clearance ~49.1 mm. Runtime images and report are in `../record_stack_family/`. No asset/script errors remained; import and runtime logs separately contain the host Windows certificate-store error.

No live Blender MCP tools were exposed, so `get_addon_status`/`get_scene_info` could not be called. Godot MCP `get_state` failed to connect at ws://127.0.0.1:6550. This delivery used standalone Blender and isolated Godot processes, not MCP. To repeat live validation, expose/connect Blender MCP and enable Godot's MCP addon in this project's editor. Live `godot_validate_meshes`, shelf-light #27 fit, full room camera clearance, and performance acceptance remain unverified. Equivalent imported triangle checks ran in the standalone verifier.

Original project-authored geometry, generated by the included dimension-driven Python source; no downloaded meshes, paid generation, image textures, or third-party asset license. The repository's V5 furnishing concept is a visual reference only. No separate third-party license is introduced; distribution follows the project's chosen license. `manifest.json` records delivery hashes. Issues remain open for dependency/live review.

## Integration follow-up — issues #28 and #29

The reusable illuminated bay is used by `../record_stack_end_cap/capped_shelf_row.tscn` and `capped_shelf_alcove.tscn`. Both are directly importable furnishing scenes without cameras, review lighting or cassette dependencies. Original source and GLB geometry are unchanged. The row review retains 108 independently instanced cassettes of all three sizes.

Fresh standalone Godot 4.7.2 Forward+/D3D12 validation passed all 12 row fixtures' mounting contact, recess and upright clearances, unit scale, cassette fit, straight joins and rotated corner-run cap fit. Seven front/rear/end/underside runtime views were inspected. Import and runtime logs were checked separately; only the existing host root-certificate-store error remains. This supersedes the historical shelf-light integration gap above.

Both live Blender MCP calls failed to connect, and Godot MCP could not reach port 6550. Existing models needed no Blender edits; standalone Godot was the explicit engine fallback. Live MCP validation, full-room placement and performance remain pending.

## Integrated floor fit

The [grounded room review](../grounded_room_review/README.md) instances this asset
with the furnished library and delivered floor kit. It adds imported-triangle
support/clearance checks and GPU views in Godot 4.7.2, including a translated and
rotated placement. See that review for measured results and remaining limits.

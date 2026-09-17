# Medium archive record cassette

Model work for [GitHub issue #32](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/32), randomly selected from 29 open required model issues. Optional furnishings were excluded because their briefs defer production. Selection and the original request are recorded in `issue.json`.

**Staged for art review, not imported into Godot.** The local `.gdignore` prevents automatic resource import. Keep it until integration is explicitly requested. The GitHub issue remains open: actual shelf fit and Godot acceptance are still outstanding.

## Files

- `archive_record_medium.blend`: editable 16-part model, four material graphs, separate studio collection and review camera. Original user scene was preserved in the live Blender session and excluded from this file.
- `archive_record_medium.glb`: glTF 2.0, one mesh with four material surfaces; 1,728 triangles. No camera, studio geometry, animation, image or external dependency.
- `preview_front.png`, `preview_rear.png`, `preview_underside.png`: studio renders from Blender, without bloom.
- `dimensions.svg`: resolved front/side/top drawing with nominal body dimensions and the full detail envelope.
- `build_asset.py`, `export_validate.py`, `render_previews.py`: reproducible source, export checks and rendering. Execute in that order in Blender, with `__file__` set to each script's path. The build creates a new scene; export/render intentionally overwrite this folder's matching outputs.
- `validation.json`: measured mesh, material, dimensions, proposed clearance and GLB checks.
- `check_roundtrip.py`: re-imports the GLB into a temporary Blender scene, checks dimensions/counts and inspects the saved source library; removes the temporary objects afterward. Its visual-review entry records the production review, not an automated pixel test.
- `manifest.json`: file sizes and SHA-256 hashes for delivery integrity.

## Resolved dimensions and placement

One unit equals one meter. Nominal medium body is **85 mm wide × 270 mm deep × 400 mm high**. Index marks and inlays bring the complete envelope to **86.6 × 273.7 × 400 mm**. Bevels are modeled at fixed millimeter widths, not produced by stretching a smaller finished mesh.

Blender axes: X is thickness across a shelf row; -Y is the narrow indexed spine facing the aisle; +Z is up. The broad covers face ±X. Export uses glTF +Y up and +Z toward the spine front. Mesh and source parts have identity transforms. Pivot is at the nominal body's bottom center (0,0,0), not the asymmetric detail-envelope center. Shelf contact is Z=0 in Blender / Y=0 in glTF. There is no opening mechanism or mechanical attachment.

Proposed medium shelf allocation is 105 mm pitch × 300 mm clear depth × 440 mm clear height. This gives 9.2 mm lateral clearance per side, 26.3 mm total depth clearance and 40 mm headroom. Center the body at least 150 mm behind the shelf's front edge for that depth allocation. These are numerical envelope checks, **not a test against an existing shelf model**.

Issues #28 and #31 have no implemented model/dimensional interface in this checkout. The source proposes nominal small (65 × 220 × 320 mm), medium (85 × 270 × 400 mm), and large (105 × 320 × 480 mm) sizes sharing the same material names and bottom-center convention. Only the medium model is delivered. Coordinate these proposals with the future shelf and other cassette work; no other issue is claimed complete.

## Materials and UVs

Four self-contained opaque PBR materials: `archive_graphite`, `archive_basalt_ceramic`, `archive_dark_panel`, `archive_neutral_index`. Exact linear base colors, roughness and metallic factors are in `validation.json`. All are non-emissive; index marks are neutral geometric strokes, with no lettering or baked event text. Named materials are the proposed shared family palette, not dependencies on missing files.

No texture maps are required for this restrained solid-material treatment. UV0 islands were packed together after bevel generation. Geometry includes closed chassis, inset covers, spine panel, blank catalog mount and finished rear binding. Small component overlaps are deliberate seated construction; this is not a single fused printable solid. Planar faces and bevel facets use geometric normals.

## Validation boundary and provenance

Created originally with Blender MCP in Blender 5.2.2 LTS, using the repository's V5 furnishings board as a visual reference. No downloaded meshes, texture libraries, fonts, paid generation or external material assets were used. No third-party asset attribution is required. No repository license was present at production time; no new redistribution license is assigned by this handoff.

Automated checks verify closed manifold component meshes, positive signed volumes, no zero-area faces, UV presence, identity transforms, ground contact, provisional clearance, GLB header/length, one exported mesh/four surfaces, matching triangle counts, normals/UV attributes, and absence of images/cameras/animations. These checks are recorded rather than treating successful export alone as validation. Review renders expose spine/front, both broad covers, rear binding, top and underside.

Godot import, runtime material response, actual shelf assembly, camera-clear-volume placement, performance and full family consistency remain deferred. No LOD was added because no measured performance requirement yet justifies one. The unavailable `game-dev` CLI was not used, and this folder is not represented as a CLI-certified package.

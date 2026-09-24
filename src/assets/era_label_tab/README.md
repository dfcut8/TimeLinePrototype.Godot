# Era tab and label mount — issue #15

Original reusable model for [issue #15](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/15).
A small flat label on a short, fine mount, matching V5 board 03. It attaches to
the existing rail crown and remains separate from event strips.

![Era tab mounted on the rail in Godot](godot_front.png)

## Resolved interface

One unit = one metre. Godot/glTF +Y up, +Z front, +X chronology; Blender +Z up,
-Y front. Object transforms are identity. Root is the base's rail-contact plane.

| Feature | Metres |
| --- | --- |
| Total envelope | 0.320 wide × 0.155 high × 0.024 deep |
| Label plate | 0.320 × 0.070 × 0.008, center (0, .120, 0) |
| Label plate front | Z=.004; front corner radius .003 |
| Flat front | 0.318 × 0.068 |
| Reserved live-label rectangle | 0.296 × 0.048 |
| LabelOrigin | (0, .120, .005), 1 mm ahead of the face |
| Hairline stem | 10 mm diameter, Y=.009 to .087 |
| Seat | 24 mm maximum diameter, Y=0 to .012 |
| Rail placement | (chosen X, .060, 0), unit scale, zero rotation |

[Dimension drawing](dimensions.svg). The lower 18 mm diameter seat face contacts
the rail top; its 24 mm collar stays inside the flat crown. Stem/base and
stem/label engagement are intentional. The mount does not enter the front light
channel. The assembled tab top is Y=.215, below the upper event strip's lower
edge at Y=.558. Width is about 36% of the 900 mm event casing. These dimensions
establish model interfaces, not final typography or room/camera scale.

`era_label_tab.tscn` owns the model and attachment/live-label markers.
`review_assembly.tscn` instances it on the rail with the existing light and
review rig. The insert's joint review shows it among populated event strips.
No collision, rig, animation, live text, baked symbols or runtime tracking is
included; this static decorative label uses future presentation elements.

## Delivery

Three closed meshes, **404 triangles**, two shared embedded materials, four
surfaces: RailTopSeat 124; HairlineMount 124; EraLabel 156 (138 trim/rear + 18
front). Matte non-emissive `archive_graphite` uses linear RGB (.048,.060,.073);
the label front uses `archive_basalt_ceramic` (.095,.112,.125). Both use roughness
.68 and metallic .22, with no textures or external dependencies. Front UVs are
continuous planar 0–1; plate trim has packed triangle islands. Cylindrical mounts
use nondegenerate triangle-local UVs appropriate for uniform materials; a painted
mount would need a dedicated atlas. All sides, ends and undersides are finished.

`source/era_label_tab.blend` contains editable meshes/materials and the review
studio, excluded from Godot import. `build_asset.py` reuses the insert's rounded
plate builder and tracked socket helpers. Rebuild with Blender after checking
live MCP connectivity; it creates a new isolated scene and refreshes only this
asset's exports. Four Blender previews and five Godot close-up captures are
included, along with dimensions, topology/GLB/engine reports and a SHA-256 manifest.

## Verification and limits

Blender **5.2.2 LTS** verified closed manifold geometry, positive volume and no
degenerate faces. Godot **4.7.2 stable / Forward+ / D3D12 / RTX 4080 SUPER**
verified import, 404 triangles, scale, material slots, winding/normals/UV areas,
actual rail-top contact, front-light clearance and separation from neighboring
records. Inspected front, rear, side/end, underside and seat-detail captures
without bloom. See the joint `godot_validation.json` and the insert folder's
separate import/reimport/runtime logs. Only the pre-existing Windows certificate
store error occurred; no asset/script/test errors.

Run `./src/assets/event_strip_insert/verify_godot.ps1` from the repository root
to reproduce the joint checks in an isolated temporary project. Full rotunda
scale, live label readability, camera movement and performance remain unvalidated.
No LOD was added without a measured need.

Blender MCP addon-status and scene-info checks failed; authoring used a separate
background Blender process. Godot MCP get-state and validate-meshes checks could
not reach the bridge at port 6550; standalone imported-mesh checks and engine
captures were the fallback. **Live MCP validation remains incomplete** pending
the Blender addon listener and Godot bridge connections. No MCP success is claimed.

Provenance: original procedural project artwork based on V5, with no downloaded
assets or external license obligations. No repository-wide license is assigned
by this delivery. The optional game-dev CLI was unavailable; files follow the
existing repository delivery convention.

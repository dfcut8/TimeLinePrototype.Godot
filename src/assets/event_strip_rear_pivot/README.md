# Event strip rear pivot — issue #12

Original two-axis joint for [issue #12](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/12),
authored/exported through live Blender MCP in Blender 5.2.2 LTS. Fits the existing
issue #11 connector and the issue #13 casing. All pre-existing Blender scenes
were preserved. Source, GLB and reusable Godot scene are included.

![Pivot and casing rear in Godot](../event_strip_casing/godot_pivot.png)

## Resolved interface

One unit = one metre. Godot/glTF +Y up, +Z toward the panel front; Blender +Z
up, -Y front. Root is the connector's 20 mm diameter terminal face. Place the
root at the arm's `PivotAttachment`, with matching rotation and unit scale.

| Interface | Local Godot coordinates / size |
| --- | --- |
| Connector seat | (0, 0, 0), diameter 0.020 m |
| Yaw axis | +Y through (0, 0.030, 0) |
| Pitch axis | local +X through (0, 0.140, 0) at neutral yaw |
| Panel attachment | (0, 0.140, 0.085) in the neutral pose |
| Panel mating face | diameter 0.048 m, faces +Z |
| Neutral total envelope | X ±0.039; Y 0–0.168; Z -0.022–0.085 m |
| Yoke inner width | 0.052 m; axle end faces at X ±0.026 m |

[Dimension drawing](dimensions.svg). The yaw collar, continuous U-shaped yoke,
pitch axle, stem and flange remain separate functional parts. Bearing contact
and stem/axle/flange engagement are intentional. The yoke itself is one closed
mesh with no overlapping bridge/cheek surfaces.

`yaw_degrees` and `pitch_degrees` expose static poses, clamped to ±60° yaw and
±20° pitch. These are supported model clearances, **not unrestricted orbit tracking**.
No animation or automatic camera behavior is added. Attach a panel beneath
`Model/Yaw/Pitch/PanelAttachment`; see the casing's `review_event.tscn` for an
instanced example. Object rotations/scales are identity; the Yaw/Pitch nodes
carry the documented translations. Inverting the whole assembly places it below
the rail; future presentation must keep live content upright independently.

## Delivery

- `source/event_strip_rear_pivot.blend`: editable geometry and review studio,
  isolated from unrelated scenes. `.gdignore` excludes authoring source from Godot.
- `event_strip_rear_pivot.glb`: 1,064 triangles, six meshes/surfaces, two materials.
- `event_strip_rear_pivot.tscn` and `.gd`: reusable scene and bounded pose controls.
- `build_asset.py`: run via live Blender MCP after inspecting the current scene;
  uses the existing `event_socket/build_asset.py` helpers. Creates a new scene.
- Four Blender previews, mesh validation report and SHA-256 manifest.
- Joint Godot report is also copied here; captures/logs/reproduction script live
  in `../event_strip_casing/`.

Opaque, non-emissive shared-palette materials: graphite linear RGB
(0.048, 0.060, 0.073), bearing ceramic (0.095, 0.112, 0.125), both roughness
0.68 / metallic 0.22. Materials are embedded, with no external maps/dependencies.
Names may have Blender uniqueness suffixes; values define the palette. UV0 uses
nondegenerate triangle-local projections for uniform materials; painting would
require a dedicated nonoverlapping atlas. Flat geometric normals retain small
faceted chamfers. No LOD is justified without a measured performance need.

## Validation and limits

Blender: every component is closed/manifold, with positive volume and no
zero-area faces. Scene/viewport and all-side review renders were inspected.
Godot 4.7.2 Forward+/D3D12 ran an isolated assembly on the RTX 4080 SUPER.
Imported triangle counts, normals/winding, UV areas, opaque material slots,
scale, axes, connector/panel seams, angle clamps and pre-ready configuration
passed. 450 poses cover both above/below assemblies in 5° steps. The casing
remains at least 7.72 mm above the connector-end plane and 30.67 mm ahead of
the yoke's front envelope in its local yaw frame across sampled poses.
These are conservative shell-envelope tests, not a general physics simulation.

Godot MCP `get_state` and `godot_validate_meshes` were blocked by another
connected client. That client must disconnect before this task can use the
live project's bridge. Live-project MCP validation remains incomplete; the
fallback uses explicit mesh-array checks and actual engine renders. Separate
editor import/reimport and game logs contain only the pre-existing Windows
root-certificate-store error, with no asset/script/test errors.

Full room-scale/readability, unrestricted orbit, runtime tracking and performance
remain outside this model delivery. Original procedural project artwork based
on the V5 concept boards; no downloaded assets or third-party licensing claims.
The repository has no top-level license; redistribution is the owner's decision.

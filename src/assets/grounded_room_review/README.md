# Grounded library room — issues #5, #24, #25 and #28

![Godot room overview](godot_overview.png)

This follow-up integrates the existing furnished room with a reusable continuous
floor assembly. It replaces the earlier placement study's floor datum with real
imported floor meshes. Original models, materials and Blender sources are reused.

| Issue | Work completed in this review |
| --- | --- |
| [#5 Rail housing](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5) | Seven-module 14 m rail over the finished floor; 1.437 m minimum mesh clearance and 29 floor coverage probes along its projection. |
| [#24 Wall infill](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | Twenty wall bays on actual floor geometry, including their support corners, floor datum and existing wraparound pier joins. |
| [#25 Portal frame](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | Both jamb pairs supported; 250 probes cover the two 3 m wide approaches from 1 m outside to 5 m inside. Opening probes confirm no threshold lip. |
| [#28 Shelf bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/28) | Eight illuminated, populated bays supported by floor meshes; existing cassette, closed-back, fixture and wall-clearance checks run again in the assembled room. |

## Use

Run `review_room.tscn`. Instance `grounded_room.tscn` to reuse the room without
camera/lights, or `library_floor.tscn` to reuse only the floor. Every distinct
object is an existing PackedScene instance. The main application is unchanged.

The floor contains 100 unscaled 4 m slabs and four unscaled curved wedges.
Tile centres span -18 to +18 m in 4 m steps on X/Z. Wedges share the room-centre
pivot with 0/90/180/270 degree yaw. Floor top is Y=0, underside Y=-0.25 m,
and radius is 32 m. The existing perimeter remains at pier radius 24.8 m,
leaving an exterior floor apron; this preserves both delivered kits' dimensions.
The floor has 4,352 triangles and uses the existing matte ceramic material.

## Evidence

Standalone **Godot 4.7.2 stable, Forward+/D3D12** passed at identity and after
translation (8,2,-6) m and yaw 0.71 rad. Per placement:

- 224 floor support probes across 56 bays, piers and shelves; base datum error
  below 0.1 mm (reported maximum 0 at these placements).
- 250 portal floor probes, 29 rail projection probes and 440 seam locations.
- Seam probes test both sides at +/-0.01 mm to avoid triangle-edge numerical
  ambiguity. This is a 0.02 mm tolerance, not proof of mathematically zero gaps.
  Vertical support tolerance admits the floor kit's documented 2 mm chamfer.
- Negative controls reject a point beyond the floor and a point 10 mm above it.
- Inherited room/furnishing checks pass for bay joins, portal openings, 448 shelf
  cassettes, end caps and peripheral stations.
- Representative slab/wedge imported triangles pass winding, normals, UV area
  and opaque matte material checks.

`godot_validation.json` records measurements. Import and runtime logs were
checked separately: only the existing host certificate-store error appears,
with no asset, scene or script failures. Overview, portal, shelf and rail GPU
captures were visually inspected. Closeups use perspective cameras to avoid
orthographic near-plane floor clipping. Thin floor seams alias at room scale;
these captures are fit evidence, not a final lighting or anti-aliasing pass.

## Reproduce

From the repository root:

```powershell
python src/assets/grounded_room_review/create_review.py
./src/assets/grounded_room_review/verify_grounded.ps1
```

The verifier copies the explicit resource dependency closure and existing GLB
import settings into a unique temporary project, isolates editor preferences,
imports, runs GPU checks, and copies successful evidence back. The temporary
project is retained. `-Godot` overrides the pinned executable.

## Remaining review

On 2 October 2026, Blender MCP `get_addon_status` and `get_scene_info` could not
connect. Godot MCP `get_state` could not reach ws://127.0.0.1:6550. No Blender
authoring was needed. Standalone Godot is the explicit fallback; live MCP and
`godot_validate_meshes` remain unavailable. Enable Blender's addon server and
open this project in Godot with its MCP addon to restore live review.

This completes floor-fit follow-ups, not every acceptance gate on the four
issues. Art approval, roof integration, interactive camera, text readability
and measured performance remain separate. The delivered floor is visual mesh
geometry, without collision or navigation. Issues remain open; no PR is created.

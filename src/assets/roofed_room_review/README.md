# Single-storey roof-frame fit — issues #24, #25, #31 and #33

![Godot overview](godot_overview.png)

This reusable assembly places the existing roof beams and oculus curb on the
grounded library's actual piers, completing an overhead-fit follow-up for four
open model issues. All meshes, materials, GLBs and editable Blender sources are
reused unchanged. The roof is an open frame, without roof panels.

| Issue | Work in this delivery |
| --- | --- |
| [#24 Wall infill](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | Integrates the overhead frame with 20 wall bays and their shared piers; checks every bay against every roof component for penetration and reruns wall, join and floor checks. |
| [#25 Portal frame](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | Verifies both 3 × 3.4 m openings and their approach volumes remain free of roof geometry, with continuous floor support and a rendered doorway view. |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | Reviews 272 independent records in four populated shelves under the frame; reruns shelf support, neighbor, wall and light clearances and captures a shelf view. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | Reviews 176 independent records in four populated shelves under the frame, including the tighter fixture gap, and captures a shelf view. |

## Use and dimensions

Run `review_room.tscn`. Instance `roofed_room.tscn` to reuse the assembled room
without review lighting/camera, or `library_roof_frame.tscn` to reuse just the
24 beams and 24 curb sectors. Components are existing PackedScene instances;
the assembly shares the room's existing 24 piers rather than duplicating them.
The application main scene is unchanged.

This is an explicit **single-storey proportion study**. It uses the existing
4.75 m pier/header datum, rather than the older roof-only review's unsupported
10 m upper-tier offset. Beam undersides sit at Y=4.75 m, curb undersides at
Y=4.15 m, and beam tops at Y=5.30 m. All instance scales are one. The room origin
is floor centre, +Y up; one unit is one metre.

For pier index `i`, roof yaw is `97.5 - 15*i` degrees. Curbs share the room-centre
pivot; beam inner ends sit at radius 10.15 m. Outer bearing markers at beam-local
X=14.65 m meet the room piers at radius 24.8 m. The 7.5-degree offset matches
piers between bays. The existing oculus retains a nominal 20 m clear diameter.
No claim of structural engineering suitability is made by these visual contacts.

## Fresh engine evidence

`godot_validation.json` records passing standalone **Godot 4.7.2 stable,
Forward+/D3D12** checks at identity and at translation (8,2,-6) m with yaw 0.71 rad:

- 288 paired triangle probes per placement confirm actual inner/outer bearing
  surfaces, with measured contact error zero. Marker error is below 0.004 mm.
- All 24 curb seams, including the closing seam, agree within 0.0022 mm.
  Seam measurements use raw imported surface vertices; intersection queries
  use triangle faces. Their different precision is not conflated.
- Every beam remains inside its angular sector. All bays avoid roof penetration;
  both portal approach volumes remain clear. A ray misses the open oculus and
  a positive control hits its curb.
- The lowest roof plane is 1.75 m above the populated shelf envelopes. All 448
  records retain shelf support and nonoverlap; the minimum fixture gap is 42 mm.
- Inherited checks pass for floor support, floor seams, rail clearance, wall
  joins, portal approaches, cassette contacts and optional furnishings.
- 720 camera samples at radii 9/10.3/12/16/19 m, heights 1.8/3.5 m and 5-degree
  intervals clear all mesh AABBs with a 0.3 m camera envelope. Minimum remaining
  clearance is 0.35 m. Negative controls reject cameras inside the curb and
  intersecting the floor. This does not approve the former open-room 8 m orbit
  as an interior path, nor establish continuous camera movement safety.
- Representative roof meshes pass imported winding, UV area and opaque matte
  material checks: 396 triangles per curb, 28 per beam (10,176 frame triangles).

Six GPU captures were visually inspected: overview, portal, small shelf, large
shelf, outer bearing and interior. No geometry is hidden for these captures.
The existing neutral review lighting and floor seam aliasing remain visible;
this is fit evidence, not a final lighting or antialiasing pass.

Import and runtime logs were inspected separately. Both contain only the known
host Windows certificate-store error, with no asset, scene or script failures.

## Reproduce

From the repository root:

```powershell
python src/assets/roofed_room_review/create_review.py
./src/assets/roofed_room_review/verify_roofed.ps1
```

`-Godot` overrides the pinned executable. The runner copies the resource dependency
closure and existing GLB import settings into a unique temporary project,
isolates editor preferences, imports, runs the GPU verifier and publishes
successful evidence. It retains the temporary project and separate logs.

## Remaining acceptance gates

On 2 October 2026, Blender MCP `get_addon_status` and `get_scene_info` both failed
to connect. Godot MCP `get_state` could not reach ws://127.0.0.1:6550. No Blender
authoring was needed. Standalone Godot supplied engine validation; live MCP
validation remains incomplete. Restore Blender's addon server and open this
project in Godot with the MCP addon enabled for live review.

These four overhead-fit follow-ups are complete. The issues remain open because
final art/proportion approval is not established by automated checks. The scene
also does not implement roof panels, structural simulation, collision/navigation,
interactive cameras, event text/readability or measured performance acceptance.

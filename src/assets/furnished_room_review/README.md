# Furnished room placement — issues #29, #34, #35 and #36

![Peripheral reading station in Godot](godot_station_front.png)

This optional placement study integrates the existing end caps, lectern, bench
and cassette display with the previously verified library room. All models,
materials, editable Blender sources and imported asset settings are reused.
It adds no geometry and does not change the base room or application settings.

| Issue | Implemented and checked |
| --- | --- |
| [#29 End caps](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/29) | Sixteen caps finish both ends of all eight populated shelves. Imported bounds verify contact, floor/header alignment and full depth coverage. |
| [#34 Catalog lectern](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34) | Four inward-facing lecterns at peripheral stations. Checks cover floor datum, unit scale, opaque matte materials and inward screen slope. |
| [#35 Reading bench](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/35) | Four benches beside lecterns, outside the central clear volume. Both feet contact the floor datum; furniture clears shelves, walls and portal approaches. |
| [#36 Display plinth](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36) | Four reusable display assemblies, each with an independently instanced large cassette. Checks verify support contact and margins clear of the top bevel. |

## Use and dimensions

Run `review_room.tscn` for the overview. Instance `furnished_room.tscn` for the
complete study without camera or lights. `reading_station.tscn`,
`cassette_display.tscn` and `shelf_end_pair.tscn` are independently reusable.
Every distinct object is an existing PackedScene instance.

The room's floor-centre pivot, +Y up and metre units remain unchanged. Each cap
pair aligns to a shelf at radius 23 m, with caps at local X = -0.8/+0.8 m and
yaw 180/0 degrees. Stations lie at radius 22.4 m, angles 45/135/225/315 degrees
measured clockwise from -Z. Their +Z faces the room centre. Within each station,
bench, lectern and display centres lie at X = -1.3/0.4/1.7 m. The cassette rests
at Y = 0.6 m on its plinth. All object scales are one.

## Engine evidence

Standalone **Godot 4.7.2 stable, Forward+/D3D12** passed the following checks at
identity and after translating the assembly (8,2,-6) m and yawing it 0.71 rad:

- Maximum cap join error: **0.0012 mm**, below the 0.1 mm tolerance.
- Maximum cassette/plinth support error: **0.00012 mm**; minimum edge margin
  **112.2 mm**, exceeding the 8 mm bevel exclusion.
- Conservative added-furniture clear radius: **21.3995 m**, outside the proposed
  20 m camera volume radius. Furniture envelopes do not overlap one another.
- Minimum horizontal separation from stations to shelves/architecture:
  **1.6120 m**, measured conservatively in each station's coordinate frame.
- Both 3 × 3.4 m portal approaches remain clear, extending 5 m inward.
- **648 camera samples**, radii 12/16/19 m, heights 1.8/4/8 m, 5-degree steps,
  with a 0.3 m envelope: minimum imported-mesh AABB clearance **2.4378 m**.
- Existing room checks still pass: perimeter seams, portal triangle probes,
  and support/fixture clearance for 448 shelf cassettes.
- Representative imported caps and furniture pass normals, triangle winding,
  UV area and opaque matte material checks.

`godot_validation.json` records results. Separate `furnished_import.log` and
`furnished_runtime.log` contain the existing Windows certificate-store error
only, with no scene, asset or script errors. Four GPU captures were inspected:
overview, station front, station rear cutaway and capped shelf. The rear cutaway
temporarily hides the perimeter for inspection; all measurements and the other
captures use the complete assembly. There is no bloom.

## Reproduce

From the repository root:

```powershell
python src/assets/furnished_room_review/create_review.py
./src/assets/furnished_room_review/verify_furnished.ps1
```

The verifier copies the explicit scene/script resource dependency closure and
GLB import settings into a unique temporary project. It isolates editor
preferences, imports assets, runs GPU checks, copies successful evidence back,
and retains the temporary project for inspection. `-Godot` overrides the pinned
executable. The source project editor is not opened or modified.

## Acceptance limits

On 2 October 2026, Blender MCP `get_addon_status` and `get_scene_info` failed to
connect, and Godot MCP `get_state` could not reach ws://127.0.0.1:6550. No Blender
authoring was needed. Standalone Godot is the explicit fallback; live MCP review
and `godot_validate_meshes` were unavailable. To enable them, run Blender's addon
server and open this project in Godot with its MCP addon enabled.

This is a static placement study pending art approval, not approved production
room dressing. The floor is a Y=0 datum, not an integrated floor mesh or physics
surface. Floor/roof integration, interactive camera behavior, timeline text
readability and measured performance remain separate. Sampled camera clearance
does not prove every possible path. No interaction, animation or collision is
added. The four GitHub issues remain open for their remaining reviews.

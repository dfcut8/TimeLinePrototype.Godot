# Configurable library kit — issues #24, #25, #28 and #29

![Entrance sector in Godot](godot_sector_front.png)

Four reusable assembly follow-ups to the existing model packages. All visuals
remain independent PackedScene instances; existing GLBs, Blender sources,
materials and import settings are reused.

| Issue | Delivered behavior |
| --- | --- |
| [#24 Wall infill](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | Configurable wall/portal/window arcs, including a saved 24-bay perimeter with a shared closing pier. |
| [#25 Portal frame](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | A configurable three-bay portal sector, approach markers and a furnished entrance assembly with an unobstructed 3 × 3.4 m opening. |
| [#28 Shelf bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/28) | Configurable cassette patterns and zero to nine independent records on each of four illuminated shelves. |
| [#29 End cap](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/29) | Capped populated rows with adjustable length, density and cassette pattern; both handed end closures follow the row ends. |

## Architecture

Instance [configurable_bay_arc.tscn](../wall_infill_bay/configurable_bay_arc.tscn).
Its root is the room centre at floor level, with metre units and +Y up.
**bay_layout** is an ordered PackedInt32Array: 0 = wall, 1 = portal, 2 = window.
It contains one to 24 entries; empty input becomes one wall, extra entries are
truncated and invalid codes clamp to 0–2. The default is [0,1,2]. Assign a new
array to apply edits.

**start_angle_degrees** locates the first bay, clockwise from -Z, and clamps to
±180 degrees (default -15). Bays face inward. Pitch stays at 15 degrees,
pier radius at 24.8 m and chord radius at 24.587832 m. These fixed dimensions
preserve the delivered unscaled bay/pier interfaces. Open arcs share count+1
piers; a 24-bay ring shares exactly 24, including the last-to-first join.
The narrow existing pier reveals remain intentional.

[library_perimeter.tscn](../wall_infill_bay/library_perimeter.tscn) saves a full
ring: portals at 0/180 degrees, windows at 90/270 and walls elsewhere.
[portal_bay_arc.tscn](../passage_portal_bay_frame/portal_bay_arc.tscn) saves
[0,1,0], centred on -Z. The portal object adds InsideApproach at (0,0,5) and
OutsideApproach at (0,0,-1), both at floor level. Reserve a 3 m wide, 3.4 m high
approach between these markers. They are placement interfaces; the model has
no door or movement behavior.

## Storage

Instance [configurable_cassette_shelf_bay.tscn](../record_stack_shelf_bay/configurable_cassette_shelf_bay.tscn).
**cassette_pattern** repeats left to right on every tier: 0 = small, 1 = medium,
2 = large. The default is [0,1,2]; empty input becomes [0], codes clamp to 0–2,
and only the first nine entries are retained. **records_per_shelf** clamps to
0–9, default 9. Zero leaves all decks empty while retaining the lights.

The floor-centre pivot, +Z aisle front and 1.6 × 2.4 × 0.44 m envelope match the
existing shelf. Records use 150 mm X pitch, centred on each deck. Contacts are
Y=0.16/0.72/1.28/1.84 m; size-specific Z offsets of 0.080/0.055/0.030 m align
the nominal front spines. Keep the object's support/container transforms at
their saved values and use the root for placement.

[configurable_populated_shelf_row.tscn](../record_stack_end_cap/configurable_populated_shelf_row.tscn)
inherits the existing capped-row behavior, selects the new populated bay and
defaults to two bays. **bay_count** clamps to 1–32; width is 1.6 × count + 0.164 m.
Population settings propagate to all generated bays. Population edits retain
bay instances and their user attachments; count or bay-scene changes replace
generated bays. The inherited **bay_scene** override remains available;
population settings apply to the built-in configurable cassette bay.

All three scripts run in the Inspector and at runtime without frame polling.
Array getters return copies. Generated nodes have no saved owner: saving stores
configuration and rebuilds once on load. Persistent user attachments belong
under the object root or its Bays/Piers/Records container, with names other than
the generated BayN/PierN/Record_tier_slot names. Attachments inside a generated
object share that object's replacement lifetime. Editor interaction remains
unverified through the disconnected live MCP.

## Entrance assembly and engine evidence

[library_entrance_sector.tscn](../passage_portal_bay_frame/library_entrance_sector.tscn)
combines the portal arc with two two-bay capped rows at radius 22.8 m, angles
-15/+15 degrees. The rows face inward. Left density is nine records per tier
with [0,1,2]; right density is six with [2,1,0], for 120 records total. This
importable sector has no review camera or floor. [review_sector.tscn](review_sector.tscn)
adds the existing floor and review rig as scene instances. It is a static
placement study.

On **14 October 2026**, standalone **Godot 4.7.2 stable official,
Forward+/D3D12, RTX 4080 SUPER** passed:

- **19 arc inspections**, including pre-ready configuration, all bay types,
  23/24/25-entry boundary cases, clamps, translated/rotated placement,
  detached updates, saved variants and disk save/reload. **2,540 imported
  triangle probes** check solid walls, portal openings/jambs/headers and window
  apertures/sills. Bay/pier separation is **8.685–8.693 mm**.
- **88 shelf inspections**, including shelves inside tested rows, empty/full
  density, all three sizes, repeating/reversed patterns, invalid inputs,
  independent instances and disk serialization with user attachments.
  Actual imported shelf-surface probes supplement bounding-box measurements.
  Maximum contact error is **0.00012 mm**; minimum structural clearance is
  **27.197 mm**, light gap **41.999 mm** and neighboring record gap **43.399 mm**.
  Consecutive large cassettes set the smallest neighbor gap. Floating and
  unsupported cassette controls fail the support probe as expected.
- **14 capped-row inspections**, including odd/even lengths, 32 empty bays,
  resize, population updates, transformed placement, detach/reentry and
  disk roundtrip. Maximum bay/cap join error is **0.00191 mm**.
- **Two entrance placements**, identity and translation (8,2,-6) m with
  0.71 radian Y rotation. **314 actual floor probes** check row/cap bases and
  the portal approach. Both rows clear the approach and each other, with at
  least **1.4448 m** setback from the wall face.
- Imported meshes pass winding/area, normals, UV area and opaque matte material
  checks. Both import and runtime logs contain no errors or warnings.

Six GPU captures were visually inspected: entrance front, portal, row front,
rear, end and underside. The floor and other sector objects are hidden only
for the three isolated row views. Existing review lighting and floor seam
aliasing remain visible; no lighting or material edits are included.
Detailed measurements are in [godot_validation.json](godot_validation.json).

## Reproduce and remaining acceptance

From the repository root:

~~~powershell
./src/assets/modular_library_review/verify_modular.ps1
python src/assets/modular_library_review/update_manifests.py
~~~

The verifier accepts -Godot, stages 73 resource dependencies with their GLB
import settings in a unique retained project under src/.godot/, isolates
roaming/local preferences, imports and runs GPU verification. Each engine
process has a 60-second timeout. Review evidence is excluded from the main
project by .gdignore; all delivered object scenes are importable.

Blender MCP get_addon_status and get_scene_info failed to connect.
Godot MCP godot_editor_read(get_state) could not reach ws://127.0.0.1:6550.
No Blender authoring was required. Standalone Godot was the explicit validation
fallback. Live review requires Blender's addon server and the intended project
open in Godot with its MCP addon enabled. The unavailable MCP mesh validator is
not claimed; the verifier supplies imported-triangle evidence.

These four follow-ups are implemented and tested. Issues remain open for live
review and final art/proportion approval. Roof fit, physics, interaction,
continuous camera motion, text readability and measured performance are outside
this assembly delivery. Original asset provenance and repository ownership
terms apply; no external models, paid generation or new license is introduced.

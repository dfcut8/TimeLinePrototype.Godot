# Archive storage islands — issues #28, #29, #31 and #33

![Small-cassette face in Godot](godot_front.png)

Four assembly fit tasks for the existing model issues. The island combines two
complete, closed-back shelf rows facing outward. Shelves, four end caps, shelf
lights and every cassette remain independently instanced reusable scenes.
Existing Blender sources, GLBs, materials and import settings are reused.

| Issue | Delivered task |
| --- | --- |
| [#28 Shelf bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/28) | Two outward-facing rows with an adjustable, measured separation between their finished backs; closed-back surfaces and adjacent bay continuity are checked in Godot. |
| [#29 End cap](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/29) | Both exposed ends of both rows use the existing cap scene, rotated without mirroring. All four caps retain their identities through length edits. |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | Independent front/back population settings and a saved all-small island. Default capacity is 16 small records per deck, 256 in a two-bay island. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | A saved all-large island, plus large and mixed populations on either face. Default capacity is 11 large records per deck, 176 in a two-bay island. |

## Object interfaces

Instance [configurable_archive_island.tscn](../record_stack_end_cap/configurable_archive_island.tscn),
[small_archive_island.tscn](../archive_record_small/small_archive_island.tscn) or
[large_archive_island.tscn](../archive_record_large/large_archive_island.tscn).
The root is at floor centre, +Y up, +X along the rows. FrontRow faces +Z;
BackRow faces -Z using a 180° rotation. Keep child transforms at their saved
values; place and rotate the whole object by its root. Units are metres.

The default split island has small records on the front and large on the back:
128 small plus 88 large records across its two rows. It is 3.364 m wide,
2.4 m high and 0.92 m deep. Both nominal 0.44 m row envelopes remain unscaled.

| Exported property | Default | Meaning |
| --- | --- | --- |
| bay_count | 2 | 1–4 bays per face. Total width = 1.6 × count + 0.164 m. |
| back_gap | 0.04 m | 0.04–0.30 m between complete row envelopes, including the closed backs and caps. Total depth = 0.88 + gap. |
| approach_depth | 1.2 m | 1.2–2.0 m outside each face, across the entire capped width. |
| front_pattern, back_pattern | [0], [2] | Ordered repeating patterns: 0=small, 1=medium, 2=large. Codes clamp to 0–2; only the first nine entries are retained. Empty becomes [0]. |
| front_records_per_shelf, back_records_per_shelf | 32 | Independent requests, clamped to 0–32. Zero empties that face. Each existing packed bay truncates to its maximal fitting prefix. |
| front_record_gap, back_record_gap | 0.02 m | Independent gaps of 0.02–0.15 m between the actual cassette envelopes. |

Pattern getters return copies; reassign arrays to apply changes. Population
changes retain both rows, their bay objects and all caps. Editing one face retains
the opposite face's records. Count changes replace generated bays in both rows,
while back-gap and approach edits retain all model instances. Use **Attachments**
for persistent additions. Generated objects have no owner; only configuration
is serialized. Nested instance additions require Godot's usual editable-children
and ownership setup.

get_body_bounds() returns the local capped geometry envelope.
get_approach_bounds(front=true) returns a local AABB, 2 m high, beyond either
face. **FrontApproach** and **BackApproach** mark the centres at floor level.
These are layout interfaces; no navigation, physics or accessibility
certification is implied. The gap between closed backs is a construction
separation, not an aisle.

## Room placement

[archive_island_library_room.tscn](../../assemblies/archive_island_library_room.tscn)
is an importable room assembly using the existing complete perimeter, floor
and centred 14 m rail. Two islands are placed at X=±22.2 m, rotated tangentially
to the perimeter. East uses two split-size bays; west uses three mixed-size
bays with reversed patterns on its faces. Both have 1.2 m approaches.

The saved room and one-/four-bay configurations at both back-gap limits pass
floor, architecture, portal and central-volume checks. **Room fit is qualified
for 1.2 m approaches**; larger exported approach values need a new placement
review. The room assembly has no camera or lights; the separate
[review_room.tscn](review_room.tscn) instances the existing review rig.

## Engine evidence

Standalone **Godot 4.7.2 stable official**, Forward+/D3D12 on an RTX 4080 SUPER,
passed on **14 October 2026**:

- **47 island inspections**, including room placements, test one/two/four bays,
  both back-gap limits, both approach limits on isolated objects, all cassette
  sizes, reversed mixed patterns, empty/partial/full requests, clamps and
  defensive array copies. Translated/rotated placement, detached edits,
  independent instances, three saved variants, attachment preservation and
  disk serialization pass.
- **180 shelf inspections** use **7,368 actual imported-deck support probes**.
  Maximum cassette contact error is **0.00012 mm**; minimum structure clearance
  **27.197 mm**, fixture clearance **41.999 mm** and neighbor gap **19.997 mm**
  (float tolerance around the 20 mm request). Imported cassette widths
  independently verify maximal fitting capacities.
- **1,620 short triangle probes** hit both closed backs away from the uprights
  and decks. Row envelopes do not overlap. Maximum adjacent-bay seam error is
  **0.00067 mm** and cap join error **0.00120 mm**, below the 0.1 mm tolerance.
- **Seven room inspections** use **1,554 floor probes** beneath shelves, caps
  and both full-width approaches. The widest tested layout leaves **20.410 m**
  central radius including the approaches and **0.140 m** minimum separation
  from the imported architecture. Both portal approaches stay clear.
  Floating/outside-floor negative controls fail as expected.
- **648 camera samples** at radii 12/16/19 m, heights 1.8/4/8 m and 5° steps
  clear all imported room meshes with a 0.3 m envelope. Minimum clearance is
  **1.50 m**. These are static samples, not continuous collision tests.
- Representative shelf, cap and all three cassette sizes pass imported
  triangle winding/area, UV area, normal-presence and opaque matte material
  checks. Eight GPU captures cover the room, both room faces, isolated front,
  back, end, underside and back-gap view. Existing review lighting and thin
  floor seam aliasing remain visible.
- The adaptive regression passes **32 rail / 115 shelf / 24 alcove / 4 room**
  inspections; the capped-row regression passes **14 cases**. Import and
  game-runtime logs are checked separately and contain no errors or warnings.

[godot_validation.json](godot_validation.json) records the exact measurements,
[godot_adaptive_regression.json](godot_adaptive_regression.json) and
[godot_row_regression.json](godot_row_regression.json) retain regression results.

## Reproduce and remaining validation

From repository root:

~~~powershell
./src/assets/archive_island_review/verify_island.ps1
python src/assets/archive_island_review/update_manifests.py
~~~

The runner accepts -Godot, stages the dependency closure and unchanged GLB
import settings in a unique retained src/.godot/ project, isolates preferences,
and runs GPU verification and both regressions. Every engine process has a
60-second timeout. Successful reports and captures are then copied here.
Open the retained project for visual review. This evidence folder is excluded
from the main project by .gdignore; the object scenes and room are importable.

Blender MCP get_addon_status and get_scene_info failed to connect.
Godot MCP godot_editor_read(get_state) could not reach
ws://127.0.0.1:6550. No modeling or material edits were needed; standalone Godot
was the explicit fallback. Live MCP/Inspector review and godot_validate_meshes
remain unavailable. They require Blender's addon listener and the intended
Godot project open with its MCP addon enabled.

These four assembly tasks are implemented and tested. The parent model issues
remain open for live review and final art/proportion approval. Roof fit,
interaction, continuous camera movement, text readability and measured
performance are outside this delivery. Original source provenance and repository
ownership terms apply; no external model, paid generation or license is added.

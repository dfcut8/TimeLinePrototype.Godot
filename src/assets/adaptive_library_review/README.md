# Adaptive library assemblies — issues #5, #31, #33 and #35

![Small cassette reading alcove in Godot](godot_alcove.png)

Four assembly follow-ups to the open model issues, using the existing GLBs,
Blender sources and material slots. Every visual object remains an independent
PackedScene instance. This delivery adds configuration and fit evidence.

| Issue | Delivered follow-up |
| --- | --- |
| [#5 Timeline rail](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5) | A center anchor for length edits, a saved 14 m variant, and cap/light/joiner continuity at both anchor modes. |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | A reusable dense shelf variant, with adjustable count/gap and capacity checked against imported cassette widths. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | A corresponding large variant and size-aware mixed sequences that retain actual shelf and fixture clearances. |
| [#35 Reading bench](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/35) | A configurable one-to-four-bay alcove, with an adjustable bench aisle, persistent attachment container and floor/perimeter fit checks. |

## Reusable scenes

All dimensions use metres, +Y up and unit scale. Use the object root for placement;
keep supporting containers and imported models at their saved transforms.

### Rail

Instance [centered_timeline_rail.tscn](../timeline_rail_housing/centered_timeline_rail.tscn).
It inherits the existing configurable rail, saving **module_count=7** and
**anchor_mode=1**. The pivot is the center of its 14 m attachment span;
EarlierEnd/LaterEnd are at X=-7/+7 m. +X is later. Both end caps extend 4 mm
beyond the attachment span. Each module stays 2 m long without scaling.

The original rail still defaults to three modules and **anchor_mode=0**
(Earlier end), with its attachment span beginning at X=0. Count clamps to 1–64;
anchor mode clamps to 0–1. Center mode places the earlier/later interfaces at
±module_count metres. Switching anchors moves the supporting containers and
caps while retaining module instances. Count edits replace generated modules
and joiners. A 64-module configuration is a guard, not room-fit approval.
Only the saved seven-module rail is checked in the complete room.

### Size-aware shelves

Instance [packed_cassette_shelf_bay.tscn](../record_stack_shelf_bay/packed_cassette_shelf_bay.tscn),
[small dense shelf](../archive_record_small/dense_shelf_bay.tscn), or
[large dense shelf](../archive_record_large/dense_shelf_bay.tscn).
Their 1.6 × 2.4 × 0.44 m shelf envelope, floor-center pivot and +Z aisle front
match the existing kit. Lights, closed back, decks and cassettes are subscenes.

- **cassette_pattern** repeats left to right on all four decks: 0=small,
  1=medium, 2=large. Default [0,1,2]. Empty input becomes [0]; codes clamp to
  0–2, and only the first nine entries are kept. Reassign to apply an edit;
  the getter returns a copy.
- **requested_records_per_shelf** clamps to 0–32, default 32. Zero leaves
  the decks empty. Overflow keeps the longest ordered prefix that fits.
- **record_gap** clamps to 0.02–0.15 m, default 0.02. It measures the gap
  between actual cassette envelopes, including the small cover index strokes.
- **effective_records_per_shelf** is a read-only runtime property. At the
  default gap, capacities are **16 small, 13 medium, 11 large**, or **13**
  for the default mixed pattern. Capacity follows both pattern order and gap.

Resolved widths are 0.0666/0.0866/0.1066 m, verified against the imported meshes.
The usable span is 1.44 m, centered on each shelf, leaving at least 30 mm to
the 1.50 m inner upright span. Records sit at Y=0.16/0.72/1.28/1.84 m and
Z=0.080/0.055/0.030 m for small/medium/large, aligning nominal front spines.
Population edits now retain unchanged deck/size slots; only removed slots or
changed sizes are replaced. See [archive slot editing](../archive_editing_review/README.md)
for identity and imported-fit evidence. Persistent user nodes under
Records retain their lifetime. This variant leaves previous fixed-pitch
shelf scenes and their defaults unchanged.

### Reading alcove and room

Instance [configurable_reading_alcove.tscn](../reading_bench/configurable_reading_alcove.tscn).
The root is a floor datum, +Z aisle front. **bay_count** clamps to 1–4,
default two; row width is 1.6 × count + 0.164 m including both end caps.
**aisle_width** clamps to 1.2–2.0 m, default 1.54. It is the measured clear
distance from shelf front to bench rear. These are layout bounds, not a
regulatory accessibility claim.

The row stays at Z=-1.4 m. The bench's Z is -0.94 + aisle_width, retaining
the original Z=0.6 placement by default. Its 1.6 × 0.45 × 0.48 m model remains
unscaled. AisleCentre tracks the midpoint of the clear aisle. Cassette pattern,
requested count and gap have the same defaults/clamps as the packed bay and
propagate to every bay. Population and aisle edits retain bay/bench instances;
row count changes now retain surviving bays. Keep persistent additions under
**Attachments** or the alcove root. Edits inside a nested scene instance need
the usual Godot editable-children/ownership setup for serialization.

The importable [adaptive_library_room.tscn](../../assemblies/adaptive_library_room.tscn)
combines the existing floor and full wall/portal/window perimeter with the
centered rail at Y=1.5 m and two inward-facing alcoves at X=±21.8 m. East saves
two small-record bays; west saves three bays with [2,1,0]. This focused room
has no review camera or lights. [review_room.tscn](review_room.tscn) adds the
existing review rig in the isolated validation project. Main project settings
and the older furnished room remain unchanged.

## Engine evidence

On **14 October 2026**, standalone **Godot 4.7.2 stable official,
Forward+/D3D12, RTX 4080 SUPER** passed:

- **32 rail inspections**: both anchors, one/three/seven/64 modules, count
  and mode clamps, transformed placement, detached edits, disk roundtrip,
  independent instances and user attachments. Maximum housing/light seam
  error is **0.01526 mm**, below the 0.1 mm tolerance.
- **115 shelf inspections**, including alcove bays: all sizes, mixed/reversed
  sequences, empty/full requests, minimum/maximum gaps, invalid codes and
  clamps, transformed placement, saved variants and disk roundtrip.
  **3,154 support calls** include two negative controls; the remaining
  **3,152** probe actual imported decks. Maximum contact error is
  **0.00012 mm**, minimum structure clearance **27.198 mm**, minimum light
  separation about **42 mm**, and minimum measured neighbor gap **19.998 mm**
  (float tolerance around the 20 mm request). Imported widths independently
  confirm that the next ordered record cannot fit when capacity truncates.
- **24 alcove inspections**: lengths 1–4, all three tested aisle values,
  propagated settings, model identity preservation, transformed placement,
  disk roundtrip and persistent attachments. Maximum cap join error is
  **0.00120 mm**.
- **Four room inspections**: saved and translated/rotated room, plus both
  aisle extremes with four-bay rows. **452 floor probes** cover row/cap bases,
  both bench foot pads, aisle centers and the rail projection. Alcoves clear
  wall/pier envelopes and both portal approaches. Minimum central clear radius
  is **20.5 m**, perimeter setback **0.41298 m**, and rail/floor separation
  **1.437 m**. Floating and outside-floor controls reject unsupported placements.
- Representative housing, cassettes, shelf, caps and bench pass imported
  triangle winding/area, UV area, opaque matte material and normal-presence
  checks. Seven GPU views were inspected: room, small alcove, mixed alcove,
  rail, isolated rear, end and underside. Existing review lighting and thin
  floor seam aliasing remain visible.
- The original **seven rail** and **14 capped-row** regression cases pass.
  Import and all three runtime logs contain no errors or warnings.

[godot_validation.json](godot_validation.json) contains measurements;
[rail regression](godot_rail_regression.json) and
[row regression](godot_row_regression.json) retain the existing checks.

## Reproduce and validation limits

From the repository root:

~~~powershell
./src/assets/adaptive_library_review/verify_adaptive.ps1
python src/assets/adaptive_library_review/update_manifests.py
~~~

The runner accepts -Godot and stages 66 scene/script/model dependencies,
including the existing GLB import settings, under a unique retained src/.godot/
directory. It isolates roaming/local preferences, imports, runs GPU verification
and two regression suites, checks diagnostics separately, then copies successful
evidence back. Each engine process has a 60-second timeout. Open the retained
project to review its camera scene. This evidence folder is excluded from the
main project by .gdignore; all new reusable object scenes and the room assembly
remain importable.

Blender MCP get_addon_status and get_scene_info both failed to connect.
Godot MCP godot_editor_read(get_state) could not reach ws://127.0.0.1:6550.
No model/material/animation authoring was required. Standalone Godot was the
explicit fallback, and no live MCP mesh validation is claimed. Live review
requires Blender's addon listener and the intended Godot project open with its
MCP addon enabled. Editor Inspector interactions remain unverified through MCP.

These four follow-ups are implemented and tested; the issues remain open for
live review and final art/proportion approval. Physics, navigation, seating
interaction, roof fit, continuous camera paths, text readability and measured
performance are outside this delivery. Original asset provenance and repository
ownership terms apply; no external model or paid generation is introduced.

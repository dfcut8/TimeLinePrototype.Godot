# Assembly editing — issues #5, #34, #35 and #36

![Edited rail, reading alcove and catalog station in Godot](godot_front.png)

Four follow-up tasks fix editing failures in the existing reusable scenes.

| Issue | Change |
| --- | --- |
| [#5 Rail housing](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5) | Length edits retain surviving module/joiner slots, child state and material overrides. Translated/rotated Modules and Joiners containers no longer break imported seams or cap contact. |
| [#34 Catalog lectern](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34) | Layout controls update furniture and approach markers independently of display configuration. Each size/yaw/visibility control updates only its own property and side. |
| [#35 Reading bench](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/35) | The bench and aisle marker follow the shelf row's full local frame. Translating or yawing the row retains its floor plane, centred bench and requested clear aisle. |
| [#36 Display plinth](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36) | Refresh replaces queued/freed cassettes and reattaches live detached/reparented records. Hiding a detached record safely releases it. The imported plinth and slot additions survive. |

## Editing behavior

Use the existing configurable_timeline_rail.tscn,
configurable_catalog_station.tscn, configurable_reading_alcove.tscn and
configurable_archive_display.tscn. All visual objects remain PackedScene
instances. No Blender source, mesh, GLB, material or import setting changed.

Rail slots retain their index through count and anchor edits. Shrinking removes
trailing slots immediately; growing creates only missing slots. An anchor or
count assignment also refreshes layout after container-transform changes and
recovers deleted parts. Generated root transforms belong to the layout; their
children, metadata and appearance overrides persist while the slot survives.
Container transforms and user additions remain intact. Caps keep their existing
instances and move to the resolved endpoints. The 2 m module pitch and 1–64
count guard are unchanged.

Catalog spacing, lectern offset and approach-depth edits preserve direct display
overrides. Assigning a station's left/right size, yaw or visibility property
updates only that property on that display. Before the station becomes ready,
exports still provide its initial configuration. Save reusable station presets
through the station exports; transient child overrides do not override those
exports on disk reload.

For alcoves, edit ShelfRow's translation/yaw, then assign aisle_width or bay_count
to refresh placement. The bench root and AisleCentre transforms belong to the
layout. The 1.2–2.0 m aisle is measured along shelf-local +Z from the imported
shelf front to bench rear. The bench shares the shelf floor plane; placing both
on a world floor remains the caller's responsibility. Evidence covers unit-scale
rows with yaw rotations and translated/rotated parents.

Display size/yaw/visibility assignments recover an externally removed record.
A queued/freed record gets a fresh instance; a live detached/reparented record
returns to RecordSlot with its child state. Hiding or changing size releases the
old record, including its children. Persistent additions belong beside the
record in RecordSlot or in an authored object variant. Existing TopContact
placement, size clamps and metre-scale interfaces are unchanged.

Generated nodes have no owner. Saved exports reconstruct one population on load;
generated child additions are transient unless saved in an authored object scene.

## Engine evidence

Standalone **Godot 4.7.2 stable official**, **Forward+/D3D12**, RTX 4080 SUPER,
14 October 2026:

- The original code reproduced failures in all four workflows; baseline logs and
  a JSON report are retained separately from passing runtime evidence.
- Focused editing checks cover retained identities and overrides, transformed
  supporting containers, queued/freed/detached recovery, independent station
  controls, pre-ready settings, detached edits and disk roundtrips.
- The focused suite passes **11 rail**, **18 aisle** and **9 display** inspections.
  Maximum measured rail seam error is **0.000954 mm**; cap contact, bench-floor
  alignment and display-contact errors are below **0.1 mm** in every case.
- Imported housing/light seams and both cap contacts remain within 0.1 mm.
  Imported bench bounds confirm the aisle at five yaw angles and all three
  tested widths, with the same floor plane and unit dimensions.
- Imported cassette bottom-face triangle probes confirm plinth support after
  recovery, hiding/repopulation and RecordSlot transforms.
- Existing adaptive-library, catalog-perimeter and display regression suites
  pass. They retain full-room floor/clearance evidence, imported normals/UVs,
  winding, opaque matte materials and independent scene configuration checks.
- Editor import and all four passing game-runtime logs contain no errors or
  warnings. Front/rear captures were visually inspected without bloom.

Run from the repository root:

~~~powershell
./src/assets/assembly_editing_review/verify_editing.ps1
python src/assets/assembly_editing_review/update_manifests.py
~~~

The runner accepts -Godot, copies dependencies into a fresh retained src/.godot
project, isolates engine preferences, and bounds each process to 60 seconds.
Pass -Baseline to replay the original four scripts from commit b90a628 in the
isolated project against the focused verifier. Expected assertion/script errors
are retained in baseline_runtime.log and godot_baseline.json; baseline_source.json
records the commit and verifier hash. The checkout remains unchanged.
The review folder has .gdignore. Open review_objects.tscn in the retained project
for inspection; production object scenes remain importable in the main project.

Blender MCP get_addon_status/get_scene_info failed to connect; Godot MCP
godot_editor_read(get_state) could not reach ws://127.0.0.1:6550. No MCP was used
for authoring or engine validation. Standalone Godot was the explicit fallback.
Live review requires Blender's addon listener and the intended Godot project
open with its MCP addon enabled. No procedural geometry changed and
godot_validate_meshes did not run.

These four editing tasks are complete. Parent model issues remain open for live
review and final art/proportion approval. Interactive Inspector use, physics,
navigation and performance acceptance remain outside this evidence. Existing
source provenance and repository ownership terms apply; no external assets or
paid generation were added.

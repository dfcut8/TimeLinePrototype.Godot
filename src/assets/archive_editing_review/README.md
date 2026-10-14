# Archive slot editing — issues #28, #29, #31 and #33

![Edited three-bay island in Godot](godot_front.png)

Four editing follow-ups for the existing open model issues. Changing shelf
length, cassette count or spacing previously discarded every generated
instance, including attached state and material overrides. The existing
reusable scenes now retain surviving slots and replace only affected objects.

| Issue | Completed task |
| --- | --- |
| [#28 Shelf bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/28) | Count edits retain surviving bay objects, their closed backs, shelf lights and nested additions. A changed bay template replaces the generated bays. |
| [#29 End cap](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/29) | Resizing retains both cap instances and moves the joins to the new row ends. Bay-container transforms preserve the centred shelf grid and imported cap contact. |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | Small records survive count and gap edits in both fixed-pitch and packed bays, retaining child state and material overrides. Removed slots are detached immediately. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | Large and mixed populations retain unchanged sizes by deck/slot; changed sizes replace only their slots. Both island faces retain surviving populations through row-length edits. |

## Editing interfaces

Use the existing configurable_shelf_row.tscn, configurable_populated_shelf_row.tscn,
configurable_cassette_shelf_bay.tscn, packed_cassette_shelf_bay.tscn and
configurable_archive_island.tscn. No new object variant or export is required.
The row still uses 1.6 m bay pitch, a floor-centre pivot, unit-scale imported
assets and reversible end caps. Shelf capacities and population limits are
unchanged. Cassette placement still uses the existing deck and front datums.

Slots retain their index when counts change; recentering moves those instances
to the new positions. A removed slot or changed cassette size releases its old
instance. Regrowing a removed slot creates a new instance. Equivalent patterns
and assignments of the same settings retain instances. A bay template change
replaces bays while preserving caps and unrelated container additions.

Layout controls generated root transforms. Records and Bays containers may be
translated/rotated; reassign an exported setting to refresh placement in the
object's coordinate system. Individual generated-root placement overrides are
replaced by layout. Other child additions, metadata and appearance overrides
survive while their slot exists.

Generated instances have no owner. Saving persists configuration, then creates
exactly one population on load; transient additions inside generated slots
are not serialized. Save reusable authored variations as object scenes. For
persistent root/container additions, use Godot's usual editable-children and
ownership setup. The helper cassette_slot_instances.gd shares slot reconciliation
between the two existing shelf objects; every cassette remains a PackedScene
instance.

## Engine evidence

On **14 October 2026**, standalone **Godot 4.7.2 stable official**, Forward+/D3D12
on an RTX 4080 SUPER, passed the focused review and three regression suites:

- Nine focused workflows exercise all three cassette sizes in both population
  variants, two row variants and an island. **446 identity checks** verify
  retained slots, fixtures and opposite-face populations.
- Growth/shrink, equivalent patterns, single-size changes, material overrides,
  child state, container transforms, empty/repopulate, pre-ready configuration,
  detached edits, queued/freed-slot recovery and disk roundtrips pass.
- The focused suite includes **57 packed-shelf and 5 island inspections**,
  **2,232 imported-bottom support probes** and **216 closed-back probes**.
  Fixed-pitch populations also pass actual deck-contact and separated-record
  checks. Imported cassette, shelf and cap geometry passes winding, normals,
  UV area and matte opaque-material checks.
- The island regression passes **47 island / 180 shelf / 7 room inspections**,
  including actual floor contact, both-face approaches and sampled camera
  clearance. The modular regression passes **19 arc / 88 shelf / 14 row / 2
  sector inspections**. The original unpopulated row passes **14 inspections**.
- Separate editor import and all four game-runtime logs contain no errors or
  warnings. Front, rear and end GPU captures show the resized mixed island,
  cap surfaces and back separation without bloom.

[godot_validation.json](godot_validation.json) records the focused checks;
the three godot_*_regression.json reports retain the regression measurements.
Run from repository root:

~~~powershell
./src/assets/archive_editing_review/verify_editing.ps1
python src/assets/archive_editing_review/update_manifests.py
~~~

The runner accepts -Godot, stages an isolated project under src/.godot, isolates
preferences and bounds each engine process to 60 seconds. The review folder
has .gdignore; open review_island.tscn in the retained project for inspection.
Production object scenes remain importable in the main project.

Blender MCP get_addon_status and get_scene_info failed to connect. Godot MCP
godot_editor_read(get_state) could not reach ws://127.0.0.1:6550. Existing
Blender sources, GLBs, materials and import settings were reused without asset
authoring; standalone Godot was the explicit engine fallback. Live review needs
Blender's addon listener and the intended Godot project open with its MCP addon
enabled. No procedural mesh was changed; godot_validate_meshes did not run.

These four follow-ups are implemented and tested. The parent issues remain open
for live review and final art/proportion approval. Live Inspector interaction,
physics, navigation, continuous camera motion and performance acceptance remain
outside this evidence. Original repository source provenance and ownership
terms apply; no external assets or paid generation were added.

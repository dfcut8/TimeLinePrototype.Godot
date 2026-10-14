# Library kit editing — issues #24, #25, #34 and #36

![Saved single-record catalog station in Godot](godot_station.png)

Four configuration and model-fit follow-ups using the existing Blender sources,
GLBs, material slots and import settings. Every visual object is still a reusable
scene instance. No mesh or material authoring was required.

| Issue | Completed task |
| --- | --- |
| [#24 Wall infill bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | Arc edits retain unchanged bays and shared piers, including their runtime additions and overrides. Transformed supporting containers preserve the resolved grid. |
| [#25 Portal bay](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | The portal owns local opening and approach bounds, checked against imported opening surfaces, existing markers and the actual floor. |
| [#34 Catalog lectern](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34) | Perimeters accept a saved station scene variant. Authored spacing, cassette choices and empty sides survive removal/recreation and disk reload. |
| [#36 Display plinth](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36) | Configurable displays can be empty while retaining the plinth, configured size/yaw and sibling slot attachments. |

## Scene interfaces

All dimensions are metres, +Y up, with unit-scale imported models.

**Arc editing.** Use the existing
[configurable_bay_arc.tscn](../wall_infill_bay/configurable_bay_arc.tscn).
Angle changes retain every generated object. A layout edit replaces only a bay
whose type changes, creates appended bays/piers and removes trailing ones.
Slots are identified by index, not by content moving between indices. The
23/24-bay transition retains the same 24 piers and shares the closing pier.
Placement remains relative to the arc root when Bays or Piers is transformed;
reassign an exported setting to refresh after editing these containers.

Use **Attachments** for persistent root additions. Existing user additions under
Bays/Piers also remain untouched. Additions and overrides inside a generated
object survive only while that object remains; they are not serialized by the
arc. Save authored variations as object scenes when persistence is needed.

**Portal fit.** The existing
[passage_portal_bay_frame.tscn](../passage_portal_bay_frame/passage_portal_bay_frame.tscn)
now has two methods, returning local AABBs:

| Method | Position | Size |
| --- | --- | --- |
| get_opening_bounds() | (-1.5, 0, -0.123) | (3, 3.4, 0.246) |
| get_approach_bounds() | (-1.5, 0, -1) | (3, 3.4, 6) |

OpeningCentre, OutsideApproach and InsideApproach agree with these bounds.
Transform points with the portal root for placement checks. Multiplying an
AABB by a transform produces an enclosing AABB, which can overestimate a rotated
opening. These are static layout interfaces without physics or navigation.

**Catalog template.** Set **station_scene** on
[catalog_perimeter.tscn](../wall_infill_bay/catalog_perimeter.tscn) to a saved
variant of configurable_catalog_station.tscn. Its root must use
configurable_catalog_station.gd or a derived script. All active stations use the
selected variant's authored configuration. Null selects the original default;
an incompatible root falls back to the default and reports an Inspector
configuration warning. A template change replaces generated stations while
retaining architecture. Angle and unrelated bay edits retain active stations.

[single_record_catalog_station.tscn](../catalog_lectern/single_record_catalog_station.tscn)
saves 1.1 m display spacing, 0.7 m lectern offset, a medium cassette at -45 degrees
on the left and an empty right display.
[single_record_catalog_entrance.tscn](../passage_portal_bay_frame/single_record_catalog_entrance.tscn)
uses this template on both solid walls of the existing wall/portal/wall sector.
Direct changes to a generated station still share its lifetime; use a saved
template to retain settings through wall-to-portal changes or disk reload.

**Empty displays.** Set **show_cassette=false** on
[configurable_archive_display.tscn](../archive_display_plinth/configurable_archive_display.tscn),
or instance [empty_archive_display.tscn](../archive_display_plinth/empty_archive_display.tscn).
The cassette is removed; the imported plinth, TopContact and other RecordSlot
children remain. Size and yaw edits while empty are applied when enabled again.
Re-enabling creates a new cassette instance; additions inside the old cassette
share its lifetime. Station exports **left_show_cassette** and
**right_show_cassette** independently, both true by default.

## Engine evidence

On **14 October 2026**, standalone **Godot 4.7.2 stable official**,
Forward+/D3D12 on RTX 4080 SUPER passed all four suites:

- Eight editing workflows cover five arc angles, changed/unchanged bay identity,
  growing/shrinking sectors, transformed containers, ring closure, attachments,
  disk roundtrips, detached edits, empty displays and station templates.
- **24 imported-triangle probes** check the portal's clear opening and solid
  jamb/header boundaries under identity and translated/rotated parents.
  **66 floor probes** check the entire sampled portal approach and furniture
  support in those placements.
- Eight occupied display inspections verify actual imported bottom-face support
  when enabling all three cassette sizes and reloading the saved template.
  Maximum contact error is **0.00012 mm**; minimum flat-top edge margin is
  **146.94 mm** for these samples.
- The catalog regression passes **170 station / 23 perimeter / 3 room**
  inspections. The display regression passes **42 display / 4 placement**
  inspections and its existing unsupported/floating negative controls.
  The modular regression passes **19 arc / 88 shelf / 14 row / 2 sector**
  inspections, including imported pier joins and opening probes.
- Imported wall, portal, lectern, plinth and cassette surfaces pass winding,
  triangle/UV area, normal and opaque matte-material checks. Three GPU captures
  show the entrance, occupied/empty station and rear surfaces. Existing review
  lighting and thin floor seam aliasing remain visible.
- Editor import and four separate game-runtime logs contain no errors or warnings.

[godot_validation.json](godot_validation.json) records the focused checks.
The three godot_*_regression.json files retain the regression measurements.

Reproduce from repository root:

~~~powershell
./src/assets/kit_editing_review/verify_editing.ps1
python src/assets/kit_editing_review/update_manifests.py
~~~

The runner accepts -Godot, stages dependencies in a new retained src/.godot/
project, isolates preferences and bounds each engine process to 60 seconds.
The review folder has .gdignore; its runner stages the scenes for validation.
Open review_entrance.tscn in the retained project to inspect it. Production object
scenes and saved variants remain importable in the main project.

Blender MCP get_addon_status and get_scene_info failed to connect. Godot MCP
godot_editor_read(get_state) could not reach ws://127.0.0.1:6550. Standalone
Godot was the explicit fallback; Blender was not used for this delivery. Live
validation requires Blender's addon listener and the intended Godot project open
with its MCP addon enabled. No procedural mesh was changed; imported-triangle
checks do not represent execution of godot_validate_meshes.

These four follow-up tasks are implemented and tested. The parent model issues
remain open for live review and final art/proportion approval. Arbitrary custom
station dimensions require their own room-fit review. Gameplay, continuous camera
movement, navigation and performance are outside this delivery. Original source
provenance and repository ownership terms apply; no external asset or paid
generation was added.

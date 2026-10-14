# Catalog perimeter assemblies — issues #24, #25, #34 and #36

![Configurable station in Godot](godot_station.png)

Four follow-ups to the open model issues, using the existing GLBs, Blender
sources, materials and imports. Every wall, pier, portal, lectern, plinth and
cassette remains an independent PackedScene instance.

| Issue | Delivered follow-up |
| --- | --- |
| [#24 Wall infill](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | A reusable catalog perimeter derives station transforms from actual wall-bay interfaces, including complete rings and rotated grids. |
| [#25 Portal frame](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | Portal and window bays exclude stations automatically. A saved entrance sector and full room keep both 3 × 3.4 m portal approaches clear. |
| [#34 Catalog lectern](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34) | A configurable comparison station exposes display spacing, lectern position and a supported front approach with start/end/centre markers. |
| [#36 Display plinth](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36) | Either independent plinth display accepts any cassette size and yaw; imported bottom-face contact and floor support are checked throughout configuration changes. |

## Reusable objects

All placement uses metres, +Y up, unit scale and floor-centred roots.
The station's +Z faces its user approach. No visual hierarchy is reconstructed
in a level script.

Instance [configurable_catalog_station.tscn](../catalog_lectern/configurable_catalog_station.tscn).
Its `@tool` script provides these properties:

| Property | Default | Bounds/meaning |
| --- | --- | --- |
| `display_spacing` | 0.9 m | 0.75–1.25 m from centre to each display; centres at X=±spacing, Z=-0.2. |
| `lectern_offset` | 0.8 m | 0.6–1.0 m along +Z. |
| `approach_depth` | 1.0 m | 0.8–1.5 m. Begins at Z=offset+0.255, beyond the actual lectern front. |
| `left_cassette_size`, `right_cassette_size` | 0, 2 | 0=small, 1=medium, 2=large; clamps to 0–2. |
| `left_cassette_yaw`, `right_cassette_yaw` | -30°, +30° | -180°–+180°, relative to the plinth contact frame. |

`get_approach_bounds()` returns a local AABB, 1.8 m high, spanning the complete
display width (2 × (spacing+0.35)). `ApproachStart`, `ApproachEnd` and `UserApproach`
track its centreline at floor level. These are layout interfaces, not movement
or accessibility certification. Larger approach settings can reach inside the
proposed 20 m central radius; the geometry remains outside it. The saved room
uses the default approach depth and station dimensions.

Spacing/yaw/approach edits retain the lectern and both plinths; size edits replace
only the relevant generated cassette. Configuration serializes and rebuilds
exactly one record per display. Add persistent user nodes beneath `Attachments`
or use normal editable-child ownership for additions inside scene instances.

Instance [catalog_perimeter.tscn](../wall_infill_bay/catalog_perimeter.tscn).
The root is the room centre at floor level. It instances the existing configurable
bay arc as `Architecture`; the unscaled 24.8 m pier radius and 15° pitch are reused.

- `bay_layout` is an ordered PackedInt32Array: 0=wall, 1=portal, 2=window.
  It keeps the first 24 entries, clamps codes to 0–2, and turns an empty layout
  into one wall. Defaults to [0,1,0].
- `station_bays` selects indices 0–23, default [0,2]. Invalid indices and
  duplicates are removed and entries sorted. Empty input yields no stations.
  Requests outside the current layout or on portals/windows stay dormant;
  they become active if that index later contains a wall.
- `start_angle_degrees` locates the first bay clockwise from -Z; bounds
  -180°–+180°, default -15°. Arrays return copies; reassign to apply edits.
- Read-only `active_station_bays` reports eligible indices. Stations are named
  `Stations/StationN`. Their floor pivots sit exactly 2.3 m inward from the
  selected bay pivot and share its inward orientation. Supporting-container
  transforms are composed into placement.

Angle changes and unrelated layout edits retain stations on still-active bays.
Changing a selected wall to a portal/window removes its generated station;
switching back creates a new station. The perimeter serializes its root
configuration and persistent additions under `Attachments`/`Stations`, then
rebuilds generated stations. Direct edits inside a generated station persist
while it remains active but are not serialized by the perimeter. For saved
custom station settings, instance the standalone configurable station.

[catalog_entrance_sector.tscn](../passage_portal_bay_frame/catalog_entrance_sector.tscn)
saves the three-bay wall/portal/wall configuration with two flanking stations.
[library_catalog_perimeter.tscn](../wall_infill_bay/library_catalog_perimeter.tscn)
saves the existing 24-bay layout with portals at 0°/180°, windows at 90°/270°
and stations on bays 1/11/13/23 beside both entrances.

The importable [catalog_library_room.tscn](../../assemblies/catalog_library_room.tscn)
combines that perimeter with the existing floor, centred 14 m timeline and
two size-aware reading alcoves. The scene contains no review camera or lights.
[review_room.tscn](review_room.tscn) adds the existing review rig in the isolated
validation project. This evidence folder is excluded from main-project import
by `.gdignore`; the new object scenes and room assembly remain importable.

## Engine evidence

On **14 October 2026**, standalone **Godot 4.7.2 stable official,
Forward+/D3D12, RTX 4080 SUPER** passed:

**170 station inspections** (including 340 individual cassette displays),
**23 perimeter inspections** and **three room inspections** use **7,140 station
floor probes** plus **750 portal floor probes**.

- Station geometry extremes, all nine left/right size pairs, four yaw pairs,
  clamps, transformed placement, detached edits, independent instances and
  disk serialization. Lectern/plinth identities and user attachments survive.
  Actual screen-insert contact and forward-facing normals pass. Minimum
  internal furniture separation is **292.08 mm**.
- Every cassette bottom-face centroid intersects the real imported plinth top.
  Maximum contact error is **0.00012 mm**; minimum tested flat-top margin
  **107.36 mm**. No record geometry is baked into the plinth.
- Perimeter index/type/angle clamps, defensive array copies, dormant requests,
  wall-to-portal changes, zero/one/three/twenty stations, complete ring closure,
  rotated grids, container transforms, saved variants, disk roundtrip and
  detached changes. Every station and its approach clears the imported
  architecture and all portal approach envelopes. Maximum bay alignment error
  is **0.00463 mm**, minimum wall setback **1.702 m** and conservative central
  clear radius **20.7997 m**.
- The saved room, translated/rotated room and complete room disk roundtrip
  retain four stations and both alcoves. Each placement probes the actual floor
  through both complete portal approaches and checks clear 3 × 3.4 m openings.
  Station feet and front approaches use actual imported floor triangles;
  floor datum error is zero. Floating/buried/absent-floor controls fail as expected.
- **648 camera samples**, radii 12/16/19 m, heights 1.8/4/8 m and 5° steps,
  clear the complete imported room with a 0.3 m camera envelope. Minimum
  clearance is **1.50 m**. These are static samples, not continuous collision.
- Representative wall, portal, lectern, both plinths and all three cassette
  sizes pass imported triangle area/winding, UV area, normal-presence and
  opaque matte material checks. Seven GPU captures were inspected: room,
  entrance, station front, floor contact, isolated rear, end and underside.
  Existing review lighting and thin floor seam aliasing remain visible.
- Both original regression suites pass: **42 display inspections** with four
  station placements and **19 arc / 88 shelf / 14 row / 2 sector inspections**.
  Editor import and game-runtime logs are checked separately for errors/warnings.

[godot_validation.json](godot_validation.json) contains exact case/probe counts
and measurements; [display regression](godot_display_regression.json) and
[modular regression](godot_modular_regression.json) retain the older checks.

## Reproduce and remaining acceptance

From repository root:

```powershell
./src/assets/catalog_perimeter_review/verify_catalog.ps1
python src/assets/catalog_perimeter_review/update_manifests.py
```

The runner accepts `-Godot`, stages the dependency closure and unchanged GLB
import settings into a unique retained `src/.godot/` project, isolates roaming
and local preferences, imports and runs GPU verification plus both regressions.
Each engine process has a 60-second timeout. Evidence is published only after
all suites pass. Open the retained project for the camera review scene.

Blender MCP `get_addon_status` and `get_scene_info` failed to connect.
Godot MCP `godot_editor_read(get_state)` could not reach ws://127.0.0.1:6550.
No mesh/material/animation authoring was needed; existing sources are reused.
Standalone Godot is the explicit fallback. Live Inspector/MCP review and
`godot_validate_meshes` remain unavailable. They require Blender's addon listener
and the intended Godot project open with its MCP addon enabled.

These four assembly follow-ups are implemented and tested. Issues remain open
for live review and final art/proportion approval. Roof fit, interaction,
physics, continuous camera paths, live text readability and measured performance
remain outside this delivery. Existing model provenance and repository ownership
terms apply; no external model, paid generation or license is introduced.

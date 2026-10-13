# Populated capped rows and reading alcoves — issues #29 and #35

![Reading alcove in Godot](godot_alcove_front.png)

This follow-up adds two importable assemblies using the existing model kit:
a configurable capped row with mixed cassette sizes for
[#29](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/29), and a bench/shelf
alcove with actual floor support for
[#35](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/35).
All GLBs, editable Blender sources, material graphs and model import settings
are reused unchanged. No new asset license or external dependency is introduced.

## Reusable objects

Instance `../record_stack_end_cap/capped_mixed_shelf_row.tscn` in the main project.
It inherits the existing configurable row, selecting
`../record_stack_shelf_bay/mixed_cassette_shelf_bay.tscn` as its `bay_scene`.
Each bay contains 36 independent records, 12 of each size, and four shelf lights.
`bay_count` defaults to three and retains the existing 1–32 clamp. The complete
width is `1.6 * bay_count + 0.164` metres; height/depth are 2.4/0.44 m.
The pivot is at the row's floor centre, +Y up and +Z aisle front. Both caps use
the existing documented transforms, with rotation rather than negative scale.

The original `configurable_shelf_row.tscn` still defaults to empty illuminated
bays. Its new `bay_scene` property accepts shelf variants retaining the existing
1.6 × 2.4 × 0.44 m interface. Assigning null restores the original bay. Changes to
the count or scene rebuild generated PackedScene instances; user-owned attachments
retain the existing lifecycle and serialization behavior. Count limits are a
configuration guard, not a measured performance budget.

Instance `../reading_bench/reading_alcove.tscn` for a two-bay populated capped row
and the existing bench. The row is at (0,0,-1.4) m and the bench at (0,0,0.6) m.
The alcove's root is a floor datum, +Y up and +Z aisle front. Its complete envelope
is 3.364 × 2.4 × 2.46 m, with Z from -1.62 to +0.84 m. Keep scales at one.
The measured shelf-face-to-bench-rear aisle is **1.54 m**. The row, cap, bench,
cassette and fixture hierarchies remain self-contained reusable scenes.

## Room placement and engine evidence

`room_assembly.tscn` adds two alcoves beside the existing windows of the grounded
furnished room. Centres are (±21.8,0,0) m with east/west yaw -90/+90 degrees,
so both face inward. The existing perimeter, floor, furniture and rail are reused.
`review_room.tscn` adds the existing review rig. The review folder remains excluded
from main-project import by `.gdignore`; the reusable row and alcove are importable.

On **13 October 2026**, standalone **Godot 4.7.2 stable official, Forward+/D3D12,
RTX 4080 SUPER** passed:

- Nine new row configuration checks: populated lengths 1/2/3/4, null fallback,
  switching back to populated bays, disk save/reload, independent instances, and
  the original default. Records remain independent scenes: 36 per bay.
- Both room alcoves at identity and parent translation (8,2,-6) m/yaw 0.71 rad.
  Maximum cap join error is **0.0012 mm**, under the 0.1 mm tolerance; cassette
  contact error is below **0.0002 mm**.
- **61 floor probes per alcove placement**, 244 total: both bench foot pads,
  both cap bases, both shelf bases and the aisle. Bench floor datum error is zero.
  The existing floor permits up to 2.1 mm of chamfer depth. Exact triangle-edge
  misses require support on both sides at ±10 micrometres; this does not bridge
  a larger missing surface. Floating/buried 10 mm and outside-floor controls fail
  the same support test as expected.
- Alcove envelopes clear existing shelves, stations, architecture and both portal
  approaches. Their conservative minimum central clear radius is **20.96 m**,
  exceeding the proposed 20 m radius.
- **648 camera samples**, radii 12/16/19 m, heights 1.8/4/8 m and 5-degree steps.
  A 0.3 m envelope clears every imported mesh in the complete room; minimum
  clearance is **1.50 m**. These are static samples, not continuous collision.
- Imported bench, left/right caps and one populated bay pass triangle winding,
  area, normals, UV area and opaque matte material checks.
- All **14 original configurable-row regression cases** pass, including clamps,
  user attachment preservation, detached reentry and disk serialization.

Six GPU captures were visually inspected: room overview, alcove front, bench
floor contact, isolated rear, end and underside. The room is hidden only for the
three isolated views to expose finished model surfaces. Separate import,
alcove runtime and original-row runtime logs contain no errors or warnings.
Results are in `godot_validation.json` and `godot_existing_row_validation.json`.

## Reproduce and acceptance limits

From the repository root:

```powershell
./src/assets/reading_alcove_review/verify_alcove.ps1
```

`-Godot` overrides the pinned executable. The runner copies 71 scene/script/model
dependencies into a unique isolated project under `src/.godot/`, retains import
settings, isolates editor preferences, imports, runs GPU checks and the unchanged
original-row suite, then publishes passing evidence. The isolated project is
retained and its path printed. Both import and runtime have bounded timeouts.
Run `python src/assets/reading_alcove_review/update_manifests.py` after changes
to refresh file hashes.

Blender MCP `get_addon_status` and `get_scene_info` both failed to connect.
Godot MCP `godot_editor_read(get_state)` could not reach ws://127.0.0.1:6550.
No Blender authoring was required. Standalone Godot was the explicit validation
fallback; live MCP and `godot_validate_meshes` were unavailable. Live review needs
Blender's addon server and this project's Godot editor with its MCP addon enabled.

These two follow-ups are implemented and tested. The GitHub issues remain open
for live review and final art/proportion approval. The scene is a static placement
study: roof fit, physics, seating interaction, timeline readability and measured
performance remain outside this delivery.

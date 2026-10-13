# Catalog comparison stations — issues #31, #33, #34 and #36

![Catalog station in Godot](godot_station_front.png)

Four integration follow-ups using the existing archive kit. Models, editable
Blender sources, materials and GLB import settings are reused without edits.

| Issue | New reusable object |
| --- | --- |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | `../archive_record_small/plinth_display.tscn` seats the independent small cassette on the existing plinth. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | `../archive_record_large/plinth_display.tscn` supplies the large variant with configurable orientation, including comparison alongside the small record. |
| [#34 Catalog lectern](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/34) | `../catalog_lectern/catalog_comparison_station.tscn` combines the blank lectern and two independent displays, with a user-approach marker. |
| [#36 Display plinth](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36) | `../archive_display_plinth/configurable_archive_display.tscn` selects all three record sizes and seats them using `Plinth/TopContact`. |

## Use and interfaces

All four object scenes are importable in the main project. Every cassette,
plinth and lectern remains a separate PackedScene instance. Review scenes and
evidence in this folder are excluded by `.gdignore`.

The configurable display's root is at the plinth's floor centre. Use metre units,
+Y up, +Z front and unit scale. `cassette_size` selects small/medium/large (0/1/2),
defaulting to large; out-of-range values clamp to the nearest size.
`cassette_yaw_degrees` ranges from -180 to +180, defaulting to zero. Size changes
replace only the generated cassette; yaw changes retain its instance. The
`@tool` script updates configuration in the Inspector and at runtime. Contact
placement composes the plinth, contact marker and slot transforms. If those
transforms are edited separately, reassign either configuration property to
refresh placement.

`RecordSlot/Cassette` is generated and has no scene owner. Saving records the
configuration and rebuilds one cassette on load. Add persistent user attachments
as siblings in `RecordSlot`, using names other than `Cassette`; attachments inside
the generated cassette belong to that replaceable instance. There is no frame
polling, interaction, animation or physics. The small and large scenes inherit
this display with the corresponding size selected.

The station's floor datum is (0,0,0), with +Z toward the user. Small/large display
centres are (-0.9,0,-0.2)/(0.9,0,-0.2) m, with cassette yaw -30/+30 degrees.
The lectern is at (0,0,0.8) m; `UserApproach` is at (0,0,1.8) m. The imported
assembly envelope is **2.50 × 1.08 × 1.51067 m**. Leave an additional one-metre
front approach beyond the lectern envelope. The approach marker is a placement
interface, not a movement or interaction feature.

## Room and engine evidence

`room_assembly.tscn` adds two stations to the previously grounded room and reading
alcoves. Centres are at radius 22.4 m, angles 15/195 degrees clockwise from -Z,
with yaw -15/165 degrees so +Z faces inward. Existing furnishings stay in place.
`review_room.tscn` adds the existing review rig. This remains an optional static
placement study pending approval of the room proportions.

On **13 October 2026**, standalone **Godot 4.7.2 stable official,
Forward+/D3D12, RTX 4080 SUPER** passed:

- **42 display inspections**, including all three sizes at eight yaw values,
  invalid-value clamps, configuration before ready, edited slot/support transforms,
  a translated/rotated parent, disk save/reload, independent instances, detached
  updates and the saved variants. Generated records do not accumulate and user
  slot attachments survive replacement and serialization.
- Every flat cassette bottom triangle is probed against the actual imported
  plinth surface (two centroids per inspection). Maximum bottom/top contact error
  is **0.00012 mm**. Minimum measured edge margin is **107.36 mm**, beyond the
  8 mm top bevel. The largest cassette's diagonal footprint bound also proves
  clearance of the inset top rectangle at every yaw angle. Floating and
  unsupported records fail the same surface-support check as expected.
- Both stations at identity and after parent translation (8,2,-6) m and yaw
  0.71 rad: **54 actual floor probes per placement**, 216 total, under all three
  furniture feet and through the front approach. Floor datum error is zero.
  The existing slab seam chamfer permits 2.1 mm depth; exact triangle-edge misses
  require support on both sides at ±10 micrometres. Floating, buried and absent
  floor controls fail the support test.
- Station envelopes clear existing architecture, shelves, reading stations,
  alcoves and both 3 × 3.4 m portal approaches. Minimum conservative horizontal
  separation from existing objects is **1.5898 m**. The stations' conservative
  central clear radius is **21.0455 m**. Each one-metre front approach is clear
  and supported. The lectern screen marker intersects its imported opaque surface
  and its normal faces the approach.
- **648 camera samples**, radii 12/16/19 m, heights 1.8/4/8 m and 5-degree steps:
  a 0.3 m camera envelope clears every imported room mesh, with **1.50 m** minimum
  clearance. These are static samples, not continuous collision testing.
- Imported small/medium/large cassettes, plinth and lectern pass triangle winding,
  area, normals, UV area and opaque matte material checks. Counts remain 1,728
  triangles per cassette and 432 per plinth/lectern.

Six GPU captures were visually inspected: overview, station front, floor contact,
isolated rear, end and underside. The room is hidden only for the three isolated
views. Existing review lighting and floor seam aliasing are visible; final
lighting and timeline readability are separate work. Import and runtime logs
were inspected separately and contain no errors or warnings. Results are in
`godot_validation.json`.

## Reproduce and remaining acceptance

From the repository root:

```powershell
./src/assets/catalog_display_review/verify_display.ps1
```

`-Godot` overrides the pinned executable. The runner copies 74 resource
dependencies and their GLB import settings into a unique retained project under
`src/.godot/`, isolates both roaming preferences and the local cache, imports,
runs GPU checks and publishes passing evidence. Both engine processes have
60-second timeouts. Refresh file receipts with
`python src/assets/catalog_display_review/update_manifests.py` after changes.

Blender MCP `get_addon_status` and `get_scene_info` both failed to connect.
Godot MCP `godot_editor_read(get_state)` could not reach ws://127.0.0.1:6550.
No Blender authoring was required. Standalone Godot was the explicit engine
validation fallback. Live MCP review and `godot_validate_meshes` remain
unavailable; the verifier supplies separate imported-triangle evidence. Live
review requires Blender's addon server and the intended Godot project open with
its MCP addon enabled.

These four follow-ups are implemented and tested. The issues remain open for
live review and final art/proportion approval. No physics, catalog interaction,
timeline text readability, roof fit or measured performance acceptance is
claimed. Existing source provenance and repository ownership terms apply;
no external models, maps, paid generation or new licensing dependency is added.

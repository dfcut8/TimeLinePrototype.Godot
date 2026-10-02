# Room fit — issues #24, #25, #31 and #33

This follow-up tests the existing wall infill, portal frame, small cassette and
large cassette together at room scale. It fills the earlier three-bay and
isolated-shelf reviews' perimeter-placement gap. Original Blender sources,
GLBs, materials and object scenes are reused without geometry edits.

![Godot room overview](godot_room_overview.png)

Open `review_room.tscn` and run the scene for an overview. Instance
`library_room_assembly.tscn` to reuse the assembly without review lights or
camera. Every bay, pier, shelf, cassette and rail component is an existing
PackedScene instance. This is a static fit study with no floor or roof;
Y=0 is the floor datum. It does not replace the application's main scene.

## Four issue outcomes

| Issue | Added integration and verification |
| --- | --- |
| [#24 Wall infill](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/24) | Twenty wall bays in a complete ring; both joins per bay, including the last-to-first seam, floor/header alignment and solid-surface triangle probes. |
| [#25 Portal frame](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25) | Two opposite 3 × 3.4 m portals; opening/jamb/header probes and clear furnishing-free approach volumes. |
| [#31 Small cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/31) | Four inward-facing shelves with 272 independent records; support contact, shelf and fixture clearances and no record overlaps under room rotations. |
| [#33 Large cassette](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/33) | Four inward-facing shelves with 176 independent records; the same measured checks, including the tighter 42 mm fixture clearance. |

## Dimensions and measured results

The room pivot is its centre at floor height, +Y up. Twenty-four piers sit at
radius 24.8 m on a 15° grid; bay centres sit at chord radius 24.587832 m.
Bay 0 is on -Z, Bay 12 on +Z; both are portals. Bays 6 and 18 are windows.
All other bays are walls. Eight shelf centres sit at radius 23 m, aligned
with walls 2/4/8/10/14/16/20/22 and facing inward. The 14 m rail runs along X,
centred at Y=1.5 m. All model instance scales remain one.

Standalone Godot 4.7.2 Forward+/D3D12 passed:

- 48 bay/pier interfaces with 8.685–8.693 mm clearance, including wraparound.
- 440 wall/portal triangle probes per placement, at identity and after moving
  the room by (8, 2, -6) m and rotating it 0.71 radians about +Y.
- 448 cassette supports with maximum error below 0.001 mm; minimum structural
  clearance 27.199 mm and light clearance 42.000 mm. No cassette overlaps.
- Shelves set back more than 1.2 m from their walls and clear of both portal
  approaches (3 m wide, 3.4 m high, extending 5 m inward and 1 m outward).
- A conservative 21.735 m clear radius for architecture/furnishings, exceeding
  the exploratory 20 m camera volume radius. The central rail is tested separately.
- 648 camera positions: radii 12/16/19 m, heights 1.8/4/8 m and 5° increments.
  With a 0.3 m camera envelope, minimum clearance is 2.435 m. These are geometric
  samples, not an implemented camera controller or proof of every possible path.

Four runtime captures were inspected: overview, portal, small shelf and large
shelf. `godot_room_validation.json` contains the measurements. Import and runtime
logs were inspected separately; both contain the existing Windows root
certificate-store error, with no scene, asset or script failures.

## Reproduce

From the repository root:

```powershell
python src/assets/library_room_review/create_review.py
./src/assets/library_room_review/verify_room.ps1
```

Use `-Godot` to override the executable. The verifier copies only required assets
to a unique temporary project, preserves their import settings, isolates editor
preferences, runs GPU verification, and retains that project for inspection.
It returns a failure for failed checks and copies successful evidence here.

## Remaining acceptance limits

On 2 October 2026, Blender MCP `get_addon_status` and `get_scene_info` both failed
to connect. Godot MCP `get_state` could not reach ws://127.0.0.1:6550. No Blender
authoring was needed; standalone Godot supplied the engine evidence. Live review
requires the Blender addon server and the Godot MCP addon connected to this
project. No live MCP validation is claimed.

Floor/roof integration, interactive camera behavior, event-strip/text readability,
art approval and measured performance remain outside this static assembly test.
No physics or animation is added to these decorative models. The four issues
remain open; this review does not claim their remaining acceptance gates passed.

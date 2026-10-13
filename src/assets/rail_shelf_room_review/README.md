# Rail visibility and mixed shelf fit — issues #5 and #28

![Mixed shelf in the room](godot_mixed_shelf.png)

Two follow-ups to existing model packages: a reusable mixed-size shelf bay for
[#28](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/28), and measured
perspective orbit visibility of the housing for
[#5](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5).
Existing GLBs, materials and Blender model bytes are unchanged.

## Reusable shelf

Instance `../record_stack_shelf_bay/mixed_cassette_shelf_bay.tscn`. Its floor-centre
pivot, +Y up, +Z aisle front and 1.6 × 2.4 × 0.44 m envelope match the existing bay.
Four shelves each hold nine independent cassette scenes: small/medium/large
repeated three times, for 36 records total (12 of each size). X pitch is 150 mm,
Y contacts are 0.16/0.72/1.28/1.84 m; Z positions are 0.080/0.055/0.030 m so the
three nominal front spines align. The four existing shelf lights remain instances.
This saved assembly has no runtime generator, camera or lighting rig.

The medium cassette now has its own object `.tscn` and explicit lossless import
settings. Its unchanged editable `.blend` moved into `source/` with `.gdignore`;
the model folder itself is importable. Export/render/roundtrip scripts follow
the new source path. Its original source SHA-256 remains
`76758c97a1978617f17bbed831dfef633ba651b3ada1287eabd767fe2fb15551`.

`room_assembly.tscn` combines the existing roofed room with a mixed shelf at
(22,0,0) m, yaw -90 degrees. The shelf remains outside the central 40 m diameter,
has floor support and clears existing shelves, perimeter, roof and portal
approaches. No existing shelf or room geometry is replaced.

## Engine evidence

Standalone **Godot 4.7.2 stable, Forward+/D3D12**, RTX 4080 SUPER:

- Mixed shelf tested at identity and parent translation (8,2,-6) m/yaw 0.71 rad.
  Maximum contact error is under 0.0002 mm; minimum structural clearance is
  27.198 mm, light gap 41.999 mm and neighboring cassette gap 53.398 mm.
- Imported small/medium/large meshes pass triangle winding/area, normals, UV
  area and four opaque matte material-slot checks; 1,728 triangles each.
- A 0.3 m camera envelope passes 216 samples: each of the 2/6/14 m rails at
  5-degree intervals, radius 12 m, height 1.8 m. Minimum remaining clearance
  is 1.50 m. A negative control rejects a camera inside the mixed shelf.
- Every rail vertex remains in frame at all samples, at 1280 × 720 and a
  65-degree vertical FOV. Measurements use actual imported vertices and the
  engine camera projection, including the insert's flat front face.

| Housing length | Maximum endpoint span | Minimum endpoint span |
| --- | --- | --- |
| 2 m | 94.15 px | 2.37 px |
| 6 m | 282.46 px | 7.53 px |
| 14 m | 659.06 px | 24.95 px |

The insert is only **1.04 px high** in the tested front ±60-degree sector.
The small minimum spans are end-on foreshortening, not missing meshes. Rear
captures show finished opaque housing, hiding the front insert as expected.
These results argue for a front browse sector and a deliberate zoom/reader
design; they do **not** establish text readability or approve unrestricted orbit.
The half-pixel assertion is only a geometry regression threshold.

Ten GPU captures were visually inspected: three front rail lengths, end/rear
rail views, mixed shelf in the room, and isolated front/rear/side/underside.
Room geometry is present in the first six; it is deliberately hidden for the
four isolated shelf views. Existing review lighting and floor seam aliasing
remain visible; this is not a final lighting pass.

Separate import/runtime logs contain no asset or script errors. Both retain
the host's existing Windows root-certificate-store error.

## Reproduce

From the repository root:

```powershell
python src/assets/rail_shelf_room_review/create_review.py
./src/assets/rail_shelf_room_review/verify_review.ps1
```

The runner accepts `-Godot`, copies the resource dependency closure into a new
temporary project, imports, runs the GPU verifier and publishes passing evidence.
The temporary project path is printed; open its `project.godot` to run the review.
The review folder stays excluded from the main project through `.gdignore`.
Reusable cassette and shelf objects are importable in the main project.

## Remaining issue acceptance

On 2 October 2026 Blender MCP `get_addon_status` and `get_scene_info` both failed
to connect. Godot MCP `get_state` could not reach ws://127.0.0.1:6550. No Blender
authoring was needed; standalone Godot was the explicit validation fallback.
Live review requires Blender's addon server and this project's Godot editor
with its MCP addon enabled. No live MCP mesh-validation pass is claimed.

These two follow-ups are implemented and tested. Issues remain open for live
review and final art/proportion approval. Camera measurements are discrete
static samples; continuous motion, interaction, event text, performance and
physics remain outside this model-fit delivery. Existing asset provenance and
licensing are unchanged; no external assets or paid generation were used.

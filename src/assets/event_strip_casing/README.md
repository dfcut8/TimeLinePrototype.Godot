# Shared event strip casing — issue #13

Reusable shallow graphite shell for [issue #13](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/13).
One casing serves image, video and future text records. Produced in live Blender
MCP, exported as GLB, and checked together with issue #12's rear pivot in Godot.

![Assembled, articulated casing in Godot](godot_articulated.png)

## Dimensions and interfaces

One unit = one metre. **900 × 200 × 30 mm** total envelope (4.5:1 front aspect).
Godot/glTF +Y up and +Z front; Blender +Z up and -Y front. Root/`PivotAttachment`
is the rear central mating face at (0,0,0). All exported transforms are identity.
The round rear mount contacts the pivot's 48 mm flange face without a gap.

| Feature | Resolved dimensions / position |
| --- | --- |
| Total shell outline | X ±0.450, Y ±0.100 m |
| Rear plate | back at Z=0.006 m |
| Front lip | Z=0.030 m, restrained 3–4 mm chamfer |
| Recess opening | 0.876 × 0.176 m, 6 mm corner radius |
| Recess floor | Z=0.015 m |
| PresentationOrigin | (0,0,0.016), 1 mm above floor |
| Safe rectangular presentation area | 0.852 × 0.152 m, centered |
| Picking proxy | 0.900 × 0.200 × 0.030 m, center Z=0.015 |

[Dimension drawing](dimensions.svg). The closed basin includes its finished back,
side walls, chamfered rim and recessed floor as one continuous mesh. The separate
rear mount seats 2 mm into the rear plate. No duplicated coplanar shell layers.
The floor is structural graphite: the independent dark face/backing insert is
still **issue #14**. No date/title/type/expand text, icons, state meshes, baked
captions or large reader panel are included.

The safe presentation area reserves room for date/title on the left and type/
expand affordances on the right. A possible layout allocates 650 mm to text,
16 mm separation and two 80 mm control zones; final typography and hit targets
need the separate runtime UI task. Camera/room scale and live-text readability
remain provisional; these dimensions establish the model's mounting interface.

`PickingProxy` is an Area3D on collision bit 6 (mask value 32), separate from
the socket's bit 5. It is ray-pickable, non-monitoring, and uses a simple box
that intentionally fills the recess and rounded corner cutouts. No blocking
physics body is needed for this presentation object.

## Delivery and reuse

- `event_strip_casing.tscn`: reusable object containing the GLB, attachment and
  presentation markers, and picking proxy.
- `event_strip_casing.glb`: 376 triangles, two meshes/surfaces, one embedded
  matte graphite material (linear RGB 0.048/0.060/0.073; roughness 0.68;
  metallic 0.22). Opaque and non-emissive; no textures or external dependencies.
- `source/event_strip_casing.blend`: editable model/review studio, excluded from
  Godot import using `source/.gdignore`.
- `build_asset.py`: live Blender build using pivot/socket helpers. Existing
  unrelated Blender scenes are preserved; matching delivery files are refreshed.
- `review_event.tscn`: socket, arm, pivot and casing subscene assembly.
- `review_assembly.tscn`: above/below examples on the existing rail and light.
- Four Blender previews, seven Godot captures, dimension drawing, mesh and
  engine reports, separate import/runtime logs and a SHA-256 manifest.

UV0 contains nondegenerate triangle-local projections suitable for these uniform
materials, not a painted texture atlas. All visible surfaces have geometric
normals and finished ends. No animation or LOD is included. Source provenance:
original procedural project artwork following V5 boards 03–04; no external
meshes, maps, fonts or third-party asset licenses. No repository-wide license
has been assigned by this delivery.

## Validation

Run `./src/assets/event_strip_casing/verify_godot.ps1` from the repository root.
It copies only the relevant assets into a retained temporary project, imports
with pinned Godot 4.7.2, and runs Forward+/D3D12 checks and captures. It does not
stop or alter another editor session. Import compression and automatic LODs are
disabled on the new assets to retain measured bevel geometry/triangle counts.

Both models passed manifold/positive-volume/degenerate-face checks in Blender.
Godot checks cover triangle counts, clockwise winding, normalized normals,
nonzero UV triangle areas, opaque matte materials, exact casing dimensions,
connector/panel attachment alignment, 450 above/below articulated poses, pose
clamps and pre-ready settings. Front/back physics picking rays hit the casing;
outside-width rays miss. Screenshots cover front/rear/side/underside, pivot
detail, assembly and an extreme supported pose, without bloom.

The minimum sampled shell clearances are 7.72 mm beyond the connector terminal
and 30.67 mm ahead of the yoke front envelope. Import/reimport and runtime logs
were checked separately: only the existing Windows root-certificate-store error
was present, no asset/script/test failures.

Godot MCP was blocked because another client owns the bridge; both `get_state`
and `godot_validate_meshes` failed to connect. **Live-project MCP validation
remains incomplete.** Explicit imported-mesh checks and GPU runtime validation
are the documented fallback. Full rotunda scale, performance, live content and
camera tracking are not established by these focused model tests.

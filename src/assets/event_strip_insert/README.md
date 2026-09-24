# Event strip blank insert — issue #14

Original model for [issue #14](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/14),
following V5 board 04. Includes editable Blender source, GLB, reusable Godot
subscene and an assembled example using the existing issue #13 casing.

![Insert fitted in Godot](godot_front.png)

## Dimensions and placement

One unit = one metre; Godot/glTF +Y up, +Z front, +X right. Blender +Z up,
-Y front. Transforms are identity. Root is the center of the rear seating face.

| Interface | Metres |
| --- | --- |
| Envelope | 0.874 wide × 0.174 high × 0.003 deep |
| Outer corner radius | 0.005 |
| Front/rear bevel | 0.0005 |
| Flat front | 0.873 × 0.173, at local Z=0.003 |
| Casing-relative placement | (0, 0, 0.015) |
| Clearance to casing opening | 0.001 each side, including rounded corners |
| Front depth below casing lip | 0.012 |
| Live-presentation marker | local (0, 0, 0.004), assembled Z=0.019 |
| Safe live-presentation rectangle | 0.852 × 0.152, centered |

[Dimension drawing](dimensions.svg). Rear contact with the casing floor is
intentional. The visible presentation plane is 3 mm ahead of that floor, avoiding
coplanar visible surfaces. The existing casing's old PresentationOrigin at Z=.016
is below this face: use **Insert/PresentationOrigin** for populated casings.
Rear closure stays in the casing. The insert has no collision; the casing's
Area3D continues to own selection. The assembly references the existing casing
and pivot folders, which were already uncommitted when this task began; those
dependencies must be included when publishing the assembled example.

`event_strip_insert.tscn` owns the imported mesh and markers.
`populated_casing.tscn` composes the casing and insert. `review_event.tscn`
composes the existing socket, arm and pivot with that populated casing.
`review_assembly.tscn` shows above/below events and issue #15's era tab on a rail.
Each object is an instanced subscene. No main scene or runtime behavior changed.

## Materials and UVs

One closed mesh, **156 triangles**, two material surfaces:

| Material | Linear RGB | Roughness | Metallic | Surface |
| --- | --- | --- | --- | --- |
| insert_edge | .025, .032, .040 | .68 | .22 | 138 trim/rear triangles |
| presentation_dark | .012, .017, .024 | .82 | 0 | 18 front triangles |

Both are opaque, non-emissive Principled materials embedded in the GLB. No maps
or external dependencies. The front has continuous planar 0–1 UVs with +X to
the right and +Y at the image top in Godot; all rounded front vertices preserve
the same mapping. Select the surface by material name `presentation_dark` and
use a per-instance surface override for replacement. Do not mutate the shared
imported material for per-event content. Live dates/titles/icons remain a future
presentation task; none are baked here. Trim triangles use separate packed UV
islands for their uniform material, rather than sharing the front's material.

## Production and verification

Built in **Blender 5.2.2 LTS**, using a separate background process after both
Blender MCP `get_addon_status` and `get_scene_info` failed to connect. No live
Blender session was controlled. `build_asset.py` creates an isolated scene and
uses the tracked `event_socket/build_asset.py` export/studio helpers. Run it
inside Blender, or use `blender --background --python` when the live bridge is
unavailable. It refreshes this folder's generated outputs only. The editable
`source/event_strip_insert.blend` includes the model and review studio; source
is excluded from Godot import with `.gdignore`. Four standalone Blender views
cover front, back, side/end and underside.

Godot **4.7.2 stable / Forward+ / D3D12 / RTX 4080 SUPER** imported and ran the
joint review in a temporary isolated project with 4× MSAA and no bloom. Checks
passed for actual dimensions, normals, clockwise winding, nonzero UV areas,
opaque matte materials, continuous front UV orientation, material replacement,
measured casing fit, rail/tab fit, 18 above/below articulated poses and front
ray selection through the populated casing. Screenshots cover front, rear,
side/end, underside, assembly, and era mount detail. Godot pads planar surface
AABBs by 10 micrometres; exact fit checks use vertex bounds. Front UV comparisons
use a 1e-6 absolute float tolerance.

Blender topology checks passed: zero non-manifold edges and zero degenerate
faces, positive signed volume. `validation.json`, `glb_inspection.json`,
`godot_validation.json`, separate import/reimport/runtime logs and SHA-256
`manifest.json` record the delivery. The only engine error was the existing
Windows root-certificate-store failure; there were no asset/script/test errors.

Rerun the joint engine check from the repository root:

```powershell
& ./src/assets/event_strip_insert/verify_godot.ps1
```

The script copies required assets into a retained temporary project; it does not
control another editor. Godot MCP `get_state` and `godot_validate_meshes` could
not reach port 6550. **Live-project MCP validation remains incomplete.** Enable
the Blender MCP addon listener and Godot MCP bridge for those checks. Explicit
mesh-array tests and standalone engine captures are the fallback, not MCP
success. The optional `game-dev` CLI was not found on PATH; this delivery follows
the repository's native asset-folder format, not a game-dev canonical package.

Full room/camera composition, text readability, tracking, performance and live
content remain outside these model tasks. No LOD is justified by a measured
performance need. Source provenance: original procedural project artwork using
V5 design references; no downloaded meshes, textures, fonts or external license
obligations. The repository has no top-level license; this delivery assigns none.

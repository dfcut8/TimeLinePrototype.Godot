# Oculus curb and radial roof beam — issues #22 and #23

Original V5 roof kit for [oculus curb #22](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/22) and [radial roof beam #23](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/23).
Each model has an editable Blender source, self-contained GLB, reusable Godot scene,
four Blender previews, topology report and SHA-256 manifest. The review assembly
instances 24 curbs, 24 beams and the existing Pier A; no object hierarchy is embedded
in the assembly. It depicts only the upper support tier, without lower storeys.

![Godot roof assembly](godot_assembly.png)

## Resolved geometry and interfaces

One unit is one metre. Godot/glTF +Y is up, Blender +Z is up; Blender +Y maps to
Godot -Z. All model transforms are identity. See [dimension drawing](dimensions.svg).
These local dimensions preserve the gallery's 15-degree grid and pier radius 24.8 m.
They are provisional architectural proportions, not structural engineering specifications
or approval of the full room/camera scale.

| Part/interface | Dimensions and placement |
| --- | --- |
| Curb | 15-degree sector, radii 10–10.6 m, height 0.6 m |
| Curb pivot | Rotunda centre at the curb underside; sector centred on +X |
| Curb seams | ±7.5 degrees, flat closed end faces, 24 copies close the ring |
| Curb bevels | 15 mm radial/vertical chamfers; no chamfer across mating sector ends |
| Curve sampling | 24 divisions per sector, maximum outer chord error 0.158 mm |
| Beam | 14.9 m long in +X, 0.32 m wide in Z, 0.55 m high |
| Beam pivot | Bottom centre of inner end, X=0; outer end X=14.9 |
| Beam finish | 15 mm longitudinal corner chamfers; closed planar end faces |
| Curb BeamBearing | Local (10.365, 0.6, 0) |
| Beam InnerBearing | Local (0.215, 0, 0) |
| Beam OuterBearing | Local (14.65, 0, 0) |
| Review curb | Position (0, 14.15, 0) |
| Review beam | Position (10.15, 14.75, 0) before rotation around room centre |
| Review Pier A | Radius 24.8 m, base Y=10; top at Y=14.75 |

For site angle `a = i * 15 degrees`, rotate the curb by `a` about Y; place the beam
at `(10.15*cos(a),14.75,-10.15*sin(a))`, with Y rotation `a`. Place Pier A at
`(24.8*cos(a),10,-24.8*sin(a))`, with Y rotation `a-90 degrees`, facing inward.
Beam underside and both bearing tops coincide at Y=14.75. The beam rests on
roughly 0.43 m of curb and 0.55 m of the pier's radial top face; it does not penetrate
either support. The beam's flat underside is 0.29 m wide between chamfers.

Each beam stays strictly inside its own 15-degree sector, so repeated beams cannot
intersect. The oculus remains open: nominal clear diameter 20 m (faceted minimum
about 19.99970 m). Roof underside at Y=14.15 is overhead; no camera-path geometry
was authored. Adjacent curb caps coincide internally at the join, while exposed
surfaces meet edge-to-edge. These are deliberate closed modules without visible
overlaid skins. Gallery geometry is unchanged; this review inherits its angular grid
and tier pitch, but does not render the full gallery/floor/room.

## Materials, source and delivery

Curb: **396 triangles**; beam: **28 triangles**. Each is one closed manifold mesh,
two material surfaces and one UV set. Both use embedded opaque constant PBR values:
`archive_graphite` linear RGB (.048,.060,.073), roughness .68, metallic .22;
`archive_basalt_ceramic` (.085,.103,.117), roughness .81, metallic 0. Ceramic is
confined to the top face; all sides/undersides/end faces are graphite. Packed UV0
is nondegenerate; no maps, external images, emission, text, rigs, animations or
physics bodies are included. These are static architectural models. Collision
for navigation belongs to later integration. No LOD is justified by these counts.

The adjacent asset folders contain `source/*.blend` with editable mesh/materials
and a separate review studio, excluded from GLB export. Only source folders have
`.gdignore`; both `.tscn` models and this review scene import in the main project.
`build_asset.py` creates an isolated Blender scene and never modifies an existing
interactive scene. The artwork is original, based on V5 board 05 and the issue
briefs; no downloaded assets, paid generators or third-party attribution apply.
No repository license is assigned by this delivery. The optional `game-dev` CLI
was unavailable; this is a repository-style package, not CLI certification.

Original request: “Pick up another 2 tasks from the issues to work on a 3d model.
It is ok to implement both one at a time. Just work on both.” No image generation
prompt or negative prompt was used.

## Verification

Blender **5.2.2 LTS** checked closed manifold edges, positive volume, face areas,
identity transforms, UV0, GLB attributes, material and triangle counts. Four
Blender views per asset cover front, back, end and underside.

Godot **4.7.2 stable official, Forward+, D3D12, RTX 4080 SUPER** imported and rendered
the actual `.tscn`/GLB assets. Imported normals, clockwise winding, triangle and
material counts, UV triangle areas, dimensions and attachment markers passed.
All 24 ring seams, including the closing seam, agree within **0.00448 mm**.
**288 paired triangle probes** test beam/curb and beam/pier bearing surfaces;
measured contact error is **0**. Sector containment checks prove beams do not
intersect neighbors, and a central vertical ray confirms an open oculus.
Compression and generated LODs are disabled to preserve exact interfaces.

The [contact sheet](review_contact_sheet.png), full-ring image, camera-height
capture and both bearing closeups were visually reviewed without bloom. Finished
sides and undersides are visible, with no missing faces or exposed join gaps.
Import/reimport logs and the separate game runtime log are retained. Only the
existing Windows root-certificate-store error occurred; no model/script/test errors.

Both Blender MCP `get_addon_status` and `get_scene_info` failed to connect.
Godot MCP `get_state` and `godot_validate_meshes` failed at ws://127.0.0.1:6550.
Authoring used standalone Blender, and validation used an isolated Godot GPU run
with direct imported-triangle checks. **Live MCP validation is incomplete** until
Blender's addon listener and this project's Godot MCP bridge are connected.
Whole-room scale, moving-camera clearance, timeline readability and user art review
remain pending. Focused roof testing does not establish those broader results.

## Reproduce

From repository root, run Blender with `--background --python-exit-code 1 --python
src/assets/roof_review/build_asset.py -- curb`, then the same command ending `-- beam`.
Run `python src/assets/roof_review/prepare_review.py` to regenerate the instanced
scenes, `./src/assets/roof_review/verify_godot.ps1` for import/GPU tests, and
`python src/assets/roof_review/package_manifest.py` after any output changes.
These commands refresh matching generated files only. The test runner retains its
isolated temporary project and does not change the main project settings.

This delivery is submitted for review in a pull request that closes issues #22 and
#23. The PR description retains the validation limits above: live Blender/Godot MCP
checks, whole-room scale, moving-camera clearance, timeline readability and final
user art review remain pending.

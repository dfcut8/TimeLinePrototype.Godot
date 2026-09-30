# Record stack corner module — issue #30

Original model for [#30](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/30). Instance `record_stack_corner.tscn`; editable source is `source/record_stack_corner.blend`. Rebuild and review instructions are in `../perimeter_corner_review/README.md`.

## Resolved interface

One unit is one meter. A **90° concave-front shelf bend** joins two straight stack runs. This is a local peripheral alcove connector, not a segment intended to tile the circular rotunda wall. Place the entire assembled alcove outside the proposed 20 m central clear radius; final room placement is not established by this model.

Godot envelope: **1.24 × 2.4 × 1.24 m**. Floor-level pivot at the bend center, with the first sector in +X/+Z; +Y is up. Blender +Z maps to Godot +Y, Blender -Y to +Z. Front radius 0.80 m, back radius 1.24 m, storage back surface radius 1.20 m. All object transforms are identity. Shelf tops **0.16, 0.72, 1.28, 1.84, 2.40 m**, matching #28 exactly. Base is 0.12 m high. Shelf deck is 28 mm thick; underside rear web and front lip add 12 mm.

Attach the first straight bay at **(1.02,0,-0.8), Y=-90°** and the second at **(-0.8,0,1.02), Y=180°**. Their end planes meet the corner at Z=0 and X=0. The existing bay uprights terminate the shelf runs; there are no overlapping corner end posts. Existing #29 end caps close the two free ends in the shared review scene.

The underside light-channel recess follows the entire curve at radii **0.82–0.87 m** (50 mm wide), with its roof 28 mm below each shelf top. Endpoint positions match the straight bay recess. Existing bay uprights remain at the joins, as in straight repeated bays; no uninterrupted glowing strip is claimed through those structural posts. The straight #27 fixture cannot be bent by scaling and is not reused as a curved fixture. This delivers the continuous curved housing recess, not new lighting behavior.

Twelve unscaled large cassettes test all four storage tiers at angles 20°, 45°, 70°, radius 1 m, with spines inward. The Godot report measures their actual imported vertices against the inner front and outer back, checks floor contact, headroom and pairwise envelope separation.

**9,860 triangles across 17 closed component meshes, three embedded materials, UV0.** Each quarter arc uses 72 intervals (1.25°), keeping maximum radial chord error below 0.074 mm. The existing palette is reused: graphite RGB (0.048,0.060,0.073), roughness 0.68/metallic 0.22; ceramic (0.085,0.103,0.117), roughness 0.81; dark panel (0.018,0.026,0.033), roughness 0.76. All opaque and non-emissive. No textures or other dependencies; no baked text. Lower-detail variants await measured need.

Front, back, ends and underside are finished. Internal shelf/back/base contact planes meet; no overlaid finish panel creates z-fighting. Topology/export evidence is in `validation.json`; actual Godot mesh, winding, UV, material, assembly and screenshot evidence is in the shared review directory. Decorative model only: no collision, animation or interaction behavior is implied.

Original project geometry and script; no external meshes, paid generation or third-party attribution. No new redistribution license is assigned. Full room placement, performance and live MCP checks remain unvalidated.

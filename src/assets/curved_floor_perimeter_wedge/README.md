# Curved floor perimeter wedge — issue #21

Original model for [#21](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/21). Instance `curved_floor_perimeter_wedge.tscn`; its visual comes from the self-contained GLB. Editable source: `source/curved_floor_perimeter_wedge.blend`. Rebuild and Godot review instructions are in `../perimeter_corner_review/README.md`.

## Resolved interface

One unit is one meter. The chamber radius is **32 m**, using the existing V5 exploratory 64 m diameter. Four 90° modules surround a **40 × 40 m square** made from 10 × 10 existing 4 m slabs. Each wedge is the closed region between the square corner and the circular perimeter in one quadrant. This square inner boundary is intentional: a concentric annular wedge would leave gaps against the rectangular tile grid.

Pivot is chamber center at deck height, outside the geometry. Godot +Y is up; Blender +Z exports to +Y and Blender -Y to +Z. The first quarter occupies +X/+Z. Place all four at the same origin with Y rotations 0°, 90°, 180°, 270° and identity scale. Outer radius 32 m; inner join lines X=20 and Z=20; deck Y=0; underside Y=-0.25. Tile centers are X/Z=-18,-14,...,18. Gallery #19 retains its 22–25.5 m annulus above this continuous floor; both use 0.25 m slab thickness. Gallery tiers are not included in the review.

144 arc intervals per quarter share the gallery's 0.625° angular sampling, with maximum outer chord sagitta 0.476 mm. Closed quarter end faces meet only on internal planes; they do not overlap exposed surfaces. The existing tile's 2 mm top chamfer leaves a shallow groove against the sharp infill edge, not a through gap. No rail, curb, support pedestal or added ornament.

**588 triangles, one embedded material, UV0.** Matte `archive_basalt_ceramic`: linear RGB (0.085,0.103,0.117), roughness 0.81, metallic 0. No maps, emission or external dependencies. All exposed top/bottom/arc/radial/inner faces are closed. Disable mesh compression and automatic LOD generation using the delivered `.glb.import` settings to preserve modular interfaces.

`validation.json` records manifoldness, positive volume, nondegenerate faces, UV presence, GLB version and exported counts. Actual imported bounds, seams, materials and GPU views are checked by the shared Godot verifier. No collision is included: this issue requests model production, not navigation or physics.

Geometry and modeling script are original project work, based on the V5 concept and issue brief. No third-party source or attribution; no new redistribution license is assigned. See shared review report for engine version/results and remaining full-room/live-MCP validation limits.

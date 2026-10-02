# Record stack end cap — issue #29

## Configurable row — issues #28 and #29

Instance `configurable_shelf_row.tscn` and set `bay_count` (default 3, clamped
to 1–32). It repeats the existing illuminated shelf bay and positions the two
cap scenes at X = ±(count × 0.8 m), with left/right yaw 180/0 degrees.
The floor-center pivot stays at the middle of the row. Complete width is
`1.6 × bay_count + 0.164` metres; height/depth stay 2.4/0.44 m. Keep scale at one.
`LeftJoin` and `RightJoin` mark the bay-to-cap contact planes, not the outside
of the cap details. Existing fixed row and alcove scenes remain available.

Changing the count rebuilds the generated bays and their four fixtures each.
Generated children have no saved owner and are recreated on load; user-added
children survive rebuilding. Place persistent attachments under the row or its
`Bays` container, not inside generated bays. The `@tool` script supplies editor
previews, but live Inspector behavior remains unverified. The count limit is a
configuration guard, not a measured performance budget. This assembly has no
records, collisions, navigation or seating interactions.

Run `../record_stack_family/verify_configurable.ps1` for the isolated Godot
4.7.2 Forward+/D3D12 review. All 14 cases passed: odd/even lengths, clamp limits,
resizing, translated/rotated parents, imported mesh joins, outward cap fit,
fixture mounting/clearance, pre-ready configuration, tree reentry, independent
instances, and disk save/reload preserving user attachments without duplicates.
Maximum bay seam error was 0.003815 mm against a 0.1 mm tolerance. Four GPU views
were inspected; see `godot_configurable_*` and separate `configurable_*.log`
files in that folder. Logs contain only the existing Windows certificate-store
error, with no asset/script errors.

Blender status/scene MCP calls failed, and Godot MCP could not reach port 6550.
Existing models and editable sources were reused; no Blender authoring was
needed. Standalone Godot was the explicit validation fallback. Live MCP/editor,
full-room clearance and performance review remain pending; this follow-up does
not close the issues.

Reusable `record_stack_end_cap.tscn`, editable `source/record_stack_end_cap.blend`, GLB 2 export, four Blender preview angles, and mesh validation are included. Rebuild using `../record_stack_family/build_asset.py -- cap` through Blender.

One unit is one meter. Godot/glTF +Y up, +Z front; Blender +Z up, -Y front. Origin is the **floor-level attachment plane**, local X=0, with +X pointing outward. Height **2.400 m**, depth **0.440 m**, structural thickness **0.080 m**, complete detail envelope **0.082 m**. Base matches the bay at 0.120 m high. All source transforms are identity.

For a bay centered at zero, place the right cap at **(0.800,0,0)** with zero rotation. Place the left cap at **(-0.800,0,0)** with **180 degrees around Y**. No negative scale is needed. For three bays at X=-1.6/0/1.6, use cap positions X=-2.4/+2.4 with the same rotations. The front/back-symmetric cap encloses exposed joins at either end. Its inset and two quiet geometric marks are non-emissive; no baked text.

456 triangles, 6 closed mesh components, 3 embedded opaque PBR materials matching the shelf bay and cassette family. See the shelf bay README for exact material parameters. UV0 and geometric normals on all parts; fixed 0.5–2 mm bevels on exposed detail, square joining faces. No external maps, animation, collision, or speculative LOD variants.

Blender 5.2.2 LTS mesh/header checks passed. Godot 4.7.2 Forward+/D3D12 validated imported geometry/materials and both ends of a three-bay row; front, back, side/end and underside GPU captures were inspected. `../record_stack_family/godot_validation.json` and separate import/reimport/runtime logs hold the evidence. The only remaining logged error is the host Windows certificate-store error.

Blender MCP was not exposed and Godot MCP connection failed. Standalone Blender and Godot were the explicit fallback; live MCP checks remain incomplete. See the shelf README for reconnection requirements. Room-scale/performance review remains outside this focused fit test. Shelf-light dependency #27 remains separate.

Original project-authored, dimension-driven geometry with no third-party asset inputs or textures. Concept direction comes from the repository V5 furniture sheet. No separate third-party license is introduced; distribution follows the project's chosen license. `manifest.json` records hashes. The GitHub issue remains open for review.

## Reusable capped assemblies — follow-up for #29

`capped_shelf_row.tscn` contains three illuminated bays at X=-1.6/0/1.6 and caps at X=-2.4/+2.4 (yaw 180/0). `capped_shelf_alcove.tscn` contains the existing corner, illuminated bays at (1.02,0,-0.8), yaw -90, and (-0.8,0,1.02), yaw 180. Its free-end caps are at (1.02,0,-1.6), yaw 90, and (-1.6,0,1.02), yaw 180. All scales are one. These scenes contain only reusable object instances, without studio nodes, cassettes or new meshes. The curved recess stays empty; a straight fixture is not bent around it.

Fresh Godot 4.7.2 Forward+/D3D12 review checks both straight and rotated cap seams, depth coverage, floor contact and corner-bay joins. Seven runtime captures in `../record_stack_family/` show the assembled surfaces. Rebuild scenes with `create_review.py`, verify with `verify_godot.ps1`, then refresh hashes with `package_delivery.py` there.

Both Blender MCP checks failed and Godot MCP could not connect to port 6550. Existing Blender sources and GLBs were reused unchanged; standalone Godot performed import/runtime validation. No asset or script errors remain in separate logs; the host certificate-store error persists. Live MCP, full-room and performance review remain pending.

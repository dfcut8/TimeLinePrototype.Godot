# Record stack end cap — issue #29

Reusable `record_stack_end_cap.tscn`, editable `source/record_stack_end_cap.blend`, GLB 2 export, four Blender preview angles, and mesh validation are included. Rebuild using `../record_stack_family/build_asset.py -- cap` through Blender.

One unit is one meter. Godot/glTF +Y up, +Z front; Blender +Z up, -Y front. Origin is the **floor-level attachment plane**, local X=0, with +X pointing outward. Height **2.400 m**, depth **0.440 m**, structural thickness **0.080 m**, complete detail envelope **0.082 m**. Base matches the bay at 0.120 m high. All source transforms are identity.

For a bay centered at zero, place the right cap at **(0.800,0,0)** with zero rotation. Place the left cap at **(-0.800,0,0)** with **180 degrees around Y**. No negative scale is needed. For three bays at X=-1.6/0/1.6, use cap positions X=-2.4/+2.4 with the same rotations. The front/back-symmetric cap encloses exposed joins at either end. Its inset and two quiet geometric marks are non-emissive; no baked text.

456 triangles, 6 closed mesh components, 3 embedded opaque PBR materials matching the shelf bay and cassette family. See the shelf bay README for exact material parameters. UV0 and geometric normals on all parts; fixed 0.5–2 mm bevels on exposed detail, square joining faces. No external maps, animation, collision, or speculative LOD variants.

Blender 5.2.2 LTS mesh/header checks passed. Godot 4.7.2 Forward+/D3D12 validated imported geometry/materials and both ends of a three-bay row; front, back, side/end and underside GPU captures were inspected. `../record_stack_family/godot_validation.json` and separate import/reimport/runtime logs hold the evidence. The only remaining logged error is the host Windows certificate-store error.

Blender MCP was not exposed and Godot MCP connection failed. Standalone Blender and Godot were the explicit fallback; live MCP checks remain incomplete. See the shelf README for reconnection requirements. Room-scale/performance review remains outside this focused fit test. Shelf-light dependency #27 remains separate.

Original project-authored, dimension-driven geometry with no third-party asset inputs or textures. Concept direction comes from the repository V5 furniture sheet. No separate third-party license is introduced; distribution follows the project's chosen license. `manifest.json` records hashes. The GitHub issue remains open for review.

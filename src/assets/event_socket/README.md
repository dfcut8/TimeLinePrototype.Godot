# Event socket / node — issue #10

Reusable V5 rail node, authored through live Blender MCP in Blender 5.2.2 LTS.
Original geometry; no downloaded meshes, textures, fonts or external material dependencies.

![Socket in Godot](godot_front.png)

## Interface

Godot coordinates use metres: +X chronology, +Y up, +Z front. The root is at
the rail centerline; translate along X to position an event. All model object
transforms are identity. Overall bounds are 0.110 × 0.136 × 0.0275 m, with
Z from 0.060 to 0.0875. The 110 mm disk seats against the existing housing's
flat front lips at Z=0.060 and bridges its channel, leaving the light insert
(front Z=0.044) untouched. The node deliberately occludes a short portion of
the light line, as in concept sheet 03. It requires no rail cut or replacement.

Upper/lower connector planes are Y=±0.068, Z=0.074, centered at X=0.
Each terminal is a 20 mm diameter flat face, chamfered from a 24 mm barrel.
`UpperAttachment` points local +Y up; `LowerAttachment` rotates 180° around Z
so local +Y points down. Attach an arm using either marker's transform.
The cylindrical mounts intentionally enter the solid disk; there are no
exposed coplanar faces. [Dimension drawing](dimensions.svg).

`event_socket.tscn` contains the GLB, both markers and a separate box picking
proxy. The Area3D uses layer 5 (bit mask 16), no monitoring and no collision
mask. Picking rays must include mask 16 and enable area queries. The box is
120 × 140 × 40 mm, centered at Z=0.075, and works from both sides. This is a
selection proxy, not a rigid body or player collision obstacle.

## Delivery

- `source/event_socket.blend`: isolated editable asset and review studio.
- `event_socket.glb`: 692 triangles, three meshes, four surfaces, two materials.
- `archive_graphite`: base color (0.048, 0.060, 0.073), roughness 0.68, metallic 0.22.
- `event_emphasis`: cyan (0.12, 0.42, 0.48), same roughness/metallic, no emission.
  This is a separate material region on SocketBody for future state overrides.
- UV0 and flat face normals; no maps required. Triangle-local UVs are valid
  for the uniform shared materials, not an atlas intended for painted textures.
- Four Blender previews and five Godot captures show front, rear, underside,
  side and assembly. No bloom is required. No animation or LOD is warranted
  for this small static part; scene-wide budgets remain unmeasured.
- `build_asset.py`: repeatable source, run via live Blender MCP with `runpy`.
  It creates a new Blender scene and preserves existing scenes and unsaved work.
- `validation.json`, `godot_validation.json`, logs and `manifest.json` are evidence.

## Validation

Blender checks passed: closed manifold parts, positive signed volumes, no
degenerate faces. Scene and viewport inspected through Blender MCP; preview
front/back/side/underside inspected. Godot 4.7.2 imported and ran the focused
assembly using **Forward+/D3D12 on RTX 4080 SUPER** in an isolated project.
Checks passed for imported dimensions, material separation, triangle counts,
normals, clockwise winding, nondegenerate UVs, upper/lower markers, rail/light
clearance, front/rear picking hits and an outside picking miss. Engine captures
were inspected. Import and runtime logs were checked separately: only the
pre-existing Windows root-certificate-store error remains, with no asset or
script errors. The certificate error also occurs before asset loading.

Godot MCP rejected the connection because another client owns its bridge.
Live-project MCP validation and `godot_validate_meshes` remain incomplete;
the isolated engine's explicit mesh-array checks are the documented fallback.
This model does not establish final room scale, orbit readability, event
interaction, or future rear-pivot/casing clearance.

Rerun: `./src/assets/event_socket/verify_godot.ps1 -Renderer forward_plus`.
This launches an isolated temporary project without controlling the user's editor.

Provenance: original project-authored procedural geometry following the V5
concept direction. No third-party license obligations; the repository has no
top-level license, so redistribution licensing remains the owner's decision.

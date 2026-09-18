# Event connector arm — issue #11

Slender reusable connector for the V5 event socket, produced after issue #10's
model and isolated engine checks. Authored and exported through live Blender
MCP, Blender 5.2.2 LTS; original geometry with no external assets.

![Above and below rail assembly in Godot](godot_assembly.png)

## Interface and adjustment

Metres, Godot +Y along the arm, +Z front. The root/`SocketAttachment` is at
the socket terminal; `PivotAttachment` is at (0, length_m, 0). Default length
is 0.450 m. Overall default dimensions are 0.028 × 0.450 × 0.028 m.
Both mating end faces are 20 mm diameter; the bevel widens to a 28 mm fitting.
Each fitting is 35 mm long. The shaft diameter is 18 mm.

Align the arm root to either socket attachment marker. Upper attachment is
(0, +0.068, 0.074); lower is (0, -0.068, 0.074) with 180° rotation around Z.
Both give coincident 20 mm terminal faces without exposed overlap or a gap.
The review scene uses two symmetric socket/arm subscene instances, one rotated
180° around Z. The rail and light are existing subscene instances.

Set `length_m` in the Inspector or at runtime, range **0.12–2.0 m**. Values
outside the range are clamped. The `@tool` script scales only the straight
shaft along its axis and translates the tip; both fittings retain their
original size and bevels. The shaft occupies Y=0.028 to length_m−0.028,
with 7 mm engagement into each fitting. Do not scale the whole root to change
length. The shaft and tip have intentional local translations in the GLB;
all object rotation and scale are identity. [Dimension drawing](dimensions.svg).

The 450 mm length is an initial module interface, not a final room/panel-scale
decision. The upper endpoint reserves a 20 mm contact face for **issue #12's
rear pivot**, which is not implemented here. Final pivot/casing fit, tracking
and orbit readability remain dependent on those future models.

## Delivery and material

- `event_connector_arm.tscn`: reusable object with imported model, length
  adjustment script and named attachment markers.
- `event_connector_arm.glb`: **308 triangles**, three meshes/surfaces, one
  matte graphite material matching the rail (linear base color
  0.048/0.060/0.073, roughness 0.68, metallic 0.22), no emission or maps.
- `source/event_connector_arm.blend`: isolated editable model/review studio.
- UV0 and flat normals. Triangle-local UV islands suit uniform materials;
  a painted texture would need its own nonoverlapping atlas.
- Four Blender previews and seven Godot captures cover all sides, assembly,
  socket seam and terminal. No bloom, animation, or physics body is needed.
  Event selection uses the socket's separate picking proxy.
- `build_asset.py` uses the helper in `../event_socket/build_asset.py` through
  live Blender MCP; existing Blender scenes/unsaved work are preserved.
- `validation.json`, `godot_validation.json`, separate import/runtime logs
  and `manifest.json` record the delivery. No LOD is justified for 308 triangles;
  total scene performance budgets remain unmeasured.

## Validation

Blender: positive-volume manifold parts, zero degenerate faces; scene,
viewport and front/rear/side/underside renders inspected. Godot **4.7.2,
Forward+/D3D12, RTX 4080 SUPER** imported and ran the focused assembly in an
isolated temporary project. Imported triangle counts, material properties,
normals, clockwise winding, UV triangle areas and default bounds passed.
Both upward/downward instances passed length tests at 0.12, 0.45, 0.8 and
2.0 m, out-of-range clamping, constant fitting dimensions, shaft diameter,
7 mm engagement, socket seam alignment and attachment endpoint distance.
A length configured before `_ready` was also checked. Runtime captures were
inspected for appearance, including both terminal close-ups.

Import and game logs were checked separately. Only the pre-existing Windows
root-certificate-store error appears; there are no asset, script, or test
errors. Godot MCP could not connect because another client owns the bridge.
**Live-project MCP validation and `godot_validate_meshes` remain incomplete.**
Explicit mesh-array tests in the isolated engine are the documented fallback.

Run `./src/assets/event_connector_arm/verify_godot.ps1` to reproduce checks.
The verifier depends on the socket verifier/helper and existing rail assets.
No other editor session is stopped or taken over.

Provenance/license: original procedural project artwork following the V5
concept board, with no downloaded content or third-party license obligations.
The repository has no top-level license; redistribution is the owner's decision.

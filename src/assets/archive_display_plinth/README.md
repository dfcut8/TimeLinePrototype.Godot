# Archive display plinth — issue #36

Model work for [#36](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/36).

## Dimensions and interfaces

Low rectangular display base, **0.700 m wide × 0.600 m high × 0.550 m deep**. Floor-center pivot; Godot/glTF +Y up, +Z front, +X width (Blender +Z up, -Y front). All transforms are identity; authoring unit is one meter. `TopContact` is (0,.6,0). Four closed components: recessed foot, ceramic pedestal, shadow neck and a 48 mm thick display top with 8 mm edge radii. **432 triangles / 3 materials**.

Instance the existing large cassette independently at **(0,.6,0)** relative to the plinth origin, with identity rotation/scale. Its bottom contacts the flat top exactly in the engine; measured minimum margins are **296.7 mm in X and 112.2 mm in Z**, clear of the bevel. The cassette is not baked into the plinth GLB. There is no statue, central tower or timeline support.

## Delivery and materials

The reusable `.tscn` instances the GLB and includes a `TopContact` marker. Editable source is in `source/`; the deterministic shared builder is `../furniture_review/build_asset.py`. Four Blender previews, a dimensional drawing, measured mesh report and SHA-256 manifest accompany each model. Godot runtime captures and fit results are in `../furniture_review/`. No collision, animation, interaction, text, emission or speculative LOD is included.

Three embedded opaque materials match the existing archive kit: `archive_graphite` (linear RGB .048/.060/.073, roughness .68, metallic .22), `archive_basalt_ceramic` (.085/.103/.117, roughness .81), and `archive_dark_panel` (.018/.026/.033, roughness .76). No maps or external material files are required. Each component has closed manifold geometry, positive volume, UV0 and outward normals. Adjacent structural components contact at their flat faces; rounded edges form intentional seams. Finished front, rear, ends and underside are visible in the review captures.

Original project-authored geometry based on the V5 furnishing brief and existing archive palette, using no downloaded meshes, fonts, textures or paid generation. No new redistribution license is assigned; repository ownership terms apply.

## Validation boundary

Built with standalone Blender 5.2.2 LTS. Isolated Godot 4.7.2 stable official, Forward+/D3D12, passed actual GLB import, measured bounds, unit scale, UV triangle area, outward triangle winding, material opacity/roughness, floor contact and assembly fit. Front, rear, end and underside GPU captures were visually inspected without bloom. Import/reimport and runtime logs were reviewed separately: only the host Windows root-certificate-store error remains; no model or script errors were reported.

Blender MCP `get_addon_status` and `get_scene_info` both failed to connect; Godot MCP `get_state` could not reach ws://127.0.0.1:6550. Standalone Blender and isolated Godot were the explicit fallback. Live MCP review and `godot_validate_meshes` remain unavailable; the fallback checks imported triangles directly. Reconnect Blender's addon server and open the intended Godot project with its MCP addon for live validation.

These optional assets are staged in a focused review scene. The issues defer room dressing until core timeline/room scale is approved, so no room placement is made or claimed. Full-room camera clearance, timeline dominance, measured performance and user art approval remain pending; issues are left open.

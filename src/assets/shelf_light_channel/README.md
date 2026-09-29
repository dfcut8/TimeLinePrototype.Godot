# Shelf light channel — issue #27

[Issue](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/27)

![Godot shelf fit](../light_window_review/godot_light_closeup.png)

The 1.460 m span × 0.010 m height × 0.044 m depth channel has a closed mounting back, two fixed 8 mm end fittings, side lips and a separate diffuser recessed 4 mm above the underside. Six closed components, **72 triangles / 3 materials**. Mounting origin is top-centre: all mesh Y is -0.010 to 0; +Z is shelf front. Two mounting markers are X=±0.690 m.

For the existing shelf bay, place at **(0, shelf_top - 0.028, 0.175)**. Occupied tiers have shelf tops 0.72, 1.28, 1.84 and 2.40 m. The top contacts the deck underside, the 44 mm depth leaves 3 mm on either side of the 50 mm recess, the ends clear uprights by 20 mm and the bottom sits 2 mm above the lip. The 0.16 m bottom shelf is against the base and does not receive a light. Large-cassette head clearance is 42 mm, measured in Godot.

Warm diffuser uses linear base .42/.29/.15, emission .42/.24/.10 at strength .3, roughness .72. It is opaque and deliberately subdued; the source includes no runtime light node or light-beam geometry. Lighting behavior remains separate from the model task.

To change span, edit `LENGTH` in the shared authoring script and rebuild with `-- light`; back, rails and diffuser change length while 8 mm end fittings remain fixed. The builder relocates scene mounting markers. Do not scale the scene. The shipped validation targets the 1.46 m bay; update fit expectations for another bay. See [resolved drawing](dimensions.svg).

## Delivery and validation

Editable `source/shelf_light_channel.blend`, self-contained `shelf_light_channel.glb`, reusable `shelf_light_channel.tscn`, four Blender previews, `validation.json`, import settings and file hashes are included. Source transforms are identity; 1 unit = 1 metre. Godot/glTF +Y up, +Z front, +X width; Blender +Z up, -Y front. Every component has UV0, outward normals, positive closed volume, no nonmanifold edges or degenerate faces. Contact faces meet at boundaries; no coplanar visible overlays. No external texture maps, animation, physics bodies or speculative LODs.

Original project-authored geometry derived from the repository V5 architecture direction; no third-party model, image, paid generator or new redistribution license. Embedded opaque materials reuse `archive_graphite` (linear RGB .048/.060/.073, roughness .68, metallic .22), `archive_basalt_ceramic` (.085/.103/.117, roughness .81) and, where used, `archive_dark_panel` (.018/.026/.033, roughness .76).

Built with Blender 5.2.2 LTS. Godot 4.7.2 stable official, Forward+/D3D12 on RTX 4080 SUPER passed imported bounds, normals/UVs, triangle winding/area, matte material, fit and opening tests. Front, rear, end and underside GPU captures were visually inspected without bloom. See [shared evidence and rebuild instructions](../light_window_review/README.md) and `../light_window_review/godot_validation.json`. Import compression and automatic LODs are disabled to preserve interfaces. Separate editor import/reimport and game runtime logs contain only the host root-certificate-store error; no asset/script/validation errors.

Both live MCPs were checked: Blender `get_addon_status` and `get_scene_info` could not connect; Godot `get_state` could not reach ws://127.0.0.1:6550. Standalone Blender and an isolated Godot project were the explicit fallback. Reconnect Blender's MCP addon and the intended Godot project's MCP addon for live review. The MCP mesh validator was unavailable; the standalone harness checked imported triangles directly. Full-room camera clearance, timeline dominance/readability, runtime lighting and user art review remain separate. This delivery leaves the GitHub issue open for review.

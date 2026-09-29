# Window bay frame — issue #18

[Issue](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/18)

![Godot pier fit](../light_window_review/godot_window_front.png)

Minimal rectangular frame with an empty **5.140 × 4.430 m** opening. Overall **5.460 × 4.750 × 0.246 m**, including 3 mm front/rear opaque inlays; structural depth 0.240 m. Sill, header and jambs are 0.160 m wide. Eight closed components, **480 triangles / 3 materials**. Finished front/back, interior reveals, ends and underside. There is no glass, sky plane, baked planet or star texture. The opening exposes whichever shared environment is used by the parent scene.

Bottom-centre pivot, named Sill/Header/OpeningCentre and LeftInterface/RightInterface markers. Header at Y=4.75 m aligns with the existing pier bearing and gallery underside; next tier starts at Y=5 m with the intervening 0.25 m gallery. See [resolved drawing](dimensions.svg).

## Rotunda placement

Uses existing pier radius **24.8 m** and **15 degree** pitch. Adjacent centre chord is **6.474099 m**, so review piers are X=±3.237049567 m, Z=0, rotated +7.5/-7.5 degrees around Y, with the frame between them. This is a chord infill, not a curved window. Minimum conservative separation from each rotated pier's entire AABB is **8.689 mm**. The straight jamb leaves a deliberate wider reveal beside the narrower shaft; it does not stretch into or intersect the pier. This open reveal is intentional, not a watertight wall seal.

For the rotunda, frame bottom-centre lies at radius `24.8*cos(7.5 degrees)` = approximately **24.587832 m**, midway between the adjacent pier angles; face +Z inward. For a segment centred on world +X, translate to (24.587832,0,0) and rotate -90 degrees around Y. Repeat the placement by 15 degrees for additional bays. Do not duplicate the bounding piers per window. The nearest frame face stays outside radius 24.46 m, clear of the proposed 20 m central zone; full-room navigation is not validated here.

## Delivery and validation

Editable `source/window_bay_frame.blend`, self-contained `window_bay_frame.glb`, reusable `window_bay_frame.tscn`, four Blender previews, `validation.json`, import settings and file hashes are included. Source transforms are identity; 1 unit = 1 metre. Godot/glTF +Y up, +Z front, +X width; Blender +Z up, -Y front. Every component has UV0, outward normals, positive closed volume, no nonmanifold edges or degenerate faces. Contact faces meet at boundaries; no coplanar visible overlays. No external texture maps, animation, physics bodies or speculative LODs.

Original project-authored geometry derived from the repository V5 architecture direction; no third-party model, image, paid generator or new redistribution license. Embedded opaque materials reuse `archive_graphite` (linear RGB .048/.060/.073, roughness .68, metallic .22), `archive_basalt_ceramic` (.085/.103/.117, roughness .81) and, where used, `archive_dark_panel` (.018/.026/.033, roughness .76).

Built with Blender 5.2.2 LTS. Godot 4.7.2 stable official, Forward+/D3D12 on RTX 4080 SUPER passed imported bounds, normals/UVs, triangle winding/area, matte material, fit and opening tests. Front, rear, end and underside GPU captures were visually inspected without bloom. See [shared evidence and rebuild instructions](../light_window_review/README.md) and `../light_window_review/godot_validation.json`. Import compression and automatic LODs are disabled to preserve interfaces. Separate editor import/reimport and game runtime logs contain only the host root-certificate-store error; no asset/script/validation errors.

Both live MCPs were checked: Blender `get_addon_status` and `get_scene_info` could not connect; Godot `get_state` could not reach ws://127.0.0.1:6550. Standalone Blender and an isolated Godot project were the explicit fallback. Reconnect Blender's MCP addon and the intended Godot project's MCP addon for live review. The MCP mesh validator was unavailable; the standalone harness checked imported triangles directly. Full-room camera clearance, timeline dominance/readability, runtime lighting and user art review remain separate. This delivery leaves the GitHub issue open for review.

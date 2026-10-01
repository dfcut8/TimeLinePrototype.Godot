# Passage / portal bay frame — issue #25

[Issue](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/25)

![Godot assembly](../wall_portal_review/godot_portal_front.png)

Clear opening is 3.0 m wide by 3.4 m high, from floor level, with no threshold. Graphite jambs and header reveals are 150 mm wide and full depth. Closed side and upper wall fields complete the bay. No door, animation or passage gameplay.

## Dimensions and interfaces

Envelope **5.46 × 4.75 × 0.246 m** (width, height, depth), including 3 mm face skins on both sides of a 0.24 m structural core. One authoring unit is one metre. Bottom-centre pivot, identity source transforms. Godot/glTF +Y up, +Z front, +X width; Blender +Z up and -Y front. Named LeftInterface/RightInterface markers at X=±2.73, Y=0; Header at Y=4.75. OpeningCentre is (0,1.7,0). See [dimension drawing](dimensions.svg).

Interchangeable envelope with the existing window bay. Uses the established 24.8 m pier radius / 15° pitch: adjacent pier centres are 6.474099 m apart, rotated ±7.5° in the focused review. Minimum conservative pier AABB gap is 8.689 mm. Narrow open reveals beside the narrower pier shafts follow the existing window interface; this is not a sealed exterior-wall system. All exposed model edges and backs are closed. At world +X, place bottom-centre at (24.587832,0,0), rotate -90° about Y to face inward; repeat about the room centre at 15° intervals and share the bounding piers. These are inherited module dimensions, not final room-scale approval.

## Delivery

The portal is now also instanced in `../wall_infill_bay/mixed_bay_arc.tscn`,
between the wall and window bays with shared piers. Eighty additional transformed
surface probes check the wall and portal, including both sides of each jamb and
the header boundary. See the [mixed fit review](../wall_portal_review/README.md).

Editable `source/passage_portal_bay_frame.blend`, glTF 2.0 `passage_portal_bay_frame.glb`, reusable `passage_portal_bay_frame.tscn`, four Blender preview PNGs, import settings, geometry report and SHA-256 manifest. **720 triangles, 3 materials, 12 closed components.** Each component has UV0, positive volume, outward normals, no nonmanifold edges or degenerate faces. Contact faces meet on boundaries; decorative skins have thickness. No maps or external texture dependencies. No speculative LOD, collision bodies or animation; these are static architectural art objects.

Embedded materials match the existing kit: archive_graphite (linear RGB .048/.060/.073, roughness .68, metallic .22), archive_basalt_ceramic (.085/.103/.117, roughness .81), archive_dark_panel (.018/.026/.033, roughness .76). No emission, slogans or baked text. Original project-authored geometry based on the repository V5 architecture concept; no third-party asset or new license dependency. Redistribution follows the repository's existing terms.

## Validation

Built with Blender 5.2.2 LTS. Standalone Godot 4.7.2 stable official, Forward+/D3D12, passed imported bounds, matte material, UV/normal/winding/triangle area, floor contact, common header and pier separation checks. 150 triangle probes per model check closed surfaces and the portal opening. Front/rear/end/underside GPU views were visually inspected. See [shared evidence and rebuild instructions](../wall_portal_review/README.md).

Blender MCP status and scene checks failed; Godot MCP get_state could not reach ws://127.0.0.1:6550. Standalone Blender plus an isolated Godot project were the explicit fallback. Live MCP validation remains incomplete. The unavailable MCP mesh validator was replaced by imported-triangle checks. Separate editor import and runtime logs show only the host root-certificate-store error, no asset/script validation errors. Full-room orbit clearance and timeline readability, physics/navigation, runtime lighting and user art approval remain pending. The issue is left open for review.

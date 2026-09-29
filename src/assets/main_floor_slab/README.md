# Main floor slab — issue #20

Original V5 matte basalt-like floor module for [#20](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/20). Instance `main_floor_slab.tscn`. Editable source is `source/main_floor_slab.blend`; `build_asset.py` also authors the associated uplight fixture.

Godot dimensions **4 × 0.25 × 4 m** (X/Y/Z), deck-centre pivot at Y=0, underside Y=-0.25. Repeat at 4 m X/Z intervals with identity scale. Four join markers lie at X/Z ±2 m. A 2 mm top chamfer forms a shallow 4 mm-wide V joint between slabs; full footprints meet from Y=-0.002 down, with no through hole. Internal end faces are buried opposing closures, not exposed overlapping top faces. The square tile has no preferred front; +Y is up. Blender +Z maps to Godot +Y, Blender -Y maps to Godot +Z.

**20 triangles, one material, UV0**, closed underside and all four ends. `archive_basalt_ceramic` matches the piers: linear base RGB (0.085, 0.103, 0.117), roughness 0.81, metallic 0. Constant PBR values are embedded; no texture maps or external material files are required. This restrained surface has no emission, mirror treatment, platform, ornament or physical camera track. No LOD is warranted for 20 triangles. Thickness matches the existing gallery; curved room perimeter integration remains issue #21.

Four Blender views and the shared Godot review cover upper, lower and end surfaces. See [delivery and verification](../floor_uplight_review/README.md), [dimensional drawing](../floor_uplight_review/dimensions.svg), and [GPU tiled patch](../floor_uplight_review/godot_floor_top.png).

![Slab preview](preview_front.png)

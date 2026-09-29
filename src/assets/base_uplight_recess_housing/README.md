# Base uplight recess housing — issue #26

Original V5 fixture for [#26](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/26). Instance `base_uplight_recess_housing.tscn`; housing and separate `EmissionInsert` mesh are inside its model scene. Editable source is `source/base_uplight_recess_housing.blend`.

Godot dimensions **0.232 × 0.140 × 0.108 m** (X/Y/Z). Origin is the back-face centre, +Y up, +Z front. All object transforms are applied. Place at the existing pier A `UplightPocket` marker plus **(0, 0, 0.004)** in pier-local space: resulting position **(0, 0.39, 0.184)**. The fixture occupies X=±0.116, Y=0.32–0.46, Z=0.184–0.292. The reserved receiver is X=±0.12, Y=0.31–0.47, Z=0.18–0.30: clearances are **4 mm each side, 10 mm top/bottom, 4 mm rear, 8 mm front**. The main pier scene is preserved; the review assembly demonstrates composition. Same nominal pocket also exists in pier B, but only A was tested here.

The blind front cavity is 208 mm wide, 114 mm high and 98 mm deep, with a 10 mm closed back. The separate 192 × 55 × 6 mm diffuser is tilted 35° from horizontal toward the front. Its top normal points upward and forward; it remains wholly inside the housing's cavity. The housing has finished rear, bottom, roof, side and aperture-return surfaces. This is the pier-base insert variant, not a floor cutout: floor mounting would require a separately authored receiver.

**40 triangles** total (housing 28, diffuser 12), two embedded PBR materials, UV0. `archive_graphite`: linear RGB (0.048, 0.060, 0.073), roughness 0.68, metallic 0.22. `archive_warm_diffuser`: RGB (0.52, 0.32, 0.15), roughness 0.72, metallic 0, emission strength 0.35 (glTF emissive factor 0.182, 0.112, 0.0525). No maps, light nodes, light beams, runtime illumination setup, baked text or animation. The emission mesh/material can be replaced independently. No LOD is justified at this budget.

See [delivery and verification](../floor_uplight_review/README.md), [dimensional drawing](../floor_uplight_review/dimensions.svg), and [Godot pocket fit](../floor_uplight_review/godot_pocket.png).

![Fixture preview](preview_front.png)

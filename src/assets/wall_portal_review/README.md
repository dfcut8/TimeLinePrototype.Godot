# Wall and portal delivery — issues #24 and #25

![Godot views](review_contact_sheet.png)

Two reusable architectural scenes share the existing pier/window envelope. Open `review_wall.tscn` or `review_portal.tscn` for inspection. Each model, pier and review rig is a PackedScene instance. The main application is unchanged.

- [Wall infill](../wall_infill_bay/README.md): 708 triangles, 3 materials.
- [Portal bay](../passage_portal_bay_frame/README.md): 720 triangles, 3 materials; 3 × 3.4 m opening.

## Mixed-bay assembly (issues #24 and #25 follow-up)

Open `review_mixed.tscn` for the wall/portal/window fit review. The reusable
`../wall_infill_bay/mixed_bay_arc.tscn` contains three existing bay scene instances
and exactly four shared pier instances, with no copied mesh hierarchies. Its pivot
is the centre of the portal at floor level; +Y is up and +Z faces into the room.
Pier radius is 24.8 m, pitch is 15 degrees, and bay centres sit on the chord
midpoints at radius 24.587832 m. This is a three-bay sector, not a full room.

The standalone Godot 4.7.2 Forward+/D3D12 run passed all six bay/pier clearances
(8.689 mm), common 4.75 m headers, floor contact and unscaled module checks.
Eighty additional triangle probes verify the solid wall and the unobstructed
3 x 3.4 m portal, both at the original placement and after translating/rotating
the whole assembly. These complement the original 300 surface probes. Front,
rear, end and underside captures are saved as `godot_mixed_*.png`.

![Mixed bay assembly](godot_mixed_front.png)

This follow-up reuses the delivered Blender models without remodelling them.
Both Blender MCP connection checks and Godot MCP get_state failed again;
standalone Godot is the validation fallback. Import and runtime logs separately
contain only the host root-certificate-store error and no scene/script failures.
Live MCP and full-room camera/readability validation remain incomplete.

Regenerate the assembly with `python src/assets/wall_portal_review/create_mixed_review.py`,
then run the verification and manifest commands below.

## Rebuild assets and verification

From repository root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/wall_portal_review/build_asset.py -- wall
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/wall_portal_review/build_asset.py -- portal
./src/assets/wall_portal_review/verify_godot.ps1
python src/assets/wall_portal_review/package_manifest.py
```

Blender creates an isolated scene and writes only that scene's editable source library. The Godot runner copies required assets into a unique temporary project, imports, disables compression and automatic LODs, reimports, then runs actual GPU verification. No changes to the main project settings or unsaved interactive work.

## Evidence

Each asset's validation.json checks closed manifold components, positive volume, UV presence, triangle counts and glTF container integrity. godot_validation.json records successful engine checks of actual imported triangles, normals, UV areas, opaque matte materials, envelope, floor contact, tier alignment, markers, 8.689 mm pier separation and 300 total surface/opening probes. Eight GPU captures were inspected for front, rear, ends and undersides, without bloom. No missing exposed faces or z-fighting were observed.

Import/reimport logs and runtime.log were checked separately: only the existing Windows root-certificate-store access error appears. No model, script or validation errors. Static art scope: no physics or animation to test.

Both Blender MCP checks failed and Godot MCP could not reach port 6550. Standalone Blender 5.2.2 LTS and Godot 4.7.2 stable Forward+/D3D12 were used as fallback. Live MCP and full-room orbit/readability review remain incomplete; reconnect the Blender addon and this project's Godot addon for live review. The imported-triangle harness substitutes for the unavailable MCP mesh validator. User art approval and full-room integration remain separate. Issues are not closed and no PR is opened by this delivery.

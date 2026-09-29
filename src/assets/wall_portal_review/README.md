# Wall and portal delivery — issues #24 and #25

![Godot views](review_contact_sheet.png)

Two reusable architectural scenes share the existing pier/window envelope. Open `review_wall.tscn` or `review_portal.tscn` for inspection. Each model, pier and review rig is a PackedScene instance. The main application is unchanged.

- [Wall infill](../wall_infill_bay/README.md): 708 triangles, 3 materials.
- [Portal bay](../passage_portal_bay_frame/README.md): 720 triangles, 3 materials; 3 × 3.4 m opening.

## Rebuild

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

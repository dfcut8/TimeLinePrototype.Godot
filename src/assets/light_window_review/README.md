# Shelf light and window frame review — issues #27 and #18

Two new reusable model scenes integrate with the existing shelf bay/cassette and structural pier A. The main application scene is unchanged. Open `review_shelf.tscn` or `review_window.tscn` for focused inspection; all distinct objects, including the review rig, are scene instances.

- [Shelf channel delivery](../shelf_light_channel/README.md): 72 triangles, 3 materials, editable source and four Blender previews.
- [Window frame delivery](../window_bay_frame/README.md): 480 triangles, 3 materials, editable source and four Blender previews.

## Rebuild

From the repository root, use Blender 5.2.2:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/light_window_review/build_asset.py -- light
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/light_window_review/build_asset.py -- window
./src/assets/light_window_review/verify_godot.ps1
python src/assets/light_window_review/package_manifest.py
```

Each build uses a new Blender scene and writes only that scene to the model source library. The Godot runner copies just required assets into a uniquely named temporary project, uses the pinned 4.7.2 executable, imports, disables mesh compression/LOD generation, reimports and runs GPU verification. Temporary logs are retained. Source project settings and interactive app work are preserved.

## Evidence

`validation.json` in each model folder records manifold/volume/UV/GLB checks. `godot_validation.json` records imported mesh/material counts, triangle winding and UV area, dimensions, floor/deck contact, recess fit, four large-cassette clearances, pier footprint separation, and actual triangle probes for the open aperture and closed frame. All assertions passed. GPU captures cover front/rear/end/underside of both assemblies and an underside channel closeup. These were visually inspected: opaque surfaces are present, the lens remains recessed and quiet, and the frame opening is empty.

Import/reimport logs and `runtime.log` are distinct; the only error in the successful run is Windows certificate-store access, also seen in existing reviews. The first review attempt caught a text-scene numeric syntax error; it was fixed before the successful run. No model, script, or game validation errors remain in the recorded final run.

Both live MCP connection checks failed. Blender requires its MCP addon running; Godot requires this project's addon at ws://127.0.0.1:6550. Thus this evidence is standalone Blender and Godot validation, not live MCP validation. The unavailable MCP mesh validator is replaced here by imported triangle checks. Full-room orbit/readability, environment composition, runtime light behavior, physics/navigation and user art approval remain outside this focused model review.

The original request was: “Pick up another 2 tasks from the issues to work on a 3d model. It is ok to implement both one at a time. Just work on both.” These issues were selected because the shelf and pier dependencies already exist. Both issues remain open until review/publication; no PR was requested or opened.

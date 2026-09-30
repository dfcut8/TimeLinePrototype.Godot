# Floor perimeter and stack corner — issues #21 and #30

Two original V5 models, authored sequentially with Blender 5.2.2 LTS. Each object has its own reusable scene, editable Blender source, embedded-material GLB, four preview angles, topology report and dimensional drawing in its sibling asset directory.

- `review_floor.tscn`: four perimeter quarters surrounding 100 unscaled existing 4 m floor slabs.
- `review_corner.tscn`: curved corner between two existing shelf bays, existing end caps and 12 independently instanced large cassettes.
- `verify_godot.gd`: checks the actual imported meshes, normals, clockwise triangle winding, UV area, opaque matte materials, bounds, seam positions, shelf/channel endpoints, cassette contact and clearance. Saves GPU captures of front, rear, side, underside and floor join detail.
- `verify_godot.ps1`: creates an isolated temporary project, imports assets, disables mesh compression/automatic LODs, runs Godot 4.7.2 Forward+/D3D12 and retains separate import/runtime logs. The temporary project path is printed at completion.

From the repository root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/perimeter_corner_review/build_asset.py -- floor
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python src/assets/perimeter_corner_review/build_asset.py -- corner
& src/assets/perimeter_corner_review/verify_godot.ps1
# Requires Python with Pillow installed (the bundled Codex Python includes it).
python src/assets/perimeter_corner_review/package_delivery.py
```

Builds replace only these new model outputs. The review folder is ignored by the main project importer; its verifier copies the required scenes to a temporary project. The two object wrappers themselves are importable in the main project. Source subdirectories have separate `.gdignore` markers to prevent automatic `.blend` conversion.

Both required live Blender MCP checks failed to connect. Godot MCP `get_state` could not reach `ws://127.0.0.1:6550`. Standalone Blender and Godot were used explicitly as fallbacks; no live scene or unsaved user work was touched. The game-dev CLI was absent from PATH. These are repository-native deliveries, not CLI-certified canonical packages. No paid provider, external mesh or new license was used.

Full room placement, camera orbit/readability, final architectural dimensions, curved light-fixture behavior and performance measurement remain outside this focused import/fit review. No runtime scripts, physics, interaction or animations were added to the objects. Live MCP validation remains unavailable. Issues remain open; no PR was requested.

## Verified results

Godot **4.7.2.stable.official.ed1daf0bf**, Forward+/D3D12 on NVIDIA RTX 4080 SUPER: all recorded checks passed. Imported four-quarter seam error **0.00242 mm**; shelf/channel endpoint error below **0.000001 mm**. Twelve large cassettes have minimum **37.76 mm front clearance**, **38.52 mm back clearance** and **52.00 mm headroom**. Their envelopes do not overlap. Geometry, material slots, scale, closed surfaces and the front/rear/side/underside renders were reviewed. The final exported GLB hashes match the exact files used in this engine run.

Separate import, reimport and game runtime logs contain the host's `Failed to read the root certificate store` message. No asset import, GDScript, geometry or validation errors remain. The first verification detected cached compressed geometry; the runner now changes the temporary source modification time after setting import flags so Godot actually rebuilds it. Delivered `.glb.import` files preserve disabled compression and automatic LODs.

The contact sheets combine Blender previews (top row) with engine assembly views (bottom row). File manifests were generated and their hashes verified. This does not claim live MCP validation or a complete room-scale review.

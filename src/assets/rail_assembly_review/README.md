# Capped rail assembly — issue #5

![Forward+ runtime review](review_contact_sheet.png)

Completes the outstanding Forward+/D3D12 assembly review for [housing issue #5](https://github.com/dfcut8/TimeLinePrototype.Godot/issues/5). Existing housing, light insert, joiner and cap geometry is reused. Their prior Compatibility-mode checks remain intact.

`../timeline_rail_housing/capped_timeline_rail.tscn` is a reusable 6 m rail containing three illuminated module scene instances, two joiners, and both cap scenes. It contains no review camera, lights or environment. Its origin is the earlier housing interface; Godot +X advances chronology, +Y up, +Z front. Modules start at X=0/2/4 m, joiners at 2/4 m, caps at 0/6 m. Envelope including caps/saddles is 6.008 × .126 × .123 m. Ten mesh instances total 384 triangles; materials and editable sources remain in the original component folders.

`review_assembly.tscn` instances that rail and the existing furniture review rig separately. Run `./src/assets/rail_assembly_review/verify_godot.ps1` from repository root. It copies dependencies into a unique temporary project, imports and reimports without mesh compression/automatic LODs, then launches Godot 4.7.2 Forward+/D3D12 and saves the report and captures here. No main application or existing GLB changes are required.

Checks passed for all three housing/light modules and both saddles: imported dimensions, triangle counts, normal/winding integrity, material slots/opacity/emission, insert clearance, saddle nonpenetration, zero module/light seam gaps, attachment marker alignment and cap termination. Twenty triangle-intersection probes per cap verify channel closure. Front/rear/underside seam and cap-end GPU captures were visually inspected with bloom disabled. Separate import/reimport/runtime logs contain only the existing host certificate-store error, no asset/script failures.

Both MCP connections failed at task start. This is an isolated engine fallback, not live-editor MCP validation. `godot_validate_meshes` was unavailable; the verifier inspects actual imported triangles instead. Physics and animation are inapplicable. Live project validation, full-room orbit/readability, final art approval and measured performance remain open; issue #5 is not closed. Blender was not needed for this assembly because component geometry is unchanged.

Run `python src/assets/rail_assembly_review/package_manifest.py` after deliberate delivery changes. Manifests bind the new delivery and the reusable rail's component dependencies. This is repository provenance, not game-dev CLI package certification.
## Configurable rail follow-up — issue #5

Open `review_configurable.tscn` for a seven-module example using the reusable
`../timeline_rail_housing/configurable_timeline_rail.tscn`. Set `module_count`
on that object to resize without scaling its meshes. Existing fixed review scenes
remain available. See the housing README for interfaces and validation boundaries.

Run `./src/assets/rail_assembly_review/verify_godot.ps1 -Configurable` from the
repository root. `godot_configurable_validation.json` and
`configurable_import.log`, `configurable_reimport.log`, `configurable_runtime.log`
record the standalone Forward+/D3D12 run. The two `godot_configurable_*.png`
captures show the 14 m rail and its last internal seam. No live MCP connection
was available; no new geometry was authored.

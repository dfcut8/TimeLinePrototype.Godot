# Structural pier B / narrow rib — #17

Narrow pier: 0.50 × 4.75 × 0.80 m overall (Godot X/Y/Z), 0.40 × 0.60 m shaft cross-section. Bottom-centre origin, +Z front. 76 triangles, two embedded matte materials, UV0, closed top/bottom and a blind uplight pocket.

Instance `structural_pier_b.tscn`; model and all mounting markers are inside the reusable scene. `source/structural_pier_b.blend` is editable. Its build script uses A's shared source so material, pocket, bevel and mounting dimensions stay consistent.

See [family delivery, resolved drawing, gallery fit, validation and limitations](../structural_pier_family/README.md). Both models passed focused Godot 4.7.2 GPU/import/mesh/fit checks via the CLI fallback. Live MCP and whole-room Forward Plus validation remain pending.

![Blender preview](preview_front.png)

"""Compose existing bay scenes on the shared 24.8 m / 15 degree pier grid."""
from math import cos, sin, radians
from pathlib import Path

root = Path(__file__).resolve().parent
radius = 24.8
chord_radius = radius * cos(radians(7.5))
lines = ['[gd_scene load_steps=5 format=3]']
for index, asset in enumerate(('wall_infill_bay', 'passage_portal_bay_frame', 'window_bay_frame', 'structural_pier_a'), 1):
    lines.append(f'[ext_resource type="PackedScene" path="res://assets/{asset}/{asset}.tscn" id="{index}"]')
lines.append('[node name="MixedBayArc" type="Node3D"]')
for name, index, angle, distance in [
    ('Wall', 1, -15, chord_radius), ('Portal', 2, 0, chord_radius),
    ('Window', 3, 15, chord_radius),
    *[(f'Pier{i}', 4, a, radius) for i, a in enumerate((-22.5, -7.5, 7.5, 22.5))],
]:
    lines.extend([
        f'[node name="{name}" parent="." instance=ExtResource("{index}")]',
        f'position = Vector3({distance*sin(radians(angle)):.9f}, 0, {chord_radius-distance*cos(radians(angle)):.9f})',
        f'rotation_degrees = Vector3(0, {-angle}, 0)',
    ])
(root.parent / 'wall_infill_bay' / 'mixed_bay_arc.tscn').write_text('\n'.join(lines)+'\n')

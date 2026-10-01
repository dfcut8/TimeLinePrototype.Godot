"""Rebuild the two cassette shelf arrangements and large display assembly."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

for size, count, pitch in [('small', 17, .085), ('large', 11, .125)]:
    name = f'archive_record_{size}'
    lines = ['[gd_scene load_steps=3 format=3]',
             '[ext_resource type="PackedScene" path="res://assets/record_stack_shelf_bay/illuminated_shelf_bay.tscn" id="1"]',
             f'[ext_resource type="PackedScene" path="res://assets/{name}/{name}.tscn" id="2"]',
             f'[node name="{size.title()}CassetteShelf" type="Node3D"]',
             '[node name="Shelf" parent="." instance=ExtResource("1")]']
    for level in range(4):
        for index in range(count):
            lines += [f'[node name="Record_{level}_{index}" parent="." instance=ExtResource("2")]',
                      f'position = Vector3({(index-(count-1)/2)*pitch:.6f}, {.16+level*.56:.6f}, 0.03)']
    (ROOT/name/'shelf_assembly.tscn').write_text('\n\n'.join(lines)+'\n')

(ROOT/'archive_record_large/display_assembly.tscn').write_text('''[gd_scene load_steps=3 format=3]
[ext_resource type="PackedScene" path="res://assets/archive_display_plinth/archive_display_plinth.tscn" id="1"]
[ext_resource type="PackedScene" path="res://assets/archive_record_large/archive_record_large.tscn" id="2"]
[node name="LargeCassetteDisplay" type="Node3D"]
[node name="Plinth" parent="." instance=ExtResource("1")]
[node name="Record" parent="." instance=ExtResource("2")]
position = Vector3(0, 0.6, 0)
''')

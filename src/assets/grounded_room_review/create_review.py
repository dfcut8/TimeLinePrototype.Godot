"""Assemble the delivered floor modules and furnished library without mesh edits."""
from pathlib import Path
OUT = Path(__file__).resolve().parent
lines = ['[gd_scene load_steps=3 format=3]',
 '[ext_resource type="PackedScene" path="res://assets/main_floor_slab/main_floor_slab.tscn" id="1"]',
 '[ext_resource type="PackedScene" path="res://assets/curved_floor_perimeter_wedge/curved_floor_perimeter_wedge.tscn" id="2"]',
 '[node name="LibraryFloor" type="Node3D"]']
for x in range(10):
    for z in range(10):
        lines += [f'[node name="Tile_{x}_{z}" parent="." instance=ExtResource("1")]',
                  f'position = Vector3({-18+4*x}, 0, {-18+4*z})']
for i in range(4):
    lines += [f'[node name="Wedge{i}" parent="." instance=ExtResource("2")]',
              f'rotation_degrees = Vector3(0, {i*90}, 0)']
(OUT/'library_floor.tscn').write_text('\n\n'.join(lines)+'\n', encoding='utf-8')
def compose(filename, name, children):
    text = [f'[gd_scene load_steps={len(children)+1} format=3]']
    for i, (label, path) in enumerate(children, 1):
        text.append(f'[ext_resource type="PackedScene" path="res://assets/{path}.tscn" id="{i}"]')
    text.append(f'[node name="{name}" type="Node3D"]')
    for i, (label, _) in enumerate(children, 1):
        text.append(f'[node name="{label}" parent="." instance=ExtResource("{i}")]')
    (OUT/filename).write_text('\n\n'.join(text)+'\n', encoding='utf-8')
compose('grounded_room.tscn', 'GroundedRoom', [('Floor','grounded_room_review/library_floor'),('Furnishings','furnished_room_review/furnished_room')])
compose('review_room.tscn', 'GroundedRoomReview', [('Room','grounded_room_review/grounded_room'),('ReviewRig','library_room_review/room_review_rig')])

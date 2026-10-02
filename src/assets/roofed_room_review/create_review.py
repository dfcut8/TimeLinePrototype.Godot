"""Fit the delivered roof frame to the existing single-storey library piers."""
from math import cos, sin, radians
from pathlib import Path

OUT = Path(__file__).resolve().parent
lines = ['[gd_scene load_steps=3 format=3]',
         '[ext_resource type="PackedScene" path="res://assets/oculus_curb_segment/oculus_curb_segment.tscn" id="1"]',
         '[ext_resource type="PackedScene" path="res://assets/radial_roof_beam/radial_roof_beam.tscn" id="2"]',
         '[node name="LibraryRoofFrame" type="Node3D"]']
for i in range(24):
    # Match Perimeter/Pier<i>, which is half a bay clockwise from Bay<i>.
    angle = radians(97.5 - i * 15)
    lines += [f'[node name="Curb{i}" parent="." instance=ExtResource("1")]',
              'position = Vector3(0, 4.15, 0)',
              f'rotation = Vector3(0, {angle:.12f}, 0)',
              f'[node name="Beam{i}" parent="." instance=ExtResource("2")]',
              f'position = Vector3({10.15*cos(angle):.9f}, 4.75, {-10.15*sin(angle):.9f})',
              f'rotation = Vector3(0, {angle:.12f}, 0)']
(OUT/'library_roof_frame.tscn').write_text('\n\n'.join(lines)+'\n', encoding='utf-8')

def compose(filename, name, children):
    text = [f'[gd_scene load_steps={len(children)+1} format=3]']
    for i, (label, path) in enumerate(children, 1):
        text.append(f'[ext_resource type="PackedScene" path="res://assets/{path}.tscn" id="{i}"]')
    text.append(f'[node name="{name}" type="Node3D"]')
    for i, (label, _) in enumerate(children, 1):
        text.append(f'[node name="{label}" parent="." instance=ExtResource("{i}")]')
    (OUT/filename).write_text('\n\n'.join(text)+'\n', encoding='utf-8')

compose('roofed_room.tscn', 'RoofedLibraryRoom', [
    ('GroundedRoom', 'grounded_room_review/grounded_room'),
    ('RoofFrame', 'roofed_room_review/library_roof_frame')])
compose('review_room.tscn', 'RoofedRoomReview', [
    ('Room', 'roofed_room_review/roofed_room'),
    ('ReviewRig', 'library_room_review/room_review_rig')])

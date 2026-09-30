"""Build review scenes from reusable object instances, never embedded object meshes."""
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parent
assets=ROOT.parent
names=('oculus_curb_segment','radial_roof_beam','structural_pier_a')
header='[gd_scene load_steps=5 format=3]\n'
for i,name in enumerate(names,1):
    header+=f'[ext_resource type="PackedScene" path="res://assets/{name}/{name}.tscn" id="{i}"]\n'
header+='[ext_resource type="PackedScene" path="res://assets/roof_review/review_rig.tscn" id="4"]\n[node name="RoofReview" type="Node3D"]\n[node name="ReviewRig" parent="." instance=ExtResource("4")]\n'
assembly=header
for i in range(24):
    a=math.radians(i*15)
    for name,resource,radius,y,rotation in [('Curb',1,0,14.15,a),('Beam',2,10.15,14.75,a),('Pier',3,24.8,10,a-math.pi/2)]:
        assembly+=f'[node name="{name}{i}" parent="." instance=ExtResource("{resource}")]\nposition = Vector3({radius*math.cos(a)}, {y}, {-radius*math.sin(a)})\nrotation = Vector3(0, {rotation}, 0)\n'
(ROOT/'review_assembly.tscn').write_text(assembly)
for name in names[:2]:
    (ROOT/f'review_{name}.tscn').write_text(f'[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://assets/{name}/{name}.tscn" id="1"]\n[ext_resource type="PackedScene" path="res://assets/roof_review/review_rig.tscn" id="2"]\n[node name="Review" type="Node3D"]\n[node name="Asset" parent="." instance=ExtResource("1")]\n[node name="ReviewRig" parent="." instance=ExtResource("2")]\n')

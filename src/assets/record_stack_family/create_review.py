"""Create reusable asset wrappers and an explicitly instanced fit-review scene."""
from pathlib import Path
P=Path(__file__).resolve().parent
for name,root in [('record_stack_shelf_bay','RecordStackShelfBay'),('record_stack_end_cap','RecordStackEndCap')]:
    out=P.parent/name
    out.mkdir(exist_ok=True)
    text=f'''[gd_scene load_steps=2 format=3]
[ext_resource type="PackedScene" path="res://assets/{name}/{name}.glb" id="1"]
[node name="{root}" type="Node3D"]
[node name="Visual" parent="." instance=ExtResource("1")]
'''
    if name.endswith('bay'):
        for i,y in enumerate([.16,.72,1.28,1.84]):
            text+=f'\n[node name="Shelf{i}" type="Marker3D" parent="."]\nposition = Vector3(0, {y}, 0)\n'
        for i,y in enumerate([.686,1.246,1.806,2.366]):
            text+=f'\n[node name="LightRecess{i}" type="Marker3D" parent="."]\nposition = Vector3(0, {y}, 0.175)\n'
            text+=f'\n[node name="LightMount{i}" type="Marker3D" parent="."]\nposition = Vector3(0, {y+.006:.3f}, 0.175)\n'
        for side,x in [('Left',-.8),('Right',.8)]:
            text+=f'\n[node name="{side}Join" type="Marker3D" parent="."]\nposition = Vector3({x}, 0, 0)\n'
    (out/(name+'.tscn')).write_text(text)
paths=['record_stack_shelf_bay/record_stack_shelf_bay.tscn','record_stack_end_cap/record_stack_end_cap.tscn','archive_record_small/archive_record_small.tscn','archive_record_medium/archive_record_medium.glb','archive_record_large/archive_record_large.tscn','timeline_rail_housing/review_rig.tscn']
text='[gd_scene load_steps=7 format=3]\n'
for i,path in enumerate(paths):
    text+=f'[ext_resource type="PackedScene" path="res://assets/{path}" id="{i+1}"]\n'
text+='[node name="RecordStackReview" type="Node3D"]\n'
for i,x in enumerate([-1.6,0,1.6]):
    text+=f'[node name="Bay{i}" parent="." instance=ExtResource("1")]\nposition = Vector3({x},0,0)\n'
for side,x,rot in [('Left',-2.4,180),('Right',2.4,0)]:
    text+=f'[node name="Cap{side}" parent="." instance=ExtResource("2")]\nposition = Vector3({x},0,0)\nrotation_degrees = Vector3(0,{rot},0)\n'
for bay in range(3):
    for shelf,y in enumerate([.16,.72,1.28,1.84]):
        for slot in range(9):
            size=slot%3
            # Cassette fronts aligned at z ~= .193, all sizes independently instanced.
            depth=[.22,.27,.32][size]
            z=.19-depth/2
            x=-1.6+bay*1.6-.60+slot*.15
            text+=f'[node name="Record_{bay}_{shelf}_{slot}" parent="." instance=ExtResource("{3+size}")]\nposition = Vector3({x:.4f},{y},{z:.4f})\n'
text+='[node name="ReviewRig" parent="." instance=ExtResource("6")]\n'
(P/'review_assembly.tscn').write_text(text)
# Review medium is intentionally staged; match the existing cassette review isolation.
(P/'.gdignore').touch()

# Ready-to-place assemblies contain object instances only; studio stays separate.
def scene(root, resources, instances):
    text = f'[gd_scene load_steps={len(resources)+1} format=3]\n'
    for key, path in resources.items():
        text += f'[ext_resource type="PackedScene" path="res://assets/{path}" id="{key}"]\n'
    text += f'[node name="{root}" type="Node3D"]\n'
    for name, key, pos, yaw in instances:
        pos = ','.join(str(float(value)) for value in pos.split(','))
        text += f'[node name="{name}" parent="." instance=ExtResource("{key}")]\nposition = Vector3({pos})\nrotation_degrees = Vector3(0,{yaw},0)\n'
    return text

bay_path = 'record_stack_shelf_bay/illuminated_shelf_bay.tscn'
cap_path = 'record_stack_end_cap/record_stack_end_cap.tscn'
lights = [('Bay', 'bay', '0,0,0', 0)]
lights += [(f'Light{i}', 'light', f'0,{top-.028:.3f},.175', 0) for i,top in enumerate([.72,1.28,1.84,2.4])]
(P.parent/bay_path).write_text(scene('IlluminatedShelfBay', {
    'bay':'record_stack_shelf_bay/record_stack_shelf_bay.tscn',
    'light':'shelf_light_channel/shelf_light_channel.tscn'}, lights))
row = [(f'Bay{i}', 'bay', f'{x},0,0', 0) for i,x in enumerate([-1.6,0,1.6])]
row += [('CapLeft','cap','-2.4,0,0',180),('CapRight','cap','2.4,0,0',0)]
(P.parent/'record_stack_end_cap/capped_shelf_row.tscn').write_text(scene('CappedShelfRow', {'bay':bay_path,'cap':cap_path},row))
alcove = [('Corner','corner','0,0,0',0),('EntryBay','bay','1.02,0,-.8',-90),
          ('ExitBay','bay','-.8,0,1.02',180),('EntryCap','cap','1.02,0,-1.6',90),('ExitCap','cap','-1.6,0,1.02',180)]
(P.parent/'record_stack_end_cap/capped_shelf_alcove.tscn').write_text(scene('CappedShelfAlcove', {
    'bay':bay_path,'cap':cap_path,'corner':'record_stack_corner/record_stack_corner.tscn'},alcove))
# Keep cassettes independent of the furnishing; review the production row itself.
review = scene('RecordStackReview', {'row':'record_stack_end_cap/capped_shelf_row.tscn',
    '3':paths[2],'4':paths[3],'5':paths[4],'rig':paths[5]}, [('Row','row','0,0,0',0)])
record_start = text.index('[node name="Record_')
record_end = text.index('[node name="ReviewRig"')
review += text[record_start:record_end]
review += '[node name="ReviewRig" parent="." instance=ExtResource("rig")]\n'
(P/'review_assembly.tscn').write_text(review)


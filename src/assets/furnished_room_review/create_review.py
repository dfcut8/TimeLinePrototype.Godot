"""Compose optional placement studies without changing source models or the base room."""
from math import cos, sin, radians
from pathlib import Path

OUT = Path(__file__).resolve().parent


def scene(filename, root, resources, nodes):
    lines = [f'[gd_scene load_steps={len(resources)+1} format=3]']
    for i, asset in enumerate(resources, 1):
        lines.append(f'[ext_resource type="PackedScene" path="res://assets/{asset}.tscn" id="{i}"]')
    lines.append(f'[node name="{root}" type="Node3D"]')
    lines.extend(nodes)
    (OUT / filename).write_text('\n\n'.join(lines) + '\n', encoding='utf-8')


def instance(name, resource, position=(0, 0, 0), yaw=0):
    return (f'[node name="{name}" parent="." instance=ExtResource("{resource}")]\n'
            f'position = Vector3({position[0]:.9f}, {position[1]:.9f}, {position[2]:.9f})\n'
            f'rotation_degrees = Vector3(0, {yaw}, 0)')


scene('shelf_end_pair.tscn', 'ShelfEndPair', ['record_stack_end_cap/record_stack_end_cap'], [
    instance('Left', 1, (-.8, 0, 0), 180), instance('Right', 1, (.8, 0, 0))])
scene('cassette_display.tscn', 'CassetteDisplay', [
    'archive_display_plinth/archive_display_plinth', 'archive_record_large/archive_record_large'], [
    instance('Plinth', 1), instance('Record', 2, (0, .6, 0))])
scene('reading_station.tscn', 'ReadingStation', [
    'reading_bench/reading_bench', 'catalog_lectern/catalog_lectern',
    'furnished_room_review/cassette_display'], [
    instance('Bench', 1, (-1.3, 0, 0)), instance('Lectern', 2, (.4, 0, 0)),
    instance('Display', 3, (1.7, 0, 0))])
nodes = [instance('BaseRoom', 1)]
for j, index in enumerate((2, 4, 8, 10, 14, 16, 20, 22)):
    a = radians(index * 15)
    nodes.append(instance(f'Caps{j}', 2, (23*sin(a), 0, -23*cos(a)), -index*15))
for j, angle in enumerate((45, 135, 225, 315)):
    a = radians(angle)
    nodes.append(instance(f'Station{j}', 3, (22.4*sin(a), 0, -22.4*cos(a)), -angle))
scene('furnished_room.tscn', 'FurnishedRoom', [
    'library_room_review/library_room_assembly', 'furnished_room_review/shelf_end_pair',
    'furnished_room_review/reading_station'], nodes)
scene('review_room.tscn', 'FurnishedRoomReview', [
    'furnished_room_review/furnished_room', 'library_room_review/room_review_rig'], [
    instance('Room', 1), instance('ReviewRig', 2)])

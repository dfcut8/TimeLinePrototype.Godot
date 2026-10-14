@tool
extends Node3D
## Existing unscaled bays on the resolved 24.8 m / 15 degree pier grid.
## The root is the room centre at floor level; +Z is inward at angle zero.

const BAY_SCENES: Array[PackedScene] = [
	preload("res://assets/wall_infill_bay/wall_infill_bay.tscn"),
	preload("res://assets/passage_portal_bay_frame/passage_portal_bay_frame.tscn"),
	preload("res://assets/window_bay_frame/window_bay_frame.tscn"),
]
const PIER: PackedScene = preload("res://assets/structural_pier_a/structural_pier_a.tscn")
const PIER_RADIUS: float = 24.8
const PITCH_DEGREES: float = 15.0

var _layout := PackedInt32Array([0, 1, 2])

## Clockwise from -Z: 0 = solid wall, 1 = portal, 2 = window. One to 24 bays.
## Reassign the array to apply edits; getters return a copy.
@export var bay_layout: PackedInt32Array = PackedInt32Array([0, 1, 2]):
	get:
		return _layout.duplicate()
	set(value):
		_layout = value.slice(0, 24)
		if _layout.is_empty():
			_layout.append(0)
		for index in range(_layout.size()):
			_layout[index] = clampi(_layout[index], 0, BAY_SCENES.size() - 1)
		if is_node_ready():
			_rebuild()

@export_range(-180.0, 180.0, 0.5, "degrees") var start_angle_degrees: float = -15.0:
	set(value):
		start_angle_degrees = clampf(value, -180.0, 180.0)
		if is_node_ready():
			_rebuild()

var _generated: Array[Node3D] = []

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for object in _generated:
		if is_instance_valid(object):
			if object.get_parent() != null:
				object.get_parent().remove_child(object)
			object.queue_free()
	_generated.clear()
	var chord_radius := PIER_RADIUS * cos(deg_to_rad(PITCH_DEGREES * 0.5))
	for index in range(_layout.size()):
		_place(BAY_SCENES[_layout[index]], $Bays, "Bay%d" % index,
			start_angle_degrees + index * PITCH_DEGREES, chord_radius)
	# A complete ring shares its last/first pier; open sectors need two ends.
	var pier_count := _layout.size() if _layout.size() == 24 else _layout.size() + 1
	for index in range(pier_count):
		_place(PIER, $Piers, "Pier%d" % index,
			start_angle_degrees + (index - 0.5) * PITCH_DEGREES, PIER_RADIUS)

func _place(scene: PackedScene, container: Node3D, object_name: String,
		angle_degrees: float, radius: float) -> void:
	var object := scene.instantiate() as Node3D
	var angle := deg_to_rad(angle_degrees)
	object.name = object_name
	object.position = Vector3(radius * sin(angle), 0.0, -radius * cos(angle))
	object.rotation.y = -angle
	container.add_child(object)
	# Configuration is serialized, generated scene instances are recreated on load.
	_generated.append(object)

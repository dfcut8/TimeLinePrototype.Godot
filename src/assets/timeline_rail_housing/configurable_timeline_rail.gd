@tool
extends Node3D
## Repeats existing object scenes on their two-metre attachment pitch.

const MODULE: PackedScene = preload("res://assets/rail_module_joiner/illuminated_rail_module.tscn")
const JOINER: PackedScene = preload("res://assets/rail_module_joiner/rail_module_joiner.tscn")
const PITCH: float = 2.0

@export_range(1, 64, 1) var module_count: int = 3:
	set(value):
		module_count = clampi(value, 1, 64)
		if is_node_ready():
			_rebuild()

var _generated: Array[Node3D] = []

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Only remove our own generated instances; preserve user-added children.
	for instance in _generated:
		if is_instance_valid(instance):
			instance.get_parent().remove_child(instance)
			instance.queue_free()
	_generated.clear()
	for index in range(module_count):
		_add_part(MODULE, $Modules, "Module%d" % index, index * PITCH)
		if index > 0:
			_add_part(JOINER, $Joiners, "Joiner%d" % index, index * PITCH)
	$EndCap.position.x = module_count * PITCH
	$LaterEnd.position.x = module_count * PITCH

func _add_part(scene: PackedScene, parent: Node3D, label: String, x: float) -> void:
	var instance := scene.instantiate() as Node3D
	instance.name = label
	instance.position.x = x
	parent.add_child(instance)
	_generated.append(instance)
	# Generated instances deliberately have no owner: the saved scene stores
	# module_count, and reconstructs its preview without serialized duplicates.

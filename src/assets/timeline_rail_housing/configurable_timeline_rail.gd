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

## Earlier end preserves the original pivot; Centre keeps length edits symmetric.
@export_enum("Earlier end", "Centre") var anchor_mode: int = 0:
	set(value):
		anchor_mode = clampi(value, 0, 1)
		if is_node_ready():
			_sync_anchor()

var _generated: Array[Node3D] = []

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Only remove our own generated instances; preserve user-added children.
	for instance in _generated:
		if is_instance_valid(instance):
			if instance.get_parent() != null:
				instance.get_parent().remove_child(instance)
			instance.queue_free()
	_generated.clear()
	for index in range(module_count):
		_add_part(MODULE, $Modules, "Module%d" % index, index * PITCH)
		if index > 0:
			_add_part(JOINER, $Joiners, "Joiner%d" % index, index * PITCH)
	_sync_anchor()

func _sync_anchor() -> void:
	var offset: float = -module_count * PITCH * 0.5 if anchor_mode == 1 else 0.0
	$Modules.position.x = offset
	$Joiners.position.x = offset
	$StartCap.position.x = offset
	$EarlierEnd.position.x = offset
	$EndCap.position.x = offset + module_count * PITCH
	$LaterEnd.position.x = offset + module_count * PITCH

func _add_part(scene: PackedScene, parent: Node3D, label: String, x: float) -> void:
	var instance := scene.instantiate() as Node3D
	instance.name = label
	instance.position.x = x
	parent.add_child(instance)
	_generated.append(instance)
	# Generated instances deliberately have no owner: the saved scene stores
	# module_count, and reconstructs its preview without serialized duplicates.

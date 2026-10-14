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
			_rebuild()

var _modules: Array[Node3D] = []
var _joiners: Array[Node3D] = []

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var offset: float = -module_count * PITCH * 0.5 if anchor_mode == 1 else 0.0
	_sync_parts(_modules, MODULE, $Modules, "Module", module_count, 0, offset)
	_sync_parts(_joiners, JOINER, $Joiners, "Joiner", module_count - 1, 1, offset)
	$StartCap.position.x = offset
	$EarlierEnd.position.x = offset
	$EndCap.position.x = offset + module_count * PITCH
	$LaterEnd.position.x = offset + module_count * PITCH

func _sync_parts(parts: Array[Node3D], scene: PackedScene, container: Node3D,
		prefix: String, count: int, first_index: int, offset: float) -> void:
	# Slot indices retain their objects; only trailing or deleted parts are replaced.
	while parts.size() > count:
		_release(parts.pop_back())
	for slot in range(count):
		if slot == parts.size():
			parts.append(null)
		var part: Node3D = parts[slot] if is_instance_valid(parts[slot]) else null
		if is_instance_valid(part) and part.is_queued_for_deletion():
			_release(part)
			part = null
		if not is_instance_valid(part):
			part = scene.instantiate() as Node3D
			part.name = prefix + str(slot + first_index)
			container.add_child(part)
			# Save configuration and reconstruct exactly one population on load.
			part.owner = null
			parts[slot] = part
		elif part.get_parent() != container:
			if part.get_parent() != null:
				part.get_parent().remove_child(part)
			container.add_child(part)
		# Placement belongs to the rail, even when its containers are transformed.
		part.transform = container.transform.affine_inverse() * Transform3D(
			Basis.IDENTITY, Vector3(offset + (slot + first_index) * PITCH, 0, 0))

func _release(part: Variant) -> void:
	if is_instance_valid(part):
		if part.get_parent() != null:
			part.get_parent().remove_child(part)
		part.queue_free()

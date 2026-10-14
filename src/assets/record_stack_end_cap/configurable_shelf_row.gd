@tool
extends Node3D
## Centred row of reusable illuminated bays with reversible end caps.

const BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/illuminated_shelf_bay.tscn")
const PITCH: float = 1.6

## Bay variants must retain the 1.6 x 2.4 x 0.44 m shelf interface.
@export var bay_scene: PackedScene = BAY:
	set(value):
		bay_scene = value if value != null else BAY
		if is_node_ready():
			_rebuild()

@export_range(1, 32, 1) var bay_count: int = 3:
	set(value):
		bay_count = clampi(value, 1, 32)
		if is_node_ready():
			_rebuild()

var _generated: Array[Node3D] = []
var _active_bay_scene: PackedScene

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# A template change replaces bays; a count edit retains the shared prefix.
	if _active_bay_scene != bay_scene:
		_trim(0)
		_active_bay_scene = bay_scene
	_trim(bay_count)
	var container := $Bays as Node3D
	for index in range(bay_count):
		if index == _generated.size():
			_generated.append(null)
		var bay: Node3D = _generated[index] if is_instance_valid(_generated[index]) else null
		if is_instance_valid(bay) and bay.is_queued_for_deletion():
			_release(bay)
			bay = null
		if not is_instance_valid(bay):
			bay = bay_scene.instantiate() as Node3D
			bay.name = "Bay%d" % index
			container.add_child(bay)
			bay.owner = null
			_generated[index] = bay
		bay.transform = container.transform.affine_inverse() * Transform3D(
			Basis.IDENTITY, Vector3((index - (bay_count - 1) * 0.5) * PITCH, 0, 0))
	var half_width := bay_count * PITCH * 0.5
	$CapLeft.position.x = -half_width
	$CapRight.position.x = half_width
	$LeftJoin.position.x = -half_width
	$RightJoin.position.x = half_width

func _release(bay: Variant) -> void:
	if is_instance_valid(bay):
		if bay.get_parent() != null:
			bay.get_parent().remove_child(bay)
		bay.queue_free()

func _trim(count: int) -> void:
	while _generated.size() > count:
		_release(_generated.pop_back())

@tool
extends Node3D
## Centred row of reusable illuminated bays with reversible end caps.

const BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/illuminated_shelf_bay.tscn")
const PITCH: float = 1.6

@export_range(1, 32, 1) var bay_count: int = 3:
	set(value):
		bay_count = clampi(value, 1, 32)
		if is_node_ready():
			_rebuild()

var _generated: Array[Node3D] = []

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for bay in _generated:
		if is_instance_valid(bay):
			if bay.get_parent() != null:
				bay.get_parent().remove_child(bay)
			bay.queue_free()
	_generated.clear()
	for index in range(bay_count):
		var bay := BAY.instantiate() as Node3D
		bay.name = "Bay%d" % index
		bay.position.x = (index - (bay_count - 1) * 0.5) * PITCH
		$Bays.add_child(bay)
		_generated.append(bay)
		# Owner stays null: save the count, then rebuild without duplicates on load.
	var half_width := bay_count * PITCH * 0.5
	$CapLeft.position.x = -half_width
	$CapRight.position.x = half_width
	$LeftJoin.position.x = -half_width
	$RightJoin.position.x = half_width

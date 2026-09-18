@tool
extends Node3D
## Metres from socket terminal to the future rear-pivot terminal.
## Stretch only the straight shaft: root scaling would distort fittings/bevels.

@export_range(0.12, 2.0, 0.01, "suffix:m") var length_m: float = 0.45:
	set(value):
		length_m = clampf(value, 0.12, 2.0)
		if is_node_ready():
			_update_length()

func _ready() -> void:
	_update_length()

func _update_length() -> void:
	var shaft := $Model.find_child("ConnectorShaft*", true, false) as MeshInstance3D
	var tip := $Model.find_child("ConnectorTip*", true, false) as MeshInstance3D
	if shaft == null or tip == null:
		push_error("Connector arm GLB is missing its shaft or tip")
		return
	shaft.position.y = 0.028
	shaft.scale.y = (length_m - 0.056) / 0.394
	tip.position.y = length_m
	$PivotAttachment.position.y = length_m

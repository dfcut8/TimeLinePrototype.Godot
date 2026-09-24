@tool
extends Node3D
## Static articulation controls. Camera tracking belongs to a separate system.

@export_range(-60.0, 60.0, 1.0) var yaw_degrees: float = 0.0:
	set(value):
		yaw_degrees = clampf(value, -60.0, 60.0)
		apply_pose()

@export_range(-20.0, 20.0, 1.0) var pitch_degrees: float = 0.0:
	set(value):
		pitch_degrees = clampf(value, -20.0, 20.0)
		apply_pose()

func _ready() -> void:
	apply_pose()

func apply_pose() -> void:
	var yaw := get_node_or_null("Model/Yaw") as Node3D
	var pitch := get_node_or_null("Model/Yaw/Pitch") as Node3D
	if yaw != null and pitch != null:
		yaw.rotation.y = deg_to_rad(yaw_degrees)
		pitch.rotation.x = deg_to_rad(pitch_degrees)

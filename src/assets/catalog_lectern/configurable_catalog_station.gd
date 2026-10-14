@tool
extends Node3D
## Floor-centred catalog furniture; all visual objects remain scene instances.

@export var left_show_cassette: bool = true:
	set(value):
		left_show_cassette = value
		_update_display(^"DisplayLeft", &"show_cassette", left_show_cassette)

@export var right_show_cassette: bool = true:
	set(value):
		right_show_cassette = value
		_update_display(^"DisplayRight", &"show_cassette", right_show_cassette)

@export_range(0.75, 1.25, 0.01, "suffix:m") var display_spacing: float = 0.9:
	set(value):
		display_spacing = clampf(value, 0.75, 1.25)
		_refresh_if_ready()

@export_range(0.6, 1.0, 0.01, "suffix:m") var lectern_offset: float = 0.8:
	set(value):
		lectern_offset = clampf(value, 0.6, 1.0)
		_refresh_if_ready()

@export_range(0.8, 1.5, 0.01, "suffix:m") var approach_depth: float = 1.0:
	set(value):
		approach_depth = clampf(value, 0.8, 1.5)
		_refresh_if_ready()

@export_enum("Small", "Medium", "Large") var left_cassette_size: int = 0:
	set(value):
		left_cassette_size = clampi(value, 0, 2)
		_update_display(^"DisplayLeft", &"cassette_size", left_cassette_size)

@export_enum("Small", "Medium", "Large") var right_cassette_size: int = 2:
	set(value):
		right_cassette_size = clampi(value, 0, 2)
		_update_display(^"DisplayRight", &"cassette_size", right_cassette_size)

@export_range(-180.0, 180.0, 1.0, "degrees") var left_cassette_yaw: float = -30.0:
	set(value):
		left_cassette_yaw = clampf(value, -180.0, 180.0)
		_update_display(^"DisplayLeft", &"cassette_yaw_degrees", left_cassette_yaw)

@export_range(-180.0, 180.0, 1.0, "degrees") var right_cassette_yaw: float = 30.0:
	set(value):
		right_cassette_yaw = clampf(value, -180.0, 180.0)
		_update_display(^"DisplayRight", &"cassette_yaw_degrees", right_cassette_yaw)

func _ready() -> void:
	_sync_layout()
	_configure_display($DisplayLeft, left_cassette_size, left_cassette_yaw, left_show_cassette)
	_configure_display($DisplayRight, right_cassette_size, right_cassette_yaw, right_show_cassette)

func _refresh_if_ready() -> void:
	if is_node_ready():
		_sync_layout()

func _update_display(path: NodePath, property: StringName, value: Variant) -> void:
	# Each control owns one property, so unrelated edits retain local overrides.
	if is_node_ready():
		get_node(path).set(property, value)

func _configure_display(display: Node3D, size: int, yaw: float, populated: bool) -> void:
	if not populated:
		display.set("show_cassette", false)
	display.set("cassette_size", size)
	display.set("cassette_yaw_degrees", yaw)
	if populated:
		display.set("show_cassette", true)

func get_approach_bounds() -> AABB:
	# 19 mm beyond the imported lectern's frontmost surface at unit scale.
	return AABB(Vector3(-display_spacing - 0.35, 0.0, lectern_offset + 0.255),
		Vector3(2.0 * (display_spacing + 0.35), 1.8, approach_depth))

func _sync_layout() -> void:
	$DisplayLeft.position = Vector3(-display_spacing, 0.0, -0.2)
	$DisplayRight.position = Vector3(display_spacing, 0.0, -0.2)
	$Lectern.position = Vector3(0.0, 0.0, lectern_offset)
	var approach := get_approach_bounds()
	$ApproachStart.position = Vector3(0.0, 0.0, approach.position.z)
	$ApproachEnd.position = Vector3(0.0, 0.0, approach.end.z)
	$UserApproach.position = Vector3(0.0, 0.0, approach.get_center().z)

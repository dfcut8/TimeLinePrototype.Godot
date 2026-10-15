extends Node3D

var azimuth: float = 0.0
var elevation: float = 0.12
var distance: float = 8.8
var target := Vector3(0, 1.8, 0)
var reduced_motion: bool = false
var held: bool = false
@onready var camera: Camera3D = $Camera3D

func _process(delta: float) -> void:
	var desired := target + Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * distance
	camera.position = desired if reduced_motion else camera.position.lerp(desired, 1.0 - exp(-delta * 12.0))
	if camera.position.distance_to(target) > 0.01:
		camera.look_at(target, Vector3.UP)

func orbit(horizontal: float, vertical: float = 0.0) -> void:
	if held:
		return
	azimuth = wrapf(azimuth + horizontal, -PI, PI)
	elevation = clampf(elevation + vertical, -0.04, 0.6)

func zoom(amount: float) -> void:
	distance = clampf(distance + amount, 5.0, 15.0)

func reset_view() -> void:
	azimuth = 0.0
	elevation = 0.12
	distance = 8.8

func snapshot() -> Dictionary:
	return {"azimuth": azimuth, "elevation": elevation, "distance": distance}

func restore(state: Dictionary) -> void:
	azimuth = state.azimuth
	elevation = state.elevation
	distance = state.distance

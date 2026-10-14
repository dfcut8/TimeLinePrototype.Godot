@tool
extends Node3D
## Catalog stations follow the existing bay grid and only occupy solid walls.

const STATION: PackedScene = preload("res://assets/catalog_lectern/configurable_catalog_station.tscn")
const STATION_SETBACK: float = 2.3
var _layout := PackedInt32Array([0, 1, 0])
var _requested := PackedInt32Array([0, 2])
var _stations: Dictionary = {}

@export var bay_layout: PackedInt32Array = PackedInt32Array([0, 1, 0]):
	get:
		return _layout.duplicate()
	set(value):
		_layout = value.slice(0, 24)
		if _layout.is_empty():
			_layout.append(0)
		for index in range(_layout.size()):
			_layout[index] = clampi(_layout[index], 0, 2)
		_refresh_if_ready()

## Bay indices to furnish. Portal/window requests stay dormant until made walls.
## Invalid indices and duplicates are removed; reassign arrays to apply edits.
@export var station_bays: PackedInt32Array = PackedInt32Array([0, 2]):
	get:
		return _requested.duplicate()
	set(value):
		_requested.clear()
		for index in value:
			if index >= 0 and index < 24 and not _requested.has(index):
				_requested.append(index)
		_requested.sort()
		_refresh_if_ready()

@export_range(-180.0, 180.0, 0.5, "degrees") var start_angle_degrees: float = -15.0:
	set(value):
		start_angle_degrees = clampf(value, -180.0, 180.0)
		_refresh_if_ready()

var active_station_bays: PackedInt32Array:
	get:
		var active := PackedInt32Array()
		for index in _requested:
			if index < _layout.size() and _layout[index] == 0:
				active.append(index)
		return active

func _ready() -> void:
	_sync()

func _refresh_if_ready() -> void:
	if is_node_ready():
		_sync()

func _sync() -> void:
	var architecture := $Architecture as Node3D
	if architecture.get("bay_layout") != _layout:
		architecture.set("bay_layout", _layout)
	if not is_equal_approx(float(architecture.get("start_angle_degrees")), start_angle_degrees):
		architecture.set("start_angle_degrees", start_angle_degrees)
	var active := active_station_bays
	for index in _stations.keys():
		if not active.has(index):
			var station := _stations[index] as Node3D
			if is_instance_valid(station):
				station.get_parent().remove_child(station)
				station.queue_free()
			_stations.erase(index)
	for index in active:
		var station := _stations.get(index) as Node3D
		if not is_instance_valid(station):
			station = STATION.instantiate() as Node3D
			station.name = "Station%d" % index
			$Stations.add_child(station)
			# Persist root configuration, not generated furniture or cassettes.
			station.owner = null
			_stations[index] = station
		var bay := architecture.get_node("Bays/Bay%d" % index) as Node3D
		station.transform = $Stations.transform.affine_inverse() * architecture.transform \
			* ($Architecture/Bays as Node3D).transform * bay.transform \
			* Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, STATION_SETBACK))

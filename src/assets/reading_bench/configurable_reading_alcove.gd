@tool
extends Node3D
## A capped shelf row and bench with a clamped clear aisle between them.

const PACKED_BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/packed_cassette_shelf_bay.tscn")
const POPULATION = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.gd")

var _pattern := PackedInt32Array([0, 1, 2])

## Four bays cap the alcove's width for the documented perimeter placement.
@export_range(1, 4, 1) var bay_count: int = 2:
	set(value):
		bay_count = clampi(value, 1, 4)
		if is_node_ready():
			_sync_row()

@export_range(1.2, 2.0, 0.01, "suffix:m") var aisle_width: float = 1.54:
	set(value):
		aisle_width = clampf(value, 1.2, 2.0)
		if is_node_ready():
			_sync_bench()

@export var cassette_pattern: PackedInt32Array = PackedInt32Array([0, 1, 2]):
	get:
		return _pattern.duplicate()
	set(value):
		_pattern = POPULATION.normalise_pattern(value)
		if is_node_ready():
			_sync_population()

@export_range(0, 32, 1) var requested_records_per_shelf: int = 32:
	set(value):
		requested_records_per_shelf = clampi(value, 0, 32)
		if is_node_ready():
			_sync_population()

@export_range(0.02, 0.15, 0.001, "suffix:m") var record_gap: float = 0.02:
	set(value):
		record_gap = clampf(value, 0.02, 0.15)
		if is_node_ready():
			_sync_population()

func _ready() -> void:
	_sync_row()

func _sync_row() -> void:
	var row := $ShelfRow as Node3D
	if row.get("bay_count") != bay_count:
		row.set("bay_count", bay_count)
	_sync_population()
	_sync_bench()

func _sync_population() -> void:
	for bay in $ShelfRow/Bays.get_children():
		if bay.scene_file_path == PACKED_BAY.resource_path:
			if bay.get("cassette_pattern") != _pattern:
				bay.set("cassette_pattern", _pattern)
			if bay.get("requested_records_per_shelf") != requested_records_per_shelf:
				bay.set("requested_records_per_shelf", requested_records_per_shelf)
			if bay.get("record_gap") != record_gap:
				bay.set("record_gap", record_gap)

func _sync_bench() -> void:
	# The floor, facing direction and clear aisle are defined in the row's frame.
	var row := $ShelfRow as Node3D
	$Bench.transform = row.transform * Transform3D(Basis.IDENTITY,
		Vector3(0, 0, 0.22 + aisle_width + 0.24))
	$AisleCentre.transform = row.transform * Transform3D(Basis.IDENTITY,
		Vector3(0, 0, 0.22 + aisle_width * 0.5))

@tool
extends "res://assets/record_stack_end_cap/configurable_shelf_row.gd"
## The capped row's existing count/seam behavior with configurable population.

const POPULATION = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.gd")

var _pattern := PackedInt32Array([0, 1, 2])

@export var cassette_pattern: PackedInt32Array = PackedInt32Array([0, 1, 2]):
	get:
		return _pattern.duplicate()
	set(value):
		_pattern = POPULATION.normalise_pattern(value)
		if is_node_ready():
			_sync_population()

@export_range(0, 9, 1) var records_per_shelf: int = 9:
	set(value):
		records_per_shelf = clampi(value, 0, 9)
		if is_node_ready():
			_sync_population()

func _rebuild() -> void:
	super._rebuild()
	_sync_population()

func _sync_population() -> void:
	for bay in _generated:
		# The base row also permits a custom or empty bay_scene.
		if bay.get_script() == POPULATION:
			bay.set("cassette_pattern", _pattern)
			bay.set("records_per_shelf", records_per_shelf)

@tool
extends Node3D
## Centres a size-aware sequence inside the existing shelf's clear width.

const POPULATION = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.gd")
# Include the cover index strokes extending beyond the nominal chassis width.
const WIDTHS: Array[float] = [0.0666, 0.0866, 0.1066]
const USABLE_WIDTH: float = 1.44

var _pattern := PackedInt32Array([0, 1, 2])
var _generated: Array[Node3D] = []

@export var cassette_pattern: PackedInt32Array = PackedInt32Array([0, 1, 2]):
	get:
		return _pattern.duplicate()
	set(value):
		_pattern = POPULATION.normalise_pattern(value)
		if is_node_ready():
			_rebuild_records()

## Overflow is truncated to the longest ordered prefix that fits every deck.
@export_range(0, 32, 1) var requested_records_per_shelf: int = 32:
	set(value):
		requested_records_per_shelf = clampi(value, 0, 32)
		if is_node_ready():
			_rebuild_records()

@export_range(0.02, 0.15, 0.001, "suffix:m") var record_gap: float = 0.02:
	set(value):
		record_gap = clampf(value, 0.02, 0.15)
		if is_node_ready():
			_rebuild_records()

var effective_records_per_shelf: int:
	get:
		return _layout().size()

func _ready() -> void:
	_rebuild_records()

func _layout() -> PackedFloat32Array:
	var centres := PackedFloat32Array()
	var span: float = 0.0
	for slot in range(requested_records_per_shelf):
		var width: float = WIDTHS[_pattern[slot % _pattern.size()]]
		var gap: float = record_gap if slot > 0 else 0.0
		if span + gap + width > USABLE_WIDTH:
			break
		centres.append(span + gap + width * 0.5)
		span += gap + width
	for slot in range(centres.size()):
		centres[slot] -= span * 0.5
	return centres

func _rebuild_records() -> void:
	for record in _generated:
		if is_instance_valid(record):
			if record.get_parent() != null:
				record.get_parent().remove_child(record)
			record.queue_free()
	_generated.clear()
	var centres := _layout()
	for tier in range(4):
		for slot in range(centres.size()):
			var size: int = _pattern[slot % _pattern.size()]
			var record := POPULATION.RECORDS[size].instantiate() as Node3D
			record.name = "Record_%d_%d" % [tier, slot]
			record.position = Vector3(centres[slot], 0.16 + tier * 0.56,
				POPULATION.FRONT_OFFSETS[size])
			$Records.add_child(record)
			_generated.append(record)
			# Generated scene instances have no owner; only configuration is saved.

@tool
extends Node3D
## Independent cassette scenes on all four decks of the existing lit shelf.

const SLOTS = preload("res://assets/record_stack_shelf_bay/cassette_slot_instances.gd")
const RECORDS: Array[PackedScene] = SLOTS.RECORDS
const FRONT_OFFSETS: Array[float] = SLOTS.FRONT_OFFSETS
const RECORD_PITCH: float = 0.15

var _pattern := PackedInt32Array([0, 1, 2])

## Repeating left-to-right on each shelf: 0 = small, 1 = medium, 2 = large.
## Reassign the array to apply edits; getters return a copy.
@export var cassette_pattern: PackedInt32Array = PackedInt32Array([0, 1, 2]):
	get:
		return _pattern.duplicate()
	set(value):
		_pattern = normalise_pattern(value)
		if is_node_ready():
			_rebuild_records()

## Zero leaves the shelf empty. Nine is the validated mixed-size capacity.
@export_range(0, 9, 1) var records_per_shelf: int = 9:
	set(value):
		records_per_shelf = clampi(value, 0, 9)
		if is_node_ready():
			_rebuild_records()

var _generated: Dictionary = {}

static func normalise_pattern(value: PackedInt32Array) -> PackedInt32Array:
	var pattern := value.slice(0, 9)
	if pattern.is_empty():
		pattern.append(0)
	for index in range(pattern.size()):
		pattern[index] = clampi(pattern[index], 0, RECORDS.size() - 1)
	return pattern

func _ready() -> void:
	_rebuild_records()

func _rebuild_records() -> void:
	var centres := PackedFloat32Array()
	for slot in range(records_per_shelf):
		centres.append((slot - (records_per_shelf - 1) * 0.5) * RECORD_PITCH)
	SLOTS.sync(_generated, $Records, _pattern, centres)

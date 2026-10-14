@tool
extends Node3D
## Independent cassette scenes on all four decks of the existing lit shelf.

const RECORDS: Array[PackedScene] = [
	preload("res://assets/archive_record_small/archive_record_small.tscn"),
	preload("res://assets/archive_record_medium/archive_record_medium.tscn"),
	preload("res://assets/archive_record_large/archive_record_large.tscn"),
]
const FRONT_OFFSETS: Array[float] = [0.080, 0.055, 0.030]
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

var _generated: Array[Node3D] = []

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
	for record in _generated:
		if is_instance_valid(record):
			if record.get_parent() != null:
				record.get_parent().remove_child(record)
			record.queue_free()
	_generated.clear()
	for tier in range(4):
		for slot in range(records_per_shelf):
			var size: int = _pattern[slot % _pattern.size()]
			var record := RECORDS[size].instantiate() as Node3D
			record.name = "Record_%d_%d" % [tier, slot]
			record.position = Vector3((slot - (records_per_shelf - 1) * 0.5) * RECORD_PITCH,
				0.16 + tier * 0.56, FRONT_OFFSETS[size])
			$Records.add_child(record)
			_generated.append(record)

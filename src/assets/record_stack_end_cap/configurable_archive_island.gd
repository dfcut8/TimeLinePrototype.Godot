@tool
extends Node3D
## Two capped rows face outward, with a clear gap between their closed backs.

const POPULATION = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.gd")
const PACKED_BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/packed_cassette_shelf_bay.tscn")
const BAY_WIDTH: float = 1.6
const ROW_DEPTH: float = 0.44
const CAP_WIDTH: float = 0.082

var _front_pattern := PackedInt32Array([0])
var _back_pattern := PackedInt32Array([2])

@export_range(1, 4, 1) var bay_count: int = 2:
	set(value):
		bay_count = clampi(value, 1, 4)
		if is_node_ready():
			_sync_rows()

## Measured separation of the two complete imported row envelopes, in metres.
@export_range(0.04, 0.3, 0.01, "suffix:m") var back_gap: float = 0.04:
	set(value):
		back_gap = clampf(value, 0.04, 0.3)
		if is_node_ready():
			_sync_placement()

## Layout envelopes only; these markers do not create navigation or collision.
@export_range(1.2, 2.0, 0.01, "suffix:m") var approach_depth: float = 1.2:
	set(value):
		approach_depth = clampf(value, 1.2, 2.0)
		if is_node_ready():
			_sync_placement()

@export_category("Front population")
@export var front_pattern: PackedInt32Array = PackedInt32Array([0]):
	get:
		return _front_pattern.duplicate()
	set(value):
		_front_pattern = POPULATION.normalise_pattern(value)
		if is_node_ready():
			_sync_population($FrontRow, _front_pattern, front_records_per_shelf, front_record_gap)

@export_range(0, 32, 1) var front_records_per_shelf: int = 32:
	set(value):
		front_records_per_shelf = clampi(value, 0, 32)
		if is_node_ready():
			_sync_population($FrontRow, _front_pattern, front_records_per_shelf, front_record_gap)

@export_range(0.02, 0.15, 0.001, "suffix:m") var front_record_gap: float = 0.02:
	set(value):
		front_record_gap = clampf(value, 0.02, 0.15)
		if is_node_ready():
			_sync_population($FrontRow, _front_pattern, front_records_per_shelf, front_record_gap)

@export_category("Back population")
@export var back_pattern: PackedInt32Array = PackedInt32Array([2]):
	get:
		return _back_pattern.duplicate()
	set(value):
		_back_pattern = POPULATION.normalise_pattern(value)
		if is_node_ready():
			_sync_population($BackRow, _back_pattern, back_records_per_shelf, back_record_gap)

@export_range(0, 32, 1) var back_records_per_shelf: int = 32:
	set(value):
		back_records_per_shelf = clampi(value, 0, 32)
		if is_node_ready():
			_sync_population($BackRow, _back_pattern, back_records_per_shelf, back_record_gap)

@export_range(0.02, 0.15, 0.001, "suffix:m") var back_record_gap: float = 0.02:
	set(value):
		back_record_gap = clampf(value, 0.02, 0.15)
		if is_node_ready():
			_sync_population($BackRow, _back_pattern, back_records_per_shelf, back_record_gap)

func _ready() -> void:
	_sync_rows()
	_sync_placement()

func get_body_bounds() -> AABB:
	var width: float = bay_count * BAY_WIDTH + CAP_WIDTH * 2.0
	var depth: float = ROW_DEPTH * 2.0 + back_gap
	return AABB(Vector3(-width * 0.5, 0.0, -depth * 0.5), Vector3(width, 2.4, depth))

func get_approach_bounds(front: bool = true) -> AABB:
	var body := get_body_bounds()
	var start: float = body.end.z if front else body.position.z - approach_depth
	return AABB(Vector3(body.position.x, 0.0, start), Vector3(body.size.x, 2.0, approach_depth))

func _sync_rows() -> void:
	for row in [$FrontRow, $BackRow]:
		if row.get("bay_count") != bay_count:
			row.set("bay_count", bay_count)
	_sync_population($FrontRow, _front_pattern, front_records_per_shelf, front_record_gap)
	_sync_population($BackRow, _back_pattern, back_records_per_shelf, back_record_gap)

func _sync_placement() -> void:
	var offset: float = (ROW_DEPTH + back_gap) * 0.5
	$FrontRow.position.z = offset
	$BackRow.position.z = -offset
	$FrontApproach.position = get_approach_bounds(true).get_center() * Vector3(1.0, 0.0, 1.0)
	$BackApproach.position = get_approach_bounds(false).get_center() * Vector3(1.0, 0.0, 1.0)

func _sync_population(row: Node3D, pattern: PackedInt32Array, request: int, gap: float) -> void:
	for bay in row.get_node("Bays").get_children():
		if bay.scene_file_path != PACKED_BAY.resource_path:
			continue
		if bay.get("cassette_pattern") != pattern:
			bay.set("cassette_pattern", pattern)
		if bay.get("requested_records_per_shelf") != request:
			bay.set("requested_records_per_shelf", request)
		if bay.get("record_gap") != gap:
			bay.set("record_gap", gap)

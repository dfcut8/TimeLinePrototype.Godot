@tool
extends Node3D
## A cassette PackedScene seated on the plinth's TopContact interface.

const RECORDS: Array[PackedScene] = [
	preload("res://assets/archive_record_small/archive_record_small.tscn"),
	preload("res://assets/archive_record_medium/archive_record_medium.tscn"),
	preload("res://assets/archive_record_large/archive_record_large.tscn"),
]

@export_enum("Small", "Medium", "Large") var cassette_size: int = 2:
	set(value):
		cassette_size = clampi(value, 0, RECORDS.size() - 1)
		if is_node_ready():
			_sync_record()

@export_range(-180.0, 180.0, 1.0, "degrees") var cassette_yaw_degrees: float = 0.0:
	set(value):
		cassette_yaw_degrees = clampf(value, -180.0, 180.0)
		if is_node_ready():
			_sync_record()

var _record: Node3D

func _ready() -> void:
	_sync_record()

func _sync_record() -> void:
	var scene := RECORDS[cassette_size]
	if is_instance_valid(_record) and _record.scene_file_path != scene.resource_path:
		_record.get_parent().remove_child(_record)
		_record.queue_free()
		_record = null
	if not is_instance_valid(_record):
		_record = scene.instantiate() as Node3D
		_record.name = "Cassette"
		$RecordSlot.add_child(_record)
		# Save configuration, not generated nodes; rebuild exactly once on load.
		_record.owner = null
	var plinth := $Plinth as Node3D
	var contact := $Plinth/TopContact as Marker3D
	var slot := $RecordSlot as Node3D
	_record.transform = slot.transform.affine_inverse() * plinth.transform * contact.transform \
		* Transform3D(Basis(Vector3.UP, deg_to_rad(cassette_yaw_degrees)), Vector3.ZERO)

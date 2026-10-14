@tool
extends RefCounted
## Retain cassette instances by deck/slot while their requested size is unchanged.

const RECORDS: Array[PackedScene] = [
	preload("res://assets/archive_record_small/archive_record_small.tscn"),
	preload("res://assets/archive_record_medium/archive_record_medium.tscn"),
	preload("res://assets/archive_record_large/archive_record_large.tscn"),
]
const FRONT_OFFSETS: Array[float] = [0.080, 0.055, 0.030]

static func release(record: Variant) -> void:
	if is_instance_valid(record):
		if record.get_parent() != null:
			record.get_parent().remove_child(record)
		record.queue_free()

static func sync(records: Dictionary, container: Node3D,
		pattern: PackedInt32Array, centres: PackedFloat32Array) -> void:
	for key: Vector2i in records.keys():
		if key.y >= centres.size():
			release(records[key])
			records.erase(key)
	for tier in range(4):
		for slot in range(centres.size()):
			var key := Vector2i(tier, slot)
			var size: int = pattern[slot % pattern.size()]
			var scene: PackedScene = RECORDS[size]
			# Check validity before casting: another script may have freed this slot.
			var candidate: Variant = records.get(key)
			var record: Node3D = candidate as Node3D if is_instance_valid(candidate) else null
			if is_instance_valid(record) and (record.is_queued_for_deletion()
					or record.scene_file_path != scene.resource_path):
				release(record)
				record = null
			if not is_instance_valid(record):
				record = scene.instantiate() as Node3D
				record.name = "Record_%d_%d" % [tier, slot]
				container.add_child(record)
				record.owner = null
				records[key] = record
			# Placement belongs to the bay, even when Records is transformed.
			record.transform = container.transform.affine_inverse() * Transform3D(
				Basis.IDENTITY, Vector3(centres[slot], 0.16 + tier * 0.56, FRONT_OFFSETS[size]))

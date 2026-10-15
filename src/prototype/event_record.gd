extends Node3D
## Presentation stays with this reusable record scene; JSON contains no transforms.
var event_index: int = 0
var event: Dictionary = {}
var lower: bool = false

func configure(item: Dictionary, index: int, same_date: bool) -> void:
	event = item
	event_index = index
	lower = index % 2 == 1
	var sign_y := -1.0 if lower else 1.0
	$Arm.position.y = sign_y * 0.068
	$Arm.rotation.z = PI if lower else 0.0
	$Pivot.position.y = sign_y * 0.668
	$Pivot.rotation.z = PI if lower else 0.0
	$Panel.position.y = sign_y * 0.808
	var kind := "VIDEO  >" if item.kind == "video_text" else "IMAGE  +"
	var date: String = _caption(item.date.label, 24) + (" · same date" if same_date else "")
	$Panel/Text.text = "%s\n%s\n%s" % [date, _caption(item.title, 40), kind]

func _caption(value: String, limit: int) -> String:
	var plain := value.replace("\n", " ").replace("\r", " ").strip_edges()
	return plain if plain.length() <= limit else plain.left(limit - 1) + "…"

func face_camera(camera: Camera3D) -> void:
	# Content is upright at all azimuths; the small mechanical joint retains its bounds.
	$Panel.global_basis = camera.global_basis.orthonormalized()

func set_emphasis(focused: bool, hovered: bool, selected: bool = false) -> void:
	$Panel/Focus.visible = focused or hovered or selected
	$Panel/Focus.modulate = Color("f0d7a1") if selected else (Color("68dae8") if focused else Color("b6c1d0"))
	$Panel/Text.modulate = Color.WHITE if focused or hovered else Color("c8d7de")

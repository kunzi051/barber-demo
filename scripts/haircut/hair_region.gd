extends ColorRect

class_name HairRegion

signal region_clicked(region_name: String)

@export var region_name: String = ""
@export var region_length: int = 3

var highlighted: bool = false
var original_color: Color = Color.WHITE


func _ready() -> void:
	original_color = color
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func set_length(val: int) -> void:
	region_length = clampi(val, 0, 3)
	_update_visual()


func _update_visual() -> void:
	match region_length:
		0:
			color = Color(0.9, 0.8, 0.7)
			custom_minimum_size = Vector2(20, 6)
		1:
			color = Color(0.5, 0.4, 0.35)
			custom_minimum_size = Vector2(30, 10)
		2:
			color = Color(0.35, 0.25, 0.2)
			custom_minimum_size = Vector2(40, 16)
		3:
			color = Color(0.2, 0.12, 0.08)
			custom_minimum_size = Vector2(50, 22)


func _on_mouse_entered() -> void:
	highlighted = true
	modulate = Color(1.0, 1.0, 0.8, 1.0)


func _on_mouse_exited() -> void:
	highlighted = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("region_clicked", region_name)

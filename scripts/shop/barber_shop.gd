extends Node2D

class_name BarberShop

@onready var barber: Node2D = $Barber
@onready var customer: Node2D = $Customer
@onready var talk_button: Button = $CanvasLayer/TalkButton
@onready var interaction_label: Label = $CanvasLayer/InteractLabel
@onready var dialogue_panel: Control = $CanvasLayer/DialoguePanel
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var shop_background: ColorRect = $ShopBackground
@onready var floor_area: ColorRect = $FloorArea
@onready var barber_chair: ColorRect = $BarberChair
@onready var mirror: ColorRect = $Mirror
@onready var counter: ColorRect = $Counter
@onready var entrance: ColorRect = $Entrance

const WALK_SPEED: float = 300.0
const INTERACT_DISTANCE: float = 80.0

var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO
var dialogue_active: bool = false
var dialogue_finished: bool = false


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 1)
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)
	
	barber.position = Vector2(200, 350)
	customer.position = Vector2(750, 250)
	
	talk_button.hide()
	interaction_label.hide()
	dialogue_panel.hide()
	
	if dialogue_panel.has_signal("dialogue_finished"):
		dialogue_panel.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
	
	_setup_shop_background()


func _setup_shop_background() -> void:
	shop_background.color = Color(0.95, 0.88, 0.75)
	floor_area.color = Color(0.55, 0.35, 0.2)
	barber_chair.color = Color(0.6, 0.2, 0.2)
	mirror.color = Color(0.8, 0.85, 0.9)
	mirror.modulate = Color(0.8, 0.85, 0.9, 0.5)
	counter.color = Color(0.7, 0.6, 0.4)
	entrance.color = Color(0.9, 0.8, 0.6)


func _process(delta: float) -> void:
	if dialogue_active or dialogue_finished:
		return
	
	_handle_input(delta)
	_update_movement(delta)
	_check_interaction()


func _handle_input(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	
	if input_dir != Vector2.ZERO:
		is_moving = true
		target_position = barber.position + input_dir * 200.0
		_clamp_barber_position()
	
	if Input.is_action_just_pressed("ui_accept"):
		var dist: float = barber.position.distance_to(customer.position)
		if dist < INTERACT_DISTANCE * 1.5 and not dialogue_finished:
			_start_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_active or dialogue_finished:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos: Vector2 = get_global_mouse_position()
		if click_pos.y > 200 and click_pos.y < 500 and click_pos.x > 50 and click_pos.x < 1230:
			target_position = Vector2(clampf(click_pos.x, 100, 1180), clampf(click_pos.y, 220, 480))
			is_moving = true


func _update_movement(delta: float) -> void:
	if not is_moving:
		return
	
	var dir: Vector2 = target_position - barber.position
	var dist: float = dir.length()
	
	if dist < 5.0:
		is_moving = false
		return
	
	dir = dir.normalized()
	barber.position += dir * WALK_SPEED * delta
	_clamp_barber_position()


func _clamp_barber_position() -> void:
	barber.position.x = clampf(barber.position.x, 100, 1180)
	barber.position.y = clampf(barber.position.y, 220, 480)
	target_position.x = clampf(target_position.x, 100, 1180)
	target_position.y = clampf(target_position.y, 220, 480)


func _check_interaction() -> void:
	var dist: float = barber.position.distance_to(customer.position)
	if dist < INTERACT_DISTANCE and not dialogue_finished:
		talk_button.show()
		interaction_label.show()
	else:
		talk_button.hide()
		interaction_label.hide()


func _on_talk_button_pressed() -> void:
	if dialogue_finished:
		_on_start_haircut_pressed()
		return
	_start_dialogue()


func _start_dialogue() -> void:
	dialogue_active = true
	talk_button.hide()
	interaction_label.hide()
	dialogue_panel.show()
	if dialogue_panel.has_method("start_dialogue"):
		var cust_data: Dictionary = GameState.get_current_customer_data()
		dialogue_panel.start_dialogue(cust_data)


func _on_dialogue_finished() -> void:
	dialogue_active = false
	dialogue_finished = true
	dialogue_panel.hide()
	show_go_to_haircut()


func show_go_to_haircut() -> void:
	interaction_label.text = "已了解客人需求，请前往理发椅准备"
	interaction_label.show()
	talk_button.text = "开始理发"
	talk_button.show()


func _on_start_haircut_pressed() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/haircut/haircut_scene.tscn")

extends Control

class_name DialogueController

@onready var customer_name_label: Label = $CustomerNameLabel
@onready var dialogue_text_label: Label = $DialogueTextLabel
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var portrait_rect: ColorRect = $PortraitRect

var dialogue_data: Dictionary = {}
var current_round_id: String = ""
var current_round_data: Dictionary = {}
var is_type_writing: bool = false
var full_text: String = ""
var type_speed: float = 0.03
var type_timer: float = 0.0
var type_index: int = 0
var text_revealed: bool = false
var waiting_for_next: bool = false
var dialogue_complete: bool = false

signal dialogue_finished


func _ready() -> void:
	portrait_rect.color = Color(0.9, 0.8, 0.7)
	customer_name_label.text = "李明"


func start_dialogue(customer_id: String) -> void:
	dialogue_data = JSONLoader.load_json("res://data/dialogues/" + customer_id + "_dialogue.json")
	if dialogue_data.is_empty():
		push_error("Failed to load dialogue data for: " + customer_id)
		emit_signal("dialogue_finished")
		return
	
	GameState.dialogue_understanding_score = 0
	GameState.customer_trust = 0
	GameState.revealed_hidden_need = false
	
	var rounds: Array = dialogue_data.get("rounds", [])
	if rounds.is_empty():
		push_error("No rounds found in dialogue data")
		emit_signal("dialogue_finished")
		return
	
	current_round_id = rounds[0].get("id", "")
	_show_round(current_round_id)


func _show_round(round_id: String) -> void:
	var rounds: Array = dialogue_data.get("rounds", [])
	var round_data: Dictionary = {}
	for r in rounds:
		if r.get("id") == round_id:
			round_data = r
			break
	
	if round_data.is_empty():
		_show_summary()
		return
	
	current_round_data = round_data
	text_revealed = false
	waiting_for_next = false
	
	full_text = round_data.get("text", "")
	dialogue_text_label.text = ""
	type_index = 0
	type_timer = 0.0
	is_type_writing = true
	
	_clear_options()
	
	await get_tree().process_frame


func _process(delta: float) -> void:
	if is_type_writing:
		type_timer += delta
		while type_timer >= type_speed and type_index < len(full_text):
			dialogue_text_label.text += full_text[type_index]
			type_index += 1
			type_timer -= type_speed
		
		if type_index >= len(full_text):
			is_type_writing = false
			text_revealed = true
			_show_options()


func _show_options() -> void:
	_clear_options()
	var options: Array = current_round_data.get("options", [])
	if options.is_empty():
		var next_id = current_round_data.get("next_round", "")
		if next_id:
			_show_round(next_id)
		else:
			_show_summary()
		return
	
	for opt in options:
		var btn: Button = Button.new()
		btn.text = opt.get("text", "")
		btn.custom_minimum_size = Vector2(400, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.connect("pressed", Callable(self, "_on_option_selected").bind(opt))
		options_container.add_child(btn)


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _on_option_selected(option: Dictionary) -> void:
	if not text_revealed:
		return
	
	var effects: Dictionary = option.get("effects", {})
	GameState.dialogue_understanding_score += effects.get("understanding", 0)
	GameState.customer_trust += effects.get("trust", 0)
	if effects.get("revealed_hidden_need", false):
		GameState.revealed_hidden_need = true
	
	var next_id = option.get("next_round", "")
	if next_id and not next_id.is_empty():
		_show_round(next_id)
	else:
		_show_summary()


func _show_summary() -> void:
	dialogue_complete = true
	dialogue_text_label.text = dialogue_data.get("summary", "我明白了你的需求。")
	_clear_options()
	
	var btn: Button = Button.new()
	btn.text = "开始理发"
	btn.custom_minimum_size = Vector2(300, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.connect("pressed", Callable(self, "_on_start_haircut"))
	options_container.add_child(btn)


func _on_start_haircut() -> void:
	emit_signal("dialogue_finished")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_type_writing:
			is_type_writing = false
			dialogue_text_label.text = full_text
			text_revealed = true
			_show_options()

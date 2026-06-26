extends Control

class_name DialogueController

enum DialogueState { TYPING, WAITING_FOR_CONTINUE, WAITING_FOR_CHOICE, FINISHED }

@onready var customer_name_label: Label = $CustomerNameLabel
@onready var dialogue_text_label: Label = $DialogueTextLabel
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var portrait_rect: ColorRect = $PortraitRect

var dialogue_data: Dictionary = {}
var current_round_id: String = ""
var current_round_data: Dictionary = {}
var state: int = DialogueState.FINISHED
var typing_tween: Tween = null
var full_text: String = ""
var input_locked: bool = false

signal dialogue_finished


func _ready() -> void:
	portrait_rect.color = Color(0.9, 0.8, 0.7)


func start_dialogue(customer_data: Dictionary) -> void:
	var dialogue_path: String = customer_data.get("dialogue_file", "")
	if dialogue_path.is_empty():
		dialogue_path = "res://data/dialogues/" + customer_data.get("id", "") + "_dialogue.json"
	
	dialogue_data = JSONLoader.load_json(dialogue_path)
	if dialogue_data.is_empty():
		push_error("Failed to load dialogue data for: " + customer_data.get("id", ""))
		emit_signal("dialogue_finished")
		return
	
	customer_name_label.text = customer_data.get("name", "客人")
	
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
	full_text = round_data.get("text", "")
	
	_clear_options()
	_start_typing(full_text)


func _start_typing(text: String) -> void:
	_stop_typing_tween()
	
	dialogue_text_label.text = text
	dialogue_text_label.visible_characters = 0
	state = DialogueState.TYPING
	input_locked = false
	
	typing_tween = create_tween()
	typing_tween.tween_property(dialogue_text_label, "visible_characters", -1, len(text) * 0.025)
	typing_tween.finished.connect(_on_typing_finished)


func _stop_typing_tween() -> void:
	if typing_tween != null and typing_tween.is_valid():
		typing_tween.kill()
	typing_tween = null


func _finish_current_line_immediately() -> void:
	_stop_typing_tween()
	dialogue_text_label.visible_characters = -1
	_on_typing_finished()


func _on_typing_finished() -> void:
	_stop_typing_tween()
	
	if state == DialogueState.FINISHED:
		return
	
	var options: Array = current_round_data.get("options", [])
	if options.is_empty():
		var next_id = current_round_data.get("next_round", "")
		if next_id and not next_id.is_empty():
			state = DialogueState.WAITING_FOR_CONTINUE
			input_locked = false
		else:
			_show_summary()
		return
	
	state = DialogueState.WAITING_FOR_CHOICE
	input_locked = false
	_show_options(options)


func _show_options(options: Array) -> void:
	_clear_options()
	for opt in options:
		var btn: Button = Button.new()
		btn.text = opt.get("text", "")
		btn.custom_minimum_size = Vector2(400, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.connect("pressed", Callable(self, "_on_option_selected").bind(opt))
		options_container.add_child(btn)
	
	await get_tree().create_timer(0.1).timeout
	for child in options_container.get_children():
		if child is Button:
			child.disabled = false


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _on_option_selected(option: Dictionary) -> void:
	if state != DialogueState.WAITING_FOR_CHOICE:
		return
	
	# Disable all buttons immediately to prevent double-click
	_set_options_disabled(true)
	
	var effects: Dictionary = option.get("effects", {})
	GameState.dialogue_understanding_score += effects.get("understanding", 0)
	GameState.customer_trust += effects.get("trust", 0)
	if effects.get("revealed_hidden_need", false):
		GameState.revealed_hidden_need = true
	
	_clear_options()
	
	var next_id = option.get("next_round", "")
	if next_id and not next_id.is_empty():
		_show_round(next_id)
	else:
		_show_summary()


func _set_options_disabled(disabled: bool) -> void:
	for child in options_container.get_children():
		if child is Button:
			child.disabled = disabled


func _show_summary() -> void:
	state = DialogueState.FINISHED
	dialogue_text_label.text = dialogue_data.get("summary", "我明白了你的需求。")
	dialogue_text_label.visible_characters = -1
	_clear_options()
	
	var btn: Button = Button.new()
	btn.text = "开始理发"
	btn.custom_minimum_size = Vector2(300, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.connect("pressed", Callable(self, "_on_start_haircut"))
	options_container.add_child(btn)
	
	await get_tree().create_timer(0.15).timeout
	btn.disabled = false


func _on_start_haircut() -> void:
	state = DialogueState.FINISHED
	emit_signal("dialogue_finished")


func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if input_locked:
		return
	if state == DialogueState.FINISHED:
		return
	
	accept_event()
	
	match state:
		DialogueState.TYPING:
			input_locked = true
			_finish_current_line_immediately()
		DialogueState.WAITING_FOR_CONTINUE:
			input_locked = true
			var next_id = current_round_data.get("next_round", "")
			if next_id and not next_id.is_empty():
				_show_round(next_id)
		DialogueState.WAITING_FOR_CHOICE:
			pass

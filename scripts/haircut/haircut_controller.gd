extends Control

class_name HaircutController

@onready var hair_bangs: HairRegion = $HairContainer/HairBangs
@onready var hair_top: HairRegion = $HairContainer/HairTop
@onready var hair_left: HairRegion = $HairContainer/HairLeft
@onready var hair_right: HairRegion = $HairContainer/HairRight
@onready var hair_back: HairRegion = $HairContainer/HairBack
@onready var tool_scissors: Button = $ToolScissors
@onready var tool_clipper: Button = $ToolClipper
@onready var tool_comb: Button = $ToolComb
@onready var undo_button: Button = $UndoButton
@onready var finish_button: Button = $FinishButton
@onready var feedback_label: Label = $FeedbackLabel
@onready var customer_name_label: Label = $CustomerNameLabel
@onready var need_hint_label: Label = $NeedHintLabel
@onready var comfort_indicator: ColorRect = $ComfortIndicator
@onready var confirm_panel: Control = $ConfirmPanel
@onready var confirm_yes: Button = $ConfirmPanel/ConfirmYes
@onready var confirm_no: Button = $ConfirmPanel/ConfirmNo
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer

var selected_tool: String = "scissors"
var history: Array = []
var max_history: int = 10
var clipper_mode: String = "short"
var timer: float = 0.0
var is_timing: bool = true


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 1)
	var tween_in: Tween = create_tween()
	tween_in.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)
	
	_connect_regions()
	_connect_tools()
	_restore_hair_visuals()
	_update_need_hint()
	_update_undo_button()
	confirm_panel.hide()
	customer_name_label.text = "客人：李明"
	
	hair_bangs.region_name = "bangs"
	hair_top.region_name = "top"
	hair_left.region_name = "left_side"
	hair_right.region_name = "right_side"
	hair_back.region_name = "back"
	
	_apply_initial_hair_positions()
	
	_save_state()


func _process(delta: float) -> void:
	if is_timing:
		timer += delta


func _apply_initial_hair_positions() -> void:
	var init_state: Dictionary = GameState.current_hair_state
	hair_bangs.set_length(init_state.get("bangs", 3))
	hair_top.set_length(init_state.get("top", 3))
	hair_left.set_length(init_state.get("left_side", 3))
	hair_right.set_length(init_state.get("right_side", 3))
	hair_back.set_length(init_state.get("back", 3))


func _connect_regions() -> void:
	hair_bangs.connect("region_clicked", Callable(self, "_on_region_clicked").bind("bangs"))
	hair_top.connect("region_clicked", Callable(self, "_on_region_clicked").bind("top"))
	hair_left.connect("region_clicked", Callable(self, "_on_region_clicked").bind("left_side"))
	hair_right.connect("region_clicked", Callable(self, "_on_region_clicked").bind("right_side"))
	hair_back.connect("region_clicked", Callable(self, "_on_region_clicked").bind("back"))


func _connect_tools() -> void:
	tool_scissors.connect("pressed", Callable(self, "_select_tool").bind("scissors"))
	tool_clipper.connect("pressed", Callable(self, "_select_tool").bind("clipper"))
	tool_comb.connect("pressed", Callable(self, "_select_tool").bind("comb"))
	undo_button.connect("pressed", Callable(self, "_undo"))
	finish_button.connect("pressed", Callable(self, "_on_finish_pressed"))
	confirm_yes.connect("pressed", Callable(self, "_confirm_finish"))
	confirm_no.connect("pressed", Callable(self, "_cancel_finish"))


func _select_tool(tool: String) -> void:
	selected_tool = tool
	feedback_label.text = "已选择：" + _tool_name(tool)


func _tool_name(tool: String) -> String:
	match tool:
		"scissors": return "剪刀"
		"clipper": return "电推子"
		"comb": return "梳子"
	return tool


func _on_region_clicked(region: String) -> void:
	_save_state()
	
	match selected_tool:
		"scissors":
			_apply_scissors(region)
		"clipper":
			_apply_clipper(region)
		"comb":
			_apply_comb(region)
	
	_restore_hair_visuals()
	_update_undo_button()


func _apply_scissors(region: String) -> void:
	var state: Dictionary = GameState.current_hair_state
	var val: int = state.get(region, 3)
	if val > 0:
		state[region] = val - 1
		GameState.haircut_action_count += 1
		feedback_label.text = _region_name(region) + "剪短了一些"
	else:
		feedback_label.text = _region_name(region) + "已经不能再短了"
		_pop_state()


func _apply_clipper(region: String) -> void:
	var state: Dictionary = GameState.current_hair_state
	var val: int = state.get(region, 3)
	var top_regions: Array = ["top", "bangs"]
	
	if region in top_regions and val <= 1:
		state[region] = 0
		GameState.mistake_count += 1
		GameState.haircut_action_count += 1
		feedback_label.text = "警告：" + _region_name(region) + "被推得很短！"
	else:
		var new_val: int = 1
		if val <= new_val:
			new_val = 0
		state[region] = new_val
		GameState.haircut_action_count += 1
		feedback_label.text = _region_name(region) + "已经推短"


func _apply_comb(region: String) -> void:
	var state: Dictionary = GameState.current_hair_state
	if region == "top" or region == "bangs":
		state["parting"] = "left"
		state["styled"] = true
		GameState.haircut_action_count += 1
		feedback_label.text = "头发整理成了自然侧分"
	else:
		feedback_label.text = "梳子适用于顶部或刘海区域"
		_pop_state()


func _region_name(region: String) -> String:
	match region:
		"bangs": return "刘海"
		"top": return "顶部"
		"left_side": return "左侧"
		"right_side": return "右侧"
		"back": return "后脑"
	return region


func _save_state() -> void:
	var state_copy: Dictionary = GameState.current_hair_state.duplicate(true)
	history.push_front(state_copy)
	if history.size() > max_history:
		history.pop_back()


func _pop_state() -> void:
	if not history.is_empty():
		history.pop_front()


func _undo() -> void:
	if history.is_empty():
		feedback_label.text = "没有可以撤销的操作"
		return
	
	var previous: Dictionary = history.pop_front()
	GameState.current_hair_state = previous
	_restore_hair_visuals()
	_update_undo_button()
	feedback_label.text = "已撤销上一步"


func _restore_hair_visuals() -> void:
	var state: Dictionary = GameState.current_hair_state
	hair_bangs.set_length(state.get("bangs", 3))
	hair_top.set_length(state.get("top", 3))
	hair_left.set_length(state.get("left_side", 3))
	hair_right.set_length(state.get("right_side", 3))
	hair_back.set_length(state.get("back", 3))
	
	_update_parting_visual(state.get("parting", "none"))


func _update_parting_visual(parting: String) -> void:
	if parting == "left":
		hair_top.position.x = -10
		hair_bangs.position.x = -8
	else:
		hair_top.position.x = -20
		hair_bangs.position.x = -20


func _update_undo_button() -> void:
	undo_button.disabled = history.is_empty()


func _update_need_hint() -> void:
	if GameState.revealed_hidden_need:
		need_hint_label.text = "需求：自然、正式、容易整理的自然短侧分"
	else:
		need_hint_label.text = "需求：稍微剪短，精神一些"


func _on_finish_pressed() -> void:
	confirm_panel.show()


func _cancel_finish() -> void:
	confirm_panel.hide()


func _confirm_finish() -> void:
	is_timing = false
	GameState.elapsed_haircut_time = timer
	
	var scorer: Dictionary = HaircutScoring.calculate_score(
		GameState.current_hair_state,
		GameState.target_hair_state,
		GameState.dialogue_understanding_score,
		GameState.revealed_hidden_need,
		GameState.mistake_count,
		GameState.haircut_action_count,
		GameState.elapsed_haircut_time
	)
	
	GameState.final_score = scorer.get("total", 0)
	GameState.score_breakdown = scorer.get("breakdown", {})
	GameState.customer_feedback = scorer.get("feedback", "")
	
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")

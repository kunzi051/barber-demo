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
@onready var style_buttons: Control = $StyleButtons
@onready var style_left_part: Button = $StyleButtons/StyleLeftPart
@onready var style_fluffy: Button = $StyleButtons/StyleFluffy

var selected_tool: String = ""
var history: Array = []
var max_history: int = 10
var timer: float = 0.0
var is_timing: bool = true
var selected_style: String = "none"


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 1)
	var tween_in: Tween = create_tween()
	tween_in.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)
	
	_connect_regions()
	_connect_tools()
	_load_customer_info()
	_restore_hair_visuals()
	_update_need_hint()
	_update_undo_button()
	_update_tool_highlight()
	confirm_panel.hide()
	style_buttons.hide()
	
	_save_state()


func _load_customer_info() -> void:
	var cust_data: Dictionary = GameState.get_current_customer_data()
	customer_name_label.text = "客人：" + cust_data.get("name", "客人")
	
	if GameState.initial_hair_state.is_empty():
		GameState.initial_hair_state = GameState.current_hair_state.duplicate(true)


func _process(delta: float) -> void:
	if is_timing:
		timer += delta


func _connect_regions() -> void:
	hair_bangs.connect("region_clicked", Callable(self, "_on_region_clicked"))
	hair_top.connect("region_clicked", Callable(self, "_on_region_clicked"))
	hair_left.connect("region_clicked", Callable(self, "_on_region_clicked"))
	hair_right.connect("region_clicked", Callable(self, "_on_region_clicked"))
	hair_back.connect("region_clicked", Callable(self, "_on_region_clicked"))


func _connect_tools() -> void:
	tool_scissors.connect("pressed", Callable(self, "_select_tool").bind("scissors"))
	tool_clipper.connect("pressed", Callable(self, "_select_tool").bind("clipper"))
	tool_comb.connect("pressed", Callable(self, "_select_tool").bind("comb"))
	undo_button.connect("pressed", Callable(self, "_undo"))
	finish_button.connect("pressed", Callable(self, "_on_finish_pressed"))
	confirm_yes.connect("pressed", Callable(self, "_confirm_finish"))
	confirm_no.connect("pressed", Callable(self, "_cancel_finish"))
	style_left_part.connect("pressed", Callable(self, "_select_style").bind("natural_left_part"))
	style_fluffy.connect("pressed", Callable(self, "_select_style").bind("fluffy"))


func _select_tool(tool: String) -> void:
	selected_tool = tool
	style_buttons.hide()
	_update_tool_highlight()
	
	var tool_name: String = _tool_name(tool)
	var tool_desc: String = _tool_description(tool)
	feedback_label.text = "当前工具：" + tool_name + "\n" + tool_desc


func _tool_name(tool: String) -> String:
	match tool:
		"scissors": return "剪刀"
		"clipper": return "电推子"
		"comb": return "梳子"
	return tool


func _tool_description(tool: String) -> String:
	match tool:
		"scissors": return "效果：将所选区域剪短一级"
		"clipper": return "效果：将所选区域设置为短"
		"comb": return "效果：先选择造型方式，再点击头发"
	return ""


func _update_tool_highlight() -> void:
	var buttons: Array = [tool_scissors, tool_clipper, tool_comb]
	for btn in buttons:
		btn.modulate = Color(1, 1, 1, 1)
	
	if selected_tool == "scissors":
		tool_scissors.modulate = Color(0.8, 1.0, 0.8, 1)
	elif selected_tool == "clipper":
		tool_clipper.modulate = Color(0.8, 1.0, 0.8, 1)
	elif selected_tool == "comb":
		tool_comb.modulate = Color(0.8, 1.0, 0.8, 1)
		style_buttons.show()


func _select_style(style: String) -> void:
	selected_style = style
	var style_name: String = "自然侧分" if style == "natural_left_part" else "蓬松整理"
	feedback_label.text = "当前造型：" + style_name + "\n点击顶部或刘海应用"
	style_buttons.hide()


func _on_region_clicked(region: String) -> void:
	if selected_tool.is_empty():
		feedback_label.text = "请先选择工具"
		return
	
	_save_state()
	var changed: bool = false
	var old_val: int = GameState.current_hair_state.get(region, 3)
	
	match selected_tool:
		"scissors":
			changed = _apply_scissors(region)
		"clipper":
			changed = _apply_clipper(region)
		"comb":
			changed = _apply_comb(region)
	
	if changed:
		var new_val: int = GameState.current_hair_state.get(region, 3)
		var old_name: String = get_length_display_name(old_val)
		var new_name: String = get_length_display_name(new_val)
		feedback_label.text = _region_name(region) + "：" + old_name + " → " + new_name
		_play_region_click_animation(region)
		_spawn_hair_clippings(region)
		if selected_tool == "scissors":
			_play_scissors_animation()
		elif selected_tool == "clipper":
			_play_clipper_feedback()
	else:
		feedback_label.text = _region_name(region) + "已经不能再剪短了"
		_pop_state()
	
	_restore_hair_visuals()
	_update_undo_button()


func get_length_display_name(value: int) -> String:
	match value:
		0: return "很短"
		1: return "短"
		2: return "中等"
		3: return "较长"
	return "未知"


func _apply_scissors(region: String) -> bool:
	var state: Dictionary = GameState.current_hair_state
	var val: int = state.get(region, 3)
	if val > 0:
		state[region] = val - 1
		GameState.haircut_action_count += 1
		return true
	return false


func _apply_clipper(region: String) -> bool:
	var state: Dictionary = GameState.current_hair_state
	var val: int = state.get(region, 3)
	var top_regions: Array = ["top", "bangs"]
	
	if region in top_regions and val <= 1:
		state[region] = 0
		GameState.mistake_count += 1
		GameState.haircut_action_count += 1
		_update_customer_comfort(-1)
		feedback_label.text = "警告：" + _region_name(region) + "被推得很短！\n李明似乎有些担心……"
		return true
	else:
		var new_val: int = 1
		if val <= new_val:
			new_val = 0
		state[region] = new_val
		GameState.haircut_action_count += 1
		return true


func _apply_comb(region: String) -> bool:
	var state: Dictionary = GameState.current_hair_state
	if region == "top" or region == "bangs":
		if selected_style.is_empty() or selected_style == "none":
			feedback_label.text = "请先选择造型方式（自然侧分或蓬松整理）"
			_pop_state()
			return false
		state["style_type"] = selected_style
		GameState.haircut_action_count += 1
		var sname: String = "自然侧分" if selected_style == "natural_left_part" else "蓬松造型"
		feedback_label.text = "头发整理成了" + sname
		style_buttons.hide()
		return true
	else:
		feedback_label.text = "梳子适用于顶部或刘海区域"
		_pop_state()
		return false


func _region_name(region: String) -> String:
	match region:
		"bangs": return "刘海"
		"top": return "顶部"
		"left_side": return "左侧"
		"right_side": return "右侧"
		"back": return "后脑"
	return region


func _play_region_click_animation(region: String) -> void:
	var region_node: ColorRect = _get_region_node(region)
	if region_node == null:
		return
	
	if region_node.has_meta("click_tween"):
		var old_tween: Tween = region_node.get_meta("click_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	var orig_scale: Vector2 = region_node.scale
	var tween: Tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(region_node, "scale", orig_scale * 0.92, 0.06)
	tween.tween_property(region_node, "scale", orig_scale, 0.08)
	region_node.set_meta("click_tween", tween)


func _play_scissors_animation() -> void:
	$ToolScissors.position.x = 920
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tool_scissors, "rotation_degrees", 10, 0.04)
	tween.tween_property(tool_scissors, "scale", Vector2(0.85, 1.15), 0.04)
	
	var tween2: Tween = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(tool_scissors, "rotation_degrees", 0, 0.06)
	tween2.tween_property(tool_scissors, "scale", Vector2(1, 1), 0.06)


func _play_clipper_feedback() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tool_clipper, "position", Vector2(918, 155), 0.02)
	
	var tween2: Tween = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(tool_clipper, "position", Vector2(920, 155), 0.06)


func _spawn_hair_clippings(region: String) -> void:
	var region_node: ColorRect = _get_region_node(region)
	if region_node == null:
		return
	
	var spawn_pos: Vector2 = region_node.get_global_rect().position + Vector2(randf_range(-10, 10), 0)
	var count: int = randi_range(3, 6)
	
	for i in count:
		var clipping: ColorRect = ColorRect.new()
		clipping.size = Vector2(randf_range(2, 5), randf_range(1, 3))
		clipping.color = Color(0.2, 0.12, 0.08, 0.8)
		clipping.position = spawn_pos + Vector2(randf_range(-8, 8), randf_range(-4, 4))
		clipping.pivot_offset = clipping.size / 2
		clipping.rotation = randf_range(-0.3, 0.3)
		add_child(clipping)
		
		var fall_tween: Tween = create_tween()
		fall_tween.set_parallel(true)
		fall_tween.tween_property(clipping, "position", clipping.position + Vector2(randf_range(-15, 15), randf_range(20, 40)), randf_range(0.4, 0.8))
		fall_tween.tween_property(clipping, "modulate", Color(0.2, 0.12, 0.08, 0), randf_range(0.3, 0.6))
		fall_tween.tween_property(clipping, "scale", Vector2(0.3, 0.3), randf_range(0.4, 0.8))
		
		await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
		if is_instance_valid(clipping):
			clipping.queue_free()


func _get_region_node(region: String) -> ColorRect:
	match region:
		"bangs": return hair_bangs
		"top": return hair_top
		"left_side": return hair_left
		"right_side": return hair_right
		"back": return hair_back
	return null


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
	
	_update_style_visual(state.get("style_type", "none"))


func _update_style_visual(style_type: String) -> void:
	if style_type == "natural_left_part":
		hair_top.position.x = -10
		hair_bangs.position.x = -8
	elif style_type == "fluffy":
		hair_top.position.x = -25
		hair_bangs.position.x = -28
		hair_top.scale = Vector2(1.15, 1.0)
		hair_bangs.scale = Vector2(1.1, 1.0)
	else:
		hair_top.position.x = -20
		hair_bangs.position.x = -20
		hair_top.scale = Vector2(1.0, 1.0)
		hair_bangs.scale = Vector2(1.0, 1.0)


func _update_undo_button() -> void:
	undo_button.disabled = history.is_empty()


func _update_need_hint() -> void:
	var cust_data: Dictionary = GameState.get_current_customer_data()
	if GameState.revealed_hidden_need:
		var target_data: Dictionary = JSONLoader.load_json(cust_data.get("target_hairstyle_file", "res://data/hairstyles/" + cust_data.get("target_hairstyle_id", "") + ".json"))
		var style_name: String = target_data.get("name", "")
		need_hint_label.text = "需求：" + style_name
	else:
		need_hint_label.text = "需求：" + cust_data.get("visible_request", "")


func _update_customer_comfort(change: int) -> void:
	pass


func _on_finish_pressed() -> void:
	confirm_panel.show()


func _cancel_finish() -> void:
	confirm_panel.hide()


func _confirm_finish() -> void:
	is_timing = false
	GameState.elapsed_haircut_time = timer
	
	var cust_data: Dictionary = GameState.get_current_customer_data()
	var scoring_file: String = cust_data.get("scoring_profile_file", "")
	var feedback_file: String = cust_data.get("feedback_file", "")
	
	var scorer: Dictionary = HaircutScoring.calculate_score(
		GameState.current_hair_state,
		GameState.target_hair_state,
		GameState.dialogue_understanding_score,
		GameState.revealed_hidden_need,
		GameState.mistake_count,
		GameState.haircut_action_count,
		GameState.elapsed_haircut_time,
		scoring_file,
		feedback_file,
		cust_data
	)
	
	GameState.final_score = scorer.get("total", 0)
	GameState.score_breakdown = scorer.get("breakdown", {})
	GameState.customer_feedback = scorer.get("feedback", "")
	
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")

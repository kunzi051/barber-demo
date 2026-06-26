extends Control

class_name ResultController

@onready var total_score_label: Label = $ResultPanel/TotalScoreLabel
@onready var score_breakdown_container: VBoxContainer = $ResultPanel/ScoreBreakdownContainer
@onready var customer_feedback_label: Label = $ResultPanel/CustomerFeedbackLabel
@onready var restart_button: Button = $ResultPanel/RestartButton
@onready var next_customer_button: Button = $ResultPanel/NextCustomerButton
@onready var customer_portrait: ColorRect = $ResultPanel/MirrorFrame/CustomerPortrait
@onready var grade_label: Label = $ResultPanel/GradeLabel
@onready var mirror_frame: ColorRect = $ResultPanel/MirrorFrame
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var customer_name_result: Label = $ResultPanel/CustomerNameResult
@onready var before_portrait: ColorRect = $ResultPanel/BeforeAfter/BeforePortrait
@onready var after_portrait: ColorRect = $ResultPanel/BeforeAfter/AfterPortrait
@onready var before_after_container: Control = $ResultPanel/BeforeAfter


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 1)
	var tween_in: Tween = create_tween()
	tween_in.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)
	
	_display_results()


func _display_results() -> void:
	var cust_data: Dictionary = GameState.get_current_customer_data()
	var cust_name: String = cust_data.get("name", "客人")
	customer_name_result.text = cust_name + "的理发结果"
	
	total_score_label.text = str(GameState.final_score) + " 分"
	
	var grade: String = _get_grade(GameState.final_score)
	grade_label.text = grade
	
	var breakdown: Dictionary = GameState.score_breakdown
	for child in score_breakdown_container.get_children():
		child.queue_free()
	
	for key in breakdown:
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		name_label.text = key
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var score_label: Label = Label.new()
		var val: float = breakdown.get(key, 0)
		score_label.text = str(val)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_label)
		row.add_child(score_label)
		score_breakdown_container.add_child(row)
	
	customer_feedback_label.text = GameState.customer_feedback
	
	_update_before_after()
	_update_button()


func _update_before_after() -> void:
	_update_portrait(before_portrait, GameState.initial_hair_state)
	_update_portrait(after_portrait, GameState.current_hair_state)


func _update_portrait(portrait: ColorRect, hair_state: Dictionary) -> void:
	portrait.color = Color(0.95, 0.85, 0.7, 1)
	
	# Clear previous hair children
	for child in portrait.get_children():
		child.queue_free()
	
	# Draw simple hair based on state
	var bangs_len: int = hair_state.get("bangs", 3)
	var top_len: int = hair_state.get("top", 3)
	
	var bangs_rect: ColorRect = ColorRect.new()
	bangs_rect.size = Vector2(18, 4 + bangs_len * 3)
	bangs_rect.color = Color(0.2, 0.12, 0.08, 1)
	bangs_rect.position = Vector2(1, 0)
	portrait.add_child(bangs_rect)
	
	var top_rect: ColorRect = ColorRect.new()
	top_rect.size = Vector2(22, 4 + top_len * 3)
	top_rect.color = Color(0.2, 0.12, 0.08, 1)
	top_rect.position = Vector2(-2, -top_len)
	portrait.add_child(top_rect)
	
	var style_type: String = hair_state.get("style_type", "none")
	if style_type == "natural_left_part":
		bangs_rect.position.x = -2
	elif style_type == "fluffy":
		top_rect.size.x = 26
		bangs_rect.size.x = 22


func _get_grade(score: int) -> String:
	if score >= 90:
		return "非常满意"
	elif score >= 75:
		return "满意"
	elif score >= 60:
		return "基本满意"
	else:
		return "有些遗憾"


func _update_button() -> void:
	if GameState.has_next_customer():
		next_customer_button.show()
		restart_button.hide()
	else:
		next_customer_button.hide()
		restart_button.show()


func _on_next_customer_pressed() -> void:
	if GameState.advance_to_next_customer():
		var tween: Tween = create_tween()
		tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
		await tween.finished
		get_tree().change_scene_to_file("res://scenes/shop/barber_shop.tscn")


func _on_restart_pressed() -> void:
	GameState.reset_demo()
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

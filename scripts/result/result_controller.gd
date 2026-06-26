extends Control

class_name ResultController

@onready var total_score_label: Label = $ResultPanel/TotalScoreLabel
@onready var score_breakdown_container: VBoxContainer = $ResultPanel/ScoreBreakdownContainer
@onready var customer_feedback_label: Label = $ResultPanel/CustomerFeedbackLabel
@onready var restart_button: Button = $ResultPanel/RestartButton
@onready var customer_portrait: ColorRect = $ResultPanel/MirrorFrame/CustomerPortrait
@onready var grade_label: Label = $ResultPanel/GradeLabel
@onready var mirror_frame: ColorRect = $ResultPanel/MirrorFrame
@onready var transition_overlay: ColorRect = $TransitionOverlay


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 1)
	var tween_in: Tween = create_tween()
	tween_in.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)
	
	_display_results()


func _display_results() -> void:
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


func _get_grade(score: int) -> String:
	if score >= 90:
		return "非常满意"
	elif score >= 75:
		return "满意"
	elif score >= 60:
		return "基本满意"
	else:
		return "有些遗憾"


func _on_restart_pressed() -> void:
	GameState.reset_demo()
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

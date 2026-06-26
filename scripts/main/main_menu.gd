extends Control

class_name MainMenu


@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton
@onready var title_label: Label = $CanvasLayer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CanvasLayer/VBoxContainer/SubtitleLabel
@onready var footer_label: Label = $CanvasLayer/VBoxContainer/FooterLabel
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var audio_stream: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	transition_overlay.modulate = Color(0, 0, 0, 0)
	_setup_ui()


func _setup_ui() -> void:
	title_label.text = "暖暖理发店"
	subtitle_label.text = "听懂客人的故事，再为他剪一个合适的发型"
	footer_label.text = "Warm Barber Demo"
	start_button.text = "开始营业"


func _on_start_button_pressed() -> void:
	start_button.disabled = true
	GameState.reset_demo()
	_fade_to_scene()


func _fade_to_scene() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/shop/barber_shop.tscn")

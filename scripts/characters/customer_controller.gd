extends Node2D

class_name CustomerController

enum Emotion { NERVOUS, NEUTRAL, RELAXED, TRUSTING, WORRIED, SATISFIED, DISAPPOINTED, INTERESTED }

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var hair: ColorRect = $Hair
@onready var left_leg: ColorRect = $LeftLeg
@onready var right_leg: ColorRect = $RightLeg
@onready var eye_left: ColorRect = $EyeLeft
@onready var eye_right: ColorRect = $EyeRight
@onready var mouth: ColorRect = $Mouth

var current_emotion: int = Emotion.NERVOUS


func setup(customer_data: Dictionary) -> void:
	var visual: Dictionary = customer_data.get("visual_profile", {})
	
	body.color = _parse_color(visual.get("shirt_color", "0.4,0.35,0.3"))
	head.color = _parse_color(visual.get("skin_tone", "0.95,0.85,0.7"))
	hair.color = _parse_color(visual.get("hair_color", "0.15,0.1,0.1"))
	left_leg.color = _parse_color(visual.get("pants_color", "0.25,0.2,0.15"))
	right_leg.color = _parse_color(visual.get("pants_color", "0.25,0.2,0.15"))
	eye_left.color = Color(0.1, 0.1, 0.1)
	eye_right.color = Color(0.1, 0.1, 0.1)
	mouth.color = Color(0.6, 0.3, 0.3)
	
	body.size = Vector2(32, 44)
	head.size = Vector2(26, 26)
	hair.size = Vector2(28, 12)
	left_leg.size = Vector2(8, 16)
	right_leg.size = Vector2(8, 16)
	eye_left.size = Vector2(3, 3)
	eye_right.size = Vector2(3, 3)
	mouth.size = Vector2(6, 2)
	
	head.position = Vector2(-13, -48)
	hair.position = Vector2(-14, -58)
	left_leg.position = Vector2(-10, 28)
	right_leg.position = Vector2(2, 28)
	eye_left.position = Vector2(-6, -52)
	eye_right.position = Vector2(3, -52)
	mouth.position = Vector2(-3, -44)
	
	set_emotion(Emotion.NERVOUS)


func _parse_color(str_val: String) -> Color:
	var parts: PackedStringArray = str_val.split(",")
	if parts.size() >= 3:
		return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), 1.0)
	return Color(0.5, 0.5, 0.5, 1)


func set_emotion(emotion: int) -> void:
	current_emotion = emotion
	
	_apply_emotion_to_eyes(emotion)
	_apply_emotion_to_mouth(emotion)


func _apply_emotion_to_eyes(emotion: int) -> void:
	match emotion:
		Emotion.NERVOUS, Emotion.WORRIED:
			eye_left.size = Vector2(3, 4)
			eye_right.size = Vector2(3, 4)
			eye_left.position.y = -53
			eye_right.position.y = -53
		Emotion.NEUTRAL, Emotion.INTERESTED:
			eye_left.size = Vector2(3, 3)
			eye_right.size = Vector2(3, 3)
			eye_left.position.y = -52
			eye_right.position.y = -52
		Emotion.RELAXED, Emotion.TRUSTING, Emotion.SATISFIED:
			eye_left.size = Vector2(2, 2)
			eye_right.size = Vector2(2, 2)
			eye_left.position.y = -51
			eye_right.position.y = -51
		Emotion.DISAPPOINTED:
			eye_left.size = Vector2(3, 3)
			eye_right.size = Vector2(3, 3)
			eye_left.position.y = -51
			eye_right.position.y = -51


func _apply_emotion_to_mouth(emotion: int) -> void:
	match emotion:
		Emotion.NERVOUS:
			mouth.size = Vector2(4, 2)
			mouth.position.y = -44
		Emotion.WORRIED:
			mouth.size = Vector2(6, 2)
			mouth.rotation = 0.1
		Emotion.NEUTRAL:
			mouth.size = Vector2(6, 2)
			mouth.rotation = 0
			mouth.position.y = -44
		Emotion.INTERESTED:
			mouth.size = Vector2(4, 3)
			mouth.position.y = -45
		Emotion.RELAXED:
			mouth.size = Vector2(6, 2)
			mouth.rotation = -0.15
			mouth.position.y = -45
		Emotion.TRUSTING:
			mouth.size = Vector2(8, 2)
			mouth.rotation = -0.2
			mouth.position.y = -46
		Emotion.SATISFIED:
			mouth.size = Vector2(10, 2)
			mouth.rotation = -0.25
			mouth.position.y = -47
		Emotion.DISAPPOINTED:
			mouth.size = Vector2(6, 2)
			mouth.rotation = 0.2
			mouth.position.y = -43


func set_emotion_from_score(total_score: int) -> void:
	if total_score >= 90:
		set_emotion(Emotion.SATISFIED)
	elif total_score >= 75:
		set_emotion(Emotion.RELAXED)
	elif total_score >= 60:
		set_emotion(Emotion.NEUTRAL)
	else:
		set_emotion(Emotion.DISAPPOINTED)


func get_emotion_text() -> String:
	match current_emotion:
		Emotion.NERVOUS: return "有些紧张"
		Emotion.NEUTRAL: return "平静"
		Emotion.RELAXED: return "放松了一些"
		Emotion.TRUSTING: return "比较信任"
		Emotion.WORRIED: return "有些担心"
		Emotion.SATISFIED: return "非常满意"
		Emotion.DISAPPOINTED: return "有些失望"
		Emotion.INTERESTED: return "感兴趣"
	return ""

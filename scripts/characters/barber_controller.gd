extends Node2D

class_name BarberController

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var left_leg: ColorRect = $LeftLeg
@onready var right_leg: ColorRect = $RightLeg

var move_bob: float = 0.0


func _ready() -> void:
	body.color = Color(0.3, 0.5, 0.8)
	head.color = Color(0.95, 0.85, 0.7)
	left_leg.color = Color(0.2, 0.3, 0.6)
	right_leg.color = Color(0.2, 0.3, 0.6)
	body.size = Vector2(30, 40)
	head.size = Vector2(24, 24)
	left_leg.size = Vector2(8, 16)
	right_leg.size = Vector2(8, 16)
	
	head.position = Vector2(-12, -44)
	left_leg.position = Vector2(-10, 24)
	right_leg.position = Vector2(2, 24)


func _process(delta: float) -> void:
	var parent: Node2D = get_parent() as Node2D
	if parent and parent.has_method("is_moving") and parent.is_moving:
		move_bob += delta * 8.0
		var bob_offset: float = sin(move_bob) * 2.0
		left_leg.position.y = 24 + bob_offset
		right_leg.position.y = 24 - bob_offset
	else:
		move_bob = 0.0
		left_leg.position.y = 24
		right_leg.position.y = 24

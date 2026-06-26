extends Node2D

class_name CustomerController

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var hair: ColorRect = $Hair
@onready var left_leg: ColorRect = $LeftLeg
@onready var right_leg: ColorRect = $RightLeg
@onready var eye_left: ColorRect = $EyeLeft
@onready var eye_right: ColorRect = $EyeRight
@onready var mouth: ColorRect = $Mouth


func _ready() -> void:
	body.color = Color(0.4, 0.35, 0.3)
	head.color = Color(0.95, 0.85, 0.7)
	hair.color = Color(0.15, 0.1, 0.1)
	left_leg.color = Color(0.25, 0.2, 0.15)
	right_leg.color = Color(0.25, 0.2, 0.15)
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

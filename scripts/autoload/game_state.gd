extends Node

# Dialogue scores
var dialogue_understanding_score: int = 0
var customer_trust: int = 0
var revealed_hidden_need: bool = false

# Hair state
var current_hair_state: Dictionary = {}
var target_hair_state: Dictionary = {}

# Performance tracking
var haircut_action_count: int = 0
var mistake_count: int = 0
var elapsed_haircut_time: float = 0.0

# Final results
var final_score: int = 0
var score_breakdown: Dictionary = {}
var customer_feedback: String = ""


func _ready() -> void:
	reset_demo()


func reset_demo() -> void:
	dialogue_understanding_score = 0
	customer_trust = 0
	revealed_hidden_need = false

	current_hair_state = {
		"bangs": 3,
		"top": 3,
		"left_side": 3,
		"right_side": 3,
		"back": 3,
		"parting": "none",
		"styled": false
	}

	target_hair_state = {
		"bangs": 2,
		"top": 2,
		"left_side": 1,
		"right_side": 1,
		"back": 1,
		"parting": "left",
		"styled": true
	}

	haircut_action_count = 0
	mistake_count = 0
	elapsed_haircut_time = 0.0

	final_score = 0
	score_breakdown = {}
	customer_feedback = ""

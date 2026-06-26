extends Node

# Customer queue
var customer_queue: Array[String] = []
var current_customer_index: int = 0
var current_customer_id: String = ""
var current_customer_data: Dictionary = {}

# Dialogue scores
var dialogue_understanding_score: int = 0
var customer_trust: int = 0
var revealed_hidden_need: bool = false

# Hair state
var current_hair_state: Dictionary = {}
var target_hair_state: Dictionary = {}
var initial_hair_state: Dictionary = {}

# Performance tracking
var haircut_action_count: int = 0
var mistake_count: int = 0
var elapsed_haircut_time: float = 0.0

# Tutorial state
var shop_move_tutorial_completed: bool = false
var talk_tutorial_completed: bool = false
var haircut_tutorial_completed: bool = false

# Final results
var final_score: int = 0
var score_breakdown: Dictionary = {}
var customer_feedback: String = ""


func _ready() -> void:
	reset_demo()


func reset_demo() -> void:
	customer_queue = ["li_ming"]
	current_customer_index = 0
	load_current_customer()
	
	dialogue_understanding_score = 0
	customer_trust = 0
	revealed_hidden_need = false
	
	haircut_action_count = 0
	mistake_count = 0
	elapsed_haircut_time = 0.0
	initial_hair_state = {}
	
	shop_move_tutorial_completed = false
	talk_tutorial_completed = false
	haircut_tutorial_completed = false
	
	final_score = 0
	score_breakdown = {}
	customer_feedback = ""


func start_day(customer_ids: Array[String]) -> void:
	customer_queue = customer_ids.duplicate()
	current_customer_index = 0
	load_current_customer()
	reset_current_customer_session()
	tutorial_reset()


func tutorial_reset() -> void:
	shop_move_tutorial_completed = false
	talk_tutorial_completed = false
	haircut_tutorial_completed = false


func load_current_customer() -> bool:
	if current_customer_index < 0 or current_customer_index >= customer_queue.size():
		current_customer_id = ""
		current_customer_data = {}
		return false
	
	var cid: String = customer_queue[current_customer_index]
	current_customer_id = cid
	
	customer_queue.resize(len(customer_queue))
	
	current_customer_data = load_customer_data(cid)
	if current_customer_data.is_empty():
		push_error("Failed to load customer data for: " + cid)
		return false
	
	var target_file: String = current_customer_data.get("target_hairstyle_file", "")
	if target_file.is_empty():
		target_file = "res://data/hairstyles/" + current_customer_data.get("target_hairstyle_id", "") + ".json"
	
	var target_data: Dictionary = JSONLoader.load_json(target_file)
	if not target_data.is_empty():
		_load_hair_state_from_data(target_data, target_hair_state, true)
	
	var init_file: String = current_customer_data.get("initial_hairstyle_file", "")
	if init_file.is_empty():
		init_file = "res://data/hairstyles/" + cid + "_initial.json"
		if not FileAccess.file_exists(init_file):
			init_file = ""
	
	if not init_file.is_empty():
		var init_data: Dictionary = JSONLoader.load_json(init_file)
		if not init_data.is_empty():
			_load_hair_state_from_data(init_data, current_hair_state, false)
	
	reset_current_customer_session()
	return true


func load_customer_data(cid: String) -> Dictionary:
	var path: String = "res://data/customers/customer_" + cid + ".json"
	return JSONLoader.load_json(path)


func get_current_customer_data() -> Dictionary:
	if current_customer_data.is_empty():
		load_current_customer()
	return current_customer_data


func _load_hair_state_from_data(data: Dictionary, target: Dictionary, is_target: bool) -> void:
	var regions: Dictionary = data.get("regions", {})
	target["bangs"] = regions.get("bangs", 3)
	target["top"] = regions.get("top", 3)
	target["left_side"] = regions.get("left_side", 3)
	target["right_side"] = regions.get("right_side", 3)
	target["back"] = regions.get("back", 3)
	
	var style_type: String = data.get("style_type", "")
	if style_type.is_empty():
		style_type = data.get("parting", "none")
	target["style_type"] = style_type


func reset_current_customer_session() -> void:
	dialogue_understanding_score = 0
	customer_trust = 0
	revealed_hidden_need = false
	
	if current_customer_data.is_empty():
		load_current_customer()
	
	var init_file: String = current_customer_data.get("initial_hairstyle_file", "")
	if init_file.is_empty():
		init_file = "res://data/hairstyles/" + current_customer_id + "_initial.json"
		if not FileAccess.file_exists(init_file):
			init_file = ""
	
	if not init_file.is_empty():
		var init_data: Dictionary = JSONLoader.load_json(init_file)
		if not init_data.is_empty():
			_load_hair_state_from_data(init_data, current_hair_state, false)
		else:
			_init_default_hair_state(current_hair_state)
	else:
		_init_default_hair_state(current_hair_state)
	
	var target_file: String = current_customer_data.get("target_hairstyle_file", "")
	if target_file.is_empty():
		target_file = "res://data/hairstyles/" + current_customer_data.get("target_hairstyle_id", "") + ".json"
	
	var target_data: Dictionary = JSONLoader.load_json(target_file)
	if not target_data.is_empty():
		_load_hair_state_from_data(target_data, target_hair_state, true)
	else:
		_init_default_hair_state(target_hair_state)
	
	initial_hair_state = current_hair_state.duplicate(true)
	
	haircut_action_count = 0
	mistake_count = 0
	elapsed_haircut_time = 0.0


func _init_default_hair_state(state: Dictionary) -> void:
	state["bangs"] = 3
	state["top"] = 3
	state["left_side"] = 3
	state["right_side"] = 3
	state["back"] = 3
	state["style_type"] = "none"


func has_next_customer() -> bool:
	return current_customer_index < customer_queue.size() - 1


func advance_to_next_customer() -> bool:
	if not has_next_customer():
		return false
	current_customer_index += 1
	if not load_current_customer():
		return false
	tutorial_reset()
	return true

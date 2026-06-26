extends Node

class_name SmokeTest

func run() -> void:
	print("=== Smoke Test ===")
	_test_game_state()
	_test_json_loader()
	_test_haircut_scoring()
	print("=== Smoke Test Complete ===")


func _test_game_state() -> void:
	var gs: GameState = GameState.new()
	gs.reset_demo()
	assert(gs.dialogue_understanding_score == 0, "dialogue_understanding_score should be 0")
	assert(gs.customer_trust == 0, "customer_trust should be 0")
	assert(gs.revealed_hidden_need == false, "revealed_hidden_need should be false")
	assert(gs.current_hair_state.get("top") == 3, "top should be 3")
	assert(gs.current_hair_state.get("parting") == "none", "parting should be none")
	assert(gs.current_hair_state.get("styled") == false, "styled should be false")
	print("GameState: OK")


func _test_json_loader() -> void:
	var data: Dictionary = JSONLoader.load_json("res://data/customers/customer_li_ming.json")
	assert(not data.is_empty(), "customer data should not be empty")
	assert(data.get("id") == "li_ming", "customer id should be li_ming")
	assert(data.get("name") == "李明", "customer name should be 李明")
	print("JSONLoader: OK")


func _test_haircut_scoring() -> void:
	var current: Dictionary = {
		"bangs": 2, "top": 2, "left_side": 1, "right_side": 1, "back": 1,
		"parting": "left", "styled": true
	}
	var target: Dictionary = {
		"bangs": 2, "top": 2, "left_side": 1, "right_side": 1, "back": 1,
		"parting": "left", "styled": true
	}
	
	var result: Dictionary = HaircutScoring.calculate_score(current, target, 10, true, 0, 5, 60.0)
	assert(result.get("total", 0) >= 90, "perfect hair should score >= 90")
	print("HaircutScoring (perfect): " + str(result.get("total", 0)))
	
	var bad_current: Dictionary = {
		"bangs": 0, "top": 0, "left_side": 0, "right_side": 0, "back": 0,
		"parting": "none", "styled": false
	}
	var bad_result: Dictionary = HaircutScoring.calculate_score(bad_current, target, -5, false, 5, 20, 200.0)
	assert(bad_result.get("total", 100) < 50, "bad hair should score < 50")
	print("HaircutScoring (bad): " + str(bad_result.get("total", 0)))
	print("HaircutScoring: OK")

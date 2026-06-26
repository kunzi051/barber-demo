extends RefCounted

class_name HaircutScoring


static func calculate_score(
	current_state: Dictionary,
	target_state: Dictionary,
	understanding_score: int,
	revealed_hidden_need: bool,
	mistake_count: int,
	action_count: int,
	elapsed_time: float,
	scoring_profile_path: String = "",
	feedback_path: String = "",
	customer_data: Dictionary = {}
) -> Dictionary:
	var profile: Dictionary = _load_scoring_profile(scoring_profile_path)
	var feedback_templates: Dictionary = _load_feedback_templates(feedback_path)
	
	var breakdown: Dictionary = {}
	
	var hair_score: float = _calculate_hair_match(current_state, target_state, profile)
	hair_score = clampf(hair_score, 0, 50)
	breakdown["发型匹配度"] = hair_score
	
	var need_score: float = _calculate_need_understanding(understanding_score, revealed_hidden_need)
	need_score = clampf(need_score, 0, 25)
	breakdown["需求理解度"] = need_score
	
	var comfort_score: float = _calculate_comfort(mistake_count, current_state, action_count, profile)
	comfort_score = clampf(comfort_score, 0, 15)
	breakdown["服务舒适度"] = comfort_score
	
	var efficiency_score: float = _calculate_efficiency(elapsed_time)
	efficiency_score = clampf(efficiency_score, 0, 10)
	breakdown["操作效率"] = efficiency_score
	
	var total: float = hair_score + need_score + comfort_score + efficiency_score
	var final_score: int = clampi(roundi(total), 0, 100)
	
	var feedback: String = _generate_feedback(final_score, current_state, target_state, understanding_score, revealed_hidden_need, feedback_templates, customer_data)
	
	return {
		"total": final_score,
		"breakdown": breakdown,
		"feedback": feedback
	}


static func _load_scoring_profile(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	return JSONLoader.load_json(path)


static func _load_feedback_templates(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	return JSONLoader.load_json(path)


static func _calculate_hair_match(current: Dictionary, target: Dictionary, profile: Dictionary) -> float:
	var weights: Dictionary = profile.get("region_weights", {
		"bangs": 7, "top": 11, "left_side": 8, "right_side": 8, "back": 6
	})
	
	var total_weight: float = 0.0
	var weighted_score: float = 0.0
	
	var regions: Array = ["bangs", "top", "left_side", "right_side", "back"]
	for region in regions:
		var w: float = weights.get(region, 5)
		total_weight += w
		var current_val: int = current.get(region, 3)
		var target_val: int = target.get(region, 2)
		var error: int = abs(current_val - target_val)
		
		var region_score: float = 0.0
		if error == 0:
			region_score = 1.0
		elif error == 1:
			region_score = 0.6
		elif error == 2:
			region_score = 0.2
		else:
			region_score = 0.0
		
		weighted_score += region_score * w
	
	var style_weight: float = weights.get("style_type", 10)
	total_weight += style_weight
	var current_style: String = current.get("style_type", "none")
	var target_style: String = target.get("style_type", "none")
	if current_style == target_style:
		weighted_score += style_weight
	elif current_style != "none" and target_style != "none":
		weighted_score += style_weight * 0.3
	
	if total_weight <= 0:
		total_weight = 50.0
	
	var result: float = (weighted_score / total_weight) * 50.0
	return minf(result, 50.0)


static func _calculate_need_understanding(understanding_score: int, revealed: bool) -> float:
	var normalized: float = clampf(understanding_score, 0, 20) / 20.0 * 20.0
	if revealed:
		normalized += 5.0
	return clampf(normalized, 0, 25)


static func _calculate_comfort(mistake_count: int, current: Dictionary, action_count: int, profile: Dictionary) -> float:
	var score: float = 15.0
	
	var top_penalty: float = profile.get("top_clipper_zero_penalty", 4.0)
	
	score -= mistake_count * top_penalty
	
	var top: int = current.get("top", 3)
	var bangs: int = current.get("bangs", 3)
	if top == 0:
		score -= top_penalty
	if bangs == 0:
		score -= top_penalty
	
	if action_count > 15:
		score -= (action_count - 15) * 1.0
	
	var sym_penalty: float = profile.get("symmetry_penalty", 2.0)
	var left: int = current.get("left_side", 3)
	var right: int = current.get("right_side", 3)
	if abs(left - right) >= 2:
		score -= sym_penalty
	
	return maxf(score, 0.0)


static func _calculate_efficiency(elapsed_time: float) -> float:
	var seconds: float = elapsed_time
	if seconds <= 90.0:
		return 10.0
	elif seconds <= 150.0:
		return 10.0 - (seconds - 90.0) / 60.0 * 7.0
	else:
		return 3.0


static func _generate_feedback(
	total_score: int,
	current: Dictionary,
	target: Dictionary,
	understanding: int,
	revealed: bool,
	templates: Dictionary,
	customer_data: Dictionary
) -> String:
	if not templates.is_empty():
		return _generate_from_templates(total_score, current, target, understanding, revealed, templates)
	return _generate_default_feedback(total_score, current, target, understanding, revealed)


static func _generate_from_templates(
	total_score: int,
	current: Dictionary,
	target: Dictionary,
	understanding: int,
	revealed: bool,
	templates: Dictionary
) -> String:
	var feedback_parts: PackedStringArray = []
	
	if total_score >= 90:
		return templates.get("high_score", "非常满意！")
	
	if total_score >= 75:
		feedback_parts.append(templates.get("medium_score", "整体效果不错。"))
	else:
		feedback_parts.append(templates.get("low_score", "发型看起来还可以。"))
	
	var top: int = current.get("top", 3)
	var target_top: int = target.get("top", 2)
	if top < target_top:
		feedback_parts.append(templates.get("top_too_short", "顶部好像比预想短了一些。"))
	
	var bangs: int = current.get("bangs", 3)
	var target_bangs: int = target.get("bangs", 2)
	if bangs < target_bangs:
		feedback_parts.append(templates.get("bangs_too_short", "刘海剪得有些短。"))
	
	var left: int = current.get("left_side", 3)
	var target_left: int = target.get("left_side", 1)
	if left < target_left:
		feedback_parts.append(templates.get("sides_too_short", "两侧比预期短了一些。"))
	elif left > target_left + 1:
		feedback_parts.append(templates.get("sides_too_long", "两侧还可以再修一下。"))
	
	var right: int = current.get("right_side", 3)
	if abs(left - right) >= 2:
		feedback_parts.append("两边长度好像不太一样。")
	
	var current_style: String = current.get("style_type", "none")
	var target_style: String = target.get("style_type", "none")
	if current_style == "none" and target_style != "none":
		feedback_parts.append(templates.get("style_mismatch", "如果再做一下造型会更适合。"))
	elif current_style != target_style and target_style != "none":
		feedback_parts.append(templates.get("style_mismatch", "造型方式和预想的不太一样。"))
	
	if revealed and understanding >= 5:
		feedback_parts.append(templates.get("good_understanding_average_haircut", "你确实听懂了我的想法。"))
	elif not revealed and understanding < 3:
		feedback_parts.append(templates.get("low_understanding", "感觉和我表达的有些不同。"))
	
	return " ".join(feedback_parts)


static func _generate_default_feedback(
	total_score: int,
	current: Dictionary,
	target: Dictionary,
	understanding: int,
	revealed: bool
) -> String:
	if total_score >= 90:
		return "非常满意！这正是我想要的感觉。"
	
	var feedback_parts: PackedStringArray = []
	
	if total_score >= 75:
		feedback_parts.append("整体效果不错。")
	else:
		feedback_parts.append("发型看起来还可以。")
	
	var top: int = current.get("top", 3)
	var target_top: int = target.get("top", 2)
	if top < target_top:
		feedback_parts.append("顶部好像比预想短了一些。")
	
	var left: int = current.get("left_side", 3)
	var target_left: int = target.get("left_side", 1)
	if left < target_left:
		feedback_parts.append("两侧比预期短了一些。")
	elif left > target_left + 1:
		feedback_parts.append("两侧还可以再修一下。")
	
	var right: int = current.get("right_side", 3)
	if abs(left - right) >= 2:
		feedback_parts.append("两边长度好像不太一样。")
	
	var current_style: String = current.get("style_type", "none")
	var target_style: String = target.get("style_type", "none")
	if current_style == "none" and target_style != "none":
		feedback_parts.append("如果再做一下造型会更适合。")
	
	if revealed and understanding >= 5:
		feedback_parts.append("你确实听懂了我的想法，谢谢。")
	elif not revealed and understanding < 3:
		feedback_parts.append("虽然效果还行，但感觉和我表达的有些不同。")
	
	return " ".join(feedback_parts)

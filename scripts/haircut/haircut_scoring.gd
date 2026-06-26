extends RefCounted

class_name HaircutScoring


static func calculate_score(
	current_state: Dictionary,
	target_state: Dictionary,
	understanding_score: int,
	revealed_hidden_need: bool,
	mistake_count: int,
	action_count: int,
	elapsed_time: float
) -> Dictionary:
	var breakdown: Dictionary = {}
	
	var hair_score: float = _calculate_hair_match(current_state, target_state)
	hair_score = clampf(hair_score, 0, 50)
	breakdown["发型匹配度"] = hair_score
	
	var need_score: float = _calculate_need_understanding(understanding_score, revealed_hidden_need)
	need_score = clampf(need_score, 0, 25)
	breakdown["需求理解度"] = need_score
	
	var comfort_score: float = _calculate_comfort(mistake_count, current_state, action_count)
	comfort_score = clampf(comfort_score, 0, 15)
	breakdown["服务舒适度"] = comfort_score
	
	var efficiency_score: float = _calculate_efficiency(elapsed_time)
	efficiency_score = clampf(efficiency_score, 0, 10)
	breakdown["操作效率"] = efficiency_score
	
	var total: float = hair_score + need_score + comfort_score + efficiency_score
	var final_score: int = clampi(roundi(total), 0, 100)
	
	var feedback: String = _generate_feedback(final_score, current_state, target_state, understanding_score, revealed_hidden_need)
	
	return {
		"total": final_score,
		"breakdown": breakdown,
		"feedback": feedback
	}


static func _calculate_hair_match(current: Dictionary, target: Dictionary) -> float:
	var weights: Dictionary = {
		"bangs": 7,
		"top": 11,
		"left_side": 8,
		"right_side": 8,
		"back": 6
	}
	
	var max_score: float = 50.0
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
	
	var parting_score: float = 0.0
	if current.get("parting", "none") == target.get("parting", "left"):
		parting_score = 5.0
	
	var styled_score: float = 0.0
	if current.get("styled", false) == target.get("styled", true):
		styled_score = 5.0
	
	var result: float = (weighted_score / total_weight) * 40.0 + parting_score + styled_score
	return minf(result, 50.0)


static func _calculate_need_understanding(understanding_score: int, revealed: bool) -> float:
	var normalized: float = clampf(understanding_score, 0, 20) / 20.0 * 20.0
	if revealed:
		normalized += 5.0
	return clampf(normalized, 0, 25)


static func _calculate_comfort(mistake_count: int, current: Dictionary, action_count: int) -> float:
	var score: float = 15.0
	
	score -= mistake_count * 4.0
	
	var top: int = current.get("top", 3)
	var bangs: int = current.get("bangs", 3)
	if top == 0:
		score -= 4.0
	if bangs == 0:
		score -= 4.0
	
	if action_count > 15:
		score -= (action_count - 15) * 1.0
	
	var left: int = current.get("left_side", 3)
	var right: int = current.get("right_side", 3)
	if abs(left - right) >= 2:
		score -= 2.0
	
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
	revealed: bool
) -> String:
	if total_score >= 90:
		return "正是我想要的感觉。看起来精神了很多，但还是很像我自己。明天面试的时候，我应该会更有信心。"
	
	var feedback_parts: PackedStringArray = []
	
	if total_score >= 75:
		feedback_parts.append("整体效果不错，我很满意。")
	else:
		feedback_parts.append("发型看起来还可以。")
	
	var top: int = current.get("top", 3)
	var target_top: int = target.get("top", 2)
	if top < target_top:
		feedback_parts.append("不过顶部好像剪得比我想象中短了一些。")
	
	var left: int = current.get("left_side", 3)
	var target_left: int = target.get("left_side", 1)
	if left < target_left:
		feedback_parts.append("两侧比我预期的短了一点，可能需要几天才能习惯。")
	elif left > target_left + 1:
		feedback_parts.append("两侧好像还可以再修一下。")
	
	var right: int = current.get("right_side", 3)
	if abs(left - right) >= 2:
		feedback_parts.append("两边长度好像不太一样。")
	
	if current.get("parting", "none") == "none":
		feedback_parts.append("如果再整理一下顶部，可能会更适合明天的面试。")
	
	if revealed and understanding >= 5:
		feedback_parts.append("你确实听懂了我的想法，这点我很感谢。")
	elif not revealed and understanding < 3:
		feedback_parts.append("虽然效果还行，但感觉和我刚才想表达的有些不同。")
	
	if total_score < 60:
		return "嗯…" + " ".join(feedback_parts)
	
	return " ".join(feedback_parts)

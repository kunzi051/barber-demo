extends Node

class_name JSONLoader


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: " + path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: " + path)
		return {}

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(content)
	if parse_result != OK:
		push_error("JSON parse error in " + path + ": " + json.get_error_message())
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("JSON data is not a Dictionary in " + path)
		return {}

	return json.data

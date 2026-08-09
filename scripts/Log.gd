extends Label3D

## Max lines allowed on screen
@export var max_lines: int = 20


var _log_history: Array[String] = []
var _file: FileAccess
var _last_pos: int = 0

func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Fetch setting or fall back to default Godot log location
	var setting_path = ProjectSettings.get_setting("debug/settings/logging/file_logging/log_path")
	
	if setting_path == null:
		setting_path = "user://logs/godot.log"
		
	var global_path = ProjectSettings.globalize_path(str(setting_path))
	
	# Open log file if it exists
	if FileAccess.file_exists(global_path):
		_file = FileAccess.open(global_path, FileAccess.READ)
		if _file:
			_file.seek_end()
			_last_pos = _file.get_position()


func _process(_delta: float) -> void:
	if not _file:
		return
		
	if _file.get_length() > _last_pos:
		_file.seek(_last_pos)
		
		while _file.get_position() < _file.get_length():
			var line = _file.get_line()
			if not line.is_empty():
				_add_line(line)
				
		_last_pos = _file.get_position()


func _add_line(message: String) -> void:
	# Format the message with a cmd-style prompt arrow
	var formatted_message = "> " + message
	
	_log_history.append(formatted_message)
	
	while _log_history.size() > max_lines:
		_log_history.pop_front()
		
	text = "\n".join(_log_history)

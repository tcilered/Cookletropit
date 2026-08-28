extends Label3D

## Max lines allowed on screen
@export var max_lines: int = 20

var _log_history: Array[String] = []

func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameLog.message_logged.connect(_add_line)


func _add_line(message: String) -> void:
	var formatted_message = "> " + message
	
	_log_history.append(formatted_message)
	
	while _log_history.size() > max_lines:
		_log_history.pop_front()
		
	text = "\n".join(_log_history)

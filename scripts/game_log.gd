extends Node

signal message_logged(message: String)

var _history: Array[String] = []
const MAX_HISTORY: int = 200

func log(message: String) -> void:
	_history.append(message)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	message_logged.emit(message)

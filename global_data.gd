extends Node

# Changed the extension from .json to .save since it's now binary data
var save_path = "user://Cookletropitsavegame.save"

var active_charms_global = []

var player_stats = {
	"health": 100,
	"gold": 67,
	"current_level": 1,
	"last_position": Vector2(150, 300) 
}

###
# LOADING AND SAVING
###

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	print(save_path)
	if file:
		# store_var() takes ANY Godot variable and saves it directly
		file.store_var(player_stats)
		print("Game Saved!")

func load_game():
	if not FileAccess.file_exists(save_path):
		print("No save file found.")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	# get_var() pulls the data out exactly as it was saved
	var data = file.get_var()
	
	# Double check that the data we loaded is actually a Dictionary
	if typeof(data) == TYPE_DICTIONARY:
		player_stats = data
		print("Game Loaded!")

###
# MISC
###

func reset_data():
	player_stats = {
		"health": 100,
		"gold": 0,
		"current_level": 1,
		"last_position": Vector2.ZERO
	}

extends Node

# Changed the extension from .json to .save since it's now binary data
var save_path = "user://Cookletropitsavegame.save"

var active_charms_global = []
var owned_charms_global: Array[String] = []
var shop_reroll_price: int = 25
var shop_purchase_locked: bool = false
var shop_stock_names: Array[String] = []
var shop_sold_out_slots: Array[bool] = []

# Food buff system
var active_foods: Array = []

# Round tracking (4 spins per round, must earn threshold to continue)
const SPINS_PER_ROUND: int = 4
var SPIN_MONEY_THRESHOLD: int = 500
var spin_count: int = 0
var money_earned_this_round: int = 0

var player_stats = {
	"health": 100,
	"gold": 400,
	"current_level": 67,
	"last_position": Vector2(150, 300) 
}

###
#LOADING AND SAVING
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
		"health": 400,
		"gold": 6767,
		"current_level": 1,
		"last_position": Vector2.ZERO
	}
	active_foods = []
	active_charms_global = []
	owned_charms_global = []
	shop_reroll_price = 25
	shop_purchase_locked = false
	shop_stock_names = []
	shop_sold_out_slots = []
	SPIN_MONEY_THRESHOLD = 500
	spin_count = 0
	money_earned_this_round = 0

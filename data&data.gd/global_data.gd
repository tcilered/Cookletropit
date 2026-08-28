extends Node

#save it's now binary data
var save_path = "user://Cookletropitsavegame.save"

var active_charms_global = []
var owned_charms_global: Array[String] = []
var shop_reroll_price: int = 25
var shop_purchase_locked: bool = false
var shop_stock_names: Array[String] = []
var shop_sold_out_slots: Array[bool] = []

# Food buff system
var active_foods: Array = []

# Round tracking (4 spins per round, threshold scales exponentially per round)
const SPINS_PER_ROUND: int = 4
var current_round: int = 1
const BASE_MONEY_THRESHOLD: float = 500.0
const THRESHOLD_GROWTH_FACTOR: float = 1.4 # Base exponent factor (1.30 to 1.40 keeps it smooth)

var SPIN_MONEY_THRESHOLD: int = 500
var spin_count: int = 0
var money_earned_this_round: int = 0

var player_stats = {
	"health": 100,
	"gold": 400,
	"current_level": 67,
	"last_position": Vector2(150, 300) 
}


func _ready() -> void:
	update_money_threshold()


# --- THRESHOLD SCALING ---

func update_money_threshold() -> void:
	# Calculates threshold: Base * (1.35 ^ (round - 1))
	# Starts at $500 and scales smoothly without skyrocketing instantly like 2^x
	SPIN_MONEY_THRESHOLD = int(BASE_MONEY_THRESHOLD * pow(THRESHOLD_GROWTH_FACTOR, current_round - 1))


func advance_round() -> void:
	current_round += 1
	spin_count = 0
	money_earned_this_round = 0
	update_money_threshold()
	print("[ROUND_SYS] Up time: ", current_round, " days", " | Current price of meal: $", SPIN_MONEY_THRESHOLD)


# --- LOADING AND SAVING ---

func save_game() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	#print(save_path)
	if file:
		var save_data = {
			"player_stats": player_stats,
			"current_round": current_round,
			"owned_charms": owned_charms_global,
			"shop_reroll_price": shop_reroll_price
		}
		file.store_var(save_data)
		#print("Game Saved!")


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		#print("No save file found.")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = file.get_var()
	
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("player_stats"):
			player_stats = data["player_stats"]
		if data.has("current_round"):
			current_round = data["current_round"]
		if data.has("owned_charms"):
			owned_charms_global = Array(data["owned_charms"], TYPE_STRING, "", null)
		if data.has("shop_reroll_price"):
			shop_reroll_price = data["shop_reroll_price"]
			
		update_money_threshold()
		print("System reboot! Round: ", current_round, " Target: $", SPIN_MONEY_THRESHOLD)


# --- MISC ---

func reset_data() -> void:
	player_stats = {
		"health": 400,
		"gold": 250,
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
	
	current_round = 1
	spin_count = 0
	money_earned_this_round = 0
	update_money_threshold()

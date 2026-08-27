extends Node

# --- Food Definitions ---
# Each food is a Dictionary with:
#   "name"        : String  - Display name
#   "description" : String  - Flavour text / buff description
#   "model_path"  : String  - Path to the 3D model GLB (optional, cosmetic)
#   "buff_key"    : String  - Identifier used by active_foods in GlobalData

const ALL_FOODS: Array = [
	{
		"name": "Lucky Bread",
		"description": "A golden loaf baked under a full moon.\n+0.5x payout multiplier on all wins.",
		"model_path": "",
		"buff_key": "lucky_bread"
	},
	{
		"name": "Power Soup",
		"description": "A hearty bowl that sharpens the senses.\nEarns +$50 bonus after every winning spin.",
		"model_path": "",
		"buff_key": "power_soup"
	},
	{
		"name": "Golden Apple",
		"description": "Crisp and glowing with fortune.\nReduces the money threshold each round by 100.",
		"model_path": "",
		"buff_key": "golden_apple"
	},
	{
		"name": "Spicy Pepper",
		"description": "Burns away bad luck.\nAny spin that earns $0 still gives back $25.",
		"model_path": "",
		"buff_key": "spicy_pepper"
	},
	{
		"name": "Mystic Mushroom",
		"description": "Strange and powerful.\nOne spin per round is doubled automatically.",
		"model_path": "",
		"buff_key": "mystic_mushroom"
	},
]

# Returns 3 unique random food definitions
func get_random_selection() -> Array:
	var pool = ALL_FOODS.duplicate()
	pool.shuffle()
	return pool.slice(0, 3)


# Apply a food buff's effect to the world (called when player picks a card)
func apply_food_buff(buff_key: String) -> void:
	# Avoid duplicates
	for food in GlobalData.active_foods:
		if food.get("buff_key") == buff_key:
			print("Food buff already active: ", buff_key)
			return

	var entry: Dictionary = {}
	match buff_key:
		"lucky_bread":
			entry = {
				"buff_key": buff_key,
				"apply_to_reward": func(payout: float) -> float:
					return payout * 1.5
			}
			print("Food Buff: Lucky Bread – 1.5x payout multiplier active!")

		"power_soup":
			entry = {
				"buff_key": buff_key,
				"win_bonus": 50
			}
			print("Food Buff: Power Soup – +$50 bonus on every winning spin!")

		"golden_apple":
			entry = {
				"buff_key": buff_key,
				"threshold_reduction": 100
			}
			GlobalData.SPIN_MONEY_THRESHOLD = max(0, GlobalData.SPIN_MONEY_THRESHOLD - 100)
			print("Food Buff: Golden Apple – threshold reduced to ", GlobalData.SPIN_MONEY_THRESHOLD)

		"spicy_pepper":
			entry = {
				"buff_key": buff_key,
				"zero_spin_payout": 25
			}
			print("Food Buff: Spicy Pepper – $25 guaranteed on zero-win spins!")

		"mystic_mushroom":
			entry = {
				"buff_key": buff_key,
				"double_used": false
			}
			print("Food Buff: Mystic Mushroom – one spin per round will be doubled!")

		_:
			entry = {"buff_key": buff_key}
			print("Warning: Unknown food buff '", buff_key, "'")

	GlobalData.active_foods.append(entry)

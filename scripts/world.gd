extends Node3D
@export var pause_menu: Control
@export var table_square_scene: PackedScene 
@export var bet_placed: int 

# Track bets using a Dictionary. Key: unique_bet_string, Value: Dictionary of bet data
@onready var tv: Node3D = $TV/Area3D # Adjust path if TV is nested under another node
@onready var video_player: VideoStreamPlayer = $TV/SubViewport/VideoStreamPlayer
var active_bets: Dictionary = {}
var tv_is_playing: bool = false
var roll_recived = int()
var time_passed: float = 0.0
# Array of dictionaries holding the value and the specific 3D scene for each chip size
var chip_tiers: Array = [
	{"amount": 10, "scene": preload("res://models/Glb/letitride.glb")},
	{"amount": 50, "scene": preload("res://models/Glb/letitride1.glb")},
	{"amount": 100, "scene": preload("res://models/Glb/letitride2.glb")},
	{"amount": 250, "scene": preload("res://models/Glb/letitride6.glb")},
	{"amount": 500, "scene": preload("res://models/Glb/letitride5.glb")},
	{"amount": 1000, "scene": preload("res://models/Glb/letitride3.glb")},
	{"amount": 2500, "scene": preload("res://models/Glb/letitride4.glb")},
]

# Tracks which chip tier is currently selected by the scroll wheel
var current_chip_index: int = 0
signal main_world_item_toggeled(item)
const FLOATING_TEXT_SCENE = preload("res://scenes/pop_up.tscn")

func spawn_text(spawn_position: Vector3, text: String) -> void:
	var popup = FLOATING_TEXT_SCENE.instantiate()
	# 1. Add to scene first (this triggers _ready() and assigns label/sprite/viewport)
	get_tree().current_scene.add_child(popup)
	# 2. Set position and display text AFTER it is added to the scene
	popup.global_position = spawn_position
	popup.display_text(text, 4.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Scroll up: Increase chip size, clamp to max array size
			current_chip_index = min(current_chip_index + 1, chip_tiers.size() - 1)
			print("Selected Chip Amount: ", chip_tiers[current_chip_index]["amount"])
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Scroll down: Decrease chip size, clamp to 0
			current_chip_index = max(current_chip_index - 1, 0)
			print("Selected Chip Amount: ", chip_tiers[current_chip_index]["amount"])

func _physics_process(delta: float) -> void:
	pass

func _ready():
	spawn_text(Vector3(0, 0, 0), "sixseven")
	###
	#connecting signals
	###
	video_player.finished.connect(_on_video_finished)
	tv.object_clicked.connect(_on_tv_clicked)
	
	if pause_menu:
		print("hiding pause menu")
		pause_menu.hide()
	else:
		print("_ready in main broken")


	for child in get_children():
		if child.has_signal("object_clicked") or child.has_signal("_on_object_unhovered") or child.has_signal("_on_object_clicked"):
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)
			
	var board_container = $Table_Scene
	
	for child in board_container.get_children():
		if child is Area3D:
			child.placing_requested.connect(_on_square_placing_requested)
			child.hover_entered.connect(_on_square_hover_entered)
			child.hover_exited.connect(_on_square_hover_exited)
			child.hover_moved.connect(_on_square_hover_moved)

# --- Receiver Functions ---

func _on_object_hovered(node):
	if node.item_info.has_bought == true:
		print("This item is called ", node.item_info.item_name, " and is worth ", node.item_info.item_value)
	elif node.item_info.has_bought == false:
		#create popup of info and colour change and increase in scale
		print("This item is called ", node.item_info.item_name, " and is worth ", node.item_info.item_value)
		pass
	else:
		print("uh you own and don't own this at the same time, kms")
		pass

func _on_object_unhovered(node):
	if node.item_info:
		print("Main World: stopped hovering over: ", node.item_info.item_name)

func _on_object_clicked(node):
	if not node or not "item_info" in node or not node.item_info:
		return
		
	var item_name = node.item_info.item_name

	# IGNORE THE BOWL/WHEEL HERE so world.gd doesn't treat it as a charm buy purchase!
	if item_name == "bowl":
		return

	var active_names = GlobalData.active_charms_global.map(func(charm): return charm.get("name", ""))
	if item_name in active_names:
		print("you already have this mr Jeff Bezos")
	elif GlobalData.player_stats.gold >= int(node.item_info.item_value):
		emit_signal("main_world_item_toggeled", node)
		GlobalData.player_stats.gold -= int(node.item_info.item_value)
	else:
		if GlobalData.player_stats.gold <= 0:
			print("Litttteraly out of money!!!!!! L skill issue")
		else:
			print("Too poor, speed please i need this my mom is kinda homeless")


# --- SIGNAL RECEIVERS ---

# Triggered when a player left-clicks a zone/square
# Added 'button_index' parameter to determine left vs. right click
func _on_square_placing_requested(play_type: String, origin_square_id: int, global_spawn_pos: Vector3, button_index: int) -> void:
	var bet_key = play_type + "_" + str(origin_square_id)
	
	# Grab the currently selected chip data based on the scroll wheel
	var selected_chip_data = chip_tiers[current_chip_index]
	var current_bet_amount = selected_chip_data["amount"]

	# ==========================================
	# RIGHT CLICK: CANCEL/REFUND BET
	# ==========================================
	if button_index == MOUSE_BUTTON_RIGHT:
		if active_bets.has(bet_key):
			var old_chip = active_bets[bet_key]["chip_node"]
			if is_instance_valid(old_chip):
				old_chip.queue_free() # Despawn the chip visual
				
			# Refund the ENTIRE stacked amount stored in the dictionary
			GlobalData.player_stats.gold += active_bets[bet_key]["amount"]
			active_bets.erase(bet_key)
			print("Bet removed: ", bet_key, ". Gold refunded.")
		else:
			print("No bet to cancel here.")

	# ==========================================
	# LEFT CLICK: PLACE NEW OR STACK BET
	# ==========================================
	elif button_index == MOUSE_BUTTON_LEFT:
		if GlobalData.player_stats.gold >= current_bet_amount:
			
			# IF BET ALREADY EXISTS -> STACK IT
			if active_bets.has(bet_key):
				GlobalData.player_stats.gold -= current_bet_amount
				active_bets[bet_key]["amount"] += current_bet_amount
				print("Bet stacked! Total on this spot: ", active_bets[bet_key]["amount"])
				# Note: Since you mentioned the model doesn't change when stacking, 
				# we just update the math above and do nothing visually.
				
			# ELSE -> PLACE A NEW UNIQUE BET
			else:
				GlobalData.player_stats.gold -= current_bet_amount
				
				# Instantiate the SPECIFIC chip visual chosen by the scroll wheel
				var new_chip = selected_chip_data["scene"].instantiate()
				add_child(new_chip)
				new_chip.global_position = global_spawn_pos

				# Force uniform scale across all loaded GLB models
				new_chip.scale = Vector3(0.167, 0.167, 0.167)
				
				# Store complete bet data
				active_bets[bet_key] = {
					"chip_node": new_chip,
					"play_type": play_type,
					"amount": current_bet_amount,
					"origin_square_id": origin_square_id
				}
				print("New bet placed! Remaining Gold: ", GlobalData.player_stats.gold)
		else:
			print("Not enough gold to place a bet of ", current_bet_amount, "!")

func _on_square_hover_entered(square_id: int) -> void:
	pass

func _on_square_hover_exited(square_id: int) -> void:
	pass

func _on_square_hover_moved(play_type: String, origin_square_id: int, global_pos: Vector3) -> void:
	pass
	

func _on_tv_clicked(clicked_node):
	print("World scene received click from: ", clicked_node.name)
	# Stop the video if it's already running, then play from the start
	if tv_is_playing:
		return
		
	tv_is_playing = true
	video_player.play()
		
func _on_video_finished() -> void:
	# Unlock input when the video ends so it can be clicked again
	tv_is_playing = false

# --- WHEEL SPIN & ROULETTE PAYOUT LOGIC ---

func _on_wheel_scene_numrolled(roll: Variant) -> void:
	roll_recived = int(roll)
	print("--- WHEEL RESULT: ", roll_recived, " ---")
	
	var round_winnings = 0.0
	
	# Evaluate every bet tracking key currently active on the board
	for bet_key in active_bets.keys():
		var bet_data = active_bets[bet_key]
		var play_type = bet_data["play_type"]
		var amount = bet_data["amount"]
		var square_id = bet_data["origin_square_id"]
		
		if evaluate_roulette_win(roll_recived, play_type, square_id):
			var multiplier = get_roulette_multiplier(play_type)
			# Payout formula: (Bet * Multiplier) + Original Bet returned
			var base_payout = (amount * multiplier) + amount
			
			# APPLY CHARM MULTIPLIERS HERE
			var payout = apply_charm_multipliers(base_payout)
			
			round_winnings += payout
			print("Bet ", bet_key, " WON! Base: $", base_payout, " | Paid with Charms: $", payout)
		else:
			print("Bet ", bet_key, " LOST.")
		
		# Clean up the chip visual now that the spin is finished
		if is_instance_valid(bet_data["chip_node"]):
			bet_data["chip_node"].queue_free()
			
	if round_winnings > 0:
		GlobalData.player_stats.gold += int(round_winnings)
		print("Total Payout Added to Wallet: $", round_winnings)
	
	# Clear out active bets registry for the next spin round
	active_bets.clear()
	
# Helper function to apply active charm rewards to any base payout
func apply_charm_multipliers(base_payout: float) -> float:
	var final_payout = base_payout
	
	for charm in GlobalData.active_charms_global:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_reward"):
			final_payout = charm.apply_to_reward.call(final_payout)
			
	return final_payout


# --- HELPER FUNCTIONS FOR ROULETTE RULES ---

func evaluate_roulette_win(roll: int, play_type: String, square_id: int) -> bool:
	var normalized_type = play_type.to_lower()
	
	# FIX 2: Smart String Parser 
	# Splits strings like "corner_7_8_10_11" into individual numbers and checks for a match
	if "_" in normalized_type:
		var parts = normalized_type.split("_")
		for part in parts:
			if part.is_valid_int() and int(part) == roll:
				# Found the rolled number inside the custom name identifier!
				return true
				
	# Context evaluation checking using the RouletteData Autoload
	if normalized_type.begins_with("straight"):
		return roll == square_id
	elif normalized_type.begins_with("corner"):
		# Math grid fallback if the string parser missed it (Assuming a standard 3 column setup)
		return roll == square_id or roll == (square_id + 1) or roll == (square_id + 3) or roll == (square_id + 4)
	elif normalized_type.begins_with("split"):
		return roll == square_id or roll == (square_id + 1) or roll == (square_id + 3)
	elif normalized_type.begins_with("red"):
		return roll in RouletteData.reds
	elif normalized_type.begins_with("black"):
		return roll in RouletteData.blacks
	elif normalized_type.begins_with("even"):
		return roll in RouletteData.evens
	elif normalized_type.begins_with("odd"):
		return roll in RouletteData.odds
	elif normalized_type.begins_with("low"):
		return roll in RouletteData.lows
	elif normalized_type.begins_with("high"):
		return roll in RouletteData.highs
	elif normalized_type.begins_with("dozen1"):
		return roll in RouletteData.first_dozen
	elif normalized_type.begins_with("dozen2"):
		return roll in RouletteData.second_dozen
	elif normalized_type.begins_with("dozen3"):
		return roll in RouletteData.third_dozen
		
	return roll == square_id


func get_roulette_multiplier(play_type: String) -> int:
	var normalized_type = play_type.to_lower()
	
	# Uses begins_with to properly calculate multipliers for names like "corner_7_8_10_11"
	if normalized_type.begins_with("straight"): return 35
	if normalized_type.begins_with("split"): return 17
	if normalized_type.begins_with("street"): return 11
	if normalized_type.begins_with("corner"): return 8 # Traditional European 8:1 payout
	if normalized_type.begins_with("six_line"): return 5
	if normalized_type.begins_with("dozen") or normalized_type.begins_with("column"): return 2
	if normalized_type.begins_with("red") or normalized_type.begins_with("black") or normalized_type.begins_with("even") or normalized_type.begins_with("odd") or normalized_type.begins_with("low") or normalized_type.begins_with("high"): return 1
	
	return 35


###
#credits:
#thanks to Maleficentcharacturmayhapsmourn
#thanks to Comestibles disssschaaaarger tycoooon
###

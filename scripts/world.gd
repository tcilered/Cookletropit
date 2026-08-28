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

# Food card popup
const FOOD_CARD_POPUP_SCENE = preload("res://scenes/food_card_popup.tscn")
var food_card_popup: CanvasLayer = null
signal main_world_item_toggeled(item)
const FLOATING_TEXT_SCENE = preload("res://scenes/pop_up.tscn")

func spawn_text(
	spawn_position: Vector3, 
	text: String, 
	custom_scale: Vector3 = Vector3.ONE, 
	move_camera: bool = false, 
	target_camera_position: Vector3 = Vector3.ZERO, 
	camera_duration: float = 1.5
) -> Node3D:
	var popup = FLOATING_TEXT_SCENE.instantiate() as FloatingText
	get_tree().current_scene.add_child(popup)
	popup.display_text(text, 4.0, custom_scale, spawn_position)
	
	if move_camera:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(camera, "global_position", target_camera_position, camera_duration)
	
	return popup

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Scroll up: Increase chip size, clamp to max array size
			current_chip_index = min(current_chip_index + 1, chip_tiers.size() - 1)
			print("[CHIP SELECT] Denomination set to $" + str(chip_tiers[current_chip_index]["amount"]))
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Scroll down: Decrease chip size, clamp to 0
			current_chip_index = max(current_chip_index - 1, 0)
			print("[CHIP SELECT] Denomination set to $" + str(chip_tiers[current_chip_index]["amount"]))

func _physics_process(delta: float) -> void:
	pass


func _ready():
	
	# --- STEP 1 ---
	# Spawn the first popup and wait for the player to click it
	var popup1 = spawn_text(Vector3(9.375,1.856,4.58), "Welcome to the table!")
	await popup1.tree_exited 
	
	
	# --- STEP 2 ---
	# Spawn the second popup
	var popup2 = spawn_text(Vector3(9.375,1.856,4.58), "Use the scroll wheel to change chips size and thus bet size.")
	await popup2.tree_exited
	
	var popup3 = spawn_text(Vector3(9.375,1.856,4.58), "Move around with WASD or move your mouse to the edge of the screen.")
	await popup3.tree_exited

# --- STEP 4 ---
	var popup4 = spawn_text(
		Vector3(9.375, 1.856, 4.58),
		".",
		Vector3.ONE,
		true,
		Vector3(11.1, 4, -2.3),
		1.5
	)
	await popup4.tree_exited
	
	var popup7 = spawn_text(Vector3(9.375,1.856,4.58), "Click on the gray triangle to vist the shop and to get back. You can only buy 1 item per round and each reroll triples in price each time.")
	await popup7.tree_exited 

	# --- STEP 5 ---
	var popup5 = spawn_text(
		Vector3(9.375, 2.5, 4.58),
		"Click on the gray triangle to vist the shop and to get back. You can only buy 1 item per round and each reroll triples in price each time.",
		Vector3.ONE,
		true,
		Vector3(9.375, 5, 6.196),
		1.5
	)
	await popup5.tree_exited

	var popup9 = spawn_text(
		Vector3(9.375, 2.5, 4.58),
		"You can bet on the other squares, like colors, odd, evens, 1st, 2nd, or 3rd dozen, or the 12 tall columns.",
		Vector3.ONE,
		true,
		Vector3(9.375, 5, 6.196),
		1.5
	)
	await popup9.tree_exited

	var popup6 = spawn_text(
		Vector3(9.375, 2.5, 4.58),
		"Click straight on a numbered square to make a bet, you can split between two by clicking an edge, or 4 by clicking a corner.",
		Vector3.ONE,
		true,
		Vector3(9.375, 5, 6.196),
		1.5
	)
	await popup6.tree_exited

	var popup8 = spawn_text(Vector3(9.375,1.856,4.58), "Click on the wheel to spin and test your luck, your wins and losses are displayed on the TV.")
	await popup8.tree_exited 

	var popup10 = spawn_text(Vector3(9.375,1.856,4.58), "Your goal is to try to make enough money to afford food each day(4spins). If you don't get enough money you starve, survive for as long as you can against escalating food prices!")
	await popup10.tree_exited 

	print("[SYSTEM] Tutorial complete. System ready.")

	# Spawn the food card popup (hidden until needed)
	food_card_popup = FOOD_CARD_POPUP_SCENE.instantiate()
	add_child(food_card_popup)
	food_card_popup.food_selected.connect(_on_food_selected)
	var all_shops = get_tree().get_nodes_in_group("shops")
	for shop in all_shops:
		if shop.has_signal("charm_purchase_requested"):
			shop.charm_purchase_requested.connect(_on_shop_charm_purchase_requested)
	###
	#connecting signals
	###
	video_player.finished.connect(_on_video_finished)
	tv.object_clicked.connect(_on_tv_clicked)
	
	if pause_menu:
		print("[UI] Pause menu initialized.")
		pause_menu.hide()
	else:
		print("[ERROR] Failed to locate pause menu component.")


	for child in get_children():
		if child.has_signal("object_clicked") or child.has_signal("_on_object_unhovered") or child.has_signal("_on_object_clicked"):
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)

	for child in get_children():
		if child.has_signal("charm_purchase_requested"):
			child.charm_purchase_requested.connect(_on_shop_charm_purchase_requested)
			
	var board_container = $Table_Scene
	
	for child in board_container.get_children():
		if child is Area3D:
			child.placing_requested.connect(_on_square_placing_requested)
			child.hover_entered.connect(_on_square_hover_entered)
			child.hover_exited.connect(_on_square_hover_exited)
			child.hover_moved.connect(_on_square_hover_moved)

# --- Receiver Functions ---

func _on_object_hovered(node):
	if node.get("item_info") == null:
		return
	if node.item_info.has_bought == true:
		print("[INSPECT] " + str(node.item_info.item_name) + " (Owned) | Value: $" + str(node.item_info.item_value))
	elif node.item_info.has_bought == false:
		print("[INSPECT] " + str(node.item_info.item_name) + " | Price: $" + str(node.item_info.item_value))
		pass
	else:
		print("[WARNING] Item ownership state corrupted.")
		pass

func _on_object_unhovered(node):
	if node.get("item_info") != null:
		print("[INSPECT] Target unselected: " + str(node.item_info.item_name))

# worl.gd
func _on_object_clicked(node):
	# Let shop.gd handle charm purchases directly; do not process shop items here.
	if node.get("item_info") != null:
		var item_name = node.item_info.item_name
		if item_name != "bowl" and item_name != "ShopReroll":
			return # Handled by shop.gd
			
	_try_purchase_charm(node)

func _try_purchase_charm(node) -> bool:
	if not node or node.get("item_info") == null:
		return false
		
	var item_name = node.item_info.item_name

	if item_name == "bowl" or item_name == "ShopReroll":
		return false

	var owned_names: Array[String] = GlobalData.owned_charms_global.duplicate()
	for charm in GlobalData.active_charms_global:
		var charm_name := str(charm.get("name", ""))
		if charm_name != "" and charm_name not in owned_names:
			owned_names.append(charm_name)

	if item_name in owned_names:
		print("[SHOP ERROR] Item already owned: " + str(item_name))
		return false
	elif GlobalData.player_stats.gold >= int(node.item_info.item_value):
		node.item_info.has_bought = true
		if item_name not in GlobalData.owned_charms_global:
			GlobalData.owned_charms_global.append(item_name)
		emit_signal("main_world_item_toggeled", node)
		GlobalData.player_stats.gold -= int(node.item_info.item_value)
		return true
	else:
		if GlobalData.player_stats.gold <= 0:
			print("[SHOP ERROR] Funds depleted. Cannot afford " + str(item_name) + ".")
		else:
			print("[SHOP ERROR] Insufficient funds for " + str(item_name) + ".")
		return false
		
		
# worl.gd
func _on_shop_charm_purchase_requested(node: Node) -> void:
	if not node or node.get("item_info") == null:
		return
		
	var item_name: String = node.item_info.item_name
	
	# Pass charm to WheelScene to construct functional closures
	var wheel = get_node_or_null("WheelScene") # Adjust path if needed
	if wheel and wheel.has_method("add_charm"):
		wheel.add_charm(item_name)
	else:
		push_warning("WheelScene not found or missing add_charm method!")

	if item_name == "CouponCharm" or item_name == "RerollResetCharm":
		GlobalData.shop_reroll_price = 100


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
			print("[BET CANCELLED] Refunded $" + str(active_bets[bet_key]["amount"]) + " from " + str(bet_key) + ".")
		else:
			print("[BET ERROR] No active bet found on " + str(bet_key) + ".")

	# ==========================================
	# LEFT CLICK: PLACE NEW OR STACK BET
	# ==========================================
	elif button_index == MOUSE_BUTTON_LEFT:
		if GlobalData.player_stats.gold >= current_bet_amount:
			
			# IF BET ALREADY EXISTS -> STACK IT
			if active_bets.has(bet_key):
				GlobalData.player_stats.gold -= current_bet_amount
				active_bets[bet_key]["amount"] += current_bet_amount
				print("[BET STACKED] " + str(bet_key) + " total now $" + str(active_bets[bet_key]["amount"]))
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
				print("[BET PLACED] $" + str(current_bet_amount) + " on " + str(bet_key) + ". Total balance: $" + str(GlobalData.player_stats.gold))
		else:
			print("[BET ERROR] Insufficient funds to place $" + str(current_bet_amount) + " bet.")

func _on_square_hover_entered(square_id: int) -> void:
	pass

func _on_square_hover_exited(square_id: int) -> void:
	pass

func _on_square_hover_moved(play_type: String, origin_square_id: int, global_pos: Vector3) -> void:
	pass
	

func _on_tv_clicked(clicked_node):
	print("[SYSTEM] Feed activated from source: " + str(clicked_node.name))
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
	print("\n=== WHEEL SPIN RESULT: [" + str(roll_recived) + "] ===")
	
	var round_winnings = 0.0
	var had_any_win = false
	
	# Evaluate every bet tracking key currently active on the board
	for bet_key in active_bets.keys():
		var bet_data = active_bets[bet_key]
		var play_type = bet_data["play_type"]
		var amount = bet_data["amount"]
		var square_id = bet_data["origin_square_id"]
		
		if evaluate_roulette_win(roll_recived, play_type, square_id):
			had_any_win = true
			var multiplier = get_roulette_multiplier(play_type)
			# Payout formula: (Bet * Multiplier) + Original Bet returned
			var base_payout = (amount * multiplier) + amount
			
			# APPLY CHARM MULTIPLIERS HERE
			var payout = apply_charm_multipliers(base_payout)
			
			# Apply food: power_soup win_bonus
			for food in GlobalData.active_foods:
				if food.get("buff_key") == "power_soup":
					payout += food.get("win_bonus", 0)
			
			# Apply food: mystic_mushroom — double one spin per round
			for food in GlobalData.active_foods:
				if food.get("buff_key") == "mystic_mushroom" and not food.get("double_used", true):
					payout *= 2.0
					food["double_used"] = true
					print("[BUFF EVENT] Mystic Mushroom applied: Payout doubled.")
					break
			
			round_winnings += payout
			print("[WIN] " + str(bet_key) + " paid out $" + str(payout) + " (Base: $" + str(base_payout) + ")")
		else:
			print("[LOSS] " + str(bet_key) + " ($" + str(amount) + ")")
		
		# Clean up the chip visual now that the spin is finished
		if is_instance_valid(bet_data["chip_node"]):
			bet_data["chip_node"].queue_free()
	
	# Apply food: spicy_pepper — if no winnings this spin, give guaranteed payout
	if round_winnings == 0:
		for food in GlobalData.active_foods:
			if food.get("buff_key") == "spicy_pepper":
				round_winnings += food.get("zero_spin_payout", 0)
				if round_winnings > 0:
					print("[BUFF EVENT] Spicy Pepper granted $" + str(food.get("zero_spin_payout", 0)) + " consolation bonus.")
				break

	if round_winnings > 0:
		GlobalData.player_stats.gold += int(round_winnings)
		print("[CREDITS ADDED] Wallet credited with $" + str(round_winnings) + ".")
	
	# Track round money and spin count
	GlobalData.money_earned_this_round += int(round_winnings)
	GlobalData.spin_count += 1
	
	print("[STATUS] Spin " + str(GlobalData.spin_count) + "/" + str(GlobalData.SPINS_PER_ROUND) + " complete. Current earnings: $" + str(GlobalData.money_earned_this_round) + " / Target: $" + str(GlobalData.SPIN_MONEY_THRESHOLD) + "\n")
	
	# Clear out active bets registry for the next spin round
	active_bets.clear()
	
	# Check round end condition
	if GlobalData.spin_count >= GlobalData.SPINS_PER_ROUND:
		if GlobalData.money_earned_this_round >= GlobalData.SPIN_MONEY_THRESHOLD:
			print("[ROUND CLEARED] Target met. Proceeding to food selection...")
			# Reset mystic_mushroom double flag for next round
			for food in GlobalData.active_foods:
				if food.get("buff_key") == "mystic_mushroom":
					food["double_used"] = false
			# Reset round counters then show food selection
			GlobalData.spin_count = 0
			GlobalData.money_earned_this_round = 0
			_refresh_shop_for_new_round()
			food_card_popup.show_popup()
		else:
			print("[ROUND FAILED] Target not met. Bankrupt.")
			spawn_text(Vector3(0, 1, 0), "GAME OVER! You didn't earn $" + str(GlobalData.SPIN_MONEY_THRESHOLD) + " in 4 spins!")
			await get_tree().create_timer(3.0).timeout
			GlobalData.reset_data()
			get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
	
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

func _refresh_shop_for_new_round() -> void:
	for child in get_children():
		if child.has_method("start_new_round"):
			child.start_new_round()
			return


###
#credits:
#thanks to Maleficentcharacturmayhapsmourn
#thanks to Comestibles disssschaaaarger tycoooon
###

# --- FOOD SELECTION CINEMATIC ---
@export var food_model_scale: Vector3 = Vector3(2.67, 2.67, 2.67) # Adjust default scale as needed

# --- FOOD SELECTION CINEMATIC ---
func _on_food_selected(buff_key: String, model_path: String) -> void:
	# Apply the buff first
	FoodData.apply_food_buff(buff_key)

	# Get references
	var camera_node: Node3D = $Cameranode
	var move_to_chute: Marker3D = $move_to_chute
	var food_spawn: Marker3D = $chute_food_spawn

	# Remember where the camera was
	var original_position: Vector3 = camera_node.global_position
	var original_rotation: Vector3 = camera_node.rotation

	# 1 — Move camera to the chute viewpoint (position + rotation)
	var tween_to = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	tween_to.tween_property(camera_node, "global_position", move_to_chute.global_position, 1.2)
	tween_to.tween_property(camera_node, "rotation", move_to_chute.rotation, 1.2)
	await tween_to.finished

	# 2 — Spawn the food model at the spawn marker
	var food_node: Node3D = null
	if model_path != "":
		var packed: PackedScene = load(model_path) as PackedScene
		if packed:
			food_node = packed.instantiate()
			food_spawn.add_child(food_node)
			food_node.position = Vector3.ZERO
			
			# APPLY SCALE HERE
			food_node.scale = food_model_scale
			
			print("[DELIVERY] Item dispatched to chute: " + "'", buff_key, "'")
		else:
			push_warning("_on_food_selected: could not construct emulated food structure correctly: " + model_path)

	# 3 — Show food for 2.5 seconds
	await get_tree().create_timer(2.5).timeout

	# 4 — Despawn the model
	if is_instance_valid(food_node):
		food_node.queue_free()

	# 5 — Sit at chute for 4 more seconds
	await get_tree().create_timer(4.0).timeout

	# 6 — Return camera to original position and rotation
	var tween_back = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	tween_back.tween_property(camera_node, "global_position", original_position, 1.2)
	tween_back.tween_property(camera_node, "rotation", original_rotation, 1.2)
	await tween_back.finished

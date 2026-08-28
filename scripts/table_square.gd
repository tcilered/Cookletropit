extends Area3D

# FIX 1: Added 'button_index' to the signal declaration
signal placing_requested(play_type, square_id, global_spawn_pos, button_index)
signal hover_entered(square_id)
signal hover_exited(square_id)
signal hover_moved(play_type, square_id, global_pos)

@export var square_id: int = 17

# --- NEW: EXPORT GROUP FOR SPECIAL BETS ---
@export_group("Special Outside Bet")
@export_enum("none", "even", "odd", "red", "black", "dozen1", "dozen2", "dozen3", "column1", "column2", "column3", "low", "high") var special_bet_type: String = "none"
# ------------------------------------------

@export_group("Identification")
@export_enum("red", "black", "green") var square_colour: String = "red"
@export_group("Roulette Logic")
@export_enum("none", "1st Column", "2nd Column", "3rd Column") var column: String = "none"
@export_enum("none", "1st Dozen", "2nd Dozen", "3rd Dozen") var dozen: String = "none"
@export_enum("none", "1-18 (Low)", "19-36 (High)") var range_half: String = "none"
@export var is_even: bool = false

var current_hover_zone: String = "none"

func get_shared_border_dynamic(zone: String) -> String:
	# --- NEW: OVERRIDE FOR OUTSIDE BETS ---
	# If this is a special bet, skip ALL edge/corner math and just return the bet name.
	if special_bet_type != "none":
		return special_bet_type
	# --------------------------------------

	if zone == "center":
		return "straight_" + str(square_id)
		
	var adjacent_id = -1
	
	# INVERTED MATH: 
	# 1, 4, 7 are now mapped as the TOP edge.
	# 3, 6, 9 are now mapped as the BOTTOM edge.
	var is_top_edge = (square_id % 3 == 1)    
	var is_bottom_edge = (square_id % 3 == 0) 
	
	# 1. Figure out what number is on the other side
	match zone:
		"edge_right": 
			adjacent_id = square_id + 3
		"edge_left": 
			adjacent_id = square_id - 3
		"edge_top": 
			if not is_top_edge:
				adjacent_id = square_id - 1 # Moving UP now subtracts 1
		"edge_bottom": 
			if not is_bottom_edge:
				adjacent_id = square_id + 1 # Moving DOWN now adds 1
				
		# Corners have also been fully inverted to match the new vertical layout
		"corner_top_right":
			if not is_top_edge:
				return get_corner_string(square_id, square_id-1, square_id+3, square_id+2)
		"corner_bottom_right":
			if not is_bottom_edge:
				return get_corner_string(square_id, square_id+1, square_id+3, square_id+4)
		"corner_top_left":
			if not is_top_edge:
				return get_corner_string(square_id, square_id-1, square_id-3, square_id-4)
		"corner_bottom_left":
			if not is_bottom_edge:
				return get_corner_string(square_id, square_id+1, square_id-3, square_id-2)

	# 2. Check if the adjacent square is a valid number (1-36)
	if adjacent_id >= 1 and adjacent_id <= 36:
		var min_id = min(square_id, adjacent_id)
		var max_id = max(square_id, adjacent_id)
		return "split_%d_%d" % [min_id, max_id]
		
	# Handle edges that touch the 0/00 or the outside of the board
	return "board_edge_" + zone + "_on_" + str(square_id)

func get_corner_string(a: int, b: int, c: int, d: int) -> String:
	var nums = [a, b, c, d]
	nums.sort()
	return "corner_%d_%d_%d_%d" % [nums[0], nums[1], nums[2], nums[3]]

func _ready():
	var mesh_node = get_node("17_Mesh") # Note: You might want to make this dynamic later
	var mat = mesh_node.get_active_material(0)
	
	if mat:
		var unique_mat = mat.duplicate()
		mesh_node.set_surface_override_material(0, unique_mat)
		
		if square_colour == "red":
			unique_mat.albedo_color = Color("b61412")
		elif square_colour == "black":
			unique_mat.albedo_color = Color("000000")

func _on_mouse_entered():
	print("[SYSTEM]: Cursor focus gained on Square #", square_id)
	hover_entered.emit(square_id)

func _on_mouse_exited():
	print("[SYSTEM]: Cursor focus lost on Square #", square_id)
	current_hover_zone = "none"
	hover_exited.emit(square_id)

# ADDED underscores to unused parameters to fix warnings
func _input_event(_camera, event, click_position, _click_normal, _shape_idx):
	var local_pos = to_local(click_position)
	var edge_margin = 0.35 
	
	var on_right = local_pos.x > edge_margin
	var on_left = local_pos.x < -edge_margin
	var on_top = local_pos.z > edge_margin 
	var on_bottom = local_pos.z < -edge_margin
	
	var detected_zone = "center"
	
	if on_right and on_top: detected_zone = "corner_top_right"
	elif on_right and on_bottom: detected_zone = "corner_bottom_right"
	elif on_left and on_top: detected_zone = "corner_top_left"
	elif on_left and on_bottom: detected_zone = "corner_bottom_left"
	elif on_right: detected_zone = "edge_right"
	elif on_left: detected_zone = "edge_left"
	elif on_top: detected_zone = "edge_top"
	elif on_bottom: detected_zone = "edge_bottom"
	
	if event is InputEventMouseMotion:
		if current_hover_zone != detected_zone:
			current_hover_zone = detected_zone
			# Convert the raw edge into the unified string before emitting
			var unified_zone = get_shared_border_dynamic(detected_zone)
			#print("[BETTING CONSOLE]: Targeted zone changed to '", unified_zone, "' (Square #", square_id, ")")
			hover_moved.emit(unified_zone, square_id, click_position)

	# FIX 2: Check for ANY mouse button press, then filter for Left or Right
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			# Convert the raw edge into the unified string before emitting
			var unified_zone = get_shared_border_dynamic(detected_zone)
			
			# Just for debugging: Print different messages based on the click
			var action_str = "BET PLACED" if event.button_index == MOUSE_BUTTON_LEFT else "BET REFUNDED"
			print("[BETTING CONSOLE]: Client chose -> ", action_str, " | Target: ", unified_zone)#add for bug testing" | Position: ", click_position 
			
			# Emit the signal with all 4 expected arguments!
			placing_requested.emit(unified_zone, square_id, click_position, event.button_index)

extends Area3D

signal placing_requested(play_type, square_id, global_spawn_pos)
signal hover_entered(square_id)
signal hover_exited(square_id)
signal hover_moved(play_type, square_id, global_pos)

@export var square_id: int = 17
var current_hover_zone: String = "none"

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	print("--- Mouse Entered Square: ", square_id, " ---")
	hover_entered.emit(square_id)

func _on_mouse_exited():
	print("--- Mouse Exited Square: ", square_id, " ---")
	current_hover_zone = "none"
	hover_exited.emit(square_id)

func _input_event(camera, event, click_position, click_normal, shape_idx):
	# 1. Math: Convert world position to local space
	var local_pos = to_local(click_position)
	var edge_margin = 0.35 
	
	var on_right = local_pos.x > edge_margin
	var on_left = local_pos.x < -edge_margin
	var on_top = local_pos.z > edge_margin 
	var on_bottom = local_pos.z < -edge_margin
	
	# 2. Logic: Determine the specific zone
	var detected_zone = "center"
	
	if on_right and on_top: detected_zone = "corner_top_right"
	elif on_right and on_bottom: detected_zone = "corner_bottom_right"
	elif on_left and on_top: detected_zone = "corner_top_left"
	elif on_left and on_bottom: detected_zone = "corner_bottom_left"
	elif on_right: detected_zone = "edge_right"
	elif on_left: detected_zone = "edge_left"
	elif on_top: detected_zone = "edge_top"
	elif on_bottom: detected_zone = "edge_bottom"

	# 3. Debug Print for Hovering
	if event is InputEventMouseMotion:
		if current_hover_zone != detected_zone:
			current_hover_zone = detected_zone
			print("Hovering Zone: ", detected_zone, " on Square: ", square_id)
			hover_moved.emit(current_hover_zone, square_id, click_position)

	# 4. Debug Print for PLACING
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("PLACED PLAY: '", detected_zone, "' at global position: ", click_position)
		placing_requested.emit(detected_zone, square_id, click_position)

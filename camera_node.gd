extends Node3D

@export_group("Movement Settings")
@export var pan_speed: float = 5.0
@export var edge_margin: float = 96.7

@export_group("Tilt Settings")
@export var max_tilt_degrees: float = 16.7 # Max degrees to lean from moving
@export var stretch_tilt_degrees: float = 10.67 # Extra degrees to lean when hitting the rubber-band stretch
@export var tilt_in_speed: float = 6.7 # How fast it leans when you START moving
@export var tilt_return_speed: float = 1.5 # How slowly it flattens back out when you STOP moving

@export_group("Map Limits")
@export var limit_radius: float = 4.0 # The maximum distance the camera can travel from the center (0, 0, 0)

@export_group("Stretch Settings")
@export var max_stretch: float = 1.67 
@export var snap_back_speed: float = 4.0 # Resistance speed while actively pushing against the boundary
@export var idle_snap_back_speed: float = 67 # How slowly the position returns when you let go at the edge

# Track if the window is currently active
var is_window_focused: bool = true

func _ready():
	# Confine the mouse to the window so it can hit the edges without leaving the game
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

# Detect when the player Alt-Tabs or clicks a different window
func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# Free the mouse and tell the script to stop panning
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_window_focused = false
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		# Trap the mouse inside the window again
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		is_window_focused = true

# Allow manual release via Escape
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_window_focused = false
		
	if event is InputEventMouseButton and event.pressed:
		if is_window_focused == false:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			is_window_focused = true

func _process(delta: float) -> void:
	# --- Apply Movement ---
	# We use abs() > 0.05 to ignore microscopic floating-point errors
	var is_actively_moving = abs(move_x) > 0.05 or abs(move_y) > 0.05
	
	if is_actively_moving:
		var cam_right = cam.global_transform.basis.x
		var cam_up = cam.global_transform.basis.y
		
		# Lock depth (Y-axis)
		cam_right.y = 0.0
		cam_up.y = 0.0
		
		cam_right = cam_right.normalized()
		cam_up = cam_up.normalized()
		
		var move_dir = (cam_right * move_x) + (cam_up * move_y)
		
		if move_dir.length() > 1.0:
			move_dir = move_dir.normalized()
			
		global_position += move_dir * pan_speed * delta

	# --- Calculate Hard Limits (Circular) ---
	var current_pos_2d = Vector2(global_position.x, global_position.z)
	var target_pos_2d = current_pos_2d
	
	if current_pos_2d.length() > limit_radius:
		target_pos_2d = current_pos_2d.normalized() * limit_radius
		
	var target_x = target_pos_2d.x
	var target_z = target_pos_2d.y

	# --- Dynamic Edge & Stretch Tilting ---
	var extra_tilt_x: float = 0.0
	var extra_tilt_z: float = 0.0
	
	if max_stretch > 0.0:
		var stretch_ratio_x = (global_position.x - target_x) / max_stretch
		var stretch_ratio_z = (global_position.z - target_z) / max_stretch
		
		extra_tilt_x = -stretch_ratio_z * stretch_tilt_degrees
		extra_tilt_z = -stretch_ratio_x * stretch_tilt_degrees

	var target_tilt_x = deg_to_rad((move_y * max_tilt_degrees) + extra_tilt_x)
	var target_tilt_z = deg_to_rad((-move_x * max_tilt_degrees) + extra_tilt_z)
	
	var current_tilt_speed = tilt_in_speed if is_actively_moving else tilt_return_speed
	
	rotation.x = lerp_angle(rotation.x, target_tilt_x, current_tilt_speed * delta)
	rotation.z = lerp_angle(rotation.z, target_tilt_z, current_tilt_speed * delta)

	# --- Elastic Stretch Clamping (Circular) ---
	var current_snap_speed = snap_back_speed if is_actively_moving else idle_snap_back_speed

	if global_position.x != target_x:
		global_position.x = lerp(global_position.x, target_x, current_snap_speed * delta)
		
	if global_position.z != target_z:
		global_position.z = lerp(global_position.z, target_z, current_snap_speed * delta)
		
	var max_allowed_radius = limit_radius + max_stretch
	var final_pos_2d = Vector2(global_position.x, global_position.z)
	
	if final_pos_2d.length() > max_allowed_radius:
		final_pos_2d = final_pos_2d.normalized() * max_allowed_radius
		global_position.x = final_pos_2d.x
		global_position.z = final_pos_2d.y

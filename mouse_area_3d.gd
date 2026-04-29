extends Area3D

func _ready():
	# Connect the built-in mouse signals to our custom functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Connect the input_event signal to detect clicks
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	print("Mouse hovered over the 3D object!")
	
	# Make the object slightly larger uniformly across X, Y, and Z axes
	# (Note: You might want to change this to Vector3(1.1, 1.1, 1.1) to actually enlarge it!)
	scale = Vector3(1, 1, 1) 
	
	# 1. Target the visual node named "cube" (lowercase c)
	var base_material = $Cube.mesh.surface_get_material(0)
	
	if base_material:
		var hover_material = base_material.duplicate()
		hover_material.albedo_color = Color(1, 0, 0) # Red
		
		# 2. Apply it to the visual node named "cube"
		$Cube.set_surface_override_material(0, hover_material)

func _on_mouse_exited():
	print("Mouse left the 3D object.")
	GlobalData.player_stats.gold += 1
	
	scale = Vector3(1.0, 1.0, 1.0)
	
	# Remove the override from the visual node named "cube" to revert the color
	$Cube.set_surface_override_material(0, null)

# --- NEW FUNCTION FOR CLICK DETECTION ---
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	# Check if the event is a mouse button event
	if event is InputEventMouseButton:
		# Check if the left mouse button was clicked (pressed down)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("3D Object was clicked!")
			
			# Add whatever you want to happen on click here!
			# For example: GlobalData.player_stats.gold += 10

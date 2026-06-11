extends Area3D

# The Resource that holds all this item's specific data
@export var item_info: ItemData 

# Define custom signals that carry the object (self) to the main world
signal object_hovered(interacted_node)
signal object_unhovered(interacted_node)
signal object_clicked(interacted_node)

func _apply_texture_to_all_meshes(current_node: Node, texture: Texture2D):
	if current_node is MeshInstance3D:
		# Material override ensures everything uses this texture
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = texture
		current_node.material_override = mat
		
	for child in current_node.get_children():
		_apply_texture_to_all_meshes(child, texture)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	if item_info != null and item_info.item_mesh != null:
		# 1. Instantiate the scene (spawns the whole roulette wheel)
		var spawned_wheel = item_info.item_mesh.instantiate()
		add_child(spawned_wheel)
		
		# 2. To apply a custom texture dynamically to everything in the scene:
		if item_info.surface_texture != null:
			_apply_texture_to_all_meshes(spawned_wheel, item_info.surface_texture)

		# 3. Create collision from the spawned wheel
		# (Note: If your roulette_wheel.glb already had collision enabled when importing, 
		# you might not even need this step!)
func _on_mouse_entered():
	object_hovered.emit(self)

func _on_mouse_exited():
	object_unhovered.emit(self)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	# Check for a left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 1. Unconditional print so you ALWAYS know the click registered
		print("Area3D was clicked!") 
		
		# 2. Check if the resource is there
		if item_info != null:
			print(" -> Attached Resource: ", item_info.item_name)
		else:
			print(" -> WARNING: item_info is empty! Drag a .tres file into the Inspector.")
			
		# 3. Emit the signal to the world regardless
		object_clicked.emit(self)

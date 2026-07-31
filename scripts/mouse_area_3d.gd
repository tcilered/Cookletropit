extends Area3D

# The Resource that holds all this item's specific data
@export var item_info: ItemData 

# Define custom signals that carry the object (self) to the main world
signal object_hovered(interacted_node)
signal object_unhovered(interacted_node)
signal object_clicked(interacted_node)

func _apply_texture_to_all_meshes(current_node: Node, texture: Texture2D):
	if current_node is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = texture
		current_node.material_override = mat
		
	for child in current_node.get_children():
		_apply_texture_to_all_meshes(child, texture)

# Helper function to find meshes and build collision shapes
func _generate_collision_from_scene(current_node: Node):
	if current_node is MeshInstance3D:
		if current_node.mesh != null:
			# --- FIX 1: Ignore accidental cone/placeholder meshes if named or structured weirdly ---
			# If a specific mesh causes problems (like the TV), you can filter it out by name:
			if "Cone" in current_node.name or "Placeholder" in current_node.name:
				print("Skipping unintended mesh for collision: ", current_node.name)
				# Continue the loop for other children instead of returning early
				for child in current_node.get_children():
					_generate_collision_from_scene(child)
				return

			var collision_shape_data = current_node.mesh.create_convex_shape()
			
			var col_shape_node = CollisionShape3D.new()
			col_shape_node.shape = collision_shape_data
			
			# --- FIX 2: Apply the mesh's local transform so nested/offset meshes align correctly ---
			# This fixes the model that was off by half its height because its MeshInstance3D 
			# had a local offset/translation relative to the root node of the scene.
			col_shape_node.transform = current_node.transform
			
			add_child(col_shape_node)
			
	for child in current_node.get_children():
		_generate_collision_from_scene(child)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	if item_info != null and item_info.item_mesh != null:
		var spawned_wheel = item_info.item_mesh.instantiate()
		add_child(spawned_wheel)
		
		if item_info.surface_texture != null:
			_apply_texture_to_all_meshes(spawned_wheel, item_info.surface_texture)

		# 3. Handle Collision Setup
		if item_info.custom_collision_shape != null:
			var col_shape_node = CollisionShape3D.new()
			col_shape_node.shape = item_info.custom_collision_shape
			
			var vertical_offset: float = 0.5
			
			if item_info.custom_collision_shape is CapsuleShape3D:
				vertical_offset = item_info.custom_collision_shape.height / 2
			elif item_info.custom_collision_shape is CylinderShape3D:
				vertical_offset = item_info.custom_collision_shape.height / 2
			elif item_info.custom_collision_shape is BoxShape3D:
				vertical_offset = item_info.custom_collision_shape.size.y / 2
				
			col_shape_node.position.y += vertical_offset
			
			add_child(col_shape_node)
			print("Using custom defined shape for: ", item_info.item_name)
		else:
			_generate_collision_from_scene(spawned_wheel)
			print("Auto-generating shape from mesh for: ", item_info.item_name)

func _on_mouse_entered():
	object_hovered.emit(self)

func _on_mouse_exited():
	object_unhovered.emit(self)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Area3D was clicked!") 
		if item_info != null:
			print(" -> Attached Resource: ", item_info.item_name)
		else:
			print(" -> WARNING: item_info is empty! Drag a .tres file into the Inspector.")
		object_clicked.emit(self)

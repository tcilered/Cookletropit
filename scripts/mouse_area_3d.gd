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

# Helper function to find meshes and build collision shapes
func _generate_collision_from_scene(current_node: Node):
	if current_node is MeshInstance3D:
		if current_node.mesh != null:
			# Choose your shape generation type:
			# OPTION A: Convex shape (Best for performance/simple shapes)
			var collision_shape_data = current_node.mesh.create_convex_shape()
			
			# OPTION B: Trimesh shape (Precise, matches complex geometry exactly but heavier)
			# var collision_shape_data = current_node.mesh.create_trimesh_shape()
			
			# Create the CollisionShape3D node
			var col_shape_node = CollisionShape3D.new()
			col_shape_node.shape = collision_shape_data
			
			# Match the position and rotation of the mesh inside the spawned scene
			col_shape_node.global_transform = current_node.global_transform
			
			# Add it as a child of this Area3D so it acts as its collision body
			add_child(col_shape_node)
			
	# Recursively search through children in case the mesh is nested deep inside the .tscn
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
			
			# --- FIX THE HALF-LENGTH OFFSET ---
			# Calculate how much to lift the shape based on its specific type
			var vertical_offset: float = 0.25
			
			if item_info.custom_collision_shape is CapsuleShape3D:
				vertical_offset = item_info.custom_collision_shape.height / 2.0
			elif item_info.custom_collision_shape is CylinderShape3D:
				vertical_offset = item_info.custom_collision_shape.height / 2.0
			elif item_info.custom_collision_shape is BoxShape3D:
				vertical_offset = item_info.custom_collision_shape.size.y / 2.0
				
			# Apply the offset to the local position so it shifts up relative to the mesh base
			col_shape_node.position.y += vertical_offset
			# ----------------------------------
			
			add_child(col_shape_node)
			print("Using custom defined shape for: ", item_info.item_name)
		else:
			# Fallback: if no custom shape is set, auto-generate it from the mesh vertices
			_generate_collision_from_scene(spawned_wheel)
			print("Auto-generating shape from mesh for: ", item_info.item_name)
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

extends Area3D

# The Resource that holds all this item's specific data
@export var item_info: ItemData 

# Define custom signals that carry the object (self) to the main world
signal object_hovered(interacted_node)
signal object_unhovered(interacted_node)
signal object_clicked(interacted_node)

# --- Spin Settings ---
@export var spin_angle_degrees: float = 720.0
@export var spin_duration: float = 2.0

# Track the instantiated mesh scene so we can easily animate/rotate it
var _spawned_model_instance: Node3D = null

# Hover pickup animation state
var _rest_model_position: Vector3 = Vector3.ZERO
var _rest_model_rotation: Vector3 = Vector3.ZERO
var _hover_tween: Tween = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	_rebuild_from_item_info()

func set_item_info_data(new_item_info: ItemData) -> void:
	item_info = new_item_info
	_rebuild_from_item_info()

func clear_item_info_data() -> void:
	item_info = null
	_rebuild_from_item_info()

func _rebuild_from_item_info() -> void:
	_spawned_model_instance = null
	_rest_model_position = Vector3.ZERO
	_rest_model_rotation = Vector3.ZERO
	input_ray_pickable = false

	for child in get_children():
		remove_child(child)
		child.queue_free()

	if item_info != null and item_info.item_mesh != null:
		var spawned_wheel = item_info.item_mesh.instantiate()
		add_child(spawned_wheel)
		
		# Save reference to the instantiated 3D model node for easy access later
		if spawned_wheel is Node3D:
			_spawned_model_instance = spawned_wheel
			_rest_model_position = spawned_wheel.position
			_rest_model_rotation = spawned_wheel.rotation
		
		if item_info.surface_texture != null:
			_apply_texture_to_all_meshes(spawned_wheel, item_info.surface_texture)

		# Handle Collision Setup
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

		input_ray_pickable = true


# --- Helper Functions ---

func spin_model() -> void:
	# Rotates the spawned 3D mesh model dynamically regardless of its name
	var target_to_rotate: Node3D = _spawned_model_instance
	if not target_to_rotate:
		target_to_rotate = self # Fallback to rotating self if no mesh instance exists
		
	var target_radians = deg_to_rad(spin_angle_degrees)
	var tween = create_tween()
	
	tween.tween_property(target_to_rotate, "rotation:y", target_to_rotate.rotation.y + target_radians, spin_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)


func _apply_texture_to_all_meshes(current_node: Node, texture: Texture2D):
	if current_node is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = texture
		current_node.material_override = mat
		
	for child in current_node.get_children():
		_apply_texture_to_all_meshes(child, texture)


func _generate_collision_from_scene(current_node: Node):
	if current_node is MeshInstance3D:
		if current_node.mesh != null:
			if "Cone" in current_node.name or "Placeholder" in current_node.name:
				print("Skipping unintended mesh for collision: ", current_node.name)
				for child in current_node.get_children():
					_generate_collision_from_scene(child)
				return

			var collision_shape_data = current_node.mesh.create_convex_shape()
			var col_shape_node = CollisionShape3D.new()
			col_shape_node.shape = collision_shape_data
			col_shape_node.transform = current_node.transform
			add_child(col_shape_node)
			
	for child in current_node.get_children():
		_generate_collision_from_scene(child)


# --- Signals ---

func _on_mouse_entered() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.15, 1.15, 1.15), 0.15)
	object_hovered.emit(self)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)
	object_unhovered.emit(self)

# Plays a subtle "pick up" animation on hover: lifts and tilts the model
func _play_hover_animation(is_hovering: bool) -> void:
	if not _spawned_model_instance:
		return
	# Skip the animation for the roulette bowl/wheel and the TV
	if item_info != null:
		var name_lower = item_info.item_name.to_lower()
		if name_lower == "bowl" or name_lower == "wheel" or name_lower == "tv":
			return
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_hovering:
		_hover_tween.tween_property(_spawned_model_instance, "position",
			_rest_model_position + Vector3(0, 0.12, 0), 0.2)
		_hover_tween.parallel().tween_property(_spawned_model_instance, "rotation",
			_rest_model_rotation + Vector3(0, 0, deg_to_rad(10)), 0.2)
	else:
		_hover_tween.tween_property(_spawned_model_instance, "position",
			_rest_model_position, 0.2)
		_hover_tween.parallel().tween_property(_spawned_model_instance, "rotation",
			_rest_model_rotation, 0.2)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Area3D was clicked!") 
		if item_info != null:
			print(" -> Attached Resource: ", item_info.item_name)
			
			# IF THIS ITEM IS THE BOWL/WHEEL, TRIGGER SPIN AUTOMATICALLY!
			if item_info.item_name.to_lower() == "bowl" or item_info.item_name.to_lower() == "wheel":
				spin_model()
		else:
			print(" -> WARNING: item_info is empty! Drag a .tres file into the Inspector.")
			
		object_clicked.emit(self)

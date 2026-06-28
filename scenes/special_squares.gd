extends Area3D
@export_group("Identification")
@export_enum("red", "black", "green","even","odd") var special_square_identity: String = "none"

signal object_clicked(interacted_node)

# Called when the node enters the scene tree for the first time.
func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	# Check for a left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		object_clicked.emit()
		print("Area3D was clicked ! =>") 
		
		# 2. Check if the resource is there
		if special_square_identity != null:
			print(" -> Attached Resource: ", special_square_identity)
		else:
			print(" -> WARNING: special square ID not found")
			
		# 3. Emit the signal to the world regardless
		object_clicked.emit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

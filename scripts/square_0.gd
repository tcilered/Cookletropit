extends Area3D

@export_group("Identification")
@export_enum("red", "black", "green","even","odd") 
var special_square_identity: String = "none"

signal object_clicked(interacted_node)

# Called when the node enters the scene tree for the first time.
func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	# Check for a left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("[BETTING CONSOLE]: Square selected by client.") 
		
		# 2. Check if the resource is there
		if special_square_identity != null:
			print("[SYSTEM]: Square identity confirmed -> Type: ", special_square_identity.to_upper())
		else:
			print("[ERROR]: Target square missing identity payload.")
			
		# 3. Emit the signal to the world regardless
		object_clicked.emit(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

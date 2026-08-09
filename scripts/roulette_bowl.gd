extends StaticBody3D

# Define the signal with parameters
signal move_requested(pos: Vector3, radius: float)

@export var target: Marker3D
@export var radius_for_this_spot: float = 1

func _input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Send the signal out into the world
			move_requested.emit(target.global_position, radius_for_this_spot)

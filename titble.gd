extends Node3D # Works for MeshInstance2D if you swap Vector3 for Vector2

@export var amplitude: float = 2.0
@export var rotation_amplitude: float = 0.5 # Separate control for the rotation wobble intensity
@export var frequency: float = 1.5

var time: float = 0.0

# Store baseline vectors so everything scales relative to its starting point
var start_position: Vector3
var start_rotation: Vector3

func _ready() -> void:
	start_position = position
	start_rotation = rotation

func _process(delta: float) -> void:
	time += delta
	
	# =========================================================================
	# 3. TRANSFORMED COSINE TO X POSITION (Off-Center / Off-Phase)
	# =========================================================================
	# Adding 1.5 shifts the phase; adding 1.0 shifts the baseline so it stays positive
	var transformed_cos = (cos(time * frequency + 1.5) + 1.0) * amplitude * 0.4


	# =========================================================================
	# 4. VERY IRREGULAR CURVES (Stacking 3 different sin/cos functions per property)
	# =========================================================================
	# X Axis Position Stack: Base low freq + medium noise + high frequency micro-jitter
	var irregular_x = (sin(time * 1.1) * 0.5) + (cos(time * 2.7) * 0.25) + (sin(time * 4.3) * 0.1)
	
	# Y Axis Position Stack: Mismatched components to break standard rhythmic loop
	var irregular_y = (cos(time * 0.8) * 0.4) + (sin(time * 2.3) * 0.2)  + (cos(time * 5.1) * 0.08)
	
	# Z Axis Position Stack: Distinct frequencies for a completely unique Z depth path
	var irregular_z = (sin(time * 1.4) * 0.5) + (cos(time * 3.2) * 0.3)  + (sin(time * 6.8) * 0.12)

	# X Axis Rotation Stack: Organic pitching up/down
	var irregular_rot_x = (cos(time * 1.6) * 0.5) + (sin(time * 2.9) * 0.2) + (cos(time * 5.5) * 0.1)

	# Y Axis Rotation Stack: Organic panning left/right
	var irregular_rot_y = (sin(time * 1.2) * 0.4) + (cos(time * 3.5) * 0.25) + (sin(time * 4.7) * 0.08)


	# =========================================================================
	# 5. APPLY POSITIONING & ROTATION
	# =========================================================================
	# Position Applications
	position.x = start_position.x + transformed_cos + (irregular_x * amplitude)
	position.y = start_position.y + (irregular_y * amplitude)
	position.z = start_position.z + (irregular_z * amplitude)

	# Rotation Applications (Direct property modifications to prevent transform drift)
	rotation.x = start_rotation.x + (irregular_rot_x * rotation_amplitude)
	rotation.y = start_rotation.y + (irregular_rot_y * rotation_amplitude)

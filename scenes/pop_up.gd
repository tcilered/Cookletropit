class_name FloatingText
extends Node3D

## Assign these in the Inspector for maximum flexibility
@export var label: Label
@export var sprite: Sprite3D
@export var viewport: SubViewport

func _ready() -> void:
	# Fallback checks in case they weren't set in the Inspector
	if not label:
		label = $SubViewport/Label
	if not sprite:
		sprite = $Sprite3D
	if not viewport:
		viewport = $SubViewport
		
	# Ensure the SubViewport texture is dynamically linked on instantiation
	if sprite and viewport:
		sprite.texture = viewport.get_texture()

## Set custom text and optional shader parameters upon spawning
func display_text(new_text: String, wave_speed: float = 3.0) -> void:
	if label:
		label.text = new_text
	
	if sprite:
		var shader_mat = sprite.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("wave_speed", wave_speed)
		
	_animate()

func _animate() -> void:
	var tween = create_tween().set_parallel(true)
	
	# Float upward
	tween.tween_property(self, "position:y", position.y + 1.0, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# Fade out sprite alpha
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	
	# Free memory after animation finishes
	tween.chain().tween_callback(queue_free)

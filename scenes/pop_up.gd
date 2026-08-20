class_name FloatingText
extends Node3D

@export var label: Label
@export var sprite: Sprite3D
@export var viewport: SubViewport

func _ready() -> void:
	if not viewport:
		viewport = $SubViewport
	if not sprite:
		sprite = $Sprite3D
	if not label:
		label = $SubViewport/PanelContainer/Label

	if sprite and viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sprite.texture = viewport.get_texture()
		
		# Always face the active camera
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func display_text(new_text: String, wave_speed: float = 3.0) -> void:
	if label:
		label.text = new_text
	
	if sprite:
		var shader_mat = sprite.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("wave_speed", wave_speed)

## Animate closing and remove from scene tree
func dismiss() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15)
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
	
func _on_area_3d_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dismiss()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dismiss()

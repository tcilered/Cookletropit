class_name FloatingText
extends Node3D

@export var label: Label
@export var sprite: Sprite3D
@export var viewport: SubViewport

# --- NEW MANUAL CONTROLS ---
## Set the exact pixel dimensions of your text box here
@export var box_size: Vector2i = Vector2i(246, 80)
## Adjust if the panel is off-center inside the viewport
@export var box_offset: Vector2 = Vector2(-110,-36)
# ---------------------------

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
	if sprite:
		sprite.visible = false 
		
	if label:
		label.text = new_text
		
	if viewport:
		# 1. Force the viewport to your manually typed size
		viewport.size = box_size
		
		# 2. Force the panel to match and apply your offset
		var panel = $SubViewport/PanelContainer
		panel.size = Vector2(box_size)
		panel.position = box_offset
	
	# 3. Wait for the SubViewport to render the new resolution
	await get_tree().process_frame
	await get_tree().process_frame

	if sprite:
		var shader_mat = sprite.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("wave_speed", wave_speed)
		sprite.visible = true 

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

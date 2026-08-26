class_name FloatingText
extends Node3D

@export var label: Label
@export var sprite: Sprite3D
@export var viewport: SubViewport

# Set how wide you want the bubble to get before the text is forced to wrap to a new line
@export var max_box_width: int = 300

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
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func display_text(new_text: String, wave_speed: float = 3.0) -> void:
	if sprite:
		sprite.visible = false 
		
	if label and viewport:
		var panel = $SubViewport/PanelContainer
		
		# 1. Reset positioning and sizing completely
		panel.position = Vector2.ZERO
		panel.size = Vector2.ZERO 
		
		# 2. Tell the label to wrap and set its absolute maximum width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(max_box_width, 0)
		label.text = new_text
		
		# 3. Give the Viewport infinite room so the UI can expand naturally
		viewport.size = Vector2i(max_box_width, 2000)
		
	# Wait for Godot's UI layout engine to process the word-wrapping
	await get_tree().process_frame
	await get_tree().process_frame
	
	if viewport:
		var panel = $SubViewport/PanelContainer
		# 4. Shrink-wrap the Viewport strictly to the UI's final calculated size
		viewport.size = Vector2i(panel.size.x, panel.size.y)
		
	# Wait one final frame for the SubViewport to render the crop
	await get_tree().process_frame

	if sprite:
		var shader_mat = sprite.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("wave_speed", wave_speed)
		sprite.visible = true


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

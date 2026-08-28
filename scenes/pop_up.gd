class_name FloatingText
extends Node3D

@export var label: Label
@export var sprite: Sprite3D
@export var viewport: SubViewport
@export var max_box_width: int = 300
@export var edge_margin: float = 50.0
@export var popup_scale: Vector3 = Vector3.ONE

var target_world_pos: Vector3 = Vector3.ZERO
var is_active: bool = false
var can_dismiss: bool = false


func _ready() -> void:
	if not viewport:
		viewport = get_node_or_null("SubViewport")
	if not sprite:
		sprite = get_node_or_null("Sprite3D")
	if not label:
		label = get_node_or_null("SubViewport/PanelContainer/Label")

	target_world_pos = global_position
	scale = popup_scale

	if sprite and viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sprite.texture = viewport.get_texture()
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _process(_delta: float) -> void:
	if is_active:
		_clamp_to_screen_edge()


func display_text(new_text: String, wave_speed: float = 3.0, custom_scale: Vector3 = Vector3.ONE, world_pos: Vector3 = Vector3.ZERO) -> void:
	if world_pos != Vector3.ZERO:
		target_world_pos = world_pos
		global_position = world_pos
	else:
		target_world_pos = global_position

	popup_scale = custom_scale
	scale = popup_scale
	can_dismiss = false

	if sprite:
		sprite.visible = false
		
	if label and viewport:
		var panel = viewport.get_node_or_null("PanelContainer")
		if panel:
			panel.position = Vector2.ZERO
			panel.size = Vector2.ZERO
		
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(max_box_width, 0)
		label.text = new_text
		viewport.size = Vector2i(max_box_width, 2000)
		
	await get_tree().process_frame
	await get_tree().process_frame
	
	if viewport:
		var panel = viewport.get_node_or_null("PanelContainer")
		if panel:
			viewport.size = Vector2i(panel.size.x, panel.size.y)
		
	await get_tree().process_frame

	if sprite:
		var shader_mat = sprite.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("wave_speed", wave_speed)
		sprite.visible = true
	
	is_active = true
	print("[POPUP_SYS] Displaying floating popup at target coordinates: ", target_world_pos)
	
	await get_tree().create_timer(0.7).timeout
	can_dismiss = true


func _clamp_to_screen_edge() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var screen_center = screen_size * 0.5

	var is_behind = camera.is_position_behind(target_world_pos)
	var screen_pos = camera.unproject_position(target_world_pos)

	if is_behind:
		screen_pos = screen_center - (screen_pos - screen_center)

	var is_offscreen = is_behind \
		or screen_pos.x < edge_margin \
		or screen_pos.x > (screen_size.x - edge_margin) \
		or screen_pos.y < edge_margin \
		or screen_pos.y > (screen_size.y - edge_margin)

	var final_screen_pos = screen_pos

	if is_offscreen:
		var dir = (screen_pos - screen_center).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP

		var limit = (screen_size * 0.5) - Vector2(edge_margin, edge_margin)
		var scale_factor = min(
			abs(limit.x / dir.x) if dir.x != 0 else INF,
			abs(limit.y / dir.y) if dir.y != 0 else INF
		)
		final_screen_pos = screen_center + dir * scale_factor

	var depth = max(camera.global_position.distance_to(target_world_pos), 1.0)
	global_position = camera.project_position(final_screen_pos, depth)


func dismiss() -> void:
	is_active = false
	can_dismiss = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15)
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Always consume the input so it doesn't click the world behind the popup
		get_viewport().set_input_as_handled()
		
		# Only actually dismiss if the cooldown has finished
		if can_dismiss:
			dismiss()

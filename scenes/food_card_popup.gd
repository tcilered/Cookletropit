extends CanvasLayer

signal food_selected(buff_key: String)

# Holds the 3 food definitions currently displayed
var _offered_foods: Array = []

# Per-card state for spin tweens and model nodes
var _model_nodes: Array = [null, null, null]  # Node3D inside each SubViewport
var _spin_tweens: Array = [null, null, null]   # Active spin tweens

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer


func _ready() -> void:
	# Layer 1 so the pause menu (layer 2) always draws on top
	layer = 1
	hide()


# Show the popup with 3 randomly chosen food cards
func show_popup() -> void:
	_offered_foods = FoodData.get_random_selection()
	_cleanup_models()

	for i in range(cards_container.get_child_count()):
		var card: PanelContainer = cards_container.get_child(i)
		if i < _offered_foods.size():
			var food = _offered_foods[i]
			card.get_node("VBox/FoodName").text = food["name"]
			card.get_node("VBox/FoodDesc").text = food["description"]
			card.get_node("VBox/PickBtn").text = "Pick"
			card.visible = true
			_load_model_into_card(i, food["model_path"])
		else:
			card.visible = false

	show()
	# Pause AFTER models are added so the SubViewports can render their first frame
	await get_tree().process_frame
	get_tree().paused = true


# Consume the pause action so Escape doesn't unpause while this popup is open
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()


# Load the food GLB into card i's SubViewport
func _load_model_into_card(card_index: int, model_path: String) -> void:
	if model_path == "":
		return

	var viewport: SubViewport = cards_container.get_child(card_index).get_node("VBox/ModelViewportContainer/ModelViewport")

	# Clear any previous model
	for child in viewport.get_children():
		if child is Node3D and child.name == "FoodModel":
			child.queue_free()

	var packed = load(model_path)
	if not packed:
		push_warning("FoodCardPopup: could not load model: " + model_path)
		return

	var model: Node3D = packed.instantiate()
	model.name = "FoodModel"
	viewport.add_child(model)
	_model_nodes[card_index] = model


# Start continuous Y-rotation spin when hovering
func _start_spin(card_index: int) -> void:
	var model = _model_nodes[card_index]
	if not model:
		return
	# Kill any existing tween
	if _spin_tweens[card_index] and _spin_tweens[card_index].is_valid():
		_spin_tweens[card_index].kill()

	var tween = create_tween().set_loops()
	tween.tween_property(model, "rotation:y", model.rotation.y + TAU, 1.5)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	_spin_tweens[card_index] = tween


# Stop spin on unhover
func _stop_spin(card_index: int) -> void:
	if _spin_tweens[card_index] and _spin_tweens[card_index].is_valid():
		_spin_tweens[card_index].kill()
		_spin_tweens[card_index] = null


func _cleanup_models() -> void:
	for i in range(3):
		_stop_spin(i)
		_model_nodes[i] = null


func _on_pick_btn_pressed(card_index: int) -> void:
	var food = _offered_foods[card_index]
	_cleanup_models()
	FoodData.apply_food_buff(food["buff_key"])
	emit_signal("food_selected", food["buff_key"])
	get_tree().paused = false
	hide()


func _on_card_mouse_entered(card_index: int) -> void:
	_start_spin(card_index)


func _on_card_mouse_exited(card_index: int) -> void:
	_stop_spin(card_index)




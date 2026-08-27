extends CanvasLayer

# Emits the chosen food's buff_key and model_path so world.gd can run the cinematic
signal food_selected(buff_key: String, model_path: String)

var _offered_foods: Array = []

@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer


func _ready() -> void:
	# Layer 1 so the pause menu (layer 2) always draws on top
	layer = 1
	hide()


func show_popup() -> void:
	_offered_foods = FoodData.get_random_selection()

	for i in range(cards_container.get_child_count()):
		var card: PanelContainer = cards_container.get_child(i)
		if i < _offered_foods.size():
			var food = _offered_foods[i]
			card.get_node("VBox/FoodName").text = food["name"]
			card.get_node("VBox/FoodDesc").text = food["description"]
			card.get_node("VBox/PickBtn").text = "Pick"
			card.visible = true
		else:
			card.visible = false

	show()
	await get_tree().process_frame
	get_tree().paused = true


# Consume the pause action so Escape doesn't unpause while this popup is open
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()


func _on_pick_btn_pressed(card_index: int) -> void:
	var food = _offered_foods[card_index]
	get_tree().paused = false
	hide()
	emit_signal("food_selected", food["buff_key"], food["model_path"])


func _on_card_mouse_entered(_card_index: int) -> void:
	pass


func _on_card_mouse_exited(_card_index: int) -> void:
	pass

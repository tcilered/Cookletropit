extends CanvasLayer

signal food_selected(buff_key: String)

# Holds the 3 food definitions currently displayed
var _offered_foods: Array = []

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer


func _ready() -> void:
	hide()


# Show the popup with 3 randomly chosen food cards
func show_popup() -> void:
	_offered_foods = FoodData.get_random_selection()

	# Populate each card slot
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
	get_tree().paused = true


func _on_pick_btn_pressed(card_index: int) -> void:
	var food = _offered_foods[card_index]
	FoodData.apply_food_buff(food["buff_key"])
	emit_signal("food_selected", food["buff_key"])
	get_tree().paused = false
	hide()

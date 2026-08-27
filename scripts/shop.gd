extends Node3D

# Emitted when a player clicks a charm in the shop.
# The listener (world.gd) handles the gold deduction and charm activation.
signal charm_purchase_requested(item_node)
signal reroll_requested

const SHOP_OPTION_COUNT := 3
const REROLL_ITEM_NAME := "ShopReroll"
const RESET_REROLL_CHARM_NAME := "RerollResetCharm"

const CHARM_DEFINITIONS := [
	{
		"name": "GoldenGoblet",
		"value": 150,
		"description": "The goblet of a functional alcoholic gambling king. Just holding it you feel tipsy and forget your debt.",
		"mesh": preload("res://models/Glb/goblle.glb")
	},
	{
		"name": "BrokenHilt",
		"value": 100,
		"description": "A sword with a broken hilt. It still offers protection against the worst rolls.",
		"mesh": preload("res://models/Glb/sowrd.glb")
	},
	{
		"name": "MirrorShard",
		"value": 75,
		"description": "The shard of a shattered mirror.",
		"mesh": preload("res://models/Glb/mirror.glb")
	},
	{
		"name": "Crystalcharm",
		"value": 90,
		"description": "A standard crystal charm, it probably gives of negitive ions",
		"mesh": preload("res://models/tscn/charms!.tscn")
	},
	{
		"name": "TheCube",
		"value": 25,
		"description": "Adds more square numbers to the wheel.",
		"mesh": preload("res://models/Glb/The actual cube.glb")
	},
	{
		"name": "Die",
		"value": 80,
		"description": "A 20 sided die.",
		"mesh": preload("res://models/Glb/d20.glb")
	},
	{
		"name": "Garbage",
		"value": 50,
		"description": "Spawns a random charm.",
		"mesh": preload("res://models/Glb/rubbish!!!.glb")
	},
	{
		"name": "HotGarbage",
		"value": 125,
		"description": "Spawns a random high-tier charm.",
		"mesh": preload("res://models/Glb/rubbish(hot)!!!.glb")
	},
	{
		"name": RESET_REROLL_CHARM_NAME,
		"value": 200,
		"description": "You can only get this once. It resets reroll price to 100.",
		"mesh": preload("res://models/Glb/johnporkcharm.glb")
	}
]

@onready var option_nodes: Array = [
	$Option_1/Area3D,
	$Option_2/Area3D,
	$Option_3/Area3D
]
@onready var reroll_node = $Reroll_Button/Area3D

var purchase_made_this_round: bool = false

func _ready() -> void:
	randomize()
	_connect_item_signals(self)
	_refresh_reroll_button()
	start_new_round()

# Recursively walks descendants and connects object_clicked on any Area3D
# interactive items found inside the shop options.
func _connect_item_signals(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("object_clicked"):
			if not child.object_clicked.is_connected(_on_item_clicked):
				child.object_clicked.connect(_on_item_clicked)
		_connect_item_signals(child)

func start_new_round() -> void:
	purchase_made_this_round = false
	restock_shop()

func restock_shop() -> void:
	var stock = _pick_random_stock()
	for index in range(option_nodes.size()):
		var option = option_nodes[index]
		if index < stock.size():
			option.set_item_info_data(_build_item_data(stock[index]))
		else:
			option.clear_item_info_data()
	_refresh_reroll_button()

func handle_successful_purchase(item_node: Node) -> void:
	if not item_node or item_node == reroll_node:
		return
	purchase_made_this_round = true
	item_node.clear_item_info_data()

func reroll_shop_stock() -> void:
	restock_shop()

func _pick_random_stock() -> Array:
	var available = _get_available_charms()
	available.shuffle()
	return available.slice(0, min(SHOP_OPTION_COUNT, available.size()))

func _get_available_charms() -> Array:
	var active_names = GlobalData.active_charms_global.map(func(charm): return charm.get("name", ""))
	var available: Array = []
	for charm_data in CHARM_DEFINITIONS:
		if charm_data["name"] in active_names:
			continue
		available.append(charm_data)
	return available

func _build_item_data(charm_data: Dictionary) -> ItemData:
	var item_data := ItemData.new()
	item_data.item_name = charm_data.get("name", "")
	item_data.item_value = charm_data.get("value", 0)
	item_data.discription = charm_data.get("description", "")
	item_data.item_mesh = charm_data.get("mesh")
	item_data.has_bought = false
	return item_data

func _refresh_reroll_button() -> void:
	var reroll_item := ItemData.new()
	reroll_item.item_name = REROLL_ITEM_NAME
	reroll_item.item_value = GlobalData.shop_reroll_price
	reroll_item.discription = "Restock the shop. Cost triples forever after each use."
	reroll_item.item_mesh = preload("res://scenes/shop_reroll_button.tscn")
	reroll_node.set_item_info_data(reroll_item)

func _on_item_clicked(node: Node) -> void:
	if not node or not "item_info" in node or not node.item_info:
		return
	if node == reroll_node or node.item_info.item_name == REROLL_ITEM_NAME:
		reroll_requested.emit()
		return
	if purchase_made_this_round:
		print("You can only buy one shop charm each round.")
		return
	charm_purchase_requested.emit(node)
	
	

extends Node3D

signal charm_purchase_requested(item_node)

const INTERACTIVE_ITEM_SCENE = preload("res://scenes/interactive_item.tscn")
const STOCK_SIZE: int = 3
const REROLL_ITEM_NAME: String = "ShopReroll"
const RESET_CHARM_NAME: String = "CouponCharm"
const BASE_REROLL_PRICE: int = 25
const REROLL_RESET_PRICE: int = 100
const REROLL_PRICE_MULTIPLIER: int = 3
const SHOP_ITEM_SCALE := Vector3(0.2, 0.2, 0.2)

const SHOP_ITEMS := {
	"GoldenGoblet": {
		"price": 150,
		"description": "The goblet of a functional alcoholic gambling king. Delays losses for the next 3 days.",
		"mesh": preload("res://models/Glb/goblle.glb")
	},
	"BrokenHilt": {
		"price": 100,
		"description": "A sword with a broken hilt. It still offers protection against the worst rolls.",
		"mesh": preload("res://models/Glb/sowrd.glb")
	},
	"MirrorShard": {
		"price": 75,
		"description": "The shard of a shattered mirror.",
		"mesh": preload("res://models/Glb/mirror.glb")
	},
	"Crystalcharm": {
		"price": 90,
		"description": "A standard crystal charm. Grants a 1.5x payout multiplier on all wins.",
		"mesh": preload("res://models/tscn/charms!.tscn")
	},
	"TheCube": {
		"price": 125,
		"description": "A suspicious cube that stuffs the wheel with extra square numbers.",
		"mesh": preload("res://models/Glb/The actual cube.glb")
	},
	"Die": {
		"price": 60,
		"description": "A 20 sided die with wildly unstable luck.",
		"mesh": preload("res://models/Glb/d20.glb")
	},
	"CouponCharm": {
		"price": 175,
		"description": "Can only be bought once. Resets the reroll price to $100.",
		"mesh": preload("res://models/Glb/The actual cube outline.glb")
	}
}

func _ready() -> void:
	add_to_group("shops")
	_ensure_global_shop_state()
	_connect_item_signals(self)
	_sync_with_global_state()
	

func _ensure_global_shop_state() -> void:
	if GlobalData.shop_reroll_price <= 0:
		GlobalData.shop_reroll_price = BASE_REROLL_PRICE
	if GlobalData.shop_stock_names.size() != STOCK_SIZE:
		_restock_global_shop()
	elif GlobalData.shop_sold_out_slots.size() != STOCK_SIZE:
		GlobalData.shop_sold_out_slots = [false, false, false]

func _connect_item_signals(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("object_clicked"):
			if not child.object_clicked.is_connected(_on_item_clicked):
				child.object_clicked.connect(_on_item_clicked)
		_connect_item_signals(child)

func _on_item_clicked(node: Node) -> void:
	# 1. Walk UP the tree until we find the node holding item_info
	var target_node = node
	while target_node != null and target_node.get("item_info") == null:
		target_node = target_node.get_parent()

	if target_node == null:
		print("[SHOP ERROR]: Target item metadata could not be resolved.")
		return

	var item_info: ItemData = target_node.item_info
	print("[SHOP CONSOLE]: Item targeted -> ", item_info.item_name)

	if item_info.item_name == REROLL_ITEM_NAME:
		_try_reroll_shop()
		return

	_try_buy_charm(target_node, item_info)


func _try_buy_charm(node: Node, item_info: ItemData) -> void:
	if GlobalData.shop_purchase_locked:
		print("[SHOP TRANSACTION DENIED]: Purchases locked for current round.")
		return

	var owned_names = _get_owned_charm_names()
	if item_info.item_name in owned_names:
		print("[SHOP TRANSACTION DENIED]: Item '", item_info.item_name, "' is already owned.")
		return

	if GlobalData.player_stats.gold < int(item_info.item_value):
		print("[SHOP TRANSACTION DENIED]: Insufficient funds. Price: $", item_info.item_value, " | Available: $", GlobalData.player_stats.gold)
		return

	# --- PURCHASE SUCCESSFUL ---
	print("[SHOP TRANSACTION SUCCESS]: Purchased '", item_info.item_name, "' for $", item_info.item_value, ".")
	GlobalData.player_stats.gold -= int(item_info.item_value)
	GlobalData.shop_purchase_locked = true
	item_info.has_bought = true
	
	if item_info.item_name not in GlobalData.owned_charms_global:
		GlobalData.owned_charms_global.append(item_info.item_name)

	var slot_index = _get_slot_index(node)
	if slot_index >= 0 and slot_index < GlobalData.shop_sold_out_slots.size():
		GlobalData.shop_sold_out_slots[slot_index] = true

	node.visible = false
	
	# 1. Emit the signal (for anything else listening)
	charm_purchase_requested.emit(node)
	
	# 2. DIRECT FALLBACK: Force the Wheel to update directly, ignoring signals
	var root = get_tree().current_scene
	# Find any node containing "Wheel" in its name (e.g., WheelScene, Wheel_Scene)
	var wheel = root.find_child("Wheel*", true, false) 
	
	if wheel and wheel.has_method("add_charm"):
		print("[CHARM MANAGER]: Active charm equipped -> ", item_info.item_name)
		wheel.add_charm(item_info.item_name)
	else:
		print("[WARNING]: Wheel target offline. Charm modifier not applied.")

	_sync_all_shops()



func _try_reroll_shop() -> void:
	var reroll_price := int(GlobalData.shop_reroll_price)
	if GlobalData.player_stats.gold < reroll_price:
		print("[SHOP REROLL FAILED]: Insufficient funds. Reroll Cost: $", reroll_price, " | Available: $", GlobalData.player_stats.gold)
		return

	GlobalData.player_stats.gold -= reroll_price
	GlobalData.shop_reroll_price *= REROLL_PRICE_MULTIPLIER
	print("[SHOP CONSOLE]: Restocking items for $", reroll_price, ". Next reroll cost: $", GlobalData.shop_reroll_price)
	_restock_global_shop()
	_sync_all_shops()

func _restock_global_shop() -> void:
	var owned_names = _get_owned_charm_names()
	var preferred_pool: Array[String] = []
	var fallback_pool: Array[String] = []

	for charm_name in SHOP_ITEMS.keys():
		if charm_name == RESET_CHARM_NAME and charm_name in owned_names:
			continue

		fallback_pool.append(charm_name)
		if charm_name not in owned_names:
			preferred_pool.append(charm_name)

	var stock_pool: Array[String] = preferred_pool if preferred_pool.size() >= STOCK_SIZE else fallback_pool
	stock_pool.shuffle()

	GlobalData.shop_stock_names = []
	for index in range(min(STOCK_SIZE, stock_pool.size())):
		GlobalData.shop_stock_names.append(stock_pool[index])

	GlobalData.shop_sold_out_slots = [false, false, false]

func _sync_all_shops() -> void:
	if get_tree():
		get_tree().call_group("shops", "_sync_with_global_state")

func _sync_with_global_state() -> void:
	_update_reroll_button()
	_refresh_stock_slots()

func _update_reroll_button() -> void:
	var reroll_button = get_node_or_null("RerollButton")
	if reroll_button and reroll_button.get("item_info") != null:
		reroll_button.item_info.item_value = int(GlobalData.shop_reroll_price)
		reroll_button.item_info.discription = "Restock the shop. Costs $" + str(GlobalData.shop_reroll_price) + " and triples after each use."

func _refresh_stock_slots() -> void:
	for slot_index in range(STOCK_SIZE):
		var slot = get_node_or_null("Option_" + str(slot_index + 1))
		if slot == null:
			continue

		for child in slot.get_children():
			child.queue_free() # <-- Safely queues deletion

		if slot_index >= GlobalData.shop_stock_names.size():
			continue

		var item_node = INTERACTIVE_ITEM_SCENE.instantiate()
		item_node.scale = SHOP_ITEM_SCALE
		item_node.item_info = _create_item_data(GlobalData.shop_stock_names[slot_index])
		item_node.visible = not GlobalData.shop_sold_out_slots[slot_index]
		slot.add_child(item_node)

	_connect_item_signals(self)
	
	
	
func _create_item_data(charm_name: String) -> ItemData:
	var item_data := ItemData.new()
	var definition: Dictionary = SHOP_ITEMS.get(charm_name, {})

	item_data.item_name = charm_name
	item_data.item_value = int(definition.get("price", 0))
	item_data.discription = str(definition.get("description", ""))
	item_data.item_mesh = definition.get("mesh", null)
	item_data.has_bought = false

	return item_data

func _get_slot_index(node: Node) -> int:
	var current_node := node
	while current_node:
		var parent = current_node.get_parent()
		if parent == self:
			if current_node.name.begins_with("Option_"):
				return max(current_node.name.trim_prefix("Option_").to_int() - 1, -1)
			break
		current_node = parent
	return -1

func _get_owned_charm_names() -> Array[String]:
	var owned_names: Array[String] = []
	for charm_name in GlobalData.owned_charms_global:
		if charm_name != "":
			owned_names.append(charm_name)
	for charm in GlobalData.active_charms_global:
		if typeof(charm) == TYPE_DICTIONARY:
			var active_name := str(charm.get("name", ""))
			if active_name != "" and active_name not in owned_names:
				owned_names.append(active_name)
	return owned_names

func start_new_round() -> void:
	GlobalData.shop_purchase_locked = false
	_restock_global_shop()
	_sync_all_shops()

func reset_reroll_price() -> void:
	GlobalData.shop_reroll_price = REROLL_RESET_PRICE
	_sync_all_shops()

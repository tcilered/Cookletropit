extends Node3D

# --- Configuration & Defaults ---
# Default mesh node name inside spawned scenes if no specific path is given in item_info
@export var default_mesh_node_name: String = "Object_9"

# Customizable variables for the spin
@export var spin_angle_degrees: float = randi_range(520, 900) # How far to spin (can change this in Inspector)
@export var spin_duration: float = 2.0        # How long the spin takes in seconds
# maybe for later to have logic in charms to change roatation amount and duration
var spin_angle_rand_change =  randi_range(300, 360)

signal numrolled(roll)
var active_charms: Array = []


func _ready():
	for child in get_children():
		if child.has_signal("object_clicked"):
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)


# --- Core Logic ---
func spin_wheel():
	# Now using the Autoload for the base wheel numbers!
	var modified_wheel = RouletteData.wheel_numbers.duplicate()
	
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_wheel"):
			modified_wheel = charm.apply_to_wheel.call(modified_wheel)
	
	var roll = modified_wheel.pick_random()
	
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_roll"):
			roll = charm.apply_to_roll.call(roll)
			
	return int(roll)
	
func calculate_payout(base_payout: float) -> float:
	var final_payout = base_payout
	
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_reward"):
			final_payout = charm.apply_to_reward.call(final_payout)
			
	return final_payout

# --- Helper Methods ---
# Dynamically resolves the target MeshInstance3D inside the object node
func _get_target_mesh(node: Node) -> MeshInstance3D:
	if not node:
		return null

	# If the clicked node itself is a MeshInstance3D
	if node is MeshInstance3D:
		return node

	# 1. Try resolving using item_info / custom resource fields (if set on the item)
	if "item_info" in node and node.item_info:
		var info = node.item_info
		
		# If you defined a specific mesh node path/name on your Item Resource
		if "item_mesh_node_path" in info and info.item_mesh_node_path != "":
			var found = node.get_node_or_null(info.item_mesh_node_path)
			if found is MeshInstance3D:
				return found

	# 2. Try looking inside the spawned sub-scene (e.g. Sketchfab_Scene)
	var sub_scene = node.get_node_or_null("Sketchfab_Scene")
	if sub_scene:
		if sub_scene is MeshInstance3D:
			return sub_scene
		# Fallback search inside the sub-scene for the configurable mesh name
		var sub_mesh = sub_scene.find_child(default_mesh_node_name, true, false)
		if sub_mesh is MeshInstance3D:
			return sub_mesh

	# 3. Fallback: Search the entire subtree for any MeshInstance3D automatically
	var recursive_mesh = node.find_child("*", true, false)
	if recursive_mesh is MeshInstance3D:
		return recursive_mesh

	return null


# --- Charm Management ---
const ALL_CHARMS: Array[String] = [
	"Lucky Clover", "The Cube", "Crystal charm", "Broken hilt", "tan rook", "Golden goblet"
]
const HOT_CHARMS: Array[String] = [
	"The Cube", "Crystal charm", "tan rook", "Golden goblet"
]

func add_charm(charm_name: String) -> void:
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and str(charm.get("name", "")) == charm_name:
			print("[CHARM STATUS] Charm already active: " + str(charm_name))
			return

	var new_charm: Dictionary = {}

	match charm_name:
		"LuckyClover":
			new_charm = {
				"name": charm_name,
				"apply_to_roll": func(r: int) -> int: return 7 if r == 0 else r
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — House 0s converted to 7s.")

		"TheCube":
			new_charm = {
				"name": charm_name,
				"apply_to_wheel": func(w: Array) -> Array:
					for i in range(3):
						w.append_array(RouletteData.square_numbers)
					return w
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Appended 3 sets of square numbers to wheel.")

		"Crystalcharm":
			new_charm = {
				"name": charm_name,
				"multiplier": 1.5,
				"apply_to_reward": func(payout: float) -> float:
					return payout * 1.5
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — 1.5x payout multiplier granted.")

		"Die":
			new_charm = {
				"name": charm_name,
				"apply_to_reward": func(payout: float) -> float:
					var multiplier = clamp(randfn(1.25, 0.4), 0.1, 2.0)
					print("[BUFF EVENT] Die multiplier calculated: " + str(snapped(multiplier, 0.01)) + "x")
					return payout * multiplier
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Random payout multiplier active (0.1x - 2.0x).")

		"HotGarbage":
			new_charm = {
				"name": charm_name
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Spawning high-tier charm...")
			var random_hot = HOT_CHARMS[randi() % HOT_CHARMS.size()]
			call_deferred("add_charm", random_hot)

		"Garbage":
			new_charm = {
				"name": charm_name
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Spawning random charm...")
			var random_charm = ALL_CHARMS[randi() % ALL_CHARMS.size()]
			call_deferred("add_charm", random_charm)

		"BrokenHilt":
			new_charm = {
				"name": charm_name,
				"charges": 3,
				"on_zero_roll": func(charm_dict: Dictionary) -> bool:
					if charm_dict.get("charges", 0) > 0:
						charm_dict["charges"] -= 1
						print("[BUFF EVENT] Broken Hilt protected against 0-roll. Remaining charges: " + str(charm_dict["charges"]))
						return true
					return false
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — 3 charges of 0-roll protection active.")

		"TanRook":
			new_charm = {
				"name": charm_name,
				"rook_position": Vector2i(2, 2),
				"modify_spot_reward": func(spot_pos: Vector2i, reward: float, rook_pos: Vector2i) -> float:
					if spot_pos == rook_pos:
						return -abs(reward)
					elif spot_pos.x == rook_pos.x or spot_pos.y == rook_pos.y:
						return reward * 2.0
					return reward
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Rook alignment bonus active.")

		"GoldenGoblet":
			new_charm = {
				"name": charm_name,
				"delay_days": 3,
				"description": "The goblet of a functional alcoholic gambling king. Just holding it you feel tipsy and forget your debt.",
				"process_loss": func(loss_amount: float, charm_dict: Dictionary) -> float:
					if charm_dict.get("delay_days", 0) > 0:
						charm_dict["delay_days"] -= 1
						print("[BUFF EVENT] Golden Goblet delayed $" + str(loss_amount) + " loss. Days left: " + str(charm_dict["delay_days"]))
						return 0.0
					return loss_amount
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — Loss deferral active (3 days remaining).")

		"MirrorShard":
			new_charm = {
				"name": charm_name,
				"description": "The shard of a shattered mirror",
				"apply_to_reward": func(payout: float) -> float:
					if randf() <= 0.15:
						print("[BUFF EVENT] Mirror Shard triggered! Payout doubled (2.0x).")
						return payout * 2.0
					return payout
			}
			print("[CHARM APPLIED] " + str(charm_name) + " — 15% reflection chance active.")

		"CouponCharm":
			new_charm = {
				"name": charm_name,
				"description": "Can only be bought once. Resets the reroll price to $100."
			}
			GlobalData.shop_reroll_price = 100
			if get_tree():
				get_tree().call_group("shops", "_sync_with_global_state")
			print("[CHARM APPLIED] " + str(charm_name) + " — Shop reroll price reset to $100.")

		_:
			new_charm = {"name": charm_name}
			print("[WARNING] Unrecognized charm identifier: " + str(charm_name) + ". Registered as generic charm.")

	active_charms.append(new_charm)
	GlobalData.active_charms_global = active_charms
	if charm_name not in GlobalData.owned_charms_global:
		GlobalData.owned_charms_global.append(charm_name)

	var charm_names = active_charms.map(func(c): return c.get("name", "Unknown"))
	print("[CHARM INVENTORY] Active list updated: " + str(charm_names))


# --- Signal Handling ---
func _on_object_hovered(node):
	node.scale = Vector3(1.21, 1.21, 1.21)
	print("[INSPECT] Wheel module hovered.")
	
	var mesh_instance = _get_target_mesh(node)
	if mesh_instance:
		var red_material = StandardMaterial3D.new()
		red_material.albedo_color = Color(1, 0, 0)
		mesh_instance.material_override = red_material


func _on_object_unhovered(node):
	node.scale = Vector3(1.2, 1.2, 1.2)
	
	var mesh_instance = _get_target_mesh(node)
	if mesh_instance:
		mesh_instance.material_override = null


func _get_spin_target(node: Node) -> Node3D:
	if not node:
		return null
	
	var mesh = _get_target_mesh(node)
	
	if mesh:
		if mesh.get_parent() != node and mesh.get_parent() is Node3D:
			return mesh.get_parent() as Node3D
		return mesh
		
	for child in node.get_children():
		if child is Node3D:
			return child
			
	return node if node is Node3D else null


func _on_object_clicked(node):
	if not node.item_info:
		return

	var item_name = node.item_info.item_name

	if item_name == "bowl":
		print("[SYSTEM] Wheel initiation sequence started.")
		
		var spin_target = _get_spin_target(node)
		
		if spin_target:
			var target_radians = deg_to_rad(spin_angle_degrees)
			var tween = create_tween()

			tween.tween_property(spin_target, "rotation:y", spin_target.rotation.y + target_radians, spin_duration)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)
				
		var result = spin_wheel()
		numrolled.emit(result)
		print("[SYSTEM] Wheel spin outcome: [" + str(result) + "]")
	
	else:
		add_charm(item_name)


func _on_node_3d_main_world_item_toggeled(item: Variant) -> void:
	if item and item.item_info:
		add_charm(item.item_info.item_name)

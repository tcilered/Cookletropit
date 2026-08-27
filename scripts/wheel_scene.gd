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
			print("Charm already active: ", charm_name)
			return

	var new_charm: Dictionary = {}
	
	match charm_name:
		"LuckyClover":
			new_charm = {
				"name": charm_name,
				"apply_to_roll": func(r: int) -> int: return 7 if r == 0 else r
			}
			print("Added Lucky Clover: House 0s are now 7s!")

		"TheCube":
			new_charm = {
				"name": charm_name,
				"apply_to_wheel": func(w: Array) -> Array:
					for i in range(9999):
						# Now pulling square numbers from the Autoload!
						w.append_array(RouletteData.square_numbers)
					return w
			}
			print("Added The Cube: Added 3 sets of square numbers to the wheel!")

		"Crystalcharm":
			new_charm = {
				"name": charm_name,
				"multiplier": 1.5,
				"apply_to_reward": func(payout: float) -> float:
					return payout * 1.5
			}
			print("Added Crystal Charm: Grants a 1.5x payout multiplier on all wins!")

		"Die":
			new_charm = {
				"name": charm_name,
			}
			print("Added Die: Randomly sets a multiplier between 0.1X to 2X, weighted at a standard distribution of prob mean centred on 1.25X")

		"HotGarbage":
			new_charm = {
				"name": charm_name
			}
			print("Added Hot Garbage: Spawning a random high-tier charm!")
			var random_hot = HOT_CHARMS[randi() % HOT_CHARMS.size()]
			call_deferred("add_charm", random_hot)

		"Garbage":
			new_charm = {
				"name": charm_name
			}
			print("Added Garbage: Spawning a random charm!")
			var random_charm = ALL_CHARMS[randi() % ALL_CHARMS.size()]
			call_deferred("add_charm", random_charm)

		"BrokenHilt":
			new_charm = {
				"name": charm_name,
				"charges": 3,
				"on_zero_roll": func(charm_dict: Dictionary) -> bool:
					if charm_dict.get("charges", 0) > 0:
						charm_dict["charges"] -= 1
						print("Broken Hilt protected you from 0! Remaining charges: ", charm_dict["charges"])
						return true
					return false
			}
			print("Added Broken Hilt: Protects against a 0-roll three times!")

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
			print("Added Tan Rook: Moves horizontally/vertically double rewards; tile occupied flips negative!")

		"GoldenGoblet":
			new_charm = {
				"name": charm_name,
				"delay_days": 3,
				"description": "The goblet of a functional alcoholic gambling king. Just holding it you feel tipsy and forget your debt.",
				"process_loss": func(loss_amount: float, charm_dict: Dictionary) -> float:
					if charm_dict.get("delay_days", 0) > 0:
						charm_dict["delay_days"] -= 1
						print("Golden Goblet delayed a loss of $", loss_amount, "! Days left: ", charm_dict["delay_days"])
						return 0.0
					return loss_amount
			}
			print("Added Golden Goblet: Delays losses for the next 3 days!")

		"MirrorShard":
			new_charm = {
				"name": charm_name,
				"description": "The shard of a shattered mirror"
			}
			print("Added MirrorShard: ")

		"CouponCharm":
			new_charm = {
				"name": charm_name,
				"description": "Can only be bought once. Resets the reroll price to $100."
			}
			GlobalData.shop_reroll_price = 100
			if get_tree():
				get_tree().call_group("shops", "_sync_with_global_state")
			print("Added Coupon Charm: Shop reroll price reset to $100.")

		_:
			new_charm = {"name": charm_name}
			print("Warning: No custom logic found for '", charm_name, "'. Adding as generic charm.")

	active_charms.append(new_charm)
	GlobalData.active_charms_global = active_charms
	if charm_name not in GlobalData.owned_charms_global:
		GlobalData.owned_charms_global.append(charm_name)

	var charm_names = active_charms.map(func(c): return c.get("name", "Unknown"))
	print("Active charms list is now: ", charm_names)


# --- Signal Handling ---
func _on_object_hovered(node):
	node.scale = Vector3(1.21, 1.21, 1.21) # Slight pop effect when hovered
	print("hovering over Wheel!")
	
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
	
	# First, find the actual MeshInstance3D inside this node (using our helper from earlier)
	var mesh = _get_target_mesh(node)
	
	if mesh:
		# If the mesh's immediate parent isn't the root interactive Area3D/Node,
		# rotate the parent container (this handles GLTF/FBX import root nodes nicely)
		if mesh.get_parent() != node and mesh.get_parent() is Node3D:
			return mesh.get_parent() as Node3D
		# Otherwise rotate the mesh directly
		return mesh
		
	# Fallback: if no mesh found, rotate the first Node3D child
	for child in node.get_children():
		if child is Node3D:
			return child
			
	return node if node is Node3D else null


func _on_object_clicked(node):
	if not node.item_info:
		return

	var item_name = node.item_info.item_name

	# Logic for clicking the bowl (the "Play" button)
	if item_name == "bowl":
		print("--- SPINNING ---")
		
		# Dynamically resolve whatever model is attached
		var spin_target = _get_spin_target(node)
		
		if spin_target:
			var target_radians = deg_to_rad(spin_angle_degrees)
			var tween = create_tween()

			tween.tween_property(spin_target, "rotation:y", spin_target.rotation.y + target_radians, spin_duration)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)
				
		var result = spin_wheel()
		numrolled.emit(result)
		print("Result: ", result)
	
	# Logic for picking up a charm
	else:
		add_charm(item_name)


func _on_node_3d_main_world_item_toggeled(item: Variant) -> void:
	if item and item.item_info:
		add_charm(item.item_info.item_name)

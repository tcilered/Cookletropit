extends Area3D
@export_group("Identification")
@export_enum("red", "black", "green","even","odd") var special_square_identity: String = "red"

signal object_clicked(interacted_node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_object_clicked(interacted_node: Variant) -> void:
	pass # Replace with function body.

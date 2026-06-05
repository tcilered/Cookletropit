extends Control

# "self" refers to this exact node. 
# Ensure this node's Process -> Mode is set to "Always" in the Inspector!
@onready var pause_menu: Control = self 

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled() # Stops the event from hitting world.gd
		if get_tree().paused:
			_on_continue_pressed()
		else:
			GlobalData.save_game()
			get_tree().paused = true
			print("Paused game")
			$UI.visible = true
			print("showing menu")

func _on_continue_pressed() -> void:
	get_tree().paused = false # This unfreezes the 3D world!
	$UI.visible = false
	# This hides the pause menu so you can play again
	print("Unpaused and hid world")

func _on_new_btn_p_pressed() -> void:
	get_tree().paused = false
	GlobalData.reset_data()
	get_tree().change_scene_to_file("res://world.tscn")

func _on_quit_btn_p_pressed() -> void:
	GlobalData.save_game()
	get_tree().quit()


func _on_settings_btn_p_pressed() -> void:
	pass # Replace with function body.

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
			# Only open/close the pause menu UI — never unpause the game when
			# something else (e.g. the food card popup) still needs it paused.
			if $UI.visible:
				_on_continue_pressed()
			else:
				$UI.visible = true
				print("Paused game")
		else:
			GlobalData.save_game()
			get_tree().paused = true
			$UI.visible = true
			print("Paused game")

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

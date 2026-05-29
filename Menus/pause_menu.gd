extends Control

# "self" refers to this exact node. 
# Ensure this node's Process -> Mode is set to "Always" in the Inspector!
@onready var pause_menu: Control = self 

func _ready() -> void:
	# Hide the menu when the game starts
	hide() 

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# If it's already paused, unpause it. If it's not, pause it.
		if get_tree().paused:
			_on_continue_pressed()
		else:
			GlobalData.save_game()
			get_tree().paused = true
			show() # Shows this menu

func _on_continue_pressed() -> void:
	get_tree().paused = false # This unfreezes the 3D world!
	hide() # This hides the pause menu so you can play again

func _on_new_btn_p_pressed() -> void:
	get_tree().paused = false
	GlobalData.reset_data()
	get_tree().change_scene_to_file("res://world.tscn")

func _on_quit_btn_p_pressed() -> void:
	GlobalData.save_game()
	get_tree().quit()

extends Control


# Called when the node enters the scene tree for the first time.



func _on_quit_btn_p_pressed() -> void:
	GlobalData.save_game()
	get_tree().quit()





func _on_new_btn_p_pressed() -> void:
	GlobalData.reset_data()
	get_tree().change_scene_to_file("res://world.tscn")


func _on_continue_pressed() -> void:
	pass # Replace with function body.

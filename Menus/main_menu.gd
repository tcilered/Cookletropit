extends Control




func _on_start_btn_pressed() -> void:
	GlobalData.load_game()
	get_tree().change_scene_to_file("res://world.tscn")


func _on_quit_btn_pressed() -> void:
	GlobalData.save_game()
	get_tree().quit()


func _on_new_btn_pressed() -> void:
	GlobalData.reset_data()
	get_tree().change_scene_to_file("res://world.tscn")

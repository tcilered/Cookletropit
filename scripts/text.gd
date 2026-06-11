extends Label3D




func _process(delta):
	# Example: Display the current frames per second
	text = "FPS: " + str(Engine.get_frames_per_second()) + " | Gold:" +  str(GlobalData.player_stats.gold)
	
	# You can also change colors on the fly
	modulate = Color(1, 0, 0) # Turns the text red

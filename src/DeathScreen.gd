extends Node2D

func _process(_delta):
	
	if Input.is_action_just_pressed("ui_accept"):
		match $MenuSelector.get_position():
			0: get_tree().change_scene("res://src/levels/Level01.tscn")
			1: get_tree().quit()

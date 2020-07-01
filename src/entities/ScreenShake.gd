extends Node2D

var current_strength = 0

func _ready():
	pass
	
func moveCamera(vec:Vector2):
	get_parent().get_node("Camera2D").offset = Vector2(rand_range(-vec.x, vec.x), rand_range(-vec.y, vec.y))

func shakeScreen(length, power):
	if power >= current_strength:
		print("yes")
		current_strength = power
		$Tween.interpolate_method(self, "moveCamera", Vector2(power, power), Vector2(0, 0), length, Tween.TRANS_SINE, Tween.EASE_OUT, 0)
		$Tween.start()
		yield($Tween, "tween_completed")
	
		if not $Tween.is_processing():
			current_strength = 0

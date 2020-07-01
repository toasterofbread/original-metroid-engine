extends AnimatedSprite

func _ready():
	self.play()

func _on_MissileTrail_animation_finished():
	queue_free()

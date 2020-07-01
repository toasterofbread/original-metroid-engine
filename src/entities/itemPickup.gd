extends Area2D

export var pickupType: String

func setPickupType(type):
	pickupType = type
	
func _ready():
	$AnimatedSprite.play(pickupType)

func _on_smallEnergyPickup_body_entered(body):
	if "Samus" in body.name:
		body.pickupHandler(pickupType)
	queue_free()

func _on_Timer_timeout():
	queue_free()

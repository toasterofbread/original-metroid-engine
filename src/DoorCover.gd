extends StaticBody2D

const beamTypes = ["standard", "wave", "plasma"]
var strength: int

const doorOpen = preload("res://assets/sounds/world/Dooropen.ogg")
const doorClose = preload("res://assets/sounds/world/Doorclose.ogg")

const doorMiss = preload("res://assets/sounds/MisDoorHit.ogg")

const effect = {
	"beam": ["standard", "wave", "plasma", "missile", "super missile", "grapple beam", "bomb"],
	"missile": ["missile", "super missile"],
	"super missile": ["super missile"],
	"power bomb": ["power bomb"],
	"locked": [],
	"beam close": ["standard", "wave", "plasma", "missile", "super missile", "grapple beam", "bomb"],
	"missile close": ["missile", "super missile"],
	"super missile close": ["super missile"],
	"power bomb close": ["power bomb"],
	"locked close": []
}

func _ready():
	$AnimatedSprite.animation = get_parent().type
	$AnimatedSprite.frame = 0
	$AnimatedSprite.playing = false

func handleShot(type):

	if not strength:
		if $AnimatedSprite.animation == "missile":
			strength = 5
		else:
			strength = 0
			
	if strength > 0:
		if type == "missile":
			strength -= 1
			
			if strength > 0:
				$AudioStreamPlayer.stream = doorMiss
				$AudioStreamPlayer.play()
				
				$Timer.start()
				
				var flashCount = 2
				while flashCount > 0:
					yield($Timer, "timeout")
					$AnimatedSprite.animation = "beam"
					yield($Timer, "timeout")
					$AnimatedSprite.animation = "missile"
					
					flashCount -= 1

		elif type == "super missile":
			strength -= 5
			
	if strength > 0:
		return "explode"

	if type in effect[$AnimatedSprite.animation]:
		open()
		
	return "explode"


func open():
	
	if get_parent().get_node("AnimationPlayer").is_playing():
		return
	
	get_parent().open = true
#	$CollisionShape2D.queue_free()
	
	$AnimatedSprite.playing = true
	$AudioStreamPlayer.stream = doorOpen
	$AudioStreamPlayer.play()
	
	yield($AnimatedSprite, "animation_finished")
	
	
	$AnimatedSprite.visible = false
	
	yield($AudioStreamPlayer, "finished")
	
	queue_free()
	

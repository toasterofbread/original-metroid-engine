extends Area2D

var bulletSpeed = 6
var direction: String
var action: Vector2
var beamType: String
var boost: Vector2
var trailTime = 0.05
const trail = preload("res://src/MissileTrail.tscn")
var sound = ""

func setType(type):
	beamType = type
	
	match beamType:
		"standard": 
			sound = preload("res://assets/sounds/samus/BaseShot.ogg")
			$Hitbox.position.x = 0
			$Hitbox.shape.height = 4
			$Hitbox.shape.radius = 9
		"missile": sound = preload("res://assets/sounds/samus/Missile.ogg")
		"super missile": sound = preload("res://assets/sounds/samus/SMissile.ogg")
		
	
func momentumBoost(vel:Vector2):
	boost = vel / 75

func setDirection(dir):
	direction = dir
			
	# set the action to be executed each frame based on the 'direction' variable
	# rotate bullet if needed
	match direction:
		"right": 
			action = Vector2(bulletSpeed, 0)
			self.rotation_degrees = 180
		"left": 
			action = Vector2(-bulletSpeed, 0)
		"up": 
			action = Vector2(0, -bulletSpeed)
			self.rotation_degrees = 90
		"down": 
			action = Vector2(0, bulletSpeed)
			self.rotation_degrees = 270
		
		"upright": 
			action = Vector2(bulletSpeed, -bulletSpeed)
			self.rotation_degrees = 135
				
		"upleft": 
			action = Vector2(-bulletSpeed, -bulletSpeed)
			self.rotation_degrees = 45
			
		"downleft": 
			action = Vector2(-bulletSpeed, bulletSpeed)
			self.rotation_degrees = 315
			
		"downright": 
			action = Vector2(bulletSpeed, bulletSpeed)
			self.rotation_degrees = 225
			
	if (boost.x > 0 and action.x > 0) or (boost.x < 0 and action.x < 0):
		action.x += boost.x
			
	if (boost.y > 0 and action.y > 0) or (boost.y < 0 and action.y < 0):
		action.y += boost.y
		

func _ready():
	
	# crash the program if the action has not been set
	if not action:
		print("ERROR: Bullet's 'direction' variable was not set correctly")
		get_tree().quit()
		
	# begin the bullet's animation
	$AnimatedSprite.play(beamType)
		
	# play sound
	$AudioStreamPlayer.stream = sound
	$AudioStreamPlayer.play()
	
	trailTime = 0.05

func _physics_process(delta):
	if direction != "stop":
		# move the bullet based on the action set earlier
		translate(action)
		
		if beamType == "missile" or beamType == "super missile":
			if trailTime <= 0:
				
				var t = trail.instance()
				
				t.global_position = self.global_position
				
				get_parent().add_child(t)
				trailTime = 0.05
			else:
				trailTime -= delta

# kill bullet when it leaves the screen
func _on_screen_exited():
	killSelf()
	
func killSelf():
	direction = "stop"
	if $AudioStreamPlayer.playing:
		for child in self.get_children():
			if child != $AudioStreamPlayer:
				child.queue_free()
		
		yield($AudioStreamPlayer, "finished")
	
	queue_free()


func _on_Standard_shot_body_entered(body):
	
	if beamType == "super missile":
		get_parent().get_node("Samus/ScreenShake").shakeScreen(1, 5)
	
	# play explosion animation and kill bullet when it collides with a world tile
	if body.name == "LevelTileMap":
		direction = "stop"
		
		self.rotation_degrees = 0
		
		$Hitbox.shape.height = 1
		if beamType == "standard":
			$AnimatedSprite.play("small explosion")
			
			$Hitbox.shape.radius = 16
		else:
			$AnimatedSprite.play("large explosion")
		
			$Hitbox.shape.radius = 30
		yield($AnimatedSprite, "animation_finished")
	else:
		body.handleShot(beamType)
		
	
		
	killSelf()


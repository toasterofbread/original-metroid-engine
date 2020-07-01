extends KinematicBody2D

export var playFanfare = false

const walkSpeed = 200
const jumpPower = 600
const gravity = 20

const canSpinJumpInAir = false

var shotCooldown = 0
const FLOOR = Vector2(0, -1)
var dying = true
var velocity = Vector2()
var animator = ""
var direction = ""
var finalAnimation = "idle_right"
var health = 99
var selectedWeapon = 0
var audioChannels = []
var spinChannel = ""

var damaged = false

var cycleWeapons = [
	
	["standard", 0, 0.35], 
	["missile", 0, 0.2]
	
	]

const sounds = {
	"loadmusic": preload("res://assets/sounds/loadmusic.ogg"),
	"standard": preload("res://assets/sounds/samus/BaseShot.ogg"),
	"spin": preload("res://assets/sounds/samus/Spin.ogg"),
	"death": preload("res://assets/sounds/samus/Death.ogg"),
	"missile": preload("res://assets/sounds/samus/Missile.ogg") 
}

# load the beam shot scene
const shotScene = preload("res://src/entities/shotScene.tscn")

func _ready():
	
	if playFanfare:
		$AnimatedSprite.play("neutral")

		yield(playSound("loadmusic"), "finished")
		
	dying = false
	
	for child in self.get_children():
		if child.get_class() == "AudioStreamPlayer2D":
			audioChannels.append(child)
	

func _physics_process(delta):
	
	if dying:
		return
	
	animator = $AnimatedSprite

	if is_on_floor():
		
		# reset Samus's animation if she is on the ground and still spinning
		match animator.animation:
			"spin_right": finalAnimation = "idle_right"
			"spin_left": finalAnimation = "idle_left"
		
		
		if Input.is_action_pressed("c_move_right"):
			finalAnimation = "run_right"
			velocity.x = walkSpeed
		elif Input.is_action_pressed("c_move_left"):
			finalAnimation = "run_left"
			velocity.x = -walkSpeed
		else:
			if Input.is_action_just_released("c_move_left"):
				finalAnimation = "idle_left"
			elif Input.is_action_just_released("c_move_right"):
				finalAnimation = "idle_right"
			velocity.x = 0
			
	else:
		
		if "spin" in animator.animation:
			if Input.is_action_pressed("c_move_right"):
				finalAnimation = "spin_right"
				velocity.x = walkSpeed
			elif Input.is_action_pressed("c_move_left"):
				finalAnimation = "spin_left"
				velocity.x = -walkSpeed
				
		else:
			if Input.is_action_pressed("c_move_right"):
				finalAnimation = "idle_right"
				velocity.x = walkSpeed
			elif Input.is_action_pressed("c_move_left"):
				finalAnimation = "idle_left"
				velocity.x = -walkSpeed

	# jump if the button has been pressed
	jumpHandler()
	
	aimHandler()
	
	# fire a bullet if the button has been pressed
	shothandler(delta)
	
	weaponCycleHandler()
	
	# apply the final animation
	animator.play(finalAnimation)
	
	# apply gravity to the velocity
	velocity.y += gravity
	
	# move based on final velocity
	velocity = move_and_slide(velocity, FLOOR)
	
	if "spin" in animator.animation and spinChannel is String:
		spinChannel = playSound("spin")

	elif not "spin" in animator.animation and not spinChannel is String:
		spinChannel.stop()
		spinChannel = ""
	

func weaponCycleHandler(mode=""):
	
	if mode == "query":
		return cycleWeapons
	
	if len(cycleWeapons) == 1:
		return
	elif Input.is_action_just_pressed("c_cycle_weapons"):
		if selectedWeapon == 0:
			selectedWeapon = len(cycleWeapons) - 1
		else:
			selectedWeapon -= 1
			
		print(selectedWeapon)
			
		#for child in get_parent().get_children():
		#	if child.name == "HUD":
		#		child.select_weapon(selectedWeapon)
		#		break
			
	

func aimHandler():
	
	if Input.is_action_pressed("c_aim_up") and Input.is_action_pressed("c_aim_down"):
		print("remember to add meeee (aim up) (and also down)")
		return
	
	elif Input.is_action_pressed("c_aim_up"):
		if "right" in animator.animation:
			if Input.is_action_just_pressed("c_move_left"):
				finalAnimation = "aim_up_left"
				direction = "upleft"
				
				$BulletPosition.position = Vector2(-20, -25)
			else:
				finalAnimation = "aim_up_right"
				direction = "upright"
				
				$BulletPosition.position = Vector2(20, -25)
		elif "left" in animator.animation:
			if Input.is_action_just_pressed("c_move_right"):
				finalAnimation = "aim_up_right"
				direction = "upright"
				
				$BulletPosition.position = Vector2(20, -25)
			else:			
				finalAnimation = "aim_up_left"
				direction = "upleft"
				
				$BulletPosition.position = Vector2(-20, -25)
	elif Input.is_action_pressed("c_aim_down"):
		if "right" in animator.animation:
			if Input.is_action_just_pressed("c_move_left"):
				finalAnimation = "aim_down_left"
				direction = "downleft"
				
				$BulletPosition.position = Vector2(-20, 6)
			else:
				finalAnimation = "aim_down_right"
				direction = "downright"
				
				$BulletPosition.position = Vector2(20, 6)
		elif "left" in animator.animation:
			if Input.is_action_just_pressed("c_move_right"):
				finalAnimation = "aim_down_right"
				direction = "downright"
				
				$BulletPosition.position = Vector2(20, 6)
			else:			
				finalAnimation = "aim_down_left"
				direction = "downleft"
				
				$BulletPosition.position = Vector2(-20, 6)
	elif Input.is_action_just_released("c_aim_down") or Input.is_action_just_released("c_aim_up"):
		direction = ""
		
		match animator.animation:
			"aim_down_left", "aim_up_left": 
				finalAnimation = "idle_left"	
				$BulletPosition.position = Vector2(-14, -3)
			"aim_down_right", "aim_up_right": 
				finalAnimation = "idle_right"	
				$BulletPosition.position = Vector2(14, -3)
				
	else:
		if "right" in animator.animation:
			$BulletPosition.position = Vector2(14, -3)
		elif "left" in animator.animation:
			$BulletPosition.position = Vector2(-14, -3)

	

func shothandler(delt):

	if cycleWeapons[selectedWeapon][1] > 0:
		cycleWeapons[selectedWeapon][1] -= delt
	elif (selectedWeapon == 0 and (Input.is_action_pressed("fire_shot") and not "spin" in animator.animation)) \
			or (Input.is_action_just_pressed("fire_shot")):

		# set the cooldown for the weapon
		cycleWeapons[selectedWeapon][1] = cycleWeapons[selectedWeapon][2]
		
		# if spinning, play idle (placeholder) animation
		if animator.animation == "spin_right":
			finalAnimation = "idle_right"
		elif animator.animation == "spin_left":
			finalAnimation = "idle_left"
			
		var bullet = shotScene.instance()
		
		if direction == "":
			if "right" in animator.animation:
				bullet.setDirection("right")
			else:
				bullet.setDirection("left")
		else:
			bullet.setDirection(direction)
		
		var type = cycleWeapons[selectedWeapon][0]
		
		bullet.setType(type)
		
		get_parent().add_child(bullet)
		
		bullet.position = $BulletPosition.global_position
		
		playSound(type)


func jumpHandler():
	if Input.is_action_just_pressed("c_jump"):
		if is_on_floor():
			velocity.y = -jumpPower
			
			if velocity.x > 0:
				finalAnimation = "spin_right"
			elif velocity.x < 0:
				finalAnimation = "spin_left"
		else:
			if not "spin" in animator.animation and canSpinJumpInAir:
				match animator.animation:
					"idle_right":
						finalAnimation = "spin_right"
						velocity.x = walkSpeed
					"idle_left": 
						finalAnimation = "spin_left"
						velocity.x = -walkSpeed
				velocity.y = 0
				
func pickupHandler(type:String):
	print(type + " collected")
		


func healthHandler(type):
	
	var dmg = 0
	
	if type is int:
		dmg = type
	else:
		match type:
			"zoomer 01": dmg = -5
			"geemer": dmg = "unknown"
		
	health += dmg
	
	if health <= 0:
		death()
		return
	
	for child in get_parent().get_children():
		if child.name == "HUD":
			child.set_amount("energy", health)


func death():
	dying = true
	
	for child in get_parent().get_children():
		if not "Samus" in child.name:
			child.queue_free()
			
	for channel in audioChannels:
		channel.stop()
		
	$AnimatedSprite.playing = false
		
	$CollisionShape2D.disabled = true
		
	$AnimationPlayer.play("death1")
	yield($AnimationPlayer, "animation_finished")
	
	playSound("death")
	$AnimatedSprite.playing = true
	
	$AnimatedSprite.play("death_left_0")
	yield($AnimatedSprite, "animation_finished")
	
	$AnimatedSprite.play("death_left_1")
	yield($AnimatedSprite, "animation_finished")
	
	$AnimationPlayer.play("death2")
	$AnimatedSprite.play("death_left_2")
	yield($AnimatedSprite, "animation_finished")
	$AnimatedSprite.visible = false
	
	$AnimationPlayer.play("death3")
	yield($AnimationPlayer, "animation_finished")
	
	get_tree().change_scene("res://src/DeathScreen.tscn")
	
func playSound(sound:String):
	
	for channel in audioChannels:
		if not channel.playing:
			channel.stream = sounds[sound.to_lower()]
			channel.play()
			return channel

	print("Not enough audio channels!")
	get_tree().quit()


extends KinematicBody2D

export var playFanfare = false
export var outputVelocity = false

const walkSpeedCap = 150
const runSpeedCap = 275
const spinSpeedCap = 150
const jumpSpeed = 72
const morph_ball_speed = 150
var debug_shift_count = 0

const bombCooldownDefault = 0.4 * 60
var bombCooldown = 0
const walkSpeed = 17
const spinDeceleration = 0.3

const runDeceleration = 0.3

const jumpPower = 22
const jumpCap = 270
const gravity = 9
const fallCap = 250

const canSpinJumpInAir = false

const FLOOR = Vector2(0, -1)
var invincible = false
var run_physics = false
var velocity = Vector2()
var hitstun = false
var direction = ""
var facing = "right"
var fallAnim = false
var spinChannel = ""
var aiming = "none"

export var health = 99
var selectedWeapon = 0
var audioChannels = []

var damaged = false
var mode = "idle"
var awaitAnimation = false
var falling = false
var spinning = false
var animCache: Array
var HUD: Control

var weaponList = [
	
	["standard", 0, 0.35, ""], 
	["missile", 0, 0.1, 20],
	["super missile", 0, 0.2, 20]
	]

var upgrades = {"morph ball": "", "bomb": preload("res://src/Bomb.tscn")}

const sounds = {
	"loadmusic": preload("res://assets/sounds/loadmusic.ogg"),
	"spin": preload("res://assets/sounds/samus/Spin.ogg"),
	"death": preload("res://assets/sounds/samus/Death.ogg"),
	"land": preload("res://assets/sounds/samus/Land.ogg"),
	"damage": preload("res://assets/sounds/samus/Injure.ogg"),
	"click": preload("res://assets/sounds/other/Click.ogg")
}

const animationOffset = {
	["morph ball"]: Vector2(0, 14.691),
	["to morph", "from morph", "crouch", "crouch turn", "crouch aim up", "crouch aim side up", "crouch aim side down"]: Vector2(0, 6.691)
}

# load the beam shot scene
const shotScene = preload("res://src/entities/shotScene.tscn")

func _ready():

	print($Hitbox.get_shape().get_extents(), " / ", $Hitbox.position)
	setHealth(0)
	
	$CanvasLayer/ColorRect.visible = false
	$IFrameTimer.wait_time = $AnimationPlayer.get_animation("damage").length
	
	for child in self.get_children():
		if child.get_class() == "AudioStreamPlayer":
			audioChannels.append(child)
			
	for child in get_parent().get_children():
		if child is Control and child.name == "HUD":
			HUD = child
			
	for item in weaponList:
		if item[3] is int:
			HUD.set_amount(item[0], item[3])

	if playFanfare:
		invincible = true
		$SpriteLeft.play("neutral")
		mode = "neutral"
		facing = "neutral"
		yield(playSound("loadmusic"), "finished")
		invincible = false
	
	setHitBox()
	run_physics = true
		
func _physics_process(delta):
	
	var delt = delta * 59.999997
	
	if outputVelocity:
		print(velocity)

	if Input.is_action_just_pressed("debug_shift_left"):
		self.position.x -= 16
		debug_shift_count += 1
		print("Shift count: ", debug_shift_count)
		
	if Input.is_action_just_pressed("debug_shift_right"):
		self.position.x +=16
		debug_shift_count += 1
		print("Shift count: ", debug_shift_count)
		
	if Input.is_action_just_pressed("debug_reset_shift_count"):
		debug_shift_count = 0
		print("Shift count: ", debug_shift_count)
		
	
	
	if not run_physics:
		return
	
	if int(delt) != 1:
		print("Delt is not 1! Value of delt: ", delt)
	
	movementHandler(delt)
	cycleWeapon()
	
	if not awaitAnimation:
		match mode:
			"run": 
				if aiming == "side up":
					animate("aim side up run")
				elif aiming == "side down":
					animate("aim side down run")
				else:
					animate("run")
			"idle": 
				if aiming == "side up":
					animate("aim_side_up")
				elif aiming == "side down":
					animate("aim_side_down")
				elif aiming == "up":
					animate("aim up standing")
				else:
					animate("idle")
			"jump": 
				if spinning:
					animate("spin")
				elif falling and velocity.y > 0:
					animate("falling")
				else:
					animate("rising")
			"crouch":
				if aiming == "side up":
					animate("crouch aim side up")
				elif aiming == "side down":
					animate("crouch aim side down")
				elif aiming == "up":
					animate("crouch aim up")
				else:
					animate("crouch")
			"morph ball":
				animate("morph ball")

	# apply gravity to the velocity
	if velocity.y < fallCap and not hitstun:
		velocity.y += gravity
	
	# move based on final velocity
	velocity = move_and_slide(velocity, FLOOR)

	if "spin" in $SpriteLeft.animation and spinChannel is String:
		spinChannel = playSound("spin")

	elif not "spin" in $SpriteLeft.animation and not spinChannel is String:
		spinChannel.stop()
		spinChannel = ""
	

func movementHandler(delt):
	
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = true

	if Input.is_action_just_pressed("cancel_selection"):
		cycleWeapon("cancel")
	
	if hitstun:
		return
		
	if Input.is_action_just_pressed("fire_shot"):
		shot()
	
	if (Input.is_action_pressed("aim_up") and Input.is_action_pressed("aim_down")) or (mode == "idle" and Input.is_action_pressed("ui_up")):
		if aiming == "side down":
			match mode:
				"idle": turnAnimation("aim_side_up")
				"crouch": turnAnimation("crouch aim side up")
		aiming = "up"
	elif Input.is_action_pressed("aim_up") or (mode == "run" and Input.is_action_pressed("up")):
		aiming = "side up"
	elif Input.is_action_pressed("aim_down") or (mode == "run" and Input.is_action_pressed("crouch")):
		if aiming == "up":
			match mode:
				"idle": turnAnimation("aim_side_up")
				"crouch": turnAnimation("crouch aim side up")
		aiming = "side down"
	else:
		aiming = "none"
	
	var startFacing = facing
	if Input.is_action_just_pressed("move_left") and facing != "left":
		facing = "left"
		match mode:
			"run", "idle": turnAnimation("turn standing")
		
	elif Input.is_action_just_pressed("move_right") and facing != "right":
		facing = "right"
		match mode:
			"run", "idle": turnAnimation("turn standing")

	if mode in ["run", "neutral", "idle"] and is_on_floor():


		if Input.is_action_just_pressed("crouch") and mode != "run":
			mode = "crouch"
			velocity.x = 0
			return
		elif Input.is_action_just_pressed("jump"):
			mode = "jump"
			falling = false
			velocity.y -= jumpPower * delt
			
			if not round(velocity.x) - 10 <= 0 or not round(velocity.x) + 10 >= 0:
				spinning = true	
				velocity.x -= velocity.x * 0.2
			return

		var cap = walkSpeedCap
		
		if Input.is_action_pressed("run"):
			cap = runSpeedCap
			match facing:
				"right": 
					if velocity.x >= cap:
						$SpriteLeft.speed_scale = 1.35
						$SpriteRight.speed_scale = 1.35
					else:
						$SpriteLeft.speed_scale = 1
						$SpriteRight.speed_scale = 1
					
				"left": 
					if velocity.x <= -cap:
						$SpriteLeft.speed_scale = 1.35
						$SpriteRight.speed_scale = 1.35
					else:
						$SpriteLeft.speed_scale = 1
						$SpriteRight.speed_scale = 1
		
		if Input.is_action_pressed("move_left"):
			if mode != "idle" or (not awaitAnimation and aiming != "up"):
				mode = "run"
				
				if velocity.x > -cap:
					velocity.x -= walkSpeed * delt
		elif Input.is_action_pressed("move_right"):
			if mode != "idle" or (not awaitAnimation and aiming != "up"):
				mode = "run"
			
				if velocity.x < cap:
					velocity.x += walkSpeed * delt
		elif mode != "neutral":
			mode = "idle"
			velocity.x = lerp(velocity.x, 0, runDeceleration)
			
	elif mode == "jump":
	
		if is_on_floor():
			playSound("land")
			mode = "idle"
			
			if spinning:
				self.position.y -= 10
			
			falling = false
			spinning = false
			fallAnim = false
			return
			
		if (Input.is_action_just_released("jump") or velocity.y <= -jumpCap or is_on_ceiling()) and not falling:
			falling = true
				
		if not fallAnim:
			if velocity.y > 0:
				fallAnim = true
				if not spinning:
					turnAnimation("falling turn")
			
		if not falling:
			velocity.y = min(velocity.y - jumpPower * delt, jumpCap)
			
		if not spinning:
			if Input.is_action_pressed("move_left"):
				velocity.x = -jumpSpeed
			elif Input.is_action_pressed("move_right"):
				velocity.x = jumpSpeed
			else:
				velocity.x = 0
		else:
			if Input.is_action_pressed("move_left"):
				velocity.x = min(velocity.x, -jumpSpeed)
			elif Input.is_action_pressed("move_right"):
				velocity.x = max(velocity.x, jumpSpeed)
			else:
				lerp(velocity.x, jumpSpeed, spinDeceleration)
					
			
	elif mode == "crouch":
		
		if Input.is_action_pressed("move_left"):
			if startFacing == "left" and $SpriteLeft.animation != "crouch turn":
				mode = "run"
				return
			else:
				turnAnimation("crouch turn")
				
		elif Input.is_action_pressed("move_right"):
			if startFacing == "right" and $SpriteLeft.animation != "crouch turn":
				mode = "run"
				return
			else:
				turnAnimation("crouch turn")
			
		elif Input.is_action_just_pressed("jump"):
			mode = "jump"
			falling = false
			velocity.y -= jumpPower
			
			if not round(velocity.x) - 10 <= 0 or not round(velocity.x) + 10 >= 0:
				spinning = true
				velocity.x -= velocity.x * 0.2

			return
		elif Input.is_action_just_pressed("up"):
			mode = "idle"
		elif Input.is_action_just_pressed("down") and "morph ball" in upgrades:
			mode = "morph ball"
			turnAnimation("to morph")
			
		lerp(velocity.x, 0, 0.9)
			
	elif mode == "morph ball":
		
		if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("jump"):
			mode = "crouch"
			turnAnimation("from morph")
			return
		
		if Input.is_action_pressed("move_left"):
			velocity.x = -morph_ball_speed
		elif Input.is_action_pressed("move_right"):
			velocity.x = morph_ball_speed
		else:
			velocity.x = 0
			
	if bombCooldown > 0:
		if bombCooldown - delt <= 0:
			bombCooldown = 0
		else:
			bombCooldown -= delt
			
	for weapon in weaponList:
		if weapon[1] - delt <= 0:
			weapon[1] = 0
		else:
			weapon[1] -= delt


func cycleWeapon(mode=""):
	
	if mode == "query":
		return weaponList
	
	if len(weaponList) == 1:
		return
	elif Input.is_action_just_pressed("cycle_weapon") or mode != "":
		
		var originalSelection = selectedWeapon
		if mode == "cancel":
			selectedWeapon = 0
		else:
			
			while true:
				if selectedWeapon == len(weaponList) - 1:
					selectedWeapon = 0
				else:
					selectedWeapon += 1
					
				if weaponList[selectedWeapon][3] is int:
					if weaponList[selectedWeapon][3] != 0:
						break
				else:
					break
		
		if originalSelection != selectedWeapon:
			playSound("click")

		HUD.select_weapon(weaponList[selectedWeapon][0])

func pickupHandler(type):
	match type:
		"energySmall": setHealth(5)
		"energyLarge": setHealth(20)

func shot():
	
	if awaitAnimation:
		return
	
	if mode == "morph ball":
		if weaponList[selectedWeapon][0] == "power bomb":
			pass
		elif "bomb" in upgrades.keys():
			if bombCooldown == 0:
				
				var bombcount = 0
				
				for child in get_parent().get_children():
					print(child.name)
					if "Bomb" in child.name and not "Power bomb" in child.name:
						if not child.finished:
							bombcount += 1
							if bombcount >= 3:
								return
							
				print(bombcount)
							
				bombCooldown = bombCooldownDefault
				
				var bomb = upgrades["bomb"].instance()
				get_parent().add_child(bomb)
				
				bomb.position = self.global_position
							
							
				
		return
			
	
	var weapon = weaponList[selectedWeapon]
	
	if weaponList[selectedWeapon][3] is int:
		if weapon[3] <= 0:
			return
	
	if weaponList[selectedWeapon][1] > 0:
		return
		
	weaponList[selectedWeapon][1] = weaponList[selectedWeapon][2]
	
	var shot = shotScene.instance()
	var type = weaponList[selectedWeapon][0]
	shot.setType(type)
	shot.momentumBoost(velocity)
	
	match aiming:
		"side up":
			match facing:
				"right": shot.setDirection("upright")
				"left": shot.setDirection("upleft")
		"side down":
			match facing:
				"right": shot.setDirection("downright")
				"left": shot.setDirection("downleft")
		"up":
			shot.setDirection("up")
		"none":
			match facing:
				"right": shot.setDirection("right")
				"left": shot.setDirection("left")
				
			
	get_parent().add_child(shot)
	
	shot.position = $BulletPosition.global_position
	
	if weapon[3] is int:
		weaponList[selectedWeapon][3] -= 1
		HUD.set_amount(weapon[0], weapon[3])
		
		if weaponList[selectedWeapon][3] == 0:
			cycleWeapon("cancel")
	
	

func damageHandler(type, knockback):
	
	if invincible:
		return
	
	var dmg = 0
	
	match type:
		"zoomer 01": dmg = -5
		"geemer": dmg = -10
		
	if setHealth(dmg) == "death":
		return

	invincible = true
	hitstun = true
	
	if knockback.x > 0:
		knockback.x = -400
	else:
		knockback.x = 400
	
	if is_on_floor():
		knockback.y = -100
	elif knockback.y > 0:
		knockback.y = -250
	else:
		knockback.y = 250

	velocity = knockback

	if mode == "jump":
		self.position.y -= 10
		falling = false
		spinning = false

	if mode != "morph ball":
		mode = "idle"


	playSound("damage")
	$SpriteLeft.modulate = Color(2, 2, 2, 1 )
	$AnimationPlayer.play("damage")

	$IFrameTimer.start()
	

			
func setHealth(hlt):
	
	health += hlt
	
	if health <= 0:
		death()
		return "death"

	for child in get_parent().get_children():
		if child.name == "HUD":
			child.set_amount("energy", health)

func death():
	run_physics = false
	
	for child in get_parent().get_children():
		if not "Samus" in child.name:
			child.queue_free()
			
	for channel in audioChannels:
		channel.stop()
		
	$SpriteLeft.playing = false
	$SpriteRight.playing = false
		
	$AnimationPlayer.play("death1")
	yield($AnimationPlayer, "animation_finished")
	
	playSound("death")
	$SpriteLeft.playing = true
	$SpriteRight.playing = true
	
	animate("death_0")
	yield($SpriteLeft, "animation_finished")
	
	animate("death_1")
	yield($SpriteLeft, "animation_finished")
	
	$AnimationPlayer.play("death2")
	animate("death_2")
	yield($SpriteLeft, "animation_finished")
	$SpriteLeft.visible = false
	$SpriteRight.visible = false
	
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

func _on_AnimatedSprite_animation_finished():
	awaitAnimation = false


func animate(anim:String, dir: String = facing):
	
	if [anim, facing] == animCache:
		return
	else:
		animCache = [anim, facing]
		
	$SpriteLeft.speed_scale = 1
	$SpriteRight.speed_scale = 1
	
	match dir.to_lower():
		"right": 
			$SpriteLeft.visible = false
			$SpriteRight.visible = true
		"left": 
			$SpriteLeft.visible = true
			$SpriteRight.visible = false

	$SpriteLeft.play(anim)
	$SpriteRight.play(anim)
	
	var set = false
	for key in animationOffset.keys():
		if anim in key:
			$SpriteLeft.position = animationOffset[key]
			$SpriteRight.position = animationOffset[key]
			set = true
			break
			
	if not set:
		$SpriteLeft.position = Vector2(0, 0)
		$SpriteRight.position = Vector2(0, 0)


	
	
	
	setHitBox()
	return $SpriteLeft

func turnAnimation(anim):
	print("a", anim)
	var turnAnimations = {
		"crouch turn": ["crouch", "crouch aim side down", "crouch aim side up", "crouch aim up"],		
		"falling turn": ["falling"],
		"turn standing": ["run", "idle", "aim side down run", "aim side up run", "aim up standing", "aim_side_down", "aim_side_up"],
		"crouch aim side up": ["crouch aim up", "crouch aim side down"],
		"aim_side_up": ["aim_side_down", "aim up standing"],
		"to morph": ["crouch"],
		"from morph": ["morph ball"]
	}
	

	if $SpriteLeft.animation in turnAnimations[anim]:
		print(anim)
		awaitAnimation = true
		animate(anim)

func setHitBox():

	
	var result: Array

	match $SpriteLeft.animation:
		"neutral": result = [Vector2(4.5498, 26.2698), Vector2(0.110184, -0.550914)]
		"idle", "run", "turn standing", "aim_side_up", "aim_side_down", "aim side up run", "aim side down run", "aim up standing": result = [Vector2(4.51672, 23.4076), Vector2(0, 1.10183)]
		"spin": result = [Vector2(5.52311, 13.3218), Vector2(-0.042957, 0.010602)]
		"crouch", "crouch aim side up", "crouch aim side down", "crouch aim up": match facing:
			"left": result = [Vector2(6.55, 17.67), Vector2(3.88, 5.691)]
			"right": result = [Vector2(6.55, 17.67), Vector2(-3.065, 5.691)]
		"morph ball": result = [Vector2(6.550, 6.5), Vector2(-0.022, 15)]
		
	match $SpriteLeft.animation:
		"idle": match facing:
			"right": $BulletPosition.position = Vector2(14.174, -2.9)
			"left": $BulletPosition.position = Vector2(-14.174, -2.9)
		"run": match facing:
			"right": $BulletPosition.position = Vector2(14.174, -2.9)
			"left": $BulletPosition.position = Vector2(-14.174, -2.9)
		"aim_side_down", "aim side down run": match facing:
			"right": $BulletPosition.position = Vector2(20, 6)
			"left": $BulletPosition.position = Vector2(-20, 6)
		"aim_side_up", "aim side up run": match facing:
			"right": $BulletPosition.position = Vector2(22, -26.1)
			"left": $BulletPosition.position = Vector2(-22, -26.1)
		"aim up standing": match facing:
			"right": $BulletPosition.position = Vector2(1.914, -32.835)
			"left": $BulletPosition.position = Vector2(-1.914, -32.835)
		"crouch": match facing:
			"right": $BulletPosition.position = Vector2(13.251, 1)
			"left": $BulletPosition.position = Vector2(-13.251, 1)
			
		#verified
		"crouch aim up": match facing:
			"right": $BulletPosition.position = Vector2(-1.039, -29.692)
			"left": $BulletPosition.position = Vector2(1.992, -29.692)
			
		#verified
		"crouch aim side up": match facing:
			"right": $BulletPosition.position = Vector2(18.104, -21.055)
			"left": $BulletPosition.position = Vector2(-17.021, -22.021)
			
		#verified
		"crouch aim side down": match facing:
			"right": $BulletPosition.position = Vector2(16.997, 10.015)
			"left": $BulletPosition.position = Vector2(-16.046, 10.015)
			
	if not result:
		return

	$Hitbox.get_shape().set_extents(result[0])
	$Hitbox.position = result[1]

func endHitstun():
	hitstun = false
	velocity = Vector2(0, 0)

func _on_IFrameTimer_timeout():
	$IFrameTimer.stop()
	invincible = false

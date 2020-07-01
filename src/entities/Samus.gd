extends KinematicBody2D

export var playFanfare = false

const walkSpeedCap = 150
const runSpeedCap = 250
const airSpeedCap = 150

const walkSpeed = 17
const airSpeed = 15

const runDeceleration = 0.3

const jumpPower = 50
const jumpCap = 500
const gravity = 20
const jumpGravity = 20

const canSpinJumpInAir = false

const FLOOR = Vector2(0, -1)
var invincible = false
var run_physics = false
var velocity = Vector2()
var direction = ""
var facing = "right"
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
var animCache: String
var HUD: Control

var weaponList = [
	
	["standard", 0, 0.35, ""], 
	["missile", 0, 0.1, 20],
	["super missile", 0, 0.2, 20]
	]

const sounds = {
	"loadmusic": preload("res://assets/sounds/loadmusic.ogg"),
	"spin": preload("res://assets/sounds/samus/Spin.ogg"),
	"death": preload("res://assets/sounds/samus/Death.ogg"),
	"land": preload("res://assets/sounds/samus/Land.ogg"),
	"damage": preload("res://assets/sounds/samus/Injure.ogg"),
	"click": preload("res://assets/sounds/other/Click.ogg")
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
		$AnimatedSprite.play("neutral")
		mode = "neutral"
		facing = "neutral"
		yield(playSound("loadmusic"), "finished")
		invincible = false
	
	setHitBox()
	run_physics = true
		

func _physics_process(delta):
	
	if not run_physics:
		return
	
	movementHandler(delta)
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
				elif falling:
					animate("falling")
				else:
					animate("rising")
			"crouch":
				animate("crouch")

	# apply gravity to the velocity
	velocity.y += gravity
	if mode == "jumpfall":
		velocity.y += jumpGravity
	
	# move based on final velocity
	velocity = move_and_slide(velocity, FLOOR)
	
	if "spin" in $AnimatedSprite.animation and spinChannel is String:
		spinChannel = playSound("spin")

	elif not "spin" in $AnimatedSprite.animation and not spinChannel is String:
		spinChannel.stop()
		spinChannel = ""
	

func movementHandler(delt):
	if Input.is_action_just_pressed("fire_shot"):
		shot()
	
	if Input.is_action_just_pressed("cancel_selection"):
		cycleWeapon("cancel")
	
	if (Input.is_action_pressed("aim_up") and Input.is_action_pressed("aim_down")) or (mode == "idle" and Input.is_action_pressed("ui_up")):
		if aiming == "side down":
			turnAnimation("aim_side_up")
		aiming = "up"


	elif Input.is_action_pressed("aim_up") or (mode == "run" and Input.is_action_pressed("up")):
		aiming = "side up"
	elif Input.is_action_pressed("aim_down") or (mode == "run" and Input.is_action_pressed("crouch")):
		if aiming == "up":
			turnAnimation("aim_side_up")
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
			velocity.y -= jumpPower
			
			if not round(velocity.x) - 10 <= 0 or not round(velocity.x) + 10 >= 0:
				spinning = true
			else:
				turnAnimation("rising turn")
			return

		var cap = walkSpeedCap
		
		if Input.is_action_pressed("run"):
			cap = runSpeedCap
		
		if Input.is_action_pressed("move_left"):
			mode = "run"
			
			if velocity.x > -cap:
				velocity.x -= walkSpeed
		elif Input.is_action_pressed("move_right"):
			mode = "run"
			
			if velocity.x < cap:
				velocity.x += walkSpeed
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
			return
			
		if (Input.is_action_just_released("jump") or velocity.y <= -jumpCap or is_on_ceiling()) and not falling:
			falling = true
			if not spinning:
				turnAnimation("falling turn")
			
		if not falling:
			velocity.y = min(velocity.y - jumpPower, jumpCap)
			
	elif mode == "crouch":
		
		if Input.is_action_just_pressed("move_left"):
			if startFacing == "left":
				mode = "run"
				self.position.y -= 10
				return
			else:
				turnAnimation("crouch turn")
				
		elif Input.is_action_just_pressed("move_right"):
			if startFacing == "right":
				mode = "run"
				self.position.y -= 10
				return
			else:
				turnAnimation("crouch turn")
			
		elif Input.is_action_just_pressed("jump"):
			mode = "jump"
			falling = false
			velocity.y -= jumpPower
			
			if not round(velocity.x) - 10 <= 0 or not round(velocity.x) + 10 >= 0:
				spinning = true
			else:
				turnAnimation("rising turn")
			return
		elif Input.is_action_just_pressed("up"):
			mode = "idle"
			self.position.y -= 10
			
	for weapon in weaponList:
		if weapon[1] > 0:
			weapon[1] = max(weapon[1] - delt, 0)


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
	
	if $AnimatedSprite.animation == "turn standing":
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
	
	

func damageHandler(type):
	
	if invincible:
		return
	
	var dmg = 0
	
	match type:
		"zoomer 01": dmg = -5
		"geemer": dmg = -10
		
	if setHealth(dmg) == "death":
		return

	invincible = true
	
	playSound("damage")
	$AnimatedSprite.modulate = Color(2, 2, 2, 1 )
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
		
	$AnimatedSprite.playing = false
		
	$Hitbox.call_deferred("disabled", true)
	$Hitbox.disabled = true
		
	$AnimationPlayer.play("death1")
	yield($AnimationPlayer, "animation_finished")
	
	playSound("death")
	$AnimatedSprite.playing = true
	
	$AnimatedSprite.play("death_0")
	yield($AnimatedSprite, "animation_finished")
	
	$AnimatedSprite.play("death_1")
	yield($AnimatedSprite, "animation_finished")
	
	$AnimationPlayer.play("death2")
	$AnimatedSprite.play("death_2")
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

func _on_AnimatedSprite_animation_finished():
	awaitAnimation = false


func animate(anim:String, dir: String = facing):
	
	if anim == animCache:
		return
	else:
		animCache = anim
	
	var sprite = $AnimatedSprite
	
	match dir.to_lower():
		"right": sprite.flip_h = true
		"left": sprite.flip_h = false

	sprite.play(anim)
	setHitBox()
	return sprite

func turnAnimation(anim):
	if not awaitAnimation and not "turn" in $AnimatedSprite.animation:
		awaitAnimation = true
		animate(anim)

func setHitBox():

	
	var result: Array

	match $AnimatedSprite.animation:
		"neutral": result = [Vector2(4.5498, 26.2698), Vector2(0.110184, -0.550914)]
		"idle", "run", "turn standing", "aim_side_up", "aim_side_down", "aim side up run", "aim side down run", "aim up standing": result = [Vector2(4.51672, 23.4076), Vector2(0, 1.10183)]
		"spin": result = [Vector2(5.52311, 13.3218), Vector2(-0.042957, 0.010602)]
		"crouch": match facing:
			"left": result = [Vector2(6.55, 17.67), Vector2(3.88, -0.957)]
			"right": result = [Vector2(6.55, 17.67), Vector2(-3.065, -0.957)]
		
	match $AnimatedSprite.animation:
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
		
	if not result:
		return

	$Hitbox.get_shape().set_extents(result[0])
	$Hitbox.position = result[1]


func _on_IFrameTimer_timeout():
	$IFrameTimer.stop()
	invincible = false

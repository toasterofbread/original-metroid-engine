extends Area2D

var wait = 1
var samus: KinematicBody2D
var knockback = false
var finished = false

var type: String

const bombSound = preload("res://assets/sounds/Bomb.ogg")

func _ready():
	samus = get_parent().get_node("Samus")
	
	$AnimatedSprite.animation = type

			

func _physics_process(_delta):
	
	if knockback:
		
		for child in get_parent().get_children():
			if overlaps_body(child):
				if child == samus:
					if samus.mode == "morph ball":
						samus.velocity.y = -175
				elif child.get_class() != "TileMap":
					child.handleShot("bomb")


	


func _on_AnimatedSprite_animation_finished():
	if wait == 0:
		$AnimatedSprite.speed_scale = 1.75
	elif wait == -2:
		
		if type == "bomb":
			knockback = true
		
			$AnimatedSprite.animation = "explosion"
			
			$AudioStreamPlayer.stream = bombSound
			$AudioStreamPlayer.play()
			yield($AnimatedSprite, "animation_finished")
			
			knockback = false
			finished = true
			$AnimatedSprite.visible = false
			
			yield($AudioStreamPlayer, "finished")
			queue_free()
		elif type == "power bomb":
			knockback = true
			$AnimationPlayer.play("power bomb")
			yield($AnimationPlayer, "animation_finished")
			queue_free()
			

	wait -= 1
		

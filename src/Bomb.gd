extends Area2D

var wait = 1
var samus: KinematicBody2D
var knockback = false
var finished = false

func _ready():
	for child in get_parent().get_children():
		if child.name == "Samus":
			samus = child
			break
			

func _physics_process(_delta):
	
	if knockback:
		
		for child in get_parent().get_children():
			if overlaps_body(child):
				if child.name == "Samus":
					if child.mode == "morph ball":
						samus.velocity.y -= 30

				else:
					child.handleShot("bomb")
		
		

	


func _on_AnimatedSprite_animation_finished():
	if wait == 0:
		$AnimatedSprite.speed_scale = 1.75
	elif wait == -3:
		
		knockback = true
		
		$AnimatedSprite.animation = "explosion"
		
		$AudioStreamPlayer.play()
		yield($AnimatedSprite, "animation_finished")
		
		knockback = false
		finished = true
		$AnimatedSprite.visible = false
		
		yield($AudioStreamPlayer, "finished")
		queue_free()

	wait -= 1
		

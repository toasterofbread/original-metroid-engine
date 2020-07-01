extends KinematicBody2D

const speed = 30
const gravity = 500
const FLOOR = Vector2(0, -1)
var velocity = Vector2(speed, gravity)
var dead = false
var wait = false

export var enemyType: String

func _ready():

	if not enemyType:
		print("The enemyType variable has not been set")
		get_tree().quit()
	else:
		$AnimatedSprite.play(enemyType.to_lower())
		
	match int(round(self.rotation_degrees)):
		0: velocity = Vector2(speed, gravity)
		90, -270: velocity = Vector2(-gravity, speed)
		180, -180: velocity = Vector2(-speed, -gravity)
		270, -90: velocity = Vector2(gravity, -speed)
		

func _physics_process(_delta):
	if not dead :
		check_collision()

		move_and_slide(velocity, FLOOR)

func handleShot(type):
	if type == "standard" or type == "missile":
		dead = true
		
		get_node("CollisionShape2D").set_deferred("disabled", true)
		$AnimatedSprite.play("death")
		
		var pickup = preload("res://src/entities/itemPickup.tscn")
		var drops = []
		
		drops.append(pickup.instance())
			
		yield($AnimatedSprite, "animation_finished")
		
		for drop in drops:
			drop.setPickupType("energySmall")
			
			get_parent().add_child(drop)
			drop.position = $AnimatedSprite.global_position
		
		queue_free()

func _on_Area2D_body_entered(body):
	if "Samus" in body.name and not dead:
		body.damageHandler(enemyType.to_lower())

func check_collision():

	if not $DownRayCaster.is_colliding() and not wait:
		wait = true
		if self.rotation_degrees == 270:
			self.rotation_degrees = 0
		else:
			self.rotation_degrees += 90

		match int(round(self.rotation_degrees)):
			0: velocity = Vector2(speed, gravity)
			90, -270: velocity = Vector2(-gravity, speed)
			180, -180: velocity = Vector2(-speed, -gravity)
			270, -90: velocity = Vector2(gravity, -speed)
			
	elif $SideRayCaster.is_colliding() and not wait:
		if self.rotation_degrees == 0:
			self.rotation_degrees = 270
		else:
			self.rotation_degrees -= 90
		
		match int(round(self.rotation_degrees)):
			0: velocity = Vector2(speed, gravity)
			90, -270: velocity = Vector2(-gravity, speed)
			180, -180: velocity = Vector2(-speed, -gravity)
			270, -90: velocity = Vector2(gravity, -speed)
			
		
	if $DownRayCaster.is_colliding() and wait:
		wait = false

	

extends Node2D
tool

export (String, FILE) var destination_level
export var facing: String
export var type: String
export var door_id: int
export var smooth_transition = false


var open = false
var transition = false
var camera: Camera2D
var samus: KinematicBody2D

var dest = Vector2.ZERO
var transcount = 0

var level: PackedScene


func _ready():
	
	samus = get_parent().get_node("Samus")
	camera = samus.get_node("Camera2D")

	match facing:
		"right": self.rotation_degrees = 0
		"down": self.rotation_degrees = 90
		"left": self.rotation_degrees = 180
		"up": self.rotation_degrees = 270
		
		
	var trans = GLOBAL.transitionMode
	if trans != null:
		if trans["id"] == door_id:
			
			GLOBAL.transitionMode = null
			get_tree().paused = true
			
			var pos = position
			
			match facing:
				"right": pos.x += 20
				"left": pos.x -= 20
				"up": pos.y -= 20
				"down": pos.y += 20
			
			samus.position = pos
			
			$GhostDoor.visible = true
			$DoorCover/AnimatedSprite.visible = false
			$CanvasLayer/ColorRect.visible = true
			$CanvasLayer/ColorRect.modulate = Color(1, 1, 1, 1)
			
			var node: String
			match trans["facing"]:
				"left": 
					node = "SpriteLeft"
					samus.get_node("SpriteRight").visible = false
				"right": 
					node = "SpriteRight"
					samus.get_node("SpriteLeft").visible = false
			
			samus.get_node(node).animation = trans["anim"]
			samus.get_node(node).frame = trans["frame"]
			samus.get_node(node).playing = true
			
			for child in get_parent().get_children():
				if child != self:
					child.visible = false
			
			$Camera2D.zoom = camera.zoom
			var res = camera.get_viewport().get_size_override()
			camera.current = false
			$Camera2D.current = true
			
			var dest = camera.global_position
			
			match facing:
				"right": 
					$Camera2D.position.x += (res.x / 2)
					dest.x += res.x / 2 - 20
				"left": 
					dest.x -= res.x / 2 - 20
					$Camera2D.position.x -= (res.x / 2)
				"up": 
					$Camera2D.position.y -= (res.y / 2)
				"down": 
					$Camera2D.position.y += (res.y / 2)
			
			
			
			var tween = get_node("Tween")
			tween.interpolate_property($Camera2D, "global_position",
					$Camera2D.global_position, dest, 2,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
					
			tween.start()
			yield(tween, "tween_completed")
			tween.stop_all()
			
			for child in get_parent().get_children():
				child.visible = true
			
			$Camera2D.current = false
			camera.current = true
			
			$AnimationPlayer.play("fade from black")
			yield($AnimationPlayer, "animation_finished")
			
			get_tree().paused = false
			
			$DoorCover/AnimatedSprite.animation = type + " close"
			$GhostDoor.visible = false
			$AnimationPlayer.play("wait then close")
			yield($AnimationPlayer, "animation_finished")
			$DoorCover/AnimatedSprite.playing = false
			$DoorCover/AnimatedSprite.animation = type
			
			
		
		
		
		
func _physics_process(delta):
	if transition and smooth_transition and transcount < 90:
		self.position = lerp(self.position, dest, 0.04)
		transcount += 1

	elif transcount == 90:
		self.position = dest
		transition = false
		transition()

func _on_DoorMain_body_entered(body):
	if open and not transition:
		
		get_parent().get_node("Samus").run_physics = false
		
		for child in get_parent().get_children():
			if child != self and not child.get_class() in ["CanvasLayer"]:
				child.visible = false
		 
		$AnimationPlayer.play("fade to black")
		transition = true

		dest = camera.get_camera_screen_center()

		var res = camera.get_viewport().get_size_override()

		match facing:
			"right": dest.x -= res.x / 2 - 12
			"left": dest.x += res.x / 2 - 12
			"up": dest.y += res.y / 2 - 12
			"down": dest.y -= res.y / 2 - 12

		if not smooth_transition:
			var tween = get_node("Tween")
			tween.interpolate_property(self, "position",
					self.global_position, dest, 1.5,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
					
			tween.start()
			yield(tween, "tween_completed")
			tween.stop_all()
			transition()
		else:
			transition = true
				
func transition():
	get_parent().get_node("Samus").saveData()
	
	GLOBAL.transitionMode = {"id": door_id, "anim": samus.get_node("SpriteLeft").animation, "frame": samus.get_node("SpriteLeft").frame, "facing": samus.facing}
	
	get_tree().change_scene_to(load(destination_level))
	
func handleShot(_type):
	return

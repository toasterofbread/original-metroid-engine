extends Node2D

func _physics_process(delta):

	if Input.is_action_just_pressed("pause"):
		startMain()


func startMain():
	
	$CanvasLayer/ColorRect.visible = false
	$CanvasLayer/RichTextLabel.visible = false
	$"CanvasLayer/Opening logo".visible = false
		
	$Camera2D.position = Vector2(128, 112)
	$Camera2D.zoom = Vector2(1, 1)
	
	$MainAudio.play(25)
	
	$AnimationPlayer.stop()
	
	$SuperMetroidLogo.visible = true
	$SuperMetroidLogo.modulate = Color(1, 1, 1, 1)
	
	$AnimatedSprite.modulate = Color(1, 1, 1, 1)
	$AnimatedSprite.playing = true
	$AnimationPlayer.play("main screen")

	$BabyMetroidTank/AnimationPlayer.play("main loop")
	$BabyMetroidTank/AnimatedSprite.playing = true
	
func startBaby():
	
	$BabyMetroidTank/AnimatedSprite.playing = true
	$BabyMetroidTank/AnimationPlayer.play("main loop")
	
func startLighting():
	$LightingController.play("main")

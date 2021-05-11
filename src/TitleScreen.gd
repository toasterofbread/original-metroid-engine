extends Node2D

var current_mode = "intro"
var fade_mode = ""
const spinsound = preload("res://assets/sounds/samus/Spin (no loop).ogg")

var saves = [
	{"used" : false, "slot": 1},
	{"used" : false, "slot": 2},
	{"used" : false, "slot": 3}
]

func _physics_process(_delta):
	print(current_mode)
	if current_mode == "save selection":
		if Input.is_action_just_pressed("ui_accept"):
		
			var slot: AnimatedSprite
			
			match $SaveSelectionScreen/MenuSelector.get_position():
				0: slot = $"SaveSelectionScreen/Slot 1"
				1: slot = $"SaveSelectionScreen/Slot 2"
				2: slot = $"SaveSelectionScreen/Slot 3"
				
				3: get_tree().change_scene("res://src/levels/Level01.tscn")
				
			if slot:
				$SelectAudio.stream = spinsound
				$SelectAudio.play()
				slot.play()
				$SaveSelectionScreen/MenuSelector.setStatus(false)
				yield(slot, "animation_finished")
				$SelectAudio.stop()
				
				get_tree().change_scene("res://src/levels/Level01.tscn")

	elif (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_accept")) and not $"CanvasLayer/Opening logo".visible:
		match current_mode:
			"intro":
				$MainAudio.stop()
				$CanvasLayer/RichTextLabel.visible = false
				$FadeAnimator.play("fade")
				fade_mode = "start main"
			"title":
				$FadeAnimator.play("fade")
				fade_mode = "next"
				
				
	
func _ready():
	$FadeCanvas/ColorRect.visible = false
	$SaveSelectionScreen/MenuSelector.on = false
	$SaveSelectionScreen.visible = false
	
func saveSelectionReady():
	
	var no_saves = true
	for save in saves:
		var slot: AnimatedSprite
		match save["slot"]:
			1: slot = $"SaveSelectionScreen/Slot 1"
			2: slot = $"SaveSelectionScreen/Slot 2"
			3: slot = $"SaveSelectionScreen/Slot 3"
		
		for child in slot.get_children():
			if child.name == "NO DATA":
				if save["used"]:
					no_saves = false
					child.visible = true
				else:
					child.visible = false
	if no_saves:
		for child in $SaveSelectionScreen.get_children():
			if "pos" in child.name:
				child.name = "pos" + child.name[3]
		
		$SaveSelectionScreen/Text.frame = 1
	else:
		for child in $SaveSelectionScreen.get_children():
			if "pos" in child.name:
				child.name = "pos" + child.name[3] + " MenuLocation"
		
		$SaveSelectionScreen/Text.frame = 0
	
	$SaveSelectionScreen/MenuSelector.resetPositions()
		
func restartIntro():
	$AnimationPlayer.play("start")
	$AnimationPlayer.seek(4.0, true)

func startMain(fade):
	
	current_mode = "title"

	$CanvasLayer/ColorRect.visible = false
	
	$CanvasLayer/RichTextLabel.visible = false
	$"CanvasLayer/Opening logo".visible = false
		
	$Camera2D.position = Vector2(128, 112)
	$Camera2D.zoom = Vector2(1, 1)
	
	$AnimationPlayer.stop()
	
	$SuperMetroidLogo.visible = true
	$SuperMetroidLogo.modulate = Color(1, 1, 1, 1)
	
	$AnimatedSprite.modulate = Color(1, 1, 1, 1)
	$AnimatedSprite.playing = true

	$BabyMetroidTank/AnimationPlayer.play("main loop")
	$BabyMetroidTank/AnimatedSprite.playing = true
	
	if fade:
		yield($FadeAnimator, "animation_finished")

	$MainAudio.play(25)
	

func startBaby():
	
	$BabyMetroidTank/AnimatedSprite.playing = true
	$BabyMetroidTank/AnimationPlayer.play("main loop")
	
func startLighting():
	$LightingController.play("main")
	
func setmode():
	current_mode = "title"
	
func endFade():
	match fade_mode:
		"start main": startMain(true)
		"next": 
			
			$BabyMetroidTank/AnimationPlayer.stop()
			$BabyMetroidTank/AudioStreamPlayer2D.stop()
			$AnimationPlayer.stop()
			$SaveSelectionScreen.visible = true
			$CanvasLayer/ColorRect.visible = false
			current_mode = "save selection"
			
			saveSelectionReady()
			
			yield($FadeAnimator, "animation_finished")
			
			$SaveSelectionScreen/MenuSelector.on = true

func _on_MainAudio_finished():
	if current_mode == "title":
		restartIntro()

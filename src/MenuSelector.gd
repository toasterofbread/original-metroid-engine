extends Node2D

export var locatorName: String = "MenuLocation"
var menuItems = []
var currentPosition = 0
var singleItem = false
var output = ""
var audioChannels = []
var on = true
const click = preload("res://assets/sounds/other/Click.ogg")

func _ready():
	
	for child in get_parent().get_children():
		if child.get_class() == "Position2D" and locatorName in child.name:
			menuItems.append(child)
			
	for child in self.get_children():
		if child.get_class() == "AudioStreamPlayer":
			audioChannels.append(child)
			
	self.global_position = menuItems[0].global_position
	self.visible = true
	
	if len(menuItems) == 0:
		print("There are no locators for the MenuSelector to attach to")
	elif len(menuItems) == 1:
		singleItem = true
	

	
func _physics_process(_delta):
	
	if on:
		if Input.is_action_just_pressed("ui_up"):
			self.global_position = menuItems[get_next_position("up")].global_position
		elif Input.is_action_just_pressed("ui_down"):
			self.global_position = menuItems[get_next_position("down")].global_position

func get_next_position(dir):
	if singleItem:
		return
	elif dir == "up":
		if currentPosition == 0:
			output = len(menuItems) - 1
		else:
			output = currentPosition - 1
	elif dir == "down":
		if currentPosition == len(menuItems) - 1:
			output = 0
		else:
			output = currentPosition + 1

	playSound(click)

	currentPosition = output
	return output

func get_position():
	return currentPosition


func playSound(sound):
	
	for channel in audioChannels:
		if not channel.playing:
			channel.stream = sound
			channel.play()
			return channel

	print("Not enough audio channels!")
	
func setStatus(stat:bool):
	on = stat
	
func resetPositions():
	menuItems = []
	
	for child in get_parent().get_children():
		if child.get_class() == "Position2D" and locatorName in child.name:
			menuItems.append(child)

extends Control

var cycleWeapons: Array
const ItemIcon = preload("res://src/ItemIcon.tscn")
const ItemIconMissile = preload("res://src/ItemIcon (missile).tscn")
var weaponNodes = {}
var missilePlaced = false

func _ready():
	for child in get_parent().get_children():
		if "Samus" in child.name:
			cycleWeapons = child.cycleWeapon("query")
			break
			
	var count = 0
	for weapon in cycleWeapons:
		
		if count == 0:
			pass
		else:
			weapon = weapon[0]
			
			var item: AnimatedSprite
			if weapon == "missile":
				item = ItemIconMissile.instance()
			else:
				item = ItemIcon.instance()
				
			item.animation = weapon
			item.play()
				
			var pos: Vector2
			match count:
				1: pos = $CanvasLayer/ItemPos1.global_position
				2: pos = $CanvasLayer/ItemPos2.global_position
				3: pos = $CanvasLayer/ItemPos3.global_position
				4: pos = $CanvasLayer/ItemPos4.global_position
				5: pos = $CanvasLayer/ItemPos5.global_position
				
			if missilePlaced:
				pos.x += 8
				
			if weapon == "missile":
				missilePlaced = true
				pos.x += 4

			item.global_position = pos
			
			if weapon == "grapple beam" or weapon == "x ray":
				for child in item.get_children():
					child.queue_free()
					
			
			$CanvasLayer.add_child(item)
			
			weaponNodes[weapon] = item

				
		count += 1
		

func set_amount(value, amount):

	var node = ""
	if value == "energy":
		node = $CanvasLayer/EnergyText
	else:
		node = weaponNodes[value]

	amount = String(amount)
	var length = len(amount)
	
	if value == "missile":
		if length == 1:
			amount = "00" + amount
		elif length == 2:
			amount = "0" + amount
	else:
		if length == 1:
			amount = "0" + amount
	
	var count = 0		
	for child in node.get_children():
		child.frame = int(amount[count])
		count += 1
		
func get_amount(type):
	return
		
func select_weapon(weapon):
	
	for icon in Array(weaponNodes.keys()):
		if icon == weapon:
			weaponNodes[icon].frame = 1
		else:
			weaponNodes[icon].frame = 0

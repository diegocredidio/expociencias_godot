extends Node

# Door Debug Script - Para facilitar identificação e teste das portas
# Adicione este script como um nó autônomo na cena para debug

var dungeon_level: Node

func _ready():
	print("🚪 Door Debug System initialized")
	# Find dungeon level
	dungeon_level = get_tree().get_first_node_in_group("dungeon_level")
	if not dungeon_level:
		print("❌ DungeonLevel not found!")
		return
	
	# Wait a bit for doors to register
	await get_tree().create_timer(1.0).timeout
	print_door_status()

func _input(event):
	if event.is_action_pressed("ui_accept"): # Space key
		print_door_status()
	elif event.is_action_pressed("ui_select"): # Enter key
		test_door_unlock()
	elif event.is_action_pressed("ui_cancel"): # Escape key
		test_door_lock()

func print_door_status():
	if not dungeon_level:
		return
	
	print("\n🚪 === DOOR DEBUG STATUS ===")
	var stats = dungeon_level.get_door_statistics()
	print("🚪 Total doors: ", stats["total_doors"])
	print("🚪 Locked doors: ", stats["locked_doors"])
	print("🚪 Unlocked doors: ", stats["unlocked_doors"])
	
	print("\n🚪 === DOOR DETAILS ===")
	var all_doors = dungeon_level.get_all_doors()
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.has_method("get_door_info"):
			var info = door.get_door_info()
			var status = "🔒 LOCKED" if info["is_locked"] else "🔓 UNLOCKED"
			var blocking = "🚫 BLOCKING" if door.is_door_blocking() else "✅ PASSABLE"
			print("🚪 ", door_id, " - ", status, " - ", blocking)
			print("    📝 ", info["description"])
			print("    🎯 Requires: ", door.get_unlock_requirement())
			print("    📍 Position: ", info["position"])
			print("")

func test_door_unlock():
	if not dungeon_level:
		return
	
	print("🚪 Testing door unlock...")
	var locked_doors = dungeon_level.get_locked_doors()
	if locked_doors.size() > 0:
		var door = locked_doors[0]
		if door.has_method("force_unlock"):
			door.force_unlock()
			print("🚪 Unlocked: ", door.door_id)
	else:
		print("🚪 No locked doors to test")

func test_door_lock():
	if not dungeon_level:
		return
	
	print("🔒 Testing door lock...")
	var unlocked_doors = dungeon_level.get_unlocked_doors()
	if unlocked_doors.size() > 0:
		var door = unlocked_doors[0]
		if door.has_method("force_lock"):
			door.force_lock()
			print("🔒 Locked: ", door.door_id)
	else:
		print("🔒 No unlocked doors to test")

func get_door_by_position(player_position: Vector3) -> Node:
	# Find the closest door to player position
	if not dungeon_level:
		return null
	
	var all_doors = dungeon_level.get_all_doors()
	var closest_door = null
	var closest_distance = INF
	
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door:
			var distance = player_position.distance_to(door.global_position)
			if distance < 10.0 and distance < closest_distance: # Within 10 units
				closest_distance = distance
				closest_door = door
	
	return closest_door

func print_controls():
	print("\n🎮 === DOOR DEBUG CONTROLS ===")
	print("🎮 SPACE - Print door status")
	print("🎮 ENTER - Test unlock closest door")
	print("🎮 ESCAPE - Test lock closest door")
	print("🎮 === END CONTROLS ===\n")

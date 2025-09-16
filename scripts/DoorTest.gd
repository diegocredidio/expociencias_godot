extends Node

# Script de teste para verificar o sistema de portas
# Adicione este script como nó autônomo na cena para debug

var dungeon_level: Node

func _ready():
	print("🚪 Door Test System initialized")
	# Find dungeon level
	dungeon_level = get_tree().get_first_node_in_group("dungeon_level")
	if not dungeon_level:
		print("❌ DungeonLevel not found!")
		return
	
	# Wait a bit for doors to register
	await get_tree().create_timer(2.0).timeout
	test_door_system()

func _input(event):
	if event.is_action_pressed("ui_accept"): # Space key
		test_door_system()
	elif event.is_action_pressed("ui_select"): # Enter key
		test_unlock_biology_door()

func test_door_system():
	if not dungeon_level:
		return
	
	print("\n🚪 === DOOR TEST SYSTEM ===")
	
	# Test simple doors
	var simple_doors = dungeon_level.get_simple_doors()
	print("🚪 Simple doors count: ", simple_doors.size())
	
	for door_id in simple_doors:
		var door = simple_doors[door_id]
		if door:
			var info = door.get_door_info()
			print("🚪 Door: ", door_id)
			print("   📝 Required NPC: ", info["required_npc"])
			print("   🔒 Is locked: ", info["is_locked"])
			print("   📍 Position: ", info["position"])
	
	# Test unlock by NPC
	print("\n🚪 Testing unlock by NPC 'Prof. Silva'...")
	var result = dungeon_level.unlock_simple_door_by_npc("Prof. Silva")
	print("🚪 Unlock result: ", result)
	
	print("🚪 === END DOOR TEST ===\n")

func test_unlock_biology_door():
	if not dungeon_level:
		return
	
	print("🚪 Testing direct unlock of biology door...")
	var result = dungeon_level.unlock_simple_door_by_id("door_to_biology")
	print("🚪 Direct unlock result: ", result)

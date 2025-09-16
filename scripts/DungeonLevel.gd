extends Node3D

@onready var dungeon_pieces = []
var room_doors = {} # Store door references by room_id
var all_doors = {} # Store all door references by door_id
var door_registry = {} # Registry for door management
var simple_doors = {} # Store simple doors by door_id

func _ready():
	# Add this node to the dungeon_level group for door registration
	add_to_group("dungeon_level")
	
	setup_dungeon_structure()
	setup_doors()
	add_collision_to_rooms()
	
	# Print door system status
	print_door_system_status()
	print_simple_door_status()

func setup_dungeon_structure():
	load_dungeon_pieces()
	build_dungeon_layout()

func load_dungeon_pieces():
	# Commented out - rooms are now created via .tscn file only
	# This prevents duplicate room creation
	print("Using rooms from DungeonLevel.tscn file instead of programmatic creation")

func build_dungeon_layout():
	pass

func setup_doors():
	# Find all doors in the scene and register them
	var doors = find_children("Door*", "StaticBody3D", true, false)
	for door in doors:
		if door.has_method("unlock_door"):
			room_doors[door.door_id] = door
			print("🚪 Registered door: ", door.door_id)
	
	print("🚪 Door system initialized with ", room_doors.size(), " doors")

func create_gate_barrier(gate_node):
	var barrier_mesh = BoxMesh.new()
	barrier_mesh.size = Vector3(1, 3, 0.2)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = barrier_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	mesh_instance.material_override = material
	
	gate_node.add_child(mesh_instance)
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, 3, 0.2)
	collision_shape.shape = box_shape
	gate_node.add_child(collision_shape)

func add_collision_to_rooms():
	print("Adding collision to room models...")
	var rooms = [
		$StartingRoom/RoomModel,
		$BiologyRoom/RoomModel,
		$ScienceRoom/RoomModel,
		$FinalRoom/RoomModel
	]
	
	for room in rooms:
		if room:
			add_collision_to_mesh_instances(room)

func add_collision_to_mesh_instances(node: Node):
	if node is MeshInstance3D and node.mesh:
		# Create StaticBody3D for collision
		var static_body = StaticBody3D.new()
		static_body.name = "WallCollision"
		
		var collision_shape = CollisionShape3D.new()
		var trimesh_shape = node.mesh.create_trimesh_shape()
		
		collision_shape.shape = trimesh_shape
		static_body.add_child(collision_shape)
		node.add_child(static_body)
		
		print("Added collision to: ", node.name)
	
	# Recursively check child nodes
	for child in node.get_children():
		add_collision_to_mesh_instances(child)

func unlock_room(room_id: String):
	# Use new door system
	unlock_door_to_room(room_id)
	print("Unlocking room: ", room_id)

func unlock_door_to_room(target_room_id: String):
	# Map room_id to door_id
	var door_mapping = {
		"biology_room": "door_to_biology",
		"science_room": "door_to_science",
		"final_room": "door_to_final"
	}
	
	var door_id = door_mapping.get(target_room_id, "")
	if door_id != "" and door_id in room_doors:
		var door = room_doors[door_id]
		if door and door.has_method("unlock_door"):
			door.unlock_door()
			print("🚪 Unlocked door to ", target_room_id)
			return
	
	print("🚪 No door found for room: ", target_room_id)

func unlock_door_by_npc(npc_name: String):
	# Find door that requires this NPC to be completed
	for door_id in room_doors:
		var door = room_doors[door_id]
		if door and door.required_npc == npc_name and door.has_method("unlock_door"):
			door.unlock_door()
			print("🚪 Unlocked door after completing NPC: ", npc_name)
			return
	
	print("🚪 No door found for NPC: ", npc_name)

func lock_door(door_id: String):
	if door_id in room_doors:
		var door = room_doors[door_id]
		if door and door.has_method("lock_door"):
			door.lock_door()

func is_door_locked(door_id: String) -> bool:
	if door_id in room_doors:
		var door = room_doors[door_id]
		if door:
			return door.is_locked
	return false

# === ENHANCED DOOR MANAGEMENT SYSTEM ===

func register_door(door_node):
	# Register a door with the enhanced door management system
	if door_node and door_node.has_method("get_door_info"):
		var door_info = door_node.get_door_info()
		var door_id = door_info["door_id"]
		
		# Store in all_doors registry
		all_doors[door_id] = door_node
		
		# Store in door_registry with additional metadata
		door_registry[door_id] = {
			"node": door_node,
			"info": door_info,
			"registered_at": Time.get_unix_time_from_system(),
			"unlock_count": 0
		}
		
		print("🚪 Enhanced registration: ", door_id, " (", door_info["description"], ")")
		return true
	return false

func get_all_doors() -> Dictionary:
	# Return all registered doors
	return all_doors

func get_door_by_id(door_id: String):
	# Get a specific door by ID
	return all_doors.get(door_id, null)

func get_doors_by_npc(npc_name: String) -> Array:
	# Get all doors that require a specific NPC
	var doors = []
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.required_npc == npc_name:
			doors.append(door)
	return doors

func get_locked_doors() -> Array:
	# Get all currently locked doors
	var locked_doors = []
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.is_locked:
			locked_doors.append(door)
	return locked_doors

func get_unlocked_doors() -> Array:
	# Get all currently unlocked doors
	var unlocked_doors = []
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and not door.is_locked:
			unlocked_doors.append(door)
	return unlocked_doors

func unlock_door_by_id(door_id: String) -> bool:
	# Unlock a specific door by ID
	var door = all_doors.get(door_id, null)
	if door and door.has_method("unlock_door"):
		door.unlock_door()
		# Update registry
		if door_id in door_registry:
			door_registry[door_id]["unlock_count"] += 1
		print("🚪 Door unlocked by ID: ", door_id)
		return true
	print("🚪 Door not found or cannot be unlocked: ", door_id)
	return false

func lock_door_by_id(door_id: String) -> bool:
	# Lock a specific door by ID
	var door = all_doors.get(door_id, null)
	if door and door.has_method("lock_door"):
		door.lock_door()
		print("🔒 Door locked by ID: ", door_id)
		return true
	print("🔒 Door not found or cannot be locked: ", door_id)
	return false

func print_door_system_status():
	# Print comprehensive door system status
	print("\n🚪 === DOOR SYSTEM STATUS ===")
	print("🚪 Total doors registered: ", all_doors.size())
	print("🚪 Locked doors: ", get_locked_doors().size())
	print("🚪 Unlocked doors: ", get_unlocked_doors().size())
	
	print("\n🚪 === DOOR DETAILS ===")
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.has_method("get_door_info"):
			var info = door.get_door_info()
			var status = "🔒 LOCKED" if info["is_locked"] else "🔓 UNLOCKED"
			var requirement = info["required_npc"] if info["required_npc"] != "" else "No requirement"
			print("🚪 ", door_id, " - ", status, " - Requires: ", requirement)
			if info["description"] != "":
				print("    📝 ", info["description"])
	print("🚪 === END DOOR STATUS ===\n")

func get_door_statistics() -> Dictionary:
	# Return statistics about the door system
	var stats = {
		"total_doors": all_doors.size(),
		"locked_doors": get_locked_doors().size(),
		"unlocked_doors": get_unlocked_doors().size(),
		"doors_by_npc": {}
	}
	
	# Count doors by NPC requirement
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door:
			var npc = door.required_npc
			if npc != "":
				if not npc in stats["doors_by_npc"]:
					stats["doors_by_npc"][npc] = 0
				stats["doors_by_npc"][npc] += 1
	
	return stats

func force_unlock_all_doors():
	# Force unlock all doors (for debugging)
	print("🚪 Force unlocking all doors...")
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.has_method("force_unlock"):
			door.force_unlock()

func force_lock_all_doors():
	# Force lock all doors (for debugging)
	print("🔒 Force locking all doors...")
	for door_id in all_doors:
		var door = all_doors[door_id]
		if door and door.has_method("force_lock"):
			door.force_lock()

# === SIMPLE DOOR MANAGEMENT ===

func register_simple_door(door_node):
	# Register a simple door
	if door_node and door_node.has_method("get_door_info"):
		var door_info = door_node.get_door_info()
		var door_id = door_info["door_id"]
		
		simple_doors[door_id] = door_node
		print("🚪 Simple door registered: ", door_id)
		return true
	return false

func unlock_simple_door_by_npc(npc_name: String):
	print("🚪 === UNLOCK SIMPLE DOOR BY NPC ===")
	print("🚪 NPC Name: ", npc_name)
	print("🚪 Simple doors count: ", simple_doors.size())
	print("🚪 Simple doors keys: ", simple_doors.keys())
	
	# Unlock simple door by NPC name
	for door_id in simple_doors:
		var door = simple_doors[door_id]
		print("🚪 Checking door: ", door_id, " - Required NPC: ", door.required_npc if door else "null")
		if door and door.required_npc == npc_name:
			print("🚪 MATCH FOUND! Unlocking door: ", door_id)
			door.unlock_door()
			print("🚪 Simple door unlocked by NPC: ", npc_name, " (", door_id, ")")
			return true
	
	print("🚪 No simple door found for NPC: ", npc_name)
	return false

func unlock_simple_door_by_id(door_id: String):
	# Unlock simple door by ID
	if door_id in simple_doors:
		var door = simple_doors[door_id]
		if door:
			door.unlock_door()
			print("🚪 Simple door unlocked by ID: ", door_id)
			return true
	
	print("🚪 Simple door not found: ", door_id)
	return false

func get_simple_doors() -> Dictionary:
	return simple_doors

func print_simple_door_status():
	print("\n🚪 === SIMPLE DOOR STATUS ===")
	print("🚪 Total simple doors: ", simple_doors.size())
	
	for door_id in simple_doors:
		var door = simple_doors[door_id]
		if door:
			var status = "🔒 LOCKED" if door.is_locked else "🔓 UNLOCKED"
			var requirement = door.required_npc if door.required_npc != "" else "No requirement"
			print("🚪 ", door_id, " - ", status, " - Requires: ", requirement)
	
	print("🚪 === END SIMPLE DOOR STATUS ===\n")

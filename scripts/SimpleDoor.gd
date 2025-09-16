extends StaticBody3D

# Simple Door Script - Clean and functional
@export var door_id: String = "door_1"
@export var required_npc: String = ""
@export var is_locked: bool = true

# Door models
var closed_door_scene: PackedScene
var open_door_scene: PackedScene

# Components
@onready var door_model: Node3D
var collision_shape: CollisionShape3D

func _ready():
	print("🚪 Simple Door ", door_id, " initializing...")
	
	# Load door models
	closed_door_scene = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate-door.glb")
	open_door_scene = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate.glb")
	
	# Find door model
	door_model = get_node_or_null("DoorModel")
	if not door_model:
		print("⚠️ Warning: DoorModel not found for door ", door_id)
		return
	
	# Create collision shape
	setup_collision()
	
	# Set initial state
	update_door_state()
	
	# Register with door manager
	register_with_manager()
	
	print("🚪 Simple Door ", door_id, " ready!")

func setup_collision():
	# Create collision shape for blocking
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "DoorCollision"
	add_child(collision_shape)
	
	# Create box shape
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2, 3, 0.5) # Adjust size as needed
	collision_shape.shape = box_shape

func update_door_state():
	if not door_model:
		return
	
	if is_locked:
		# Locked state - closed door
		replace_door_model(closed_door_scene)
		if collision_shape:
			collision_shape.disabled = false
		print("🚪 Door ", door_id, " is LOCKED")
	else:
		# Unlocked state - open door
		replace_door_model(open_door_scene)
		if collision_shape:
			collision_shape.disabled = true
		print("🚪 Door ", door_id, " is OPEN")

func replace_door_model(new_scene: PackedScene):
	if not door_model or not new_scene:
		return
	
	# Store current transform
	var current_transform = door_model.transform
	
	# Remove old model
	door_model.queue_free()
	
	# Create new model
	var new_model = new_scene.instantiate()
	new_model.name = "DoorModel"
	new_model.transform = current_transform
	add_child(new_model)
	
	# Update reference
	door_model = new_model

func unlock_door():
	print("🚪 === UNLOCK DOOR CALLED ===")
	print("🚪 Door ID: ", door_id)
	print("🚪 Is locked: ", is_locked)
	print("🚪 Required NPC: ", required_npc)
	
	if is_locked:
		print("🚪 Door was locked, unlocking now...")
		is_locked = false
		play_unlock_animation()
		print("🎉 Door ", door_id, " unlocked!")
	else:
		print("🚪 Door was already unlocked!")

func play_unlock_animation():
	# Play unlock animation with visual effects
	if door_model:
		# Scale effect
		var tween = create_tween()
		tween.parallel().tween_property(door_model, "scale", Vector3(1.2, 1.2, 1.2), 0.3)
		tween.parallel().tween_property(door_model, "scale", Vector3(1.0, 1.0, 1.0), 0.3).set_delay(0.3)
		
		# Rotation effect (optional)
		var original_rotation = door_model.rotation
		tween.parallel().tween_property(door_model, "rotation", original_rotation + Vector3(0, 0.1, 0), 0.2)
		tween.parallel().tween_property(door_model, "rotation", original_rotation, 0.2).set_delay(0.2)
	
	# Wait for animation to start, then update door state
	await get_tree().create_timer(0.1).timeout
	update_door_state()

func lock_door():
	if not is_locked:
		is_locked = true
		update_door_state()
		print("🔒 Door ", door_id, " locked!")

func register_with_manager():
	# Register with dungeon level
	var dungeon_level = get_tree().get_first_node_in_group("dungeon_level")
	if dungeon_level and dungeon_level.has_method("register_simple_door"):
		dungeon_level.register_simple_door(self)
		print("🚪 Door ", door_id, " registered with manager")

func get_door_info() -> Dictionary:
	return {
		"door_id": door_id,
		"required_npc": required_npc,
		"is_locked": is_locked,
		"position": global_position
	}

extends StaticBody3D

@export var door_id: String = "door_1"
@export var required_npc: String = "" # NPC that needs to be completed to open
@export var is_locked: bool = true
@export var door_description: String = "" # Description for debugging/identification
@export var unlock_animation_duration: float = 1.0 # Duration of unlock animation

# Preload door models
var closed_door_scene: PackedScene
var open_door_scene: PackedScene

@onready var door_model = $DoorModel
@onready var collision = $BlockingCollision

var initial_door_transform: Transform3D

func _ready():
	print("🚪 Door ", door_id, " initializing...")
	
	# Load door models
	closed_door_scene = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate-door.glb")
	open_door_scene = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate.glb")
	
	# Store initial transform if door model exists
	if door_model:
		initial_door_transform = door_model.transform
	
	setup_door_appearance()
	update_door_state()
	
	# Register this door with the door manager
	register_with_door_manager()
	
	print("🚪 Door ", door_id, " ready!")
	if door_description != "":
		print("   📝 Description: ", door_description)

func setup_door_appearance():
	# The door model should be loaded as a child node from the scene
	if not door_model:
		door_model = get_node_or_null("DoorModel")
		if not door_model:
			print("⚠️ Warning: DoorModel not found for door ", door_id)
			return
	
	# Store the initial transform
	initial_door_transform = door_model.transform
	
	# Create collision shape for blocking (this will be controlled by lock state)
	if not collision:
		collision = CollisionShape3D.new()
		collision.name = "BlockingCollision"
		add_child(collision)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3, 4, 0.3) # Adjust to match gate model
	collision.shape = box_shape


func update_door_state():
	if is_locked:
		# Locked state - use closed door model
		replace_door_model(closed_door_scene)
		# Keep blocking collision active when locked
		if collision:
			collision.disabled = false
		print("🚪 Door ", door_id, " is LOCKED")
	else:
		# Unlocked state - use open door model
		replace_door_model(open_door_scene)
		# Disable blocking collision when unlocked
		if collision:
			collision.disabled = true
		print("🚪 Door ", door_id, " is OPEN")

func replace_door_model(new_scene: PackedScene):
	if door_model and new_scene:
		# Store the current transform
		var current_transform = door_model.transform
		
		# Remove the old model
		door_model.queue_free()
		
		# Create new model instance
		var new_model = new_scene.instantiate()
		new_model.name = "DoorModel"
		new_model.transform = current_transform
		
		# Add to scene
		add_child(new_model)
		door_model = new_model
		
		print("🚪 Replaced door model for ", door_id)


func unlock_door():
	if is_locked:
		is_locked = false
		update_door_state()
		
		# Play unlock animation/effect
		var tween = create_tween()
		tween.tween_method(_door_unlock_effect, 0.0, 1.0, 1.0)
		print("🎉 Door ", door_id, " has been unlocked!")

func _door_unlock_effect(progress: float):
	# Scale effect on the door model
	if door_model:
		var scale_factor = 1.0 + (0.1 * sin(progress * PI * 4))
		door_model.scale = Vector3(scale_factor, 1.0, scale_factor)

func lock_door():
	if not is_locked:
		is_locked = true
		update_door_state()
		print("🔒 Door ", door_id, " has been locked!")

# === DOOR MANAGEMENT AND IDENTIFICATION METHODS ===

func register_with_door_manager():
	# Register this door with the DungeonLevel door manager
	var dungeon_level = get_tree().get_first_node_in_group("dungeon_level")
	if dungeon_level and dungeon_level.has_method("register_door"):
		dungeon_level.register_door(self)
		print("🚪 Door ", door_id, " registered with door manager")

func get_door_info() -> Dictionary:
	# Return comprehensive information about this door
	return {
		"door_id": door_id,
		"required_npc": required_npc,
		"is_locked": is_locked,
		"description": door_description,
		"position": global_position,
		"has_collision": collision != null,
		"collision_enabled": collision.disabled == false if collision else false
	}

func is_door_blocking() -> bool:
	# Check if door is currently blocking passage
	return is_locked and collision and not collision.disabled

func can_player_pass() -> bool:
	# Check if player can pass through this door
	return not is_locked

func get_unlock_requirement() -> String:
	# Return what is needed to unlock this door
	if required_npc != "":
		return "Complete quiz with " + required_npc
	else:
		return "No requirement"

func force_unlock():
	# Force unlock door (for debugging or special cases)
	if is_locked:
		unlock_door()
		print("🔓 Door ", door_id, " force unlocked!")

func force_lock():
	# Force lock door (for debugging or special cases)
	if not is_locked:
		lock_door()
		print("🔒 Door ", door_id, " force locked!")

func set_door_description(description: String):
	# Set door description for better identification
	door_description = description
	print("🚪 Door ", door_id, " description set to: ", description)

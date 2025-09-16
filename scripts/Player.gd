extends CharacterBody3D

signal interaction_detected(npc)
signal interaction_lost
signal interact_requested

@export var speed = 8.0
@export var jump_velocity = 8.0
@export var acceleration = 15.0
@export var friction = 40.0
@export var initial_y_position: float = 0.1 # Posição Y inicial do player

@onready var interaction_area = $InteractionArea
@onready var character_model = $CharacterModel
@onready var animation_player = $CharacterModel/AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var interactable_npcs = []
var current_interactable = null
var is_moving = false
var bob_time = 0.0
var original_model_y = 0.0
var current_animation = "idle"
var animation_speed = 1.0

func _ready():
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	if character_model:
		original_model_y = character_model.position.y
	
	# Definir posição Y inicial
	position.y = initial_y_position
	
	# Aguardar um frame para garantir que a física seja inicializada
	await get_tree().process_frame
	# Verificar se está no chão, se não estiver, ajustar posição
	if not is_on_floor():
		position.y = initial_y_position
		# Forçar uma atualização da física
		await get_tree().process_frame
	
	# Inicializar animações
	setup_animations()

func _physics_process(delta):
	# Aplicar gravidade apenas se não estiver no chão
	if not is_on_floor():
		velocity.y -= gravity * delta * 2
	else:
		# Se estiver no chão, garantir que não afunde
		if velocity.y < 0:
			velocity.y = 0

	# Pular apenas se estiver no chão
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		play_animation("jump")

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Movement detection
	
	# Verificação manual adicional de NPCs próximos a cada segundo
	if Engine.get_process_frames() % 60 == 0: # A cada 60 frames (aprox. 1 segundo)
		manual_proximity_check()
	
	# Detectar se há input de movimento
	var has_input = input_dir.length() > 0.1
	
	if has_input:
		# Calcular velocidade alvo
		var target_velocity = Vector3(input_dir.x * speed, 0, input_dir.y * speed)
		
		# Aplicar aceleração mais responsiva
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		
		# Rotacionar o personagem na direção do movimento
		if character_model:
			var look_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
			if look_direction.length() > 0.1:
				# Usar atan2 para rotação apenas no eixo Y, evitando inclinações
				var target_rotation_y = atan2(look_direction.x, look_direction.z)
				character_model.rotation.y = lerp_angle(character_model.rotation.y, target_rotation_y, 10.0 * delta)
		
		# Atualizar estado de movimento
		if not is_moving:
			is_moving = true
			play_animation("walk")
	else:
		# Aplicar atrito mais forte para parar rapidamente
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		# Atualizar estado de movimento
		if is_moving:
			is_moving = false
			play_animation("idle")
			# Garantir que o personagem fique reto quando parar
			if character_model:
				character_model.rotation.x = 0
				character_model.rotation.z = 0
	
	# Animação de caminhada (bob up/down)
	if character_model:
		if is_moving:
			bob_time += delta * 8 # Velocidade da animação
			var bob_offset = sin(bob_time) * 0.1 # Amplitude do movimento
			character_model.position.y = original_model_y + bob_offset
		else:
			bob_time = 0
			character_model.position.y = original_model_y

	# Aplicar movimento com colisão
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		if current_interactable:
			interact_requested.emit()

func _on_interaction_area_body_entered(body):
	if body.has_method("get_npc_data"):
		interactable_npcs.append(body)
		if body.has_method("show_chat_indicator"):
			body.show_chat_indicator()
		update_current_interactable()

func _on_interaction_area_body_exited(body):
	if body in interactable_npcs:
		if body.has_method("hide_chat_indicator"):
			body.hide_chat_indicator()
		interactable_npcs.erase(body)
		update_current_interactable()

func update_current_interactable():
	if interactable_npcs.size() > 0:
		var closest_npc = null
		var closest_distance = INF
		
		for npc in interactable_npcs:
			var distance = global_position.distance_to(npc.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_npc = npc
		
		if closest_npc != current_interactable:
			current_interactable = closest_npc
			interaction_detected.emit(current_interactable)
	else:
		if current_interactable:
			current_interactable = null
			interaction_lost.emit()

func setup_animations():
	if animation_player:
		# Listar todas as animações disponíveis
		var animation_list = animation_player.get_animation_list()
		print("🎬 Animações disponíveis: ", animation_list)
		
		# Configurar velocidade padrão
		animation_player.speed_scale = animation_speed
		
		# Iniciar com animação idle
		play_animation("idle")

func play_animation(animation_name: String):
	if not animation_player:
		return
	
	# Não trocar animação se já estiver na mesma
	if current_animation == animation_name:
		return
	
	# Mapear nomes de animação para os nomes reais do modelo
	var animation_mapping = {
		"idle": "idle",
		"walk": "walk",
		"jump": "jump",
		"run": "run"
	}
	
	var real_animation_name = animation_mapping.get(animation_name, animation_name)
	
	# Verificar se a animação existe
	if animation_player.has_animation(real_animation_name):
		animation_player.play(real_animation_name)
		# Garantir que animações de movimento sejam em loop
		if animation_name in ["walk", "run"]:
			animation_player.get_animation(real_animation_name).loop_mode = Animation.LOOP_LINEAR
		current_animation = animation_name
	else:
		# Se a animação não existir, tentar variações comuns
		var fallback_animations = []
		
		# Variações específicas para cada tipo de animação
		match animation_name:
			"idle":
				fallback_animations = ["idle", "Idle", "IDLE", "Idle_01", "idle_01"]
			"walk":
				fallback_animations = ["walk", "Walk", "WALK", "walk_01", "Walk_01", "walking", "Walking"]
			"jump":
				fallback_animations = ["jump", "Jump", "JUMP", "jump_01", "Jump_01"]
			"run":
				fallback_animations = ["run", "Run", "RUN", "run_01", "Run_01", "running", "Running"]
		
		for fallback in fallback_animations:
			if animation_player.has_animation(fallback):
				animation_player.play(fallback)
				# Garantir que animações de movimento sejam em loop
				if animation_name in ["walk", "run"]:
					animation_player.get_animation(fallback).loop_mode = Animation.LOOP_LINEAR
				current_animation = animation_name
				print("🎬 Usando animação fallback: ", fallback, " para ", animation_name)
				break

func manual_proximity_check():
	# Busca manual por NPCs próximos como backup
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	if all_npcs.size() == 0:
		# Se o grupo está vazio, buscar por métodos alternativos
		all_npcs = []
		var root_node = get_tree().current_scene
		_find_npcs_recursive(root_node, all_npcs)
	
	var found_nearby = false
	for npc in all_npcs:
		if npc and is_instance_valid(npc):
			var distance = global_position.distance_to(npc.global_position)
			if distance <= 2.0: # Dentro do raio de interação
				if npc not in interactable_npcs:
					print("🔧 BACKUP: NPC detectado manualmente: ", npc.name)
					interactable_npcs.append(npc)
					if npc.has_method("show_chat_indicator"):
						npc.show_chat_indicator()
					update_current_interactable()
				found_nearby = true
	
	# Remover NPCs que estão longe
	for npc in interactable_npcs.duplicate():
		if npc and is_instance_valid(npc):
			var distance = global_position.distance_to(npc.global_position)
			if distance > 2.5: # Um pouco mais longe para evitar flicker
				print("🔧 BACKUP: NPC removido por distância: ", npc.name)
				if npc.has_method("hide_chat_indicator"):
					npc.hide_chat_indicator()
				interactable_npcs.erase(npc)
				update_current_interactable()

func _find_npcs_recursive(node, npcs_array):
	if node.has_method("get_npc_data"):
		npcs_array.append(node)
	
	for child in node.get_children():
		_find_npcs_recursive(child, npcs_array)

func set_animation_speed(speed: float):
	animation_speed = speed
	if animation_player:
		animation_player.speed_scale = speed

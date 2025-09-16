extends StaticBody3D

# Sistema de Portas Novo e Simples
@export var door_name: String = "door_1"
@export var unlocks_when_npc_completes: String = ""

# Modelos de porta
var closed_model: PackedScene
var open_model: PackedScene

# Componentes
var door_mesh: Node3D
var collision: CollisionShape3D

# Sistema de efeito mágico
var magic_effect: Sprite3D
var light_frames: Array[Texture2D] = []
var is_playing_magic: bool = false

func _ready():
	print("🚪 Nova porta '", door_name, "' inicializando...")
	
	# Carregar modelos
	closed_model = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate-door.glb")
	open_model = load("res://kenney_modular-dungeon-kit_1/Models/GLB format/gate.glb")
	
	# Carregar frames de luz mágica
	load_magic_light_frames()
	
	# Encontrar mesh da porta
	door_mesh = get_node_or_null("DoorMesh")
	if not door_mesh:
		print("❌ DoorMesh não encontrado!")
		return
	
	# Criar colisão
	create_collision()
	
	# Começar fechada
	set_door_closed()
	
	# Aguardar um frame para garantir que Main.gd esteja pronto
	await get_tree().process_frame
	await get_tree().process_frame # Duplo frame para garantir
	
	# Registrar com o sistema
	register_door()
	
	print("✅ Porta '", door_name, "' pronta!")

func load_magic_light_frames():
	# Carregar os 3 frames de luz do Kenney Particle Pack
	light_frames.append(load("res://kenney_particle-pack/PNG (Transparent)/light_01.png"))
	light_frames.append(load("res://kenney_particle-pack/PNG (Transparent)/light_02.png"))
	light_frames.append(load("res://kenney_particle-pack/PNG (Transparent)/light_03.png"))
	print("✨ Frames de luz mágica carregados: ", light_frames.size())

func create_collision():
	# Criar colisão para bloquear passagem
	collision = CollisionShape3D.new()
	collision.name = "DoorCollision"
	add_child(collision)
	
	# Criar forma de colisão
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2, 3, 0.5)
	collision.shape = box_shape

func set_door_closed():
	# Porta fechada - modelo fechado + colisão ativa
	if door_mesh and closed_model:
		replace_door_model(closed_model)
	
	if collision:
		collision.disabled = false
	
	print("🔒 Porta '", door_name, "' FECHADA")

func set_door_open():
	# Porta aberta - modelo aberto + colisão desabilitada
	if door_mesh and open_model:
		replace_door_model(open_model)
	
	if collision:
		collision.disabled = true
	
	print("🔓 Porta '", door_name, "' ABERTA")

func replace_door_model(new_model: PackedScene):
	if not door_mesh or not new_model:
		return
	
	# Salvar transformação atual
	var current_transform = door_mesh.transform
	
	# Remover modelo antigo
	door_mesh.queue_free()
	
	# Criar novo modelo
	var new_mesh = new_model.instantiate()
	new_mesh.name = "DoorMesh"
	new_mesh.transform = current_transform
	add_child(new_mesh)
	
	# Atualizar referência
	door_mesh = new_mesh

func unlock_door():
	print("🎉 Desbloqueando porta '", door_name, "'...")
	
	# Tocar efeito mágico de luz verde
	play_magic_light_effect()
	
	# Aguardar um pouco para o efeito iniciar
	await get_tree().create_timer(0.5).timeout
	
	set_door_open()
	
	# Animação de sucesso
	if door_mesh:
		var tween = create_tween()
		tween.tween_property(door_mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.3)
		tween.tween_property(door_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.3)

func play_magic_light_effect():
	if is_playing_magic or light_frames.is_empty():
		return
	
	print("✨ Iniciando efeito mágico de luz verde...")
	is_playing_magic = true
	
	# Criar Sprite3D para o efeito
	create_magic_sprite()
	
	# Reproduzir animação 3 vezes
	for cycle in range(3):
		print("✨ Ciclo mágico: ", cycle + 1, "/3")
		await play_light_animation_cycle()
		await get_tree().create_timer(0.2).timeout # Pausa entre ciclos
	
	# Remover efeito
	remove_magic_sprite()
	is_playing_magic = false
	print("✨ Efeito mágico concluído!")

func create_magic_sprite():
	# Criar Sprite3D para o efeito de luz
	magic_effect = Sprite3D.new()
	magic_effect.name = "MagicLightEffect"
	
	# Posicionar acima da porta
	magic_effect.position = Vector3(0, 2, 0) # 2 unidades acima da porta
	magic_effect.billboard = BaseMaterial3D.BILLBOARD_ENABLED # Sempre virado para a câmera
	
	# Configurar tamanho
	magic_effect.pixel_size = 0.01 # Ajustar tamanho conforme necessário
	
	# Cor verde mágica
	magic_effect.modulate = Color(0.2, 1.0, 0.3, 0.8) # Verde brilhante
	
	add_child(magic_effect)

func play_light_animation_cycle():
	if not magic_effect:
		return
	
	# Reproduzir os 3 frames rapidamente
	for frame_index in range(light_frames.size()):
		if magic_effect:
			magic_effect.texture = light_frames[frame_index]
			
			# Efeito de pulsação
			var tween = create_tween()
			tween.tween_property(magic_effect, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
			tween.tween_property(magic_effect, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
			
			await get_tree().create_timer(0.15).timeout # Duração de cada frame

func remove_magic_sprite():
	if magic_effect:
		magic_effect.queue_free()
		magic_effect = null

func register_door():
	# Registrar com o sistema principal
	print("📝 Tentando registrar porta '", door_name, "'...")
	var main_node = get_tree().get_first_node_in_group("main")
	print("📝 Main node encontrado: ", main_node != null)
	
	if main_node:
		print("📝 Main node tem método register_door: ", main_node.has_method("register_door"))
		if main_node.has_method("register_door"):
			var result = main_node.register_door(self)
			print("📝 Resultado do registro: ", result)
			print("📝 Porta '", door_name, "' registrada com sistema principal")
		else:
			print("📝 ❌ Main node não tem método register_door")
	else:
		print("📝 ❌ Main node não encontrado no grupo 'main'")

func get_door_info() -> Dictionary:
	var info = {
		"name": door_name,
		"unlocks_when": unlocks_when_npc_completes,
		"position": global_position,
		"is_open": collision.disabled if collision else false
	}
	print("🚪 get_door_info() chamado para: ", door_name, " - Info: ", info)
	return info

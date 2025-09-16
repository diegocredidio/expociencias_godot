extends Node3D

@onready var player = $Player
@onready var ui = $UI
@onready var interaction_prompt = $UI/InteractionPrompt
@onready var chat_dialog = $UI/ChatDialog
@onready var chat_history = $UI/ChatDialog/VBoxContainer/ChatHistory
@onready var chat_input = $UI/ChatDialog/VBoxContainer/InputContainer/ChatInput
@onready var send_button = $UI/ChatDialog/VBoxContainer/InputContainer/SendButton
@onready var close_button = $UI/ChatDialog/VBoxContainer/CloseButton
@onready var npc_name_label = $UI/ChatDialog/VBoxContainer/NPCName
@onready var dungeon_level = $DungeonLevel
@onready var quiz_dialog = $UI/QuizDialog
@onready var quiz_question = $UI/QuizDialog/VBoxContainer/QuizQuestion
@onready var quiz_close_button = $UI/QuizDialog/VBoxContainer/HeaderContainer/CloseButton
@onready var quiz_attempt_count = $UI/QuizDialog/VBoxContainer/HeaderContainer/AttemptCount
@onready var quiz_wrong_animation = $UI/QuizDialog/VBoxContainer/WrongAnswerAnimation
@onready var quiz_option_a = $UI/QuizDialog/VBoxContainer/OptionsContainer/OptionA
@onready var quiz_option_b = $UI/QuizDialog/VBoxContainer/OptionsContainer/OptionB
@onready var quiz_option_c = $UI/QuizDialog/VBoxContainer/OptionsContainer/OptionC
@onready var quiz_option_d = $UI/QuizDialog/VBoxContainer/OptionsContainer/OptionD

# Open Question elements
@onready var open_question_container = $UI/QuizDialog/VBoxContainer/OpenQuestionContainer
@onready var answer_input = $UI/QuizDialog/VBoxContainer/OpenQuestionContainer/AnswerInput
@onready var submit_button = $UI/QuizDialog/VBoxContainer/OpenQuestionContainer/SubmitButton
@onready var score_display = $UI/QuizDialog/VBoxContainer/ScoreDisplay
@onready var feedback_text = $UI/QuizDialog/VBoxContainer/FeedbackText

# AI Question Builder
var ai_question_builder: AIQuestionBuilder

var current_npc = null
var game_state = {}
# URL do proxy Supabase (substitua pela sua URL)
var supabase_proxy_url = SupabaseConfig.OPENAI_PROXY_URL
var openai_api_key = "" # DEPRECATED: Não é mais usado - usando Supabase proxy
var npc_questions = {} # Store generated questions for each NPC
var awaiting_question = false # Flag to know if we're generating a question
var npc_attempt_counts = {} # Track how many attempts each NPC has had
var cached_npc_data = {} # Cache NPC data to prevent null access
var last_detected_npc = null # Store last detected NPC as backup
var npc_used_topics = {} # Track used topics per NPC to avoid repetition
var current_npc_name = "" # Store current NPC name for persistence
var current_npc_subject = "" # Store current NPC subject for persistence

# Limpar cache de perguntas para evitar dessincronização
var quiz_cache_cleared = false
var start_time = 0 # Performance timing
var current_timeout_timer = null # Store current timeout timer for cancellation

# Quiz variables
var current_quiz_data = {} # Store current quiz question and options
var correct_answer_index = 0 # Index of correct answer (0-3)

# Open Question variables
var current_open_question_data = {} # Store current open question data
var is_open_question_mode = false # Flag to indicate if we're in open question mode

# Sistema de portas novo
var registered_doors = {} # Armazenar portas por nome

# Nova função para fazer requisições via proxy Supabase
func call_supabase_proxy(prompt: String, subject: String = "Educação", quiz_mode: String = "pergunta_aberta") -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + SupabaseConfig.ANON_KEY
	]
	
	var body = JSON.stringify({
		"prompt": prompt,
		"subject": subject,
		"quiz_mode": quiz_mode
	})
	
	print("🔗 Fazendo requisição para proxy Supabase...")
	var result = http_request.request(supabase_proxy_url, headers, HTTPClient.METHOD_POST, body)
	
	if result != OK:
		print("❌ Falha ao conectar com proxy Supabase: ", result)
		http_request.queue_free()
		return ""
	
	# Aguardar resposta
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()
	
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(response_body)
		if parse_result == OK and json.data.has("response"):
			print("✅ Resposta recebida do proxy Supabase")
			
			# Log de monitoramento com metadados
			if json.data.has("metadata"):
				var metadata = json.data.metadata
				print("📊 === MONITORAMENTO PROXY ===")
				print("📊 Matéria: ", metadata.get("subject", "N/A"))
				print("📊 Modo: ", metadata.get("quiz_mode", "N/A"))
				print("📊 Tamanho prompt: ", metadata.get("prompt_length", "N/A"), " caracteres")
				print("📊 Tamanho resposta: ", metadata.get("response_length", "N/A"), " caracteres")
				print("📊 Tokens OpenAI: ", metadata.get("tokens_used", "N/A"))
				print("📊 =============================")
			
			return json.data.response
		else:
			print("❌ Erro ao parsear resposta do proxy")
			return ""
	else:
		print("❌ Erro HTTP do proxy: ", response_code, " - ", response_body)
		return ""

func _ready():
	# Inicializar AI Question Builder
	ai_question_builder = AIQuestionBuilder.new()
	add_child(ai_question_builder)
	ai_question_builder.quiz_ready.connect(_on_quiz_ready)
	ai_question_builder.generation_failed.connect(_on_quiz_generation_failed)
	print("🤖 AIQuestionBuilder inicializado")
	
	# Conectar sinais da interface de perguntas abertas
	submit_button.pressed.connect(_on_open_question_submit_pressed)
	print("📝 Sinais de perguntas abertas conectados")
	
	# Adicionar ao grupo main para portas se registrarem
	add_to_group("main")
	print("🚪 Main.gd adicionado ao grupo 'main'")
	
	# Verificar se SupabaseConfig está disponível
	if SupabaseConfig.OPENAI_PROXY_URL == "":
		print("❌ AVISO: SupabaseConfig.OPENAI_PROXY_URL não configurado!")
	else:
		print("✅ Proxy Supabase configurado:", SupabaseConfig.OPENAI_PROXY_URL)
	
	send_button.pressed.connect(_on_send_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	chat_input.text_submitted.connect(_on_chat_input_submitted)
	
	# Connect quiz buttons
	quiz_close_button.pressed.connect(_on_quiz_close_button_pressed)
	quiz_option_a.pressed.connect(func(): _on_quiz_option_selected(0))
	quiz_option_b.pressed.connect(func(): _on_quiz_option_selected(1))
	quiz_option_c.pressed.connect(func(): _on_quiz_option_selected(2))
	quiz_option_d.pressed.connect(func(): _on_quiz_option_selected(3))
	
	# Start in fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	load_openai_key()
	
	player.interaction_detected.connect(_on_player_interaction_detected)
	player.interaction_lost.connect(_on_player_interaction_lost)
	player.interact_requested.connect(_on_player_interact_requested)
	
	# Aguardar alguns frames para garantir que todas as portas estejam prontas
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("🚪 === VERIFICANDO REGISTRO DE PORTAS ===")
	get_door_status()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			toggle_fullscreen()
		elif event.keycode == KEY_F1:
			# F1 para mostrar status das portas
			get_door_status()
		elif event.keycode == KEY_F2:
			# F2 para testar desbloqueio da porta de biologia
			test_unlock_ciencias_door()
		elif event.keycode == KEY_F3:
			# F3 para forçar registro de portas
			force_register_all_doors()

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func load_openai_key():
	# Try to load from file in project directory first
	var config_file = FileAccess.open("openai_key.txt", FileAccess.READ)
	if config_file:
		var file_content = config_file.get_as_text()
		config_file.close()
		if file_content != null and file_content is String:
			openai_api_key = file_content.strip_edges()
			# API key loaded from project directory
			return
	
	# Fallback to user directory
	var file = FileAccess.open("user://openai_key.txt", FileAccess.READ)
	if file:
		openai_api_key = file.get_as_text().strip_edges()
		file.close()
		# API key loaded from user directory
	else:
		pass # Create openai_key.txt with API key

func _on_player_interaction_detected(npc):
	print("🎯 === NPC DETECTADO ===")
	print("🎯 NPC: ", npc.npc_name if npc else "null")
	
	current_npc = npc
	last_detected_npc = npc # Always store as backup
	
	# Cache NPC data immediately to prevent null access issues
	if npc and is_instance_valid(npc) and npc.has_method("get_npc_data"):
		print("🎯 Cacheando dados do NPC: ", npc.npc_name)
		cache_npc_data(npc)
	
	interaction_prompt.visible = true

func _on_player_interaction_lost():
	interaction_prompt.visible = false
	current_npc = null

func _on_player_interact_requested():
	# Use the robust NPC detection system
	var npc_to_use = get_npc_for_chat()
	
	if npc_to_use:
		open_chat(npc_to_use)
	else:
		# Try to open chat anyway - the open_chat function will handle fallbacks
		open_chat()

func force_find_nearby_npc():
	if player and player.current_interactable and is_instance_valid(player.current_interactable):
		if player.current_interactable.has_method("get_npc_data"):
			return player.current_interactable
	
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	if all_npcs.size() == 0:
		all_npcs = find_all_npcs_in_scene()
	
	if all_npcs.size() > 0:
		var closest_npc = null
		var closest_distance = INF
		
		for npc in all_npcs:
			if npc and is_instance_valid(npc):
				var distance = player.global_position.distance_to(npc.global_position)
				if distance < 5.0 and distance < closest_distance:
					closest_distance = distance
					closest_npc = npc
		
		if closest_npc:
			return closest_npc
	
	if player and player.has_method("get_children"):
		for child in player.get_children():
			if child.name == "InteractionArea" and child.has_method("get_overlapping_bodies"):
				var bodies = child.get_overlapping_bodies()
				for body in bodies:
					if body.has_method("get_npc_data"):
						return body
	
	return null

func find_all_npcs_in_scene():
	var npcs = []
	var root_node = get_tree().current_scene
	_search_npcs_recursive(root_node, npcs)
	return npcs

func _search_npcs_recursive(node, npcs_array):
	if node.has_method("get_npc_data"):
		npcs_array.append(node)
	
	for child in node.get_children():
		_search_npcs_recursive(child, npcs_array)

func open_chat(npc = null):
	print("💬 === ABRINDO CHAT ===")
	print("💬 NPC parâmetro: ", npc.npc_name if npc else "null")
	print("💬 current_npc antes: ", current_npc.npc_name if current_npc else "null")
	
	# Use robust NPC detection system
	var chat_npc = get_npc_for_chat()
	print("💬 NPC do get_npc_for_chat(): ", chat_npc.npc_name if chat_npc else "null")
	
	if not chat_npc:
		# Last resort: try the provided NPC parameter
		if npc and is_instance_valid(npc):
			print("💬 Usando NPC do parâmetro como fallback")
			chat_npc = npc
			current_npc = npc
			cache_npc_data(npc)
		else:
			print("💬 FALHA: Nenhum NPC disponível")
			chat_history.text = "[color=red][b]❌ Erro:[/b] Não foi possível identificar o NPC para conversar[/color]"
			return
	
	current_npc = chat_npc
	
	# Check quiz mode from cached data
	var npc_data = cached_npc_data.get(chat_npc.npc_name, {})
	var quiz_mode = npc_data.get("quiz_mode", "pergunta_aberta")
	
	print("💬 Quiz mode detectado: ", quiz_mode)
	
	if quiz_mode == "pergunta_multipla_escolha":
		# Open quiz interface
		open_quiz_interface(chat_npc)
	else:
		# Open traditional chat interface
		open_traditional_chat(chat_npc)
	
	await get_tree().process_frame
	player.set_process_mode(Node.PROCESS_MODE_DISABLED)

func open_traditional_chat(chat_npc):
	chat_dialog.visible = true
	quiz_dialog.visible = false
	npc_name_label.text = chat_npc.npc_name
	
	# Always start fresh - generate a new question each time
	chat_history.text = "[b]" + chat_npc.npc_name + ":[/b] " + chat_npc.greeting_message
	chat_history.text += "\n[color=yellow][b]Preparando uma pergunta para você...[/b][/color]"
	
	# Initialize attempt count if first time
	if not npc_attempt_counts.has(chat_npc.npc_name):
		npc_attempt_counts[chat_npc.npc_name] = 0
	
	# Generate a new question for this NPC
	generate_question_for_npc(chat_npc)
	chat_input.grab_focus()

func get_topic_variety_prompt(npc_name: String, subject: String, attempt_count: int) -> String:
	# Initialize used topics for this NPC if not exists
	if not npc_used_topics.has(npc_name):
		npc_used_topics[npc_name] = []
	
	var used_topics = npc_used_topics[npc_name]
	var variety_prompt = ""
	
	if attempt_count == 0:
		variety_prompt = "PRIMEIRA PERGUNTA: Escolha um tópico interessante e envolvente. "
	else:
		variety_prompt = "PERGUNTA " + str(attempt_count + 1) + ": OBRIGATÓRIO usar tópico DIFERENTE das anteriores. "
		
		# Add specific avoidance based on subject
		match subject:
			"Português":
				if used_topics.has("virgula"):
					variety_prompt += "NÃO faça sobre vírgula novamente. "
				if used_topics.has("verbo"):
					variety_prompt += "NÃO faça sobre verbos novamente. "
				variety_prompt += "Varie entre: interpretação de texto, classes gramaticais, ortografia, literatura, produção textual. "
			"Ciências":
				variety_prompt += "Varie entre: corpo humano, meio ambiente, matéria e energia, terra e universo, seres vivos. "
			"Geografia":
				variety_prompt += "Varie entre: relevo, clima, hidrografia, população, economia, cartografia. "
			"História":
				variety_prompt += "Varie entre: Brasil colonial, povos indígenas, cultura, períodos históricos, personagens. "
			"Matemática":
				variety_prompt += "Varie entre: operações, geometria, frações, medidas, problemas práticos. "
	
	variety_prompt += "Seja CRIATIVO e use exemplos do cotidiano. "
	return variety_prompt

func update_attempt_counter(npc_name: String):
	var current_attempts = npc_attempt_counts.get(npc_name, 0)
	var attempt_number = current_attempts + 1
	quiz_attempt_count.text = "Tentativa " + str(attempt_number) + " de 3"

func adjust_button_height(button: Button) -> void:
	# Wait for the text to be set and rendered
	await get_tree().process_frame
	
	# Calculate required height based on text content
	var font = button.get_theme_font("font")
	var font_size = button.get_theme_font_size("font_size")
	
	if font and font_size > 0:
		# Get button width minus margins
		var available_width = button.size.x - 40 # 20px margin on each side
		if available_width <= 0:
			available_width = 800 # Fallback width
		
		# Calculate text dimensions
		var text_size = font.get_multiline_string_size(
			button.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			available_width,
			font_size
		)
		
		# Calculate required height (text height + padding)
		var required_height = max(80, text_size.y + 30) # Minimum 80px, +30px padding
		
		# Apply new height
		button.custom_minimum_size.y = required_height
		
		print("📏 Button '", button.text.substr(0, 20), "...' height adjusted to: ", required_height)

func adjust_all_button_heights():
	adjust_button_height(quiz_option_a)
	adjust_button_height(quiz_option_b)
	adjust_button_height(quiz_option_c)
	adjust_button_height(quiz_option_d)

func show_wrong_answer_animation():
	quiz_wrong_animation.visible = true
	quiz_wrong_animation.scale = Vector2(0.1, 0.1)
	
	# Create animation
	var tween = create_tween()
	tween.tween_property(quiz_wrong_animation, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(quiz_wrong_animation, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Hide after animation
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	quiz_wrong_animation.visible = false

func open_quiz_interface(chat_npc):
	quiz_dialog.visible = true
	chat_dialog.visible = false
	
	# Verificar se é o diretor (pergunta aberta)
	var is_director = chat_npc.npc_name == "Diretor Oliveira"
	
	if is_director:
		open_open_question_mode(chat_npc)
	else:
		open_multiple_choice_mode(chat_npc)

func open_multiple_choice_mode(chat_npc):
	is_open_question_mode = false
	
	# Esconder elementos de pergunta aberta
	open_question_container.visible = false
	score_display.visible = false
	feedback_text.visible = false
	
	# Mostrar elementos de múltipla escolha
	quiz_option_a.get_parent().visible = true
	
	# LIMPAR CACHE COMPLETAMENTE para evitar dessincronização
	clear_quiz_cache()
	
	# Initialize attempt count if first time
	if not npc_attempt_counts.has(chat_npc.npc_name):
		npc_attempt_counts[chat_npc.npc_name] = 0
	
	# Update attempt counter display
	update_attempt_counter(chat_npc.npc_name)
	
	# Show loading message
	quiz_question.text = "Preparando pergunta de múltipla escolha..."
	reset_quiz_buttons()
	
	# Generate quiz question
	generate_quiz_question_for_npc(chat_npc)

func open_open_question_mode(chat_npc):
	is_open_question_mode = true
	
	# Esconder elementos de múltipla escolha
	quiz_option_a.get_parent().visible = false
	
	# Mostrar elementos de pergunta aberta
	open_question_container.visible = true
	
	# Initialize attempt count if first time
	if not npc_attempt_counts.has(chat_npc.npc_name):
		npc_attempt_counts[chat_npc.npc_name] = 0
	
	# Update attempt counter display
	update_attempt_counter(chat_npc.npc_name)
	
	# Show loading message
	quiz_question.text = "Preparando pergunta aberta do diretor..."
	answer_input.text = ""
	answer_input.editable = false
	submit_button.disabled = true
	score_display.visible = false
	feedback_text.visible = false
	
	# Generate open question
	generate_open_question_for_npc(chat_npc)

# Função para gerar pergunta aberta do diretor
func generate_open_question_for_npc(chat_npc):
	current_npc_name = chat_npc.npc_name
	current_npc_subject = "multidisciplinar"
	
	# Gerar prompt de variedade para perguntas abertas
	var topic_variety_prompt = get_open_question_variety_prompt(chat_npc.npc_name, npc_attempt_counts.get(chat_npc.npc_name, 0))
	
	# Solicitar pergunta aberta
	ai_question_builder.request_open_question(
		chat_npc.npc_name,
		topic_variety_prompt,
		npc_attempt_counts.get(chat_npc.npc_name, 0),
		supabase_proxy_url,
		SupabaseConfig.ANON_KEY
	)

# Função para gerar prompt de variedade para perguntas abertas do diretor
func get_open_question_variety_prompt(npc_name: String, attempt_count: int) -> String:
	if attempt_count == 0:
		return "Esta é a primeira pergunta aberta do diretor. Crie uma questão multidisciplinar interessante que combine conceitos de diferentes áreas do conhecimento para revisão final."
	elif attempt_count == 1:
		return "Segunda pergunta aberta do diretor. Varie completamente o tema da anterior. Pode mesclar disciplinas diferentes (ex: Matemática + Geografia, Português + História, Ciências + Arte)."
	else:
		return "Terceira pergunta aberta do diretor. Use um tema completamente diferente das anteriores. Seja criativo e combine disciplinas de forma inovadora para uma revisão final abrangente."

# Função para lidar com envio da resposta
func _on_open_question_submit_pressed():
	var student_answer = answer_input.text.strip_edges()
	
	if student_answer == "":
		print("❌ Resposta vazia")
		return
	
	print("📝 Resposta do aluno: ", student_answer)
	
	# Validar resposta usando o AIQuestionBuilder
	var validation_result = ai_question_builder.validate_student_answer(student_answer, current_open_question_data)
	
	print("📊 Pontuação: ", validation_result.score, "%")
	print("✅ Correta: ", validation_result.is_correct)
	print("💬 Feedback: ", validation_result.feedback)
	
	# Exibir resultado
	display_open_question_result(validation_result)
	
	# Incrementar tentativas
	var npc_name = current_npc_name
	npc_attempt_counts[npc_name] = npc_attempt_counts.get(npc_name, 0) + 1
	
	# Verificar se ainda há tentativas restantes
	var remaining_attempts = 3 - npc_attempt_counts[npc_name]
	if remaining_attempts > 0 and not validation_result.is_correct:
		# Preparar para próxima tentativa
		await get_tree().create_timer(3.0).timeout
		generate_open_question_for_npc(current_npc)

# Função para exibir resultado da pergunta aberta
func display_open_question_result(validation_result: Dictionary):
	# Desabilitar campo de resposta
	answer_input.editable = false
	submit_button.disabled = true
	
	# Exibir pontuação (mais generosa - mostrar 10% a menos)
	var displayed_score = max(0, validation_result.score - 10)
	score_display.text = "Pontuação: " + str(int(displayed_score)) + "%"
	score_display.visible = true
	
	# Exibir feedback
	var feedback_text_content = validation_result.feedback + "\n\n"
	
	if validation_result.concepts_found.size() > 0:
		feedback_text_content += "[color=#00f6ff]Conceitos encontrados: " + ", ".join(validation_result.concepts_found) + "[/color]\n"
	
	if validation_result.concepts_missing.size() > 0:
		feedback_text_content += "[color=orange]Conceitos em falta: " + ", ".join(validation_result.concepts_missing) + "[/color]\n"
	
	feedback_text_content += "\n[color=#5297df]Explicação: " + current_open_question_data.rationale + "[/color]"
	
	feedback_text.text = feedback_text_content
	feedback_text.visible = true
	
	print("✅ Resultado da pergunta aberta exibido!")

func close_chat():
	chat_dialog.visible = false
	quiz_dialog.visible = false
	chat_input.text = ""
	
	# Re-enable player input after closing chat
	player.set_process_mode(Node.PROCESS_MODE_INHERIT)

func show_success_message():
	# Create a temporary success message
	var success_label = Label.new()
	success_label.text = "🎉 PARABÉNS! Porta desbloqueada! 🚪"
	success_label.add_theme_font_size_override("font_size", 24)
	success_label.add_theme_color_override("font_color", Color.GOLD)
	success_label.position = Vector2(400, 200)
	success_label.z_index = 100
	
	# Add to UI
	ui.add_child(success_label)
	
	# Animate the message
	var tween = create_tween()
	tween.tween_property(success_label, "modulate:a", 0.0, 3.0)
	tween.tween_callback(func(): success_label.queue_free())

func _on_close_button_pressed():
	close_chat()

func _on_quiz_close_button_pressed():
	close_chat()

func clear_quiz_cache():
	# Limpar completamente o cache de perguntas para evitar dessincronização
	print("🧹 LIMPANDO CACHE DE QUIZ...")
	
	# Limpar dados de quiz anteriores
	current_quiz_data = {}
	correct_answer_index = 0
	
	# Limpar perguntas armazenadas para este NPC
	if current_npc_name != "":
		npc_questions.erase(current_npc_name)
		print("🧹 Cache limpo para NPC: ", current_npc_name)
	
	# Resetar estado de espera
	awaiting_question = false
	
	# Limpar qualquer HTTPRequest pendente
	var existing_requests = get_children().filter(func(node): return node is HTTPRequest)
	for request in existing_requests:
		request.queue_free()
		print("🧹 HTTPRequest removido: ", request.name)
	
	# Cancelar timer de timeout se existir
	if current_timeout_timer:
		current_timeout_timer.queue_free()
		current_timeout_timer = null
	
	print("✅ Cache de quiz limpo completamente!")

func reset_quiz_buttons():
	quiz_option_a.text = "A) Carregando..."
	quiz_option_b.text = "B) Carregando..."
	quiz_option_c.text = "C) Carregando..."
	quiz_option_d.text = "D) Carregando..."
	quiz_option_a.disabled = true
	quiz_option_b.disabled = true
	quiz_option_c.disabled = true
	quiz_option_d.disabled = true

func enable_quiz_buttons():
	quiz_option_a.disabled = false
	quiz_option_b.disabled = false
	quiz_option_c.disabled = false
	quiz_option_d.disabled = false

func _on_quiz_option_selected(option_index: int):
	print("📝 === QUIZ OPTION SELECTED ===")
	print("📝 Opção selecionada: ", option_index, " (Correta: ", correct_answer_index, ")")
	print("📝 NPC atual: ", current_npc_name)
	print("📝 Resposta correta? ", option_index == correct_answer_index)
	
	# Disable all buttons to prevent multiple selections
	quiz_option_a.disabled = true
	quiz_option_b.disabled = true
	quiz_option_c.disabled = true
	quiz_option_d.disabled = true
	
	if option_index == correct_answer_index:
		# Correct answer
		print("🎉 RESPOSTA CORRETA! Iniciando desbloqueio...")
		quiz_question.text += "\n\n[color=green][b]🎉 PARABÉNS! Resposta correta![/b][/color]"
		
		# Mostrar explicação se disponível
		if current_quiz_data.has("rationale") and current_quiz_data.rationale != "":
			quiz_question.text += "\n\n[color=lightblue][b]💡 Explicação:[/b] " + current_quiz_data.rationale + "[/color]"
		
		quiz_question.text += "\n[color=gold][b]🎉 PORTA DESBLOQUEADA![/b][/color]"
		quiz_question.text += "\n[color=cyan][b]🚪 A porta está se abrindo...[/b][/color]"
		
		# Aguardar 3 segundos para o jogador ler as mensagens
		await get_tree().create_timer(3.0).timeout
		
		# Fechar chat primeiro
		close_chat()
		
		# Aguardar 1 segundo antes de iniciar efeito mágico e abrir porta
		await get_tree().create_timer(1.0).timeout
		
		# Unlock room and door (com efeito mágico)
		print("🚪 Chamando unlock_room_by_npc_name para: ", current_npc_name)
		unlock_room_by_npc_name(current_npc_name)
		
		# Show success message
		show_success_message()
	else:
		# Wrong answer
		npc_attempt_counts[current_npc_name] = npc_attempt_counts.get(current_npc_name, 0) + 1
		var current_attempts = npc_attempt_counts[current_npc_name]
		
		# Update attempt counter display
		update_attempt_counter(current_npc_name)
		
		# Show wrong answer animation
		show_wrong_answer_animation()
		
		quiz_question.text += "\n\n[color=red][b]Resposta incorreta![/b][/color]"
		quiz_question.text += "\n[color=#00f6ff]A resposta correta era: " + get_correct_option_text() + "[/color]"
		
		# Mostrar explicação se disponível
		if current_quiz_data.has("rationale") and current_quiz_data.rationale != "":
			quiz_question.text += "\n\n[color=lightblue][b]💡 Explicação:[/b] " + current_quiz_data.rationale + "[/color]"
		
		if current_attempts >= 3:
			quiz_question.text += "\n[color=red][b]📝 Você já tentou 3 vezes.[/b][/color]"
			quiz_question.text += "\n[color=yellow][b]💡 Sugestão: Estude mais sobre " + current_npc_subject + " e volte depois![/b][/color]"
		else:
			quiz_question.text += "\n[color=#00f6ff][b]🔄 Gerando nova pergunta...[/b][/color]"
			
			# Wait a bit then generate new question
			await get_tree().create_timer(2.0).timeout
			if current_npc_name != "":
				generate_quiz_question_for_npc(null)

func get_correct_option_text() -> String:
	var button_texts = [quiz_option_a.text, quiz_option_b.text, quiz_option_c.text, quiz_option_d.text]
	return button_texts[correct_answer_index]

func _on_send_button_pressed():
	send_message()

func _on_chat_input_submitted(_text):
	send_message()

var last_user_message = ""

func send_message():
	var message = chat_input.text.strip_edges()
	if message == "":
		return
	
	last_user_message = message # Store user's answer for validation
	chat_history.text += "\n[color=blue][b]Você:[/b] " + message + "[/color]"
	chat_input.text = ""
	
	# Debug command - if user types "debug", show debug info
	if message.to_lower() == "debug":
		show_debug_info()
		return
	
	# Complete debug command - if user types "debug2", show complete debug
	if message.to_lower() == "debug2":
		chat_history.text += "\n[color=cyan][b]🔍 DEBUG COMPLETO:[/b] Verificando tudo...[/color]"
		show_complete_debug_info()
		return
	
	# Force NPC search command
	if message.to_lower() == "findnpc":
		chat_history.text += "\n[color=cyan][b]🔍 BUSCA FORÇADA:[/b] Tentando encontrar NPCs...[/color]"
		var found_npc = force_find_nearby_npc()
		if found_npc:
			current_npc = found_npc
			chat_history.text += "\n[color=green][b]✅ NPC ENCONTRADO:[/b] " + found_npc.npc_name + "[/color]"
		else:
			chat_history.text += "\n[color=red][b]❌ NENHUM NPC ENCONTRADO[/b][/color]"
		return
	
	# Status command to see attempt count
	if message.to_lower() == "status":
		if current_npc:
			var attempt_count = npc_attempt_counts.get(current_npc.npc_name, 0)
			chat_history.text += "\n[color=cyan][b]📊 STATUS:[/b] " + current_npc.npc_name + " - Tentativa: " + str(attempt_count + 1) + "[/color]"
		else:
			chat_history.text += "\n[color=red][b]❌ Erro:[/b] Nenhum NPC selecionado[/color]"
		return
	
	# Clean logs command
	if message.to_lower() == "cleanlogs":
		# Remove all debug prints by setting a flag
		get_tree().set_meta("debug_mode", false)
		chat_history.text += "\n[color=green][b]🧹 Logs limpos![/b] Debug desabilitado.[/color]"
		return
	
	# Test message - if user types "test", do a simple HTTP test
	if message.to_lower() == "test":
		chat_history.text += "\n[color=cyan][b]🧪 TESTE HTTP:[/b] Iniciando teste de conexão...[/color]"
		test_http_connection()
		return
	
	# Debug message
	chat_history.text += "\n[color=yellow][b]⏳ STATUS:[/b] Enviando para OpenAI...[/color]"
	
	# Use robust NPC system for evaluation
	var eval_npc = get_npc_for_chat()
	
	if eval_npc:
		current_npc = eval_npc # Update current_npc
		
		# Don't allow answers while generating questions
		if awaiting_question:
			chat_history.text += "\n[color=yellow][b]⏳ Aguarde:[/b] Ainda gerando pergunta...[/color]"
			return
		
		evaluate_student_answer(message, eval_npc)
	else:
		chat_history.text += "\n[color=red][b]❌ ERRO:[/b] Nenhum NPC disponível para avaliar resposta[/color]"
		show_debug_info()

func super_wide_npc_search():
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	if all_npcs.size() == 0:
		all_npcs = find_all_npcs_in_scene()
	
	if all_npcs.size() > 0:
		var closest_npc = null
		var closest_distance = INF
		
		for npc in all_npcs:
			if npc and is_instance_valid(npc):
				var distance = player.global_position.distance_to(npc.global_position)
				if distance < 15.0 and distance < closest_distance:
					closest_distance = distance
					closest_npc = npc
		
		if closest_npc:
			return closest_npc
	
	return null

func generate_question_for_npc(npc):
	var timestamp = Time.get_datetime_string_from_system()
	print("🎯 [", timestamp, "] Iniciando geração de pergunta...")
	print("🎯 NPC recebido: ", npc.npc_name if (npc and is_instance_valid(npc)) else "null")
	print("🎯 current_npc: ", current_npc.npc_name if current_npc else "null")
	
	
	# Check if we have persistent data when NPC is null (for regeneration)
	if not npc or not is_instance_valid(npc):
		if current_npc_name == "" or current_npc_subject == "":
			print("❌ NPC inválido e sem dados persistentes")
			chat_history.text += "\n[color=red][b]❌ ERRO:[/b] NPC inválido para geração de pergunta![/color]"
			return
		else:
			print("🔄 Usando dados persistentes para regeneração: ", current_npc_name)
	else:
		# Cache NPC data for persistence
		cache_npc_data(npc)
	
	awaiting_question = true
	
	# Clean up existing requests
	var existing_http = get_children().filter(func(node): return node is HTTPRequest)
	for node in existing_http:
		node.queue_free()
	
	# Create request for question generation
	var http_request = HTTPRequest.new()
	http_request.name = "Question_Request"
	add_child(http_request)
	http_request.timeout = 15.0 # Optimized timeout for faster response
	
	# Connect signal
	print("🔗 Conectando sinal request_completed")
	http_request.request_completed.connect(_on_question_generated)
	print("🔗 Sinal conectado para: ", http_request.name)
	
	# Use Supabase proxy headers instead of direct OpenAI
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + SupabaseConfig.ANON_KEY,
		"apikey: " + SupabaseConfig.ANON_KEY
	]
	
	# Create focused single question prompt
	var simplified_prompt = ""
	
	# For Dir. Oliveira (Revisão Geral), randomly select a subject
	if current_npc_name.contains("Oliveira") or current_npc_subject == "Revisão Geral":
		var subjects = ["Português", "Matemática", "Ciências", "Geografia", "História"]
		var random_subject = subjects[randi() % subjects.size()]
		simplified_prompt = "Faça UMA pergunta específica sobre " + random_subject + " (BNCC 6º ano)."
		simplified_prompt += " A pergunta deve testar conhecimento específico da disciplina."
		simplified_prompt += " Seja direto e objetivo. Apenas uma pergunta."
	else:
		simplified_prompt = "Faça UMA pergunta específica sobre " + current_npc_subject + " (BNCC 6º ano)."
		simplified_prompt += " A pergunta deve testar conhecimento específico da disciplina."
		simplified_prompt += " Seja direto e objetivo. Apenas uma pergunta."
	
	# Use proxy format instead of OpenAI format
	var body = JSON.stringify({
		"prompt": simplified_prompt,
		"subject": current_npc_subject,
		"quiz_mode": "pergunta_aberta"
	})
	
	print("🌐 Enviando requisição para Supabase proxy...")
	print("🌐 Body size: ", body.length())
	
	# Add performance timing
	var _start_time = Time.get_ticks_msec()
	
	var result = http_request.request(supabase_proxy_url, headers, HTTPClient.METHOD_POST, body)
	
	if result != OK:
		print("❌ Falha ao enviar requisição: ", result)
		chat_history.text += "\n[color=red][b]❌ Erro:[/b] Falha ao gerar pergunta[/color]"
		awaiting_question = false
		
		# Cancel timeout timer since request failed
		if current_timeout_timer and is_instance_valid(current_timeout_timer):
			current_timeout_timer.timeout.disconnect(_on_question_timeout)
			current_timeout_timer = null
		
		http_request.queue_free()
	else:
		print("✅ Requisição enviada com sucesso")
		# Start timeout timer only for OpenAI requests
		current_timeout_timer = get_tree().create_timer(20.0) # Give HTTPRequest 15s + 5s buffer
		current_timeout_timer.timeout.connect(_on_question_timeout)

func generate_quiz_question_for_npc(npc):
	var timestamp = Time.get_datetime_string_from_system()
	print("🎯 [", timestamp, "] Iniciando geração de pergunta de múltipla escolha...")
	print("🎯 NPC recebido: ", npc.npc_name if (npc and is_instance_valid(npc)) else "null")
	print("🎯 current_npc: ", current_npc.npc_name if current_npc else "null")
	
	
	# Check if we have persistent data when NPC is null (for regeneration)
	if not npc or not is_instance_valid(npc):
		if current_npc_name == "" or current_npc_subject == "":
			print("❌ NPC inválido e sem dados persistentes")
			quiz_question.text = "❌ ERRO: NPC inválido para geração de pergunta!"
			return
		else:
			print("🔄 Usando dados persistentes para regeneração: ", current_npc_name)
	else:
		# Cache NPC data for persistence
		cache_npc_data(npc)
	
	awaiting_question = true
	
	# Clean up existing requests
	var existing_http = get_children().filter(func(node): return node is HTTPRequest)
	for node in existing_http:
		node.queue_free()
	
	# Mostrar loading state
	quiz_question.text = "🤖 Gerando pergunta..."
	reset_quiz_buttons()
	
	# Obter prompt de variedade de tópicos
	var attempt_count = npc_attempt_counts.get(current_npc_name, 0)
	var topic_variety_prompt = get_topic_variety_prompt(current_npc_name, current_npc_subject, attempt_count)
	
	# Usar o novo sistema AIQuestionBuilder
	ai_question_builder.request_question(
		current_npc_name,
		current_npc_subject,
		topic_variety_prompt,
		attempt_count,
		supabase_proxy_url,
		SupabaseConfig.ANON_KEY
	)

func _on_quiz_ready(quiz_item: Dictionary):
	print("🎉 Quiz gerado com sucesso pelo AIQuestionBuilder!")
	awaiting_question = false
	
	if is_open_question_mode:
		# Lidar com pergunta aberta do diretor
		print("🎯 Disciplinas: ", quiz_item.subjects)
		print("🎯 Conceitos-chave: ", quiz_item.key_concepts)
		print("🎯 Resposta esperada: ", quiz_item.expected_answer)
		
		# Armazenar dados da pergunta aberta
		current_open_question_data = quiz_item
		
		# Exibir pergunta
		quiz_question.text = quiz_item.question
		
		# Habilitar campo de resposta
		answer_input.editable = true
		answer_input.text = ""
		submit_button.disabled = false
		
		print("✅ Pergunta aberta exibida na interface!")
	else:
		# Lidar com múltipla escolha
		# Exibir pergunta
		quiz_question.text = quiz_item.question
		
		# Exibir alternativas (sem prefixos A) B) C) D))
		quiz_option_a.text = quiz_item.options.A
		quiz_option_b.text = quiz_item.options.B
		quiz_option_c.text = quiz_item.options.C
		quiz_option_d.text = quiz_item.options.D
		
		# Ajustar altura dos botões para texto longo
		adjust_all_button_heights()
		
		# Armazenar resposta correta para validação
		match quiz_item.correct:
			"A": correct_answer_index = 0
			"B": correct_answer_index = 1
			"C": correct_answer_index = 2
			"D": correct_answer_index = 3
			_: correct_answer_index = 0
		
		# Armazenar explicação para mostrar após resposta
		current_quiz_data["rationale"] = quiz_item.rationale
		current_quiz_data["topic_hint"] = quiz_item.topic_hint
		
		# Habilitar botões
		enable_quiz_buttons()
		
		print("✅ Quiz exibido na interface!")
		print("🎯 Pergunta: ", quiz_item.question)
		print("🎯 Resposta correta: ", quiz_item.correct)
		print("🎯 Explicação: ", quiz_item.rationale)

func _on_quiz_generation_failed(reason: String):
	print("❌ Falha na geração do quiz: ", reason)
	awaiting_question = false
	
	if is_open_question_mode:
		# Mostrar mensagem de erro para pergunta aberta
		quiz_question.text = "[color=red]❌ Erro ao gerar pergunta: " + reason + "[/color]\n\n[color=yellow]Tente novamente em alguns instantes.[/color]"
		answer_input.editable = false
		submit_button.disabled = true
	else:
		# Mostrar mensagem de fallback para múltipla escolha
		quiz_question.text = "❌ Não foi possível gerar a questão, tente novamente.\n\nMotivo: " + reason
		# Resetar botões
		reset_quiz_buttons()

func parse_and_display_quiz_json(quiz_data: Dictionary):
	print("🔍 === PARSING QUIZ JSON ===")
	print("🔍 NPC atual: ", current_npc_name)
	print("🔍 Matéria atual: ", current_npc_subject)
	print("🔍 Quiz data: ", quiz_data)
	
	# Validate quiz data structure
	if not quiz_data.has("question") or not quiz_data.has("options") or not quiz_data.has("correct_answer"):
		print("❌ Estrutura de quiz inválida - campos obrigatórios ausentes")
		quiz_question.text = "❌ Erro: Pergunta incompleta recebida"
		return
	
	var question_text = quiz_data.get("question", "")
	var options = quiz_data.get("options", [])
	var correct_answer = quiz_data.get("correct_answer", 0)
	
	# Validate question text
	if question_text == "" or question_text == null:
		print("❌ Pergunta vazia")
		quiz_question.text = "❌ Erro: Pergunta não recebida"
		return
	
	# Validate options array
	if not options is Array or options.size() < 4:
		print("❌ Opções inválidas - esperado array com 4 itens, recebido: ", options)
		quiz_question.text = "❌ Erro: Alternativas incompletas"
		return
	
	# Validate correct answer
	var correct_index = 0
	if correct_answer is String:
		match correct_answer.to_upper():
			"A": correct_index = 0
			"B": correct_index = 1
			"C": correct_index = 2
			"D": correct_index = 3
			_: correct_index = 0
	elif correct_answer is int:
		correct_index = clamp(correct_answer, 0, 3)
	else:
		print("❌ Índice de resposta correta inválido: ", correct_answer)
		correct_index = 0
	
	var correct_letter = ""
	match correct_index:
		0: correct_letter = "A"
		1: correct_letter = "B"
		2: correct_letter = "C"
		3: correct_letter = "D"
	
	print("🔍 Question: ", question_text)
	print("🔍 Options: ", options)
	print("🔍 Correct answer: ", correct_letter, " (index ", correct_index, ")")
	
	# Display the quiz
	quiz_question.text = question_text
	quiz_option_a.text = options[0]
	quiz_option_b.text = options[1]
	quiz_option_c.text = options[2]
	quiz_option_d.text = options[3]
	
	# Adjust button heights for long text
	adjust_all_button_heights()
	
	# Store correct answer for validation
	correct_answer_index = correct_index
	
	# Enable quiz buttons
	enable_quiz_buttons()
	
	print("✅ Quiz JSON exibido com sucesso!")
	print("🎯 Pergunta: ", question_text)
	print("🎯 Resposta correta: ", correct_letter)

func cache_npc_data(npc):
	if not npc or not is_instance_valid(npc):
		return
	
	var npc_data = {
		"npc_name": npc.npc_name,
		"subject": npc.subject,
		"greeting_message": npc.greeting_message,
		"room_id": npc.room_id,
		"unlocks_room": npc.unlocks_room,
		"quiz_mode": npc.quiz_mode,
		"reference": npc # Keep actual reference as backup
	}
	
	cached_npc_data[npc.npc_name] = npc_data
	
	# Also store in persistent variables
	current_npc_name = npc.npc_name
	current_npc_subject = npc.subject
	

func get_npc_for_chat():
	print("🔍 === GET NPC FOR CHAT ===")
	
	# Priority 1: Use current_npc if valid
	if current_npc and is_instance_valid(current_npc):
		print("🔍 Prioridade 1: current_npc válido: ", current_npc.npc_name)
		return current_npc
	
	# Priority 2: Use last_detected_npc if valid
	if last_detected_npc and is_instance_valid(last_detected_npc):
		print("🔍 Prioridade 2: last_detected_npc válido: ", last_detected_npc.npc_name)
		current_npc = last_detected_npc
		return last_detected_npc
	
	# Priority 3: Try to find NPC from cached data
	print("🔍 Prioridade 3: buscando no cache (", cached_npc_data.size(), " itens)")
	for npc_name in cached_npc_data:
		var cached_data = cached_npc_data[npc_name]
		if cached_data.has("reference") and cached_data["reference"] and is_instance_valid(cached_data["reference"]):
			print("🔍 Encontrado no cache: ", npc_name)
			current_npc = cached_data["reference"]
			return current_npc
	
	# Priority 4: Force search as last resort
	print("🔍 Prioridade 4: force_find_nearby_npc")
	var found_npc = force_find_nearby_npc()
	if found_npc:
		print("🔍 Encontrado por busca forçada: ", found_npc.npc_name)
		current_npc = found_npc
		cache_npc_data(found_npc)
		return found_npc
	
	print("🔍 FALHA: Nenhum NPC encontrado em todas as prioridades")
	return null

func show_complete_debug_info():
	pass

func create_quiz_prompt(npc) -> String:
	# Use persistent data instead of NPC reference
	var npc_name = current_npc_name
	var npc_subject = current_npc_subject
	
	if npc_name == "" or npc_subject == "":
		# Fallback to npc parameter if persistent data not available
		if npc and is_instance_valid(npc):
			npc_name = npc.npc_name
			npc_subject = npc.subject
		else:
			return "Erro: NPC inválido para criação de pergunta de múltipla escolha"
	
	var attempt_count = npc_attempt_counts.get(npc_name, 0)
	
	var base_prompt = "Professor(a) " + npc_name + " de " + npc_subject + " (6º ano). "
	base_prompt += "IMPORTANTE: Gere UMA pergunta de múltipla escolha com 4 alternativas sobre " + npc_subject + ". "
	base_prompt += "A pergunta deve ser específica e as alternativas devem estar relacionadas à pergunta. "
	
	# Add topic variety system
	var topic_variety_prompt = get_topic_variety_prompt(npc_name, npc_subject, attempt_count)
	base_prompt += topic_variety_prompt
	
	match npc_subject:
		"Geografia":
			base_prompt += "BNCC 6º ano GEOGRAFIA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🌍 O SUJEITO E SEU LUGAR NO MUNDO: Identidade sociocultural; conceito de espaço; lugar de vivência; paisagens da cidade e do campo; "
			base_prompt += "🔗 CONEXÕES E ESCALAS: Relações entre os componentes físico-naturais (formas de relevo, tempo atmosférico, clima, hidrografia, solos, vegetação); "
			base_prompt += "💼 MUNDO DO TRABALHO: Transformação das paisagens naturais e antrópicas; diferentes tipos de trabalho no campo e na cidade; "
			base_prompt += "🗺️ FORMAS DE REPRESENTAÇÃO: Fenômenos naturais e sociais representados de diferentes maneiras; leitura de mapas; escalas cartográficas. "
		"Português":
			base_prompt += "BNCC 6º ano LÍNGUA PORTUGUESA - TÓPICOS VARIADOS:\n"
			base_prompt += "📖 LEITURA E INTERPRETAÇÃO: Textos narrativos (contos, fábulas), textos informativos, inferências, tema central, personagens, tempo e espaço; "
			base_prompt += "🔤 ORTOGRAFIA E ACENTUAÇÃO: Palavras com dificuldades ortográficas, acentuação de oxítonas, paroxítonas e proparoxítonas, uso de hífen; "
			base_prompt += "📝 PONTUAÇÃO: Vírgula em enumerações, ponto final, exclamação, interrogação, dois pontos, aspas; "
			base_prompt += "🏷️ CLASSES GRAMATICAIS: Substantivos (próprios, comuns, coletivos), adjetivos, verbos (tempos presente, passado, futuro), artigos, pronomes; "
			base_prompt += "🔗 SINTAXE: Sujeito e predicado, concordância nominal básica, formação de frases; "
			base_prompt += "📚 LITERATURA: Elementos da narrativa, diferença entre prosa e verso, rimas, figuras de linguagem simples (metáfora, comparação); "
			base_prompt += "✍️ PRODUÇÃO TEXTUAL: Estrutura de parágrafos, coesão textual, tipos de texto (narrativo, descritivo, instrucional). "
		"Ciências":
			base_prompt += "BNCC 6º ano CIÊNCIAS DA NATUREZA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🔬 MATÉRIA E ENERGIA: Estados físicos da matéria e transformações; misturas e separação de materiais (filtração, decantação, destilação); fontes de energia (renováveis e não renováveis); usos da energia no cotidiano e impactos ambientais; luz, som, calor e eletricidade no dia a dia. "
			base_prompt += "🌎 TERRA E UNIVERSO: Estrutura da Terra (camadas, relevo, rochas e minerais); movimentos da Terra (rotação e translação, estações do ano, dia e noite); fases da Lua e eclipses; Sistema Solar (planetas, asteroides, cometas); universo (galáxias, estrelas, distâncias astronômicas). "
			base_prompt += "🧬 VIDA E EVOLUÇÃO: Características gerais dos seres vivos; diversidade da vida (plantas, animais, fungos, bactérias e protozoários); organização dos seres vivos (células, tecidos, órgãos e sistemas); reprodução (asexuada e sexuada); ciclos de vida e relações ecológicas (predação, competição, simbiose). "
			base_prompt += "🧍 SER HUMANO E SAÚDE: Corpo humano (sistemas digestório, respiratório, circulatório, excretor); alimentação saudável, nutrientes e pirâmide alimentar; higiene pessoal e prevenção de doenças; doenças transmissíveis e não transmissíveis; vacinação, autocuidado e saúde coletiva. "
		"Matemática":
			base_prompt += "BNCC 6º ano MATEMÁTICA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🔢 NÚMEROS: Operações com números naturais e decimais; frações e suas operações; porcentagem e proporcionalidade; "
			base_prompt += "📐 GEOMETRIA: Figuras planas e espaciais; perímetro, área e volume; simetria e transformações geométricas; "
			base_prompt += "📏 GRANDEZAS E MEDIDAS: Comprimento, massa, capacidade, tempo; conversões entre unidades; "
			base_prompt += "📊 ESTATÍSTICA E PROBABILIDADE: Coleta e organização de dados; gráficos (colunas, barras, linhas); probabilidade simples. "
		"História":
			base_prompt += "BNCC 6º ano HISTÓRIA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "⏰ TEMPO HISTÓRICO: Cronologia e periodização; fontes históricas (escritas, orais, iconográficas); "
			base_prompt += "👥 SOCIEDADE E CULTURA: Diversidade cultural; tradições e costumes; identidade e alteridade; "
			base_prompt += "🔧 TRABALHO E TECNOLOGIA: Evolução das técnicas; impacto das tecnologias na sociedade; "
			base_prompt += "🇧🇷 BRASIL: Formação do território brasileiro; diversidade regional; patrimônio histórico e cultural. "
		"Revisão Geral":
			base_prompt += "BNCC 6º ano - REVISÃO INTERDISCIPLINAR:\n"
			base_prompt += "📚 PORTUGUÊS: Leitura, escrita, oralidade e análise linguística; "
			base_prompt += "🔢 MATEMÁTICA: Números, geometria, grandezas e medidas, estatística; "
			base_prompt += "🔬 CIÊNCIAS: Vida e evolução, matéria e energia, terra e universo; "
			base_prompt += "🌍 GEOGRAFIA: Espaço geográfico, natureza e sociedade, mundo do trabalho; "
			base_prompt += "📖 HISTÓRIA: Tempo histórico, sociedade e cultura, trabalho e tecnologia. "
	
	base_prompt += "\n\nFORMATO OBRIGATÓRIO - RESPONDA EXATAMENTE ASSIM:\n"
	base_prompt += "PERGUNTA: [sua pergunta aqui]\n"
	base_prompt += "A) [primeira opção]\n"
	base_prompt += "B) [segunda opção]\n"
	base_prompt += "C) [terceira opção]\n"
	base_prompt += "D) [quarta opção]\n"
	base_prompt += "CORRETA: [A, B, C ou D]\n\n"
	base_prompt += "REGRA ESPECIAL: Se usar 'Todas as anteriores', 'Todas as alternativas' ou similar, SEMPRE coloque como opção D.\n\n"
	base_prompt += "FORMATO OBRIGATÓRIO:\n"
	base_prompt += "PERGUNTA: [Sua pergunta aqui]\n"
	base_prompt += "A) [Alternativa A]\n"
	base_prompt += "B) [Alternativa B]\n"
	base_prompt += "C) [Alternativa C]\n"
	base_prompt += "D) [Alternativa D]\n"
	base_prompt += "CORRETA: [Letra da resposta correta]\n\n"
	base_prompt += "EXEMPLO:\n"
	base_prompt += "PERGUNTA: Quais são características dos seres vivos?\n"
	base_prompt += "A) Nascem e crescem\n"
	base_prompt += "B) Se reproduzem\n"
	base_prompt += "C) Morrem\n"
	base_prompt += "D) Todas as anteriores\n"
	base_prompt += "CORRETA: D"
	
	return base_prompt

func _on_quiz_question_generated(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	awaiting_question = false
	
	print("📩 === CALLBACK CALLED: _on_quiz_question_generated ===")
	print("📩 Result: ", _result)
	print("📩 Response code: ", response_code)
	print("📩 Body size: ", body.size())
	print("📋 Current NPC: ", current_npc.npc_name if current_npc else "null")
	print("📋 Persistent NPC name: ", current_npc_name)
	
	if current_npc_name == "":
		print("❌ Nenhum NPC persistente disponível")
		quiz_question.text = "❌ Erro: NPC não disponível para receber pergunta de quiz"
		return
	
	if response_code == 200 and body.size() > 0:
		var body_string = body.get_string_from_utf8()
		var response = JSON.parse_string(body_string)
		
		if response != null and response.has("choices") and response.choices.size() > 0:
			var generated_quiz = response["choices"][0]["message"]["content"]
			print("✅ Quiz gerado com sucesso para: ", current_npc_name)
			print("📝 Quiz content: ", generated_quiz)
			
			# Parse the quiz content
			parse_and_display_quiz(generated_quiz)
		else:
			quiz_question.text = "❌ Erro: Falha ao gerar pergunta de múltipla escolha"
	else:
		quiz_question.text = "❌ Erro " + str(response_code) + ": Falha na geração da pergunta de quiz"
	
	# Clean up
	var quiz_request = get_node_or_null("Quiz_Request")
	if quiz_request:
		quiz_request.queue_free()
		print("🧹 HTTPRequest de quiz limpo")

func parse_and_display_quiz(quiz_content: String):
	print("🔍 === PARSING QUIZ CONTENT ===")
	print("🔍 NPC atual: ", current_npc_name)
	print("🔍 Matéria atual: ", current_npc_subject)
	print("🔍 Conteúdo recebido: ", quiz_content)
	
	# LIMPAR dados anteriores para evitar mistura
	var question_text = ""
	var options = ["", "", "", ""]
	var correct_letter = ""
	
	# Parse the quiz content to extract question and options
	var lines = quiz_content.split("\n")
	
	for line in lines:
		line = line.strip_edges()
		print("🔍 Processing line: '", line, "'")
		
		if line.begins_with("PERGUNTA:"):
			question_text = line.substr(10).strip_edges()
			print("🔍 Found question: ", question_text)
		elif line.begins_with("A)"):
			options[0] = line.substr(2).strip_edges()
			print("🔍 Found option A: ", options[0])
		elif line.begins_with("B)"):
			options[1] = line.substr(2).strip_edges()
			print("🔍 Found option B: ", options[1])
		elif line.begins_with("C)"):
			options[2] = line.substr(2).strip_edges()
			print("🔍 Found option C: ", options[2])
		elif line.begins_with("D)"):
			options[3] = line.substr(2).strip_edges()
			print("🔍 Found option D: ", options[3])
		elif line.begins_with("CORRETA:"):
			correct_letter = line.substr(8).strip_edges().to_upper()
			print("🔍 Found correct answer: ", correct_letter)
	
	# Fallback: if question is empty, try to extract from the first meaningful line
	if question_text == "":
		for line in lines:
			line = line.strip_edges()
			if line != "" and not line.begins_with("A)") and not line.begins_with("B)") and not line.begins_with("C)") and not line.begins_with("D)") and not line.begins_with("CORRETA:") and not line.begins_with("PERGUNTA:"):
				question_text = line
				print("🔍 Using fallback question: ", question_text)
				break
	
	# Final fallback if still no question
	if question_text == "":
		question_text = "Pergunta não pôde ser extraída. Conteúdo: " + quiz_content.substr(0, 100)
		print("❌ Could not extract question, using fallback")
	
	print("🎯 Final question: ", question_text)
	print("🎯 Final options: ", options)
	print("🎯 Correct letter: ", correct_letter)
	print("🔍 === FIM PARSING ===")
	
	# Set correct answer index
	match correct_letter:
		"A": correct_answer_index = 0
		"B": correct_answer_index = 1
		"C": correct_answer_index = 2
		"D": correct_answer_index = 3
		_: correct_answer_index = 0 # Default fallback
	
	# Check if any option contains "todas" patterns and should stay as last option
	var has_todas_option = false
	var todas_option_index = -1
	
	for i in range(4):
		var option_lower = options[i].to_lower()
		if "todas as anteriores" in option_lower or "todas as alternativas" in option_lower or "todas estão corretas" in option_lower or "todas acima" in option_lower:
			has_todas_option = true
			todas_option_index = i
			print("🔍 Encontrou opção 'todas' no índice: ", i, " - ", options[i])
			break
	
	var new_options = ["", "", "", ""]
	var new_correct_index = 0
	
	if has_todas_option:
		# Special handling for "todas" options - keep them as option D
		var other_options = []
		var other_indices = []
		
		# Collect non-"todas" options
		for i in range(4):
			if i != todas_option_index:
				other_options.append(options[i])
				other_indices.append(i)
		
		# Shuffle the first 3 options
		var shuffled_indices = [0, 1, 2]
		shuffled_indices.shuffle()
		
		# Place shuffled options in positions A, B, C
		for i in range(3):
			var original_index = other_indices[shuffled_indices[i]]
			new_options[i] = other_options[shuffled_indices[i]]
			if original_index == correct_answer_index:
				new_correct_index = i
		
		# Always place "todas" option as D
		new_options[3] = options[todas_option_index]
		if todas_option_index == correct_answer_index:
			new_correct_index = 3
		
		print("🔧 Opção 'todas' colocada como D: ", new_options[3])
	else:
		# Normal shuffling when no "todas" option exists
		var shuffled_options = options.duplicate()
		var shuffled_indices = [0, 1, 2, 3]
		
		# Shuffle indices
		shuffled_indices.shuffle()
		
		# Rearrange options and update correct answer index
		for i in range(4):
			var original_index = shuffled_indices[i]
			new_options[i] = shuffled_options[original_index]
			if original_index == correct_answer_index:
				new_correct_index = i
	
	correct_answer_index = new_correct_index
	
	print("🎲 Opções embaralhadas - Nova resposta correta no índice: ", correct_answer_index)
	
	# Display the quiz with question and greeting
	var cached_data = cached_npc_data.get(current_npc_name, {})
	var greeting = cached_data.get("greeting_message", "Olá!")
	var attempt_count = npc_attempt_counts.get(current_npc_name, 0)
	
	if attempt_count == 0:
		# First question - include greeting
		quiz_question.text = "[b]" + current_npc_name + ":[/b] " + greeting
		quiz_question.text += "\n\n[b]PERGUNTA:[/b]\n" + question_text
		quiz_question.text += "\n[color=gray][i](Você tem 3 tentativas para esta pergunta)[/i][/color]"
	else:
		# Subsequent questions - just add the new question
		var remaining_attempts = 3 - attempt_count
		quiz_question.text = "[b]" + current_npc_name + ":[/b] Vamos tentar com esta pergunta:"
		quiz_question.text += "\n\n[b]PERGUNTA:[/b]\n" + question_text
		quiz_question.text += "\n[color=gray][i](Tentativas restantes: " + str(remaining_attempts) + ")[/i][/color]"
	
	# Set the button options
	quiz_option_a.text = "A) " + new_options[0]
	quiz_option_b.text = "B) " + new_options[1]
	quiz_option_c.text = "C) " + new_options[2]
	quiz_option_d.text = "D) " + new_options[3]
	
	# Adjust button heights for long text
	adjust_all_button_heights()
	
	# Enable buttons
	enable_quiz_buttons()

func create_question_prompt(npc) -> String:
	# Use persistent data instead of NPC reference
	var npc_name = current_npc_name
	var npc_subject = current_npc_subject
	
	if npc_name == "" or npc_subject == "":
		# Fallback to npc parameter if persistent data not available
		if npc and is_instance_valid(npc):
			npc_name = npc.npc_name
			npc_subject = npc.subject
		else:
			return "Erro: NPC inválido para criação de pergunta"
	
	var attempt_count = npc_attempt_counts.get(npc_name, 0)
	
	# Optimized shorter prompt for faster response
	var base_prompt = "Professor(a) " + npc_name + " de " + npc_subject + " (6º ano). "
	
	if attempt_count > 0:
		base_prompt += "Nova pergunta, tópico diferente. "
	
	match npc_subject:
		"Geografia":
			base_prompt += "BNCC 6º ano GEOGRAFIA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🌍 O SUJEITO E SEU LUGAR NO MUNDO: Identidade sociocultural; conceito de espaço; lugar de vivência; paisagens da cidade e do campo; "
			base_prompt += "🔗 CONEXÕES E ESCALAS: Relações entre os componentes físico-naturais (formas de relevo, tempo atmosférico, clima, hidrografia, solos, vegetação); "
			base_prompt += "💼 MUNDO DO TRABALHO: Transformação das paisagens naturais e antrópicas; diferentes tipos de trabalho no campo e na cidade; "
			base_prompt += "🗺️ FORMAS DE REPRESENTAÇÃO: Fenômenos naturais e sociais representados de diferentes maneiras; leitura de mapas; escalas cartográficas. "
		"Português":
			base_prompt += "BNCC 6º ano LÍNGUA PORTUGUESA - TÓPICOS VARIADOS:\n"
			base_prompt += "📖 LEITURA E INTERPRETAÇÃO: Textos narrativos (contos, fábulas), textos informativos, inferências, tema central, personagens, tempo e espaço; "
			base_prompt += "🔤 ORTOGRAFIA E ACENTUAÇÃO: Palavras com dificuldades ortográficas, acentuação de oxítonas, paroxítonas e proparoxítonas, uso de hífen; "
			base_prompt += "📝 PONTUAÇÃO: Vírgula em enumerações, ponto final, exclamação, interrogação, dois pontos, aspas; "
			base_prompt += "🏷️ CLASSES GRAMATICAIS: Substantivos (próprios, comuns, coletivos), adjetivos, verbos (tempos presente, passado, futuro), artigos, pronomes; "
			base_prompt += "🔗 SINTAXE: Sujeito e predicado, concordância nominal básica, formação de frases; "
			base_prompt += "📚 LITERATURA: Elementos da narrativa, diferença entre prosa e verso, rimas, figuras de linguagem simples (metáfora, comparação); "
			base_prompt += "✍️ PRODUÇÃO TEXTUAL: Estrutura de parágrafos, coesão textual, tipos de texto (narrativo, descritivo, instrucional). "
		"Ciências":
			base_prompt += "BNCC 6º ano CIÊNCIAS DA NATUREZA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🔬 MATÉRIA E ENERGIA: Estados físicos da matéria e transformações; misturas e separação de materiais (filtração, decantação, destilação); fontes de energia (renováveis e não renováveis); usos da energia no cotidiano e impactos ambientais; luz, som, calor e eletricidade no dia a dia. "
			base_prompt += "🌎 TERRA E UNIVERSO: Estrutura da Terra (camadas, relevo, rochas e minerais); movimentos da Terra (rotação e translação, estações do ano, dia e noite); fases da Lua e eclipses; Sistema Solar (planetas, asteroides, cometas); universo (galáxias, estrelas, distâncias astronômicas). "
			base_prompt += "🧬 VIDA E EVOLUÇÃO: Características gerais dos seres vivos; diversidade da vida (plantas, animais, fungos, bactérias e protozoários); organização dos seres vivos (células, tecidos, órgãos e sistemas); reprodução (asexuada e sexuada); ciclos de vida e relações ecológicas (predação, competição, simbiose). "
			base_prompt += "🧍 SER HUMANO E SAÚDE: Corpo humano (sistemas digestório, respiratório, circulatório, excretor); alimentação saudável, nutrientes e pirâmide alimentar; higiene pessoal e prevenção de doenças; doenças transmissíveis e não transmissíveis; vacinação, autocuidado e saúde coletiva. "
		"Matemática":
			base_prompt += "BNCC 6º ano MATEMÁTICA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "🔢 NÚMEROS: Operações com números naturais e decimais; frações e suas operações; porcentagem e proporcionalidade; "
			base_prompt += "📐 GEOMETRIA: Figuras planas e espaciais; perímetro, área e volume; simetria e transformações geométricas; "
			base_prompt += "📏 GRANDEZAS E MEDIDAS: Comprimento, massa, capacidade, tempo; conversões entre unidades; "
			base_prompt += "📊 ESTATÍSTICA E PROBABILIDADE: Coleta e organização de dados; gráficos (colunas, barras, linhas); probabilidade simples. "
		"História":
			base_prompt += "BNCC 6º ano HISTÓRIA - UNIDADES TEMÁTICAS:\n"
			base_prompt += "⏰ TEMPO HISTÓRICO: Cronologia e periodização; fontes históricas (escritas, orais, iconográficas); "
			base_prompt += "👥 SOCIEDADE E CULTURA: Diversidade cultural; tradições e costumes; identidade e alteridade; "
			base_prompt += "🔧 TRABALHO E TECNOLOGIA: Evolução das técnicas; impacto das tecnologias na sociedade; "
			base_prompt += "🇧🇷 BRASIL: Formação do território brasileiro; diversidade regional; patrimônio histórico e cultural. "
		"Revisão Geral":
			base_prompt += "BNCC 6º ano - REVISÃO INTERDISCIPLINAR:\n"
			base_prompt += "📚 PORTUGUÊS: Leitura, escrita, oralidade e análise linguística; "
			base_prompt += "🔢 MATEMÁTICA: Números, geometria, grandezas e medidas, estatística; "
			base_prompt += "🔬 CIÊNCIAS: Vida e evolução, matéria e energia, terra e universo; "
			base_prompt += "🌍 GEOGRAFIA: Espaço geográfico, natureza e sociedade, mundo do trabalho; "
			base_prompt += "📖 HISTÓRIA: Tempo histórico, sociedade e cultura, trabalho e tecnologia. "
	
	base_prompt += "Pergunta clara e objetiva APENAS."
	return base_prompt

func _on_question_generated(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	awaiting_question = false
	
	# Cancel timeout timer since we got a response
	if current_timeout_timer and is_instance_valid(current_timeout_timer):
		current_timeout_timer.timeout.disconnect(_on_question_timeout)
		current_timeout_timer = null
		print("⏰ Timer cancelado - resposta recebida")
	
	# Calculate performance time
	var end_time = Time.get_ticks_msec()
	var request_time = (end_time - start_time) / 1000.0
	
	print("📩 === CALLBACK CALLED: _on_question_generated ===")
	print("📩 Result: ", _result)
	print("📩 Response code: ", response_code)
	print("📩 Body size: ", body.size())
	print("⏱️ Request time: ", request_time, "s")
	print("📋 Current NPC: ", current_npc.npc_name if current_npc else "null")
	print("📋 Persistent NPC name: ", current_npc_name)
	
	# Use persistent NPC data instead of direct reference
	if current_npc_name == "":
		print("❌ Nenhum NPC persistente disponível")
		chat_history.text += "\n[color=red][b]❌ Erro:[/b] NPC não disponível para receber pergunta[/color]"
		return
	
	if response_code == 200 and body.size() > 0:
		var body_string = body.get_string_from_utf8()
		var response = JSON.parse_string(body_string)
		
		# Handle Supabase proxy response format
		if response != null and response.has("success") and response.success and response.has("response"):
			var generated_question = response["response"]
			npc_questions[current_npc_name] = generated_question
			
			var attempt_count = npc_attempt_counts.get(current_npc_name, 0)
			var cached_data = cached_npc_data.get(current_npc_name, {})
			var greeting = cached_data.get("greeting_message", "Olá!")
			
			print("✅ Pergunta gerada com sucesso para: ", current_npc_name)
			
			# Update chat with the generated question
			if attempt_count == 0:
				# First question - include greeting
				chat_history.text = "[b]" + current_npc_name + ":[/b] " + greeting
				chat_history.text += "\n[b]" + current_npc_name + ":[/b] " + generated_question
				chat_history.text += "\n[color=gray][i](Você tem 3 tentativas para esta pergunta)[/i][/color]"
			else:
				# Subsequent questions - just add the new question
				var remaining_attempts = 3 - attempt_count
				chat_history.text += "\n[b]" + current_npc_name + ":[/b] Vamos tentar com esta pergunta:"
				chat_history.text += "\n[b]" + current_npc_name + ":[/b] " + generated_question
				chat_history.text += "\n[color=gray][i](Tentativas restantes: " + str(remaining_attempts) + ")[/i][/color]"
		else:
			chat_history.text += "\n[color=red][b]❌ Erro:[/b] Falha ao gerar pergunta[/color]"
	else:
		chat_history.text += "\n[color=red][b]❌ Erro " + str(response_code) + ":[/b] Falha na geração da pergunta[/color]"
	
	# Clean up only the question request after processing
	var question_request = get_node_or_null("Question_Request")
	if question_request:
		question_request.queue_free()
		print("🧹 HTTPRequest de pergunta limpo")

func create_evaluation_prompt(npc, user_answer: String) -> String:
	# Use persistent data instead of NPC reference
	var npc_name = current_npc_name
	var npc_subject = current_npc_subject
	
	if npc_name == "" or npc_subject == "":
		# Fallback to npc parameter if persistent data not available
		if npc and is_instance_valid(npc):
			npc_name = npc.npc_name
			npc_subject = npc.subject
		else:
			return "Erro: NPC inválido para avaliação"
	
	var question = npc_questions.get(npc_name, "pergunta não disponível")
	var attempt_count = npc_attempt_counts.get(npc_name, 0)
	
	var prompt = "Você é " + npc_name + ", professor(a) brasileiro(a) de " + npc_subject + " avaliando um aluno do 6º ano.\n"
	prompt += "PERGUNTA FEITA: " + question + "\n"
	prompt += "RESPOSTA DO ALUNO: " + user_answer + "\n"
	
	if attempt_count > 0:
		prompt += "TENTATIVA NÚMERO: " + str(attempt_count + 1) + "\n"
	
	prompt += "\nFORMATO OBRIGATÓRIO DA RESPOSTA:\n"
	prompt += "1. Inicie com 'PERCENTUAL: X%' onde X é o percentual de corretude (0-100)\n"
	prompt += "2. Se percentual >= 80%: Continue com 'PARABÉNS! Resposta correta!' e explique brevemente por que está certo\n"
	prompt += "3. Se percentual < 80%: Continue com 'Quase lá!' e dê uma explicação educativa da resposta correta de forma encorajadora\n\n"
	
	prompt += "EXEMPLOS:\n"
	prompt += "CORRETO (≥80%): 'PERCENTUAL: 90% - PARABÉNS! Resposta correta! A região Norte é mesmo a maior do Brasil devido à Amazônia.'\n"
	prompt += "INCORRETO (<80%): 'PERCENTUAL: 40% - Quase lá! A resposta correta é Norte. Esta região é a maior porque inclui toda a floresta Amazônica, que ocupa uma área imensa do país.'\n\n"
	
	prompt += "Seja sempre encorajador e educativo. Se errou, explique a resposta correta de forma clara e positiva."
	return prompt

func _on_answer_evaluated(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	# Use persistent NPC data instead of direct reference
	if current_npc_name == "":
		chat_history.text += "\n[color=red][b]❌ Erro:[/b] NPC não disponível para avaliação[/color]"
		return
	
	if response_code == 200 and body.size() > 0:
		var body_string = body.get_string_from_utf8()
		var response = JSON.parse_string(body_string)
		
		# Handle Supabase proxy response format
		if response != null and response.has("success") and response.success and response.has("response"):
			var evaluation_result = response["response"]
			chat_history.text += "\n[color=white][b]" + current_npc_name + ":[/b][/color]"
			chat_history.text += "\n[color=lightgreen]" + evaluation_result + "[/color]"
			
			# Extract percentage and validate (70% minimum for approval)
			var percentage = extract_percentage(evaluation_result)
			if percentage >= 70:
				# Student got it right! Unlock the room
				unlock_room_by_npc_name(current_npc_name)
				chat_history.text += "\n[color=gold][b]🎉 PORTA DESBLOQUEADA![/b][/color]"
				chat_history.text += "\n[color=cyan][b]Você pode fechar o chat e prosseguir para a próxima sala![/b][/color]"
			else:
				# Student got it wrong, increment attempt count
				npc_attempt_counts[current_npc_name] = npc_attempt_counts.get(current_npc_name, 0) + 1
				var current_attempts = npc_attempt_counts[current_npc_name]
				
				if current_attempts >= 3:
					# Maximum attempts reached
					chat_history.text += "\n[color=red][b]📝 Você já tentou 3 vezes.[/b][/color]"
					chat_history.text += "\n[color=yellow][b]💡 Sugestão: Estude mais sobre " + current_npc_subject + " e volte depois![/b][/color]"
					chat_history.text += "\n[color=cyan][b]🚪 Você pode fechar o chat e tentar com outro professor.[/b][/color]"
				else:
					# Generate new question
					var remaining_attempts = 3 - current_attempts
					chat_history.text += "\n[color=orange][b]🔄 Preparando uma nova pergunta... (Tentativas restantes: " + str(remaining_attempts) + ")[/b][/color]"
					
					# Brief pause for feedback readability, then generate new question
					print("⏱️ Aguardando 0.5s antes da nova pergunta...")
					await get_tree().create_timer(0.5).timeout
					print("⏱️ Iniciando geração da nova pergunta...")
					if current_npc_name != "": # Check persistent data instead
						generate_question_for_npc(null) # Pass null, will use persistent data
		else:
			chat_history.text += "\n[color=red][b]❌ Erro:[/b] Resposta inválida na avaliação[/color]"
	else:
		chat_history.text += "\n[color=red][b]❌ Erro " + str(response_code) + ":[/b] Falha na avaliação[/color]"
	
	# Clean up
	var http_nodes = get_children().filter(func(node): return node is HTTPRequest)
	for node in http_nodes:
		node.queue_free()

func extract_percentage(text: String) -> int:
	var regex = RegEx.new()
	regex.compile("PERCENTUAL:\\s*(\\d+)%")
	var result = regex.search(text)
	if result:
		return result.get_string(1).to_int()
	return 0 # Default to 0 if no percentage found

func show_debug_info():
	chat_history.text += "\n[color=cyan][b]🔍 DEBUG INFO:[/b][/color]"
	chat_history.text += "\n[color=white]• current_npc: " + (current_npc.npc_name if current_npc else "null") + "[/color]"
	chat_history.text += "\n[color=white]• last_detected_npc: " + (last_detected_npc.npc_name if last_detected_npc else "null") + "[/color]"
	chat_history.text += "\n[color=white]• player.current_interactable: " + (player.current_interactable.name if (player and player.current_interactable) else "null") + "[/color]"
	
	chat_history.text += "\n[color=cyan]• NPCs no cache: " + str(cached_npc_data.size()) + "[/color]"
	for npc_name in cached_npc_data:
		chat_history.text += "\n[color=white]  - " + npc_name + "[/color]"
	
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	chat_history.text += "\n[color=white]• NPCs no grupo: " + str(all_npcs.size()) + "[/color]"
	
	if all_npcs.size() > 0:
		for npc in all_npcs:
			var distance = player.global_position.distance_to(npc.global_position)
			chat_history.text += "\n[color=white]  - " + npc.name + " (dist: " + str(distance).pad_decimals(1) + "m)[/color]"

func test_http_connection():
	chat_history.text += "\n[color=cyan][b]Sistema:[/b] Testando conexão HTTP...[/color]"
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = 10.0
	http_request.request_completed.connect(_on_test_response_received)
	
	# Test with a simple API that should work
	var result = http_request.request("https://httpbin.org/get")
	if result != OK:
		chat_history.text += "\n[color=red][b]❌ Test HTTP failed:[/b] " + str(result) + "[/color]"
	else:
		chat_history.text += "\n[color=green][b]✅ Test HTTP sent,[/b] waiting for response...[/color]"

func _on_test_response_received(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	chat_history.text += "\n[color=green][b]✅ Test HTTP Response:[/b] Code " + str(response_code) + "[/color]"
	
	# Clean up
	var http_nodes = get_children().filter(func(node): return node is HTTPRequest)
	for node in http_nodes:
		if node != get_node_or_null("HTTPRequest"): # Don't remove OpenAI requests
			node.queue_free()

func evaluate_student_answer(user_answer: String, npc):
	if not npc or not is_instance_valid(npc):
		chat_history.text += "\n[color=red][b]❌ ERRO:[/b] NPC inválido para avaliação![/color]"
		return
	
	# Clean up existing requests
	var existing_http = get_children().filter(func(node): return node is HTTPRequest)
	for node in existing_http:
		node.queue_free()
	
	# Create request for answer evaluation
	var http_request = HTTPRequest.new()
	http_request.name = "Evaluation_Request"
	add_child(http_request)
	http_request.timeout = 15.0 # Optimized timeout for faster response
	
	# Connect signal
	http_request.request_completed.connect(_on_answer_evaluated)
	
	# Use Supabase proxy headers
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + SupabaseConfig.ANON_KEY,
		"apikey: " + SupabaseConfig.ANON_KEY
	]
	
	# Create rigorous evaluation prompt
	var current_question = npc_questions.get(current_npc_name, "")
	var simplified_prompt = "Avalie esta resposta com rigor acadêmico (BNCC 6º ano):"
	simplified_prompt += " PERGUNTA: " + current_question
	simplified_prompt += " RESPOSTA DO ALUNO: " + user_answer
	simplified_prompt += " INSTRUÇÕES: Dê uma nota de 0-100% baseada na correção factual."
	simplified_prompt += " Mínimo 70% para aprovação. Seja rigoroso mas justo."
	simplified_prompt += " FORMATO: 'NOTA: X% - [explicação]'"
	
	var body = JSON.stringify({
		"prompt": simplified_prompt,
		"subject": current_npc_subject,
		"quiz_mode": "avaliacao"
	})
	
	var result = http_request.request(supabase_proxy_url, headers, HTTPClient.METHOD_POST, body)
	
	if result == OK:
		chat_history.text += "\n[color=lime][b]✅ Enviado:[/b] Avaliando sua resposta...[/color]"
		print("✅ Requisição de avaliação enviada com sucesso")
	else:
		chat_history.text += "\n[color=red][b]❌ Erro:[/b] Falha ao avaliar resposta[/color]"
		http_request.queue_free()

func request_ai_response(user_message: String, _npc):
	# Using Supabase proxy - no API key validation needed
	# Clean up existing requests
	var existing_http = get_children().filter(func(node): return node is HTTPRequest)
	for node in existing_http:
		node.queue_free()
	
	# Create request
	var http_request = HTTPRequest.new()
	http_request.name = "OpenAI_Request"
	add_child(http_request)
	http_request.timeout = 15.0 # Optimized timeout for faster response
	
	# Connect signal
	http_request.request_completed.connect(_on_ai_response_received)
	
	# Use Supabase proxy headers
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + SupabaseConfig.ANON_KEY,
		"apikey: " + SupabaseConfig.ANON_KEY
	]
	
	# Create simplified chat prompt
	var simplified_prompt = "Responda como um professor amigável de " + current_npc_subject + " para um aluno do 6º ano."
	simplified_prompt += " Professor: " + current_npc_name
	simplified_prompt += " Mensagem do aluno: " + user_message
	simplified_prompt += " Responda de forma educativa e motivadora."
	
	var body = JSON.stringify({
		"prompt": simplified_prompt,
		"subject": current_npc_subject,
		"quiz_mode": "conversa"
	})
	
	chat_history.text += "\n[color=purple][b]📦 DADOS:[/b] Body size: " + str(body.length()) + " chars[/color]"
	
	# Send request
	var result = http_request.request(supabase_proxy_url, headers, HTTPClient.METHOD_POST, body)
	
	if result == OK:
		chat_history.text += "\n[color=lime][b]✅ Enviado:[/b] Aguardando resposta do professor...[/color]"
		print("✅ Requisição AI enviada com sucesso")
	else:
		chat_history.text += "\n[color=red][b]❌ Erro:[/b] Falha ao enviar pergunta[/color]"
		http_request.queue_free()

func create_system_prompt(npc) -> String:
	var base_prompt = "Você é " + npc.npc_name + ", professor(a) brasileiro(a) ensinando alunos do 6º ano do Ensino Fundamental. "
	base_prompt += "Responda sempre em português brasileiro de forma clara e adequada para a idade. "
	base_prompt += "Seja encorajador(a) e use linguagem simples. Máximo 100 palavras por resposta. "
	
	match npc.subject:
		"Geografia":
			base_prompt += "ESPECIALISTA EM GEOGRAFIA BNCC 6º ANO - UNIDADES TEMÁTICAS:\n"
			base_prompt += "1. O sujeito e seu lugar no mundo: identidade sociocultural; conceito de espaço; lugar de vivência; paisagens da cidade e do campo;\n"
			base_prompt += "2. Conexões e escalas: relações entre os componentes físico-naturais (formas de relevo, tempo atmosférico, clima, hidrografia, solos, vegetação);\n"
			base_prompt += "3. Mundo do trabalho: transformação das paisagens naturais e antrópicas; diferentes tipos de trabalho no campo e na cidade;\n"
			base_prompt += "4. Formas de representação: fenômenos naturais e sociais representados de diferentes maneiras; leitura de mapas; escalas cartográficas.\n"
			base_prompt += "REGRA ABSOLUTA: JAMAIS PERGUNTE 'QUAL É A CAPITAL DA REGIÃO'. REGIÕES NÃO TÊM CAPITAIS!\n"
			base_prompt += "Foque em aspectos geográficos educativos seguindo rigorosamente a BNCC 6º ano."
		
		"Biologia":
			base_prompt += "ESPECIALISTA EM CIÊNCIAS BNCC 6º ANO - VIDA E EVOLUÇÃO:\n"
			base_prompt += "1. Célula como unidade da vida: características dos seres vivos; níveis de organização;\n"
			base_prompt += "2. Interação entre os sistemas: sistema digestório, respiratório, circulatório; relação com os alimentos;\n"
			base_prompt += "3. Lentes corretivas: funcionamento da visão;\n"
			base_prompt += "4. Integração entre sistemas: nutrição do organismo; hábitos alimentares; distúrbios nutricionais.\n"
			base_prompt += "Foque nos sistemas do corpo humano e sua relação com saúde e alimentação."
		
		"Ciências":
			base_prompt += "ESPECIALISTA EM CIÊNCIAS BNCC 6º ANO - MATÉRIA E ENERGIA + TERRA E UNIVERSO:\n"
			base_prompt += "MATÉRIA E ENERGIA: 1. Misturas homogêneas e heterogêneas; separação de materiais; transformações químicas.\n"
			base_prompt += "TERRA E UNIVERSO: 2. Forma, estrutura e movimentos da Terra; movimentos de rotação e translação; sucessão de dias e noites; estações do ano;\n"
			base_prompt += "3. Características da Terra; camadas da Terra; placas tectônicas; solo.\n"
			base_prompt += "Pergunte sobre propriedades da matéria, movimentos terrestres ou estrutura da Terra."
		
		"Revisão Geral":
			base_prompt += "DIRETOR FAZENDO REVISÃO INTERDISCIPLINAR BNCC 6º ANO:\n"
			base_prompt += "Combine conhecimentos de Geografia (relações espaciais, trabalho, paisagens), Ciências (Terra, matéria, sistemas do corpo) de forma integrada.\n"
			base_prompt += "Faça perguntas que conectem diferentes disciplinas seguindo a BNCC.\n"
			base_prompt += "Parabenize o progresso do aluno através do jogo educativo."
		
		_:
			base_prompt += "Ensine sobre " + npc.subject + " seguindo a BNCC do 6º ano. "
	
	base_prompt += "\n\nCRÍTICO - FORMATO OBRIGATÓRIO DA RESPOSTA:"
	base_prompt += "\nPara resposta CORRETA: Use EXATAMENTE 'Parabéns! Muito bem!' e termine com 'Agora você pode prosseguir para a próxima sala!'"
	base_prompt += "\nPara resposta INCORRETA: NUNCA use 'parabéns', 'correto', 'muito bem', 'certo' ou 'pode prosseguir'. Seja construtivo e dê dicas."
	base_prompt += "\nEXEMPLO CORRETO: 'Parabéns! Muito bem! A região Norte é realmente a maior. Agora você pode prosseguir para a próxima sala!'"
	base_prompt += "\nEXEMPLO INCORRETO: 'Não é bem assim. A região Sul é menor. Pense na região que tem a Amazônia. Tente novamente!'"
	
	return base_prompt

func _on_ai_response_received(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200 and body.size() > 0:
		var body_string = body.get_string_from_utf8()
		
		var response = JSON.parse_string(body_string)
		# Handle Supabase proxy response format
		if response != null and response.has("success") and response.success and response.has("response"):
			var ai_message = response["response"]
			chat_history.text += "\n[color=white][b]" + current_npc_name + ":[/b][/color]"
			chat_history.text += "\n[color=lightgreen]" + ai_message + "[/color]"
			
			# This function is no longer used - evaluation is now done separately
		else:
			chat_history.text += "\n[color=red][b]❌ ERRO:[/b] Resposta inválida[/color]"
	elif response_code == 401:
		chat_history.text += "\n[color=red][b]❌ ERRO 401:[/b] Falha na autenticação[/color]"
	elif response_code == 429:
		chat_history.text += "\n[color=red][b]❌ ERRO 429:[/b] Muitas requisições[/color]"
	else:
		chat_history.text += "\n[color=red][b]❌ ERRO " + str(response_code) + ":[/b] Falha na resposta[/color]"
	
	# Clean up
	var http_nodes = get_children().filter(func(node): return node is HTTPRequest)
	for node in http_nodes:
		node.queue_free()

func validate_student_answer(ai_response: String) -> bool:
	var response_lower = ai_response.to_lower()
	
	# First, check if AI explicitly says the answer is wrong
	var wrong_indicators = [
		"incorreto",
		"errado",
		"não está certo",
		"não é correto",
		"tente novamente",
		"não exato",
		"não é isso",
		"reveja",
		"pense melhor",
		"não é bem assim"
	]
	
	for indicator in wrong_indicators:
		if indicator in response_lower:
			return false
	
	# Only accept as correct if AI explicitly confirms success AND mentions progression
	var success_keywords = [
		"parabéns",
		"correto",
		"muito bem",
		"excelente",
		"perfeito",
		"certo",
		"acertou"
	]
	
	var progress_phrases = [
		"pode prosseguir",
		"próxima sala",
		"prosseguir para",
		"ir para a próxima",
		"seguir para",
		"avançar para"
	]
	
	var has_success = false
	var has_progress = false
	
	for keyword in success_keywords:
		if keyword in response_lower:
			has_success = true
			break
	
	for phrase in progress_phrases:
		if phrase in response_lower:
			has_progress = true
			break
	
	# Only validate as correct if BOTH success and progress indicators are present
	return has_success and has_progress

func validate_direct_answer(user_answer: String, npc) -> bool:
	if not npc:
		return false
	
	var answer_lower = user_answer.to_lower().strip_edges()
	
	# Define correct answers for each NPC based on their subjects and questions
	match npc.subject:
		"Geografia":
			# Question: "Qual é a maior região do país?"
			var correct_geography = ["norte", "região norte", "regiao norte", "amazônia", "amazonia"]
			for correct in correct_geography:
				if correct in answer_lower:
					return true
		
		"Biologia":
			# Question: "Quais são os cinco reinos dos seres vivos?"
			var correct_biology = ["monera", "protista", "fungi", "plantae", "animalia", "5 reinos", "cinco reinos"]
			var found_kingdoms = 0
			for kingdom in correct_biology:
				if kingdom in answer_lower:
					found_kingdoms += 1
			return found_kingdoms >= 3 # At least 3 kingdoms mentioned
		
		"Ciências":
			# Question: "Quantos planetas existem no nosso sistema solar?"
			var correct_science = ["8", "oito", "8 planetas", "oito planetas"]
			for correct in correct_science:
				if correct in answer_lower:
					return true
		
		"Revisão Geral":
			# Question: "O Brasil faz fronteira com todos os países da América do Sul, exceto..."
			var correct_review = ["chile", "equador", "chile e equador", "equador e chile"]
			for correct in correct_review:
				if correct in answer_lower:
					return true
	
	return false

func unlock_room_by_npc_name(npc_name: String):
	print("🚪 === UNLOCK ROOM BY NPC ===")
	print("🚪 NPC Name: ", npc_name)
	
	# Usar o novo sistema de portas
	unlock_doors_for_npc(npc_name)
	
	# Manter compatibilidade com sistema antigo
	var cached_data = cached_npc_data.get(npc_name, {})
	var unlocks_room = cached_data.get("unlocks_room", "")
	
	if unlocks_room != "" and dungeon_level:
		dungeon_level.unlock_room(unlocks_room)
		print("🚪 Sala desbloqueada: ", unlocks_room, " por NPC: ", npc_name)

# === NOVO SISTEMA DE PORTAS ===

func register_door(door_node):
	print("🚪 === REGISTER DOOR CALLED ===")
	print("🚪 Door node recebido: ", door_node)
	print("🚪 Door node válido: ", door_node != null)
	
	if door_node:
		print("🚪 Door node tem método get_door_info: ", door_node.has_method("get_door_info"))
		if door_node.has_method("get_door_info"):
			var info = door_node.get_door_info()
			var door_name = info["name"]
			registered_doors[door_name] = door_node
			print("🚪 ✅ Porta registrada: ", door_name, " (desbloqueia quando: ", info["unlocks_when"], ")")
			print("🚪 Total de portas agora: ", registered_doors.size())
			return true
		else:
			print("🚪 ❌ Door node não tem método get_door_info")
	else:
		print("🚪 ❌ Door node é null")
	return false

func unlock_doors_for_npc(npc_name: String):
	# Desbloquear portas quando NPC completa quiz
	print("🚪 === UNLOCK DOORS FOR NPC ===")
	print("🚪 NPC Name: ", npc_name)
	print("🚪 Total de portas registradas: ", registered_doors.size())
	print("🚪 Portas registradas: ", registered_doors.keys())
	
	var doors_unlocked = 0
	for door_name in registered_doors:
		var door = registered_doors[door_name]
		if door and door.has_method("get_door_info"):
			var info = door.get_door_info()
			print("🚪 Verificando porta: ", door_name, " - Desbloqueia quando: ", info["unlocks_when"])
			if info["unlocks_when"] == npc_name:
				print("🚪 ✅ MATCH! Desbloqueando porta: ", door_name)
				door.unlock_door()
				doors_unlocked += 1
			else:
				print("🚪 ❌ Não é para este NPC")
		else:
			print("🚪 ❌ Porta inválida: ", door_name)
	
	print("🚪 Total de portas desbloqueadas: ", doors_unlocked)
	print("🚪 === FIM UNLOCK DOORS ===\n")

func get_door_status():
	# Mostrar status de todas as portas
	print("\n🚪 === STATUS DAS PORTAS ===")
	print("🚪 Total de portas registradas: ", registered_doors.size())
	
	for door_name in registered_doors:
		var door = registered_doors[door_name]
		if door and door.has_method("get_door_info"):
			var info = door.get_door_info()
			var status = "🔓 ABERTA" if info["is_open"] else "🔒 FECHADA"
			print("🚪 ", door_name, " - ", status, " (desbloqueia quando: ", info["unlocks_when"], ")")
	
	print("🚪 === FIM STATUS ===\n")

func test_unlock_ciencias_door():
	# Função de teste para desbloquear porta de ciências
	print("🧪 === TESTE FORÇADO DE DESBLOQUEIO ===")
	print("🧪 Testando desbloqueio da porta de ciências...")
	
	# Primeiro, mostrar status atual
	get_door_status()
	
	# Tentar desbloqueio direto
	unlock_doors_for_npc("Profa. Maria")
	
	# Tentar desbloqueio direto por nome da porta
	if "ciencias_door" in registered_doors:
		var door = registered_doors["ciencias_door"]
		if door and door.has_method("unlock_door"):
			print("🧪 Desbloqueio direto da porta ciencias_door...")
			door.unlock_door()
		else:
			print("🧪 ❌ Porta ciencias_door não tem método unlock_door")
	else:
		print("🧪 ❌ Porta ciencias_door não encontrada nas portas registradas")
	
	# Mostrar status final
	print("🧪 Status final:")
	get_door_status()

func force_register_all_doors():
	print("🔧 === FORÇANDO REGISTRO DE TODAS AS PORTAS ===")
	
	# Procurar todas as portas na cena
	var all_doors = get_tree().get_nodes_in_group("doors")
	print("🔧 Portas encontradas no grupo 'doors': ", all_doors.size())
	
	# Procurar por StaticBody3D com script NewDoor
	var door_count = 0
	
	for node in get_tree().get_nodes_in_group(""):
		if node is StaticBody3D and node.has_method("get_door_info"):
			print("🔧 Encontrada porta: ", node.name)
			register_door(node)
			door_count += 1
	
	print("🔧 Total de portas registradas: ", door_count)
	get_door_status()

func unlock_room(room_id: String):
	if dungeon_level:
		dungeon_level.unlock_room(room_id)

func _on_question_timeout():
	# Only timeout if we're still awaiting a question generation
	if awaiting_question and current_timeout_timer:
		print("⏰ TIMEOUT: OpenAI não respondeu em 20 segundos")
		awaiting_question = false
		current_timeout_timer = null
		
		# Check if we can retry (not at max attempts)
		var current_attempts = npc_attempt_counts.get(current_npc_name, 0)
		if current_attempts < 3:
			chat_history.text += "\n[color=orange][b]⏰ OpenAI está lento. Tentando novamente...[/b][/color]"
			await get_tree().create_timer(0.3).timeout # Faster retry
			if current_npc_name != "":
				generate_question_for_npc(null)
		else:
			chat_history.text += "\n[color=orange][b]⏰ Timeout:[/b] OpenAI demorou muito. Feche o chat e tente outro professor.[/color]"
	else:
		print("⏰ Timer expirado mas não aplicável - ignorando")

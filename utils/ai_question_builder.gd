extends Node
class_name AIQuestionBuilder

signal quiz_ready(quiz_item: Dictionary)
signal generation_failed(reason: String)

# JSON Schema para validação da resposta
const QUESTION_SCHEMA = {
	"type": "object",
	"properties": {
		"subject": {
			"type": "string",
			"description": "A matéria/disciplina da pergunta"
		},
		"question": {
			"type": "string",
			"description": "O texto da pergunta"
		},
		"options": {
			"type": "object",
			"properties": {
				"A": {"type": "string"},
				"B": {"type": "string"},
				"C": {"type": "string"},
				"D": {"type": "string"}
			},
			"required": ["A", "B", "C", "D"],
			"additionalProperties": false
		},
		"correct": {
			"type": "string",
			"enum": ["A", "B", "C", "D"],
			"description": "A letra da alternativa correta"
		},
		"rationale": {
			"type": "string",
			"description": "Explicação do por que a resposta está correta"
		},
		"topic_hint": {
			"type": "string",
			"description": "Dica sobre o tópico abordado"
		}
	},
	"required": ["subject", "question", "options", "correct", "rationale", "topic_hint"],
	"additionalProperties": false
}

# System prompt para a OpenAI
const SYSTEM_PROMPT = """Você é um assistente especializado em criar questões educacionais de múltipla escolha para estudantes do 6º ano do ensino fundamental brasileiro, seguindo rigorosamente a Base Nacional Comum Curricular (BNCC).

DIRETRIZES FUNDAMENTAIS:
- Crie questões apropriadas para a faixa etária (11-12 anos)
- Use linguagem clara, direta e acessível
- Baseie-se exclusivamente no currículo da BNCC para 6º ano
- Garanta que todas as alternativas sejam plausíveis
- A resposta correta deve ser inequívoca
- Evite pegadinhas ou armadilhas desnecessárias

ESTRUTURA OBRIGATÓRIA:
- Uma pergunta clara e objetiva
- Quatro alternativas distintas (A, B, C, D)
- Apenas uma alternativa correta
- Explicação (rationale) educativa
- Dica do tópico abordado

REGRAS ESPECIAIS:
- Se usar "Todas as anteriores" ou "Todas as alternativas", SEMPRE coloque como alternativa D
- Certifique-se de que as alternativas incorretas sejam educativas (não absurdas)
- Varie os tipos de questão: conceitual, aplicação, interpretação
- Inclua contextos do cotidiano quando apropriado

VALIDAÇÃO:
- Todas as alternativas devem ser únicas
- A resposta correta deve estar claramente identificada
- O conteúdo deve ser adequado ao nível de escolaridade
- A explicação deve ser pedagógica e construtiva

Regras obrigatórias de qualidade e correção (aplicável a TODAS as disciplinas):

- Clareza: as frases devem ser simples, diretas, sem palavras desnecessárias.
- Ortografia e gramática: o texto deve estar 100% correto em português do Brasil (sem erros de acentuação, concordância ou pontuação).
- Coerência: todas as alternativas precisam estar logicamente ligadas à pergunta.
- Veracidade: use apenas informações factuais corretas e compatíveis com o nível de 6º ano da BNCC.
- Estilo: evite frases muito longas, termos técnicos avançados ou linguagem de adultos.
- Formatação: nunca saia do formato solicitado (JSON válido / opções A–D / uma resposta correta).
- SEMPRE produza uma pergunta de múltipla escolha com **apenas UMA resposta correta objetiva e verificável**. 
- NUNCA crie perguntas de opinião, frases abertas ou interpretativas sem resposta clara.
- As alternativas erradas (distratores) devem parecer plausíveis, mas serem claramente incorretas.
- Evite perguntas vagas ou subjetivas (ex.: “Qual frase é mais bonita sobre amizade?”).
- Verifique se a questão tem gabarito óbvio para um professor de 6º ano e que qualquer aluno, ao estudar, consiga identificar a resposta correta.
"""

# User prompt template
const USER_PROMPT_TEMPLATE = """Crie uma questão de múltipla escolha para:

CONTEXTO:
- Professor(a): {npc_name}
- Matéria: {npc_subject}
- Tentativa: {attempt_count}

DIRETRIZES DE VARIEDADE:
{topic_variety_prompt}

REQUISITOS ESPECÍFICOS:
- Questão baseada na BNCC 6º ano para {npc_subject}
- Nível apropriado para estudantes de 11-12 anos
- Alternativas plausíveis e educativas
- Explicação clara e pedagógica

FORMATO DE RESPOSTA:
Retorne APENAS um objeto JSON válido seguindo exatamente esta estrutura:
{{
  "subject": "{npc_subject}",
  "question": "Sua pergunta aqui",
  "options": {{
    "A": "Primeira alternativa",
    "B": "Segunda alternativa", 
    "C": "Terceira alternativa",
    "D": "Quarta alternativa"
  }},
  "correct": "A",
  "rationale": "Explicação do por que a resposta A está correta",
  "topic_hint": "Dica sobre o tópico abordado"
}}

IMPORTANTE: Responda APENAS com o JSON, sem texto adicional."""

var http_request: HTTPRequest
var current_payload: Dictionary
var regeneration_count: int = 0
var max_regenerations: int = 2

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)

func build_system_prompt() -> String:
	return SYSTEM_PROMPT

func build_user_prompt(npc_name: String, npc_subject: String, topic_variety_prompt: String, attempt_count: int) -> String:
	return USER_PROMPT_TEMPLATE.format({
		"npc_name": npc_name,
		"npc_subject": npc_subject,
		"topic_variety_prompt": topic_variety_prompt,
		"attempt_count": attempt_count
	})

func build_payload(npc_name: String, npc_subject: String, topic_variety_prompt: String, attempt_count: int) -> Dictionary:
	var system_prompt = build_system_prompt()
	var user_prompt = build_user_prompt(npc_name, npc_subject, topic_variety_prompt, attempt_count)
	
	return {
		"model": "gpt-4o-mini",
		"messages": [
			{
				"role": "system",
				"content": system_prompt
			},
			{
				"role": "user",
				"content": user_prompt
			}
		],
		"response_format": {
			"type": "json_schema",
			"json_schema": {
				"name": "quiz_question",
				"schema": QUESTION_SCHEMA
			}
		},
		"temperature": 0.2,
		"presence_penalty": 0,
		"frequency_penalty": 0,
		"max_tokens": 800
	}

func validate_quiz_item(item: Dictionary) -> Dictionary:
	var validation_result = {
		"valid": false,
		"errors": []
	}
	
	# Verificar chaves obrigatórias
	var required_keys = ["subject", "question", "options", "correct", "rationale", "topic_hint"]
	for key in required_keys:
		if not item.has(key):
			validation_result.errors.append("Campo obrigatório ausente: " + key)
	
	if validation_result.errors.size() > 0:
		return validation_result
	
	# Validar pergunta não vazia
	if item.question.strip_edges() == "":
		validation_result.errors.append("Pergunta não pode estar vazia")
	
	# Validar opções
	if not item.options is Dictionary:
		validation_result.errors.append("Opções devem ser um dicionário")
		return validation_result
	
	var option_keys = ["A", "B", "C", "D"]
	for option_key in option_keys:
		if not item.options.has(option_key):
			validation_result.errors.append("Opção ausente: " + option_key)
		elif item.options[option_key].strip_edges() == "":
			validation_result.errors.append("Opção vazia: " + option_key)
	
	if validation_result.errors.size() > 0:
		return validation_result
	
	# Verificar se todas as opções são distintas
	var options_array = [item.options.A, item.options.B, item.options.C, item.options.D]
	var unique_options = {}
	for option in options_array:
		var normalized = option.strip_edges().to_lower()
		if unique_options.has(normalized):
			validation_result.errors.append("Opções duplicadas encontradas")
			break
		unique_options[normalized] = true
	
	# Validar resposta correta
	if not item.correct in ["A", "B", "C", "D"]:
		validation_result.errors.append("Resposta correta deve ser A, B, C ou D")
	
	# Regra especial: "Todas as anteriores" deve ser D
	for option_key in option_keys:
		var option_text = item.options[option_key].to_lower()
		if "todas as anteriores" in option_text or "todas as alternativas" in option_text or "todas estão corretas" in option_text:
			if option_key != "D":
				validation_result.errors.append("Opção 'Todas as anteriores' deve estar na alternativa D")
			break
	
	# Validar explicação não vazia
	if item.rationale.strip_edges() == "":
		validation_result.errors.append("Explicação (rationale) não pode estar vazia")
	
	# Validar dica não vazia
	if item.topic_hint.strip_edges() == "":
		validation_result.errors.append("Dica do tópico não pode estar vazia")
	
	validation_result.valid = validation_result.errors.size() == 0
	return validation_result

func request_question(npc_name: String, npc_subject: String, topic_variety_prompt: String, attempt_count: int, supabase_proxy_url: String, anon_key: String):
	regeneration_count = 0
	current_payload = build_payload(npc_name, npc_subject, topic_variety_prompt, attempt_count)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + anon_key
	]
	
	var body = JSON.stringify({
		"prompt": current_payload.messages[1].content,
		"subject": npc_subject,
		"quiz_mode": "multipla_escolha",
		"openai_payload": current_payload
	})
	
	print("🤖 Enviando requisição para geração de pergunta...")
	print("🎯 Professor: ", npc_name)
	print("🎯 Matéria: ", npc_subject)
	
	http_request.timeout = 45.0
	var result = http_request.request(supabase_proxy_url, headers, HTTPClient.METHOD_POST, body)
	
	if result != OK:
		print("❌ Falha ao enviar requisição: ", result)
		generation_failed.emit("Falha na conexão com o servidor")

func _on_http_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	print("📨 Resposta recebida - Código: ", response_code)
	
	if response_code != 200:
		print("❌ Erro HTTP: ", response_code)
		_regenerate_with_feedback("Erro HTTP: " + str(response_code))
		return
	
	if body.size() == 0:
		print("❌ Resposta vazia")
		_regenerate_with_feedback("Resposta vazia do servidor")
		return
	
	var response_text = body.get_string_from_utf8()
	print("📨 Resposta bruta: ", response_text.substr(0, 200), "...")
	
	# Parse da resposta do Supabase proxy
	var proxy_response = JSON.parse_string(response_text)
	if not proxy_response or not proxy_response is Dictionary:
		print("❌ Resposta do proxy inválida")
		_regenerate_with_feedback("Resposta do proxy inválida")
		return
	
	var ai_response = proxy_response.get("response", "")
	if ai_response == "":
		print("❌ Resposta da IA vazia")
		_regenerate_with_feedback("Resposta da IA vazia")
		return
	
	# Parse da resposta da IA como JSON
	var quiz_item = JSON.parse_string(ai_response)
	if not quiz_item or not quiz_item is Dictionary:
		print("❌ JSON da IA inválido")
		_regenerate_with_feedback("JSON da IA inválido")
		return
	
	# Validar o item do quiz
	var validation = validate_quiz_item(quiz_item)
	if not validation.valid:
		print("❌ Validação falhou: ", validation.errors)
		_regenerate_with_feedback("Validação falhou: " + str(validation.errors))
		return
	
	print("✅ Pergunta gerada e validada com sucesso!")
	print("🎯 Pergunta: ", quiz_item.question)
	print("🎯 Resposta correta: ", quiz_item.correct)
	
	quiz_ready.emit(quiz_item)

func _regenerate_with_feedback(reason: String):
	regeneration_count += 1
	
	if regeneration_count >= max_regenerations:
		print("❌ Máximo de tentativas de regeneração atingido")
		generation_failed.emit("Não foi possível gerar a questão após " + str(max_regenerations) + " tentativas. Motivo: " + reason)
		return
	
	print("🔄 Tentativa de regeneração ", regeneration_count + 1, "/", max_regenerations)
	print("🔄 Motivo: ", reason)
	
	# Modificar ligeiramente o payload para tentar novamente
	if current_payload.has("messages") and current_payload.messages.size() > 1:
		current_payload.messages[1].content += "\n\nIMPORTANTE: A tentativa anterior falhou (" + reason + "). Por favor, gere uma questão válida seguindo exatamente o formato JSON especificado."
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + SupabaseConfig.ANON_KEY
	]
	
	var body = JSON.stringify({
		"prompt": current_payload.messages[1].content,
		"subject": current_payload.get("subject", ""),
		"quiz_mode": "multipla_escolha",
		"openai_payload": current_payload
	})
	
	var result = http_request.request(SupabaseConfig.OPENAI_PROXY_URL, headers, HTTPClient.METHOD_POST, body)
	
	if result != OK:
		generation_failed.emit("Falha na reconexão: " + str(result))

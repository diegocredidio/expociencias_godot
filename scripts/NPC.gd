extends StaticBody3D

@export var npc_name: String = "Professor Silva"
@export var subject: String = "Geografia"
@export var greeting_message: String = "Olá! Sou o Professor Silva. Vamos aprender sobre geografia do Brasil!"
@export var room_id: String = "room_1"
@export var unlocks_room: String = "room_2"
@export_enum("pergunta_aberta", "pergunta_multipla_escolha") var quiz_mode: String = "pergunta_aberta"

@onready var label = $Label3D
@onready var chat_indicator = $ChatIndicator

var question_answered = false

func _ready():
	label.text = npc_name
	add_to_group("npcs")

func get_npc_data():
	return {
		"name": npc_name,
		"subject": subject,
		"greeting": greeting_message,
		"room_id": room_id,
		"unlocks": unlocks_room,
		"quiz_mode": quiz_mode
	}

func show_chat_indicator():
	if chat_indicator:
		chat_indicator.visible = true

func hide_chat_indicator():
	if chat_indicator:
		chat_indicator.visible = false

func question_answered_correctly():
	question_answered = true
	label.text = npc_name + " ✓"
	
	var main = get_node("/root/Main")
	if main:
		main.unlock_room(unlocks_room)
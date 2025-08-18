class_name Context
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/outgoing_message.gd"

var _message: String
var _silent: bool

func _init(message: String, silent: bool = false):
	_message = message
	_silent = silent

func _get_command() -> String:
	return "context"

func _get_data() -> Dictionary:
	return {
		"message": _message,
		"silent": _silent
	}

static func send(message: String, silent: bool = false):
	var websocket_node = ModLoader.get_tree().root.get_node_or_null("/root/ModLoader/@@2/WebsocketNode")
	if websocket_node != null:
		var ws_message = load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/context.gd").new(message, silent)
		websocket_node.send(ws_message)
	else:
		print("WebSocket node not found at /root/ModLoader/Adesi-NeuroIntegration/WebsocketNode")

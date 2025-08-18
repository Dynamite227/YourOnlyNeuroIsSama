class_name OutgoingMessage


func _get_command() -> String:
	push_error("OutgoingMessage._get_command() is not implemented.")
	return "invalid"


func _get_data() -> Dictionary:
	return {}


func merge(_other) -> bool: # OutgoingMessage
	return false


func get_ws_message(): # -> WsMessage
	return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/ws_message.gd").new(_get_command(), _get_data(), "Your Only Move Is Hustle")

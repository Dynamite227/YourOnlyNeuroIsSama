class_name ActionsReregisterAll
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/incoming_message.gd"

func _can_handle(command: String) -> bool:
	return command == "actions/reregister_all"

func _validate(_command: String, _data, _state: Dictionary): # -> ExecutionResult
	return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").success()

func _report_result(_state: Dictionary, _result) -> void: # : ExecutionResult
	pass

func _execute(_state: Dictionary) -> void:
	get_tree().root.get_node("/root/ModLoader/Adesi-NeuroIntegration/NeuroActionHandlerNode").resend_registered_actions()

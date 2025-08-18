extends Node
class_name IncomingMessage

func can_handle(command: String) -> bool:
	return _can_handle(command)

func validate(command: String, message_data, state: Dictionary): # -> ExecutionResult
	var result = _validate(command, message_data, state)
	if result == null:
		push_error("IncomingMessage._validate() returned null. An error probably occurred.")
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").mod_failure("Action failed. An error occurred.")

	return result

func report_result(state: Dictionary, result) -> void: # : ExecutionResult
	_report_result(state, result)

func execute(state: Dictionary) -> void:
	_execute(state)

func _can_handle(_command: String) -> bool:
	push_error("IncomingMessage._can_handle() is not implemented.")
	return false

func _validate(_command: String, _data, _state: Dictionary): # -> ExecutionResult
	push_error("IncomingMessage._validate() is not implemented.")
	return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").mod_failure("IncomingMessage.validate() is not implemented.")

func _report_result(_state: Dictionary, _result) -> void: # : ExecutionResult
	push_error("IncomingMessage._report_result() is not implemented.")

func _execute(_state: Dictionary) -> void:
	push_error("IncomingMessage._execute() is not implemented.")

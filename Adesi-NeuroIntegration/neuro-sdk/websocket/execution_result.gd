class_name ExecutionResult

var successful: bool
var message: String

func _init(success_: bool, message_) -> void:
	if message_ == null:
		message_ = ""

	successful = success_
	message = message_

static func success(message_ = null):
	return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").new(true, message_)

static func failure(message_: String):
	return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").new(false, message_)

static func vedal_failure(message_: String):
	return failure(message_ + " (This is probably not your fault, blame Vedal.)")

static func mod_failure(message_: String):
	return failure(message_ + " (This is probably not your fault, blame the game integration.)")

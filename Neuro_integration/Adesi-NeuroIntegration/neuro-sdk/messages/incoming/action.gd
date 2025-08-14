extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/incoming_message.gd"
class_name Action


const WEBSOCKET_NODE_PATH := "//root/ModLoader/@@2/WebsocketNode" # Path to the Websocket node in your scene
const ACTIONHANDLER_NODE_PATH := "//root/ModLoader/@@2/NeuroActionHandlerNode" # Path to the ActionHandler node in your scene

func _can_handle(command: String) -> bool:
	return command == "action"

func _validate(_command: String, message_data, state: Dictionary): # -> ExecutionResult
	if message_data == null:
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").vedal_failure("Action failed. Missing command data.")

	var action_id = message_data.get_string("id");
	if not action_id:
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").vedal_failure("Action failed. Missing command field 'id'.")

	state["_action_id"] = action_id;

	var action_name = message_data.get_string("name")
	var action_stringified_data = message_data.get_string("data", "{}")

	if action_name == null or action_name == "":
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").vedal_failure("Action failed. Missing command field 'name'.")

	var action = get_tree().root.get_node(ACTIONHANDLER_NODE_PATH).get_action(action_name)
	if action == null:
		if get_tree().root.get_node(ACTIONHANDLER_NODE_PATH).is_recently_unregistered(action_name):
			return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").failure("This action has been recently unregistered and can no longer be used.")
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").failure("Action failed. Unknown action '%s'." % action_name)

	state["_action_instance"] = action;

	var json = JSON.parse(action_stringified_data)
	var error = json.error
	if error != OK:
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").failure("Action failed. Could not parse action parameters from JSON.")

	if typeof(json.result) != TYPE_DICTIONARY:
		push_error("Action data can only be a dictionary. Other respones are not permitted for the API implementation in Godot.")
		return load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/execution_result.gd").failure("Action failed. Could not parse action parameters from JSON.")

	var action_data = load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/incoming_data.gd").new(json.result)

	var result = action.validate(action_data, state)
	return result

func _report_result(state: Dictionary, result) -> void:
	var id = state.get("_action_id", null);
	if id == null:
		push_error("Action.report_result received no action id. It probably could not be parsed in the action. Received result: %s" % [result.message])
		return

	get_tree().root.get_node(WEBSOCKET_NODE_PATH).send(load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/action_result.gd").new(id, result))

func _execute(state: Dictionary) -> void:
	var action = state["_action_instance"]
	action.execute(state)

class_name ActionsUnregister
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/outgoing_message.gd"

var _names: Array # [String]

func _init(actions: Array): # [WsAction]
	#_names.assign(actions.map(func(action: WsAction) -> String: return action.name))
	_names.clear()
	for action in actions:
		_names.push_back(action.name)

func _get_command() -> String:
	return "actions/unregister"

func _get_data() -> Dictionary:
	return {
		"action_names": _names
	}

func merge(other) -> bool:
	if not other is get_script():
		return false

	#_names = _names.filter(func(my_name: String) -> bool: return !other._names.has(my_name))
	var temp_arr = Array()
	for name in _names:
		if !other._names.has(name):
			temp_arr.push_back(name)
	_names = temp_arr
	_names.append_array(other._names)
	return true

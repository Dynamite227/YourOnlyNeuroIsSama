class_name ActionsRegister
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/api/outgoing_message.gd"

var _actions: Array # [WsAction]

func _init(actions: Array): # [WsAction]
	_actions = actions

func _get_command() -> String:
	return "actions/register"

func _get_data() -> Dictionary:
	var arr = Array()
	for action in _actions:
		arr.push_back(action.to_dict())
	return {
		"actions": arr
	}

func merge(other) -> bool:
	if not other is get_script():
		return false

	#_actions = _actions.filter(func(my_action: WsAction) -> bool: return !other._actions.any(func(their_action: WsAction) -> bool: return my_action.name == their_action.name))
	var temp_arr = Array()
	for my_action in _actions:
		for other_action in other._actions:
			if my_action.name != other_action.name:
				temp_arr.push_back(my_action)
	_actions = temp_arr
	
	_actions.append_array(other._actions)
	return true

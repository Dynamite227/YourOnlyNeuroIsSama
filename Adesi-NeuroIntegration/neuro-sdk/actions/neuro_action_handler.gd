#class_name NeuroActionHandler
extends Node

var _registered_actions: Array = [] # [NeuroAction]
var _dying_actions: Array = [] # [NeuroAction]

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		var array: Array = [] # [WsAction]
		#array.assign(_registered_actions.map(func(x): return action.get_ws_action()))
		for action in _registered_actions:
			array.append(action.get_ws_action())
		get_tree().root.get_node("/root/ModLoader/@@2/WebsocketNode").send_immediate(load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/actions_unregister.gd").new(array))

func get_action(action_name: String):
	var actions: Array = Array() # = _registered_actions.filter(func(action: NeuroAction) -> bool: return action.get_name() == action_name)
	for action in _registered_actions:
		if action.get_name() == action_name:
			actions.append(action)
	if actions.size() == 0:
		return null

	return actions[0]

func is_recently_unregistered(action_name: String) -> bool:
	#return _dying_actions.any(func(action: NeuroAction) -> bool: return action.get_name() == action_name)
	#var arr: Array
	for action in _dying_actions:
		if action.get_name() == action_name:
			#arr.append(action)
			return true
	return false

func register_actions(actions: Array): # [NeuroAction]
	#_registered_actions = _registered_actions.filter(func(old_action: NeuroAction) -> bool: return not actions.any(func(new_action: NeuroAction) -> bool: return old_action.get_name() == new_action.get_name()))
	var temp_arr := Array()
	for old_action in _registered_actions: # TODO: figure out if this is correct
		for new_action in actions:
			if old_action.get_name() == new_action.get_name():
				temp_arr.append(old_action)
				break
			else:
				temp_arr.append(old_action)
				break
	_registered_actions = temp_arr
	
	#_dying_actions = _dying_actions.filter(func(old_action: NeuroAction) -> bool: return not actions.any(func(new_action: NeuroAction) -> bool: return old_action.get_name() == new_action.get_name()))
	temp_arr = Array()
	for old_action in _dying_actions: # TODO: figure out if this is correct
		for new_action in actions:
			if old_action.get_name() == new_action.get_name():
				temp_arr.append(old_action)
				break
			else:
				temp_arr.append(old_action)
				break
	_dying_actions = temp_arr
	
	_registered_actions.append_array(actions)

	var array: Array = [] # [WsAction]
	#array.assign(actions.map(func(action: NeuroAction) -> WsAction: return action.get_ws_action()))
	for action in actions:
		array.append(action.get_ws_action())
	get_tree().root.get_node("/root/ModLoader/@@2/WebsocketNode").send(load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/actions_register.gd").new(array))

func unregister_actions(actions: Array): # [NeuroAction]
	var actions_to_remove: Array = Array() # [NeuroAction] = _registered_actions.filter(func(old_action: NeuroAction) -> bool: return actions.any(func(new_action: NeuroAction) -> bool: return old_action.get_name() == new_action.get_name()))
	for old_action in _registered_actions:
		for new_action in actions:
			if old_action.get_name() == new_action.get_name():
				actions_to_remove.append(old_action)
				break
				
	#_registered_actions = _registered_actions.filter(func(old_action: NeuroAction) -> bool: return not actions_to_remove.has(old_action))
	var temparr = Array()
	for action in _registered_actions:
		if not actions_to_remove.has(action):
			temparr.append(action)
	_registered_actions = temparr
	_dying_actions.append_array(actions_to_remove)

	var array: Array = [] # [WsAction]
	#array.assign(actions_to_remove.map(func(action: NeuroAction) -> WsAction: return action.get_ws_action()))
	for action in actions_to_remove:
		array.append(action.get_ws_action())
	get_tree().root.get_node("/root/ModLoader/@@2/WebsocketNode").send(load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/actions_unregister.gd").new(array))

	yield (get_tree().create_timer(10), "timeout")
	#_dying_actions = _dying_actions.filter(func(action: NeuroAction) -> bool: return actions_to_remove.has(action))
	temparr = Array()
	for action in _dying_actions:
		if actions_to_remove.has(action):
			temparr.append(action)
	_dying_actions = temparr

func resend_registered_actions():
	var array: Array = [] # [WsAction]
	#array.assign(_registered_actions.map(func(action: NeuroAction) -> WsAction: return action.get_ws_action()))
	for action in _registered_actions:
		array.append(action.get_ws_action())

	if array.size() > 0:
		get_tree().root.get_node("/root/ModLoader/@@2/WebsocketNode").send(load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/actions_register.gd").new(array))


static func get_instance():
	return Engine.get_main_loop().root.get_node("NeuroActionHandlerNode")

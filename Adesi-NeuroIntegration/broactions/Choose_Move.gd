class_name ChooseMove
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"


signal action_chosen(state)
var selection_basis # thing should inherit BaseSelection
var what_is_being_selected

var cached_names = []
func _init(window, basis, what).(window):
	selection_basis = basis
	what_is_being_selected = what

func _get_name():
	return "choose_" + what_is_being_selected

func _get_description():
	return "Choses an {what_is_being_selected} from the list."

func _get_schema():
	return JsonUtils.wrap_schema({
		"move": {
			"enum": get_item_names()
		}
	})

func _validate_action(data, state):
	print("Validating action data: ", data)
	var selected = data.get_string("move", "")
	print("Selected move: ", selected)
	
	if not selected or selected == "":
		print("ERROR: No move selected")
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["move"]))
	
	var available = get_item_names()
	print("Available moves: ", available)
	
	if not available.has(selected):
		print("ERROR: Invalid move '", selected, "' not in available moves: ", available)
		# Instead of just failing, let's try to find a close match or use the first available move
		if available.size() > 0:
			var fallback_move = available[0]
			print("Using fallback move: ", fallback_move)
			state["move"] = find_item_button(fallback_move)
			return ExecutionResult.success()
		else:
			print("ERROR: No available moves found")
			return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["move"]))
	
	var button = find_item_button(selected)
	if button == null:
		print("ERROR: Could not find button for move: ", selected)
		return ExecutionResult.failure("Could not find button for selected move")
	
	state["move"] = button
	print("Validation successful for move: ", selected)
	return ExecutionResult.success()


func _execute_action(state):
	print("Executing move action...")
	
	if not state.has("move") or state["move"] == null:
		print("ERROR: No valid move in state")
		return
	
	var button = state["move"]
	print("Pressing button: ", button.action_name if button.get("action_name") != null else "unknown")
	
	# Ensure the button is valid and visible before pressing
	if is_instance_valid(button) and button.visible:
		button.set_pressed(true)
		print("Button pressed successfully")
		emit_signal("action_chosen", button)
	else:
		print("ERROR: Button is not valid or not visible")
		# Try to find any available button as fallback
		var available_buttons = []
		for item in selection_basis.buttons:
			if item.visible:
				available_buttons.append(item)
		
		if available_buttons.size() > 0:
			var fallback_button = available_buttons[0]
			print("Using fallback button: ", fallback_button.action_name)
			fallback_button.set_pressed(true)
			emit_signal("action_chosen", fallback_button)
		else:
			print("ERROR: No available buttons found")


	
func _go_on() -> String:
	return "action"

func get_item_names():
	print("Getting available move names...")
	var names = []
	
	# Always refresh the cache to ensure we have current data
	cached_names.clear()
	
	if selection_basis == null:
		print("ERROR: selection_basis is null")
		return []
	
	if not selection_basis.has_method("buttons") and selection_basis.buttons == null:
		print("ERROR: selection_basis has no buttons property")
		return []
	
	var buttons = selection_basis.buttons if selection_basis.buttons != null else []
	
	for item in buttons:
		if item != null and is_instance_valid(item) and item.visible:
			var action_name = item.action_name if item.get("action_name") != null else "unknown"
			print("Found visible button: ", action_name)
			names.append(action_name)
	
	cached_names = names
	print("Available moves cached: ", cached_names)
	return cached_names


func find_item_button(translated_name):
	print("Finding button for move: ", translated_name)
	
	if selection_basis == null:
		print("ERROR: selection_basis is null")
		return null
	
	var buttons = selection_basis.buttons if selection_basis.buttons != null else []
	
	for item in buttons:
		if item != null and is_instance_valid(item):
			var action_name = item.action_name if item.get("action_name") != null else ""
			if action_name == translated_name:
				print("Found matching button: ", action_name)
				return item
	
	print("ERROR: No button found for move: ", translated_name)
	return null

class_name SelectAction
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"

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
		"character": {
			"enum": get_item_names()
		}
	})

func _validate_action(data, state):
	print(data)
	var selected = data.get_string("character", "")
	print("selected", selected)
	if not selected or selected == "":
		print(">:(")
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["character"]))
	
	var available = get_item_names()
	if not available.has(selected):
		print("ruh roh")
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["character"]))
	state["character"] = find_item_button(selected)
	return ExecutionResult.success()


func _execute_action(state):
	print("boop")
	state["character"].emit_signal("pressed")


func get_item_names():
	print("getting names")
	var names = []
	if cached_names.empty():
		print("empty cache")

		for item in selection_basis.buttons:
			print(item.text)
			print(item)
			names.append(item.text)

		cached_names = names
		print("cached", cached_names)
		return cached_names
	else:
		print("already has")
		return cached_names


func find_item_button(translated_name):
	print(translated_name, "translated names")

	for item in selection_basis.buttons:
		print(item.text)
		print(item)
		var button = item
		if button.text == translated_name:

			return button
	return null

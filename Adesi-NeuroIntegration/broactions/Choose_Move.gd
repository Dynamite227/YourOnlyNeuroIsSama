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
	print(data)
	var selected = data.get_string("move", "")
	print("selected", selected)
	if not selected or selected == "":
		print(">:(")
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["move"]))
	
	var available = get_item_names()
	if not available.has(selected):
		print("ruh roh")
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["move"]))
	state["move"] = find_item_button(selected)
	return ExecutionResult.success()


func _execute_action(state):
	print("boop")
	state["move"].set_pressed(true)
	

	
	emit_signal("action_chosen", state["move"])


	
func _go_on() -> String:
	return "action"

func get_item_names():
	print("getting names")
	var names = []
	if cached_names.empty():
		print("empty cache")

		for item in selection_basis.buttons:

			names.append(item.action_name)

		cached_names = names
		print("cached", cached_names)
		return cached_names
	else:
		print("already has")
		return cached_names


func find_item_button(translated_name):
	print(translated_name, "translated names")

	for item in selection_basis.buttons:

		var button = item
		if button.action_name == translated_name:

			return button
	return null

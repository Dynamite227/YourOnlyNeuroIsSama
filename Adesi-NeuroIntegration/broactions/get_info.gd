class_name GetInfoAction
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"

var selection_basis # thing should inherit BaseSelection
var what_is_being_selected
var cached_names = []

var regexr = RegEx.new()
func _init(window, basis, what).(window):
	selection_basis = basis
	what_is_being_selected = what


func _get_name():
	return what_is_being_selected + "_info"

func _get_description():
	return "Get information about an {what_is_being_selected}. before choosing it. This action is useful for previewing the item before making a decision. it can be used any amount of times"

func _get_schema():
	return JsonUtils.wrap_schema({
		"character": {
			"enum": get_item_names()
		}
	})

func _validate_action(data, state):
	var selected = data.get_string("character", "")
	if not selected or selected == "":
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["character"]))
	
	var available = get_item_names()
	if not available.has(selected):
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["character"]))
	
	# Find and store the actual item button
	var item_button = find_item_button(selected)
	if item_button == null:
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["character"]))
	
	state["character"] = item_button
	return ExecutionResult.success()


func _execute_action(state):
	#state["character"].emit_signal("pressed")
	var info_text = ""






	Context.send("tooltip for " + str(state["character"].item.get_name_text()) )


func get_item_names():
	var names = []
	if cached_names.empty():

		for item in selection_basis.buttons:
			names.append(item.text)
			print("Adding item name: " + item.text)
		cached_names = names
		return cached_names
	else:
		return cached_names


func find_item_button(translated_name):

	for item in selection_basis.buttons:
		#names_and_ids.append({"name": selection_basis._find_inventory_element_by_id(item, 0).item.get_name_text(), "id": item})
		var button = selection_basis.buttons[item]
		var name = button.item.text
		if name == translated_name:
			return button
	return null

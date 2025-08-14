class_name CommandHandler
extends Node

const INCOMING_MESSAGES_FOLDER := "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/incoming/"
var handlers: Array = [] # INCOMING MESSAGES

func register_all() -> void:
	var dir = Directory.new()
	var d = dir.open(INCOMING_MESSAGES_FOLDER)
	if d != OK:
		push_error("Could not open websocket messages directory")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".remap"):
			file_name = file_name.trim_suffix(".remap")
		if file_name.ends_with(".gd"):
			var script_path = INCOMING_MESSAGES_FOLDER + file_name
			var script = load(script_path)
			if script:
				var node = script.new()
				node.name = file_name.get_file().get_basename() # TODO: figure out pascal case
				add_child(node)
				handlers.append(node)
				print("Added websocket message node: %s" % [script_path])
		file_name = dir.get_next()
	dir.list_dir_end()

func handle(command: String, data) -> void:
	for handler in handlers:
		if !handler.can_handle(command):
			continue

		var state := {}

		var validation_result = handler.validate(command, data, state)
		if !validation_result.successful:
			push_warning("Received unsuccessful execution result when handling a message")
			push_warning(validation_result.message)

		handler.report_result(state, validation_result)

		if validation_result.successful:
			handler.execute(state)

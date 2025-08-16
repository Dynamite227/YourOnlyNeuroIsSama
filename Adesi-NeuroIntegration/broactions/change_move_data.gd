class_name ChangeMoveData
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"

# Constants matching main.gd data types
const HORIZONTAL_SLIDER = "HorizSlider"
const CHECK_BUTTON = "ActionUIDataCheckButton"
const EIGHT_WAY = "8Way"
const XY_PLOT = "XYPlot"

var limitPerDataType = {
	HORIZONTAL_SLIDER: Vector2(1, 100),
	CHECK_BUTTON: Vector2(0, 1),
	EIGHT_WAY: [1,2,3,4,5,6,7,8],
	XY_PLOT: Vector2(-1, 1)
}

var selection_basis # thing should inherit BaseSelection
var what_is_being_selected
var cached_names = []

var regexr = RegEx.new()
func _init(window, basis, what).(window):
	selection_basis = basis
	what_is_being_selected = what


func _get_name():
	return "change_" + what_is_being_selected + "_data"

func _get_description():
	return "Change the value of a " + what_is_being_selected + " parameter. This action allows you to modify numeric values for the selected item."

func _get_schema():
	var schema_properties = {
		"parameter": {
			"type": "string",
			"enum": get_item_names(),
			"description": "The parameter name to change"
		}
	}
	
	# Customize value schema based on data type using limitPerDataType
	match what_is_being_selected:
		CHECK_BUTTON:
			var limits = limitPerDataType[CHECK_BUTTON]
			schema_properties["new_value"] = {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new value (0 for false, 1 for true)"
			}
		XY_PLOT:
			var limits = limitPerDataType[XY_PLOT]
			schema_properties["new_value"] = {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new coordinate value (between " + str(limits.x) + " and " + str(limits.y) + ")"
			}
		HORIZONTAL_SLIDER:
			var limits = limitPerDataType[HORIZONTAL_SLIDER]
			schema_properties["new_value"] = {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new slider value (between " + str(limits.x) + " and " + str(limits.y) + ")"
			}
		EIGHT_WAY:
			var valid_values = limitPerDataType[EIGHT_WAY]
			schema_properties["new_value"] = {
				"type": "integer",
				"enum": valid_values,
				"description": "The direction value (1-8 representing the 8 directions)"
			}
		_:
			schema_properties["new_value"] = {
				"type": "number",
				"minimum": -1.0,
				"maximum": 1.0,
				"description": "The new numeric value to set for the parameter (must be between -1 and 1)"
			}
	
	return JsonUtils.wrap_schema(schema_properties)

func _validate_action(data, state):
	var selected_parameter = data.get_string("parameter", "")
	var new_value = data.get_float("new_value", 0.0)
	
	print("Validating parameter: " + str(selected_parameter) + ", new_value: " + str(new_value))
	
	if not selected_parameter or selected_parameter == "":
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["parameter"]))
	
	# Validate value based on data type limits
	var validation_result = validate_value_for_data_type(new_value)
	if not validation_result.success:
		return ExecutionResult.failure(validation_result.error_message)
	
	var available = get_item_names()
	if not available.has(selected_parameter):
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["parameter"]))
	
	# Store the selected parameter and new value
	state["selected_parameter"] = selected_parameter
	state["new_value"] = new_value
	return ExecutionResult.success()

func validate_value_for_data_type(value: float) -> Dictionary:
	match what_is_being_selected:
		CHECK_BUTTON:
			var limits = limitPerDataType[CHECK_BUTTON]
			if value < limits.x or value > limits.y:
				return {"success": false, "error_message": "new_value must be between " + str(limits.x) + " and " + str(limits.y) + " for CHECK_BUTTON, got: " + str(value)}
		
		XY_PLOT:
			var limits = limitPerDataType[XY_PLOT]
			if value < limits.x or value > limits.y:
				return {"success": false, "error_message": "new_value must be between " + str(limits.x) + " and " + str(limits.y) + " for XY_PLOT, got: " + str(value)}
		
		HORIZONTAL_SLIDER:
			var limits = limitPerDataType[HORIZONTAL_SLIDER]
			if value < limits.x or value > limits.y:
				return {"success": false, "error_message": "new_value must be between " + str(limits.x) + " and " + str(limits.y) + " for HORIZONTAL_SLIDER, got: " + str(value)}
		
		EIGHT_WAY:
			var valid_values = limitPerDataType[EIGHT_WAY]
			var int_value = int(value)
			if not valid_values.has(int_value):
				return {"success": false, "error_message": "new_value must be one of " + str(valid_values) + " for EIGHT_WAY, got: " + str(int_value)}
		
		_:
			if value < -1.0 or value > 1.0:
				return {"success": false, "error_message": "new_value must be between -1 and 1, got: " + str(value)}
	
	return {"success": true, "error_message": ""}


func _execute_action(state):
	var selected_parameter = state["selected_parameter"]
	var new_value = state["new_value"]
	
	print("Changing parameter: " + str(selected_parameter) + " to value: " + str(new_value))
	
	# Call the function to actually change the data
	var success = change_move_data_value(selected_parameter, new_value)
	
	if success:
		Context.send("Successfully changed " + str(selected_parameter) + " to " + str(new_value))
		return ExecutionResult.success()
	else:
		return ExecutionResult.failure("Failed to change " + str(selected_parameter))


func change_move_data_value(parameter_name: String, new_value: float) -> bool:
	print("Attempting to change parameter: " + parameter_name + " to value: " + str(new_value))
	print("Data type being changed: " + what_is_being_selected)
	
	# Clamp value based on data type limits
	var clamped_value = clamp_value_for_data_type(new_value)
	print("Clamped value: " + str(clamped_value))
	
	# Handle different data types based on what_is_being_selected
	match what_is_being_selected:
		XY_PLOT:
			return handle_xy_plot_change(parameter_name, clamped_value)
		HORIZONTAL_SLIDER:
			return handle_horizontal_slider_change(parameter_name, clamped_value)
		CHECK_BUTTON:
			return handle_check_button_change(parameter_name, clamped_value)
		EIGHT_WAY:
			return handle_eight_way_change(parameter_name, clamped_value)
		_:
			print("Unknown data type: " + what_is_being_selected)
			return handle_generic_change(parameter_name, clamped_value)

func clamp_value_for_data_type(value: float) -> float:
	match what_is_being_selected:
		CHECK_BUTTON:
			var limits = limitPerDataType[CHECK_BUTTON]
			return clamp(value, limits.x, limits.y)
		
		XY_PLOT:
			var limits = limitPerDataType[XY_PLOT]
			return clamp(value, limits.x, limits.y)
		
		HORIZONTAL_SLIDER:
			var limits = limitPerDataType[HORIZONTAL_SLIDER]
			return clamp(value, limits.x, limits.y)
		
		EIGHT_WAY:
			# For EIGHT_WAY, find the closest valid value
			var valid_values = limitPerDataType[EIGHT_WAY]
			var int_value = int(round(value))
			var closest_value = valid_values[0]
			var min_distance = abs(int_value - closest_value)
			
			for valid_val in valid_values:
				var distance = abs(int_value - valid_val)
				if distance < min_distance:
					min_distance = distance
					closest_value = valid_val
			
			return float(closest_value)
		
		_:
			return clamp(value, -1.0, 1.0)

func handle_xy_plot_change(parameter_name: String, new_value: float) -> bool:
	print("Handling XYPlot change for parameter: " + parameter_name)
	
	if selection_basis.has_method("set_value_float") and selection_basis.has_method("get_value_float"):
		var current_vector = selection_basis.get_value_float()
		print("Current vector value: " + str(current_vector))
		
		var new_vector = current_vector
		if parameter_name == "x":
			new_vector.x = new_value + 100
		elif parameter_name == "y":
			new_vector.y = new_value + 100
		else:
			print("Invalid parameter for XYPlot: " + parameter_name)
			return false
		
		# Ensure vector stays within unit circle
		if new_vector.length() > 1.0:
			new_vector = new_vector.normalized()
		
		print("Setting new vector value: " + str(new_vector))
		selection_basis.set_value_float(new_vector)
		
		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		return true
	
	return false

func handle_horizontal_slider_change(parameter_name: String, new_value: float) -> bool:
	print("Handling HorizontalSlider change for parameter: " + parameter_name)
	
	if selection_basis.has_method("set_value"):

		selection_basis.get_node("%Direction").value = new_value

		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		print("Set slider value to: " + str(new_value))
		return true
	
	return false

func handle_check_button_change(parameter_name: String, new_value: float) -> bool:
	print("Handling CheckButton change for parameter: " + parameter_name)
	
	# For check buttons, convert float to boolean (>0.5 = true, <=0.5 = false)
	var bool_value = new_value > 0.5
	
	if selection_basis.has_method("set_pressed"):
		selection_basis.set_pressed(bool_value)
		
		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		print("Set check button to: " + str(bool_value))
		return true
	
	return false

func handle_eight_way_change(parameter_name: String, new_value: float) -> bool:
	print("Handling 8Way change for parameter: " + parameter_name)
	
	# For 8Way controls, convert discrete direction to vector
	var direction_value = int(new_value)
	print("8Way direction value: " + str(direction_value))
	
	if selection_basis.has_method("set_value_float") and selection_basis.has_method("get_value_float"):
		var new_vector = Vector2.ZERO
		
		# Convert direction number (1-8) to vector
		match direction_value:
			1: # Up
				new_vector = Vector2(0, -1)
			2: # Up-Right
				new_vector = Vector2(1, -1).normalized()
			3: # Right
				new_vector = Vector2(1, 0)
			4: # Down-Right
				new_vector = Vector2(1, 1).normalized()
			5: # Down
				new_vector = Vector2(0, 1)
			6: # Down-Left
				new_vector = Vector2(-1, 1).normalized()
			7: # Left
				new_vector = Vector2(-1, 0)
			8: # Up-Left
				new_vector = Vector2(-1, -1).normalized()
			_: # Invalid or 0 - neutral
				new_vector = Vector2.ZERO
		
		print("Setting new 8Way vector value: " + str(new_vector))
		selection_basis.set_value_float(new_vector)
		
		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		return true
	
	return false

func handle_generic_change(parameter_name: String, new_value: float) -> bool:
	print("Handling generic change for parameter: " + parameter_name)
	
	# Try common methods for setting values
	if selection_basis.has_method("set_value"):
		selection_basis.set_value(new_value)
		
		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		return true
	elif selection_basis.has_method("set_property"):
		selection_basis.set_property(parameter_name, new_value)
		
		# Trigger data changed signal if available
		if selection_basis.has_signal("data_changed"):
			selection_basis.emit_signal("data_changed")
		
		return true
	
	print("No suitable method found for generic change")
	return false


func get_item_names():
	var names = []
	
	if cached_names.empty():
		print("Getting item names for data type: " + what_is_being_selected)
		
		# Handle different data types based on what_is_being_selected
		match what_is_being_selected:
			XY_PLOT:
				names = ["x", "y"]
				print("XYPlot parameters: " + str(names))
			
			HORIZONTAL_SLIDER:
				names = ["value"]
				print("HorizontalSlider parameters: " + str(names))
			
			CHECK_BUTTON:
				names = ["pressed"]
				print("CheckButton parameters: " + str(names))
			
			EIGHT_WAY:
				names = ["direction"]
				print("8Way parameters: " + str(names))
			
			_:
				# Fallback: try to get parameters from the selection_basis
				names = get_generic_parameters()
				print("Generic parameters: " + str(names))
		
		# If still no names found, provide defaults based on data type
		if names.empty():
			match what_is_being_selected:
				XY_PLOT:
					names = ["x", "y"]
				EIGHT_WAY:
					names = ["direction"]
				HORIZONTAL_SLIDER:
					names = ["value"]
				CHECK_BUTTON:
					names = ["pressed"]
				_:
					names = ["value"]  # Ultimate fallback
		
		cached_names = names
		Context.send("Available parameters to change for " + what_is_being_selected + ": " + str(cached_names))
		print("Final available parameters: " + str(cached_names))
		return cached_names
	else:
		return cached_names

func get_generic_parameters():
	var names = []
	
	# Try to get data from selection_basis
	if selection_basis.has_method("get_data"):
		var data = selection_basis.get_data()
		print("Getting generic parameters from data: " + str(data))
		
		if data is Dictionary:
			for key in data.keys():
				# Only include numeric parameters that can be modified
				if typeof(data[key]) == TYPE_INT or typeof(data[key]) == TYPE_REAL:
					names.append(str(key))
			print("Found dictionary keys for numeric values: " + str(names))
	
	return names

	



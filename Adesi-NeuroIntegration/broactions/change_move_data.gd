class_name ChangeMoveData
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"

# =============================================================================
# SIGNALS
# =============================================================================
signal ghost_done()

# =============================================================================
# CONSTANTS
# =============================================================================
# Data type constants matching main.gd
const HORIZONTAL_SLIDER = "HorizSlider"
const CHECK_BUTTON = "ActionUIDataCheckButton"
const EIGHT_WAY = "8Way"
const XY_PLOT = "XYPlot"

# Direction mapping for 8-way controls
const DIRECTION_STRINGS = ["NW", "N", "NE", "W", "Neutral", "E", "SW", "S", "SE"]

# Validation limits for each data type
const DATA_TYPE_LIMITS = {
	HORIZONTAL_SLIDER: Vector2(1, 100),
	CHECK_BUTTON: Vector2(0, 1),
	EIGHT_WAY: DIRECTION_STRINGS,
	XY_PLOT: Vector2(-1, 1)
}

# Parameter names for each data type
const DATA_TYPE_PARAMETERS = {
	XY_PLOT: ["x", "y"],
	HORIZONTAL_SLIDER: ["value"],
	CHECK_BUTTON: ["pressed"],
	EIGHT_WAY: ["direction"]
}

# =============================================================================
# VARIABLES
# =============================================================================
# Ghost game result tracking
var ghost_results = {
	"winner": 0,
	"p1_hp": 0,
	"p2_hp": 0,
	"game_ended": false,
	"game_length": 0,
	"forfeit": false,
	"forfeit_player": 0,
	"player_hit": false,
	"player_hit_frame": 0
}

# Core data
var selection_basis  # UI element being modified
var what_is_being_selected  # Data type identifier
var cached_names = []  # Cached parameter names

# =============================================================================
# INITIALIZATION
# =============================================================================
func _init(window, basis, what).(window):
	selection_basis = basis
	what_is_being_selected = what
	





# =============================================================================
# ACTION INTERFACE METHODS
# =============================================================================
func _get_name():
	return "change_%s_data" % what_is_being_selected

func _get_description():
	return "Change the value of a %s parameter. This action allows you to modify values for the selected item." % what_is_being_selected

func _get_schema():
	var schema_properties = {
		"parameter": {
			"type": "string",
			"enum": get_item_names(),
			"description": "The parameter name to change"
		}
	}
	
	# Add value schema based on data type
	schema_properties["new_value"] = _create_value_schema()
	
	return JsonUtils.wrap_schema(schema_properties)

func _create_value_schema() -> Dictionary:
	"""Create schema for the new_value parameter based on data type"""
	match what_is_being_selected:
		CHECK_BUTTON:
			var limits = DATA_TYPE_LIMITS[CHECK_BUTTON]
			return {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new value (0 for false, 1 for true)"
			}
		XY_PLOT:
			var limits = DATA_TYPE_LIMITS[XY_PLOT]
			return {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new coordinate value (between " + str(limits.x) + " and " + str(limits.y) + ")"
			}
		HORIZONTAL_SLIDER:
			var limits = DATA_TYPE_LIMITS[HORIZONTAL_SLIDER]
			return {
				"type": "number",
				"minimum": limits.x,
				"maximum": limits.y,
				"description": "The new slider value (between " + str(limits.x) + " and " + str(limits.y) + ")"
			}
		EIGHT_WAY:
			var valid_values = DATA_TYPE_LIMITS[EIGHT_WAY]
			return {
				"type": "string",
				"enum": valid_values,
				"description": "The direction value (" + str(valid_values).replace("[", "").replace("]", "") + ")"
			}
		_:
			return {
				"type": "number",
				"minimum": -1.0,
				"maximum": 1.0,
				"description": "The new numeric value to set for the parameter (must be between -1 and 1)"
			}

# =============================================================================
# VALIDATION METHODS
# =============================================================================
func _validate_action(data, state):
	"""Validate action parameters and store them in state"""
	var selected_parameter = data.get_string("parameter", "")
	
	print("Validating parameter: " + str(selected_parameter))
	
	if not selected_parameter or selected_parameter == "":
		return ExecutionResult.failure(Strings.action_failed_missing_required_parameter(["parameter"]))
	
	# Get value based on data type
	var new_value = _extract_value_from_data(data)
	print("Extracted value: " + str(new_value) + " (type: " + str(what_is_being_selected) + ")")
	
	# Validate value constraints
	var validation_result = _validate_value_constraints(new_value)
	if not validation_result.success:
		return ExecutionResult.failure(validation_result.error_message)
	
	# Validate parameter exists
	var available_parameters = get_item_names()
	if not available_parameters.has(selected_parameter):
		return ExecutionResult.failure(Strings.action_failed_invalid_parameter(["parameter"]))
	
	# Store validated data
	state["selected_parameter"] = selected_parameter
	state["new_value"] = new_value
	return ExecutionResult.success()

func _extract_value_from_data(data):
	"""Extract the appropriate value type from data based on data type"""
	if what_is_being_selected == EIGHT_WAY:
		return data.get_string("new_value", "")
	else:
		return data.get_float("new_value", 0.0)

func _validate_value_constraints(value) -> Dictionary:
	"""Validate value against data type constraints"""
	match what_is_being_selected:
		CHECK_BUTTON:
			return _validate_check_button_value(value)
		XY_PLOT:
			return _validate_xy_plot_value(value)
		HORIZONTAL_SLIDER:
			return _validate_horizontal_slider_value(value)
		EIGHT_WAY:
			return _validate_eight_way_value(value)
		_:
			return _validate_generic_value(value)

func _validate_check_button_value(value) -> Dictionary:
	var limits = DATA_TYPE_LIMITS[CHECK_BUTTON]
	if value < limits.x or value > limits.y:
		return _create_validation_error("CHECK_BUTTON", limits.x, limits.y, value)
	return _create_validation_success()

func _validate_xy_plot_value(value) -> Dictionary:
	var limits = DATA_TYPE_LIMITS[XY_PLOT]
	if value < limits.x or value > limits.y:
		return _create_validation_error("XY_PLOT", limits.x, limits.y, value)
	return _create_validation_success()

func _validate_horizontal_slider_value(value) -> Dictionary:
	var limits = DATA_TYPE_LIMITS[HORIZONTAL_SLIDER]
	if value < limits.x or value > limits.y:
		return _create_validation_error("HORIZONTAL_SLIDER", limits.x, limits.y, value)
	return _create_validation_success()

func _validate_eight_way_value(value) -> Dictionary:
	var valid_values = DATA_TYPE_LIMITS[EIGHT_WAY]
	if not valid_values.has(value):
		return {
			"success": false, 
				"error_message": "new_value must be one of " + str(valid_values) + " for EIGHT_WAY, got: " + str(value)
		}
	return _create_validation_success()

func _validate_generic_value(value) -> Dictionary:
	if typeof(value) == TYPE_REAL or typeof(value) == TYPE_INT:
		if value < -1.0 or value > 1.0:
			return {
				"success": false, 
				"error_message": "new_value must be between -1 and 1, got: " + str(value)
			}
	else:
		return {
			"success": false, 
			"error_message": "new_value must be a number, got: " + str(value)
		}
	return _create_validation_success()

func _create_validation_error(type_name: String, min_val, max_val, actual_val) -> Dictionary:
	return {
		"success": false,
		"error_message": "new_value must be between " + str(min_val) + " and " + str(max_val) + " for " + str(type_name) + ", got: " + str(actual_val)
	}

func _create_validation_success() -> Dictionary:
	return {"success": true, "error_message": ""}

# =============================================================================
# EXECUTION METHODS
# =============================================================================
func _execute_action(state):
	"""Execute the parameter change action"""
	var selected_parameter = state["selected_parameter"]
	var new_value = state["new_value"]
	
	print("Executing change: " + str(selected_parameter) + " = " + str(new_value))
	
	var success = _apply_parameter_change(selected_parameter, new_value)
	
	if success:
		return ExecutionResult.success()
	else:
		return ExecutionResult.failure("Failed to change " + str(selected_parameter))

func _apply_parameter_change(parameter_name: String, new_value) -> bool:
	"""Apply the parameter change based on data type"""
	print("Applying change: " + str(parameter_name) + " -> " + str(new_value) + " (type: " + str(what_is_being_selected) + ")")
	
	match what_is_being_selected:
		XY_PLOT:
			return _handle_xy_plot_change(parameter_name, new_value)
		HORIZONTAL_SLIDER:
			return _handle_horizontal_slider_change(parameter_name, new_value)
		CHECK_BUTTON:
			return _handle_check_button_change(parameter_name, new_value)
		EIGHT_WAY:
			return _handle_eight_way_change(parameter_name, new_value)
		_:
			print("Unknown data type: " + str(what_is_being_selected))
			return _handle_generic_change(parameter_name, new_value)

# =============================================================================
# DATA TYPE SPECIFIC HANDLERS
# =============================================================================
func _handle_xy_plot_change(parameter_name: String, new_value: float) -> bool:
	"""Handle XY plot parameter changes"""
	print("Handling XYPlot change: " + str(parameter_name) + " = " + str(new_value))
	
	if not selection_basis.has_method("set_value_float") or not selection_basis.has_method("get_value_float"):
		print("ERROR: selection_basis missing required methods for XYPlot")
		return false
	
	var current_vector = selection_basis.get_value_float()
	var new_vector = current_vector
	
	match parameter_name:
		"x":
			new_vector.x = new_value
		"y":
			new_vector.y = new_value
		_:
			print("ERROR: Invalid parameter for XYPlot: " + str(parameter_name))
			return false
	
	print("Setting XYPlot vector: " + str(current_vector) + " -> " + str(new_vector))
	selection_basis.set_value_float(new_vector)
	selection_basis.update_value(new_vector)
	
	_emit_data_changed_signals()
	selection_basis.emit_signal("pos_data_changed", new_vector)
	return true

func _handle_horizontal_slider_change(parameter_name: String, new_value: float) -> bool:
	"""Handle horizontal slider parameter changes"""
	print("Handling HorizontalSlider change: " + str(parameter_name) + " = " + str(new_value))
	
	var direction_node = selection_basis.get_node("Direction")
	if direction_node == null:
		print("ERROR: Could not find Direction node")
		return false
	
	direction_node.value = new_value
	print("Set slider value to: " + str(new_value))
	
	_emit_data_changed_signals()
	
	# Call update methods if available
	if selection_basis.has_method("on_value_changed"):
		selection_basis.on_value_changed(new_value)
	
	selection_basis.buffer_value_changed = true
	return true

func _handle_check_button_change(parameter_name: String, new_value: float) -> bool:
	"""Handle check button parameter changes"""
	print("Handling CheckButton change: " + str(parameter_name) + " = " + str(new_value))
	
	var bool_value = new_value > 0.5
	
	if not selection_basis.has_method("set_pressed"):
		print("ERROR: selection_basis missing set_pressed method")
		return false
	
	selection_basis.set_pressed(bool_value)
	_emit_data_changed_signals()
	
	print("Set check button to: " + str(bool_value))
	return true

func _handle_eight_way_change(parameter_name: String, new_value) -> bool:
	"""Handle 8-way direction parameter changes"""
	print("Handling 8Way change: " + str(parameter_name) + " = " + str(new_value))
	
	var direction_vector = _get_direction_vector(str(new_value))
	
	if selection_basis.has_method("set_facing"):
		selection_basis.set_facing(direction_vector.x)
	
	_emit_data_changed_signals()
	print("Set 8Way direction to: " + str(new_value) + " (vector: " + str(direction_vector) + ")")
	return true

func _handle_generic_change(parameter_name: String, new_value: float) -> bool:
	"""Handle generic parameter changes as fallback"""
	print("Handling generic change: " + str(parameter_name) + " = " + str(new_value))
	
	# Try common setter methods
	if selection_basis.has_method("set_value"):
		selection_basis.set_value(new_value)
		_emit_data_changed_signals()
		return true
	elif selection_basis.has_method("set_property"):
		selection_basis.set_property(parameter_name, new_value)
		_emit_data_changed_signals()
		return true
	
	print("ERROR: No suitable method found for generic change")
	return false

# =============================================================================
# UTILITY METHODS
# =============================================================================
func _get_direction_vector(direction_string: String) -> Vector2:
	"""Convert direction string to Vector2"""
	match direction_string:
		"SE": return Vector2(1, 1).normalized()
		"NE": return Vector2(1, -1).normalized()
		"E": return Vector2(1, 0)
		"SW": return Vector2(-1, 1).normalized()
		"NW": return Vector2(-1, -1).normalized()
		"W": return Vector2(-1, 0)
		"S": return Vector2(0, 1)
		"N": return Vector2(0, -1)
		"Neutral": return Vector2(0, 0)
		_: return Vector2(0, 0)

func _emit_data_changed_signals():
	"""Emit data changed signals if available"""
	if selection_basis.has_signal("data_changed"):
		selection_basis.emit_signal("data_changed")

# =============================================================================
# PARAMETER DISCOVERY
# =============================================================================
func get_item_names() -> Array:
	"""Get available parameter names for the current data type"""
	if cached_names.empty():
		cached_names = _discover_parameter_names()
		print("Discovered parameters for " + str(what_is_being_selected) + ": " + str(cached_names))
	
	return cached_names

func _discover_parameter_names() -> Array:
	"""Discover parameter names based on data type"""
	print("Discovering parameter names for: " + str(what_is_being_selected))
	
	# First try predefined parameters
	if DATA_TYPE_PARAMETERS.has(what_is_being_selected):
		var names = DATA_TYPE_PARAMETERS[what_is_being_selected]
		print("Using predefined parameters: " + str(names))
		return names
	
	# Fallback to generic discovery
	var generic_names = _discover_generic_parameters()
	if not generic_names.empty():
		print("Using generic parameters: " + str(generic_names))
		return generic_names
	
	# Ultimate fallback based on data type
	var fallback_names = _get_fallback_parameters()
	print("Using fallback parameters: " + str(fallback_names))
	return fallback_names

func _discover_generic_parameters() -> Array:
	"""Try to discover parameters from the selection_basis object"""
	var names = []
	
	if not selection_basis or not selection_basis.has_method("get_data"):
		return names
	
	var data = selection_basis.get_data()
	print("Examining data for generic parameters: " + str(data))
	
	if data is Dictionary:
		for key in data.keys():
			var value = data[key]
			# Only include numeric parameters that can be modified
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_REAL:
				names.append(str(key))
	
	return names

func _get_fallback_parameters() -> Array:
	"""Get fallback parameters when discovery fails"""
	match what_is_being_selected:
		XY_PLOT:
			return ["x", "y"]
		EIGHT_WAY:
			return ["direction"]
		HORIZONTAL_SLIDER:
			return ["value"]
		CHECK_BUTTON:
			return ["pressed"]
		_:
			return ["value"]  # Ultimate fallback

# =============================================================================
# GHOST GAME RESULT TRACKING
# =============================================================================
func update_ghost_results(winner: int, p1_hp: int, p2_hp: int, game_ended: bool = true):
	"""Update ghost game results for AI decision making"""
	ghost_results["winner"] = winner
	ghost_results["p1_hp"] = p1_hp
	ghost_results["p2_hp"] = p2_hp
	ghost_results["game_ended"] = game_ended
	ghost_results["game_length"] += 1
	
	print("Ghost results updated: " + str(ghost_results))
	emit_signal("ghost_done")

func get_ghost_winner() -> int:
	"""Get the winner from ghost game results"""
	return ghost_results.get("winner", 0)

func reset_ghost_results():
	"""Reset ghost game results to defaults"""
	ghost_results = {
		"winner": 0,
		"p1_hp": 0,
		"p2_hp": 0,
		"game_ended": false,
		"game_length": 0,
		"forfeit": false,
		"forfeit_player": 0,
		"player_hit": false,
		"player_hit_frame": 0
	}

# =============================================================================
# DEBUG UTILITIES
# =============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	return {
		"data_type": what_is_being_selected,
		"available_parameters": get_item_names(),
		"has_selection_basis": selection_basis != null,
		"ghost_results": ghost_results,
		"cached_names": cached_names
	}

func print_debug_info():
	"""Print debug information to console"""
	var info = get_debug_info()
	print("=== ChangeMoveData Debug Info ===")
	for key in info.keys():
		print(str(key) + ": " + str(info[key]))
	print("=== End Debug Info ===")

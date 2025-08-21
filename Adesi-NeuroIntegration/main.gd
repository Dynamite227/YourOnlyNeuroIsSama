extends Node
class_name IntegrationMain
# Main integration class for Neuro AI with "Your Only Move Is Hustle"
# Handles action windows, character selection, move picking, and game state management

# =============================================================================
# CONSTANTS
# =============================================================================
const HORIZONTAL_SLIDER = "HorizSlider"
const CHECK_BUTTON = "ActionUIDataCheckButton" 
const EIGHT_WAY = "8Way"
const XY_PLOT = "XYPlot"

# Move state enum for better state tracking
enum MoveState {
	IDLE,
	CHOOSING_MOVE,
	WAITING_FOR_ACTION,
	PROCESSING_DATA,
	CONFIRMING_MOVE
}

# =============================================================================
# VARIABLES
# =============================================================================
# Core references
var mod_main
var gameMain
var game
var matchData

# UI references - will be cached for performance
var _ui_action_buttons_path = "Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons"
var _ui_character_select_path = "UILayer/CharacterSelect/"

# State management
var current_move_state = MoveState.IDLE
var is_choosing = false
var is_game_initialized = false
var is_multiplayer_mode = false
var my_player_id = 1

# Stuck state detection
var state_start_time = 0.0
var last_state = MoveState.IDLE
var stuck_detection_enabled = true

# Move data types for UI components
var move_data_types = [HORIZONTAL_SLIDER, CHECK_BUTTON, EIGHT_WAY, XY_PLOT]

# =============================================================================
# INITIALIZATION
# =============================================================================
func _init(parent):
	mod_main = parent
func _ready():
	print("IntegrationMain initializing...")
	yield(get_tree().create_timer(1), "timeout")
	
	print("IntegrationMain ready - waiting for game to start...")
	# Don't automatically start any game mode - wait for manual start

func _exit_tree():
	"""Clean up when being removed from scene tree"""
	print("IntegrationMain exiting tree - cleaning up...")
	# Reset state variables to prevent issues with ActionWindows
	is_choosing = false
	current_move_state = MoveState.IDLE
	is_game_initialized = false
	
	# Disconnect signals to prevent errors during cleanup
	if game != null and is_instance_valid(game):
		if game.is_connected("ghost_my_turn", self, "_on_ghost_game"):
			game.disconnect("ghost_my_turn", self, "_on_ghost_game")

func _detect_game_mode_and_start():
	"""Detect if we're in multiplayer mode and start appropriate sequence - MANUAL USE ONLY"""
	print("Detecting game mode...")
	print("Network.multiplayer_active: ", Network.multiplayer_active)
	
	# Check if multiplayer is active
	if Network.multiplayer_active:
		is_multiplayer_mode = true
		my_player_id = Network.player_id
		print("Multiplayer mode detected - Player ID: ", my_player_id)
		_update_ui_paths_for_player()
		# In multiplayer, skip menu interaction as game is already starting
		_wait_for_game_start()
	else:
		is_multiplayer_mode = false
		my_player_id = 1
		print("Singleplayer mode detected")
		_start_singleplayer_sequence()

func _update_ui_paths_for_player():
	"""Update UI paths based on player ID"""
	var base_path = "Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/"
	
	if my_player_id == 2:
		# For P2, try P2ActionButtons first, but fall back to P1ActionButtons if they don't exist
		var p2_path = base_path + "P2ActionButtons"
		var p1_path = base_path + "P1ActionButtons"
		
		# Test if P2ActionButtons actually exist
		if _get_ui_node(p2_path) != null:
			_ui_action_buttons_path = p2_path
			print("Found P2ActionButtons - Player 2 using: ", _ui_action_buttons_path)
		else:
			_ui_action_buttons_path = p1_path
			print("P2ActionButtons not found - Player 2 falling back to P1ActionButtons: ", _ui_action_buttons_path)
	else:
		# P1 always uses P1ActionButtons
		_ui_action_buttons_path = base_path + "P1ActionButtons"
		print("Player 1 using: ", _ui_action_buttons_path)

func _start_singleplayer_sequence():
	"""Start the singleplayer game sequence"""
	var menu_start_button = get_tree().current_scene.get_node("UILayer/MainMenu/ButtonContainer/SingleplayerButton")
	if menu_start_button:
		menu_start_button.emit_signal("pressed")
		yield(get_tree().create_timer(1), "timeout")
		_choose_character()
	else:
		print("ERROR: Could not find singleplayer button")

func _wait_for_game_start():
	"""Wait for multiplayer game to start and handle character selection if needed"""
	print("Waiting for multiplayer game to start...")
	
	# Check if we're in character select screen
	yield(get_tree().create_timer(1), "timeout")
	var character_select_node = get_tree().current_scene.get_node(_ui_character_select_path)
	if character_select_node != null:
		print("Character selection screen detected in multiplayer")
		_choose_character()
	else:
		print("No character selection needed - game will start automatically")

func _start_game_sequence():
	"""Starts the game sequence by pressing singleplayer and choosing character"""
	_choose_character()

func start_character_selection():
	"""Public function to manually trigger character selection in multiplayer"""
	print("Manual character selection triggered")
	
	# Force character selection regardless of current state
	if is_multiplayer_mode:
		print("Forcing character selection in multiplayer mode for Player ", my_player_id)
	else:
		print("Forcing character selection in singleplayer mode")
	
	_choose_character()

func force_character_selection_check():
	"""Force check for character selection - useful for manual triggering"""
	print("Force checking for character selection...")
	
	if is_multiplayer_mode:
		_check_for_character_selection_multiplayer()
	else:
		_choose_character()

# =============================================================================
# GAME LOOP AND STATE MANAGEMENT  
# =============================================================================
func _process(delta):
	_check_game_initialization()
	_check_for_stuck_states()
	_handle_game_turn()
	_check_for_stuck_states()

func _check_game_initialization():
	"""Check if game is ready and initialize if needed"""
	# If game becomes invalid, reset our state
	if game != null and not is_instance_valid(game):
		print("WARNING: Game object became invalid, resetting...")
		game = null
		gameMain = null
		is_game_initialized = false
		is_choosing = false
		current_move_state = MoveState.IDLE
	
	if game == null and _is_main_game_available():
		_initialize_game_references()

func _is_main_game_available() -> bool:
	var main_node = get_tree().root.get_node("Main")
	return main_node != null and main_node.game != null

func _initialize_game_references():
	"""Initialize game references and connect signals"""
	gameMain = get_tree().root.get_node("Main")
	game = gameMain.game
	
	if not is_game_initialized:
		print("Game is ready, initializing...")
		is_game_initialized = true
		
		# Detect and configure for multiplayer or singleplayer
		if Network.multiplayer_active:
			is_multiplayer_mode = true
			my_player_id = Network.player_id
			_update_ui_paths_for_player()
			print("Multiplayer game detected - Player ID: ", my_player_id)
			
			# In multiplayer, wait a bit longer and then check for character selection
			yield(get_tree().create_timer(1.0), "timeout")
			_check_for_character_selection_multiplayer()
		else:
			is_multiplayer_mode = false
			my_player_id = 1
			print("Singleplayer game detected")
		
		game.connect("ghost_my_turn", self, "_on_ghost_game")

func _handle_game_turn():
	"""Handle player turn logic"""
	if game == null or not is_instance_valid(game):
		return
	
	# Check if we're stuck in choosing state but it's actually our turn
	if is_choosing:
		var should_act = false
		if is_multiplayer_mode:
			if my_player_id == 1:
				should_act = game.p1_turn if game.get("p1_turn") != null else false
			elif my_player_id == 2:
				should_act = game.p2_turn if game.get("p2_turn") != null else false
		else:
			should_act = game.p1_turn if game.get("p1_turn") != null else false
		
		# If it's NOT our turn and we're choosing, reset the state (we shouldn't be choosing when it's not our turn)
		if not should_act:
			print("WARNING: Choosing when it's not our turn - resetting state")
			is_choosing = false
			current_move_state = MoveState.IDLE
			return
		else:
			# If it's our turn and we're choosing, that's expected - continue
			return
	
	var should_act = false
	
	if is_multiplayer_mode:
		# In multiplayer, only act when it's our turn
		if my_player_id == 1:
			should_act = game.p1_turn if game.get("p1_turn") != null else false
		elif my_player_id == 2:
			should_act = game.p2_turn if game.get("p2_turn") != null else false
		
		# Debug: Log turn state in multiplayer
		if should_act:
			print("MULTIPLAYER DEBUG: It's Player ", my_player_id, "'s turn - P1:", game.p1_turn if game.get("p1_turn") != null else false, " P2:", game.p2_turn if game.get("p2_turn") != null else false)
	else:
		# In singleplayer, always act on p1 turn
		should_act = game.p1_turn if game.get("p1_turn") != null else false
	
	if should_act:
		_play_turn()

func _play_turn():
	"""Start a new turn for the player"""
	if game == null or not is_instance_valid(game):
		print("ERROR: Cannot play turn - game is null or freed")
		return
	
	# Check if we're already in a choosing state (might indicate manual lock-in happened)
	if is_choosing:
		print("WARNING: Already in choosing state when starting turn - checking if move was manually locked in")
		
		# Check if the turn is still active - if not, a move was likely already locked in manually
		var still_our_turn = false
		if is_multiplayer_mode:
			if my_player_id == 1:
				still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
			elif my_player_id == 2:
				still_our_turn = game.p2_turn if game.get("p2_turn") != null else false
		else:
			still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
		
		if not still_our_turn:
			print("Turn ended while we were choosing - move was likely locked in manually, resetting state")
			print("MULTIPLAYER DEBUG: P", my_player_id, " turn ended - P1:", game.p1_turn if game.get("p1_turn") != null else false, " P2:", game.p2_turn if game.get("p2_turn") != null else false)
			is_choosing = false
			current_move_state = MoveState.IDLE
			return
	
	current_move_state = MoveState.CHOOSING_MOVE
	is_choosing = true
	
	# Check if it's our turn based on game mode
	var player_data = null
	if is_multiplayer_mode:
		player_data = game.p1_data if my_player_id == 1 and game.get("p1_data") != null else (game.p2_data if game.get("p2_data") != null else null)
	else:
		player_data = game.p1_data if game.get("p1_data") != null else null
	
	if player_data:
		yield(get_tree().create_timer(1), "timeout")
		
		# Double-check we're still supposed to be choosing before proceeding
		var still_our_turn = false
		if is_multiplayer_mode:
			if my_player_id == 1:
				still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
			elif my_player_id == 2:
				still_our_turn = game.p2_turn if game.get("p2_turn") != null else false
		else:
			still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
		
		if still_our_turn and is_choosing:
			pick_move()
		else:
			print("Turn ended during delay - move was likely locked in manually, resetting state")
			print("MULTIPLAYER DEBUG: P", my_player_id, " turn check after delay - P1:", game.p1_turn if game.get("p1_turn") != null else false, " P2:", game.p2_turn if game.get("p2_turn") != null else false)
			is_choosing = false
			current_move_state = MoveState.IDLE

func _is_node_safe_to_use(node) -> bool:
	"""Check if a node is safe to use (not null, valid, and in scene tree)"""
	if node == null:
		return false
	if not is_instance_valid(node):
		return false
	if not node.is_inside_tree():
		return false
	return true

func _safe_queue_free(node):
	"""Safely queue free a node if it's valid"""
	if node != null and is_instance_valid(node):
		node.queue_free()

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
func get_game_state():
	"""Get current game state safely"""
	if game != null and is_instance_valid(game) and game.has_method("get_state"):
		return game.get_state()
	else:
		return null

func get_players() -> Array:
	"""Get player references"""
	if game != null and is_instance_valid(game) and game.get("p1") != null and game.get("p2") != null:
		return [game.p1, game.p2]
	else:
		return []

func _get_ui_node(path: String) -> Node:
	"""Safely get UI node with error handling"""
	var node = null
	
	# Try different approaches to find the node
	# First try from current scene
	if get_tree().current_scene != null:
		if get_tree().current_scene.has_node(path):
			node = get_tree().current_scene.get_node(path)
			if node != null:
				return node
	
	# Try from root
	if get_tree().root.has_node(path):
		node = get_tree().root.get_node(path)
		if node != null:
			return node
	
	# Try removing "Main/" prefix if it exists
	if path.begins_with("Main/"):
		var path_without_main = path.substr(5)  # Remove "Main/"
		if get_tree().current_scene != null and get_tree().current_scene.has_node(path_without_main):
			node = get_tree().current_scene.get_node(path_without_main)
			if node != null:
				return node
	
	# Silently return null - let calling function handle the error message
	return null

func _get_p2_character_name_safely(matchData) -> String:
	"""Safely get P2 character name from match data"""
	if matchData == null or not is_instance_valid(matchData):
		return "Unknown"
	
	if matchData.get("selected_characters") == null:
		return "Unknown"
	
	var selected_chars = matchData.selected_characters
	if selected_chars == null:
		return "Unknown"
	
	# Handle both Dictionary and Array types
	if typeof(selected_chars) == TYPE_DICTIONARY:
		if not 2 in selected_chars:
			return "Unknown"
		var p2_data = selected_chars[2]
		if typeof(p2_data) == TYPE_DICTIONARY and "name" in p2_data:
			return p2_data["name"]
	elif typeof(selected_chars) == TYPE_ARRAY:
		if selected_chars.size() > 2:
			var p2_data = selected_chars[2]
			if typeof(p2_data) == TYPE_DICTIONARY and "name" in p2_data:
				return p2_data["name"]
	
	return "Unknown"

# =============================================================================
# MOVE SELECTION AND ACTION HANDLING
# =============================================================================
func pick_move():
	"""Handle move selection for the current turn"""
	# Safety check - ensure we're still valid and in the scene tree
	if not _is_node_safe_to_use(self):
		print("ERROR: IntegrationMain is not safe to use")
		is_choosing = false
		return
	
	var game_state = _gather_game_state()
	var action_buttons = _get_ui_node(_ui_action_buttons_path)
	
	if action_buttons == null:
		print("ERROR: Could not find action buttons at path: ", _ui_action_buttons_path)
		# Try comprehensive fallback paths for multiplayer
		var fallback_paths = []
		
		if is_multiplayer_mode and my_player_id == 2:
			fallback_paths = [
				"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P2ActionButtons",
				"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",  # P2 might use P1 buttons
				"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",
				"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",  # Direct VBoxContainer
				"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",
				"UILayer/GameUI/BottomBar/ActionButtons",  # ActionButtons container itself
				"Main/UILayer/GameUI/BottomBar/ActionButtons"
			]
		else:
			# Fallback paths for P1 or when P2 detection fails
			fallback_paths = [
				"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",
				"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",
				"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",
				"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",
				"UILayer/GameUI/BottomBar/ActionButtons",
				"Main/UILayer/GameUI/BottomBar/ActionButtons"
			]
		
		for fallback_path in fallback_paths:
			print("Trying fallback path: ", fallback_path)
			action_buttons = _get_ui_node(fallback_path)
			if action_buttons != null:
				print("Found action buttons at fallback path: ", fallback_path)
				_ui_action_buttons_path = fallback_path  # Update path for future use
				break
		
		if action_buttons == null:
			print("ERROR: Could not find action buttons at any path")
			is_choosing = false
			return
	
	# Verify action buttons are still valid
	if not _is_node_safe_to_use(action_buttons):
		print("ERROR: Action buttons node is not safe to use")
		is_choosing = false
		return
	
	var available_actions = _get_available_actions(action_buttons)
	var context_message = _build_context_message(game_state, available_actions)
	print(context_message)
	
	_create_move_selection_window(action_buttons, context_message)

func _gather_game_state() -> Dictionary:
	"""Gather all relevant game state information"""
	if game == null or not is_instance_valid(game):
		print("WARNING: Game object is null or invalid, returning empty state")
		return {}
	
	matchData = game.match_data if game != null and is_instance_valid(game) and game.get("match_data") != null else null
	return {
		# Basic game state
		"current_tick": game.current_tick if game.get("current_tick") != null else 0,
		"time_left": game.get_ticks_left() if game.has_method("get_ticks_left") else 0,
		"game_started": game.game_started if game.get("game_started") != null else false,
		"game_finished": game.game_finished if game.get("game_finished") != null else false,
		"game_paused": game.game_paused if game.get("game_paused") != null else false,
		
		# Multiplayer info
		"is_multiplayer": is_multiplayer_mode,
		"my_player_id": my_player_id,
		"network_active": Network.multiplayer_active if Network.multiplayer_active != null else false,
		
		# Stage and environment
		"stage_width": game.stage_width if game.stage_width != null else 1100,
		"char_distance": game.char_distance if game.char_distance != null else 200,
		"max_char_distance": game.max_char_distance if game.max_char_distance != null else 600,
		"gravity_enabled": game.gravity_enabled if game.gravity_enabled != null else true,
		"has_ceiling": game.has_ceiling if game.has_ceiling != null else true,
		"ceiling_height": game.ceiling_height if game.ceiling_height != null else 400,
		"clashing_enabled": game.clashing_enabled if game.clashing_enabled != null else false,
		"asymmetrical_clashing": game.asymmetrical_clashing if game.asymmetrical_clashing != null else false,
		
		# Player 1 data
		"p1_character": game.p1.get_name() if game.p1 != null and game.p1.has_method("get_name") else "Unknown",
		"p1_state": game.p1.current_state().state_name if game.p1 != null and game.p1.current_state() != null else "Unknown",
		"p1_pos": game.p1.get_pos() if game.p1 != null and game.p1.has_method("get_pos") else Vector2(0, 0),
		"p1_facing": game.p1.get_facing_int() if game.p1 != null and game.p1.has_method("get_facing_int") else 1,
		"p1_hp": game.p1.hp if game.p1 != null and game.p1.hp != null else 0,
		"p1_max_hp": game.p1.MAX_HEALTH if game.p1 != null and game.p1.MAX_HEALTH != null else 1500,
		"p1_super_meter": game.p1.super_meter if game.p1 != null and game.p1.super_meter != null else 0,
		"p1_supers_available": game.p1.supers_available if game.p1 != null and game.p1.supers_available != null else 0,
		"p1_burst_meter": game.p1.burst_meter if game.p1 != null and game.p1.burst_meter != null else 0,
		"p1_bursts_available": game.p1.bursts_available if game.p1 != null and game.p1.bursts_available != null else 0,
		"p1_combo_count": game.p1.combo_count if game.p1 != null and game.p1.combo_count != null else 0,
		"p1_combo_moves": game.p1.combo_moves_used if game.p1 != null and game.p1.combo_moves_used != null else {},
		"p1_penalty": game.p1.penalty if game.p1 != null and game.p1.penalty != null else 0,
		"p1_turn": game.p1_turn if game.get("p1_turn") != null else false,
		"p1_actionable": game.p1.state_interruptable if game.p1 != null and is_instance_valid(game.p1) and game.p1.get("state_interruptable") != null else false,
		"p1_grounded": game.p1.is_grounded() if game.p1 != null and is_instance_valid(game.p1) and game.p1.has_method("is_grounded") else true,
		"p1_air_movements": game.p1.air_movements_left if game.p1 != null and is_instance_valid(game.p1) and game.p1.get("air_movements_left") != null else 0,
		"p1_invulnerable": game.p1.invulnerable if game.p1 != null and is_instance_valid(game.p1) and game.p1.get("invulnerable") != null else false,
		"p1_projectile_invulnerable": game.p1.projectile_invulnerable if game.p1 != null and is_instance_valid(game.p1) and game.p1.get("projectile_invulnerable") != null else false,
		"p1_armor": game.p1.has_armor() if game.p1 != null and is_instance_valid(game.p1) and game.p1.has_method("has_armor") else false,
		"p1_projectile_armor": game.p1.has_projectile_armor() if game.p1 != null and is_instance_valid(game.p1) and game.p1.has_method("has_projectile_armor") else false,
		
		# Player 2 data
		"p2_character": _get_p2_character_name_safely(matchData),
		"p2_state": game.p2.current_state().state_name if game.p2 != null and game.p2.current_state() != null else "Unknown",
		"p2_pos": game.p2.get_pos() if game.p2 != null and game.p2.has_method("get_pos") else Vector2(0, 0),
		"p2_facing": game.p2.get_facing_int() if game.p2 != null and game.p2.has_method("get_facing_int") else -1,
		"p2_hp": game.p2.hp if game.p2 != null and game.p2.hp != null else 0,
		"p2_max_hp": game.p2.MAX_HEALTH if game.p2 != null and game.p2.MAX_HEALTH != null else 1500,
		"p2_super_meter": game.p2.super_meter if game.p2 != null and game.p2.super_meter != null else 0,
		"p2_supers_available": game.p2.supers_available if game.p2 != null and game.p2.supers_available != null else 0,
		"p2_burst_meter": game.p2.burst_meter if game.p2 != null and game.p2.burst_meter != null else 0,
		"p2_bursts_available": game.p2.bursts_available if game.p2 != null and game.p2.bursts_available != null else 0,
		"p2_combo_count": game.p2.combo_count if game.p2 != null and game.p2.combo_count != null else 0,
		"p2_combo_moves": game.p2.combo_moves_used if game.p2 != null and game.p2.combo_moves_used != null else {},
		"p2_penalty": game.p2.penalty if game.p2 != null and game.p2.penalty != null else 0,
		"p2_turn": game.p2_turn if game.get("p2_turn") != null else false,
		"p2_actionable": game.p2.state_interruptable if game.p2 != null and is_instance_valid(game.p2) and game.p2.get("state_interruptable") != null else false,
		"p2_grounded": game.p2.is_grounded() if game.p2 != null and is_instance_valid(game.p2) and game.p2.has_method("is_grounded") else true,
		"p2_air_movements": game.p2.air_movements_left if game.p2 != null and is_instance_valid(game.p2) and game.p2.get("air_movements_left") != null else 0,
		"p2_invulnerable": game.p2.invulnerable if game.p2 != null and is_instance_valid(game.p2) and game.p2.get("invulnerable") != null else false,
		"p2_projectile_invulnerable": game.p2.projectile_invulnerable if game.p2 != null and is_instance_valid(game.p2) and game.p2.get("projectile_invulnerable") != null else false,
		"p2_armor": game.p2.has_armor() if game.p2 != null and is_instance_valid(game.p2) and game.p2.has_method("has_armor") else false,
		"p2_projectile_armor": game.p2.has_projectile_armor() if game.p2 != null and is_instance_valid(game.p2) and game.p2.has_method("has_projectile_armor") else false,
		
		# Special effects and states
		"super_freeze_ticks": game.super_freeze_ticks if game.super_freeze_ticks != null else 0,
		"super_active": game.super_active if game.super_active != null else false,
		"p1_super": game.p1_super if game.p1_super != null else false,
		"p2_super": game.p2_super if game.p2_super != null else false,
		"hit_freeze": game.hit_freeze if game.hit_freeze != null else false,
		"parry_freeze": game.parry_freeze if game.parry_freeze != null else false,
		"player_actionable": game.player_actionable if game.player_actionable != null else false,
		"prediction_effect": game.prediction_effect if game.prediction_effect != null else false,
		
		# Ghost game data
		"p1_ghost_action": gameMain.p1_ghost_action if gameMain != null and gameMain.p1_ghost_action != null else null,
		"p1_ghost_data": gameMain.p1_ghost_data if gameMain != null and gameMain.p1_ghost_data != null else null,
		"p1_ghost_extra": gameMain.p1_ghost_extra if gameMain != null and gameMain.p1_ghost_extra != null else null,
		"p2_ghost_action": gameMain.p2_ghost_action if gameMain != null and gameMain.p2_ghost_action != null else null,
		"p2_ghost_data": gameMain.p2_ghost_data if gameMain != null and gameMain.p2_ghost_data != null else null,
		"p2_ghost_extra": gameMain.p2_ghost_extra if gameMain != null and gameMain.p2_ghost_extra != null else null,
		"ghost_actionable_freeze_ticks": game.ghost_actionable_freeze_ticks if game.ghost_actionable_freeze_ticks != null else 0,
		"ghost_p1_actionable": game.ghost_p1_actionable if game.ghost_p1_actionable != null else false,
		"ghost_p2_actionable": game.ghost_p2_actionable if game.ghost_p2_actionable != null else false,
		"ghost_simulated_ticks": game.ghost_simulated_ticks if game.ghost_simulated_ticks != null else 0,
		
		# Objects and effects
		"active_objects": game.objects.size() if game.objects != null else 0,
		"active_effects": game.effects.size() if game.effects != null else 0,

	}

func _get_available_actions(action_buttons) -> Array:
	"""Get list of available actions from UI buttons"""
	var actions = []
	if action_buttons == null or not is_instance_valid(action_buttons):
		print("ERROR: action_buttons is null or invalid")
		return actions
	
	if action_buttons.buttons == null:
		print("ERROR: action_buttons does not have 'buttons' property")
		return actions
	
	if action_buttons.continue_button == null:
		print("ERROR: action_buttons does not have 'continue_button' property")
		return actions
		
	for button in action_buttons.buttons:
		if button != null and is_instance_valid(button) and button.visible and button != action_buttons.continue_button:
			if button.get("action_name") != null:
				actions.append(button.action_name)
			else:
				print("WARNING: Button does not have action_name property")
	return actions

func _build_context_message(game_state: Dictionary, actions: Array) -> String:
	"""Build context message for AI decision making"""
	var context_parts = PoolStringArray()
	
	# Basic game info
	var mode_text = "MULTIPLAYER" if game_state.is_multiplayer else "SINGLEPLAYER"
	var my_player_text = " (Playing as P" + str(game_state.my_player_id) + ")" if game_state.is_multiplayer else ""
	context_parts.append("GAME STATE: " + mode_text + my_player_text + " - Tick " + str(game_state.current_tick) + ", Time left: " + str(game_state.time_left))
	context_parts.append("Stage: " + str(game_state.stage_width) + " width, Distance: " + str(game_state.char_distance))
	
	# Available actions
	context_parts.append("AVAILABLE MOVES: " + str(actions))
	
	# Player 1 status - highlight if this is us in multiplayer
	var p1_prefix = "P1"
	if game_state.is_multiplayer and game_state.my_player_id == 1:
		p1_prefix = "ME(P1)"
	var p1_status = p1_prefix + "(" + game_state.p1_character + "): " + game_state.p1_state + " at " + str(game_state.p1_pos)
	p1_status += ", HP:" + str(game_state.p1_hp) + "/" + str(game_state.p1_max_hp)
	p1_status += ", Super:" + str(game_state.p1_super_meter) + "/" + str(game_state.p1_supers_available) + "bars"
	p1_status += ", Burst:" + str(game_state.p1_burst_meter) + "/" + str(game_state.p1_bursts_available) + "bars"
	p1_status += ", Combo:" + str(game_state.p1_combo_count) + ", Penalty:" + str(game_state.p1_penalty)
	p1_status += ", Facing:" + str(game_state.p1_facing)
	p1_status += ", Grounded:" + str(game_state.p1_grounded) + ", Air moves:" + str(game_state.p1_air_movements)
	if game_state.p1_armor: p1_status += ", ARMOR"
	if game_state.p1_invulnerable: p1_status += ", INVULN"
	if game_state.p1_actionable: p1_status += ", ACTIONABLE"
	context_parts.append(p1_status)
	
	# Player 2 status - highlight if this is us in multiplayer
	var p2_prefix = "P2"
	if game_state.is_multiplayer and game_state.my_player_id == 2:
		p2_prefix = "ME(P2)"
	var p2_status = p2_prefix + "(" + game_state.p2_character + "): " + game_state.p2_state + " at " + str(game_state.p2_pos)
	p2_status += ", HP:" + str(game_state.p2_hp) + "/" + str(game_state.p2_max_hp)
	p2_status += ", Super:" + str(game_state.p2_super_meter) + "/" + str(game_state.p2_supers_available) + "bars"
	p2_status += ", Burst:" + str(game_state.p2_burst_meter) + "/" + str(game_state.p2_bursts_available) + "bars"
	p2_status += ", Combo:" + str(game_state.p2_combo_count) + ", Penalty:" + str(game_state.p2_penalty)
	p2_status += ", Facing:" + str(game_state.p2_facing)
	p2_status += ", Grounded:" + str(game_state.p2_grounded) + ", Air moves:" + str(game_state.p2_air_movements)
	if game_state.p2_armor: p2_status += ", ARMOR"
	if game_state.p2_invulnerable: p2_status += ", INVULN"
	if game_state.p2_actionable: p2_status += ", ACTIONABLE"
	context_parts.append(p2_status)
	
	# Special effects
	var effects = PoolStringArray()
	if game_state.super_active: effects.append("SUPER_ACTIVE(" + str(game_state.super_freeze_ticks) + ")")
	if game_state.hit_freeze: effects.append("HIT_FREEZE")
	if game_state.parry_freeze: effects.append("PARRY_FREEZE")
	if game_state.prediction_effect: effects.append("PREDICTION")
	if game_state.p1_super: effects.append("P1_SUPER")
	if game_state.p2_super: effects.append("P2_SUPER")
	if effects.size() > 0:
		context_parts.append("EFFECTS: " + effects.join(", "))
	
	# Ghost game data
	if game_state.p1_ghost_action != null or game_state.p2_ghost_action != null:
		var ghost_info = "GHOST: "
		if game_state.p1_ghost_action != null:
			ghost_info += "P1_Action:" + str(game_state.p1_ghost_action) + " "
		if game_state.p2_ghost_action != null:
			ghost_info += "P2_Action:" + str(game_state.p2_ghost_action) + " "
		ghost_info += "Ticks:" + str(game_state.ghost_simulated_ticks)
		context_parts.append(ghost_info)
	
	# Environment
	if game_state.active_objects > 0 or game_state.active_effects > 0:
		context_parts.append("ENVIRONMENT: Objects:" + str(game_state.active_objects) + ", Effects:" + str(game_state.active_effects))
	
	return context_parts.join(". ")

func _create_move_selection_window(action_buttons, context: String):
	"""Create and register the move selection action window"""
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		print("ERROR: Cannot create action window - parent is null or invalid")
		is_choosing = false
		return
	
	# Double-check we're still in the scene tree
	if not is_inside_tree():
		print("ERROR: Cannot create action window - not in scene tree")
		is_choosing = false
		return
	
	# Ensure action_buttons is still valid
	if action_buttons == null or not is_instance_valid(action_buttons):
		print("ERROR: Action buttons became invalid while creating window")
		is_choosing = false
		return
	
	# Check one more time if it's still our turn before creating the window
	var still_our_turn = false
	if is_multiplayer_mode:
		if my_player_id == 1:
			still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
		elif my_player_id == 2:
			still_our_turn = game.p2_turn if game.get("p2_turn") != null else false
	else:
		still_our_turn = game.p1_turn if game.get("p1_turn") != null else false
	
	if not still_our_turn:
		print("Turn ended before creating action window - move was likely locked in manually")
		is_choosing = false
		current_move_state = MoveState.IDLE
		return
	
	var pick_window = ActionWindow.new(parent)
	if pick_window == null:
		print("ERROR: Failed to create ActionWindow")
		is_choosing = false
		return
	
	var pick_action = ChooseMove.new(pick_window, action_buttons, "move")
	if pick_action == null:
		print("ERROR: Failed to create ChooseMove action")
		if is_instance_valid(pick_window):
			pick_window.queue_free()
		is_choosing = false
		return
	
	pick_window.add_action(pick_action)
	pick_window.set_context(context, false)
	pick_window.set_force(10, "Pick a move", "Pick a move", false)
	pick_window.register()
	
	current_move_state = MoveState.WAITING_FOR_ACTION
	
	if pick_action != null and is_instance_valid(pick_action):
		pick_action.connect("action_chosen", self, "_on_action_chosen")
	
	print("Move selection window created")


func get_state_data_node(state):
	"""Get the data node from a state safely"""
	return state.data_node if state != null and state.data_node != null else null

# =============================================================================
# ACTION PROCESSING AND DATA HANDLING
# =============================================================================
func _on_action_chosen(state):
	"""Handle when an action is chosen by the AI"""
	var action_buttons = _get_ui_node(_ui_action_buttons_path)
	if action_buttons == null:
		print("ERROR: Could not find action buttons")
		is_choosing = false
		return
	
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		print("ERROR: Cannot create data window - parent is null or invalid")
		_finalize_move_selection(action_buttons)
		return
	
	# Double-check we're still in the scene tree
	if not is_inside_tree():
		print("ERROR: Cannot create data window - not in scene tree")
		_finalize_move_selection(action_buttons)
		return
	
	# Ensure state is valid
	if state == null or not is_instance_valid(state):
		print("ERROR: State is null or invalid")
		_finalize_move_selection(action_buttons)
		return
	
	var data_window = ActionWindow.new(parent)
	if data_window == null:
		print("ERROR: Failed to create data window")
		_finalize_move_selection(action_buttons)
		return
	
	var actions_added = _process_move_data_children(state, data_window)
	
	if actions_added:
		_register_data_window(data_window)
		yield(get_tree().create_timer(20), "timeout")
	else:
		print("No move data actions found - skipping data window")
		if is_instance_valid(data_window):
			data_window.queue_free()
	
	_finalize_move_selection(action_buttons)

func _process_move_data_children(state, data_window) -> bool:
	"""Process children nodes for move data types and add actions"""
	if not _is_node_safe_to_use(data_window):
		print("ERROR: Data window is not safe to use")
		return false
	
	var data_node = get_state_data_node(state)
	if data_node == null or not is_instance_valid(data_node):
		print("No valid data node found")
		return false
	
	var children = data_node.get_children()
	var actions_added = false
	
	print("Processing %d children for move data" % children.size())
	
	for child in children:
		if not is_instance_valid(child):
			continue
			
		var data_type = _identify_move_data_type(child)
		if data_type != "":
			_add_move_data_action(data_window, child, data_type)
			actions_added = true
			print("Added action for: ", data_type)
	
	return actions_added

func _identify_move_data_type(child) -> String:
	"""Identify what type of move data component this child is"""
	var script_path = child.get_script().resource_path if child.get_script() != null else ""
	
	for data_type in move_data_types:
		if data_type in script_path:
			return data_type
	
	return ""

func _add_move_data_action(data_window, child, data_type: String):
	"""Add a move data action to the window based on type"""
	var action = ChangeMoveData.new(data_window, child, data_type)
	data_window.add_action(action)
	
	var context = _get_data_type_context(data_type)
	data_window.set_context(context, false)

func _get_data_type_context(data_type: String) -> String:
	"""Get appropriate context message for each data type"""
	match data_type:
		HORIZONTAL_SLIDER:
			return "Adjust slider value for move parameters like speed or intensity"
		XY_PLOT:
			return "Set XY coordinates for 2D movement or positioning"
		EIGHT_WAY:
			return "Choose directional input from 8-way movement options"
		CHECK_BUTTON:
			return "Toggle boolean option on or off for this move"
		_:
			return "Configure move data parameter"

func _register_data_window(data_window):
	"""Register the data window for move parameter adjustment"""
	data_window.set_force(1, "change", "move data", false)
	data_window.register()
	current_move_state = MoveState.PROCESSING_DATA
	print("Data window registered for parameter adjustment")

func _finalize_move_selection(action_buttons):
	"""Finalize the move selection process"""
	print("Finalizing move selection...")
	current_move_state = MoveState.CONFIRMING_MOVE
	
	if action_buttons == null or not is_instance_valid(action_buttons):
		print("ERROR: Invalid action buttons during finalization")
		# Try to get action buttons again as fallback
		action_buttons = _get_ui_node(_ui_action_buttons_path)
		if action_buttons == null:
			print("ERROR: Could not retrieve action buttons for finalization")
			is_choosing = false
			return
	
	var select_button = action_buttons.get_node("%SelectButton")
	if select_button != null and is_instance_valid(select_button):
		select_button.emit_signal("pressed")
		print("Select button pressed")
	else:
		print("WARNING: Could not find select button")
		# Try alternative button names/paths
		var alt_button_names = ["SelectButton", "Select", "ConfirmButton", "Confirm"]
		for button_name in alt_button_names:
			select_button = action_buttons.get_node(button_name)
			if select_button != null and is_instance_valid(select_button):
				print("Found select button with alternative name: ", button_name)
				select_button.emit_signal("pressed")
				break
	
	is_choosing = false
	print("Move selection finalized")

# =============================================================================
# CHARACTER SELECTION
# =============================================================================
func _choose_character():
	"""Handle character selection at game start - works for both singleplayer and multiplayer"""
	print("Starting character selection for ", "multiplayer" if is_multiplayer_mode else "singleplayer", " mode")
	
	# Try multiple possible paths for character selection
	var character_select_paths = [
		"UILayer/CharacterSelect/",
		"UILayer/CharacterSelect",
		"CharacterSelect/",
		"CharacterSelect"
	]
	
	var character_select_node = null
	for path in character_select_paths:
		character_select_node = get_tree().current_scene.get_node(path)
		if character_select_node != null:
			print("Found character select node at path: ", path)
			break
	
	if character_select_node == null:
		print("ERROR: Could not find character select UI at any expected path")
		# Try the stored path as fallback
		character_select_node = get_tree().current_scene.get_node(_ui_character_select_path)
		if character_select_node == null:
			print("ERROR: Character select UI not found at stored path either: ", _ui_character_select_path)
			return
	
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		print("ERROR: Cannot create character selection window - parent is null or invalid")
		return
	
	# Double-check we're still in the scene tree
	if not is_inside_tree():
		print("ERROR: Cannot create character selection window - not in scene tree")
		return
	
	# Ensure character select node is still valid
	if not is_instance_valid(character_select_node):
		print("ERROR: Character select node became invalid")
		return
	
	var pick_window = ActionWindow.new(parent)
	if pick_window == null:
		print("ERROR: Failed to create character selection window")
		return
	
	var pick_action = SelectAction.new(pick_window, character_select_node, "character")
	if pick_action == null:
		print("ERROR: Failed to create character selection action")
		if is_instance_valid(pick_window):
			pick_window.queue_free()
		return
	
	pick_window.add_action(pick_action)
	
	# Different context based on game mode
	var context_message = ""
	if is_multiplayer_mode:
		context_message = "MULTIPLAYER: Choose your fighter for Player " + str(my_player_id) + "! Pick strategically against your opponent."
	else:
		context_message = "Choose your fighter! Pick any character you want - variety is key"
	
	pick_window.set_context(context_message, false)
	pick_window.set_force(3, "Pick a character", "Pick a character", false)
	pick_window.register()
	
	print("Character selection window registered for ", "P" + str(my_player_id) if is_multiplayer_mode else "player")

# =============================================================================
# EVENT HANDLERS
# =============================================================================
func _on_ghost_game():
	"""Handle ghost game events"""
	print("Ghost game event triggered")
	# Add ghost game handling logic here

# =============================================================================
# DEBUG AND UTILITY
# =============================================================================
func print_all_p1_variables():
	"""Debug function to print all P1 variables"""
	if game == null or game.p1 == null:
		print("ERROR: Game or P1 is null")
		return
	
	print("=== P1 DEBUG INFO ===")
	var p1 = game.p1
	print("HP: %d/%d" % [p1.hp, p1.MAX_HEALTH])
	print("State: %s" % p1.current_state().state_name)
	print("Position: %s" % str(p1.get_pos()))
	print("Facing: %d" % p1.get_facing_int())
	print("Super Meter: %d" % p1.super_meter)
	print("=== END P1 DEBUG ===")

func is_character_select_active() -> bool:
	"""Check if character selection screen is currently active"""
	var character_select_node = get_tree().current_scene.get_node(_ui_character_select_path)
	return character_select_node != null and character_select_node.visible

func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	if game == null or not is_instance_valid(game):
		return {"error": "Game not initialized or freed"}
	
	return {
		"move_state": current_move_state,
		"is_choosing": is_choosing,
		"game_initialized": is_game_initialized,
		"is_multiplayer_mode": is_multiplayer_mode,
		"my_player_id": my_player_id,
		"network_active": Network.multiplayer_active if Network.multiplayer_active != null else false,
		"p1_turn": game.p1_turn if game.get("p1_turn") != null else false,
		"p2_turn": game.p2_turn if game.get("p2_turn") != null else false,
		"players": get_players().size(),
		"character_select_active": is_character_select_active()
	}

func debug_multiplayer_state():
	"""Debug function to check multiplayer state and character selection"""
	print("=== MULTIPLAYER DEBUG INFO ===")
	print("Network.multiplayer_active: ", Network.multiplayer_active)
	print("Network.player_id: ", Network.player_id if Network.get("player_id") != null else "N/A")
	print("is_multiplayer_mode: ", is_multiplayer_mode)
	print("my_player_id: ", my_player_id)
	print("is_game_initialized: ", is_game_initialized)
	
	# Check for character selection UI
	var character_select_paths = [
		"UILayer/CharacterSelect/",
		"UILayer/CharacterSelect",
		"CharacterSelect/",
		"CharacterSelect"
	]
	
	print("Checking for character selection UI:")
	for path in character_select_paths:
		var node = get_tree().current_scene.get_node(path)
		if node != null:
			print("  FOUND at ", path, " - Visible: ", node.visible)
		else:
			print("  NOT FOUND at ", path)
	
	# Check current scene
	print("Current scene: ", get_tree().current_scene.name if get_tree().current_scene != null else "NULL")
	
	# Check game state
	if game != null and is_instance_valid(game):
		print("Game exists and is valid")
		print("Game started: ", game.game_started if game.get("game_started") != null else "N/A")
	else:
		print("Game is null or invalid")
	
	print("=== END MULTIPLAYER DEBUG ===")

func debug_ui_structure():
	"""Debug function to explore UI structure and find action buttons"""
	print("=== UI STRUCTURE DEBUG ===")
	print("Current scene: ", get_tree().current_scene.name if get_tree().current_scene != null else "NULL")
	
	# Try to find Main node
	var main_node = get_tree().root.get_node("Main")
	if main_node != null:
		print("Found Main node")
		var ui_layer = main_node.get_node("UILayer")
		if ui_layer != null:
			print("Found UILayer")
			var game_ui = ui_layer.get_node("GameUI")
			if game_ui != null:
				print("Found GameUI")
				var bottom_bar = game_ui.get_node("BottomBar")
				if bottom_bar != null:
					print("Found BottomBar")
					var action_buttons = bottom_bar.get_node("ActionButtons")
					if action_buttons != null:
						print("Found ActionButtons")
						var vbox = action_buttons.get_node("VBoxContainer")
						if vbox != null:
							print("Found VBoxContainer")
							print("VBoxContainer children:")
							for child in vbox.get_children():
								print("  - ", child.name, " (", child.get_class(), ")")
						else:
							print("VBoxContainer not found")
					else:
						print("ActionButtons not found")
				else:
					print("BottomBar not found")
			else:
				print("GameUI not found")
		else:
			print("UILayer not found")
	else:
		print("Main node not found")
	
	# Try current paths
	print("\nTesting current paths:")
	print("P1 path: ", "Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons")
	var p1_buttons = _get_ui_node("Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons")
	print("P1 buttons found: ", p1_buttons != null)
	
	print("P2 path: ", "Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P2ActionButtons")
	var p2_buttons = _get_ui_node("Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P2ActionButtons")
	print("P2 buttons found: ", p2_buttons != null)
	
	print("=== END UI STRUCTURE DEBUG ===")

func debug_action_button_paths():
	"""Debug function to test various action button paths and find the correct one"""
	print("=== ACTION BUTTON PATH DEBUG ===")
	print("Current _ui_action_buttons_path: ", _ui_action_buttons_path)
	print("is_multiplayer_mode: ", is_multiplayer_mode)
	print("my_player_id: ", my_player_id)
	
	var test_paths = [
		"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",
		"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P2ActionButtons",
		"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons",
		"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P2ActionButtons",
		"Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",
		"UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer",
		"Main/UILayer/GameUI/BottomBar/ActionButtons",
		"UILayer/GameUI/BottomBar/ActionButtons"
	]
	
	print("\nTesting paths:")
	for path in test_paths:
		var node = _get_ui_node(path)
		var exists = node != null
		var node_class = node.get_class() if exists else "N/A"
		var child_count = node.get_child_count() if exists else 0
		print("  ", path, " -> EXISTS: ", exists, " CLASS: ", node_class, " CHILDREN: ", child_count)
		
		if exists and child_count > 0:
			print("    Children:")
			for child in node.get_children():
				print("      - ", child.name, " (", child.get_class(), ")")
	
	print("=== END ACTION BUTTON PATH DEBUG ===")

func _check_for_character_selection_multiplayer():
	"""Check for character selection screen in multiplayer and trigger selection"""
	print("Checking for character selection in multiplayer...")
	
	# Try multiple paths for character selection
	var character_select_paths = [
		"UILayer/CharacterSelect/",
		"UILayer/CharacterSelect",
		"CharacterSelect/",
		"CharacterSelect"
	]
	
	var character_select_node = null
	for path in character_select_paths:
		character_select_node = get_tree().current_scene.get_node(path)
		if character_select_node != null:
			print("Found character select node at: ", path)
			break
	
	# If found and visible, trigger character selection
	if character_select_node != null and character_select_node.visible:
		print("Character selection screen active in multiplayer - triggering selection")
		_choose_character()
	else:
		# If not found immediately, keep checking for a few seconds
		print("Character selection not immediately visible, will keep checking...")
		_start_character_selection_polling()

func _start_character_selection_polling():
	"""Poll for character selection screen for a limited time"""
	var max_attempts = 10
	var attempt = 0
	
	while attempt < max_attempts:
		yield(get_tree().create_timer(0.5), "timeout")
		attempt += 1
		
		print("Character selection polling attempt: ", attempt)
		
		var character_select_node = get_tree().current_scene.get_node(_ui_character_select_path)
		if character_select_node != null and character_select_node.visible:
			print("Character selection screen found on attempt ", attempt, " - triggering selection")
			_choose_character()
			return
		
		# Also check if the game has already started (no character selection needed)
		if game != null and is_instance_valid(game) and game.get("game_started") != null and game.game_started:
			print("Game already started, no character selection needed")
			return
	
	print("Character selection polling timed out - may not be needed for this multiplayer game")

func _check_for_stuck_states():
	"""Check for and recover from stuck states caused by manual move lock-ins"""
	if not stuck_detection_enabled:
		return
	
	# Track state changes and time in each state
	var current_time = OS.get_system_time_msecs() / 1000.0
	
	if current_move_state != last_state:
		last_state = current_move_state
		state_start_time = current_time
		return
	
	var time_in_state = current_time - state_start_time
	
	# Define timeout thresholds for different states
	var timeout_threshold = 0.0
	match current_move_state:
		MoveState.CHOOSING_MOVE:
			timeout_threshold = 15.0  # 15 seconds for character selection
		MoveState.WAITING_FOR_ACTION:
			timeout_threshold = 10.0  # 10 seconds for move selection
		MoveState.PROCESSING_DATA:
			timeout_threshold = 25.0  # 25 seconds for data processing
		MoveState.CONFIRMING_MOVE:
			timeout_threshold = 5.0   # 5 seconds for confirming
		_:
			return  # No timeout for IDLE state
	
	# Check if we've been stuck too long
	if time_in_state > timeout_threshold:
		print("STUCK STATE DETECTED: Been in state ", current_move_state, " for ", time_in_state, " seconds")
		_recover_from_stuck_state()

func _recover_from_stuck_state():
	"""Recover from stuck states with appropriate actions"""
	print("Attempting to recover from stuck state: ", current_move_state)
	
	match current_move_state:
		MoveState.CHOOSING_MOVE:
			print("RECOVERY: Stuck in character selection - forcing random character")
			_force_random_character_selection()
		
		MoveState.WAITING_FOR_ACTION:
			print("RECOVERY: Stuck in move selection - forcing random move")
			_force_random_move_selection()
		
		MoveState.PROCESSING_DATA:
			print("RECOVERY: Stuck in data processing - skipping to finalization")
			_force_move_finalization()
		
		MoveState.CONFIRMING_MOVE:
			print("RECOVERY: Stuck in move confirmation - forcing confirmation")
			_force_move_confirmation()
		
		_:
			print("RECOVERY: Unknown stuck state - resetting to idle")
			_reset_to_idle_state()

func _force_random_character_selection():
	"""Force selection of a random character when stuck"""
	var character_select_node = get_tree().current_scene.get_node(_ui_character_select_path)
	if character_select_node != null:
		# Try to find and click a random character button
		var children = character_select_node.get_children()
		if children.size() > 0:
			var random_index = randi() % children.size()
			var random_character = children[random_index]
			
			# Try different methods to activate the character button safely
			var button_activated = false
			
			# Method 1: Try calling press() method if it exists
			if random_character.has_method("press"):
				random_character.press()
				button_activated = true
				print("RECOVERY: Pressed random character: ", random_character.name)
			
			# Method 2: Try emitting pressed signal if it exists
			elif random_character.has_signal("pressed"):
				random_character.emit_signal("pressed")
				button_activated = true
				print("RECOVERY: Emitted pressed signal for random character: ", random_character.name)
			
			# Method 3: Try calling _pressed() method if it exists
			elif random_character.has_method("_pressed"):
				random_character._pressed()
				button_activated = true
				print("RECOVERY: Called _pressed() for random character: ", random_character.name)
			
			if not button_activated:
				print("RECOVERY: Could not force character selection - no valid press method found")
		else:
			print("RECOVERY: No character buttons found")
	else:
		print("RECOVERY: Character select node not found")
	
	_reset_to_idle_state()

func _force_random_move_selection():
	"""Force selection of a random move when stuck"""
	var action_buttons = _get_ui_node(_ui_action_buttons_path)
	if action_buttons != null and action_buttons.get("buttons") != null:
		var available_buttons = []
		for button in action_buttons.buttons:
			if button != null and is_instance_valid(button) and button.visible and button != action_buttons.continue_button:
				available_buttons.append(button)
		
		if available_buttons.size() > 0:
			var random_index = randi() % available_buttons.size()
			var random_button = available_buttons[random_index]
			
			# Try different methods to activate the button safely
			var button_activated = false
			
			# Method 1: Try calling press() method if it exists
			if random_button.has_method("press"):
				random_button.press()
				button_activated = true
				print("RECOVERY: Pressed random move button: ", random_button.get("action_name", "Unknown"))
			
			# Method 2: Try emitting pressed signal if it exists
			elif random_button.has_signal("pressed"):
				random_button.emit_signal("pressed")
				button_activated = true
				print("RECOVERY: Emitted pressed signal for random move: ", random_button.get("action_name", "Unknown"))
			
			# Method 3: Try calling _pressed() method if it exists
			elif random_button.has_method("_pressed"):
				random_button._pressed()
				button_activated = true
				print("RECOVERY: Called _pressed() for random move: ", random_button.get("action_name", "Unknown"))
			
			# Method 4: Try calling button's script method if available
			elif random_button.get_script() != null and random_button.has_method("on_press"):
				random_button.on_press()
				button_activated = true
				print("RECOVERY: Called on_press() for random move: ", random_button.get("action_name", "Unknown"))
			
			if button_activated:
				# Wait a moment then force finalization
				yield(get_tree().create_timer(2.0), "timeout")
				_force_move_finalization()
			else:
				print("RECOVERY: Could not activate random button - no valid press method found")
				_reset_to_idle_state()
		else:
			print("RECOVERY: No available move buttons found")
			_reset_to_idle_state()
	else:
		print("RECOVERY: Action buttons not found")
		_reset_to_idle_state()

func _force_move_finalization():
	"""Force move finalization when stuck"""
	var action_buttons = _get_ui_node(_ui_action_buttons_path)
	if action_buttons != null:
		var select_button = action_buttons.get_node("%SelectButton")
		if select_button == null:
			# Try alternative button names
			var alt_button_names = ["SelectButton", "Select", "ConfirmButton", "Confirm"]
			for button_name in alt_button_names:
				select_button = action_buttons.get_node(button_name)
				if select_button != null:
					break
		
		if select_button != null and is_instance_valid(select_button):
			# Try different methods to activate the select button safely
			var button_activated = false
			
			# Method 1: Try calling press() method if it exists
			if select_button.has_method("press"):
				select_button.press()
				button_activated = true
				print("RECOVERY: Pressed select button")
			
			# Method 2: Try emitting pressed signal if it exists
			elif select_button.has_signal("pressed"):
				select_button.emit_signal("pressed")
				button_activated = true
				print("RECOVERY: Emitted pressed signal for select button")
			
			# Method 3: Try calling _pressed() method if it exists
			elif select_button.has_method("_pressed"):
				select_button._pressed()
				button_activated = true
				print("RECOVERY: Called _pressed() for select button")
			
			if not button_activated:
				print("RECOVERY: Could not activate select button - no valid press method found")
		else:
			print("RECOVERY: Could not find select button for finalization")
	else:
		print("RECOVERY: Action buttons not found for finalization")
	
	_reset_to_idle_state()

func _force_move_confirmation():
	"""Force move confirmation when stuck"""
	# Same as finalization for now
	_force_move_finalization()

func _reset_to_idle_state():
	"""Reset AI state to idle and clear any stuck conditions"""
	print("RECOVERY: Resetting to idle state")
	is_choosing = false
	current_move_state = MoveState.IDLE
	state_start_time = OS.get_system_time_msecs() / 1000.0
	
	# Clean up any lingering ActionWindows
	_cleanup_action_windows()

func _cleanup_action_windows():
	"""Safely clean up any ActionWindows that might be causing issues"""
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		return
	
	# Look for ActionWindow children and safely remove them
	for child in parent.get_children():
		if child.get_class() == "ActionWindow" or child.name.begins_with("ActionWindow"):
			print("CLEANUP: Removing ActionWindow: ", child.name)
			_safe_queue_free(child)

func force_reset_state():
	"""Public function to manually reset the AI state if it gets stuck"""
	print("Force resetting AI state...")
	_reset_to_idle_state()
	print("AI state reset complete")

extends Node
class_name IntegrationMain
# This file is used to actually faciliate the actions and context management for Neuro,
# This file will be very very very big.
# As i don't want to deal with multiple load() scattered over multiple files. 
# Some dedicated files should be fine. but stuff that interacts with the sdk should be in here. But stuff like a wrapper or something can be written seperatly and included here


const HORIZONTAL_SLIDER = "HorizSlider"
const CHECK_BUTTON = "ActionUIDataCheckButton"
const EIGHT_WAY = "8Way"
const XY_PLOT = "XYPlot"
var moveDataTypesArray = [HORIZONTAL_SLIDER, CHECK_BUTTON, EIGHT_WAY, XY_PLOT]
var movesButtons
var mod_main
var gameMain
var game 
var in_game = false
var player
var matchData
var opChar
var choosing = false
var allMovesPath
func _init(parent):
	self.mod_main = parent
	

func _ready():
	yield (get_tree().create_timer(1), "timeout")
	print("IntegrationMain ready")
	yield(get_tree().create_timer(6), "timeout")
	var menu_start_button = get_tree().current_scene.get_node("UILayer/MainMenu/ButtonContainer/SingleplayerButton")
	menu_start_button.emit_signal("pressed")
	yield (get_tree().create_timer(1), "timeout")
	_choose_character()
	
	

	
func _process(delta):
	if game == null:
		if get_tree().root.get_node("Main").game != null: 
			gameMain = get_tree().root.get_node("Main")



			game = get_tree().root.get_node("Main").game
			get_players()
			
	else:
		if game != null:
			if game.p1_turn and not choosing:
				play_turn()




func play_turn():
	
	choosing = true
	if game.p1_data:
		yield (get_tree().create_timer(1), "timeout")
		pick_move()

func _get_game_state():
	if game == null:
		return null
	return game.get_state()

func get_players():
	return [game.p1, game.p2]

func pick_move():
	


	var p1State = game.p1.current_state().state_name
	var p1Pos = game.p1.get_pos()
	var allMoves = get_tree().root.get_node("Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons")
	var actionList = []
	var p2State = game.p2.current_state().state_name
	var p2Pos = game.p2.get_pos()
	matchData = game.match_data
	var p2Character = matchData.selected_characters[2]["name"]
	print("p2 char is ", p2Character)
	for button in allMoves.buttons:
		if button.visible:

			actionList.append(button.action_name) 
		else:
			continue
		


	var pick = ActionWindow.new(get_parent())
	

	var pick_action = ChooseMove.new(pick, allMoves, "move")
	pick.add_action(pick_action)
	pick.set_context("Pick a move to play, your choices are " + str(actionList) + "your current fighter state is " + str(p1State) + "your character is at " + str(p1Pos) + "your oponent is playing " + str(p2Character) + "your oponent is at " + str(p2Pos) + "your oponent is at state: " + str(p2State) +" also, please keep responses concise, really dont want too long of rants", false)

	print("picking move")
	pick.set_force(3, "Pick a move", "Pick a move", false)
	pick.register()
	if pick_action != null:

		pick_action.connect("action_chosen", self, "_on_action_chosen")

	


func get_state_data_node(state):
	var dataNode
	if state.data_node != null:
		dataNode = state.data_node
	return dataNode


func _on_action_chosen(state):
	var allMoves = get_tree().root.get_node("Main/UILayer/GameUI/BottomBar/ActionButtons/VBoxContainer/P1ActionButtons")
	
	var dataWindow = ActionWindow.new(get_parent())
	var foundConsts = []
	var actions_added = false
	var children = get_state_data_node(state).get_children() if get_state_data_node(state) != null else []
	print("Found children: ", children.size())
	
	for child in children:
		var scriptPath = child.get_script().resource_path if child.get_script() != null else ""
		print("Checking script path: ", scriptPath)
		
		for constCheck in moveDataTypesArray:
			if constCheck in scriptPath:
				print(constCheck, "found in", scriptPath)
				foundConsts.append(constCheck)
		
		for found in foundConsts:
			var chooseAction = ChangeMoveData.new(dataWindow, child, found)
			dataWindow.add_action(chooseAction)
			actions_added = true
			print("Added action for: ", found)
			
			match found:
				HORIZONTAL_SLIDER:
					print("found horizontal slider")
					dataWindow.set_context("Change the value of the slider, the slider is used for things like move speed, or other values that are not binary, so please pick a value that makes sense for the move you are using, you are using " + str(state), false)
				XY_PLOT:
					print("found xy plot")
					dataWindow.set_context("Change the value of the XY plot, the XY plot is used for things like move speed in 2d space, or other values that are not binary, so please pick a value that makes sense for the move you are using, you are using " + str(state), false)
				EIGHT_WAY:
					print("8way found")
					dataWindow.set_context("Change the value of the 8-way direction, the 8-way direction is used for things like movement direction in a 2D space, so please pick a direction that makes sense for the move you are using, please note that not all values will be usable, you are using " + str(state), false)
				CHECK_BUTTON:
					print("check button found")
					dataWindow.set_context("Change the value of the check button, the check button is used for things like toggling options on and off, so please pick a value that makes sense for the move you are using, you are using " + str(state), false)
		
		# Clear foundConsts for next child
		foundConsts.clear()
	
	# Only register and proceed if actions were added
	if actions_added:
		dataWindow.set_force(1, "change", "move data", false)
		dataWindow.register()
		print("ActionWindow registered with actions")
		yield(get_tree().create_timer(20), "timeout")
	else:
		print("No actions found to add to ActionWindow - skipping registration")
	
	allMoves.get_node("%SelectButton").emit_signal("pressed")
	choosing = false		
			
func _choose_character():
	
	print("shown selections")
	var pick = ActionWindow.new(get_parent())
	var pick_action = SelectAction.new(pick, get_tree().current_scene.get_node("UILayer/CharacterSelect/"), "character")
	pick.add_action(pick_action)

	pick.set_force(3, "Pick a character", "Pick a character", false)

	pick.set_context("Pick a character to play with, pick whoever you want dont just go with one specific character, be different", false)
	print("picking")

	pick.register()

	


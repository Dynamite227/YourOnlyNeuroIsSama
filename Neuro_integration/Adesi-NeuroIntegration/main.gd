extends Node
class_name IntegrationMain
# This file is used to actually faciliate the actions and context management for Neuro,
# This file will be very very very big.
# As i don't want to deal with multiple load() scattered over multiple files. 
# Some dedicated files should be fine. but stuff that interacts with the sdk should be in here. But stuff like a wrapper or something can be written seperatly and included here

var movesButtons
var mod_main
var gameMain
var game 
var in_game = false
var player
var matchData
var opChar
var choosing = false
func _init(parent):
	self.mod_main = parent
	
	

func _ready():
	yield (get_tree().create_timer(1), "timeout")
	print("IntegrationMain ready")
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

		pick.connect("action_chosen", self, "_on_action_chosen")

	
	while choosing:
		yield (get_tree().create_timer(5), "timeout")
		if not choosing:
			break
		choosing = false


	
func _on_action_chosen():
	choosing = false

func _choose_character():
	
	print("shown selections")
	var pick = ActionWindow.new(get_parent())
	var pick_action = SelectAction.new(pick, get_tree().current_scene.get_node("UILayer/CharacterSelect/"), "character")
	pick.add_action(pick_action)

	pick.set_force(3, "Pick a character", "Pick a character", false)

	pick.set_context("Pick a character to play with", false)
	print("picking")

	pick.register()

	


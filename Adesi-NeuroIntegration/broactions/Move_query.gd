class_name MoveQuery
extends "res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action.gd"


signal action_chosen(state)
var selection_basis # thing should inherit BaseSelection
var what_is_being_selected
var game 
var currPlayer
var enemyPlayer

var ghost_results = {
	"winner": 0,
	"p1_hp": 0,
	"p2_hp": 0,
	"game_ended": false,
	"game_length": 0,
	"forfeit": false,
	"forfeit_player": 0,
	"player hit": false,
	"player hit frame": 0
}
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
			"enum": true
		}
	})

func _validate_action(data, state):
	return ExecutionResult.success()


func _execute_action(state):
	action_query()


	


	
func _go_on() -> String:
	return "action"

func action_query():
	yield( game, "ghost_finished")
	
	update_ghost_results()

func update_ghost_results():
	if game and game.is_ghost:
		ghost_results["winner"] = get_ghost_winner()
		ghost_results["p1_hp"] = game.p1.hp if game.p1 else 0
		ghost_results["p2_hp"] = game.p2.hp if game.p2 else 0
		ghost_results["game_ended"] = game.game_finished
		ghost_results["game_length"] = game.current_tick
		ghost_results["forfeit"] = game.forfeit
		ghost_results["forfeit_player"] = game.forfeit_player.id if game.forfeit_player else 0
		ghost_results["player hit"] = currPlayer.ghost_got_hit
		ghost_results["player hit frame"] = currPlayer.hit_frame_label.text 
		ghost_results["enemy hit"] = enemyPlayer.ghost_got_hit
		ghost_results["enemy hit frame"] = enemyPlayer.hit_frame_label.text
		print("Ghost game results updated: ", ghost_results)
		
		print("Ghost game finished. Winner: Player " + str(ghost_results["winner"]) + 
					", P1 HP: " + str(ghost_results["p1_hp"]) + 
					", P2 HP: " + str(ghost_results["p2_hp"]) +
					", got hit? " + str(ghost_results["player hit"]) +
					", Player hit frame: " + str(ghost_results["player hit frame"]) +
					", Enemy got hit? " + str(ghost_results["enemy hit"]) +
					", Enemy hit frame: " + str(ghost_results["enemy hit frame"]))
		emit_signal("ghost_done")

func get_ghost_winner() -> int:
	if not game or not game.is_ghost:
		return 0
	
	if game.forfeit and game.forfeit_player:
		# Winner is the opposite of who forfeited
		return 2 if game.forfeit_player.id == 1 else 1
	
	if game.p2.hp > game.p1.hp:
		return 2
	elif game.p1.hp > game.p2.hp:
		return 1
	else:
		return 0  # Draw or no clear winner

func get_ghost_results() -> Dictionary:
	return ghost_results.duplicate()

func reset_ghost_results():
	ghost_results = {
		"winner": 0,
		"p1_hp": 0,
		"p2_hp": 0,
		"game_ended": false,
		"game_length": 0,
		"forfeit": false,
		"forfeit_player": 0,
		"player hit": false
	}

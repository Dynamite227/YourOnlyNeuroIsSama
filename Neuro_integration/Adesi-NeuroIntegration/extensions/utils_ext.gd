extends "res://ModOverride.gd"

var Context = preload("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/context.gd")
var ActionWindow = preload("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/action_window.gd")
var NeuroActionHandler
var SelectAction = preload("res://Neuro_integration/Adesi-NeuroIntegration/broactions/select_thing.gd")


enum MoveMode {
    MovePattern,
    RunToClosestEnemy,
    RunAwayFromClosestEnemy,
    MoveTo,
    MoveCustom
}
var move_mode = MoveMode.MovePattern
enum MovePattern {
    Circle,
    Spiral,
    Random,
}
var pattern_move = MovePattern.Circle
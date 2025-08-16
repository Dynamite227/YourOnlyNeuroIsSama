extends Node


const AUTHORNAME_MODNAME_DIR := "Adesi-NeuroIntegration" 
const AUTHORNAME_MODNAME_LOG_NAME := "Adesi-NeuroIntegration:Main"

var mod_dir_path := ""
var extensions_dir_path := ""

var mod_loader

func _init(ml = ModLoader):
	print("NeuroIntegration: Init")
	mod_loader = ml
	
	mod_dir_path = "res://Neuro_integration/Adesi-NeuroIntegration/"

	install_script_extensions()

	add_child_nodes()

var action_handler
func add_child_nodes():
	var websocket = load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/websocket/websocket.gd").new()
	websocket.name = "WebsocketNode"
	add_child(websocket)

	action_handler = load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/actions/neuro_action_handler.gd").new()
	action_handler.name = "NeuroActionHandlerNode"
	add_child(action_handler)
	var main = load("res://Neuro_integration/Adesi-NeuroIntegration/main.gd").new(self)
	main.name = "IntegrationMainNode"
	add_child(main)
func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")

	mod_loader.installScriptExtension(extensions_dir_path.plus_file("utils_ext.gd"))


func _ready() -> void:
	ModOverride.NeuroActionHandler = action_handler
	print(get_tree().root.get_node("/root/ModLoader/@@2/WebsocketNode"))

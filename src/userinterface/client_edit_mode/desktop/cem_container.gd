extends Node

var _cem_state: bool = false

@onready var inspector: Node = get_node("Inspector")
@onready var file_browser: Node = get_node("VBoxContainer/Panel")
@onready var crosshair: Node = get_node("VBoxContainer/SubViewportContainer/SubViewport/Crosshair")


func _ready() -> void:
	Events.cem_set_state.connect(_cem_set_state)
	return


func _cem_set_state(state: bool) -> void:
	var is_different = state != _cem_state

	if is_different == false:
		return
	_cem_state = state

	if state == true:
		inspector.visible = true
		file_browser.visible = true
		crosshair.visible = false
	else:
		inspector.visible = false
		file_browser.visible = false
		crosshair.visible = true
	return

extends Control

@export var display_text: String = "Default Text"

@onready var lineedit_node = get_child(0).get_child(0).get_child(1).get_child(0)


func _ready():
	lineedit_node.placeholder_text = display_text

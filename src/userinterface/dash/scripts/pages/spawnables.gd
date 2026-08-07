# --- License
# File: /client/src/userinterface/dash/scripts/pages/spawnables.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dash/scripts/pages/left_nav_container.gd"

const BASE_DIR = "user://inventory/"

var current_dir: Array[String] = []
var _action_buttons: Array[Node] = []
var _template_button = preload("res://userinterface/dash/partials/category_button.tscn")
var _selected_folder: Node

@onready var _app_spawnable_file_handling_m = get_tree().current_scene.get_node("SpawnableFileHandling")
@onready var _path_container = $"HBox/Right/Local/Path"
@onready var _folder_container = $"HBox/Right/Local/Folders"
@onready var _file_container = $"HBox/Right/Local/Files"
@onready var _create_folder_btn = $"HBox/Right/Local/Actions/NewFolder/Button"
@onready var _delete_selected_btn = $"HBox/Right/Local/Actions/DeleteSelected/Button"
@onready var _folder_creation_dialog = $"FolderCreation"
@onready var _deletion_dialog = $"DeleteConfirmation"
@onready var dashboard = get_tree().current_scene.get_node("Dashboard")


func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_page_opened)

	_create_folder_btn.pressed.connect(_open_file_dialog)
	_delete_selected_btn.pressed.connect(_open_delete_dialog)

	_folder_creation_dialog.confirmed.connect(_create_folder)
	_deletion_dialog.confirmed.connect(_delete_selected)

	_build_view()
	return


func _handle_page_opened(page_name) -> void:
	if page_name != "Spawnables":
		return

	return


func _build_view() -> void:
	var _filelist = FileManager.get_inv_filelist()
	var _files = _filelist["files"]
	var _dirs = _filelist["directories"]

	await _clear_view()

	for file in _files:
		var _file_pretty_name = file.name
		var _file_name: String = file.hash
		var _listing
		if file.type == Enum.SpawnableType.WORLD:
			_listing = _create_button(_file_pretty_name, "", _create_world.bind(_file_name + ".tscn"))
		else:
			_listing = _create_button(_file_pretty_name, "", _load_file.bind(_file_name + ".tscn"))

		_file_container.add_child(_listing)
		continue

	for folder in _dirs:
		var _listing = _create_button(folder, "Folder", _dir_deeper.bind(folder))
		_folder_container.add_child(_listing)
		continue

	# Path
	# Label
	var _label_label = Label.new()
	_label_label.text = "Path:"
	_path_container.add_child(_label_label)

	# Root path
	var _base_listing = _create_button("Base", "", _dir_relocate.bind(-1), Vector2(200, 35))
	_path_container.add_child(_base_listing)

	# Any lower path
	for index in FileManager.spawnables_dir.size():
		var _path = FileManager.spawnables_dir[index]
		var _label = Label.new()
		var _listing = _create_button(_path, "", _dir_relocate.bind(index), Vector2(200, 35))

		_label.text = "/"

		_path_container.add_child(_label)
		_path_container.add_child(_listing)
		continue
	return


func _dir_deeper(path: String) -> void:
	FileManager.move_inv_deeper(path)
	_build_view()
	return


func _dir_relocate(index: int) -> void:
	FileManager.move_inv_relocate(index + 1)
	_build_view()
	return


func _load_file(file_name: String) -> void:
	var _path = FileManager._current_path() + file_name
	_app_spawnable_file_handling_m.load_spawnable(_path)
	return


func _create_world(file_name: String) -> void:
	var _dialog: Control = dashboard.get_node("NewWorld")
	var _world_load_dir_val: Control = _dialog.get_node("%WorldLoadDirVal")
	var _base_val: Control = _dialog.get_node("%BaseVal")
	var _file_path = FileManager._current_path() + file_name

	_world_load_dir_val.text = _file_path
	_base_val.selected = Enum.BaseLevel.CUSTOM

	_dialog.show_window()
	return


func _create_button(btn_name: String, icon: String = "", double_click = null, min_size: Vector2 = Vector2(350, 50)) -> Node:
	var _listing = _template_button.instantiate()
	_listing.set_meta("label", btn_name)
	_listing.selected_icon = icon
	_listing.custom_minimum_size = min_size
	_listing.toggle = true

	_listing.get_node("Button").pressed.connect(_button_selected.bind(_listing))

	if double_click != null:
		# TODO: Check if double_click param is a function
		_listing.double_clicked.connect(double_click)

	_action_buttons.append(_listing)
	return _listing


func _button_selected(selected: Node) -> void:
	var _button_name = selected.get_meta("label")

	for button in _action_buttons:
		button.get_node("Button").button_pressed = false

	selected.get_node("Button").button_pressed = true

	_selected_folder = selected
	return


func _clear_view() -> void:
	_action_buttons = []
	_selected_folder = null

	for child in _folder_container.get_children():
		child.queue_free()

	for child in _file_container.get_children():
		child.queue_free()

	for child in _path_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	return


func _open_file_dialog() -> void:
	_folder_creation_dialog.show()
	return


func _create_folder() -> void:
	var _folder_name = _folder_creation_dialog.get_node("LineEdit").text
	GlobalLogger.log("Creating folder '%s'" % _folder_name)
	FileManager.create_folder(_folder_name)
	_folder_creation_dialog.get_node("LineEdit").text = ""
	_build_view()
	return


func _open_delete_dialog() -> void:
	if _selected_folder == null:
		GlobalLogger.log("Tried to open the delete dialog without anything selected.", Enum.LogLevel.WARNING)
		return

	var _folder_name = _selected_folder.get_meta("label")
	var _text = "Are you sure you want to delete\n\"%s\"" % _folder_name

	_deletion_dialog.dialog_text = _text

	_deletion_dialog.show()
	return


func _delete_selected() -> void:
	var _folder_name = _selected_folder.get_meta("label")
	GlobalLogger.log("Deleting Item '%s'" % _folder_name)
	FileManager.delete_folder(_folder_name)
	_build_view()
	return

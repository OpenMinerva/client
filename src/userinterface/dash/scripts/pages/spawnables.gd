# --- License
# File: /client/src/userinterface/dash/scripts/pages/spawnables.gd
# Project: OpenMinerva
# Created Date: 11 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dash/scripts/pages/left_nav_container.gd"

var _folder_icon = load("res://resources/icons/godot/Folder.svg")
var _item_icon = load("res://resources/icons/godot/Node3D.svg")
var _world_icon = load("res://resources/icons/godot/World3D.svg")
var _action_buttons: Array[Node] = []
var _template_button = preload("res://userinterface/dash/partials/generic_button.tscn")
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
	Events.cem_spawnable_saved.connect(func(): _build_view())

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
	var _filelist = _get_inv_filelist()
	var _files = _filelist["files"]
	var _dirs = _filelist["directories"]

	await _clear_view()

	for file in _files:
		var _file_pretty_name = file.name
		var _file_name: String = file.hash
		var _listing
		if file.type == Enum.SpawnableType.WORLD:
			_listing = _create_button(_file_container, _file_pretty_name, _world_icon, _create_world.bind(_file_name + ".tscn"))
		else:
			_listing = _create_button(_file_container, _file_pretty_name, _item_icon, _load_file.bind(_file_name + ".tscn"))

		_listing.set_meta("type", "spawnable")
		_listing.set_meta("file_name", _file_name)
		continue

	for folder in _dirs:
		var _listing = _create_button(_folder_container, folder, _folder_icon, _dir_deeper.bind(folder))
		_listing.set_meta("type", "folder")
		continue

	# Path
	# Label
	var _label_label = Label.new()
	_label_label.text = "Path:"
	_path_container.add_child(_label_label)

	# Root path
	var _base_listing = _create_button(_path_container, "Base", null, _dir_relocate.bind(-1), Vector2(200, 35))

	# Any lower path
	for index in StateManager.spawnable_directory.size():
		var _path = StateManager.spawnable_directory[index]

		var _label = Label.new()
		_label.text = "/"
		_path_container.add_child(_label)

		var _listing = _create_button(_path_container, _path, null, _dir_relocate.bind(index), Vector2(200, 35))
		continue
	return


func _get_inv_filelist() -> Dictionary:
	var response = { "files": [], "directories": [] }

	var _files = Database.get_spawnables_by_directory(_get_current_path())

	response.files = _files
	response.directories = FileManager.list_directories(_get_current_path())

	return response


func _dir_deeper(folder_name: String) -> void:
	StateManager.spawnable_directory.append(folder_name)
	_build_view()
	return


func _dir_relocate(index: int) -> void:
	StateManager.spawnable_directory.resize(index + 1)
	_build_view()
	return


func _get_current_path() -> String:
	var _response: String = FileManager.BASE_SPAWNABLE_DIR + "/".join(StateManager.spawnable_directory)

	if _response.ends_with("/") == false:
		_response = _response + "/"

	return _response


func _load_file(file_name: String) -> void:
	var _path = _get_current_path() + file_name
	_app_spawnable_file_handling_m.load_spawnable(_path)
	return


func _create_world(file_name: String) -> void:
	var _dialog: Control = dashboard.get_node("NewWorld")
	var _world_load_dir_val: Control = _dialog.get_node("%WorldLoadDirVal")
	var _base_val: Control = _dialog.get_node("%BaseVal")
	var _file_path = _get_current_path() + file_name

	_world_load_dir_val.text = _file_path
	_base_val.selected = Enum.BaseLevel.CUSTOM

	_dialog.show_window()
	return


func _create_button(parent: Node, label: String = "invalid", icon: Texture2D = null, double_click_fn = null, min_size: Vector2 = Vector2(350, 50)) -> Node:
	var _listing: Node = _template_button.instantiate()
	parent.add_child(_listing)

	if icon != null:
		_listing.set_icon(icon)

	_listing.set_label(label)
	_listing.set_toggle(true)

	_listing.custom_minimum_size = min_size

	_listing.clicked.connect(func(): _button_selected(_listing))

	if double_click_fn != null:
		# TODO: Check if double_click param is a function
		_listing.double_clicked.connect(double_click_fn)

	_action_buttons.append(_listing)
	return _listing


func _button_selected(selected: Node) -> void:
	# HACK: Directly interfacing with the internal button on the generic button.
	for button in _action_buttons:
		button._node_button.button_pressed = false
	selected._node_button.button_pressed = true

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
	FileManager.create_directory(_get_current_path() + _folder_name)
	_folder_creation_dialog.get_node("LineEdit").text = ""
	_build_view()
	return


func _open_delete_dialog() -> void:
	if _selected_folder == null:
		GlobalLogger.log("Tried to open the delete dialog without anything selected.", Enum.LogLevel.WARNING)
		return

	var _folder_name = _selected_folder.label
	var _text = "Are you sure you want to delete\n\"%s\"" % _folder_name

	_deletion_dialog.dialog_text = _text

	_deletion_dialog.show()
	return


func _delete_selected() -> void:
	var _folder_name = _selected_folder.label
	var _type: String = _selected_folder.get_meta("type")
	var _path: String = _get_current_path() + _folder_name

	GlobalLogger.log("Deleting Item '%s'" % _folder_name)

	if _type == "spawnable":
		var _file_name: String = _selected_folder.get_meta("file_name")
		var _db_entry: Dictionary = Database.get_spawnable(_file_name)

		if _db_entry.has("directory") == false:
			GlobalLogger.log("Tried to delete file '%s' but the directory could not be found!" % _file_name, Enum.LogLevel.WARNING)
			return

		FileManager.delete_file(_db_entry.directory)
		Database.delete_spawnable(_db_entry.hash)

	if _type == "folder":
		FileManager.delete_directory(_path)

	_build_view()
	return

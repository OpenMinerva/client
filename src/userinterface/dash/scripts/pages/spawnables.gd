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
var _template_button = preload("res://userinterface/dash/partials/category_button.tscn")

@onready var _path_container = $"HBox/Right/Local/Path"
@onready var _folder_container = $"HBox/Right/Local/Folders"
@onready var _file_container = $"HBox/Right/Local/Files"


# TODO:
# Filesystem Browser
# Local storage browser
# Cloud storage browser (Select which cloud storage to use?)
#
# When spawning something, validate the node before spawning it?
# Some way to quickly get the list? File library?
#

func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_page_opened)

	_initialize_inventory()
	_build_view()
	return


func _handle_page_opened(page_name) -> void:
	if page_name != "Spawnables":
		return

	return

func _initialize_inventory() -> void:
	# Check if the folder exists
	DirAccess.make_dir_recursive_absolute(BASE_DIR)

	return


func _build_view() -> void:
	var _files = DirAccess.get_files_at(BASE_DIR + _current_path())
	var _dirs = DirAccess.get_directories_at(BASE_DIR + _current_path())

	await _clear_view()

	for file in _files:
		var _listing = _create_button(file)
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
	for index in current_dir.size():
		var _path = current_dir[index]
		var _label = Label.new()
		var _listing = _create_button(_path, "", _dir_relocate.bind(index), Vector2(200, 35))

		_label.text = "/"

		_path_container.add_child(_label)
		_path_container.add_child(_listing)
		continue
	return

func _dir_deeper(path: String) -> void:
	current_dir.append(path)
	_build_view()
	return

func _dir_relocate(index: int) -> void:
	current_dir.resize(index + 1)
	_build_view()
	return

func _create_button(name: String, icon: String = "", double_click = null, min_size: Vector2 = Vector2(350, 50)) -> Node:
	var _listing = _template_button.instantiate()
	_listing.set_meta("label", name)
	_listing.selected_icon = icon
	_listing.custom_minimum_size = min_size

	_listing.get_node("Button").toggle_mode = false

	if double_click != null:
		# TODO: Check if double_click param is a function
		_listing.double_clicked.connect(double_click)

	return _listing

func _current_path() -> String:
	return "/".join(current_dir)

func _clear_view() -> void:
	for child in _folder_container.get_children():
		child.queue_free()

	for child in _file_container.get_children():
		child.queue_free()

	for child in _path_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	return


func _create_folder(name: String) -> void:
	return


func _delete_folder(name: String) -> void:
	return

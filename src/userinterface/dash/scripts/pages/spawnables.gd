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
var _selected_folder: Node

@onready var dev_spawn_m = get_tree().current_scene.get_node("DevSpawnManager")
@onready var _path_container = $"HBox/Right/Local/Path"
@onready var _folder_container = $"HBox/Right/Local/Folders"
@onready var _file_container = $"HBox/Right/Local/Files"

@onready var _create_folder_btn = $"HBox/Right/Local/Actions/NewFolder/Button"
@onready var _delete_folder_btn = $"HBox/Right/Local/Actions/DeleteFolder/Button"

@onready var _folder_creation_dialog = $"FolderCreation"

# TODO:
# Filesystem Browser
# Local storage browser
# Cloud storage browser (Select which cloud storage to use?)
#
# When spawning something, validate the node before spawning it?
# Some way to quickly get the list? File library?


func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_page_opened)

	_create_folder_btn.pressed.connect(_open_file_dialog)
	_delete_folder_btn.pressed.connect(_delete_folder)

	_folder_creation_dialog.confirmed.connect(_create_folder)

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
		var _listing = _create_button(file, "", _load_file.bind(file))
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
	dev_spawn_m.load_spawnable(_path)
	return

func _create_button(name: String, icon: String = "", double_click = null, min_size: Vector2 = Vector2(350, 50)) -> Node:
	var _listing = _template_button.instantiate()
	_listing.set_meta("label", name)
	_listing.selected_icon = icon
	_listing.custom_minimum_size = min_size
	_listing.toggle = false

	_listing.get_node("Button").pressed.connect(func(): _selected_folder = _listing)


	if double_click != null:
		# TODO: Check if double_click param is a function
		_listing.double_clicked.connect(double_click)

	return _listing

func _clear_view() -> void:
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
	return

func _delete_folder() -> void:
	# TODO Confirmation before delete
	var _folder_name = _selected_folder.get_meta("label")
	GlobalLogger.log("Deleting folder '%s'" % _folder_name)
	FileManager.delete_folder(_folder_name)
	return

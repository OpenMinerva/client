# --- License
# File: /client/src/scripts/utils/files.gd
# Project: OpenMinerva
# Created Date: 05 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const BASE_SPAWNABLE_DIR = "user://spawnables/"

var spawnables_dir: Array[String] = []


func _ready() -> void:
	_initialize_spawnable_folder()
	return


# Creates a log file following the internal format.
# FIXME: Logger library should handle this.
func create_log_file() -> String:
	GlobalLogger.log("Creating a log file for this session.")
	_maybe_make_directory("user://logs/")
	# TODO: Sanataize param
	# TODO: Error checks
	# TODO: Try to create a different file if one already exists with that name.
	var log_file_name = _get_today_log_file_name()
	var log_file_path = "user://logs/%s.%s" % [ProjectSettings.get_setting("application/config/name"), log_file_name]
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	file.close()
	GlobalLogger.log("Log file '%s' created." % log_file_path)
	return log_file_path


func create_file(dir: String, file_name: String) -> void:
	_maybe_make_directory(dir)
	# TODO: Sanitize name
	var file = FileAccess.open("%s/%s" % [dir, file_name], FileAccess.WRITE)
	GlobalLogger.log("File '%s' created at '%s'." % [file_name, dir])
	file.close()


func get_inv_filelist() -> Dictionary:
	var response = { "files": [], "directories": [] }

	var _files = Database.get_spawnables_by_directory(_current_path())

	response.files = _files
	response.directories = DirAccess.get_directories_at(_current_path())

	return response


func move_inv_deeper(folder: String) -> void:
	# Move to a new folder from the current _maybe_make_directory
	# TODO: Validate folder exists
	spawnables_dir.append(folder)
	return


func move_inv_relocate(target: int) -> void:
	# Relocate the current spawnable file path to a previous position in the path.
	spawnables_dir.resize(target)
	return


func create_folder(folder_name: String = "New Folder") -> void:
	# TODO: Sanatize file name
	DirAccess.make_dir_recursive_absolute(_current_path() + "/%s" % folder_name)
	return


func delete_folder(folder_name: String) -> void:
	# TODO: Sanatize file name
	# TODO: Recursive delete for all files
	DirAccess.remove_absolute(_current_path() + "/%s" % folder_name)
	return


func _maybe_make_directory(dir: String):
	var dir_access = DirAccess.open("user://")
	dir_access.make_dir_recursive(dir)


func _parse_log_file_name(file_name: String) -> Dictionary:
	var date = file_name.split(".")[1].split("-")
	var year = date[0].split("_")[0]
	var month = date[0].split("_")[1]
	var day = date[0].split("_")[2]
	var hour = date[1].split("_")[0]
	var minute = date[1].split("_")[1]
	var second = date[1].split("_")[2]
	var time_dictionary = Time.get_datetime_dict_from_datetime_string("%s-%s-%sT%s:%s:%s" % [year, month, day, hour, minute, second], true)
	return time_dictionary


func _get_today_log_file_name() -> String:
	var current_timestring = Time.get_datetime_string_from_system()
	var file_name = current_timestring.replace("-", "_").replace("T", "-").replace(":", "_")
	return file_name


# TODO: Initialization section to make sure all folders exist.
# Spawnables local file management
func _initialize_spawnable_folder() -> void:
	# Check if the folder exists
	DirAccess.make_dir_recursive_absolute(BASE_SPAWNABLE_DIR)

	return


func _current_path() -> String:
	var _response: String = BASE_SPAWNABLE_DIR + "/".join(spawnables_dir)
	if _response.ends_with("/") == false:
		_response = _response + "/"

	return _response

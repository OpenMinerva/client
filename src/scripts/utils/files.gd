# --- License
# File: /client/src/scripts/utils/files.gd
# Project: OpenMinerva
# Created Date: 05 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node
## This file handles the file system management of the application. If the app needs to read a file or writes a file, it will go through here.

const BASE_SPAWNABLE_DIR = "user://spawnables/"

var spawnables_dir: Array[String] = []


func _ready() -> void:
	_initialize()
	return


# Creates a log file following the internal format.
# FIXME: Logger library should handle this.
func create_log_file() -> String:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
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
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	_maybe_make_directory(dir)
	# TODO: Sanitize name
	var file = FileAccess.open("%s/%s" % [dir, file_name], FileAccess.WRITE)
	GlobalLogger.log("File '%s' created at '%s'." % [file_name, dir])
	file.close()


func get_inv_filelist(directory: String) -> Dictionary:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	var response = { "files": [], "directories": [] }

	var _files = Database.get_spawnables_by_directory(directory)

	response.files = _files
	response.directories = DirAccess.get_directories_at(directory)

	return response


func delete_folder(folder_name: String) -> void:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	# TODO: Sanatize file name
	# TODO: Recursive delete for all files
	DirAccess.remove_absolute(_current_path() + "/%s" % folder_name)
	return


func delete_file(file_path: String) -> void:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	# TODO: Validate that we have a file path and not a directory.
	DirAccess.remove_absolute(file_path)
	return


## This will create a folder at a given directory if it does not already exist.
## [param directory] is the directory to create. Note that "user://" is automatically prefixed.
func create_folder(directory: String) -> void:
	GlobalLogger.log("Trying to make directory 'user://%s'" % directory)
	var dir_access = DirAccess.open("user://")
	dir_access.make_dir_recursive(directory)
	return


## Initialize the file system the application is expecting. This will create all of the base folders.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(BASE_SPAWNABLE_DIR)
	return


func _maybe_make_directory(dir: String):
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	var dir_access = DirAccess.open("user://")
	dir_access.make_dir_recursive(dir)


func _parse_log_file_name(file_name: String) -> Dictionary:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
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
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	var current_timestring = Time.get_datetime_string_from_system()
	var file_name = current_timestring.replace("-", "_").replace("T", "-").replace(":", "_")
	return file_name


func _current_path() -> String:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	var _response: String = BASE_SPAWNABLE_DIR + "/".join(spawnables_dir)
	if _response.ends_with("/") == false:
		_response = _response + "/"

	return _response

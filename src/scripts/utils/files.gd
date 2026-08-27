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

## The base directory on the file system where spawnables live.
const BASE_SPAWNABLE_DIR = "user://spawnables/"


func _ready() -> void:
	_initialize()
	return


## Creates a file on the file system
## [param directory] is the directory of the file to create. Note that there is not a prefix and can write anywhere on the file system.
func create_file(directory: String) -> void:
	var _base_dir: String = directory.get_base_dir()
	var _file_name: String = directory.get_basename()

	# TODO: Validate that file does not already exist.

	create_folder(_base_dir.get_base_dir())
	var file = FileAccess.open(directory, FileAccess.WRITE)
	file.close()

	GlobalLogger.log("File '%s' created at '%s'." % [_file_name, _base_dir])
	return


## Get a list of all available directories from a given [param path].
## [param path] is the path to look in and return a list of folders. Note that there is not a prefix and can look anywhere on the file system.
func list_directories(path: String) -> Array:
	GlobalLogger.log("Listing directories at '%s'." % path)
	# TODO: Validate path exists.
	return DirAccess.get_directories_at(path)


## Delete a folder from a directory.
## [param directory] is the directory of the folder to create. Note that there is not a prefix and can remove any folder on the file system.
# TODO: Make function recursively delete files in a folder if desired.
func delete_folder(directory: String, _recursive: bool = false) -> void:
	DirAccess.remove_absolute(directory)
	GlobalLogger.log("Removed folder '%s'" % directory)
	return


## Opens a file on the file system. 
## [param directory] is the directory of the file to open. Note that there is not a prefix and can open any file on the file system.
func open(directory: String) -> FileAccess:
	# TODO: Validate file exists.
	var _file: FileAccess = FileAccess.open(directory, FileAccess.WRITE)
	GlobalLogger.log("File '%s' opened." % directory)
	return _file


## Checks to see if a file exists on the file system.
## [param directory] is the directory of the file to check. Note that there is not a prefix and can check any file on the file system.
func file_exists(directory: String) -> bool:
	GlobalLogger.log("Checking if '%s' exists on the file system.")
	return FileAccess.file_exists(directory)


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


## Initialize the file system the application is expecting. This will create all of the base folders and set up the file system environment.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(BASE_SPAWNABLE_DIR)
	return

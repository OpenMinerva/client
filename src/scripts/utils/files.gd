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
## Some functions are named after their intended operation (example: `open`) as they are either agnostic of, or targeted towards specifically files OR folders. Other functions are named more specifically (example: `list_directories`, `delete_folder`) as they work for a specific file type.
## These differences in generality are intentional and are done in some instances to better describe the intent of the action that is desired to be preformed at execution time.

## The base directory on the file system where spawnables live.
const BASE_SPAWNABLE_DIR = "user://spawnables/"

## Contains all of the file access mode flags in a string format for logging purposes.
var _fileaccess_modeflags: Array = ClassDB.class_get_enum_constants("FileAccess", "ModeFlags")


func _ready() -> void:
	_initialize()
	return


## Creates a file on the file system
## [param path] is the path of the file to create. Note that there is not a prefix and can write anywhere on the file system.
func create_file(path: String) -> void:
	var _base_dir: String = path.get_base_dir()
	var _file_name: String = path.get_file()

	if file_exists(path) == true:
		GlobalLogger.log("File '%s' exists already, not creating." % path)
		return

	create_directory(_base_dir)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.close()

	GlobalLogger.log("File '%s' created at '%s'." % [_file_name, _base_dir])
	return


## Delete a file from the file system.
## [param path] is the path of the file on the file system.
func delete_file(path: String) -> void:
	if file_exists(path) == false:
		GlobalLogger.log("File '%s' does not exist, not removing." % path)
		return

	DirAccess.remove_absolute(path)
	return


## Opens a file on the file system. 
## [param path] is the path of the file to open. Note that there is not a prefix and can open any file on the file system.
func open(path: String, mode: FileAccess.ModeFlags = FileAccess.READ) -> FileAccess:
	if file_exists(path) == false:
		GlobalLogger.log("File '%s' does not exist, not opening." % path)
		return null

	var _file: FileAccess = FileAccess.open(path, mode)
	if _file != null:
		GlobalLogger.log("File '%s' opened in mode '%s'." % [path, _fileaccess_modeflags[mode]])
		return _file

	GlobalLogger.log("File '%s' was not opened due to an error." % [path], Enum.LogLevel.WARNING)
	return null


## Checks to see if a file exists on the file system.
## [param path] is the path of the file to check. Note that there is not a prefix and can check any file on the file system.
func file_exists(path: String) -> bool:
	GlobalLogger.log("Checking if '%s' exists on the file system.")
	return FileAccess.file_exists(path)


## Checks to see if a directory exists on the file system.
## [param path] is the path of the directory to check. Note that there is not a prefix and can check any file on the file system.
func directory_exists(path: String) -> bool:
	GlobalLogger.log("Checking if '%s' exists on the file system.")
	return DirAccess.dir_exists_absolute(path)


## Get a list of all available directories from a given [param path].
## [param path] is the path to look in and return a list of folders. Note that there is not a prefix and can look anywhere on the file system.
func list_directories(path: String) -> Array:
	GlobalLogger.log("Listing directories at '%s'." % path)

	if directory_exists(path) == false:
		GlobalLogger.log("Directory '%s' does not exist." % path)
		return []

	return DirAccess.get_directories_at(path)


## Delete a directory.
## [param path] is the directory of the directory to delete. Note that there is not a prefix and can remove any folder on the file system.
# TODO: Make function recursively delete files in a folder if desired.
func delete_directory(path: String) -> void:
	if directory_exists(path) == false:
		GlobalLogger.log("Directory '%s' does not exist, not removing." % path)
		return

	DirAccess.remove_absolute(path)
	GlobalLogger.log("Removed directory '%s'" % path)
	return


## This will create a folder at a given directory if it does not already exist.
## [param path] is the path to create. Note that there is not a prefix and can create a directory anywhere on the file system.
func create_directory(path: String) -> void:
	GlobalLogger.log("Trying to make directory '%s'" % path)
	DirAccess.make_dir_recursive_absolute(path)
	return


## Initialize the file system the application is expecting. This will create all of the base folders and set up the file system environment.
func _initialize() -> void:
	create_directory(BASE_SPAWNABLE_DIR)
	return

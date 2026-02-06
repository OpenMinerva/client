extends Node

## Create a config file at a given relative directory.
## Example: /system/cool.json
## @returns void
func create_config_file(dir: String, file_name: String) -> void:
	var config = ConfigFile.new()
	GlobalLogger.logs("Creating '%s/%s'" % [dir, file_name], 0)
	_maybe_make_directory("user://config/")
	# TODO: Sanataize param
	# TODO: Error checks
	var dir_access = DirAccess.open("user://config/")
	dir_access.make_dir_recursive("user://config/%s" % dir)
	var err = config.save("user://config/%s/%s" % [dir, file_name])
	if err != OK:
		GlobalLogger.logs("Failed to create config file! '%s'" % err, 3)
	return

## Read a config file from a directory.
## Example: /system/cool.json
## @returns String
func read_config_file(dir: String, file_name: String) -> Variant:
	var config = ConfigFile.new()
	# TODO: Error checks
	GlobalLogger.logs("Reading '%s'" % dir, 0)
	dir = "user://config/%s" % dir
	# var file_contents = FileAccess.open(dir, FileAccess.READ).get_as_text()
	var file_contents = config.load("%s/%s" % [dir, file_name])

	if file_contents != OK:
		return

	return config

## Creates a log file following the internal format.
## @returns String - Directory of the log file.
func create_log_file() -> String:
	GlobalLogger.logs("Creating a log file for this session.", 0)
	_maybe_make_directory("user://logs/")
	# TODO: Sanataize param
	# TODO: Error checks
	# TODO: Try to create a different file if one already exists with that name.
	var log_file_name = _get_today_log_file_name()
	var log_file_path = "user://logs/%s.%s" % [ProjectSettings.get_setting("application/config/name"), log_file_name]
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	file.close()
	GlobalLogger.logs("Log file '%s' created." % log_file_path, 0)
	return log_file_path

func create_client_file(_dir: String) -> void:
	# Create a file to store in-game user data. This is for in-game data storage!
	# IMPORTANT: DO NOT STORE PRIVATE DATA IN THIS DIRECTORY AS IT IS INTENDED TO BE READ AND WRITTEN TO FREELY!
	GlobalLogger.logs("Not implemented.", 3)
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

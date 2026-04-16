extends Node

## Creates a log file following the internal format.
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

func create_file(dir: String, name: String) -> void:
	_maybe_make_directory(dir)
	# TODO: Sanitize name
	var file = FileAccess.open("%s/%s" % [dir, name], FileAccess.WRITE)
	GlobalLogger.logs("File '%s' created at '%s'." % [name, dir], 0)
	file.close()

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

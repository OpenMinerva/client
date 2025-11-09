# This library provides an interface for file handling
# This handles housekeeping related to files including file creation, deletion, and some modifications.

extends Node

# TODO: Every 7 days, zip all log files and compress them. Delete the original files.
# TODO: After zip file is a month old, delete it.

func log_file_exists() -> bool:
	var args = LaunchManager.get_command_line_args()
	var today_log_filename = get_today_log_file_name()
	var docs_path = OS.get_user_data_dir()
	var does_log_file_exist = FileAccess.file_exists("%s/logs/%s.%s" % [docs_path, args.name, today_log_filename])
	return does_log_file_exist

func get_today_log_file_name() -> String:
	var current_timestring = Time.get_datetime_string_from_system()
	return sanitize_log_file_name(current_timestring)

func sanitize_log_file_name(file_name: String) -> String:
	return file_name.replace("-", "_").replace("T", "-").replace(":", "_")

func parse_log_file_name(file_name: String) -> Dictionary:
	var date = file_name.split(".")[1].split("-")
	var year = date[0].split("_")[0]
	var month = date[0].split("_")[1]
	var day = date[0].split("_")[2]
	var hour = date[1].split("_")[0]
	var minute = date[1].split("_")[1]
	var second = date[1].split("_")[2]
	var time_dictionary = Time.get_datetime_dict_from_datetime_string("%s-%s-%sT%s:%s:%s" % [year, month, day, hour, minute, second], true)
	return time_dictionary

func create_log_file() -> String:
	var args = LaunchManager.get_command_line_args()
	var today_log_filename = get_today_log_file_name()
	var docs_path = OS.get_user_data_dir()
	var path = "%s/logs/%s.%s" % [docs_path, args.name, today_log_filename]
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.close()
	return path

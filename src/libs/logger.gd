extends Node

var console_logging_enabled = true
var file_logging_enabled = true
var log_file : FileAccess
var log_file_initialized = false
var log_file_path = ""

var log_level_colors = {
	0: "lightblue",
	1: "green",
	2: "yellow",
	3: "red"
}
var log_level_names = {
	0: "Debug",
	1: "Info",
	2: "Warning",
	3: "Error"
}

func _ready():
	_initialize_log_file()
	set_console_logging(true)
	set_file_logging(true)
	log_string("Logger initialized")

func _initialize_log_file():
	if not FileManager.log_file_exists():
		log_file_path = FileManager.create_log_file()
		log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
		log_file_initialized = true
		log_string("Opened log file at %s" % log_file_path, 0)
		return

## Logs a message to both file and console (if enabled).
## @param message: The message string to log. If omitted, defaults to an empty string.
## @param level: The log level indicating the severity. Must be an integer:
##   0 -> Debug
##   1 -> Info
##   2 -> Warning
##   3 -> Error
##   Defaults to 0 (Debug).
func log_string(message: String = "", level: int = 0):
	_log_to_file(message, level)

	if console_logging_enabled:
		print_rich("[[color=%s]%s[/color]] %s" % [log_level_colors[level], log_level_names[level], message])
	pass

func _log_to_file(message: String = "", level: int = 0):
	if file_logging_enabled:
		var formatted_log = "[%s] %s" % [log_level_names[level], message]
		log_file.store_line(formatted_log)
		log_file.flush()

func set_console_logging(enabled: bool):
	if enabled:
		console_logging_enabled = true
		log_string("Console logging enabled for this session.", 1)
	else:
		console_logging_enabled = false
		log_string("Console logging disabled for this session.", 1)

func set_file_logging(enabled: bool):
	if enabled:
		file_logging_enabled = true
		log_string("File logging enabled for this session.", 1)
	else:
		file_logging_enabled = false
		log_string("File logging disabled for this session.", 1)

extends Node

var console_logging_enabled: bool = true
var file_logging_enabled: bool = true
var log_file: FileAccess
var log_file_initialized = false
var log_file_path = ""
var log_level_colors = {
	0: "lightblue",
	1: "green",
	2: "yellow",
	3: "red",
}
var log_level_names = {
	0: "Debug",
	1: "Info",
	2: "Warning",
	3: "Error",
}


func _ready():
	var launch_arguments: Dictionary = LaunchArguments.get_command_line_args()
	console_logging_enabled = !launch_arguments.has("console_log") || launch_arguments.console_log == "True"
	file_logging_enabled = !launch_arguments.has("file_log") || launch_arguments.file_log == "True"
	_initialize_log_file()
	set_console_logging(true)
	set_file_logging(true)
	self.log("Logger initialized")


## Logs a message to both file and console (if enabled).
## @param message: The message string to log. If omitted, defaults to an empty string.
## @param level: The log level indicating the severity. Must be an integer:
func log(message: String = "", level: Enum.LogLevel = Enum.LogLevel.DEBUG):
	_log_to_file(message, level)

	if console_logging_enabled:
		var stack := get_stack()
		print_rich("[[color=%s]%s[/color]] %s [[color=lightyellow]%s[/color]]" % [log_level_colors[level], log_level_names[level], message, stack[1]["function"]])
		if level == 3:
			# We are skipping the first frame, otherwise this function will be logged.
			for i in range(1, stack.size()):
				var frame = stack[i]
				print(
					"%s:%d @ %s()" % [
						frame.source,
						frame.line,
						frame.function,
					],
				)
	pass


func set_console_logging(enabled: bool):
	if enabled:
		console_logging_enabled = true
		self.log("Console logging enabled for this session.", Enum.LogLevel.INFO)
	else:
		console_logging_enabled = false
		self.log("Console logging disabled for this session.", Enum.LogLevel.INFO)


func set_file_logging(enabled: bool):
	if enabled:
		file_logging_enabled = true
		self.log("File logging enabled for this session.", Enum.LogLevel.INFO)
	else:
		file_logging_enabled = false
		self.log("File logging disabled for this session.", Enum.LogLevel.INFO)


func _initialize_log_file():
	log_file_path = FileManager.create_log_file()
	log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	log_file_initialized = true
	self.log("Opened log file at %s" % log_file_path)


func _log_to_file(message: String = "", level: int = 0):
	if file_logging_enabled && log_file:
		var formatted_log = "[%s] %s" % [log_level_names[level], message]
		log_file.store_line(formatted_log)
		log_file.flush()

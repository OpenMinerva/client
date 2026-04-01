extends Node

const MONTH_MAP = {
	"Jan": 1,
	"Feb": 2,
	"Mar": 3,
	"Apr": 4,
	"May": 5,
	"Jun": 6,
	"Jul": 7,
	"Aug": 8,
	"Sep": 9,
	"Oct": 10,
	"Nov": 11,
	"Dec": 12
}

func convert_jwt_timestamp_to_unix(timestamp: String) -> int:
	var _split = timestamp.split(" ")
	var _time_split = _split[4].split(":")

	var datetime_dict = {
		"year": _split[3].to_int(),
		"month": MONTH_MAP.get(_split[2], 1),
		"day": _split[1].to_int(),
		"hour": _time_split[0].to_int(),
		"minute": _time_split[1].to_int(),
		"second": _time_split[2].to_int()
	}

	var unix_timestamp = Time.get_unix_time_from_datetime_dict(datetime_dict)
	return unix_timestamp
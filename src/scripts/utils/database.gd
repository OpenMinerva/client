# --- License
# File: /client/src/scripts/utils/database.gd
# Project: OpenMinerva
# Created Date: 05 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const DATABASE_PATH: String = "user://spawnable_database.db"

var _db: SQLite = SQLite.new()


func _ready() -> void:
	_db.path = DATABASE_PATH

	# Ensure Database it set up
	if _database_exists() == false:
		GlobalLogger.log("Could not open the spawnable database", Enum.LogLevel.ERROR)
		# Since this is a critical error, I should probably display an error window before force-closing the app?
		return

	_build_database_schema()

	# Preform sanity check to ensure database is not corrupted. Or that it has not changed from when we last changed it.
	# Should we hash the database on close, then read the hash on open to ensure not-corrupted / changed?
	# If there was a difference, would we need to rebuild the database? What would that look like? Sounds expensive!
	return


func _exit_tree() -> void:
	_db.close_db()
	return


func get_spawnable(item_hash: String) -> Dictionary:
	_db.query("SELECT * FROM spawnable WHERE hash = '%s'" % item_hash)

	if _db.query_result.is_empty():
		GlobalLogger.log("[ Database ] Spawnable '%s' does not exist." % item_hash, Enum.LogLevel.DEBUG)
		return { }

	return _db.query_result[0]


func get_spawnables_by_directory(directory: String) -> Array:
	var _query: String = "SELECT * FROM spawnable WHERE directory LIKE ? AND directory NOT LIKE ?"

	_db.query_with_bindings(_query, [directory + "%", directory + "%/%"])

	return _db.query_result


func set_spawnable(item_hash: String, new_data: Dictionary) -> bool:
	GlobalLogger.log("[ Database ] Updating spawnable '%s'." % item_hash, Enum.LogLevel.DEBUG)
	var _success: bool = _db.insert_row("spawnable", new_data)
	return _success


func delete_spawnable(item_hash: String) -> bool:
	var _asset_deletion_queue: Array = []
	var _assets: Array = get_spawnable_assets(item_hash)

	for _single_asset in _assets:
		if is_asset_used_by_one_spawnable(_single_asset) == true:
			_asset_deletion_queue.append(_single_asset)

	for _orphan_asset in _asset_deletion_queue:
		FileManager.delete_file("user://spawnables_assets/%s.res" % _orphan_asset)
		delete_asset(_orphan_asset)

	var _success: bool = _db.delete_rows("spawnable", "hash = '%s'" % item_hash)
	_db.delete_rows("spawnable_asset_rel", "spawnable = '%s'" % item_hash)

	return _success


func get_asset(hash: String) -> Dictionary:
	# TODO: Use query bindings?
	GlobalLogger.log("[ Database ] Getting asset '%s'." % hash, Enum.LogLevel.DEBUG)
	_db.query("SELECT * FROM asset WHERE hash = '%s'" % hash)

	if _db.query_result.is_empty():
		GlobalLogger.log("[ Database ] Asset '%s' does not exist." % hash, Enum.LogLevel.DEBUG)
		return { }

	return _db.query_result[0]


func set_asset(item_hash: String, new_data: Dictionary) -> bool:
	# TODO: Validation before inserting into the database.
	GlobalLogger.log("[ Database ] Updating asset '%s'." % item_hash, Enum.LogLevel.DEBUG)
	var _success: bool = _db.insert_row("asset", new_data)
	return _success


func delete_asset(asset_hash: String) -> bool:
	var _success: bool = _db.delete_rows("asset", "hash = '%s'" % asset_hash)

	return _success


func set_spawnable_asset_rel(item_hash: String, asset_hash: String) -> bool:
	GlobalLogger.log("[ Database ] Adding item relationship '%s' to '%s'." % [item_hash, asset_hash], Enum.LogLevel.DEBUG)

	var new_data: Dictionary = { "spawnable": item_hash, "asset": asset_hash }
	var _success: bool = _db.insert_row("spawnable_asset_rel", new_data)

	return _success


func get_spawnable_assets(item_hash: String) -> Array:
	var _query_success = _db.query("SELECT * FROM spawnable_asset_rel WHERE spawnable = '%s'" % item_hash)
	var _assets = _db.query_result
	return _assets.map(func(entry): return entry.asset)


func is_asset_used_by_one_spawnable(asset_hash: String) -> bool:
	var _query_success = _db.query("SELECT * FROM spawnable_asset_rel WHERE asset = '%s'" % asset_hash)

	var _spawnables = _db.query_result
	return _spawnables.size() == 1


func _database_exists() -> bool:
	var _is_open = _db.open_db()
	return _is_open


func _build_database_schema() -> void:
	_db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='spawnable'")

	if _db.query_result.is_empty():
		GlobalLogger.log("The database table does not exist, this probably means the database was not initialized. Adding the tables now.")

		var _spawnable_table: Dictionary = Dictionary()
		_spawnable_table = {
			"hash": { "data_type": "text", "primary_key": true, "unique": true },
			"name": { "data_type": "text", "not_null": true },
			"thumbnail": { "data_type": "text" },
			"directory": { "data_type": "text", "not_null": true },
			"original_owner": { "data_type": "text" },
			"creation_date": { "data_type": "int", "default": -1 },
			"modified_date": { "data_type": "int", "default": -1 },
			"type": { "data_type": "int", "default": -1 },
		}

		var _asset_table: Dictionary = Dictionary()
		_asset_table = {
			"hash": { "data_type": "text", "primary_key": true, "unique": true },
			"size": { "data_type": "int", "default": -1 },
			"directory": { "data_type": "text" },
			"type": { "data_type": "int", "default": -1 },
		}

		var _spawnable_asset_rel_table: Dictionary = Dictionary()
		_spawnable_asset_rel_table = {
			"spawnable": { "data_type": "text" },
			"asset": { "data_type": "text" },
		}

		_db.create_table("spawnable", _spawnable_table)
		_db.create_table("asset", _asset_table)
		_db.create_table("spawnable_asset_rel", _spawnable_asset_rel_table)

		return

	GlobalLogger.log("[ Database ] Database tables exist.", Enum.LogLevel.DEBUG)
	return

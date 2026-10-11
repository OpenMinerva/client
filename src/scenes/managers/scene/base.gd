# --- License
# File: /client/src/scenes/manager/scene/base.gd
# Project: OpenMinerva
# Created Date: 01 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node3D

const MANAGER_TYPE = {
	SPAWNABLE = "SpawnableManager",
	NETWORK = "NetworkManager",
	PLAYER = "PlayerManager",
	SIGNAL_BUS = "SignalBus",
	RPC = "RpcAwaiter",
}

var is_ready: bool = false


func _ready():
	is_ready = true
	return


func get_manager(manager: String) -> Node:
	var _found_manager_node: Node = get_node_or_null(manager)
	return _found_manager_node

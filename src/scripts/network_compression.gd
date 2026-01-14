extends Node

# TODO: Positional data can further be reduced by using raw bytes instead of the given 16 bits. Maybe shoot for 10 bytes?

## Compresses a Vector3 to a PackedByteArray using 32 bit precision
## @returns PackedByteArray
func c_32_vec3(provided_data: Vector3) -> PackedByteArray:
	var data = PackedByteArray()
	data.resize(12)
	data.encode_s32(0, _float_to_int(provided_data.x))
	data.encode_s32(4, _float_to_int(provided_data.y))
	data.encode_s32(8, _float_to_int(provided_data.z))

	return data

## Decompress a PackedByteArray to a Vector3 using 32 bit precision 
## @returns Vector3
func d_32_vec3(provided_data: PackedByteArray) -> Vector3:
	# Validate array size
	if provided_data.size() < 12:
		GlobalLogger.log_string("'%s' contained invalid PackedByteArray size. Can not decode value.", 2)
		return Vector3()

	var x = _int_to_float(provided_data.decode_s32(0))
	var y = _int_to_float(provided_data.decode_s32(4))
	var z = _int_to_float(provided_data.decode_s32(8))

	return Vector3(x, y, z)

## Compresses a Vector3 to a PackedByteArray using 16 bit precision
## @returns PackedByteArray
func c_16_vec3(provided_data: Vector3) -> PackedByteArray:
	var data = PackedByteArray()
	data.resize(6)
	data.encode_s16(0, _float_to_int(provided_data.x))
	data.encode_s16(2, _float_to_int(provided_data.y))
	data.encode_s16(4, _float_to_int(provided_data.z))

	return data

## Decompress a PackedByteArray to a Vector3 using 16 bit precision 
## @returns Vector3
func d_16_vec3(provided_data: PackedByteArray) -> Vector3:
	# Validate array size
	if provided_data.size() < 6:
		GlobalLogger.log_string("'%s' contained invalid PackedByteArray size. Can not decode value.", 2)
		return Vector3()

	var x = _int_to_float(provided_data.decode_s16(0))
	var y = _int_to_float(provided_data.decode_s16(2))
	var z = _int_to_float(provided_data.decode_s16(4))

	return Vector3(x, y, z)

## Compresses a user position with octree position to a PackedByteArray using 32 bit precision
## @returns PackedByteArray
func c_32_pos(provided_data: Vector3) -> PackedByteArray:
	const OCTREE_OCTANT_SIZE: int = 1000

	# Get the octree position
	# HINT: o_x = octree_x_position
	# FIXME: Unsure if we even need to round, or if this is the correct operation
	var o_x = int(provided_data.x / OCTREE_OCTANT_SIZE)
	var o_y = int(provided_data.y / OCTREE_OCTANT_SIZE)
	var o_z = int(provided_data.z / OCTREE_OCTANT_SIZE)

	# HINT: octree_compressed_position
	# var o_c_pos = c_32_vec3(Vector3(o_x, o_y, o_z))

	# Get the position in that octree
	# HINT: i_x = internal_x_position
	var i_x = _float_to_int(fmod(provided_data.x, OCTREE_OCTANT_SIZE))
	var i_y = _float_to_int(fmod(provided_data.y, OCTREE_OCTANT_SIZE))
	var i_z = _float_to_int(fmod(provided_data.z, OCTREE_OCTANT_SIZE))

	# var i_c_pos = c_32_vec3(Vector3(i_x, i_y, i_z))

	# HINT: packed_compressed_position
	# FIXME: Appending the array does not work for some reason. Try and figure that out
	var p_c_pos = PackedByteArray()
	p_c_pos.resize(24)
	p_c_pos.encode_s32(0, o_x)
	p_c_pos.encode_s32(4, o_y)
	p_c_pos.encode_s32(8, o_z)
	p_c_pos.encode_s32(12, i_x)
	p_c_pos.encode_s32(16, i_y)
	p_c_pos.encode_s32(20, i_z)

	return p_c_pos

## Decompress a user position with octree position to a Vector3 using 32 bit precision
## @returns Vector3
func d_32_pos(provided_data: PackedByteArray) -> Vector3:
	# NOTE: See compression function for variable name hints.
	const OCTREE_OCTANT_SIZE: int = 1000

	var o_x = provided_data.decode_s32(0)
	var o_y = provided_data.decode_s32(4)
	var o_z = provided_data.decode_s32(8)

	var i_x = _int_to_float(provided_data.decode_s32(12))
	var i_y = _int_to_float(provided_data.decode_s32(16))
	var i_z = _int_to_float(provided_data.decode_s32(20))

	var g_pos_x = (float(o_x) * OCTREE_OCTANT_SIZE) + i_x
	var g_pos_y = (float(o_y) * OCTREE_OCTANT_SIZE) + i_y
	var g_pos_z = (float(o_z) * OCTREE_OCTANT_SIZE) + i_z

	var global_position = Vector3(g_pos_x, g_pos_y, g_pos_z)

	return global_position

## Compresses a user position with octree position to a PackedByteArray using 16 bit precision
## @returns PackedByteArray
func c_16_pos(provided_data: Vector3) -> PackedByteArray:
	const OCTREE_OCTANT_SIZE: int = 1000

	var o_x = int(provided_data.x / OCTREE_OCTANT_SIZE)
	var o_y = int(provided_data.y / OCTREE_OCTANT_SIZE)
	var o_z = int(provided_data.z / OCTREE_OCTANT_SIZE)

	var i_x = _float_to_int(fmod(provided_data.x, OCTREE_OCTANT_SIZE))
	var i_y = _float_to_int(fmod(provided_data.y, OCTREE_OCTANT_SIZE))
	var i_z = _float_to_int(fmod(provided_data.z, OCTREE_OCTANT_SIZE))

	var p_c_pos = PackedByteArray()
	p_c_pos.resize(12)
	p_c_pos.encode_s16(0, o_x)
	p_c_pos.encode_s16(2, o_y)
	p_c_pos.encode_s16(4, o_z)
	p_c_pos.encode_s16(6, i_x)
	p_c_pos.encode_s16(8, i_y)
	p_c_pos.encode_s16(10, i_z)

	return p_c_pos

## Decompress a user position with octree position to a Vector3 using 16 bit precision
## @returns Vector3
func d_16_pos(provided_data: PackedByteArray) -> Vector3:
	# NOTE: See compression function for variable name hints.
	const OCTREE_OCTANT_SIZE: int = 1000

	var o_x = provided_data.decode_s16(0)
	var o_y = provided_data.decode_s16(2)
	var o_z = provided_data.decode_s16(4)

	var i_x = _int_to_float(provided_data.decode_s16(6))
	var i_y = _int_to_float(provided_data.decode_s16(8))
	var i_z = _int_to_float(provided_data.decode_s16(10))

	var g_pos_x = (float(o_x) * OCTREE_OCTANT_SIZE) + i_x
	var g_pos_y = (float(o_y) * OCTREE_OCTANT_SIZE) + i_y
	var g_pos_z = (float(o_z) * OCTREE_OCTANT_SIZE) + i_z

	var global_position = Vector3(g_pos_x, g_pos_y, g_pos_z)

	return global_position

func _float_to_int(val: float) -> int:
	const FLOAT_PRECISION: int = 1000
	return int(val * FLOAT_PRECISION)

func _int_to_float(val: int) -> float:
	const FLOAT_PRECISION: int = 1000
	return float(val) / FLOAT_PRECISION
# --- License
# File: /client/src/scrips/libs/models.gd
# Project: OpenMinerva
# Created Date: 25 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name ModelHandling

static var global_logger = GlobalLogger


static func get_glb_assets(file_path: String) -> String:
	global_logger.log("Deconstructing '%s' into assets" % file_path)
	var cache_dir = OS.get_cache_dir()

	var app_cache_dir = cache_dir.path_join("OpenMinerva/")
	DirAccess.make_dir_absolute(app_cache_dir)

	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var error = gltf_doc.append_from_file(file_path, gltf_state)

	var manifest = gltf_state.json.duplicate()

	manifest.base_path = app_cache_dir
	manifest["images"] = []

	if error != OK:
		print("Error loading GLB: ", error)

	var gltf_extracted_images = extract_images(gltf_state, app_cache_dir + 'images/')
	for image_id in range(gltf_extracted_images.size()):
		manifest["images"].append(gltf_extracted_images[image_id])

	var gltf_extracted_meshes = extract_meshes(gltf_state, app_cache_dir + 'meshes/')
	manifest.buffers[0]["uri"] = '../meshes/' + gltf_extracted_meshes + ".bin"
	DirAccess.make_dir_absolute(app_cache_dir + 'gltf')

	# HACK: Force WEBP extensions in the gltf file.
	manifest["extensionsRequired"] = ["EXT_texture_webp"]
	manifest["extensionsUsed"] = ["EXT_texture_webp"]

	var gltf_hash = JSON.stringify(manifest).sha256_text()
	var gltf_manifest_path = app_cache_dir + "gltf/%s.gltf" % gltf_hash

	var file = FileAccess.open(gltf_manifest_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t", true))
	file.close()
	return gltf_manifest_path


static func extract_images(gltf_state: GLTFState, path_root: String) -> Array:
	var response_images = []
	DirAccess.make_dir_absolute(path_root)

	for img_idx in range(gltf_state.get_images().size()):
		var image_entry = gltf_state.get_images()[img_idx]
		var image = image_entry.get_image()
		var img_hash = hash_image_sha256_hex(image)
		var img_path = path_root + img_hash + ".webp"
		image.save_webp(img_path, false, 0.85)

		response_images.append(
			{
				"hash": img_hash,
				"uri": '../images/' + img_hash + ".webp",
				"format": image.get_format(),
			},
		)
	return response_images


static func extract_meshes(gltf_state: GLTFState, path_root: String) -> String:
	var return_array = []

	var buffers = gltf_state.get_buffers()
	var buffer_hash = hash_buffer_sha256_hex(buffers)
	var bin_path = path_root + "/%s.bin" % buffer_hash
	DirAccess.make_dir_absolute(path_root)

	var file = FileAccess.open(bin_path, FileAccess.WRITE)

	for buffer in buffers:
		file.store_buffer(buffer)

	file.close()
	return buffer_hash


# TODO: Validate that this creates a good hash
static func hash_buffer_sha256_hex(buffers) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for surface in buffers:
		ctx.update(surface)

	return ctx.finish().hex_encode()


static func hash_image_sha256_hex(image: Image) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	var image_data = image.get_data()
	ctx.update(image_data)

	return ctx.finish().hex_encode()

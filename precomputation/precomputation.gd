@tool class_name Precomputation extends Node

func gaussian_pdf (x : float) -> float:
	return exp(-(x*x) / 2.0) / sqrt(2.0 * PI)

const exemplar_size : int = 512
const exemplar_frequency : float = 10.0
const kernel_size : int = 256
@warning_ignore("unused_private_class_variable")
@export_tool_button("Compute phase exemplar") var _compute_exemplar = func () :
	var exemplar = Image.create_empty(exemplar_size, exemplar_size, true, Image.FORMAT_RGF)
	for kernel in 256:
		var offset = Vector2i(randi_range(0, exemplar_size), randi_range(0, exemplar_size))
		var random_phase = randf() * 2.0 * PI
		for x in kernel_size:
			for y in kernel_size:
				var position = (offset + Vector2i(x, y)) % exemplar_size
				var pixel = exemplar.get_pixelv(position)
				
				var radius = kernel_size / 2.0
				var distance_from_center = (Vector2(x, y) / radius - Vector2.ONE).length()
				var w = gaussian_pdf(distance_from_center * 3.0)
				var distance_x = (float(x) / float(exemplar_size)) * exemplar_frequency
				pixel.r += w * sin(distance_x * 2.0 * PI + random_phase)
				pixel.g += w * cos(distance_x * 2.0 * PI + random_phase)
				
				exemplar.set_pixelv(position, pixel)
	exemplar.save_exr("textures/exemplar.exr")
	
	$ExemplarPreview.texture = ImageTexture.create_from_image(exemplar)


const profile_size : int = 512
@warning_ignore("unused_private_class_variable")
@export_tool_button("Compute profile map") var _compute_profile_map = func () :
	var profile_map = Image.create_empty(profile_size, profile_size, true, Image.FORMAT_RF)
	
	for x in profile_size:
		for y in profile_size:
			var radius = profile_size / 2.0
			var position = Vector2(x, y) / radius - Vector2.ONE
			var target_phase = atan2(position.x, position.y)
			var profile = position.limit_length(1.0).length()
			
			var current_phase = target_phase
			var l = PI * 0.5
			for iter in 128:
				var phase = current_phase + cos(current_phase) * profile
				if phase > target_phase:
					current_phase -= l
				else:
					current_phase += l
				l /= 2.0
			profile_map.set_pixel(x, y, Color(sin(current_phase) * profile, 0, 0, 1))
	
	profile_map.save_exr("textures/profile.exr")
	
	$ProfilePreview.texture = ImageTexture.create_from_image(profile_map)

shader_type spatial;

#include "includes/ocean.gdshaderinc"

uniform float wavelengths[WAVE_TRAINS_COUNT];
uniform sampler2D orientation : filter_linear, repeat_disable;
uniform sampler2D profile : filter_linear, repeat_disable;
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv, float time) {
	// remaps the world uv [-128, 128] to [0, 1] for the texture fetches
	uv += 128.0;
	uv /= 256.0;
	
	wave_train_query queries[WAVE_TRAINS_COUNT];
	
	// The diffraction effect is reproduced by having a spatially varying orientation and profile. (see orientation_diffraction.png and profile_diffraction.png)
	for (int i = 0; i < PRIMARY_WAVE_TRAINS; i++) {
		queries[i].wavelength = wavelengths[i];
		queries[i].orientation = texture(orientation, uv).r * 2.0 * PI - 0.5 * PI;
		queries[i].profile = texture(profile, uv).r;
	}
	
	// No effects
	for (int i = 0; i < SECONDARY_WAVE_TRAINS; i++) {
		queries[PRIMARY_WAVE_TRAINS + i].wavelength = 1.0;
		queries[PRIMARY_WAVE_TRAINS + i].orientation = 0.0;
		queries[PRIMARY_WAVE_TRAINS + i].profile = 0.0;
	}
	
	return queries;
}

#define CUSTOM_QUERIES
#include "render_ocean.gdshaderinc"
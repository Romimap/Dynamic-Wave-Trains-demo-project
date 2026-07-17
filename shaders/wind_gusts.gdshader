shader_type spatial;

#include "includes/ocean.gdshaderinc"

uniform float wavelengths[PRIMARY_WAVE_TRAINS];
uniform float orientations[PRIMARY_WAVE_TRAINS];
uniform float profiles[PRIMARY_WAVE_TRAINS];
uniform sampler2D wind_strength : filter_linear, repeat_enable;
uniform float wind_speed : hint_range(0.1, 0.8, 0.001) = 0.5;
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv, float time) {
	// remaps the world uv [-128, 128] to [0, 1] for the texture fetches
	uv += 128.0;
	uv /= 256.0;
	
	wave_train_query queries[WAVE_TRAINS_COUNT];
	
	for (int i = 0; i < PRIMARY_WAVE_TRAINS; i++) {
		queries[i].wavelength = wavelengths[i];
		queries[i].orientation = orientations[i];
		queries[i].profile = profiles[i];
	}
	
	// Inits the secondary wave trains
	for (int i = 0; i < SECONDARY_WAVE_TRAINS; i++) {
		queries[PRIMARY_WAVE_TRAINS + i].wavelength = 1.0;
		queries[PRIMARY_WAVE_TRAINS + i].orientation = 0.0;
		queries[PRIMARY_WAVE_TRAINS + i].profile = 0.0;
	}
	
	// We use a secondary wave train to represent wind gusts
	queries[PRIMARY_WAVE_TRAINS].wavelength = 0.3; // Small 30cm waves
	queries[PRIMARY_WAVE_TRAINS].orientation = PI; // Wind direction
	queries[PRIMARY_WAVE_TRAINS].profile = wind_speed * texture(wind_strength, uv + vec2(time * wind_speed * 0.05, 0.0)).r; // With a profile that depends on local wind strenght
	
	return queries;
}

#define CUSTOM_QUERIES
#include "render_ocean.gdshaderinc"

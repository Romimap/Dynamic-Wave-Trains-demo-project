shader_type spatial;

#include "includes/ocean.gdshaderinc"

uniform float wavelengths[PRIMARY_WAVE_TRAINS];
uniform float orientations[PRIMARY_WAVE_TRAINS];
uniform float profiles[PRIMARY_WAVE_TRAINS];
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv, float time) {
	wave_train_query queries[WAVE_TRAINS_COUNT];
	
	for (int i = 0; i < PRIMARY_WAVE_TRAINS; i++) {
		queries[i].wavelength = wavelengths[i];
		queries[i].orientation = orientations[i];
		queries[i].profile = profiles[i];
	}
	
	// Reflection : The secondary wave trains are set such as it mimics the reflection of the first wave trains, that decays with distance to a cliff.
	for (int i = 0; i < SECONDARY_WAVE_TRAINS; i++) {
		queries[PRIMARY_WAVE_TRAINS + i].wavelength = queries[i].wavelength;
		queries[PRIMARY_WAVE_TRAINS + i].orientation = -queries[i].orientation + PI;
		queries[PRIMARY_WAVE_TRAINS + i].profile = queries[i].profile * clamp(uv.x * 0.01 + 0.1, 0.01, 1.0);
	}
	
	return queries;
}

#define CUSTOM_QUERIES
#include "render_ocean.gdshaderinc"
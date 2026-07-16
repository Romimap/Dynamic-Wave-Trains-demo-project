shader_type spatial;

#include "includes/ocean.gdshaderinc"

uniform float wavelengths[WAVE_TRAINS_COUNT];
uniform float orientations[WAVE_TRAINS_COUNT];
uniform float profiles[WAVE_TRAINS_COUNT];
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv, float time) {
	wave_train_query queries[WAVE_TRAINS_COUNT];
	
	for (int i = 0; i < PRIMARY_WAVE_TRAINS; i++) { // The refraction effect is computed in the shallow wave train control fields (see control_fields.gdshaderinc)
		queries[i].wavelength = wavelengths[i];
		queries[i].orientation = orientations[i];
		queries[i].profile = profiles[i];
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
#include "includes/render_ocean.gdshaderinc"

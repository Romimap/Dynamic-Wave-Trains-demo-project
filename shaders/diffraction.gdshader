shader_type spatial;

#define SHALLOW_WATER //options : SHALLOW_WATER, DEEP_WATER

render_mode depth_draw_always
//,wireframe
//,unshaded
;

#include "includes/ocean.gdshaderinc"

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;
uniform vec3 sea_color : source_color;
uniform vec3 sss_color : source_color;
uniform float footprint_scale : hint_range(0.01, 100.0, 0.01) = 1.2;
uniform sampler2D foam_texture;



uniform float wavelengths[WAVE_TRAINS_COUNT];
uniform sampler2D orientation : filter_linear, repeat_disable;
uniform sampler2D profile : filter_linear, repeat_disable;
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv) {
	uv += 128.0;
	uv /= 256.0;
	
	wave_train_query queries[WAVE_TRAINS_COUNT];
	for (int i = 0; i < 5; i++) {
		queries[i].wavelength = wavelengths[i];
		queries[i].orientation = texture(orientation, uv).r * 2.0 * PI - 0.5 * PI;
		queries[i].profile = texture(profile, uv).r;
	}
	
	return queries;
}


varying vec2 uv;
void vertex() {
	uv = (MODEL_MATRIX * vec4(VERTEX, 1)).xz;
	FP P = footprint_make_fp(uv, vec2(1, 0), vec2(0, 1));
	wave_train_query queries[WAVE_TRAINS_COUNT] = generate_queries(uv);
	vec3 displacement;
	OceanVertex(P, TIME, queries, displacement);
	
	if (VERTEX.y < 0.0) displacement.y *= 0.0;
	if (VERTEX.x != clamp(VERTEX.x, -127, 127)) displacement.x *= 0.0;
	if (VERTEX.z != clamp(VERTEX.z, -127, 127)) displacement.z *= 0.0;
	
	VERTEX += displacement;
}


void fragment() {
	//Computes sea floor and sea surface distance to make water transparent
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	vec3 sea_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	//Dynamic Wave Trains
	FP P = footprint_make_fp(uv, dFdx(uv) * footprint_scale, dFdy(uv) * footprint_scale); //A small amount of over filtering can be necessary to prevent flickering
	float O;
	float sigma;
	visual_effects effects;
	wave_train_query queries[WAVE_TRAINS_COUNT] = generate_queries(uv);
	vec2 slope;
	OceanFragment(P, TIME, queries, O, sigma, effects, slope);
	
	//Sets the normal
	if ((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y > 0.5) {
		NORMAL = (VIEW_MATRIX * vec4(normalize(vec3(slope.x, 1.0, -slope.y)), 0)).xyz;
	}
	
	// Water BRDF params
	float water_alpha = clamp(1.0 - exp(-distance(world_position, sea_position) * 0.3), 0.0, 1.0);
	vec3 water_albedo = sea_color;
	vec3 water_emission = sss_color * effects.sss;
	float water_roughness = 0.1 + sigma;
	
	// Foam BRDF params
	float foam_alpha = 1.0;
	vec3 foam_albedo = vec3(0.8);
	vec3 foam_emission = vec3(0.4) * effects.sss;
	float foam_roughness = 1.0;
	
	//Here we add a texture to the "foam quantity" returned by OceanFragment
	effects.foam = clamp(texture(foam_texture, UV * 50.0).r * effects.foam * 2.0 - 0.1, 0.0, 1.0); //Foam behind the waves
	effects.foam += max(0.0, texture(foam_texture, UV * 10.0).r - 0.55); //Static foam
	
	// Final BRDF params
	ALPHA = mix(water_alpha, foam_alpha, effects.foam);
	ALBEDO = mix(water_albedo, foam_albedo, effects.foam);
	EMISSION = mix(water_emission, foam_emission, effects.foam);
	ROUGHNESS = mix(water_roughness, foam_roughness, effects.foam);
	SPECULAR = 1.0;
}

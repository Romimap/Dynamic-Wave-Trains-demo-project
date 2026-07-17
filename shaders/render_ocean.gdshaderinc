/*
This file renders an ocean by running the method on the vertex and the fragment shader.
To do so, it feeds a wave_train_query array, defined by a generate_queries function, to the OceanVertex and OceanFragment functions.
Using #defines, the user can individually replace the default generate_queries function (What waves should we instanciate), the vertex shader (How should we displace the mesh) and the fragment shader (How should we shade the mesh) to tweak the appearance.
*/


#ifndef __RENDER_OCEAN__
#define __RENDER_OCEAN__
#include "includes/ocean.gdshaderinc"

#ifndef CUSTOM_RENDER_MODE
render_mode depth_draw_always;
#endif

// Default queries, asks for a flat ocean (all profiles to 0)
#ifndef CUSTOM_QUERIES
wave_train_query[WAVE_TRAINS_COUNT] generate_queries(vec2 uv, float time) {
	wave_train_query queries[WAVE_TRAINS_COUNT];
	
	for (int i = 0; i < WAVE_TRAINS_COUNT; i++) {
		queries[i].wavelength = 0.0;
		queries[i].orientation = 0.0;
		queries[i].profile = 0.0;
	}
	
	return queries;
}
#endif


//Default vertex shader, considers that the mesh is a grid with a 1 unit spacing between vertices
#ifndef CUSTOM_VERTEX
const float grid_size = 1.0;
varying vec2 uv;
void vertex() {
	uv = (MODEL_MATRIX * vec4(VERTEX, 1)).xz;
	FP P = footprint_make_fp(uv, vec2(grid_size, 0), vec2(0, grid_size));
	wave_train_query queries[WAVE_TRAINS_COUNT] = generate_queries(uv, TIME);
	vec3 displacement;
	OceanVertex(P, TIME, queries, displacement);
	
	VERTEX += displacement;
}
#endif


//Default fragment shader, makes the water transparent close to obstacles, and applies a foam texture behind the highest waves.
#ifndef CUSTOM_FRAGMENT
uniform sampler2D depth_texture: hint_depth_texture;
uniform vec3 sea_color : source_color;
uniform vec3 sss_color : source_color;
uniform float footprint_scale : hint_range(0.01, 100.0, 0.01) = 1.2;
uniform sampler2D foam_texture;
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
	vec3 sigma;
	visual_effects effects;
	wave_train_query queries[WAVE_TRAINS_COUNT] = generate_queries(uv, TIME);
	vec2 slope;
	OceanFragment(P, TIME, queries, O, sigma, effects, slope);
	
	//Sets the normal
	NORMAL = (VIEW_MATRIX * vec4(normalize(vec3(slope.x, 1.0, -slope.y)), 0)).xyz;
	
	// Water BRDF params
	float water_alpha = clamp(1.0 - exp(-distance(world_position, sea_position) * 0.3), 0.0, 1.0);
	vec3 water_albedo = sea_color;
	vec3 water_emission = sss_color * effects.sss;
	float water_roughness = 0.1 + sigma.x; 
	/*
	The X variance (sigma.x), Y variance (sigma.y) and XY covariance (sigma.z) should be used to get anisotropic reflections.
	However, because this is not easely mapped into Godot BRDF parameters, we choose a simple isotropic roughness.
	*/
	
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
#endif

#endif
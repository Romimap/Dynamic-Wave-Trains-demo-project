#ifndef __OCEAN__
#define __OCEAN__


#include "control_fields.gdshaderinc"
#include "tiling_and_blending.gdshaderinc"
#include "visual_effects.gdshaderinc"

// Should be the same as the precomputation step.
#define EXEMPLAR_FREQUENCY 10.0 
#define WAVE_TRAINS_COUNT 5

uniform sampler2D exemplar : filter_linear_mipmap_anisotropic;
uniform sampler2D profile_map : filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool shallow_water = true;


float H(vec2 G) {
	return texture(profile_map, (G * 0.5 + 0.5)).r;
}


const float var[4] = {
	0.0, 0.0,
	0.0, 0.2
};
float get_sigma(FP P, float frequency, float profile) {
	float max_p = max(length(P.dx), length(P.dy));
	float x = clamp(max_p * frequency, 0.0, 1.0);
	float y = clamp(profile, 0.0, 1.0);
	float a = (var[1] - var[0]) * x + var[0];
	float b = (var[3] - var[2]) * x + var[2];
	return (b - a) * y + a;
}


vec2 synthesize_gaussian_field(FP P, wave_train_query query, int wave_id, float t) {
	TB_grid_data tb_grid_data = TB_get_grid_data(P.uv, (1.0 / query.wavelength));
	
	//Section 6 and 7
	control_fields c  = sample_control_fields(P.uv           , query, wave_id, t, shallow_water);
	control_fields c1 = sample_control_fields(tb_grid_data.u1, query, wave_id, t, shallow_water);
	control_fields c2 = sample_control_fields(tb_grid_data.u2, query, wave_id, t, shallow_water);
	control_fields c3 = sample_control_fields(tb_grid_data.u3, query, wave_id, t, shallow_water);
	
	//Section 5.2, Equations (10, 11, 12, 13)
	mat3 T1 = translate(vec2(c1.frequency * -c1.speed * t / EXEMPLAR_FREQUENCY, 0.0)) * rotate(c1.orientation) * scale(vec2(c1.frequency)) * scale(vec2(1.0 / EXEMPLAR_FREQUENCY));
	mat3 T2 = translate(vec2(c2.frequency * -c2.speed * t / EXEMPLAR_FREQUENCY, 0.0)) * rotate(c2.orientation) * scale(vec2(c2.frequency)) * scale(vec2(1.0 / EXEMPLAR_FREQUENCY));
	mat3 T3 = translate(vec2(c3.frequency * -c3.speed * t / EXEMPLAR_FREQUENCY, 0.0)) * rotate(c3.orientation) * scale(vec2(c3.frequency)) * scale(vec2(1.0 / EXEMPLAR_FREQUENCY));
	
	TB_transform_data tb_transform_data = TB_make_transform_data(c.profile, T1, T2, T3);
	
	return TB_tiling_and_blending(P, exemplar, tb_grid_data, tb_transform_data, false).rg;
}


void OceanFragment(FP P, float t, wave_train_query queries[WAVE_TRAINS_COUNT], out float O, out float sigma, out visual_effects effects, out vec2 slope) {
	O = 0.0;
	sigma = 0.0;
	effects.sss = 0.0;
	effects.foam = 0.0;
	
	for (int i = 0; i < queries.length(); i++) {
		wave_train_query query = queries[i];
		if (query.profile == 0.0) continue;
		
		
		vec2 G_l_raw = synthesize_gaussian_field(P, query, i, t);
		// Section 3.1, Equation (8)
		vec2 G_l = normalize(G_l_raw) * tanh(length(G_l_raw));
		
		control_fields c = sample_control_fields(P.uv, query, i, t, shallow_water);
		
		// Section 3 : Model
		O += H(G_l) / (c.frequency * 2.0 * PI);
		// Section 8.3 : BRDF (In this implementation we opted for a simple isotropic roughness)
		sigma += get_sigma(P, c.frequency, c.profile);
		
		// Section 9 : Geometry correlated visual effects
		effects.sss += sss(G_l, query.wavelength); // Visual effects can be accumulated ...
		if (i == 0) { // ... or set for a single wave train
			effects.foam = foam(G_l, G_l_raw);
		}
	}
	
	// Section 8.2 : Normal maps
	mat2 dUV = mat2(
		P.dx,
		P.dy
	);
	dUV = inverse(transpose(dUV));
	vec2 dO = vec2(dFdx(O), dFdy(O));	
	slope = dUV * dO;
}


void OceanVertex(FP P, float t, wave_train_query queries[5], out vec3 displacement) {
	displacement = vec3(0.0);
	
	for (int i = 0; i < queries.length(); i++) {
		wave_train_query query = queries[i];
		if (query.profile == 0.0) continue;
		
		vec2 G_l_raw = synthesize_gaussian_field(P, query, i, t);
		vec2 G_l = normalize(G_l_raw) * tanh(length(G_l_raw));
		
		control_fields c = sample_control_fields(P.uv, query, i, t, shallow_water);
		
		// Appendix C : Technical details, mesh displacement
		G_l *= (query.wavelength / (2.0 * PI));
		vec3 G_rotated = vec3(cos(c.orientation) * G_l.x, -sin(c.orientation) * G_l.x, -G_l.y);
		G_rotated *= vec3(-1, -1, 1);
		displacement += G_rotated;
	}
}

#endif
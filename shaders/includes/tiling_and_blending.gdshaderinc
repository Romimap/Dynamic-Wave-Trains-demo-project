/*
See [Eric Heitz, Fabrice Neyret. High-Performance By-Example Noise using a Histogram-Preserving Blending Operator. Proceedings of the ACM on Computer Graphics and Interactive Techniques, 2018, ACM SIGGRAPH]
*/

#ifndef __TILING_AND_BLENDING__
#define __TILING_AND_BLENDING__

#include "footprint.gdshaderinc"

struct TB_transform_data {
	float intensity;
	mat3 T1;
	mat3 T2;
	mat3 T3;
};


struct TB_grid_data {
	vec2 u1;
	vec2 u2;
	vec2 u3;
	ivec2 vert1;
	ivec2 vert2;
	ivec2 vert3;
	float v1;
	float v2;
	float v3;
};


TB_transform_data TB_make_transform_data(float intensity, mat3 T1, mat3 T2, mat3 T3) {
	TB_transform_data tb_transform_data;
	tb_transform_data.intensity = intensity;
	tb_transform_data.T1 = T1;
	tb_transform_data.T2 = T2;
	tb_transform_data.T3 = T3;
	return tb_transform_data;
}


TB_grid_data TB_get_grid_data(vec2 uv, float grid_scale) {
	TB_grid_data tb_grid_data;
	uv *= grid_scale;

	const mat2 grid_to_skewed_grid = mat2(
		vec2(1.0, 0.0),
		vec2(-0.57735027, 1.15470054)
	);

	const mat2 inv_grid_to_skewed_grid = inverse(grid_to_skewed_grid);

	vec2 skewedCoord = grid_to_skewed_grid * uv;

	ivec2 baseId = ivec2(floor(skewedCoord));
	vec3 temp = vec3(fract(skewedCoord), 0);
		
	temp.z = 1.0 - temp.x - temp.y;
	if (temp.z > 0.0)
	{
		tb_grid_data.v1 = temp.z;
		tb_grid_data.v2 = temp.y;
		tb_grid_data.v3 = temp.x;
		tb_grid_data.vert1 = baseId + ivec2(0, 0);
		tb_grid_data.vert2 = baseId + ivec2(0, 1);
		tb_grid_data.vert3 = baseId + ivec2(1, 0);
		tb_grid_data.u1 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert1)) / grid_scale;
		tb_grid_data.u2 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert2)) / grid_scale;
		tb_grid_data.u3 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert3)) / grid_scale;
	}
	else
	{
		tb_grid_data.v1 = -temp.z;
		tb_grid_data.v3 = 1.0 - temp.y;
		tb_grid_data.v2 = 1.0 - temp.x;
		tb_grid_data.vert1 = baseId + ivec2(1, 1);
		tb_grid_data.vert3 = baseId + ivec2(1, 0);
		tb_grid_data.vert2 = baseId + ivec2(0, 1);
		tb_grid_data.u1 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert1)) / grid_scale;
		tb_grid_data.u3 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert3)) / grid_scale;
		tb_grid_data.u2 = (inv_grid_to_skewed_grid * vec2(tb_grid_data.vert2)) / grid_scale;
	}

	TB_grid_data output;
	output.u1 = vec2(0);
	output.u2 = vec2(0);
	output.u3 = vec2(0);
	output.v1 = 0.0;
	output.v2 = 0.0;
	output.v3 = 0.0;
	output.vert1 = ivec2(0);
	output.vert2 = ivec2(0);
	output.vert3 = ivec2(0);
	
	//Makes the tiles coherent across multiple triangles, prevents a grid artifact 
	switch ((baseId.x - baseId.y + 1000000) % 3) {
		case 0:
			output.u1 = tb_grid_data.u1;
			output.u2 = tb_grid_data.u2;
			output.u3 = tb_grid_data.u3;
			output.v1 = tb_grid_data.v1;
			output.v2 = tb_grid_data.v2;
			output.v3 = tb_grid_data.v3;
			output.vert1 = tb_grid_data.vert1;
			output.vert2 = tb_grid_data.vert2;
			output.vert3 = tb_grid_data.vert3;
			break;
		case 1:
			output.u1 = tb_grid_data.u2;
			output.u2 = tb_grid_data.u3;
			output.u3 = tb_grid_data.u1;
			output.v1 = tb_grid_data.v2;
			output.v2 = tb_grid_data.v3;
			output.v3 = tb_grid_data.v1;
			output.vert1 = tb_grid_data.vert2;
			output.vert2 = tb_grid_data.vert3;
			output.vert3 = tb_grid_data.vert1;
			break;
		case 2:
			output.u1 = tb_grid_data.u3;
			output.u2 = tb_grid_data.u1;
			output.u3 = tb_grid_data.u2;
			output.v1 = tb_grid_data.v3;
			output.v2 = tb_grid_data.v1;
			output.v3 = tb_grid_data.v2;
			output.vert1 = tb_grid_data.vert3;
			output.vert2 = tb_grid_data.vert1;
			output.vert3 = tb_grid_data.vert2;
			break;
	}
	
	return output;
}


vec2 hash(vec2 p) {
	return fract(sin((p) * mat2(vec2(127.1, 311.7), vec2(269.5, 183.3))) * 43758.5453);
}


vec4 TB_tiling_and_blending(FP P, sampler2D tex, TB_grid_data tb_grid_data, TB_transform_data tb_transform_data, bool w_sq) {
	FP P1 = footprint_transform_fp(P, tb_transform_data.T1);
	FP P2 = footprint_transform_fp(P, tb_transform_data.T2);
	FP P3 = footprint_transform_fp(P, tb_transform_data.T3);

	vec2 h1 = hash(vec2(tb_grid_data.vert1));
	vec2 h2 = hash(vec2(tb_grid_data.vert2));
	vec2 h3 = hash(vec2(tb_grid_data.vert3));
	P1.uv += h1;
	P2.uv += h2;
	P3.uv += h3;
	
	vec4 mean = textureLod(tex, vec2(0.5), 100);
	vec4 E1 = textureGrad(tex, P1.uv, P1.dx, P1.dy) - mean;
	vec4 E2 = textureGrad(tex, P2.uv, P2.dx, P2.dy) - mean;
	vec4 E3 = textureGrad(tex, P3.uv, P3.dx, P3.dy) - mean;
	
	float sum = sqrt(tb_grid_data.v1 * tb_grid_data.v1 + tb_grid_data.v2 * tb_grid_data.v2 + tb_grid_data.v3 * tb_grid_data.v3);
	
	float w1 = tb_grid_data.v1 / sum;
	float w2 = tb_grid_data.v2 / sum;
	float w3 = tb_grid_data.v3 / sum;
	
	
	return tb_transform_data.intensity * (w1 * E1 + w2 * E2 + w3 * E3 + mean);
}

#endif
#ifndef __FOOTPRINT__
#define __FOOTPRINT__

#include "transforms.gdshaderinc"

struct FP {
	vec2 uv;
	vec2 dx;
	vec2 dy;
};

FP footprint_make_fp(vec2 uv, vec2 dx, vec2 dy) {
	FP P;
	P.uv = uv;
	P.dx = dx;
	P.dy = dy;
	return P;
}

FP footprint_transform_fp(FP P, mat3 T) {
	FP ans;

	ans.uv = transform_point(P.uv, T);
	ans.dx = transform_direction(P.dx, T);
	ans.dy = transform_direction(P.dy, T);

	return ans;
}

#endif
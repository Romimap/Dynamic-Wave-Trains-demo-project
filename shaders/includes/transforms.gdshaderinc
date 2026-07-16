/*
Helper functions to transform vectors
*/

#ifndef __TRANSFORMS__
#define __TRANSFORMS__

mat3 identity() {
	mat3 m = mat3(0);
	m[0][0] = 1.0;
	m[1][1] = 1.0;
	m[2][2] = 1.0;
	return m;
}

mat3 translate(vec2 t) {
	mat3 m = mat3(0);
	m[0][0] = 1.0;
	m[1][1] = 1.0;
	m[2][0] = t.x;
	m[2][1] = t.y;
	m[2][2] = 1.0;
	return m;
}

mat3 rotate(float t) {
	mat3 m = mat3(0);
	m[0][0] = cos(t);
	m[0][1] = sin(t);
	m[1][0] = -sin(t);
	m[1][1] = cos(t);
	m[2][2] = 1.0;

	return m;
}


vec3 rotate_sigma(vec3 sigma, float t) {
	float a = cos(t);
	float b = sin(t);
	float c = sigma.x;
	float d = sigma.x;
	float e = sigma.x;
	return vec3(
		a*a*c - 2.0*a*b*d + b*b*e,
		b*b*c + 2.0*a*b*d + a*a*e,
		a*b*c - b*b*c + a*a*d - a*b*e
	);
}

mat3 scale(vec2 s) {
	mat3 m = mat3(0);
	m[0][0] = s.x;
	m[1][1] = s.y;
	m[2][2] = 1.0;
	return m;
}

vec2 transform_point(vec2 A, mat3 T) {
	return (T * vec3(A, 1)).xy;
}

vec2 transform_direction(vec2 A, mat3 T) {
	return (T * vec3(A, 0)).xy;
}

#endif
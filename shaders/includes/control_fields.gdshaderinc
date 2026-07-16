#ifndef __CONTROL_FIELDS__
#define __CONTROL_FIELDS__

const float g = 9.8;

struct wave_train_query {
	float wavelength;
	float orientation;
	float profile;
};

struct control_fields {
	float speed;
	float orientation;
	float frequency;
	float profile;
};



//DEEP

float speed_deep(float wavelength) {
	return sqrt((wavelength * g) / (2.0 * PI));
}

float frequency_deep(float wavelength) {
	return 1.0 / wavelength;
}



//SHALLOW

uniform sampler2D depth_map : repeat_disable;

float depth(vec2 u) {
	return texture(depth_map, u * (1.0 / 256.0) + 0.5).r * 0.5;
}

float depth_gradient(float _p, vec2 u) {
	float p_dx = depth(u + vec2(0.1, 0.0)) - _p;
	float p_dy = depth(u + vec2(0.0, 0.1)) - _p;
	return atan(p_dx, p_dy);
}

float speed_shallow(float depth, float wavelength) {
	depth = max(depth, 0.3); // Clamp so speed does not go to 0
	return sqrt(((wavelength * g) / (2.0 * PI)) * tanh(2.0  *  PI * (depth / wavelength)));
}

float orientation_shallow(float _orientation_deep, float _depth_gradient, float _speed_deep, float _speed) {
	float n_2 = (_speed_deep / _speed);
	float theta_1 = _orientation_deep - (_depth_gradient + PI * 0.5);
	
	if (abs(theta_1) > PI * 0.5) return _orientation_deep;
	
	float theta_2 = asin(sin(theta_1) / n_2);
	float _Theta_shallow = _orientation_deep + (theta_2 - theta_1);
	
	return _Theta_shallow;
}

float frequency_shallow(float speed_deep, float speed, float frequency_deep) {
	return (speed_deep/speed) * frequency_deep;
}

float profile_shallow(float depth, float wavelength, float profile_deep) {
	if (depth < 0.0) return 0.0;
	return sqrt(sqrt((wavelength * 0.5)/depth)) * profile_deep;
}



control_fields sample_control_fields(vec2 u, wave_train_query query, int wave_id, float t, bool shallow_water) {
	control_fields deep;
	
	deep.speed = speed_deep(query.wavelength);
	deep.orientation = query.orientation;
	deep.frequency = frequency_deep(query.wavelength);
	deep.profile = query.profile;
	
	if (!shallow_water) return deep;
	
	
	control_fields shallow;
	
	float _depth = depth(u);
	float _depth_gradient = depth_gradient(_depth, u);
	shallow.speed = speed_shallow(_depth, query.wavelength);
	shallow.orientation = orientation_shallow(deep.orientation, _depth_gradient, deep.speed, shallow.speed);
	shallow.frequency = frequency_shallow(deep.speed, shallow.speed, deep.frequency);
	shallow.profile = profile_shallow(_depth, query.wavelength, deep.profile);
	
	return shallow;
}

#endif
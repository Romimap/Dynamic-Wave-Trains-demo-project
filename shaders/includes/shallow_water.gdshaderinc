#ifndef __CONTROL_FIELDS__
#define __CONTROL_FIELDS__

const float g = 9.8;
uniform sampler2D depth_map : repeat_disable;
uniform float orientations[5];
uniform float profiles[5];

float depth(vec2 u) {
	return texture(depth_map, u * (1.0 / 256.0) + 0.5).r * 0.5;
}

float depth_gradient(float _p, vec2 u) {
	float p_dx = depth(u + vec2(0.1, 0.0)) - _p;
	float p_dy = depth(u + vec2(0.0, 0.1)) - _p;
	return atan(p_dx, p_dy);
}

float speed_deep(float wavelength) {
	return sqrt((wavelength * g) / (2.0 * PI));
}

float orientation_deep(int wave_id) {
	return orientations[wave_id];
}

float frequency_deep(float wavelength) {
	return 1.0 / wavelength;
}

float profile_deep(int wave_id) {
	return profiles[wave_id];
}

struct control_fields {
	float speed;
	float orientation;
	float frequency;
	float profile;
};

float speed(float depth, float wavelength) {
	depth = max(depth, 0.3); // Clamp so speed does not go to 0
	return sqrt(((wavelength * g) / (2.0 * PI)) * tanh(2.0  *  PI * (depth / wavelength)));
}

float orientation(float _orientation_deep, float _depth_gradient, float _speed_deep, float _speed) {
	float n_2 = (_speed_deep / _speed);
	float theta_1 = _orientation_deep - (_depth_gradient + PI * 0.5);
	
	if (abs(theta_1) > PI * 0.5) return _orientation_deep;
	
	float theta_2 = asin(sin(theta_1) / n_2);
	float _Theta_shallow = _orientation_deep + (theta_2 - theta_1);
	
	return _Theta_shallow;
}

float frequency(float speed_deep, float speed, float frequency_deep) {
	return (speed_deep/speed) * frequency_deep;
}

float profile(float depth, float wavelength, float profile_deep) {
	float coast_mute = clamp(depth * 3.0, 0.0, 1.0); //Tune down the profiles close to the coast
	return sqrt(sqrt((wavelength * 0.5)/depth)) * profile_deep * coast_mute;
}

control_fields sample_control_fields(vec2 u, float wavelength, int wave_id, float t) {
	control_fields c;
	
	float _depth = depth(u);
	float _depth_gradient = depth_gradient(_depth, u);
	float _speed_deep = speed_deep(wavelength);
	float _orientation_deep = orientation_deep(wave_id);
	float _frequency_deep = frequency_deep(wavelength);
	float _profile_deep = profile_deep(wave_id);
	float _speed = speed(_depth, wavelength);
	
	c.speed = _speed;
	c.orientation = orientation(_orientation_deep, _depth_gradient, _speed_deep, _speed);
	c.frequency = frequency(_speed_deep, _speed, _frequency_deep);
	c.profile = profile(_depth, wavelength, _profile_deep);
	
	return c;
}

#endif
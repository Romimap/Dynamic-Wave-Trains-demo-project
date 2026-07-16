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


//DEEP (Section 6)

float speed_deep(float wavelength) {
	return sqrt((wavelength * g) / (2.0 * PI)); // Equation 15
}

float frequency_deep(float wavelength) {
	return 1.0 / wavelength; // Equation 14
}

control_fields deep_water_control_fields(vec2 u, wave_train_query query) {
	control_fields deep;
	
	deep.speed = speed_deep(query.wavelength); // Equation 15
	deep.orientation = query.orientation;
	deep.frequency = frequency_deep(query.wavelength); // Equation 14
	deep.profile = query.profile;
	
	return deep;
}



//SHALLOW (Section 7)

uniform sampler2D depth_map : repeat_disable;
float depth(vec2 u) {
	// remaps the world uv [-128, 128] to [0, 1] for the texture fetches
	u += 128.0;
	u /= 256.0;
	return texture(depth_map, u).r * 0.5;
}

float depth_gradient(float _p, vec2 u) {
	float p_dx = depth(u + vec2(0.1, 0.0)) - _p;
	float p_dy = depth(u + vec2(0.0, 0.1)) - _p;
	return atan(p_dx, p_dy);
}

//Equation 16 and Appendix C : Technical details
float speed_shallow(float depth, float wavelength, float speed_deep) {
	return max(speed_deep * 0.1, sqrt(((wavelength * g) / (2.0 * PI)) * tanh(2.0  *  PI * (depth / wavelength))));
}

// Equation 17 and Appendix C : Technical details
float orientation_shallow(float _orientation_deep, float _depth_gradient, float _speed_deep, float _speed) {
	float n_2 = (_speed_deep / _speed);
	float theta_1 = _orientation_deep - (_depth_gradient + PI * 0.5);
	
	if (abs(theta_1) > PI * 0.5) return _orientation_deep;
	
	float theta_2 = asin(sin(theta_1) / n_2);
	float _Theta_shallow = _orientation_deep + (theta_2 - theta_1);
	
	return _Theta_shallow;
}

// Equation 18
float frequency_shallow(float speed_deep, float speed, float frequency_deep) {
	return (speed_deep/speed) * frequency_deep;
}

// Equation 19
float profile_shallow(float depth, float wavelength, float profile_deep) {
	if (depth <= 0.0) return 1e-5; //if we are under the terrain (water depth is negative), set the profile to a small value.
	return sqrt(sqrt((wavelength * 0.5)/depth)) * profile_deep;
}

control_fields shallow_water_control_fields(vec2 u, wave_train_query query, int wave_id) {
	control_fields deep = deep_water_control_fields(u, query);
	float _depth = depth(u); // p(u) in equation 16 and 19
	float _depth_gradient = depth_gradient(_depth, u);
	
	control_fields shallow;
	shallow.speed = speed_shallow(_depth, query.wavelength, deep.speed); // Equation 16
	shallow.orientation = orientation_shallow(deep.orientation, _depth_gradient, deep.speed, shallow.speed); // Equation 17
	shallow.frequency = frequency_shallow(deep.speed, shallow.speed, deep.frequency); // Equation 18
	shallow.profile = profile_shallow(_depth, query.wavelength, deep.profile); // Equation 19
	
	return shallow;
}


control_fields sample_control_fields(vec2 u, wave_train_query query, int wave_id, bool shallow_water) {
	if (!shallow_water) return deep_water_control_fields(u, query);
	return shallow_water_control_fields(u, query, wave_id);
}


#endif
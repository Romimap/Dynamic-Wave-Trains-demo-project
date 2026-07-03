#ifndef __CONTROL_FIELDS__
#define __CONTROL_FIELDS__

const float g = 9.8;
uniform float orientations[5];
uniform float profiles[5];
uniform sampler2D wind_noise;

struct control_fields {
	float speed;
	float orientation;
	float frequency;
	float profile;
};

float speed(float wavelength) {
	return sqrt((wavelength * g) / (2.0 * PI));
}

float orientation(int wave_id) {
	return orientations[wave_id];
}

float frequency(float wavelength) {
	return 1.0 / wavelength;
}

float profile(int wave_id) {
	return profiles[wave_id];
}

control_fields sample_control_fields(vec2 u, float wavelength, int wave_id, float t) {
	control_fields c;
	c.speed = speed(wavelength);
	c.orientation = orientation(wave_id);
	c.frequency = frequency(wavelength);
	c.profile = profile(wave_id);
	return c;
}

#endif
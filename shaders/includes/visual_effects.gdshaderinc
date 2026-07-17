#ifndef __VISUAL_EFFECTS__
#define __VISUAL_EFFECTS__

struct visual_effects {
	float sss;
	float foam;
};

// This selects the top of the wave.
// Mask is stronger if profile is high, and wavelength is long (pointy big waves > small round waves)
// Section 9.1 : Subsurface scattering
float sss(vec2 G, float wavelength)
{
	float phi = mod(atan(G.y, G.x), 2.0 * PI) - PI;
	phi = abs(phi) / PI;
	phi *= length(G);
	phi = pow(phi, 2.0);
	return tanh(phi * wavelength * 0.1);
}

// This defines a foam quantity based on an "extra" energy value
// Section 9.2 : Spray and foam
float foam (vec2 G, vec2 G_raw) {
	float foam_full = (mod(atan(G.x, G.y) - PI * 0.5, 2.0 * PI) - PI) / (2.0 * PI) + 0.5;
	float extra_energy = (length(G_raw) - length(G)); // Equation 25
	
	return max(0.0, foam_full - (1.0 - extra_energy * 10.0));
}

#endif

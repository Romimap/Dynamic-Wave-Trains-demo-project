This [Godot 4.7](https://godotengine.org/download/archive/) project is a demo that both provides an implementation example and shows the capabilities of the [Dynamic Wave Trains](https://onlinelibrary.wiley.com/doi/epdf/10.1111/cgf.70495) ocean synthesis method.
The project is not made to be run through an executable, but rather opened in Godot editor to be examined.

### TL;DR, I want to QUICKLY understand

Read those files :
- ``shaders/includes/ocean.gdshaderinc`` (the sum of N wave trains)
- ``shaders/includes/[shallow/deep]_water.gdshaderinc`` (the control fields)
- ``shaders/dynamic_wave_trains.gdshader`` (how to render the ocean from the synthetized data)

# Project structure

- **scenes/dynamic_wave_trains.tscn** : This scene is a use-case scenario.
The ``Ocean`` node contains a ``ShaderMaterial`` that runs our method.


- **textures** : This folder contains the data used by the shaders. 
That is a ``depth_map.exr``, for the refraction effect. A phase ``exemplar.exr`` and a ``profile.exr`` to build wave trains. An ``HDRI.exr`` for the env-map and a ``foam.jpg`` to add visual effects.


- **shaders** : This folder contains most of the code.
``shaders/includes`` contains an implementation of the paper, that is the Dynamic Wave Trains method and an associated tiling and blending algorithm.
``shaders/dynamic_wave_trains.gdshader`` contains the code for the use case scenarios.


- **precomputation** : This folder contains a precomputation step.
In the ``textures/`` folder, a phase field exemplar and a profile map are provided.
This folder contains code that generates those two textures ; To do so, open the ``precomputation/precomputation.tscn`` scene and run the ``Compute phase exemplar`` and ``Compute profile map`` commands.


# Shader dependencies

```
ocean --- tiling_and_blending -- footprint --- transforms
	  +-- [shallow/deep]_water
	  +-- visual_effects
```

# Shader description

- ocean : Computes the sum of wave-trains. ``OceanFragment`` computes a height-map, this is essentially what is explained in the article. ``OceanVertex`` computes displacements instead of a height-map, as explained in the technical details.
- deep_water : This shader contains control fields for deep water synthesis, corresponding to Section 6 in the article.
- shallow_water : contains control fields for shallow water synthesis, corresponding to Section 7 in the article.
- visual_effects : contains phase dependent functions that add sub-surface scattering and foam to the ocean. Those functions are called in ``OceanFragment``
- dynamic_wave_trains : uses those files to synthesize the ocean seen in the ``dynamic_wave_trains.tscn`` scene.

# Optimizations

Note that this implementation is not finely optimized.
For example, most maps are stored on the GPU in an uncompressed floating point format.
One could optimize this implementation by testing different sizes / format to get both speed and visual fidelity.
We however decided to limit the necessary boilerplate to keep the code simple.

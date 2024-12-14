```@meta
CurrentModule = InferenceObjects
```

# InferenceObjects

InferenceObjects.jl is a Julia implementation of the [InferenceData schema](@extref arviz schema) for storing results of Bayesian inference.
Its purpose is to serve the following three goals:
1. Usefulness in the analysis of Bayesian inference results.
2. Reproducibility of Bayesian inference analysis.
3. Interoperability between different inference backends and programming languages.

The implementation consists primarily of the [`InferenceData`](@ref) and [`Dataset`](@ref) structures.
InferenceObjects also provides the function [`convert_to_inference_data`](@ref), which may be overloaded by inference packages to define how various inference outputs can be converted to an `InferenceData`.

For examples of how `InferenceData` can be used, see the [ArviZ.jl documentation](https://julia.arviz.org/ArviZ).

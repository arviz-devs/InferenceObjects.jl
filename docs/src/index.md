```@meta
CurrentModule = InferenceObjects
```

# InferenceObjects

[![Build Status](https://github.com/arviz-devs/InferenceObjects.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/arviz-devs/InferenceObjects.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/arviz-devs/InferenceObjects.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/arviz-devs/InferenceObjects.jl)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![Powered by NumFOCUS](https://img.shields.io/badge/powered%20by-NumFOCUS-orange.svg?style=flat&colorA=E1523D&colorB=007D8A)](https://numfocus.org)

InferenceObjects.jl is a Julia implementation of the [InferenceData schema](https://python.arviz.org/en/latest/schema/schema.html) for storing results of Bayesian inference.
Its purpose is to serve the following three goals:
1. Usefulness in the analysis of Bayesian inference results.
2. Reproducibility of Bayesian inference analysis.
3. Interoperability between different inference backends and programming languages.

The implementation consists primarily of the [`InferenceData`](@ref) and [`Dataset`](@ref) structures.
InferenceObjects also provides the function [`convert_to_inference_data`](@ref), which may be overloaded by inference packages to define how various inference outputs can be converted to an `InferenceData`.

For examples of how `InferenceData` can be used, see the [ArviZ.jl documentation](https://julia.arviz.org/stable/).

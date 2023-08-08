@doc """
    rstar(
        rng::Random.AbstractRNG=Random.default_rng(),
        classifier,
        data::Union{InferenceData,Dataset};
        kwargs...,
    )

Calculate the ``R^*`` diagnostic for the data.
"""
function MCMCDiagnosticTools.rstar(
    rng::Random.AbstractRNG, clf, data::InferenceObjects.InferenceData; kwargs...
)
    return MCMCDiagnosticTools.rstar(rng, clf, data.posterior; kwargs...)
end
function MCMCDiagnosticTools.rstar(
    rng::Random.AbstractRNG, clf, data::InferenceObjects.Dataset; kwargs...
)
    data_array = cat(map(_as_3d_array ∘ _params_array, data)...; dims=3)
    return MCMCDiagnosticTools.rstar(rng, clf, data_array; kwargs...)
end
function MCMCDiagnosticTools.rstar(
    clf, data::Union{InferenceObjects.InferenceData,InferenceObjects.Dataset}; kwargs...
)
    return MCMCDiagnosticTools.rstar(Random.default_rng(), clf, data; kwargs...)
end

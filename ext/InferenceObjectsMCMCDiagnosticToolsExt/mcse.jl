"""
    ess(data::InferenceData; kwargs...) -> Dataset
    ess(data::Dataset; kwargs...) -> Dataset

Calculate the Monte Carlo standard error (MCSE) for each parameter in the data.
"""
function MCMCDiagnosticTools.mcse(data::InferenceObjects.InferenceData; kwargs...)
    return MCMCDiagnosticTools.mcse(data.posterior; kwargs...)
end
function MCMCDiagnosticTools.mcse(data::InferenceObjects.Dataset; kwargs...)
    ds = map(data) do var
        return _from_marginals(var, MCMCDiagnosticTools.mcse(_as_marginals(var); kwargs...))
    end
    return DimensionalData.rebuild(ds; metadata=DimensionalData.NoMetadata())
end

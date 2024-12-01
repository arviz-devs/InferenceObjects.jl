@doc """
    mcse(data::InferenceData; kwargs...) -> Dataset
    mcse(data::Dataset; kwargs...) -> Dataset

Calculate the Monte Carlo standard error (MCSE) for each parameter in the data.

For more details and a description of the `kwargs`, see
[`MCMCDiagnosticTools.mcse`](@extref).
"""
function MCMCDiagnosticTools.mcse(data::InferenceObjects.InferenceData; kwargs...)
    return MCMCDiagnosticTools.mcse(data.posterior; kwargs...)
end
function MCMCDiagnosticTools.mcse(data::InferenceObjects.Dataset; kwargs...)
    ds = maplayers(data) do var
        return _as_dimarray(MCMCDiagnosticTools.mcse(_params_array(var); kwargs...), var)
    end
    return DimensionalData.rebuild(ds; metadata=DimensionalData.NoMetadata())
end

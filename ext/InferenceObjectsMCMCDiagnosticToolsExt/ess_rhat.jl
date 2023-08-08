@doc """
    ess(data::InferenceData; kwargs...) -> Dataset
    ess(data::Dataset; kwargs...) -> Dataset

Calculate the effective sample size (ESS) for each parameter in the data.
"""
function MCMCDiagnosticTools.ess(data::InferenceObjects.InferenceData; kwargs...)
    return MCMCDiagnosticTools.ess(data.posterior; kwargs...)
end

@doc """
    rhat(data::InferenceData; kwargs...) -> Dataset
    rhat(data::Dataset; kwargs...) -> Dataset

Calculate the ``\\widehat{R}`` diagnostic for each parameter in the data.
"""
function MCMCDiagnosticTools.rhat(data::InferenceObjects.InferenceData; kwargs...)
    return MCMCDiagnosticTools.rhat(data.posterior; kwargs...)
end

for f in (:ess, :rhat)
    @eval begin
        function MCMCDiagnosticTools.$f(data::InferenceObjects.Dataset; kwargs...)
            ds = map(data) do var
                return _as_dimarray(MCMCDiagnosticTools.$f(_params_array(var); kwargs...), var)
            end
            return DimensionalData.rebuild(ds; metadata=DimensionalData.NoMetadata())
        end
    end
end

@doc """
    ess_rhat(data::InferenceData; kwargs...) -> Dataset
    ess_rhat(data::Dataset; kwargs...) -> Dataset

Calculate the effective sample size (ESS) and ``\\widehat{R}`` diagnostic for each parameter
in the data.
"""
function MCMCDiagnosticTools.ess_rhat(data::InferenceObjects.InferenceData; kwargs...)
    return MCMCDiagnosticTools.ess_rhat(data.posterior; kwargs...)
end
function MCMCDiagnosticTools.ess_rhat(data::InferenceObjects.Dataset; kwargs...)
    dim_diag = Dimensions.Dim{:_metric}([:ess, :rhat])
    ds = map(DimensionalData.layers(data)) do var
        ess, rhat = MCMCDiagnosticTools.ess_rhat(_params_array(var); kwargs...)
        cat(_as_dimarray(ess, var), _as_dimarray(rhat, var); dims=dim_diag)
    end
    return InferenceObjects.Dataset(ds)
end

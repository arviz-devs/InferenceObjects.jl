"""
    bfmi(data::InferenceData) -> DimArray
    bfmi(sample_stats::Dataset) -> DimArray

Calculate the chainwise estimated Bayesian fraction of missing information (BFMI).
"""
function MCMCDiagnosticTools.bfmi(data::InferenceObjects.InferenceData)
    return MCMCDiagnosticTools.bfmi(data.sample_stats)
end
function MCMCDiagnosticTools.bfmi(data::InferenceObjects.Dataset)
    energy = data.energy
    bfmi = MCMCDiagnosticTools.bfmi(energy; dims=Dimensions.dimnum(energy, :draw))
    return Dimensions.rebuild(bfmi; refdims=())
end

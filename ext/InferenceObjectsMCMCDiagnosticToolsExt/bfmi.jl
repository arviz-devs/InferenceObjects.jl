@doc """
    bfmi(data::InferenceData) -> DimArray
    bfmi(sample_stats::Dataset) -> DimArray

Calculate the chainwise estimated Bayesian fraction of missing information (BFMI).

See [`MCMCDiagnosticTools.bfmi`](@extref) for more details.
"""
function MCMCDiagnosticTools.bfmi(data::InferenceObjects.InferenceData)
    return MCMCDiagnosticTools.bfmi(data.sample_stats)
end
function MCMCDiagnosticTools.bfmi(data::InferenceObjects.Dataset)
    energy = data.energy
    # bfmi uses diff, which drops the dimensions and breaks type-inferribility for
    # dimensional arrays. So we drop the dimensions before calling bfmi and then
    # rebuild the dimensional array afterwards.
    bfmi = MCMCDiagnosticTools.bfmi(
        DimensionalData.data(energy); dims=Dimensions.dimnum(energy, :draw)
    )
    return Dimensions.rebuild(
        energy;
        data=bfmi,
        dims=(Dimensions.dims(energy, :chain),),
        metadata=(),
        name=DimensionalData.NoName(),
    )
end

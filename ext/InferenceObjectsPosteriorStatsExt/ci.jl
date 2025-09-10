
for (ci_fun, ci_desc) in
    (:eti => "equal-tailed interval (ETI)", :hdi => "highest density interval (HDI)")
    @eval begin
        # this pattern ensures that the type is completely specified at compile time
        @doc """
            $($ci_fun)(data::InferenceData; kwargs...) -> Dataset
            $($ci_fun)(data::Dataset; kwargs...) -> Dataset

        Calculate the $($ci_desc) for each parameter in the data.

        For more details and a description of the `kwargs`, see
        [`PosteriorStats.$($ci_fun)`](@extref).
        """
        function PosteriorStats.$(ci_fun)(data::InferenceObjects.InferenceData; kwargs...)
            return PosteriorStats.$(ci_fun)(data.posterior; kwargs...)
        end
        function PosteriorStats.$(ci_fun)(data::InferenceObjects.Dataset; kwargs...)
            ds = maplayers(data) do var
                return _as_dimarray(
                    PosteriorStats.$(ci_fun)(_params_array(var); kwargs...), var
                )
            end
            return DimensionalData.rebuild(ds; metadata=DimensionalData.NoMetadata())
        end
    end
end

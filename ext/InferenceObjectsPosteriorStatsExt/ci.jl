
for (ci_fun, ci_desc) in
    (:eti => "equal-tailed interval (ETI)", :hdi => "highest density interval (HDI)")
    ci_name = string(ci_fun)
    @eval begin
        @doc """
            $($ci_name)(data::InferenceData; kwargs...) -> Dataset
            $($ci_name)(data::Dataset; kwargs...) -> Dataset

        Calculate the $($ci_desc) for each parameter in the data.

        For more details and a description of the `kwargs`, see
        [`PosteriorStats.$($ci_name)`](@extref).
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

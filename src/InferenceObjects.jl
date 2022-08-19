module InferenceObjects

using Dates: Dates
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using OrderedCollections: OrderedDict
using Requires: @require

# groups that are officially listed in the schema
const SCHEMA_GROUPS = (
    :posterior,
    :posterior_predictive,
    :predictions,
    :log_likelihood,
    :sample_stats,
    :prior,
    :prior_predictive,
    :sample_stats_prior,
    :observed_data,
    :constant_data,
    :predictions_constant_data,
    :warmup_posterior,
    :warmup_posterior_predictive,
    :warmup_predictions,
    :warmup_sample_stats,
    :warmup_log_likelihood,
)
const SCHEMA_GROUPS_DICT = Dict(n => i for (i, n) in enumerate(SCHEMA_GROUPS))
const DEFAULT_SAMPLE_DIMS = Dimensions.key2dim((:chain, :draw))

export Dataset, InferenceData
export convert_to_dataset,
    convert_to_inference_data,
    from_namedtuple,
    from_netcdf,
    namedtuple_to_dataset,
    to_netcdf

include("utils.jl")
include("dimensions.jl")
include("dataset.jl")
include("inference_data.jl")
include("convert_dataset.jl")
include("convert_inference_data.jl")
include("from_namedtuple.jl")
include("io_netcdf.jl")

function __init__()
    @require NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab" include(
        "integration/ncdatasets.jl"
    )
    Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f === from_netcdf && exc.args isa Tuple{AbstractString}
            printstyled(io, "\nNCDatasets is required to use this method."; bold=true)
        end
    end
end

end # module

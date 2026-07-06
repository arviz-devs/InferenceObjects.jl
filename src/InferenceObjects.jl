module InferenceObjects

using ANSIColoredPrinters: ANSIColoredPrinters
using Dates: Dates
using DimensionalData: DimensionalData, Dimensions, Lookups
using Random: Random
using Tables: Tables

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
const DEFAULT_SAMPLE_DIMS = Dimensions.name2dim((:draw, :chain))
const DEFAULT_DRAW_DIM = 1
const DEFAULT_CHAIN_DIM = 2

export Dataset, InferenceData
export convert_to_dataset,
    convert_to_inference_data, from_dict, from_namedtuple, namedtuple_to_dataset
export from_netcdf, to_netcdf

include("utils.jl")
include("dimensions.jl")
include("dataset.jl")
include("inference_data.jl")
include("convert_dataset.jl")
include("convert_inference_data.jl")
include("from_namedtuple.jl")
include("from_dict.jl")
include("io.jl")

function __init__()
    if isdefined(Base.Experimental, :register_error_hint)
        Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
            if exc.f === from_netcdf &&
                length(argtypes) == 1 &&
                argtypes[1] <: AbstractString
                println(
                    io,
                    "\n\nTo load an InferenceData from a NetCDF file, you must first load NCDatasets.jl.",
                )
            elseif exc.f === to_netcdf &&
                length(argtypes) == 2 &&
                argtypes[2] <: AbstractString
                println(
                    io,
                    "\n\nTo save an InferenceData to a NetCDF file, you must first load NCDatasets.jl.",
                )
            end
        end
    end
end

end # module

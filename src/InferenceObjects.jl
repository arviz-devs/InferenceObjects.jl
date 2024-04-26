module InferenceObjects

using Dates: Dates
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using Tables: Tables

const EXTENSIONS_SUPPORTED = isdefined(Base, :get_extension)

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
const DEFAULT_SAMPLE_DIMS = Dimensions.key2dim((:draw, :chain))
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

if !EXTENSIONS_SUPPORTED
    using Requires: @require
end
function __init__()
    @static if !EXTENSIONS_SUPPORTED
        @require MCMCDiagnosticTools = "be115224-59cd-429b-ad48-344e309966f0" begin
            @require Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c" begin
                include(
                    "../ext/InferenceObjectsMCMCDiagnosticToolsExt/InferenceObjectsMCMCDiagnosticToolsExt.jl",
                )
            end
        end
        @require NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab" begin
            include("../ext/InferenceObjectsNCDatasetsExt/InferenceObjectsNCDatasetsExt.jl")
        end
        @require PosteriorStats = "7f36be82-ad55-44ba-a5c0-b8b5480d7aa5" begin
            @require StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91" begin
                include(
                    "../ext/InferenceObjectsPosteriorStatsExt/InferenceObjectsPosteriorStatsExt.jl",
                )
            end
        end
    end
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

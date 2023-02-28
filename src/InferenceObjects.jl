module InferenceObjects

using Compat: stack
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

include("utils.jl")
include("dimensions.jl")
include("dataset.jl")
include("inference_data.jl")
include("convert_dataset.jl")
include("convert_inference_data.jl")
include("from_namedtuple.jl")
include("from_dict.jl")

@static if !EXTENSIONS_SUPPORTED
    function __init__()
        Requires.@require MCMCDiagnosticTools = "be115224-59cd-429b-ad48-344e309966f0" begin
            include("../ext/InferenceObjectsMCMCDiagnosticToolsExt.jl")
        end
    end
end

end # module

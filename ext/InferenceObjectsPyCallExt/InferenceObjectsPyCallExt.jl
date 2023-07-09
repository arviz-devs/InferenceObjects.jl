module InferenceObjectsPyCallExt

if isdefined(Base, :get_extension)
    using DimensionalData: DimensionalData, Dimensions
    using InferenceObjects: InferenceObjects
    using OrderedCollections: OrderedDict
    using PyCall: PyCall
else  # using Requires
    using ..DimensionalData: DimensionalData, Dimensions
    using ..InferenceObjects: InferenceObjects
    using ..OrderedCollections: OrderedDict
    using ..PyCall: PyCall
end

const _min_arviz_version = v"0.13.0"
const arviz = PyCall.PyNULL()
const xarray = PyCall.PyNULL()

include("setup.jl")
include("convert.jl")

function __init__()
    return initialize_arviz()
end

end  # module

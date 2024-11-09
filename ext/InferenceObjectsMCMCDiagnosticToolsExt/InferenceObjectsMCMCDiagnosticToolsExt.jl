module InferenceObjectsMCMCDiagnosticToolsExt

using Base: @doc
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using InferenceObjects: InferenceObjects, Random
using MCMCDiagnosticTools: MCMCDiagnosticTools

maplayers = isdefined(DimensionalData, :maplayers) ? DimensionalData.maplayers : map

include("utils.jl")
include("bfmi.jl")
include("ess_rhat.jl")
include("mcse.jl")
include("rstar.jl")

end  # module

module InferenceObjectsMCMCDiagnosticToolsExt

using Base: @doc
if isdefined(Base, :get_extension)
    using DimensionalData: DimensionalData, Dimensions, LookupArrays
    using InferenceObjects: InferenceObjects, Random
    using MCMCDiagnosticTools: MCMCDiagnosticTools
else  # using Requires
    using ..DimensionalData: DimensionalData, Dimensions, LookupArrays
    using ..InferenceObjects: InferenceObjects, Random
    using ..MCMCDiagnosticTools: MCMCDiagnosticTools
end

include("utils.jl")
include("bfmi.jl")
include("ess_rhat.jl")
include("mcse.jl")
include("rstar.jl")

end  # module

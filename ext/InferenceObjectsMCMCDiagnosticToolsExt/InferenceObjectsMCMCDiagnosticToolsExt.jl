module InferenceObjectsMCMCDiagnosticToolsExt

using DimensionalData: DimensionalData, Dimensions, LookupArrays
using InferenceObjects: InferenceObjects, EXTENSIONS_SUPPORTED
using Random
if EXTENSIONS_SUPPORTED
    using MCMCDiagnosticTools: MCMCDiagnosticTools
else  # using Requires
    using ..MCMCDiagnosticTools: MCMCDiagnosticTools
end

include("utils.jl")
include("bfmi.jl")
include("ess_rhat.jl")
include("mcse.jl")
include("rstar.jl")

end  # module

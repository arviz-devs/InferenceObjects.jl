"""
    from_dict(posterior::AbstractDict; kwargs...) -> InferenceData

Convert a `Dict` to an `InferenceData`.

# Arguments

  - `posterior`: The data to be converted. Its strings must be `Symbol` or `AbstractString`,
    and its values must be arrays.

# Keywords

  - `posterior_predictive::Any=nothing`: Draws from the posterior predictive distribution
  - `sample_stats::Any=nothing`: Statistics of the posterior sampling process
  - `predictions::Any=nothing`: Out-of-sample predictions for the posterior.
  - `prior::Dict=nothing`: Draws from the prior
  - `prior_predictive::Any=nothing`: Draws from the prior predictive distribution
  - `sample_stats_prior::Any=nothing`: Statistics of the prior sampling process
  - `observed_data::NamedTuple`: Observed data on which the `posterior` is
    conditional. It should only contain data which is modeled as a random variable. Keys
    are parameter names and values.
  - `constant_data::NamedTuple`: Model constants, data included in the model
    which is not modeled as a random variable. Keys are parameter names and values.
  - `predictions_constant_data::NamedTuple`: Constants relevant to the model
    predictions (i.e. new `x` values in a linear regression).
  - `log_likelihood`: Pointwise log-likelihood for the data. It is recommended
    to use this argument as a `NamedTuple` whose keys are observed variable names and whose
    values are log likelihood arrays.
  - `library`: Name of library that generated the draws
  - `coords`: Map from named dimension to named indices
  - `dims`: Map from variable name to names of its dimensions

# Returns

  - `InferenceData`: The data with groups corresponding to the provided data

# Examples

```@example
using InferenceObjects
nchains = 2
ndraws = 100

data = Dict(
    :x => rand(ndraws, nchains),
    :y => randn(2, ndraws, nchains),
    :z => randn(3, 2, ndraws, nchains),
)
idata = from_dict(data)
```
"""
from_dict

function from_dict(posterior::Dict; prior=nothing, kwargs...)
    nt = as_namedtuple(posterior)
    nt_prior = prior === nothing ? prior : as_namedtuple(prior)
    return from_namedtuple(nt; prior=nt_prior, kwargs...)
end

"""
    convert_to_inference_data(obj::AbstractDict; kwargs...) -> InferenceData

Convert `obj` to an [`InferenceData`](@ref). See [`from_namedtuple`](@ref) for a description
of `obj` possibilities and `kwargs`.
"""
function convert_to_inference_data(data::AbstractDict; group=:posterior, kwargs...)
    group = Symbol(group)
    group === :posterior && return from_dict(data; kwargs...)
    return from_dict(; group => data, kwargs...)
end

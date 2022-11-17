"""
    recursive_stack(x)

If `x` is an array of arrays, recursively stack into a single array whose dimensions are
ordered with dimensions of the innermost container first and outermost last.
"""
recursive_stack(x) = x
recursive_stack(x::AbstractArray{<:AbstractArray}) = recursive_stack(stack(x))

as_array(x) = fill(x)
as_array(x::AbstractArray) = x

"""
    namedtuple_of_arrays(x::NamedTuple) -> NamedTuple
    namedtuple_of_arrays(x::AbstractArray{NamedTuple}) -> NamedTuple
    namedtuple_of_arrays(x::AbstractArray{AbstractArray{<:NamedTuple}}) -> NamedTuple

Given a container of `NamedTuple`s, concatenate them, using the container dimensions as the
dimensions of the resulting arrays.

# Examples

```@example
using InferenceObjects
nchains, ndraws = 4, 100
data = [(x=rand(), y=randn(2), z=randn(2, 3)) for _ in 1:ndraws, _ in 1:nchains];
ntarray = InferenceObjects.namedtuple_of_arrays(data);
```
"""
function namedtuple_of_arrays end
namedtuple_of_arrays(x::NamedTuple) = map(recursive_stack, x)
namedtuple_of_arrays(x::AbstractArray) = namedtuple_of_arrays(namedtuple_of_arrays.(x))
function namedtuple_of_arrays(x::AbstractArray{<:NamedTuple{K}}) where {K}
    return NamedTuple{K}(recursive_stack(getproperty.(x, k)) for k in K)
end

"""
    package_version(pkg::Module) -> Union{Nothing,VersionNumber}

Return version number of package `pkg`.

If `pkg` does not have a version module (e.g. it is a submodule), then `nothing` is
returned.
"""
function package_version(pkg::Module)
    @static if isdefined(Base, :pkgversion)
        return Base.pkgversion(pkg)
    end
    pkg_path = pathof(pkg)
    pkg_path === nothing && return nothing
    project = joinpath(dirname(dirname(pkg_path)), "Project.toml")
    isfile(project) || return nothing
    toml = read(project, String)
    m = match(r"(*ANYCRLF)^version\s*=\s\"(.*)\"$"m, toml)
    return VersionNumber(m[1])
end

"""
    rekey(collection, keymap) -> rekeyed_collection

Return a new collection where values for specific keys have been moved to other keys.

`keymap` must be a keyed collection mapping from keys of the same type as `collection` to
other keys of the same type.

Keys present in `keymap` but absent from `collection` are ignored.
"""
rekey(d, keymap) = Dict(get(keymap, k, k) => d[k] for k in keys(d))
function rekey(d::NamedTuple, keymap)
    new_keys = map(k -> get(keymap, k, k), keys(d))
    return NamedTuple{new_keys}(values(d))
end

as_namedtuple(dict::AbstractDict{Symbol}) = NamedTuple(dict)
function as_namedtuple(dict::AbstractDict{<:AbstractString})
    return NamedTuple(Symbol(k) => v for (k, v) in dict)
end
as_namedtuple(nt::NamedTuple) = nt

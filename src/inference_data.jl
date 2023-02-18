const InferenceDataStorageType = OrderedCollections.LittleDict{
    Symbol,Dataset,Vector{Symbol},Vector{Dataset}
}

"""
    InferenceData{group_names,group_types}

Container for inference data storage using DimensionalData.

This object implements the [InferenceData schema](https://python.arviz.org/en/latest/schema/schema.html).

# Constructors

    InferenceData(groups::AbstractDict{Symbol,Dataset})
    InferenceData(groups::NamedTuple)
    InferenceData(; groups...)

Construct an inference data from groups.

Groups must be [`Dataset`](@ref) objects.

Instead of directly creating an `InferenceData`, use the exported `from_xyz` functions or
[`convert_to_inference_data`](@ref).
"""
struct InferenceData
    groups::InferenceDataStorageType
    function InferenceData(groups::AbstractDict)
        groups_new = InferenceDataStorageType(
            Symbol[keys(groups)...], Dataset[values(groups)...]
        )
        return InferenceData(groups_new)
    end
    InferenceData(groups::InferenceDataStorageType) = new(groups)
end
InferenceData(data::NamedTuple) = InferenceData(; data...)
InferenceData(; kwargs...) = InferenceData(kwargs)
InferenceData(data::InferenceData) = data

Base.parent(data::InferenceData) = getfield(data, :groups)

Base.:(==)(data::InferenceData, other::InferenceData) = parent(data) == parent(other)

# these 3 interfaces ensure InferenceData behaves like a NamedTuple

# properties interface
"""
    propertynames(data::InferenceData) -> Tuple{Symbol}

Get names of groups
"""
Base.propertynames(data::InferenceData) = keys(data)

"""
    getproperty(data::InferenceData, name::Symbol) -> Dataset

Get group with the specified `name`.
"""
Base.getproperty(data::InferenceData, k::Symbol) = getindex(data, k)

Base.setproperty!(data::InferenceData, k::Symbol, v) = setindex!(data, v, k)

# indexing interface
"""
    Base.getindex(data::InferenceData, groups::Symbol; coords...) -> Dataset
    Base.getindex(data::InferenceData, groups; coords...) -> InferenceData

Return a new `InferenceData` containing the specified groups sliced to the specified coords.

`coords` specifies a dimension name mapping to an index, a `DimensionalData.Selector`, or
an `IntervalSets.AbstractInterval`.

If one or more groups lack the specified dimension, a warning is raised but can be ignored.
All groups that contain the dimension must also contain the specified indices, or an
exception will be raised.

# Examples

Select data from all groups for just the specified id values.

```@repl getindex
julia> using InferenceObjects, DimensionalData

julia> idata = from_namedtuple(
           (θ=randn(4, 100, 4), τ=randn(4, 100));
           prior=(θ=randn(4, 100, 4), τ=randn(4, 100)),
           observed_data=(y=randn(4),),
           dims=(θ=[:id], y=[:id]),
           coords=(id=["a", "b", "c", "d"],),
       )
InferenceData with groups:
  > posterior
  > prior
  > observed_data

julia> idata.posterior
Dataset with dimensions:
  Dim{:chain} Sampled 1:4 ForwardOrdered Regular Points,
  Dim{:draw} Sampled 1:100 ForwardOrdered Regular Points,
  Dim{:id} Categorical String[a, b, c, d] ForwardOrdered
and 2 layers:
  :θ Float64 dims: Dim{:chain}, Dim{:draw}, Dim{:id} (4×100×4)
  :τ Float64 dims: Dim{:chain}, Dim{:draw} (4×100)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2022-08-11T11:15:21.4"

julia> idata_sel = idata[id=At(["a", "b"])]
InferenceData with groups:
  > posterior
  > prior
  > observed_data

julia> idata_sel.posterior
Dataset with dimensions:
  Dim{:chain} Sampled 1:4 ForwardOrdered Regular Points,
  Dim{:draw} Sampled 1:100 ForwardOrdered Regular Points,
  Dim{:id} Categorical String[a, b] ForwardOrdered
and 2 layers:
  :θ Float64 dims: Dim{:chain}, Dim{:draw}, Dim{:id} (4×100×2)
  :τ Float64 dims: Dim{:chain}, Dim{:draw} (4×100)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2022-08-11T11:15:21.4"
```

Select data from just the posterior, returning a `Dataset` if the indices index more than
one element from any of the variables:

```@repl getindex
julia> idata[:observed_data, id=At(["a"])]
Dataset with dimensions:
  Dim{:id} Categorical String[a] ForwardOrdered
and 1 layer:
  :y Float64 dims: Dim{:id} (1)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2022-08-11T11:19:25.982"
```

Note that if a single index is provided, the behavior is still to slice so that the
dimension is preserved.
"""
Base.getindex(data::InferenceData, groups...; kwargs...)
function Base.getindex(data::InferenceData, k::Symbol; kwargs...)
    ds = parent(data)[k]
    isempty(kwargs) && return ds
    return getindex(ds; kwargs...)
end
function Base.getindex(data::InferenceData, ks; kwargs...)
    missing_ks = setdiff(ks, keys(data))
    isempty(missing_ks) || throw(KeyError(first(missing_ks)))
    data_new = InferenceData(filter(∈(ks) ∘ first, parent(data)))
    isempty(kwargs) && return data_new
    return getindex(data_new; kwargs...)
end
function Base.getindex(data::InferenceData; kwargs...)
    # if a single index is requested, then the return type of each group
    # will be a `Dataset` if the group has other dimensions or `NamedTuple`
    # if it has no other dimensions.
    # So we promote to an array of indices
    new_kwargs = map(index_to_indices, NamedTuple(kwargs))
    groups = (k => getindex(v; new_kwargs...) for (k, v) in data)
    return InferenceData(; groups...)
end

"""
    Base.setindex!(data::InferenceData, group::Dataset, name::Symbol) -> InferenceData

Add to `data` the `group` with the specified `name`.

If a group with `name` is already in `data`, it is replaced.
"""
function Base.setindex!(data::InferenceData, v, k::Symbol)
    parent(data)[k] = v
    return data
end

# iteration interface
Base.keys(data::InferenceData) = parent(data).keys
Base.haskey(data::InferenceData, k::Symbol) = haskey(parent(data), k)
Base.values(data::InferenceData) = parent(data).vals
Base.pairs(data::InferenceData) = pairs(parent(data))
Base.length(data::InferenceData) = length(parent(data))
Base.iterate(data::InferenceData, i...) = iterate(parent(data), i...)
Base.eltype(data::InferenceData) = eltype(parent(data))

function Base.show(io::IO, ::MIME"text/plain", data::InferenceData)
    print(io, "InferenceData with groups:")
    prefix = "\n  > "
    for name in _order_groups_by_name(groupnames(data))
        print(io, prefix, name)
    end
    return nothing
end
function Base.show(io::IO, mime::MIME"text/html", data::InferenceData)
    show(io, mime, HTML("<div>InferenceData"))
    for (name, group) in _order_groups_by_name(groups(data))
        show(io, mime, HTML("""
        <details>
        <summary>$name</summary>
        <pre><code>$(sprint(show, "text/plain", group))</code></pre>
        </details>
        """))
    end
    return show(io, mime, HTML("</div>"))
end

_lt_symint(a, b) = (a isa Integer && b isa Integer) ? a < b : string(a) < string(b)
_scheme_order(k) = get(SCHEMA_GROUPS_DICT, k, string(k))

_order_groups_by_name(groups) = sort(groups; lt=_lt_symint, by=_scheme_order)

"""
    groups(data::InferenceData)

Get the groups in `data` as a named tuple mapping symbols to [`Dataset`](@ref)s.
"""
groups(data::InferenceData) = parent(data)

"""
    groupnames(data::InferenceData)

Get the names of the groups (datasets) in `data` as a tuple of symbols.
"""
groupnames(data::InferenceData) = groups(data).keys

"""
    hasgroup(data::InferenceData, name::Symbol) -> Bool

Return `true` if a group with name `name` is stored in `data`.
"""
hasgroup(data::InferenceData, name::Symbol) = haskey(data, name)

"""
    merge(data::InferenceData...) -> InferenceData

Merge [`InferenceData`](@ref) objects.

The result contains all groups in `data` and `others`.
If a group appears more than once, the one that occurs last is kept.

See also: [`cat`](@ref)

# Examples

Here we merge an `InferenceData` containing only a posterior group with one containing only
a prior group to create a new one containing both groups.

```jldoctest
julia> idata1 = from_dict(Dict(:a => randn(100, 4, 3), :b => randn(100, 4)))
InferenceData with groups:
  > posterior

julia> idata2 = from_dict(; prior=Dict(:a => randn(100, 1, 3), :c => randn(100, 1)))
InferenceData with groups:
  > prior

julia> idata_merged = merge(idata1, idata2)
InferenceData with groups:
  > posterior
  > prior
```
"""
function Base.merge(data::InferenceData, others::InferenceData...)
    return InferenceData(Base.merge(groups(data), map(groups, others)...))
end

function rekey(data::InferenceData, keymap)
    pairs_new = (get(keymap, k, k) => v for (k, v) in pairs(groups(data)))
    return InferenceData(; pairs_new...)
end

"""
    cat(data::InferenceData...; [groups=keys(data[1]),] dims) -> InferenceData

Concatenate [`InferenceData`](@ref) objects along the specified dimension `dims`.

Only the groups in `groups` are concatenated. Remaining groups are [`merge`](@ref)d into the
new `InferenceData` object.

# Examples

Here is how we can concatenate all groups of two `InferenceData` objects along the existing
`chain` dimension:

```jldoctest cat
julia> coords = (; a_dim=["x", "y", "z"]);

julia> dims = dims=(; a=[:a_dim]);

julia> data = Dict(:a => randn(100, 4, 3), :b => randn(100, 4));

julia> idata = from_dict(data; coords=coords, dims=dims)
InferenceData with groups:
  > posterior

julia> idata_cat1 = cat(idata, idata; dims=:chain)
InferenceData with groups:
  > posterior

julia> idata_cat1.posterior
Dataset with dimensions:
  Dim{:draw},
  Dim{:chain},
  Dim{:a_dim} Categorical{String} String[x, y, z] ForwardOrdered
and 2 layers:
  :a Float64 dims: Dim{:draw}, Dim{:chain}, Dim{:a_dim} (100×8×3)
  :b Float64 dims: Dim{:draw}, Dim{:chain} (100×8)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2023-02-17T18:47:29.679"
```

Alternatively, we can concatenate along a new `run` dimension, which will be created.

```jldoctest cat
julia> idata_cat2 = cat(idata, idata; dims=:run)
InferenceData with groups:
  > posterior

julia> idata_cat2.posterior
Dataset with dimensions:
  Dim{:draw},
  Dim{:chain},
  Dim{:a_dim} Categorical{String} String[x, y, z] ForwardOrdered,
  Dim{:run}
and 2 layers:
  :a Float64 dims: Dim{:draw}, Dim{:chain}, Dim{:a_dim}, Dim{:run} (100×4×3×2)
  :b Float64 dims: Dim{:draw}, Dim{:chain}, Dim{:run} (100×4×2)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2023-02-17T18:47:29.679"
```

We can also concatenate only a subset of groups and merge the rest, which is useful when
some groups are present only in some of the `InferenceData` objects or will be identical in
all of them:

```jldoctest cat
julia> observed_data = Dict(:y => randn(10));

julia> idata2 = from_dict(data; observed_data=observed_data, coords=coords, dims=dims)
InferenceData with groups:
  > posterior
  > observed_data

julia> idata_cat3 = cat(idata, idata2; groups=(:posterior,), dims=:run)
InferenceData with groups:
  > posterior
  > observed_data

julia> idata_cat3.posterior
Dataset with dimensions:
  Dim{:draw},
  Dim{:chain},
  Dim{:a_dim} Categorical{String} String[x, y, z] ForwardOrdered,
  Dim{:run}
and 2 layers:
  :a Float64 dims: Dim{:draw}, Dim{:chain}, Dim{:a_dim}, Dim{:run} (100×4×3×2)
  :b Float64 dims: Dim{:draw}, Dim{:chain}, Dim{:run} (100×4×2)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2023-02-17T18:47:29.679"

julia> idata_cat3.observed_data
Dataset with dimensions: Dim{:y_dim_1}
and 1 layer:
  :y Float64 dims: Dim{:y_dim_1} (10)

with metadata Dict{String, Any} with 1 entry:
  "created_at" => "2023-02-17T15:11:00.59"
```
"""
function Base.cat(data::InferenceData, others::InferenceData...; groups=keys(data), dims)
    groups_cat = map(groups) do k
        k => cat(data[k], (other[k] for other in others)...; dims=dims)
    end
    # keep other non-concatenated groups
    return merge(data, others..., InferenceData(; groups_cat...))
end

"""
    InferenceData{group_names,group_types}

Container for inference data storage using DimensionalData.

This object implements the [InferenceData schema](@extref arviz schema).

Internally, groups are stored in a `NamedTuple`, which can be accessed using
`parent(::InferenceData)`.

# Constructors

    InferenceData(groups::NamedTuple)
    InferenceData(; groups...)

Construct an inference data from either a `NamedTuple` or keyword arguments of groups.

Groups must be [`Dataset`](@ref) objects.

Instead of directly creating an [`InferenceData`](@ref), use the exported `from_xyz`
functions or [`convert_to_inference_data`](@ref).
"""
struct InferenceData{group_names,group_types<:Tuple{Vararg{Dataset}}}
    groups::NamedTuple{group_names,group_types}
    function InferenceData(
        groups::NamedTuple{group_names,<:Tuple{Vararg{Dataset}}}
    ) where {group_names}
        group_names_ordered = _reorder_group_names(Val{group_names}())
        groups_ordered = NamedTuple{group_names_ordered}(groups)
        return new{group_names_ordered,typeof(values(groups_ordered))}(groups_ordered)
    end
end
InferenceData(; kwargs...) = InferenceData(NamedTuple(kwargs))
InferenceData(data::InferenceData) = data

Base.parent(data::InferenceData) = getfield(data, :groups)

# these 3 interfaces ensure InferenceData behaves like a NamedTuple

# properties interface
"""
    propertynames(data::InferenceData) -> Tuple{Symbol}

Get names of groups
"""
Base.propertynames(data::InferenceData) = propertynames(parent(data))

"""
    getproperty(data::InferenceData, name::Symbol) -> Dataset

Get group with the specified `name`.
"""
Base.getproperty(data::InferenceData, k::Symbol) = getproperty(parent(data), k)

# indexing interface
"""
    Base.getindex(data::InferenceData, groups::Symbol; coords...) -> Dataset
    Base.getindex(data::InferenceData, groups; coords...) -> InferenceData

Return a new [`InferenceData`](@ref) containing the specified groups sliced to the
specified `coords`.

`coords` specifies a dimension name mapping to an index, a
[`DimensionalData.Selector`](@extref DimensionalData selectors), or an
[`IntervalSets.AbstractInterval`](@extref).

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

Select data from just the posterior, returning a [`Dataset`](@ref) if the indices index more
than one element from any of the variables:

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
function Base.getindex(data::InferenceData, i::Int; kwargs...)
    ds = parent(data)[i]
    isempty(kwargs) && return ds
    return getindex(ds; kwargs...)
end
function Base.getindex(data::InferenceData, ks; kwargs...)
    data_new = InferenceData(parent(data)[ks])
    isempty(kwargs) && return data_new
    return getindex(data_new; kwargs...)
end
function Base.getindex(data::InferenceData; kwargs...)
    # if a single index is requested, then the return type of each group
    # will be a `Dataset` if the group has other dimensions or `NamedTuple`
    # if it has no other dimensions.
    # So we promote to an array of indices
    new_kwargs = map(index_to_indices, NamedTuple(kwargs))
    groups = map(parent(data)) do ds
        return getindex(ds; new_kwargs...)
    end
    return InferenceData(groups)
end

"""
    Base.setindex(data::InferenceData, group::Dataset, name::Symbol) -> InferenceData

Create a new [`InferenceData`](@ref) containing the `group` with the specified `name`.

If a group with `name` is already in `data`, it is replaced.
"""
function Base.setindex(data::InferenceData, v, k::Symbol)
    return InferenceData(Base.setindex(parent(data), v, k))
end

# iteration interface
Base.keys(data::InferenceData) = keys(parent(data))
Base.haskey(data::InferenceData, k::Symbol) = haskey(parent(data), k)
Base.values(data::InferenceData) = values(parent(data))
Base.pairs(data::InferenceData) = pairs(parent(data))
Base.length(data::InferenceData) = length(parent(data))
Base.iterate(data::InferenceData, i...) = iterate(parent(data), i...)
Base.eltype(data::InferenceData) = eltype(parent(data))

function Base.show(io::IO, ::MIME"text/plain", data::InferenceData)
    print(io, "InferenceData with groups:")
    prefix = "\n  > "
    for name in groupnames(data)
        print(io, prefix, name)
    end
    return nothing
end
function Base.show(io::IO, mime::MIME"text/html", data::InferenceData)
    show(io, mime, HTML("<div>InferenceData"))
    io_ansicolor = IOBuffer()
    ctx = IOContext(io_ansicolor, :compact => true, :color => true)
    for (name, group) in pairs(groups(data))
        show(ctx, MIME"text/plain"(), group)
        printer = ANSIColoredPrinters.HTMLPrinter(io_ansicolor)
        show(io, mime, HTML("""
        <details>
        <summary>$name</summary>
        """))
        show(io, mime, printer)
        show(io, mime, HTML("""
        </details>
        """))
        take!(io_ansicolor)  # reset the buffer
    end
    return show(io, mime, HTML("</div>"))
end

"""
    groups(data::InferenceData)

Get the groups in `data` as a named tuple mapping symbols to [`Dataset`](@ref)s.
"""
groups(data::InferenceData) = parent(data)

"""
    groupnames(data::InferenceData)

Get the names of the groups (datasets) in `data` as a tuple of symbols.
"""
groupnames(data::InferenceData) = keys(groups(data))

"""
    hasgroup(data::InferenceData, name::Symbol) -> Bool

Return `true` if a group with name `name` is stored in `data`.
"""
hasgroup(data::InferenceData, name::Symbol) = haskey(data, name)

@generated function _reorder_group_names(::Val{names}) where {names}
    lt = (a, b) -> (a isa Integer && b isa Integer) ? a < b : string(a) < string(b)
    return Tuple(sort(collect(names); lt, by=k -> get(SCHEMA_GROUPS_DICT, k, string(k))))
end

@generated _keys_and_types(::NamedTuple{keys,types}) where {keys,types} = (keys, types)

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
    groups_old = groups(data)
    names_new = map(k -> get(keymap, k, k), propertynames(groups_old))
    groups_new = NamedTuple{names_new}(Tuple(groups_old))
    return InferenceData(groups_new)
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
┌ 100×8×3 Dataset ┐
├─────────────────┴──────────────────────────────────── dims ┐
  ↓ draw,
  → chain,
  ↗ a_dim Categorical{String} ["x", …, "z"] ForwardOrdered
├──────────────────────────────────────────────────── layers ┤
  :a eltype: Float64 dims: draw, chain, a_dim size: 100×8×3
  :b eltype: Float64 dims: draw, chain size: 100×8
├────────────────────────────────────────────────── metadata ┤
  Dict{String, Any} with 1 entry:
  "created_at" => "2025-07-25T10:11:18.92"
```

Alternatively, we can concatenate along a new `run` dimension, which will be created.

```jldoctest cat
julia> idata_cat2 = cat(idata, idata; dims=:run)
InferenceData with groups:
  > posterior

julia> idata_cat2.posterior
┌ 100×4×3×2 Dataset ┐
├───────────────────┴───────────────────────────────────────── dims ┐
  ↓ draw,
  → chain,
  ↗ a_dim Categorical{String} ["x", …, "z"] ForwardOrdered,
  ⬔ run
├─────────────────────────────────────────────────────────── layers ┤
  :a eltype: Float64 dims: draw, chain, a_dim, run size: 100×4×3×2
  :b eltype: Float64 dims: draw, chain, run size: 100×4×2
├───────────────────────────────────────────────────────── metadata ┤
  Dict{String, Any} with 1 entry:
  "created_at" => "2025-07-25T10:11:18.92"
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
┌ 100×4×3×2 Dataset ┐
├───────────────────┴───────────────────────────────────────── dims ┐
  ↓ draw,
  → chain,
  ↗ a_dim Categorical{String} ["x", …, "z"] ForwardOrdered,
  ⬔ run
├─────────────────────────────────────────────────────────── layers ┤
  :a eltype: Float64 dims: draw, chain, a_dim, run size: 100×4×3×2
  :b eltype: Float64 dims: draw, chain, run size: 100×4×2
├───────────────────────────────────────────────────────── metadata ┤
  Dict{String, Any} with 1 entry:
  "created_at" => "2025-07-25T10:11:18.92"

julia> idata_cat3.observed_data
┌ 10-element Dataset ┐
├────────────────────┴───────────────── dims ┐
  ↓ y_dim_1
├──────────────────────────────────── layers ┤
  :y eltype: Float64 dims: y_dim_1 size: 10
├────────────────────────────────────────────┴ metadata ┐
  Dict{String, Any} with 1 entry:
  "created_at" => "2025-07-25T10:11:18.951"
```
"""
function Base.cat(data::InferenceData, others::InferenceData...; groups=keys(data), dims)
    groups_cat = map(groups) do k
        k => cat(data[k], (other[k] for other in others)...; dims=dims)
    end
    # keep other non-concatenated groups
    return merge(data, others..., InferenceData(; groups_cat...))
end

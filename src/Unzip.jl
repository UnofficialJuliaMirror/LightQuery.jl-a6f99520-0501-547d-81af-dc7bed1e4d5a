struct ModelArray{ElementType, NumberOfDimensions, Model, Rest <: Tuple} <:
    AbstractArray{ElementType, NumberOfDimensions}
    model::Model
    rest::Rest
end
ModelArray(model, rest...) =
    ModelArray{
        Tuple{eltype(model), eltype.(rest)...},
        ndims(model),
        typeof(model),
        typeof(rest)
    }(model, rest)
axes(array::ModelArray) = axes(array.model)
size(array::ModelArray) = size(array.model)
IndexStyle(array::ModelArray) = IndexStyle(array.model)
arrays(m::ModelArray) = (m.model, m.rest...)
@propagate_inbounds function getindex(array::ModelArray, index...)
    @propagate_inbounds inner(x) = x[index...]
    inner.(arrays(array))
end
@propagate_inbounds function setindex!(array::ModelArray, value, index...)
    @propagate_inbounds inner(x, value) = x[index...] = value
    inner.(arrays(array), value)
end

push!(array::ModelArray, value::Tuple) = push!.(arrays(array), value)
similar(array::ModelArray, ::Type{ElementType}, dims::Dims) where ElementType =
    ModelArray(ntuple(index -> Array{
        try
            fieldtype(ElementType, index)
        catch
            Any
        end
    }(undef, dims...), length(arrays(array)))...)
empty(array::ModelArray{T}, ::Type{U} = T) where {T, U} = similar(array, U)

export unzip
"""
    unzip(it, n)

Unzip an iterator `it` which returns tuples of length `n`.

```jldoctest
julia> using LightQuery

julia> f(x) = (x, x + 1.0);

julia> unzip(over([1], f), 2)
([1], [2.0])

julia> unzip(over([1, missing], f), 2);

julia> unzip(zip([1], [1.0]), 2)
([1], [1.0])

julia> unzip([(1, 1.0)], 2)
([1], [1.0])
```
"""
@inline unzip(it, n) = arrays(_collect(
    ModelArray(ntuple(x -> 1:1, n)...),
    it,
    IteratorEltype(it),
    IteratorSize(it)
))

maybe_setindex_widen_up_to(dest::AbstractArray{T}, el, i) where T =
    if isa(el, T)
        @inbounds dest[i] = el
        dest
    else
        setindex_widen_up_to(dest, el, i)
    end

setindex_widen_up_to(dest::ModelArray, el, i) =
    ModelArray(maybe_setindex_widen_up_to.(arrays(dest), el, i)...)

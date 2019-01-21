module LightQuery

using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown, StepRange, @propagate_inbounds, _collect, @default_eltype
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length, IndexStyle, getindex, setindex!, push!, similar, merge, view, isless, setindex_widen_up_to, collect, empty
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")

export Name
"""
    struct Name{T} end

```jldoctest
julia> using LightQuery

julia> Name(:a)((a = 1, b = 2.0,))
1

julia> merge(Name(:a), Name(:b))
Names{(:a, :b)}()
```
"""
struct Name{T} end
@inline Name(x) = Name{x}()
@inline (::Name{T})(x) where T = getproperty(x, T)

export Names
"""
    struct Names{T} end

```jldoctest
julia> using LightQuery

julia> Names(:a)((a = 1, b = 2.0,))
(a = 1,)
```
"""
struct Names{T} end
@inline Names(args...) = Names{args}()
(::Names{T})(x) where T = select(x, Names{T}())

@inline inner(n::Name{T}) where T = T
merge(ns::Name...) = Names{inner.(ns)}()

export unname
"""
    unname

```jldoctest
julia> using LightQuery

julia> unname((a = 1, b = 2.0))
(1, 2.0)

julia> unname((1, 2.0))
(1, 2.0)

julia> struct Triple{T1, T2, T3}
            first::T1
            second::T2
            third::T3
        end;

julia> unname(Triple(1, 1.0, "a"))
(1, 1.0, "a")

```
"""
function unname(data)
    names = propertynames(data)
    map(
        name -> getproperty(data, name),
        names
    )
end
unname(data::Tuple) = data
unname(data::NamedTuple) = Tuple(data)

export named
"""
    named(data)

```jldoctest
julia> using LightQuery

julia> named((a = 1, b = 2.0))
(a = 1, b = 2.0)

julia> struct Triple{T1, T2, T3}
            first::T1
            second::T2
            third::T3
        end;

julia> named(Triple(1, 1.0, "a"))
(first = 1, second = 1.0, third = "a")
```
"""
named(data) = NamedTuple{propertynames(data)}(unname(data))
named(data::NamedTuple) = data

export name
"""
    name(data, names...)

```jldoctest
julia> using LightQuery

julia> name((a = 1, b = 2.0), :c, :d)
(c = 1, d = 2.0)
```
"""
name(data, names::Names{T}) where T = NamedTuple{T}(unname(data))
@inline name(data, names...) = name(data, Names{names}())

export based_on
"""
    based_on(data; assignments...)

```jldoctest
julia> using LightQuery

julia> based_on((a = 1, b = 2.0), c = @_ _.a + _.b)
(c = 3.0,)
```
"""
based_on(data; assignments...) = map(f -> f(data), assignments.data)

export transform
"""
    transform(data; assignments...)

```jldoctest
julia> using LightQuery

julia> transform((a = 1, b = 2.0), c = @_ _.a + _.b)
(a = 1, b = 2.0, c = 3.0)
```
"""
transform(data; assignments...) = merge(named(data), based_on(data; assignments...))

export gather
"""
    gather(data, new_column, columns...)

```jldoctest
julia> using LightQuery

julia> gather((a = 1, b = 2.0, c = "c"), :d, :a, :c)
(b = 2.0, d = (a = 1, c = "c"))
```
"""
function gather(data, new_column::Name, columns::Names)
    merge(
        remove(data, columns),
        name(tuple(select(data, columns)), merge(new_column))
    )
end

@inline gather(data, new_column, columns...) = gather(data, Name{new_column}(), Names{columns}())

export spread
"""
    spread(data, column::Name)

```jldoctest
julia> using LightQuery

julia> spread((b = 2.0, d = (a = 1, c = "c")), :d)
(b = 2.0, a = 1, c = "c")
```
"""
function spread(data, column::Name)
    merge(
        remove(data, merge(column)),
        column(data)
    )
end
@inline spread(data, column) = spread(data, Name{column}())

export rename
"""
    rename(data; renames...)

For type stability, use [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> rename((a = 1, b = 2.0), c = Name(:a))
(b = 2.0, c = 1)
```
"""
function rename(data; renames...)
    olds = merge(Tuple(renames.data)...)
    merge(
        remove(data, olds),
        name(unname(select(data, olds)), Names(keys(renames)...))
    )
end

export select
"""
    select(data, columns...)

```jldoctest
julia> using LightQuery

julia> select((a = 1, b = 2.0), :a)
(a = 1,)
```
"""
select(data, columns::Names{T}) where T =
    name(map(
        name -> getproperty(data, name),
        T
    ), columns)

@inline select(data, columns...) = select(data, Names{columns}())

export remove
"""
    remove(data, columns...)

```jldoctest
julia> using LightQuery

julia> remove((a = 1, b = 2.0), :b)
(a = 1,)
```
"""
remove(data, columns::Names{T}) where T =
    select(data, Names{diff_names(propertynames(data), T)}())

@inline remove(data, columns...) = remove(data, Names{columns}())

export in_common
"""
    in_common(data1, data2)

```jldoctest
julia> using LightQuery

julia> in_common((a = 1, b = 2.0), (a = 1, c = "3"))
Names{(:a,)}()
```
"""
function in_common(data1, data2)
    data1_names = propertynames(data1)
    data2_names = propertynames(data2)
    Names{diff_names(data1_names, diff_names(data1_names, data2_names))}()
end

export rows
"""
    rows(n::NamedTuple)

```jldoctest
julia> using LightQuery

julia> rows((a = [1, 2], b = [2, 1])) |> first
(a = 1, b = 2)
```
"""
function rows(n::NamedTuple)
	construct = NamedTuple{propertynames(n)}
	Generator(construct, zip(Tuple(n)...))
end

# I'm actually super proud of this one.
export separate
"""
    separate(it, into_names...)

Optimize with column-wise storage.

```jldoctest
julia> using LightQuery

julia> it = [(a = 1, b = 1.0), (a = 2, b = 2.0)];

julia> result = separate(it, :a, :b)
Base.Generator{Base.Iterators.Zip{Tuple{Array{Int64,1},Array{Float64,1}}},Type{NamedTuple{(:a, :b),T} where T<:Tuple}}(NamedTuple{(:a, :b),T} where T<:Tuple, Base.Iterators.Zip{Tuple{Array{Int64,1},Array{Float64,1}}}(([1, 2], [1.0, 2.0])))

julia> first(result)
(a = 1, b = 1.0)
```
"""
separate(it, into_names::Names{T}) where T =
    rows(name(unzip(Generator(unname, it), length(T)), into_names))

@inline separate(it, into_names...) = separate(it, Names{into_names}())

export column
"""
    column(it, names::Names)

```jldoctest
julia> using LightQuery

julia> it = [(a = 1, b = 1.0), (a = 2, b = 2.0)];

julia> collect(column(it, :a))
2-element Array{Int64,1}:
 1
 2
```
"""
column(it, name::Name) = Generator(name, it)
@inline column(it, name) = column(it, Name{name}())

end

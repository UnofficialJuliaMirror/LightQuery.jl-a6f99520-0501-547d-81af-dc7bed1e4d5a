export By
"""
	By(it, f)

Marks that `it` has been pre-sorted by the key `f`. For use with
[`Group`](@ref) or [`LeftJoin`](@ref).
"""
struct By{It, F}
    it::It
	f::F
end

export order_by
"""
	order_by(it, f)

Generalized sort. Will return a [`By`](@ref) object.

```jldoctest
julia> using LightQuery

julia> order_by(["b", "a"], identity).it
2-element view(::Array{String,1}, [2, 1]) with eltype String:
 "a"
 "b"
```
"""
order_by(it, f) =
	By(view(it, mappedarray(first,
		sort!(collect(enumerate(Generator(f, it))), by = last))), f)

state_to_index(s::AbstractArray, state) = state[2]
state_to_index(it::Array, state::Int) = state
state_to_index(g::Generator, state) = state_to_index(g.iter, state)
state_to_index(z::Zip, t::Tuple) = state_to_index(z.is[1], t[1])
state_to_index(s::StepRange, t::Tuple) = t[2] + 1

export Group
struct Group{F, It}
	f::F
	it::It
end

Group(b::By) = Group(b.f, b.it)

IteratorSize(g::Group) = SizeUnknown()
IteratorEltype(g::Group) = EltypeUnknown()

"""
    group(b::By)

Group consecutive keys in `b`. Requires a presorted object (see [`By`](@ref)).

```jldoctest
julia> using LightQuery

julia> Group(By([1, 3, 2, 4], iseven)) |> collect
2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:
 0 => [1, 3]
 1 => [2, 4]
```
"""
Group(b::By) = Group(b.f, b.it)

function iterate(g::Group)
	item, state = @ifsomething iterate(g.it)
	iterate(g::Group, (state, state_to_index(g.it, state) - 1, g.f(item)))
end
iterate(g::Group, ::Nothing) = nothing
function iterate(g::Group, (state, left_index, last_result))
	item_state = iterate(g.it, state)
	if item_state === nothing
		last_result => view(g.it, left_index:length(g.it)), nothing
	else
		item, state = item_state
		result = g.f(item)
		if isequal(result, last_result)
			iterate(g, (state, left_index, last_result))
		else
			right_index = state_to_index(g.it, state) - 1
			last_result => view(g.it, left_index:right_index - 1), (state, right_index, result)
		end
	end
end

struct History{S, I, R}
	state::S
	item::I
	result::R
end

History(b::By, ::Nothing) = nothing
function History(b::By, item_state)
	item, state = item_state
	History(state, item, b.f(item))
end

next_history(b::By) = History(b, iterate(b.it))
next_history(b::By, h::History) = History(b, iterate(b.it, h.state))
isless(h1::History, h2::History) = isless(h1.result, h2.result)

export LeftJoin
"""
	LeftJoin(left::By, right::By)

For each value in left, look for a value with the same key in right. Requires
both to be presorted (see [`By`](@ref)).

```jldoctest
julia> using LightQuery

julia> LeftJoin(
            By([1, 2, 5, 6], identity),
            By([1, 3, 4, 6], identity)
       ) |> collect
4-element Array{Pair{Int64,Union{Missing, Int64}},1}:
 1 => 1
 2 => missing
 5 => missing
 6 => 6
```
"""
struct LeftJoin{Left <: By, Right <: By}
	left::Left
	right::Right
end

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(l::LeftJoin) = combine_iterator_eltype(
	IteratorEltype(l.left.it),
	IteratorEltype(l.right.it)
)
eltype(l::LeftJoin) = Pair{
    eltype(l.left.it),
    Union{Missing, eltype(l.right.it)}
}
IteratorSize(l::LeftJoin) = IteratorSize(l.left.it)
length(l::LeftJoin) = length(l.left.it)
size(l::LeftJoin) = size(l.left.it)
function iterate(l::LeftJoin)
	left_match = @ifsomething next_history(l.left)
	seek_right_match(l, left_match, next_history(l.right))
end
iterate(l::LeftJoin, ::Nothing) = nothing
function iterate(l::LeftJoin, (left_history, right_history))
	left_history = @ifsomething next_history(l.left, left_history)
    seek_right_match(l, left_history, right_history)
end
seek_right_match(l, left_history, ::Nothing) =
	(left_history.item => missing), nothing
function seek_right_match(l, left_history, right_history)
	while isless(right_history, left_history)
		right_history = next_history(l.right, right_history)
        if right_history === nothing
            return (left_history.item => missing), nothing
        end
	end
	if isless(left_history, right_history)
		# no way we can find any more matches to left item
		(left_history.item => missing), (left_history, right_history)
	else
        # they are equal
		(left_history.item => right_history.item), (left_history, right_history)
	end
end

export over
"""
	over(it, f)

Hackable reversed version of `Base.Generator`.

```jldoctest
julia> using LightQuery

julia> over([1, 2], x -> x + 1) |> collect
2-element Array{Int64,1}:
 2
 3
```
"""
over(it, f) = Generator(f, it)

export when
"""
	when(it, f)

Hackable reversed version of `Base.Iterators.Filter`.

```jldoctest
julia> using LightQuery

julia> when([1, 2], x -> x > 1) |> collect
1-element Array{Int64,1}:
 2
```
"""
when(x, f) = Filter(f, x)

# piracy
axes(g::Generator, args...) = axes(g.iter, args...)
axes(z::Zip, args...) = axes(z.is[1], args...)
view(g::Generator, args...) = Generator(g.f, view(g.iter, args...))
view(z::Zip, args...) = zip(map(
	i -> view(i, args...),
	z.is
)...)
IteratorSize(g::Generator) = IteratorSize(g.iter)
getindex(z::Zip, args...) = zip(map(
	i -> getindex(i, args...),
	z.is
)...)
getindex(g::Generator, args...) = Generator(g.f, getindex(g.iter, args...))

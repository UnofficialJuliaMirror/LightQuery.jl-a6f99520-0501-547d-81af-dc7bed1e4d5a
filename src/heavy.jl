"""
    when_columns(columns, a_function)

An eager and column-wise alternative to [`when`](@ref).

```jldoctest
julia> using LightQuery

julia> @name when_columns((a = [1, 2], b = [1, 2]), @_ _.a > 1)
((`a`, [2]), (`b`, [2]))
```
"""
function when_columns(columns, a_function)
    make_columns(when(Rows(columns), a_function))
end
export when_columns

"""
    add_columns(columns, a_function)

An eager and column-wise alternative to [`over`](@ref).

```jldoctest
julia> using LightQuery

julia> @name add_columns((a = [1], b = [1]), @_ (c = _.a + _.b,))
((`a`, [1]), (`b`, [1]), (`c`, [2]))
```
"""
function add_columns(columns, a_function)
    columns..., make_columns(over(Rows(columns), a_function))...
end
export add_columns

"""
    order_columns(columns, a_function)

An eager and column-wise alternative to [`order`](@ref).

```jldoctest
julia> using LightQuery

julia> @name order_columns((a = [2, 1], b = [2, 1]), :a)
((`a`, [1, 2]), (`b`, [1, 2]))
```
"""
function order_columns(columns, a_function)
    make_columns(order(Rows(columns), a_function))
end
export order_columns

function one_to_many(one_row, many_rows)
    over(many_rows,
        let one_row = one_row
            function merge_capture(many_row)
                merge(one_row, many_row)
            end
        end
    )
end

function many_to_one(one_row, many_rows)
    over(many_rows,
        let one_row = one_row
            function merge_capture(many_row)
                merge(many_row, one_row)
            end
        end
    )
end

function inner_join_pair((one_row, (key2, many_rows)))
    one_to_many(one_row, many_rows)
end

"""
    inner_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name inner_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, [1, 1]), (`a`, [1, 1]), (`c`, [1, 1]))
```
"""
function inner_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    make_columns(flatten(over(mix((Name{:inner}()),
        By(Rows(one_columns), both_names),
        By(Group(By(Rows(many_columns), both_names)), first)
    ), inner_join_pair)))
end
export inner_join

function left_join_pair((one_row, (key2, many_rows)), dummy_many_row)
    many_to_one(one_row, many_rows)
end

function left_join_pair((one_row, zilch)::Tuple{Any, Missing}, dummy_many_row)
    (merge(dummy_many_row, one_row),)
end

make_dummy((name, value)) = (name, missing)

"""
    left_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name left_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`c`, Union{Missing, Int64}[1, 1, missing]), (`a`, [1, 1, 2]), (`b`, [1, 1, 2]))
```
"""
function left_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    make_columns(flatten(over(
        mix(Name{:left}(),
            By(Rows(one_columns), both_names),
            By(Group(By(Rows(many_columns), both_names)), first)
        ),
        let dummy_many_row = map_unrolled(make_dummy, many_columns)
            function left_join_pair_capture(nested)
                left_join_pair(nested, dummy_many_row)
            end
        end
    )))
end
export left_join

function right_join_pair((one_row, (key2, many_rows)), dummy_one_row)
    one_to_many(one_row, many_rows)
end

function right_join_pair((zilch, (key2, many_rows))::Tuple{Missing, Any}, dummy_one_row)
    one_to_many(dummy_one_row, many_rows)
end

"""
    right_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name right_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, Union{Missing, Int64}[1, 1, missing]), (`a`, [1, 1, 3]), (`c`, [1, 1, 3]))
```
"""
function right_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    make_columns(flatten(over(
        mix(Name{:right}(),
            By(Rows(one_columns), both_names),
            By(Group(By(Rows(many_columns), both_names)), first)
        ),
        let dummy_one_row = map_unrolled(make_dummy, one_columns)
            function right_join_pair_capture(nested)
                right_join_pair(nested, dummy_one_row)
            end
        end
    )))
end
export right_join

function outer_join_pair((one_row, (key2, many_rows)), dummy_one_row, dummy_many_row)
    one_to_many(one_row, many_rows)
end

function outer_join_pair((zilch, (key2, many_rows))::Tuple{Missing, Any}, dummy_one_row, dummy_many_row)
    one_to_many(dummy_one_row, many_rows)
end

function outer_join_pair((one_row, zilch)::Tuple{Any, Missing}, dummy_one_row, dummy_many_row)
    (merge(dummy_many_row, one_row),)
end

function outer_join((zilch, zilch)::Tuple{Missing, Missing}, dummy_one_row, dummy_many_row)
    (merge(dummy_many_row, dummy_one_row),)
end

"""
    outer_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name outer_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, Union{Missing, Int64}[1, 1, 2, missing]), (`a`, [1, 1, 2, 3]), (`c`, Union{Missing, Int64}[1, 1, missing, 3]))
```
"""
function outer_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    make_columns(flatten(over(
        mix(Name{:outer}(),
            By(Rows(one_columns), both_names),
            By(Group(By(Rows(many_columns), both_names)), first)
        ),
        let dummy_one_row = map_unrolled(make_dummy, one_columns),
            dummy_many_row = map_unrolled(make_dummy, many_columns)
            function outer_join_pair_capture(nested)
                outer_join_pair(nested, dummy_one_row, dummy_many_row)
            end
        end
    )))
end
export outer_join

"""
    group_columns(columns, group_function, summarize_function)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns.

```jldoctest
julia> using LightQuery

julia> @name @> (a = [1, 1, 2, 2], b = [1, 2, 3, 4]) |>
        summarize_by(_, (:a,), @_ (c = sum(_.b),))
((`a`, [1, 2]), (`c`, [3, 7]))
```
"""
function summarize_by(columns, group_function, summarize_function)
    make_columns(over(
        Group(By(Rows(columns), group_function)),
        let summarize_function = summarize_function
            function replacement((a_key, rows))
                a_key..., summarize_function(to_columns(rows))...
            end
        end
    ))
end
export summarize_by

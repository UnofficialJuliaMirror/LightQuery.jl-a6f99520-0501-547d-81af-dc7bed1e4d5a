module LightQuery

import MacroTools: @capture
import Base.Meta: quot
import Base: Generator

export Nameless

"A container for a function and the expression that generated it"
struct Nameless{F}
    f::F
    expression::Expr
end

(nameless::Nameless)(arguments...; keyword_arguments...) =
    nameless.f(arguments...; keyword_arguments...)

substitute_underscores!(dictionary, body) = body
substitute_underscores!(dictionary, body::Symbol) =
    if all(isequal('_'), string(body))
        if !haskey(dictionary, body)
            dictionary[body] = gensym("argument")
        end
        dictionary[body]
    else
        body
    end
substitute_underscores!(dictionary, body::Expr) =
    if body.head == :quote
        body
    elseif @capture body @_ args__
        body
    else
        Expr(body.head,
            map(body -> substitute_underscores!(dictionary, body), body.args)
        ...)
    end

string_length(something) = something |> String |> length

function unname(body, line, file)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    sorted_dictionary = sort(
        lt = (pair1, pair2) ->
            isless(string_length(pair1.first), string_length(pair2.first)),
        collect(dictionary)
    )
    Expr(:call, Nameless, Expr(:->,
        Expr(:tuple, (pair.second for pair in sorted_dictionary)...),
        Expr(:block, LineNumberNode(line, file), new_body)
    ), quot(body))
end

export @_
"""
    macro _(body::Expr)

Create an `Nameless` object. The arguments are inside the body; the
first arguments is `_`, the second argument is `__`, etc. Also stores a
quoted version of the function.

```jldoctest
julia> using LightQuery

julia> 1 |> @_(_ + 1)
2

julia> map(@_(__ - _), (1, 2), (2, 1))
(1, -1)

julia> @_(_ + 1).expression
:(_ + 1)
```
"""
macro _(body::Expr)
    unname(body, @__LINE__, @__FILE__) |> esc
end

end

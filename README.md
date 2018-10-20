# LightQuery

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://bramtayl.github.io/LightQuery.jl/latest)
[![Build Status](https://travis-ci.org/bramtayl/LightQuery.jl.svg?branch=master)](https://travis-ci.org/bramtayl/LightQuery.jl)
[![CodeCov](https://codecov.io/gh/bramtayl/LightQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bramtayl/LightQuery.jl)

Hey look, I've decided to write real documentation this time!

LightQuery contains a super light-weight surface level querying macro. All it
does is put a query into a form that is easily digestible by most query
packages. As a single macro which unifies all querying macros, you can compare
it to a general theory of everything, or one ring to rule them all. Ok, ok, I
might be getting carried away with delusions of granduer.

A key concept to understand is anonymouser functions. Anonymouser functions
always have same arguments: the first is `_`, the second is `__` (two
underscores), etc. This is just as functional as regular anonymous functions but
every so slightly terser. You can choose how many arguments your anonymouser
function takes simply by including or not including underscore arguments in the
body of the function. You can experiment with anonymouser functions using the
`@_` macro in this package.

A second key concept to understand is the requirements of query packages.
Most query verb require two different kinds of arguments. The first kind are
data arguments and the second kind are transformation arguments. For example,
a filter query takes a data source and a procedure for sifting rows. The first
kind you want to pass in as is, and the second kind you want to pass in as
anonymous functions. But what if you are feeding SQL to an external
program? An anonymous function is going to do no good. You additionally need the
code of the procedure to transform it into SQL.

In `@query`, attach a number to the end of all query verbs. For example, joins
typically take two data sources, so you might try something like this:
`join2(source1, source2, row_match_procedure)`. The macro will use the number
2 to know to keep the first two arguments as is; the rest of the arguments
will be passed in as both anonymous functions and raw code. If you use a verb
ending without a number, this step will be skipped.

The final key concept is chaining. `@query` only recognizes query verbs in the
tails of chains. After the above processing is complete, the remaining code
in each tail is interpreted as one big anonymouser function. So if you use
functions without numbers, `@query` can be used as a plain and simple chaining
syntax as well.

If you're an author of a query-like package, chances are, you only will need a
few method wrappers to make your package compatible with LightQuery. Then, 
users can use LightQuery to easily mix and match various backends. Here's an
example. First, make the wrappers.

```julia
using LightQuery: @query

import DataFramesMeta: AbstractDataFrame, where
where(d::AbstractDataFrame, f_tuple::Tuple{Function, Expr}) = where(d, f_tuple[1])

import QueryOperators: Enumerable, orderby, query
orderby(source::Enumerable, f_tuple::Tuple{Function, Expr}) = orderby(source, f_tuple...)
```

Now mix and match!

```julia
julia> @query DataFrame(a = [0, 1, 2], b = [2, 1, 0]) |>
           where1(_, _.a .> 0) |>
           query(_) |>
           orderby1(_, _.b)
2x2 query result
a │ b
──┼──
2 │ 0
1 │ 1
```

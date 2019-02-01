# LightQuery.jl

```@index
```


```@autodocs
Modules = [LightQuery]
```

# Tutorial

For an example of how to use this package, see the demo below, which follows the
example [here](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html).
A copy of the flights data is included in the test folder of this package.

The biggest difference between this package and dplyr is that you have to
explicitly move your data back and forth between rows (a vector of named tuples)
and columns (a named tuple of vectors) depending on the kind of operation you
want to do. Another inconvenience is that when you are moving from rows to
columns, in many cases, you will have to re-specify the column names (except in
certain cases). This is inconvenient but prevents this package from having to
rely on inference.

You can easily convert most objects to named tuples using `named_tuple`.
As a named tuple, the data will be in a column-wise form. If you want to display
it, you can use `pretty` to hack the show methods of `DataFrame`s.

So read in flights, convert it into a named tuple, and remove the row-number
column (which reads in without a name). This package comes with its own chaining
macro `@>`, which I'll make heavy use of. I've reexported CSV from the CSV
package for convenient IO.

```jldoctest dplyr
julia> using LightQuery

julia> flights =
          @> CSV.read("flights.csv", missingstring = "NA") |>
          named_tuple |>
          remove(_, Symbol(""));

julia> pretty(flights)
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

The `rows` iterator will convert the data to row-wise form.
`when` will filter the data. You can make anonymous functions
 with `@_`.

To display row-wise data, first, convert back to a columns-wise format with
`columns`.

```jldoctest dplyr
julia> using LightQuery

julia> @> flights |>
          rows |>
          when(_, @_ _.month == 1 && _.day == 1) |>
          autocolumns |>
          pretty
842×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1   │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2   │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3   │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4   │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5   │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6   │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7   │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 835 │ 2013   │ 1      │ 1      │ 2343     │ 1724           │ 379       │
│ 836 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │
│ 837 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │
│ 838 │ 2013   │ 1      │ 1      │ 2356     │ 2359           │ -3        │
│ 839 │ 2013   │ 1      │ 1      │ missing  │ 1630           │ missing   │
│ 840 │ 2013   │ 1      │ 1      │ missing  │ 1935           │ missing   │
│ 841 │ 2013   │ 1      │ 1      │ missing  │ 1500           │ missing   │
│ 842 │ 2013   │ 1      │ 1      │ missing  │ 600            │ missing   │
```

You can arrange rows with `order`. Here, the currying version of
`select` comes in handy.

```jldoctest dplyr
julia> by_date =
          @> flights |>
          rows |>
          order(_, select(:year, :month, :day));

julia> @> by_date |>
          autocolumns |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 12     │ 31     │ missing  │ 1500           │ missing   │
│ 336770 │ 2013   │ 12     │ 31     │ missing  │ 1430           │ missing   │
│ 336771 │ 2013   │ 12     │ 31     │ missing  │ 855            │ missing   │
│ 336772 │ 2013   │ 12     │ 31     │ missing  │ 705            │ missing   │
│ 336773 │ 2013   │ 12     │ 31     │ missing  │ 825            │ missing   │
│ 336774 │ 2013   │ 12     │ 31     │ missing  │ 1615           │ missing   │
│ 336775 │ 2013   │ 12     │ 31     │ missing  │ 600            │ missing   │
│ 336776 │ 2013   │ 12     │ 31     │ missing  │ 830            │ missing   │
```

You can also pass in keyword arguments to `sort!` via `order`, like
`rev = true`. The difference from the dplyr output here is caused by how `sort!`
handles missing data in Julia (I think).

```jldoctest dplyr
julia> @> flights |>
          rows |>
          order(_, select(:arr_delay), rev = true) |>
          autocolumns |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 1525     │ 1530           │ -5        │
│ 2      │ 2013   │ 1      │ 1      │ 1528     │ 1459           │ 29        │
│ 3      │ 2013   │ 1      │ 1      │ 1740     │ 1745           │ -5        │
│ 4      │ 2013   │ 1      │ 1      │ 1807     │ 1738           │ 29        │
│ 5      │ 2013   │ 1      │ 1      │ 1939     │ 1840           │ 59        │
│ 6      │ 2013   │ 1      │ 1      │ 1952     │ 1930           │ 22        │
│ 7      │ 2013   │ 1      │ 1      │ 2016     │ 1930           │ 46        │
⋮
│ 336769 │ 2013   │ 5      │ 7      │ 2054     │ 2055           │ -1        │
│ 336770 │ 2013   │ 5      │ 13     │ 657      │ 700            │ -3        │
│ 336771 │ 2013   │ 5      │ 2      │ 1926     │ 1929           │ -3        │
│ 336772 │ 2013   │ 5      │ 4      │ 1816     │ 1820           │ -4        │
│ 336773 │ 2013   │ 5      │ 2      │ 1947     │ 1949           │ -2        │
│ 336774 │ 2013   │ 5      │ 6      │ 1826     │ 1830           │ -4        │
│ 336775 │ 2013   │ 5      │ 20     │ 719      │ 735            │ -16       │
│ 336776 │ 2013   │ 5      │ 7      │ 1715     │ 1729           │ -14       │
```

In the original column-wise form, you can `select` or `remove` columns.

```jldoctest dplyr
julia> @> flights |>
          select(_, :year, :month, :day) |>
          pretty
336776×3 DataFrames.DataFrame
│ Row    │ year   │ month  │ day    │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │
├────────┼────────┼────────┼────────┤
│ 1      │ 2013   │ 1      │ 1      │
│ 2      │ 2013   │ 1      │ 1      │
│ 3      │ 2013   │ 1      │ 1      │
│ 4      │ 2013   │ 1      │ 1      │
│ 5      │ 2013   │ 1      │ 1      │
│ 6      │ 2013   │ 1      │ 1      │
│ 7      │ 2013   │ 1      │ 1      │
⋮
│ 336769 │ 2013   │ 9      │ 30     │
│ 336770 │ 2013   │ 9      │ 30     │
│ 336771 │ 2013   │ 9      │ 30     │
│ 336772 │ 2013   │ 9      │ 30     │
│ 336773 │ 2013   │ 9      │ 30     │
│ 336774 │ 2013   │ 9      │ 30     │
│ 336775 │ 2013   │ 9      │ 30     │
│ 336776 │ 2013   │ 9      │ 30     │

julia> @> flights |>
          remove(_, :year, :month, :day) |>
          pretty
336776×16 DataFrames.DataFrame. Omitted printing of 11 columns
│ Row    │ dep_time │ sched_dep_time │ dep_delay │ arr_time │ sched_arr_time │
│        │ Int64⍰   │ Int64⍰         │ Int64⍰    │ Int64⍰   │ Int64⍰         │
├────────┼──────────┼────────────────┼───────────┼──────────┼────────────────┤
│ 1      │ 517      │ 515            │ 2         │ 830      │ 819            │
│ 2      │ 533      │ 529            │ 4         │ 850      │ 830            │
│ 3      │ 542      │ 540            │ 2         │ 923      │ 850            │
│ 4      │ 544      │ 545            │ -1        │ 1004     │ 1022           │
│ 5      │ 554      │ 600            │ -6        │ 812      │ 837            │
│ 6      │ 554      │ 558            │ -4        │ 740      │ 728            │
│ 7      │ 555      │ 600            │ -5        │ 913      │ 854            │
⋮
│ 336769 │ 2307     │ 2255           │ 12        │ 2359     │ 2358           │
│ 336770 │ 2349     │ 2359           │ -10       │ 325      │ 350            │
│ 336771 │ missing  │ 1842           │ missing   │ missing  │ 2019           │
│ 336772 │ missing  │ 1455           │ missing   │ missing  │ 1634           │
│ 336773 │ missing  │ 2200           │ missing   │ missing  │ 2312           │
│ 336774 │ missing  │ 1210           │ missing   │ missing  │ 1330           │
│ 336775 │ missing  │ 1159           │ missing   │ missing  │ 1344           │
│ 336776 │ missing  │ 840            │ missing   │ missing  │ 1020           │
```

You can also rename columns. Because constants (currently) do not propagate
through keyword arguments in Julia, it's smart to wrap column names with
`Name`.

```jldoctest dplyr
julia> @> flights |>
          rename(_, tail_num = Name(:tailnum)) |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

You can add new columns with transform. If you want to refer to previous
columns, you'll have to transform twice.

```jldoctest dplyr
julia> @> flights |>
          transform(_,
                    gain = _.arr_delay .- _.dep_delay,
                    speed = _.distance ./ _.air_time .* 60
          ) |>
          transform(_,
                    gain_per_hour = _.gain ./ (_.air_time / 60)
          ) |>
          pretty
336776×22 DataFrames.DataFrame. Omitted printing of 16 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

No summarize here, but you can just directly access columns:

```jldoctest dplyr
julia> using Statistics: mean;

julia> mean(skipmissing(flights.dep_delay))
12.639070257304708
```

I don't provide a export a sample function here, but StatsBase does.

`Group`ing here works differently than in dplyr:

- You can only `Group` sorted data. To let Julia know that the data has been sorted, you need to explicitly wrap the data with `By`.
- It's useful to collect after `Group` for performance; this allows Julia to know the number of groups ahead of time.
- Groups return a pair, key => sub-data-frame. So:

```jldoctest dplyr
julia> by_tailnum =
          @> flights |>
          rows |>
          order(_, select(:tailnum)) |>
          By(_, select(:tailnum)) |>
          Group |>
          collect;

julia> pair = first(by_tailnum);

julia> pair.first
(tailnum = "D942DN",)

julia> @> pair.second |>
          autocolumns |>
          pretty
4×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1   │ 2013   │ 2      │ 11     │ 1508     │ 1400           │ 68        │
│ 2   │ 2013   │ 3      │ 23     │ 1340     │ 1300           │ 40        │
│ 3   │ 2013   │ 3      │ 24     │ 859      │ 835            │ 24        │
│ 4   │ 2013   │ 7      │ 5      │ 1253     │ 1259           │ -6        │
```

If you would like to combine these steps, I have provided the convenience
function `group_by`.

```jldoctest dplyr
julia> pair = first(group_by(flights, :tailnum));

julia> pair.first
(tailnum = "D942DN",)

julia> pair.second |> autocolumns |> pretty
4×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1   │ 2013   │ 2      │ 11     │ 1508     │ 1400           │ 68        │
│ 2   │ 2013   │ 3      │ 23     │ 1340     │ 1300           │ 40        │
│ 3   │ 2013   │ 3      │ 24     │ 859      │ 835            │ 24        │
│ 4   │ 2013   │ 7      │ 5      │ 1253     │ 1259           │ -6        │
```

- Third, you have to explicity use `over` to map over groups. So for example:

```jldoctest dplyr
julia> @> by_tailnum |>
          over(_, @_ begin
                    sub_frame = autocolumns(_.second)
                    transform(_.first,
                              count = length(_.second),
                              distance = sub_frame.distance |> skipmissing |> mean,
                              delay = sub_frame.arr_delay |> skipmissing |> mean
                    )
          end) |>
          columns(_, :tailnum, :count, :distance, :delay) |>
          pretty
4044×4 DataFrames.DataFrame
│ Row  │ tailnum │ count │ distance │ delay    │
│      │ String⍰ │ Int64 │ Float64  │ Float64  │
├──────┼─────────┼───────┼──────────┼──────────┤
│ 1    │ D942DN  │ 4     │ 854.5    │ 31.5     │
│ 2    │ N0EGMQ  │ 371   │ 676.189  │ 9.98295  │
│ 3    │ N10156  │ 153   │ 757.948  │ 12.7172  │
│ 4    │ N102UW  │ 48    │ 535.875  │ 2.9375   │
│ 5    │ N103US  │ 46    │ 535.196  │ -6.93478 │
│ 6    │ N104UW  │ 47    │ 535.255  │ 1.80435  │
│ 7    │ N10575  │ 289   │ 519.702  │ 20.6914  │
⋮
│ 4037 │ N996DL  │ 102   │ 897.304  │ 0.524752 │
│ 4038 │ N997AT  │ 44    │ 679.045  │ 16.3023  │
│ 4039 │ N997DL  │ 63    │ 867.762  │ 4.90323  │
│ 4040 │ N998AT  │ 26    │ 593.538  │ 29.96    │
│ 4041 │ N998DL  │ 77    │ 857.818  │ 16.3947  │
│ 4042 │ N999DN  │ 61    │ 895.459  │ 14.3115  │
│ 4043 │ N9EAMQ  │ 248   │ 674.665  │ 9.23529  │
│ 4044 │ missing │ 2512  │ 710.258  │ NaN      │
```

This is the first time in the code when inference hasn't been able to figure out
the column names for us; we need to provide it them explicitly.
Again, for convenience, I provide a `summarize` function for typical usage.
You're welcome.

```jldoctest dplyr
julia> @> by_tailnum |>
          summarize(_,
            count = length,
            distance = (@_ autocolumns(_).distance |> skipmissing |> mean),
            delay = (@_ autocolumns(_).dep_delay |> skipmissing |> mean)
          ) |>
          columns(_, :tailnum, :count, :distance, :delay) |>
          pretty
4044×4 DataFrames.DataFrame
│ Row  │ tailnum │ count │ distance │ delay    │
│      │ String⍰ │ Int64 │ Float64  │ Float64  │
├──────┼─────────┼───────┼──────────┼──────────┤
│ 1    │ D942DN  │ 4     │ 854.5    │ 31.5     │
│ 2    │ N0EGMQ  │ 371   │ 676.189  │ 8.49153  │
│ 3    │ N10156  │ 153   │ 757.948  │ 17.8151  │
│ 4    │ N102UW  │ 48    │ 535.875  │ 8.0      │
│ 5    │ N103US  │ 46    │ 535.196  │ -3.19565 │
│ 6    │ N104UW  │ 47    │ 535.255  │ 9.93617  │
│ 7    │ N10575  │ 289   │ 519.702  │ 22.6507  │
⋮
│ 4037 │ N996DL  │ 102   │ 897.304  │ 6.85149  │
│ 4038 │ N997AT  │ 44    │ 679.045  │ 17.0233  │
│ 4039 │ N997DL  │ 63    │ 867.762  │ 7.62903  │
│ 4040 │ N998AT  │ 26    │ 593.538  │ 31.96    │
│ 4041 │ N998DL  │ 77    │ 857.818  │ 23.1711  │
│ 4042 │ N999DN  │ 61    │ 895.459  │ 18.9016  │
│ 4043 │ N9EAMQ  │ 248   │ 674.665  │ 9.88235  │
│ 4044 │ missing │ 2512  │ 710.258  │ NaN      │
```

For the n-distinct example, I've switched things around to be just a smidge
more efficient. This example shows how calling `columns` is sometimes necessary
to trigger eager evaluation.

```jldoctest dplyr
julia> @> flights |>
          group_by(_, :dest, :tailnum) |>
          summarize(_, flights = length) |>
          columns(_, :dest, :tailnum, :flights) |>
          group_by(_, :dest) |>
          summarize(_,
            planes = length,
            flights = @_ sum(autocolumns(_).flights)
          ) |>
          autocolumns |>
          pretty
105×3 DataFrames.DataFrame
│ Row │ dest   │ planes │ flights │
│     │ String │ Int64  │ Int64   │
├─────┼────────┼────────┼─────────┤
│ 1   │ ABQ    │ 108    │ 254     │
│ 2   │ ACK    │ 58     │ 265     │
│ 3   │ ALB    │ 172    │ 439     │
│ 4   │ ANC    │ 6      │ 8       │
│ 5   │ ATL    │ 1180   │ 17215   │
│ 6   │ AUS    │ 993    │ 2439    │
│ 7   │ AVL    │ 159    │ 275     │
⋮
│ 98  │ STL    │ 960    │ 4339    │
│ 99  │ STT    │ 87     │ 522     │
│ 100 │ SYR    │ 383    │ 1761    │
│ 101 │ TPA    │ 1126   │ 7466    │
│ 102 │ TUL    │ 105    │ 315     │
│ 103 │ TVC    │ 60     │ 101     │
│ 104 │ TYS    │ 273    │ 631     │
│ 105 │ XNA    │ 176    │ 1036    │
```

Of course, you can group repeatedly.

```jldoctest dplyr
julia> per_day =
          @> flights |>
          group_by(_, :year, :month, :day) |>
          summarize(_, flights = length) |>
          autocolumns;

julia> pretty(per_day)
365×4 DataFrames.DataFrame
│ Row │ year  │ month │ day   │ flights │
│     │ Int64 │ Int64 │ Int64 │ Int64   │
├─────┼───────┼───────┼───────┼─────────┤
│ 1   │ 2013  │ 1     │ 1     │ 842     │
│ 2   │ 2013  │ 1     │ 2     │ 943     │
│ 3   │ 2013  │ 1     │ 3     │ 914     │
│ 4   │ 2013  │ 1     │ 4     │ 915     │
│ 5   │ 2013  │ 1     │ 5     │ 720     │
│ 6   │ 2013  │ 1     │ 6     │ 832     │
│ 7   │ 2013  │ 1     │ 7     │ 933     │
⋮
│ 358 │ 2013  │ 12    │ 24    │ 761     │
│ 359 │ 2013  │ 12    │ 25    │ 719     │
│ 360 │ 2013  │ 12    │ 26    │ 936     │
│ 361 │ 2013  │ 12    │ 27    │ 963     │
│ 362 │ 2013  │ 12    │ 28    │ 814     │
│ 363 │ 2013  │ 12    │ 29    │ 888     │
│ 364 │ 2013  │ 12    │ 30    │ 968     │
│ 365 │ 2013  │ 12    │ 31    │ 776     │

julia> per_month =
          @> per_day |>
          group_by(_, :year, :month) |>
          summarize(_, flights = @_ sum(autocolumns(_).flights)) |>
          autocolumns;

julia> pretty(per_month)
12×3 DataFrames.DataFrame
│ Row │ year  │ month │ flights │
│     │ Int64 │ Int64 │ Int64   │
├─────┼───────┼───────┼─────────┤
│ 1   │ 2013  │ 1     │ 27004   │
│ 2   │ 2013  │ 2     │ 24951   │
│ 3   │ 2013  │ 3     │ 28834   │
│ 4   │ 2013  │ 4     │ 28330   │
│ 5   │ 2013  │ 5     │ 28796   │
│ 6   │ 2013  │ 6     │ 28243   │
│ 7   │ 2013  │ 7     │ 29425   │
│ 8   │ 2013  │ 8     │ 29327   │
│ 9   │ 2013  │ 9     │ 27574   │
│ 10  │ 2013  │ 10    │ 28889   │
│ 11  │ 2013  │ 11    │ 27268   │
│ 12  │ 2013  │ 12    │ 28135   │

julia> per_year =
          @> per_month |>
          group_by(_, :year) |>
          summarize(_, flights = @_ sum(autocolumns(_).flights)) |>
          autocolumns;

julia> pretty(per_year)
1×2 DataFrames.DataFrame
│ Row │ year  │ flights │
│     │ Int64 │ Int64   │
├─────┼───────┼─────────┤
│ 1   │ 2013  │ 336776  │
```

Here's the example in the dplyr docs for piping:

```jldoctest dplyr
julia> @> flights |>
          group_by(_, :year, :month, :day) |>
          summarize(_,
            arr = (@_ autocolumns(_).arr_delay |> skipmissing |> mean),
            dep = @_ autocolumns(_).dep_delay |> skipmissing |> mean
          ) |>
          when(_, @_ _.arr > 30 || _.dep > 30) |>
          autocolumns |>
          pretty
49×5 DataFrames.DataFrame
│ Row │ year  │ month │ day   │ arr     │ dep     │
│     │ Int64 │ Int64 │ Int64 │ Float64 │ Float64 │
├─────┼───────┼───────┼───────┼─────────┼─────────┤
│ 1   │ 2013  │ 1     │ 16    │ 34.2474 │ 24.6129 │
│ 2   │ 2013  │ 1     │ 31    │ 32.6029 │ 28.6584 │
│ 3   │ 2013  │ 2     │ 11    │ 36.2901 │ 39.0736 │
│ 4   │ 2013  │ 2     │ 27    │ 31.2525 │ 37.7633 │
│ 5   │ 2013  │ 3     │ 8     │ 85.8622 │ 83.5369 │
│ 6   │ 2013  │ 3     │ 18    │ 41.2919 │ 30.118  │
│ 7   │ 2013  │ 4     │ 10    │ 38.4123 │ 33.0237 │
⋮
│ 42  │ 2013  │ 10    │ 11    │ 18.923  │ 31.2318 │
│ 43  │ 2013  │ 12    │ 5     │ 51.6663 │ 52.328  │
│ 44  │ 2013  │ 12    │ 8     │ 36.9118 │ 21.5153 │
│ 45  │ 2013  │ 12    │ 9     │ 42.5756 │ 34.8002 │
│ 46  │ 2013  │ 12    │ 10    │ 44.5088 │ 26.4655 │
│ 47  │ 2013  │ 12    │ 14    │ 46.3975 │ 28.3616 │
│ 48  │ 2013  │ 12    │ 17    │ 55.8719 │ 40.7056 │
│ 49  │ 2013  │ 12    │ 23    │ 32.226  │ 32.2541 │
```

# Two table verbs

I'm following the example [here](https://cran.r-project.org/web/packages/dplyr/vignettes/two-table.html).

Again, for inference reasons, natural joins won't work. I only provide one join
at the moment, but it's super efficient. Let's start by reading in airlines and
letting julia konw that it's already sorted by `:carrier`.

```jldoctest dplyr
julia> airlines =
          @> CSV.read("airlines.csv", missingstring = "NA") |>
          named_tuple |>
          remove(_, Symbol(""));

julia> airlines_by_carrier =
          @> airlines |>
          rows |>
          By(_, select(:carrier));
```

If we want to join this data into the flights data, here's what we do.
`LeftJoin` requires not only presorted but **unique** keys. Of course,
there are multiple flights from the same airline, so we need to group first.
Then, we tell Julia that the groups are themselves sorted (by the first item,
the key). Finally we can join in the airline data. But the results are a bit
tricky. Let's take a look at the first item. Just like the dplyr manual, I'm
only using a few of the columns from `flights` for demonstration.

```jldoctest dplyr
julia> flights2 =
            @> flights |>
            select(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier);

julia> airline_join =
          @> flights2 |>
          group_by(_, :carrier) |>
          By(_, first) |>
          LeftJoin(_, airlines_by_carrier);

julia> first_airline_join = first(airline_join);
```

We end up getting a group and subframe on the left, and a row on the right.

```jldoctest dplyr
julia> first_airline_join.first.first
(carrier = "9E",)

julia> @> first_airline_join.first.second |>
            autocolumns |>
            pretty
18460×8 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row   │ year   │ month  │ day    │ hour   │ origin  │ dest    │ tailnum │
│       │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰ │ String⍰ │ String⍰ │ String⍰ │
├───────┼────────┼────────┼────────┼────────┼─────────┼─────────┼─────────┤
│ 1     │ 2013   │ 1      │ 1      │ 8      │ JFK     │ MSP     │ N915XJ  │
│ 2     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ IAD     │ N8444F  │
│ 3     │ 2013   │ 1      │ 1      │ 14     │ JFK     │ BUF     │ N920XJ  │
│ 4     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ SYR     │ N8409N  │
│ 5     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ROC     │ N8631E  │
│ 6     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ BWI     │ N913XJ  │
│ 7     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ORD     │ N904XJ  │
⋮
│ 18453 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ IAD     │ N8790A  │
│ 18454 │ 2013   │ 9      │ 30     │ 20     │ LGA     │ TYS     │ N8924B  │
│ 18455 │ 2013   │ 9      │ 30     │ 19     │ JFK     │ PHL     │ N602XJ  │
│ 18456 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ DCA     │ N602LR  │
│ 18457 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ BWI     │ N8423C  │
│ 18458 │ 2013   │ 9      │ 30     │ 18     │ JFK     │ BUF     │ N906XJ  │
│ 18459 │ 2013   │ 9      │ 30     │ 14     │ JFK     │ DCA     │ missing │
│ 18460 │ 2013   │ 9      │ 30     │ 22     │ LGA     │ SYR     │ missing │

julia> first_airline_join.second
(carrier = "9E", name = "Endeavor Air Inc.")
```

If you want to collect your results into a flat new dataframe, you need to do a
bit of surgery, including making use of `Iterators.flatten`. We also need to
make a fake row to insert on the right in case we can't find a match.

```jldoctest dplyr
julia> empty_right_row =
            @> airlines |>
            remove(_, :carrier) |>
            map(x -> missing, _);

julia> @> airline_join |>
          over(_, @_ begin
              right_row = _.second
              if right_row === missing
                  right_row = empty_right_row
              end
              over(_.first.second, x -> merge(x, right_row))
          end) |>
          Iterators.flatten(_) |>
          columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum,
                    :carrier, :name) |>
          pretty
336776×9 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 1     │ 1     │ 8     │ JFK    │ MSP    │ N915XJ  │ 9E      │
│ 2      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ IAD    │ N8444F  │ 9E      │
│ 3      │ 2013  │ 1     │ 1     │ 14    │ JFK    │ BUF    │ N920XJ  │ 9E      │
│ 4      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ SYR    │ N8409N  │ 9E      │
│ 5      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ROC    │ N8631E  │ 9E      │
│ 6      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ BWI    │ N913XJ  │ 9E      │
│ 7      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ORD    │ N904XJ  │ 9E      │
⋮
│ 336769 │ 2013  │ 9     │ 27    │ 16    │ LGA    │ IAD    │ N514MJ  │ YV      │
│ 336770 │ 2013  │ 9     │ 27    │ 17    │ LGA    │ CLT    │ N925FJ  │ YV      │
│ 336771 │ 2013  │ 9     │ 28    │ 19    │ LGA    │ IAD    │ N501MJ  │ YV      │
│ 336772 │ 2013  │ 9     │ 29    │ 16    │ LGA    │ IAD    │ N518LR  │ YV      │
│ 336773 │ 2013  │ 9     │ 29    │ 17    │ LGA    │ CLT    │ N932LR  │ YV      │
│ 336774 │ 2013  │ 9     │ 30    │ 16    │ LGA    │ IAD    │ N510MJ  │ YV      │
│ 336775 │ 2013  │ 9     │ 30    │ 17    │ LGA    │ CLT    │ N905FJ  │ YV      │
│ 336776 │ 2013  │ 9     │ 30    │ 20    │ LGA    │ CLT    │ N924FJ  │ YV      │
```

Are you exhaused? I am. To streamline this entire process, I've provided a
`left_join` function which will conduct a natural, many-to-one left join. Here,
autocolumns isn't working (take it up with Base inference), so you'll have to
manually provide column names.

```jldoctest dplyr
julia> @> left_join(flights2, airlines) |>
            columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier, :name) |>
            pretty
336776×9 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 1     │ 1     │ 8     │ JFK    │ MSP    │ N915XJ  │ 9E      │
│ 2      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ IAD    │ N8444F  │ 9E      │
│ 3      │ 2013  │ 1     │ 1     │ 14    │ JFK    │ BUF    │ N920XJ  │ 9E      │
│ 4      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ SYR    │ N8409N  │ 9E      │
│ 5      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ROC    │ N8631E  │ 9E      │
│ 6      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ BWI    │ N913XJ  │ 9E      │
│ 7      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ORD    │ N904XJ  │ 9E      │
⋮
│ 336769 │ 2013  │ 9     │ 27    │ 16    │ LGA    │ IAD    │ N514MJ  │ YV      │
│ 336770 │ 2013  │ 9     │ 27    │ 17    │ LGA    │ CLT    │ N925FJ  │ YV      │
│ 336771 │ 2013  │ 9     │ 28    │ 19    │ LGA    │ IAD    │ N501MJ  │ YV      │
│ 336772 │ 2013  │ 9     │ 29    │ 16    │ LGA    │ IAD    │ N518LR  │ YV      │
│ 336773 │ 2013  │ 9     │ 29    │ 17    │ LGA    │ CLT    │ N932LR  │ YV      │
│ 336774 │ 2013  │ 9     │ 30    │ 16    │ LGA    │ IAD    │ N510MJ  │ YV      │
│ 336775 │ 2013  │ 9     │ 30    │ 17    │ LGA    │ CLT    │ N905FJ  │ YV      │
│ 336776 │ 2013  │ 9     │ 30    │ 20    │ LGA    │ CLT    │ N924FJ  │ YV      │
```

Let's keep going in the examples. I'm going to name the weather key. I'm also
going to make a "fake" weather row that only contains missing objects, and we
can use this when weather data is missing. Yes, I know it's a bit frustrating to
have to explicitly deal with missing data, but it adds a lot more flexibility
(e.g. you could do mean replacement).

```jldoctest dplyr
julia> weather =
            @> CSV.read( "weather.csv", missingstring = "NA") |>
            named_tuple |>
            remove(_, Symbol(""));

julia> @> left_join(flights2, weather) |>
            columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier,
                :temp, :dewp, :humid, :wind_dir, :wind_speed, :wind_gust, :precip,
                :pressure, :visib, :time_hour
            ) |>
            pretty
335862×18 DataFrames.DataFrame. Omitted printing of 10 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 1     │ 1     │ 5     │ EWR    │ IAH    │ N14228  │ UA      │
│ 2      │ 2013  │ 1     │ 1     │ 5     │ EWR    │ ORD    │ N39463  │ UA      │
│ 3      │ 2013  │ 1     │ 1     │ 5     │ JFK    │ MIA    │ N619AA  │ AA      │
│ 4      │ 2013  │ 1     │ 1     │ 5     │ JFK    │ BQN    │ N804JB  │ B6      │
│ 5      │ 2013  │ 1     │ 1     │ 5     │ JFK    │ BOS    │ N708JB  │ B6      │
│ 6      │ 2013  │ 1     │ 1     │ 5     │ LGA    │ IAH    │ N24211  │ UA      │
│ 7      │ 2013  │ 1     │ 1     │ 6     │ EWR    │ FLL    │ N516JB  │ B6      │
⋮
│ 335855 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ CLE    │ N24715  │ UA      │
│ 335856 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ DSM    │ N14168  │ EV      │
│ 335857 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ PDX    │ N39475  │ UA      │
│ 335858 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ PBI    │ N77258  │ UA      │
│ 335859 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ DCA    │ N13979  │ EV      │
│ 335860 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ MCO    │ N37468  │ UA      │
│ 335861 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ BOS    │ N486UA  │ UA      │
│ 335862 │ 2013  │ 12    │ 30    │ 19    │ EWR    │ BNA    │ N17984  │ EV      │
```

Now try merging in the airplane data. Note that I rename the year column to avoid
a collision in the natural join.

```jldoctest dplyr
julia> planes =
            @> CSV.read( "planes.csv", missingstring = "NA") |>
            named_tuple |>
            remove(_, Symbol("")) |>
            rename(_, construction_year = Name(:year));

julia> @> left_join(flights2, planes) |>
            columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum,
                :carrier, :type, :manufacturer, :model, :engines, :seats,
                :speed, :engine, :construction_year
            ) |>
            pretty
334264×16 DataFrames.DataFrame. Omitted printing of 8 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String  │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 2     │ 11    │ 14    │ LGA    │ ATL    │ D942DN  │ DL      │
│ 2      │ 2013  │ 3     │ 23    │ 13    │ LGA    │ MCO    │ D942DN  │ DL      │
│ 3      │ 2013  │ 3     │ 24    │ 8     │ JFK    │ MCO    │ D942DN  │ DL      │
│ 4      │ 2013  │ 7     │ 5     │ 12    │ LGA    │ ATL    │ D942DN  │ DL      │
│ 5      │ 2013  │ 1     │ 1     │ 15    │ LGA    │ CLT    │ N0EGMQ  │ MQ      │
│ 6      │ 2013  │ 1     │ 1     │ 21    │ LGA    │ CLT    │ N0EGMQ  │ MQ      │
│ 7      │ 2013  │ 1     │ 2     │ 8     │ LGA    │ ATL    │ N0EGMQ  │ MQ      │
⋮
│ 334257 │ 2013  │ 9     │ 26    │ 13    │ LGA    │ CLT    │ N9EAMQ  │ MQ      │
│ 334258 │ 2013  │ 9     │ 26    │ 19    │ LGA    │ MSP    │ N9EAMQ  │ MQ      │
│ 334259 │ 2013  │ 9     │ 27    │ 10    │ LGA    │ DTW    │ N9EAMQ  │ MQ      │
│ 334260 │ 2013  │ 9     │ 27    │ 16    │ LGA    │ ATL    │ N9EAMQ  │ MQ      │
│ 334261 │ 2013  │ 9     │ 29    │ 12    │ LGA    │ BNA    │ N9EAMQ  │ MQ      │
│ 334262 │ 2013  │ 9     │ 29    │ 18    │ LGA    │ CMH    │ N9EAMQ  │ MQ      │
│ 334263 │ 2013  │ 9     │ 30    │ 11    │ JFK    │ DCA    │ N9EAMQ  │ MQ      │
│ 334264 │ 2013  │ 9     │ 30    │ 14    │ JFK    │ TPA    │ N9EAMQ  │ MQ      │
```

```jldoctest dplyr
julia> airports =
            @> CSV.read("airports.csv", missingstring = "NA") |>
            named_tuple |>
            remove(_, Symbol("")) |>
            rename(_, dest = Name(:faa));

julia> @> left_join(flights2, airports) |>
            columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier, :name, :lat, :lon, :alt, :tz, :dst, :tzone) |>
            pretty
336776×15 DataFrames.DataFrame. Omitted printing of 7 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 10    │ 1     │ 20    │ JFK    │ ABQ    │ N554JB  │ B6      │
│ 2      │ 2013  │ 10    │ 2     │ 20    │ JFK    │ ABQ    │ N607JB  │ B6      │
│ 3      │ 2013  │ 10    │ 3     │ 20    │ JFK    │ ABQ    │ N591JB  │ B6      │
│ 4      │ 2013  │ 10    │ 4     │ 20    │ JFK    │ ABQ    │ N662JB  │ B6      │
│ 5      │ 2013  │ 10    │ 5     │ 19    │ JFK    │ ABQ    │ N580JB  │ B6      │
│ 6      │ 2013  │ 10    │ 6     │ 20    │ JFK    │ ABQ    │ N507JB  │ B6      │
│ 7      │ 2013  │ 10    │ 7     │ 20    │ JFK    │ ABQ    │ N565JB  │ B6      │
⋮
│ 336769 │ 2013  │ 9     │ 27    │ 7     │ LGA    │ XNA    │ N724MQ  │ MQ      │
│ 336770 │ 2013  │ 9     │ 27    │ 8     │ EWR    │ XNA    │ N17146  │ EV      │
│ 336771 │ 2013  │ 9     │ 27    │ 15    │ LGA    │ XNA    │ N724MQ  │ MQ      │
│ 336772 │ 2013  │ 9     │ 29    │ 17    │ LGA    │ XNA    │ N725MQ  │ MQ      │
│ 336773 │ 2013  │ 9     │ 30    │ 7     │ LGA    │ XNA    │ N735MQ  │ MQ      │
│ 336774 │ 2013  │ 9     │ 30    │ 8     │ EWR    │ XNA    │ N14117  │ EV      │
│ 336775 │ 2013  │ 9     │ 30    │ 15    │ LGA    │ XNA    │ N725MQ  │ MQ      │
│ 336776 │ 2013  │ 9     │ 30    │ 17    │ LGA    │ XNA    │ N720MQ  │ MQ      │
```

I have not decided to support any other kind of join. However, using the
iterators in this package, equivalents to right_join, inner_join, semi_join, and
anti_join are all possible.
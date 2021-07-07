# Getting Started

Query.jl supports two different front-end syntax options: 1) standalone query operators that are combined via the pipe operator and 2) LINQ style queries.

## Standalone query operators

The standalone query operators are typically combined into more complicated queries via the pipe operator. Probably the most simple example is a query that filters a DataFrame and returns a subset of its columns:

```jldoctest
using Query, DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = df |>
  @filter(_.age>50) |>
  @map({_.name, _.children}) |>
  DataFrame

println(x)

# output

1×2 DataFrame
 Row │ name    children
     │ String  Int64
─────┼──────────────────
   1 │ Kirk           2
```

Note the shorthand syntax `_.age>50` for the anonymous function `i->i.age>50`.
See [Experimental features](experimental.md) for more information.

## LINQ style queries

The basic structure of a LINQ style query statement is

```julia
q = @from <range variable> in <source> begin
    <query statements>
end
```

Multiple `<query statements>` are separated by line breaks. The example from the previous section can also be written like this using LINQ style queryies:

```jldoctest
using Query, DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = @from i in df begin
    @where i.age>50
    @select {i.name, i.children}
    @collect DataFrame
end

println(x)

# output

1×2 DataFrame
 Row │ name    children
     │ String  Int64
─────┼──────────────────
   1 │ Kirk           2
```



## Result types

The results of a query can optionally be materialized into a data structure. For LINQ style queries this is done with a `@collect` statement at the end of the query. For the standalone query option, one can simply pipe things into a data structure type. The Data Sinks section describes all the available formats for query materialization.

A query that is not materialized will return an iterator that can be used to iterate over the individual elements of the result set.

## Tables

The Query package does not require data sources or sinks to have a table like structure (i.e. rows and columns). When a table like structure is queried, it is treated as a set of `NamedTuple`s, where the set elements correspond to the rows of the source, and the fields of the `NamedTuple` correspond to the columns. Data sinks that have a table like structure typically require the results of the query to be projected into a `NamedTuple`. The `{}` syntax in the Query package provides a simplified way to construct `NamedTuple`s in query statements.

## Missing values

Missing values are represented as `DataValue` types from the [DataValues.jl](https://github.com/queryverse/DataValues.jl) package. Here are some usage tips.

All arithmetic operators work automatically with missing values. If any of the arguments to an arithmetic operation is a missing value, the result will also be a missing value.

All comparison operators, like `==` or `<` etc. also work with missing values. These operators always return either `true` or `false`.

If you want to use a function that does not support missing values out of the box, you can *lift* that function using the `.` operator. This lifted function will propagate any missing values, i.e. if any of the arguments to such a lifted function is missing, the result will also be a missing value. For example, to apply the `log` function on a column that is of type `DataValue{Float64}`, i.e. a column that can have missing values, one would write `log.(i.a)`, assuming the column is named `a`. The return type of this call will be `DataValue{Float64}`.

## Piping data through a LINQ style query

LINQ style queries can also be integrated into data pipelines that are constructed via the `|>` operator. Such queries are started with the `@query` macro instead of
the `@from` macro. The main difference between those two macros is that the `@query` macro does not take an argument for the data source, instead the data source needs to be piped into the query. In practice the syntax for the `@query` macro looks like this:

```julia
using Query, DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = df |> @query(i, begin
            @where i.age>50
            @select {i.name, i.children}
          end) |> DataFrame

println(x)

# output

1×2 DataFrame
│ Row │ name   │ children │
├─────┼────────┼──────────┤
│ 1   │ "Kirk" │ 2        │
```

Note how the range variable `i` is the first argument to the `@query` macro, and then the second argument is a `begin`...`end` block that contains the query operators for the query. Note also that it is recommended to use parenthesis `()` to call the `@query` macro, otherwise any continuing pipe operator will not work.

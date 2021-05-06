using Query
using QueryOperators
using DataFrames
using DataValues
using Documenter
using Test

struct Person
    Name::String
    Friends::Vector{String}
end

@testset "Queries" begin

    @testset "Utilities" begin
        @test !Query.ismacro(Symbol("@from"), "@from")
        @test !Query.ismacro(:(a == 1), "@from")
        @test Query.ismacro(:(@from 1), "@from")
        @test Query.ismacro(:(@from(1)), "@from")
        @test !Query.ismacro(:(@from 1), "@for")
        @test !Query.ismacro(:(@from, 1), "@from")
        @test Query.ismacro(:(@from 1 2 3), "@from", 4)
        @test !Query.ismacro(:(@from 1 2 3 4), "@from", 4)
        @test !Query.ismacro(:(map(1)), :map)

        @test !Query.iscall(Symbol("@from"), :map)
        @test !Query.iscall(:(a == 1), :map)
        @test !Query.iscall(:(@from 1), Symbol("@from"))
        @test !Query.iscall(:(@from(1)), Symbol("@from"))
        @test Query.iscall(:(map(1)), :map)
        @test !Query.iscall(:(map, 1), :map)
        @test Query.iscall(:(map(1, 2, 3)), :map, 3)
        @test !Query.iscall(:(map(1, 2, 3, 4)), :map, 3)
    end

    @testset "shift_access!" begin
        ex = Expr(:., :c, QuoteNode(:d))
        Query.shift_access!(:b, ex)
        @test ex == :((b.c).d)
        Query.shift_access!(:a, ex)
        @test ex == :(((a.b).c).d)
    end

source_df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

q = @from i in source_df begin
    @where i.age > 30. && i.children > 2
    @select {Name = lowercase(i.name)}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (1, 1)
@test q[1,:Name] == "sally"

source_dict = Dict("John" => 34., "Sally" => 56.)

q = @from i in source_dict begin
    @where i.second > 36.
    @select {Name = lowercase(i.first)}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (1, 1)
@test q[1,:Name] == "sally"

q = @from i in source_dict begin
    @where i.second > 36.
    @select lowercase(i.first)
    @collect
end

@test isa(q, Vector{String})
@test length(q) == 1
@test q[1] == "sally"

source_array = Array{Person}(undef, 0)
push!(source_array, Person("John", ["Sally", "Miles", "Frank"]))
push!(source_array, Person("Sally", ["Don", "Martin"]))

q = @from i in source_array begin
    @where length(i.Friends) > 2
    @select {i.Name, Friendcount = length(i.Friends)}
    @collect
end

@test isa(q, Vector{NamedTuple{(:Name, :Friendcount),Tuple{String,Int}}})
@test length(q) == 1
@test q[1].Name == "John"
@test q[1].Friendcount == 3

q = @from i in source_array begin
    @where length(i.Friends) > 2
    @select {i.Name, Friendcount = length(i.Friends)}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (1, 2)
@test q[1,:Name] == "John"
@test q[1,:Friendcount] == 3

source_df2 = DataFrame(a=[1,2,3], b=[1.,2.,3.])
source_it = DataFrame(c=[2.,4.,2.], d=["John","Jim","Sally"])


q = @from i in source_df2 begin
    @join j in source_it on i.a equals convert(Int, j.c)
    @select {i.a,i.b,j.c,j.d,e = "Name: $(j.d)"}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (2, 5)
@test q[1,:a] == 2
@test q[1,:b] == 2.
@test q[1,:c] == 2.
@test q[1,:d] == "John"
@test q[1,:e] == "Name: John"
@test q[2,:a] == 2
@test q[2,:b] == 2.
@test q[2,:c] == 2.
@test q[2,:d] == "Sally"
@test q[2,:e] == "Name: Sally"

q = @from i in source_df2 begin
    @join j in (@from i in source_it begin
                    @where i.c < 3.
                    @select i
                end) on i.a equals convert(Int, j.c)
    @select {i.a,i.b,j.c,j.d,e = "Name: $(j.d)"}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (2, 5)
@test q[1,:a] == 2
@test q[1,:b] == 2.
@test q[1,:c] == 2.
@test q[1,:d] == "John"
@test q[1,:e] == "Name: John"
@test q[2,:a] == 2
@test q[2,:b] == 2.
@test q[2,:c] == 2.
@test q[2,:d] == "Sally"
@test q[2,:e] == "Name: Sally"

q = @from i in source_df begin
    @let count = length(i.name)
    @let kids_per_year = i.children / i.age
    @where count > 4
    @select {Name = i.name, Count = count, KidsPerYear = kids_per_year}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (1, 3)
@test q[1,:Name] == "Sally"
@test q[1,:Count] == 5
@test q[1,:KidsPerYear] ≈ 0.119047619047

q = @from i in source_df begin
    @orderby i.age
    @select lowercase(i.name)
    @collect
end

@test isa(q, Vector{String})
@test length(q) == 3
@test q == ["john", "sally", "kirk"]

q = @from i in source_df begin
    @orderby descending(i.age)
    @select lowercase(i.name)
    @collect
end

@test isa(q, Vector{String})
@test length(q) == 3
@test q == ["kirk", "sally", "john"]

q = @from i in source_df begin
    @orderby ascending(i.age)
    @select lowercase(i.name)
    @collect
end

@test isa(q, Vector{String})
@test length(q) == 3
@test q == ["john", "sally", "kirk"]

source_nestedsort = [(4, 3),(4, 3),(1, 2),(1, 1)]
q = @from i in source_nestedsort begin
    @orderby i[1], descending(i[2])
    @select i
    @collect
end

@test isa(q, Vector{Tuple{Int,Int}})
@test length(q) == 4
@test q == [(1, 2),(1, 1),(4, 3),(4, 3)]


# We need to use a typed const here, otherwise type inference stands no chance
closure_var_1::Int = 1

q = @from i in source_df begin
    @let k = i.children + closure_var_1
    @join j in source_df2 on i.children * closure_var_1 equals j.a * closure_var_1
    @where i.age > closure_var_1
    @orderby i.age * closure_var_1
    @select i.children + closure_var_1
    @collect
end

@test isa(q, Vector{Int})
@test length(q) == 2
@test q[1] == 4
@test q[2] == 3

q = @from i in [5,4,4,6,1] begin
    @orderby i
    @select i
    @collect
end

@test isa(q, Vector{Int})
@test length(q) == 5
@test q == [1,4,4,5,6]

q = @from i in [5,4,4,6,1] begin
    @orderby descending(i)
    @select i
    @collect
end

@test isa(q, Vector{Int})
@test length(q) == 5
@test q == [6,5,4,4,1]

# Test phase 3 query translation

q = @from i in source_array begin
    @select i
    @collect
end

@test isa(q, Vector{Person})
@test length(q) == 2
@test q[1].Name == "John"
@test q[1].Friends == ["Sally", "Miles", "Frank"]
@test q[2].Name == "Sally"
@test q[2].Friends == ["Don", "Martin"]

q = @from i in source_df begin
    @from j in source_df2
    @select {Name = i.name,Age = i.age,Children = i.children,A = j.a,B = j.b}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (9, 5)
@test q.Name == ["John","John","John","Sally","Sally","Sally","Kirk","Kirk","Kirk"]
@test q.Age == [23.,23.,23.,42.,42.,42.,59.,59.,59.]
@test q.Children == [3,3,3,5,5,5,2,2,2]
@test q.A == [1,2,3,1,2,3,1,2,3]
@test q.B == [1.,2.,3.,1.,2.,3.,1.,2.,3.]

source_nested_dict = Dict(:a => [1,2,3], :b => [4,5])

q = @from i in source_nested_dict begin
    @from j in i.second
    @select {Key = i.first,Value = j}
    @collect
end

@test isa(q, Vector{NamedTuple{(:Key, :Value),Tuple{Symbol,Int}}})
@test length(q) == 5
@test in((Key = :a, Value = 1), q)
@test in((Key = :a, Value = 2), q)
@test in((Key = :a, Value = 3), q)
@test in((Key = :b, Value = 4), q)
@test in((Key = :b, Value = 5), q)

q = @from i in source_df begin
    @from j in source_df2
    @where j.a > 1
    @select {Name = i.name,Age = i.age,Children = i.children,A = j.a,B = j.b}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (6, 5)
@test q.Name == ["John","John","Sally","Sally","Kirk","Kirk"]
@test q.Age == [23.,23.,42.,42.,59.,59.]
@test q.Children == [3,3,5,5,2,2]
@test q.A == [2,3,2,3,2,3]
@test q.B == [2.,3.,2.,3.,2.,3.]

source_nested_dict = Dict(:a => [1,2,3], :b => [4,5])

q = @from i in source_nested_dict begin
    @from j in i.second
    @where j > 2
    @select {Key = i.first,Value = j}
    @collect
end

@test isa(q, Vector{NamedTuple{(:Key, :Value),Tuple{Symbol,Int}}})
@test length(q) == 3
@test in((Key = :a, Value = 3), q)
@test in((Key = :b, Value = 4), q)
@test in((Key = :b, Value = 5), q)

source_df_groupby = DataFrame(name=["John", "Sally", "Kirk"], children=[3,2,2])

x = @from i in source_df_groupby begin
    @group i.name by i.children
    @collect
end

@test isa(x, Array{Grouping{Int,String}})
@test length(x) == 2
@test key(x[1]) == 3
@test x[1][:] == ["John"]
@test key(x[2]) == 2
@test x[2][:] == ["Sally", "Kirk"]

x = @from i in source_df_groupby begin
    @group i by i.children
    @collect
end

@test isa(x, Vector{Grouping{Int,NamedTuple{(:name, :children),Tuple{String,Int}}}})
@test length(x) == 2
@test key(x[1]) == 3
@test x[1][1].name == "John";
@test key(x[2]) == 2
@test x[2][1].name == "Sally";
@test x[2][2].name == "Kirk";

q = @from i in source_df_groupby begin
    @group i by i.children into g
    @select {Children = key(g),Number_of_parents = length(g)}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (2, 2)
@test q.Children == [3,2]
@test q.Number_of_parents == [1,2]


q = @from i in source_df begin
    @where i.age > 30. && i.children > 2
    @select i into j
    @select {Name = lowercase(j.name)}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (1, 1)
@test q[1,:Name] == "sally"

q = @from i in source_df2 begin
    @join j in source_it on i.a equals convert(Int, j.c) into k
    @select {i.a,i.b,c = k}
    @collect
end

@test isa(q, Vector{NamedTuple{(:a, :b, :c),Tuple{Int,Float64,Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}}}}})
@test length(q) == 3
@test q[1].a == 1
@test q[1].b == 1.
@test isa(q[1].c, Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}})
@test length(q[1].c) == 0
@test q[2].a == 2
@test q[2].b == 2.
@test isa(q[2].c, Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}})
@test length(q[2].c) == 2
@test q[2].c[1].c == 2.
@test q[2].c[1].d == "John"
@test q[2].c[2].c == 2.
@test q[2].c[2].d == "Sally"
@test q[3].a == 3
@test q[3].b == 3.
@test isa(q[3].c, Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}})
@test length(q[3].c) == 0

q = @from i in source_df2 begin
    @join j in source_it on i.a equals convert(Int, j.c) into k
    @where length(k) > 0
    @select {i.a,i.b,c = k}
    @collect
end

@test isa(q, Vector{NamedTuple{(:a, :b, :c),Tuple{Int,Float64,Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}}}}})
@test length(q) == 1
@test q[1].a == 2
@test q[1].b == 2.
@test isa(q[1].c, Vector{NamedTuple{(:c, :d),Tuple{Float64,String}}})
@test length(q[1].c) == 2
@test q[1].c[1].c == 2.
@test q[1].c[1].d == "John"
@test q[1].c[2].c == 2.
@test q[1].c[2].d == "Sally"

source_df_nulls = DataFrame(name=["John", "Sally", missing, "Kirk"], age=[23., 42., 54., 59.], children=[3,missing,8,2])
q = @from i in source_df_nulls begin
    @select i
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (4, 3)
@test q[1,:name] == "John"
@test q[2,:name] == "Sally"
@test q[3,:name] === missing
@test q[4,:name] == "Kirk"
@test q.age == [23., 42., 54., 59.]
@test q[1,:children] == 3
@test q[2,:children] === missing
@test q[3,:children] == 8
@test q[4,:children] == 2

q = collect(QueryOperators.default_if_empty(DataValue{String}[]))
@test length(q) == 1
@test isna(q[1])

q = collect(QueryOperators.default_if_empty(DataValue{String}["John", "Sally"]))
@test length(q) == 2
@test q == DataValue{String}["John", "Sally"]


source_df3 = DataFrame(c=Union{Int,Missing}[2,4,2], d=Union{String,Missing}["John", "Jim","Sally"])
q = @from i in source_df2 begin
    @left_outer_join j in source_df3 on i.a equals get(j.c)
    @select {i.a,i.b,j.c,j.d}
    @collect DataFrame
end

@test isa(q, DataFrame)
@test size(q) == (4, 4)
@test q.a == [1,2,2,3]
@test q.b == [1.,2.,2.,3.]
@test q[1,:c] === missing
@test q[2,:c] == 2
@test q[3,:c] == 2
@test q[4,:c] === missing
@test q[1,:d] === missing
@test q[2,:d] == "John"
@test q[3,:d] == "Sally"
@test q[4,:d] === missing

q = @from i in source_df begin
    @select i.name => i.children
    @collect Dict
end

@test isa(q, Dict{String,Int})
@test length(q) == 3
@test q["John"] == 3
@test q["Sally"] == 5
@test q["Kirk"] == 2

q = @from i in source_df begin
    @let j = i.name
    @let k = i.children
    @let l = i.age
    @select {a = j, b = k, c = l}
    @collect DataFrame
end

@test q.a == ["John", "Sally", "Kirk"]
@test q.b == [3, 5, 2]
@test q.c == [23., 42., 59.]

@test @count(source_df) == 3
@test @count(source_df, i -> i.children > 3) == 1

q = DataFrame(@filter(source_df, i -> i.age > 30. && i.children > 2))

@test isa(q, DataFrame)
@test size(q) == (1, 3)
@test q[1,:name] == "Sally"
@test q[1,:age] == 42.
@test q[1,:children] == 5

q = collect(@map(source_df, i -> i.children))

@test isa(q, Vector{Int})
@test q == [3,5,2]

include("test_dplyr-syntax.jl")
include("test_pipesyntax.jl")
include("test_macros.jl")

# Only run doctests on 64, all the output checks get messed up with
# Int32 otherwise. Also only run on Julia 1.6 and newer, because
# a lot of output printing was changed and doctests now can't be written
# to work on multiple Julia versions.
Int == Int64 && VERSION >= v"1.6" && doctest(Query)

end

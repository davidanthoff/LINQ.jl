using Query
using QueryOperators
using DataFrames
using Test

@testset "Standalone Syntax" begin

@testset "@take operator" begin
    df = DataFrame(a=[1,2,3], b=[3.,2.,1.], c=["a", "b", "c"])

    df2 = df |> @take(2) |> DataFrame

    @test df2 isa DataFrame
    @test size(df2) == (2,3)
    @test df2[:a] == [1,2]
    @test df2[:b] == [3.,2.]
    @test df2[:c] == ["a", "b"]

    df2 = DataFrame(@take(df, 2))

    @test df2 isa DataFrame
    @test size(df2) == (2,3)
    @test df2[:a] == [1,2]
    @test df2[:b] == [3.,2.]
    @test df2[:c] == ["a", "b"]
end

@testset "@drop operator" begin
    df = DataFrame(a=[1,2,3], b=[3.,2.,1.], c=["a", "b", "c"])

    df2 = df |> @drop(1) |> DataFrame

    @test df2 isa DataFrame
    @test size(df2) == (2,3)
    @test df2[:a] == [2,3]
    @test df2[:b] == [2.,1.]
    @test df2[:c] == ["b","c"]

    df2 = DataFrame(@drop(df, 1))

    @test df2 isa DataFrame
    @test size(df2) == (2,3)
    @test df2[:a] == [2,3]
    @test df2[:b] == [2.,1.]
    @test df2[:c] == ["b","c"]
end

@testset "@gather operator" begin
    source_gather = DataFrame(Year=[2017,2018,2019], US=[1,2,3], EU=[4,5,6], CN=[7,8,9])
    @test source_gather |> @gather(:US, :EU, :CN) |> collect ==
        [
            (Year = 2017, key = :US, value = 1), 
            (Year = 2017, key = :EU, value = 4),
            (Year = 2017, key = :CN, value = 7),
            (Year = 2018, key = :US, value = 2),
            (Year = 2018, key = :EU, value = 5),
            (Year = 2018, key = :CN, value = 8),
            (Year = 2019, key = :US, value = 3),
            (Year = 2019, key = :EU, value = 6),
            (Year = 2019, key = :CN, value = 9)
        ]
    @test eltype(source_gather |> @gather(:US, :EU, :CN)) == NamedTuple{(:Year, :key, :value),Tuple{Int, Symbol, Int}}
end

@testset "@unique operator" begin
    df = DataFrame(a=[1,2,1], b=[3.,3.,3.])

    @test df |> @unique() |> collect == [(a=1,b=3.), (a=2,b=3.)]
    @test df |> @unique(_.b) |> collect == [(a=1,b=3.)]
end

end

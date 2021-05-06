using Query
using DataFrames
using Test

@testset "Standalone Syntax" begin

@testset "@take operator" begin
    df = DataFrame(a=[1,2,3], b=[3.,2.,1.], c=["a", "b", "c"])

    df2 = df |> @take(2) |> DataFrame

    @test df2 isa DataFrame
    @test size(df2) == (2, 3)
    @test df2[:a] == [1,2]
    @test df2[:b] == [3.,2.]
    @test df2[:c] == ["a", "b"]

    df2 = DataFrame(@take(df, 2))

    @test df2 isa DataFrame
    @test size(df2) == (2, 3)
    @test df2[:a] == [1,2]
    @test df2[:b] == [3.,2.]
    @test df2[:c] == ["a", "b"]
end

@testset "@drop operator" begin
    df = DataFrame(a=[1,2,3], b=[3.,2.,1.], c=["a", "b", "c"])

    df2 = df |> @drop(1) |> DataFrame

    @test df2 isa DataFrame
    @test size(df2) == (2, 3)
    @test df2[:a] == [2,3]
    @test df2[:b] == [2.,1.]
    @test df2[:c] == ["b","c"]

    df2 = DataFrame(@drop(df, 1))

    @test df2 isa DataFrame
    @test size(df2) == (2, 3)
    @test df2[:a] == [2,3]
    @test df2[:b] == [2.,1.]
    @test df2[:c] == ["b","c"]
end

@testset "@unique operator" begin
    df = DataFrame(a=[1,2,1], b=[3.,3.,3.])

    @test df |> @unique() |> collect == [(a = 1, b = 3.), (a = 2, b = 3.)]
    @test df |> @unique(_.b) |> collect == [(a = 1, b = 3.)]
end

end

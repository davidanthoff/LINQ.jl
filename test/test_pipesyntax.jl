using Query
using DataFrames
using Test

@testset "Pipe Syntax" begin

    df = DataFrame(a=[1,2,3], b=[3.,2.,1.], c=["a", "b", "c"])

    df2 = df |> @query(i, begin
        @where i.a > 2
        @select {i.c, i.b}
    end) |> DataFrame
    
    @test df2 isa DataFrame
    @test size(df2) == (1, 2)
    @test df2[1,:c] == "c"
    @test df2[1,:b] == 1.
end

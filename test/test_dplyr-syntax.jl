using Query
using DataFrames
using Statistics
using Test



@testset "a.b Syntax (dplyr API)" begin

    df = DataFrame(name=repeat(["John", "Sally", "Kirk"], inner=[1], outer=[2]), 
                   age=vcat([10., 20., 30.], [10., 20., 30.] .+ 3), 
                   children=repeat([3,2,2], inner=[1], outer=[2]),state=[:a,:a,:a,:b,:b,:b])

    x = @from i in df begin
        @group i by i.state into g
        @select {group = key(g),mage = mean(g.age), oldest = maximum(g.age), youngest = minimum(g.age)}
        @collect DataFrame
    end

    @test x isa DataFrame
    @test size(x) == (2, 4)
    @test x[1,:mage] == 20
    @test x[2,:mage] == 23
    @test x[1,:oldest] == 30
    @test x[2,:oldest] == 33
    @test x[1,:youngest] == 10
    @test x[2,:youngest] == 13
end

using Query
using DataFrames
using Statistics

df = DataFrame(name=repeat(["John", "Sally", "Kirk"], inner=[1], outer=[2]), 
     age=vcat([10., 20., 30.], [10., 20., 30.] .+ 3), 
     children=repeat([3,2,2], inner=[1], outer=[2]),state=[:a,:a,:a,:b,:b,:b])

x = @from i in df begin
    @group i by i.state into g
    @select {group = key(g),mage = mean(g.age), oldest = maximum(g.age), youngest = minimum(g.age)}
    @collect DataFrame
end

println(x)

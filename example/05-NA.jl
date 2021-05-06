using Query
using DataFrames

df = DataFrame(name=["John", missing, "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = @from i in df begin
    @where i.age > 30 && i.children > 2
    @select {Name = lowercase(i.name)}
    @collect DataFrame
end

println(x)

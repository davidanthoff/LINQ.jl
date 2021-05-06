using Query
using DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

q = @from i in df begin
    @select i.name => i.children
    @collect Dict
end

println(q)
